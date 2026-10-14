#!/usr/bin/env python3
"""Check actual Roblox map geometry against avatar-sized authored circulation routes.

This is a conservative, static clearance/support check, not Roblox physics or
pathfinding. Studio playtests still determine stair behavior, visuals and balance.
"""
import argparse
import json
import math
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]


def properties(item):
    return {p.attrib['name']:p for p in item.find('Properties')}


def boxes(tree):
    result=[]
    for item in tree.findall('.//Item[@class="Part"]'):
        p=properties(item)
        if p['CanCollide'].text!='true':
            continue
        cf=p['CFrame']
        center=[float(cf.find(axis).text) for axis in 'XYZ']
        size=[float(p['size'].find(axis).text) for axis in 'XYZ']
        # World AABB for rotated roofs. Traversal checks occur below their eaves.
        extent=[sum(abs(float(cf.find(f'R{i}{j}').text))*size[j]/2 for j in range(3)) for i in range(3)]
        result.append((p['Name'].text, [center[i]-extent[i] for i in range(3)], [center[i]+extent[i] for i in range(3)]))
    return result


def check_routes(colliders, routes, avatar):
    failures=[]
    radius,height,step=(avatar[x] for x in ('radius','height','step'))
    for route in routes:
        failed=False
        for a,b in zip(route['points'],route['points'][1:]):
            count=max(1,math.ceil(math.dist(a,b)/.5))
            for i in range(count+1):
                x,y,z=[a[j]+(b[j]-a[j])*i/count for j in range(3)]
                supports=[hi[1] for _,lo,hi in colliders if lo[0]-.01<=x<=hi[0]+.01 and lo[2]-.01<=z<=hi[2]+.01 and y-1.05<=hi[1]<=y+step+.05]
                if not supports:
                    failures.append(f'{route["name"]}: no floor at ({x:.1f}, {y:.1f}, {z:.1f})')
                    failed=True
                    break
                foot=max(supports)
                for name,lo,hi in colliders:
                    if hi[1]<=foot+step+.02 or lo[1]>=foot+height:
                        continue
                    dx=max(lo[0]-x,0,x-hi[0])
                    dz=max(lo[2]-z,0,z-hi[2])
                    if dx*dx+dz*dz < (radius-.02)**2:
                        failures.append(f'{route["name"]}: {name} blocks avatar at ({x:.1f}, {foot:.1f}, {z:.1f})')
                        failed=True
                        break
                if failed:
                    break
            if failed:
                break
        if not failed:
            print('PASS route:',route['name'])
    return failures


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--place',type=Path,help='Also check a current rojo build output.')
    args=parser.parse_args()
    manifest=json.loads((ROOT/'docs/santa-aurora-geometry.json').read_text())
    tree=ET.parse(ROOT/'src/maps/santa-aurora/SantaAurora.rbxmx')
    parts=tree.findall('.//Item[@class="Part"]')
    assert len(parts)==len(manifest['parts'])
    assert len(parts)<1600, 'Review geometry budget before expanding the district'
    assert all(properties(part)['Anchored'].text=='true' for part in parts)
    assert len(tree.findall('.//Item[@class="PointLight"]'))<=24
    assert sum(properties(light)['Shadows'].text=='true' for light in tree.findall('.//Item[@class="PointLight"]'))<=6
    for portal in manifest['portals']:
        if portal['kind']=='door':
            assert portal['end']-portal['start']>=8, portal['name']
            assert portal['top']-portal['bottom']>=10, portal['name']
    failures=check_routes(boxes(tree),manifest['routes'],manifest['avatar'])
    if args.place:
        place=ET.parse(args.place)
        names={p.text for p in place.findall('.//string[@name="Name"]')}
        assert {'ZO_SantaAurora','HumanSpawn','ZombieSpawn','LobbySpawn','DistrictAtmosphere','MapConfig'}<=names
        assert not {'ZO_HarborCollision','HarborLocks_Survival_Visual'} & names
        map_item=next(i for i in place.findall('.//Item[@class="Model"]') if properties(i)['Name'].text=='ZO_SantaAurora')
        assert len(map_item.findall('.//Item[@class="Part"]'))==len(parts)
        scripts=place.findall('.//Item[@class="Script"]')+place.findall('.//Item[@class="LocalScript"]')+place.findall('.//Item[@class="ModuleScript"]')
        assert len(scripts)==11, f'Unexpected script count: {len(scripts)}'
        print('PASS compiled place: full map, 11 scripts, authored spawns, lighting; no legacy Harbor map')
    if failures:
        raise SystemExit('\n'.join(failures))
    print(f'PASS static map checks: {len(parts)} anchored parts; {len(manifest["routes"])} supported routes; avatar radius 1.5, height 5.5 studs')


if __name__=='__main__':
    main()
