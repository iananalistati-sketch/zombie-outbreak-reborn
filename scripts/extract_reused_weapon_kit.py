#!/usr/bin/env python3
"""Extract real script-free presentation assets from the pinned Roblox kit.

Pass the XML place produced by Rojo from the archived upstream RBXM. The gameplay
uses the original meshes, joints, sounds and animations; no gun mesh is generated.
"""
import argparse
import base64
import copy
import hashlib
from pathlib import Path
import struct
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
TARGET=ROOT/'src/third_party/roblox-weapon-kit/Arsenal.rbxmx'
PISTOL_VARIANTS={
    'Black':('OriginalPistol2.rbxmx','Pistol2','704f204cd3eb51a361c449f8718dd30b10869e7dcc823a1d186598176f89993e'),
    'Classic':('OriginalPistol.rbxmx','Pistol','9a0adb1e26e6fa15f0a46f04e24900b11d3fe9cfdf00e226e766b5e66202a16f'),
    'Gold':('OriginalPistol3.rbxmx','Pistol3','4ed7e278a77756ab82ea0c374f055f12f0cc229cb8b7ed9ff711bc9401c14ad8'),
}
EXECUTABLE={'Script','LocalScript','ModuleScript','RemoteEvent','UnreliableRemoteEvent',
            'RemoteFunction','BindableEvent','BindableFunction','PackageLink'}
PARTS={'Part','MeshPart','UnionOperation','WedgePart','CornerWedgePart'}


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


def boolean(item,label,value):
    properties=item.find('Properties')
    prop=properties.find(f'bool[@name="{label}"]')
    if prop is None:prop=ET.SubElement(properties,'bool',{'name':label})
    prop.text='true' if value else 'false'


def visual_only(tool):
    for item in tool.iter('Item'):
        tags=item.find('./Properties/BinaryString[@name="Tags"]')
        if tags is not None:tags.text=None
        if item.get('class') in PARTS:
            for label,value in {'Anchored':False,'Massless':True,'CanCollide':False,'CanQuery':False,'CanTouch':False}.items():
                boolean(item,label,value)
        if item.get('class')=='Sound':
            boolean(item,'Playing',False);boolean(item,'PlayOnRemove',False)
    for label,value in {'CanBeDropped':False,'Enabled':False,'ManualActivationOnly':True}.items():boolean(tool,label,value)


def string_attributes(item,values):
    """Encode native string attributes (the same binary format emitted by Rojo)."""
    prop=item.find('./Properties/BinaryString[@name="AttributesSerialize"]')
    if prop is None:prop=ET.SubElement(item.find('Properties'),'BinaryString',{'name':'AttributesSerialize'})
    assert not prop.text,'Preserve and review existing attributes before replacing them'
    def string(value):
        data=value.encode('utf-8')
        return struct.pack('<I',len(data))+data
    data=struct.pack('<I',len(values))
    for key,value in sorted(values.items()):data+=string(key)+b'\x02'+string(value)
    prop.text=base64.b64encode(data).decode('ascii')


def pistol(variant='Black'):
    """Extract a pinned official variant without its competing WeaponsSystem."""
    filename,original,sha256=PISTOL_VARIANTS[variant]
    path=ROOT/'third_party/roblox-weapon-kit/pistol'/filename
    assert hashlib.sha256(path.read_bytes()).hexdigest()==sha256,'Pistol source changed; review before extracting'
    source=ET.parse(path).getroot()
    tool=copy.deepcopy(child(source,original))
    assert tool.get('class')=='Tool'
    assert tool.findtext('./Properties/int64[@name="SourceAssetId"]')=='118912302094201'
    tool.find('./Properties/string[@name="Name"]').text='Pistol' if variant=='Black' else variant
    if variant!='Black':string_attributes(tool,{'ZO_WeaponId':'Pistol','ZO_SkinId':variant})

    def clean(item):
        for descendant in list(item.findall('Item')):
            if descendant.get('class') in EXECUTABLE or name(descendant) in ('WeaponsSystem','WeaponType'):
                item.remove(descendant)
            else:clean(descendant)

    clean(tool)
    visual_only(tool)
    # Referents from the independently saved place may overlap those of the AR.
    # Map only retained objects; references into removed controllers become null.
    prefix='Pistol_' if variant=='Black' else 'Pistol'+variant+'_'
    mapping={item.get('referent'):prefix+item.get('referent') for item in tool.iter('Item')}
    for item in tool.iter('Item'):
        item.set('referent',mapping[item.get('referent')])
        for reference in item.findall('./Properties/Ref'):
            reference.text=mapping.get(reference.text,'null')
    return tool,source


def merge_shared_strings(root,sources):
    needed={prop.text for prop in root.findall('.//Properties/SharedString')}
    strings={}
    for source in sources:
        for item in source.findall('./SharedStrings/SharedString'):
            key=item.get('md5')
            if key in strings:assert (strings[key].text or '')==(item.text or ''),'Conflicting shared string'
            else:strings[key]=item
    assert needed<=strings.keys(),'Missing retained mesh data'
    if needed:
        target=ET.SubElement(root,'SharedStrings')
        for key in sorted(needed):target.append(copy.deepcopy(strings[key]))


def extract(source):
    source=ET.parse(source).getroot()
    upstream=child(child(source,'ServerStorage'),'UpstreamKit')
    assets=child(child(child(upstream,'_PUT_ME_IN_REPLICATED_STORAGE'),'WeaponsSystem'),'Assets')
    tool=copy.deepcopy(child(child(upstream,'_example_weapon'),'AR'))
    assert not any(i.get('class') in ('Script','LocalScript','ModuleScript') for i in tool.iter('Item'))
    tool.find('./Properties/bool[@name="CanBeDropped"]').text='false'
    tool.find('./Properties/string[@name="Name"]').text='Rifle'
    visual_only(tool)
    weapon_type=tool.find('Item[@class="StringValue"]')
    if weapon_type is not None and name(weapon_type)=='WeaponType':tool.remove(weapon_type)
    root=ET.Element('roblox',{'version':'4'})
    package=folder('ZO_WeaponAssets','ZO_WeaponAssets');root.append(package)
    weapons=folder('Weapons','ZO_WeaponAssets_Weapons');package.append(weapons)
    weapons.append(tool)
    pistol_tool,pistol_source=pistol()
    weapons.append(pistol_tool)
    skins=folder('Skins','ZO_WeaponAssets_Skins');package.append(skins)
    pistol_skins=folder('Pistol','ZO_WeaponAssets_Skins_Pistol');skins.append(pistol_skins)
    skin_sources=[]
    for variant in ('Classic','Gold'):
        skin_tool,skin_source=pistol(variant)
        pistol_skins.append(skin_tool);skin_sources.append(skin_source)
    package.append(copy.deepcopy(child(assets,'Animations')))
    effects=folder('Effects','ZO_WeaponAssets_Effects');package.append(effects)
    shots=child(child(assets,'Effects'),'Shots')
    hit_effect=copy.deepcopy(child(child(shots,'Bullet'),'HitEffect'))
    # Studio confirmed this archived sound cannot load (even at volume zero).
    # Keep the original particle effect and working gun audio; do not substitute
    # an unverified ID or mutate the preserved upstream archive.
    hit_sound=child(hit_effect,'HitSound')
    assert hit_sound.get('class')=='Sound'
    assert hit_sound.findtext('./Properties/Content[@name="AudioContent"]/uri')=='rbxassetid://1489924400'
    hit_effect.remove(hit_sound)
    effects.append(hit_effect)
    merge_shared_strings(root,[source,pistol_source,*skin_sources])
    assert not any(i.get('class') in EXECUTABLE for i in root.iter('Item'))
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
    print('PASS bundled assets: Rifle and black Pistol, official Classic/Gold pistol skins, shared animations and impact particles; no archived impact sound or executable templates')
