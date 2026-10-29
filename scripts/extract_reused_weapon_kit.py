#!/usr/bin/env python3
"""Extract real script-free presentation assets from the pinned Roblox kit.

Pass the XML place produced by Rojo from the archived upstream RBXM. The gameplay
uses the original meshes, joints, sounds and animations; no gun mesh is generated.
"""
import argparse
import copy
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
TARGET=ROOT/'src/third_party/roblox-weapon-kit/Arsenal.rbxmx'


def name(item):
    return item.findtext('./Properties/string[@name="Name"]')


def child(parent,label):
    found=[i for i in parent.findall('Item') if name(i)==label]
    assert len(found)==1,(label,len(found))
    return found[0]


def folder(label,referent):
    item=ET.Element('Item',{'class':'Folder','referent':referent})
    ET.SubElement(ET.SubElement(item,'Properties'),'string',{'name':'Name'}).text=label
    return item


def extract(source):
    source=ET.parse(source).getroot()
    upstream=child(child(source,'ServerStorage'),'UpstreamKit')
    assets=child(child(child(upstream,'_PUT_ME_IN_REPLICATED_STORAGE'),'WeaponsSystem'),'Assets')
    tool=copy.deepcopy(child(child(upstream,'_example_weapon'),'AR'))
    assert not any(i.get('class') in ('Script','LocalScript','ModuleScript') for i in tool.iter('Item'))
    tool.find('./Properties/bool[@name="CanBeDropped"]').text='false'
    tool.find('./Properties/string[@name="Name"]').text='Rifle'
    weapon_type=tool.find('Item[@class="StringValue"]')
    if weapon_type is not None and name(weapon_type)=='WeaponType':tool.remove(weapon_type)
    root=ET.Element('roblox',{'version':'4'})
    package=folder('ZO_WeaponAssets','ZO_WeaponAssets');root.append(package)
    weapons=folder('Weapons','ZO_WeaponAssets_Weapons');package.append(weapons)
    weapons.append(tool)
    package.append(copy.deepcopy(child(assets,'Animations')))
    effects=folder('Effects','ZO_WeaponAssets_Effects');package.append(effects)
    shots=child(child(assets,'Effects'),'Shots')
    effects.append(copy.deepcopy(child(child(shots,'Bullet'),'HitEffect')))
    strings=source.find('SharedStrings')
    if strings is not None:root.append(copy.deepcopy(strings))
    assert not any(i.get('class') in ('Script','LocalScript','ModuleScript') for i in root.iter('Item'))
    ET.indent(root,space='  ')
    return ET.tostring(root,encoding='unicode')+'\n'


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('xml',type=Path)
    parser.add_argument('--check',action='store_true')
    args=parser.parse_args()
    data=extract(args.xml)
    if args.check:assert TARGET.read_text(encoding='utf-8')==data,'Extracted kit is stale'
    else:
        TARGET.parent.mkdir(parents=True,exist_ok=True)
        TARGET.write_text(data,encoding='utf-8')
    print('PASS bundled arsenal: original Rifle meshes, animations and used impact effect; no scripts or unused bullet/casing templates')
