#!/usr/bin/env python3
"""Verify the built Rojo profile serves the intended controllers, not the legacy ones.

This checks build integration/source identity; it does not execute Roblox APIs.
"""
import argparse
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]


def named(parent,name):
    matches=[i for i in parent.findall('Item') if i.findtext('./Properties/string[@name="Name"]')==name]
    assert len(matches)==1,(name,len(matches))
    return matches[0]


def at(root,path):
    for name in path.split('/'):
        root=named(root,name)
    return root


def validate(path):
    root=ET.parse(path).getroot()
    bindings={
        'ServerScriptService/ZO_Server/ZombieRound':'src/maps/k17/gameplay/Round.server.luau',
        'ServerScriptService/ZO_Server/Startup':'src/maps/k17/gameplay/Startup.server.luau',
        'ServerScriptService/ZO_Server/Combat':'src/maps/k17/gameplay/Combat.server.luau',
        'StarterPlayer/StarterPlayerScripts/ZO_Client/Weapons':'src/maps/k17/gameplay/Weapons.client.luau',
        'StarterPlayer/StarterPlayerScripts/ZO_Client/RoundHUD':'src/maps/k17/gameplay/HUD.client.luau',
        'ServerStorage/ZO_Validation/GameplayAudit':'tests/k17/GameplayAudit.luau',
        'ServerStorage/ZO_Validation/RefugeAudit':'tests/k17/RefugeAudit.luau',
        'ServerStorage/ZO_Validation/RefugeData':'src/maps/k17/Refuges.luau',
        'ServerScriptService/ZO_Server/Barricades':'src/maps/k17/barricades/Server.server.luau',
        **{'ReplicatedStorage/K17Barricades/'+name:'src/maps/k17/barricades/'+name+'.luau' for name in ('Config','Physics')},
        **{'ReplicatedStorage/K17Gameplay/'+name:'src/maps/k17/gameplay/'+name+'.luau' for name in ('Config','Rules','WeaponState','RoundRules')},
    }
    for instance_path,source_path in bindings.items():
        item=at(root,instance_path)
        expected='Script' if source_path.endswith('.server.luau') else 'LocalScript' if source_path.endswith('.client.luau') else 'ModuleScript'
        assert item.attrib['class']==expected,(instance_path,item.attrib['class'],expected)
        source=item.findtext('./Properties/*[@name="Source"]')
        assert source is not None and source.replace('\r\n','\n')==(ROOT/source_path).read_text(),instance_path
    for name in ('Infect','DamageBarricade','PushBarricade'):
        assert at(root,'ServerStorage/ZO_Gameplay/'+name).attrib['class']=='BindableFunction'
    legacy={(ROOT/p).read_text() for p in ('src/server/ZombieRound.server.luau','src/server/Combat.server.luau','src/client/Rifle.client.luau')}
    sources=[p.text or '' for p in root.findall('.//Properties/*[@name="Source"]')]
    assert not any(s in legacy for s in sources),'A legacy controller is still loaded in K-17'
    assert sum(s==(ROOT/'src/maps/k17/gameplay/Combat.server.luau').read_text() for s in sources)==1
    assert sum(s==(ROOT/'src/maps/k17/gameplay/Round.server.luau').read_text() for s in sources)==1
    print(f'PASS classic profile: {len(bindings)} exact source bindings, three private server functions, one round/combat controller, no legacy proximity/rifle controllers')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--place',required=True,type=Path)
    validate(parser.parse_args().place)
