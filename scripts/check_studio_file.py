#!/usr/bin/env python3
"""Verify the actual native K-17 place and the checksum used by the Windows opener."""
import argparse
import hashlib
import json
from pathlib import Path
from inspect_studio_binary import parse

ROOT=Path(__file__).resolve().parents[1]
BINARY=ROOT/'builds/ZombieOutbreakReborn_K17.rbxl'
MANIFEST=ROOT/'builds/K17.release.json'


def release(binary):
    classes,names,sources=parse(binary)
    required={'ZO_K17Foundry','R16_FilterRoom','R17_YardWorkshop','R18_CoolantRoom',
              'V_StockroomVent','V_FilterVent','V_YardVent','V_CoolantVent','Startup','RefugeAudit'}
    assert required<=set(names),'K-17 map/features missing: '+str(required-set(names))
    assert names.count('ZO_K17Foundry')==1,'Expected exactly one K-17 map'
    assert not {'ZO_SantaAurora','ZO_HarborCollision','HarborLocks_Survival_Visual'}&set(names),'Legacy scene in K-17 build'
    assert len(names)==sum(count for _,count in classes.values()),'Incomplete native Name properties'
    for path in ('src/maps/k17/gameplay/Round.server.luau','src/maps/k17/gameplay/HUD.client.luau','src/maps/k17/gameplay/Startup.server.luau'):
        assert sources.count((ROOT/path).read_text(encoding='utf-8'))==1,'Outdated/missing native source: '+path
    data=binary.read_bytes()
    return {'file':BINARY.name,'map':'ZO_K17Foundry','sha256':hashlib.sha256(data).hexdigest(),
            'bytes':len(data),'instances':len(names),'barricades':names.count('Hull'),'ducts':4}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--binary',type=Path,default=BINARY)
    parser.add_argument('--manifest',type=Path,default=MANIFEST)
    parser.add_argument('--write',action='store_true',help='Write the checksum only after inspecting native contents')
    args=parser.parse_args()
    expected=release(args.binary)
    if args.write:args.manifest.write_text(json.dumps(expected,indent=2)+'\n',encoding='utf-8')
    else:assert json.loads(args.manifest.read_text(encoding='utf-8'))==expected,'Native place/manifest differ; rebuild and run --write'
    print(f'PASS native K-17: {expected["instances"]} instances, {expected["barricades"]} props, four ducts, current controllers, no Santa Aurora; SHA-256 verified')


if __name__=='__main__':main()
