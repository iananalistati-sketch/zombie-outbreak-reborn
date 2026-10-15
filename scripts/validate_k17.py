#!/usr/bin/env python3
"""Avatar-sized collision/support sweeps against actual K-17 XML geometry.

No Roblox engine is emulated here. This catches sealed doors, missing landings,
blocked stair heads, unsupported defenses and malformed outputs before playtests.
"""
from collections import defaultdict
import argparse
import json
import math
import struct
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
CELL=16


def props(item):return {p.attrib['name']:p for p in item.find('Properties')}


def geometry(tree):
    boxes=[];all_parts=[]
    def visit(item,path):
        p=props(item);path=path+'/'+p.get('Name',ET.Element('Name')).text
        if item.attrib['class']=='Part':
            all_parts.append(p)
            if p['CanCollide'].text=='true':
                cf=p['CFrame'];v=p['size']
                center=[float(cf.find(k).text) for k in 'XYZ'];size=[float(v.find(k).text) for k in 'XYZ']
                extent=[sum(abs(float(cf.find(f'R{i}{j}').text))*size[j]/2 for j in range(3)) for i in range(3)]
                boxes.append((path,[center[i]-extent[i] for i in range(3)],[center[i]+extent[i] for i in range(3)]))
        for child in item.findall('Item'):visit(child,path)
    for item in tree.getroot().findall('Item'):visit(item,'')
    return boxes,all_parts


class CollisionIndex:
    def __init__(self,boxes):
        self.boxes=boxes;self.grid=defaultdict(list)
        for box in boxes:
            _,a,b=box
            for x in range(math.floor((a[0]-2)/CELL),math.floor((b[0]+2)/CELL)+1):
                for z in range(math.floor((a[2]-2)/CELL),math.floor((b[2]+2)/CELL)+1):self.grid[x,z].append(box)

    def at(self,x,z):return self.grid[math.floor(x/CELL),math.floor(z/CELL)]

    def sweep(self,route,avatar):
        samples=0;radius,height,step=(avatar[k] for k in ('radius','height','step'))
        for a,b in zip(route['points'],route['points'][1:]):
            count=max(1,math.ceil(math.dist(a,b)/.5))
            for i in range(count+1):
                x,y,z=[a[j]+(b[j]-a[j])*i/count for j in range(3)];samples+=1
                near=self.at(x,z)
                supports=[hi[1] for _,lo,hi in near if lo[0]-.015<=x<=hi[0]+.015 and lo[2]-.015<=z<=hi[2]+.015 and y-1.05<=hi[1]<=y+step+.05]
                if not supports:return f'no support at ({x:.1f}, {y:.1f}, {z:.1f})',samples
                foot=max(supports)
                for name,lo,hi in near:
                    if hi[1]<=foot+step+.02 or lo[1]>=foot+height:continue
                    dx=max(lo[0]-x,0,x-hi[0]);dz=max(lo[2]-z,0,z-hi[2])
                    if dx*dx+dz*dz<(radius-.02)**2:
                        return f'{name} obstructs body at ({x:.1f}, {foot:.1f}, {z:.1f})',samples
        return None,samples


def validate(path,manifest,quiet=False):
    tree=ET.parse(path);boxes,parts=geometry(tree)
    assert len(parts)==manifest['parts'],(len(parts),manifest['parts'])
    assert all(p['Anchored'].text=='true' for p in parts)
    assert len(parts)<=5500,'Review part budget before adding more decorative repetition'
    lights=tree.findall('.//Item[@class="PointLight"]')
    assert len(lights)==manifest['lights'] and len(lights)<=96
    assert sum(props(l)['Shadows'].text=='true' for l in lights)<=8
    assert {d['id'] for d in manifest['defenses']}==set(range(1,19))
    assert len(manifest['buildings'])==5
    assert {2,3,4} <= {b['floors'] for b in manifest['buildings']}
    for aperture in manifest['openings']:
        if aperture['kind']=='door':
            assert aperture['end']-aperture['start']>=9.9,aperture
            assert aperture['top']-aperture['bottom']>=9.9,aperture
        elif aperture['kind']=='refugeDoor':
            assert aperture['end']-aperture['start']>=6,aperture
            assert aperture['top']-aperture['bottom']>=9,aperture
        elif aperture['kind']=='ductPortal':
            assert aperture['end']-aperture['start']>=7.19,aperture
            assert aperture['top']-aperture['bottom']>=7.19,aperture
    index=CollisionIndex(boxes);errors=[];total=0
    for route in manifest['routes']:
        error,n=index.sweep(route,manifest['avatar']);total+=n
        if error:errors.append(route['name']+': '+error)
        elif not quiet:print('PASS',route['name'])
    for p in manifest['defenses']:
        assert any(math.dist(p['point'],q)<.15 for r in manifest['routes'] for q in r['points']),p['name']
        error,_=index.sweep({'points':[p['point'],p['point']]},manifest['avatar'])
        if error:errors.append('Defense '+str(p['id'])+': '+error)
    return errors,total


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--place',type=Path)
    parser.add_argument('--binary',type=Path,help='Compare the native Studio binary header with --place XML')
    parser.add_argument('--quiet',action='store_true')
    args=parser.parse_args()
    if args.binary and not args.place:parser.error('--binary requires --place')
    manifest=json.loads((ROOT/'docs/k17-navigation.json').read_text())
    errors,total=validate(ROOT/'src/maps/k17/K17Foundry.rbxmx',manifest,args.quiet)
    if args.place:
        tree=ET.parse(args.place)
        names={x.text for x in tree.findall('.//string[@name="Name"]')}
        assert {'ZO_K17Foundry','HumanSpawn','ZombieSpawn','LobbySpawn','K17Atmosphere','K17Audit'}<=names
        assert {'ZO_Barricades','Barricades','K17_Barricades','K17Barricades','BarricadeAudit'}<=names
        assert {'K17Gameplay','GameplayAudit','WeaponState','RoundRules','ZO_Gameplay','Infect','DamageBarricade'}<=names
        assert {'RefugeAudit','RefugeData','PushBarricade','Physics'}<=names
        assert {r['model'] for r in manifest['refuges']}<=names
        props_model=next(i for i in tree.findall('.//Item[@class="Model"]') if props(i)['Name'].text=='ZO_Barricades')
        catalog=json.loads((ROOT/'src/maps/k17/barricades/catalog.json').read_text())
        assert {props(i)['Name'].text for i in props_model.findall('Item[@class="Model"]')}==set(catalog['Props'])
        assert not {'ZO_SantaAurora','ZO_HarborCollision','HarborLocks_Survival_Visual'}&names
        model=next(i for i in tree.findall('.//Item[@class="Model"]') if props(i)['Name'].text=='ZO_K17Foundry')
        assert len(model.findall('.//Item[@class="Part"]'))==manifest['parts']
        source=ROOT/'src/maps/k17/Config.luau'
        assert 'ZO_K17Foundry' in source.read_text()
        print('PASS compiled place: K-17, authored spawns, audit, lighting; no previous scene')
        if args.binary:
            data=args.binary.read_bytes()
            assert data[:14]==b'<roblox!\x89\xff\r\n\x1a\n','Not a Roblox binary place'
            version,classes,instances=struct.unpack_from('<HII',data,14)
            items=tree.findall('.//Item')
            assert version==0 and classes==len({i.attrib['class'] for i in items})
            assert instances==len(items),(instances,len(items))
            print(f'PASS native binary: {len(data)} bytes, {instances} instances matching XML build')
    if errors:raise SystemExit('\n'.join(errors))
    print(f'PASS K-17: {len(manifest["routes"])} routes, {total} clearance samples, 18 supported defenses, {manifest["parts"]} anchored parts')


if __name__=='__main__':main()
