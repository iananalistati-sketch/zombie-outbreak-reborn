#!/usr/bin/env python3
"""Check group occupancy and firing lines against the authored geometry, with props."""
import json
import math
from pathlib import Path
import xml.etree.ElementTree as ET
from validate_k17 import CollisionIndex, geometry

ROOT=Path(__file__).resolve().parents[1]


def ray_blocker(a,b,boxes):
    # Exact slab intersection for the axis-aligned solid boxes used in these rooms.
    for name,lo,hi in boxes:
        begin,end=0.,1.
        for i in range(3):
            delta=b[i]-a[i]
            if abs(delta)<1e-9:
                if not lo[i]<a[i]<hi[i]:begin,end=1,0;break
            else:
                u,v=sorted(((lo[i]-a[i])/delta,(hi[i]-a[i])/delta))
                begin,end=max(begin,u),min(end,v)
        if begin<end and end>1e-5 and begin<1-1e-5:return name
    return None


def validate(data,boxes):
    errors=[];index=CollisionIndex(boxes)
    assert {r['id'] for r in data['refuges']}=={2,7,10,14,15,16,17,18}|set(range(19,35))|set(range(40,50))
    assert len(data['barricades'])>=164
    for r in data['refuges']:
        prefix=f'Refuge {r["id"]}'
        capacity=r.get('capacity',4)
        assert capacity>=2 and len(r['approaches'])>=1 and len(r['stands'])>=capacity
        if r['id']>=19:
            minimum=2 if r['id'] in (48,49) else 5
            assert len(r['props'])>=minimum and 'hidden' in r,r['id']
            assert sum(p['Refuge']==r['id'] for p in data['barricades'].values())>=minimum
            a,b=r['hidden'];eye=lambda p:[p[0],p[1]+5.5,p[2]]
            if ray_blocker(eye(a),eye(b),boxes) is None:errors.append(prefix+': protected bay exposed to entry')
            p=r['hold']
            if ray_blocker([p[0],p[1]+6,p[2]],[p[0],p[1]+15,p[2]],boxes) is None:errors.append(prefix+': no overhead cover')
        for name,points in r['approaches']:
            assert math.dist(points[-1],r['hold'])<.01
            error,_=index.sweep({'points':points},data['avatar'])
            if error:errors.append(name+': '+error)
        for i,p in enumerate(r['stands']):
            error,_=index.sweep({'points':[p,p]},data['avatar'])
            if error:errors.append(prefix+f' position {i}: '+error)
            assert all(math.dist(p,q)>=3 for q in r['stands'][i+1:])
        view=r['view'];spawn=[view[0],view[1]-3,view[2]]
        error,_=index.sweep({'points':[spawn,spawn]},data['avatar'])
        if error:errors.append(prefix+' tour spawn: '+error)
        for i,(a,b) in enumerate(r['sights']):
            eye=lambda p:[p[0],p[1]+5.5,p[2]]
            blocker=ray_blocker(eye(a),eye(b),boxes)
            if blocker:errors.append(prefix+f' firing line {i}: '+blocker)
    assert len(data['ducts'])==4
    for duct in data['ducts']:
        error,_=index.sweep({'points':duct['points']},data['avatar'])
        if error:errors.append(duct['name']+': '+error)
        a,b=duct['hidden'];eye=lambda p:[p[0],p[1]+5.5,p[2]]
        if ray_blocker(eye(a),eye(b),boxes) is None:errors.append(duct['name']+': bend does not break sight')
    return errors


if __name__=='__main__':
    data=json.loads((ROOT/'docs/k17-navigation.json').read_text())
    boxes=geometry(ET.parse(ROOT/'src/maps/k17/K17Foundry.rbxmx'))[0]
    boxes+=geometry(ET.parse(ROOT/'src/maps/k17/barricades/Stockroom.rbxmx'))[0]
    errors=validate(data,boxes)
    if errors:raise SystemExit('\n'.join(errors))
    print(f'PASS {len(data["refuges"])} refuges, {sum(len(r["stands"]) for r in data["refuges"])} group positions, {len(data["barricades"])} props, four bent ducts and protected bays')
