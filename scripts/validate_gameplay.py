#!/usr/bin/env python3
"""Verify the built Rojo profile serves the intended controllers, not the legacy ones.

This checks build integration/source identity; it does not execute Roblox APIs.
"""
import argparse
import hashlib
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


def validate(path,studio_test=False):
    root=ET.parse(path).getroot()
    bindings={
        'ServerScriptService/ZO_Server/ZombieRound':'src/maps/k17/gameplay/Round.server.luau',
        'ServerScriptService/ZO_Server/Startup':'src/maps/k17/gameplay/Startup.server.luau',
        'ServerScriptService/ZO_Server/Combat':'src/maps/k17/gameplay/Combat.server.luau',
        'ServerScriptService/ZO_Server/EquipmentVisuals':'src/maps/k17/gameplay/EquipmentVisuals.server.luau',
        'ServerScriptService/ZO_Server/WeaponAssets':'src/maps/k17/gameplay/WeaponAssets.server.luau',
        'ServerScriptService/ZO_Server/WeaponAssetImport':'src/maps/k17/gameplay/WeaponAssetImport.luau',
        'StarterPlayer/StarterPlayerScripts/ZO_Client/Weapons':'src/maps/k17/gameplay/Weapons.client.luau',
        'StarterPlayer/StarterPlayerScripts/ZO_Client/RoundHUD':'src/maps/k17/gameplay/HUD.client.luau',
        'StarterPlayer/StarterPlayerScripts/ZO_Client/TacticalMap':'src/maps/k17/gameplay/TacticalMap.client.luau',
        'StarterPlayer/StarterPlayerScripts/ZO_Client/Loadout':'src/maps/k17/gameplay/Loadout.client.luau',
        'ReplicatedStorage/K17Refuges':'src/maps/k17/Refuges.luau',
        'ServerStorage/ZO_Validation/GameplayAudit':'tests/k17/GameplayAudit.luau',
        'ServerStorage/ZO_Validation/BarricadeAudit':'tests/k17/BarricadeAudit.luau',
        'ServerStorage/ZO_Validation/RefugeAudit':'tests/k17/RefugeAudit.luau',
        'ServerStorage/ZO_Validation/RefugeData':'src/maps/k17/Refuges.luau',
        'ServerScriptService/ZO_Server/Barricades':'src/maps/k17/barricades/Server.server.luau',
        **{'ReplicatedStorage/K17Barricades/'+name:'src/maps/k17/barricades/'+name+'.luau' for name in ('Config','Physics')},
        **{'ReplicatedStorage/K17Gameplay/'+name:'src/maps/k17/gameplay/'+name+'.luau' for name in ('Config','Rules','WeaponState','RoundRules','LoadoutState','Containment','WeaponPresentation','PresentationConfig','WeaponPreview')},
    }
    for instance_path,source_path in bindings.items():
        item=at(root,instance_path)
        expected='Script' if source_path.endswith('.server.luau') else 'LocalScript' if source_path.endswith('.client.luau') else 'ModuleScript'
        assert item.attrib['class']==expected,(instance_path,item.attrib['class'],expected)
        source=item.findtext('./Properties/*[@name="Source"]')
        assert source is not None and source.replace('\r\n','\n')==(ROOT/source_path).read_text(),instance_path
    driver_paths={
        'ServerScriptService/ZO_StudioSurvivalScenario':'tests/studio/SurvivalScenario.server.luau',
        'StarterPlayer/StarterPlayerScripts/ZO_StudioSurvivalDriver':'tests/studio/SurvivalDriver.client.luau',
    }
    if studio_test:
        for instance_path,source_path in {**driver_paths,
            'ReplicatedStorage/Shared/RoundConfig':'tests/studio/RoundConfig.luau',
            'ReplicatedStorage/Shared/ProductionRoundConfig':'src/maps/k17/RoundConfig.luau',
        }.items():
            assert at(root,instance_path).findtext('./Properties/*[@name="Source"]')==(ROOT/source_path).read_text(),instance_path
    else:
        names={item.findtext('./Properties/string[@name="Name"]') for item in root.iter('Item')}
        assert not {path.rsplit('/',1)[-1] for path in driver_paths}&names,'Test drivers in production profile'
        assert at(root,'ReplicatedStorage/Shared/RoundConfig').findtext('./Properties/*[@name="Source"]')==(ROOT/'src/maps/k17/RoundConfig.luau').read_text(),'Short test rounds in production profile'
    for name in ('Infect','DamageBarricade','PushBarricade'):
        assert at(root,'ServerStorage/ZO_Gameplay/'+name).attrib['class']=='BindableFunction'
    # Legacy files were removed after backup; keep rejecting their exact sources
    # if an old controller is accidentally imported into a generated place.
    legacy={
        'bd184a96e6d3ee24719e571927c301159b4943334e5eb8c424dbb1f6e00a44ab',
        '06e753907bf0a81a1732417890c16651b8365ca7d1bfbe26c912c50e72b59dfa',
        'eb7bc279b165d9a4c6a702914d74c6059322e426bd7aa3a1d28e686b292538bb',
    }
    sources=[p.text or '' for p in root.findall('.//Properties/*[@name="Source"]')]
    assert not any(hashlib.sha256(s.encode()).hexdigest() in legacy for s in sources),'A legacy controller is still loaded in K-17'
    assert sum(s==(ROOT/'src/maps/k17/gameplay/Combat.server.luau').read_text() for s in sources)==1
    assert sum(s==(ROOT/'src/maps/k17/gameplay/Round.server.luau').read_text() for s in sources)==1
    print(f'PASS classic profile: {len(bindings)} exact source bindings, three private server functions, one round/combat controller, no legacy proximity/rifle controllers')
    print('PASS isolated Studio validation drivers and test config' if studio_test else 'PASS production round config; no automated test drivers')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--place',required=True,type=Path)
    parser.add_argument('--studio-test',action='store_true',help='Verify the isolated Studio validation profile')
    args=parser.parse_args();validate(args.place,args.studio_test)
