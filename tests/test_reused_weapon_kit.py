"""Check the actual reused native assets and their integration contract."""
import base64
import hashlib
import json
from pathlib import Path
import struct
import unittest
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]


class ReusedWeaponKit(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tree=ET.parse(ROOT/'src/third_party/roblox-weapon-kit/Arsenal.rbxmx')
        cls.items=cls.tree.findall('.//Item')
        cls.named={i.findtext('./Properties/string[@name="Name"]'):i for i in cls.items}
        cls.tools={i.findtext('./Properties/string[@name="Name"]'):i for i in cls.items if i.get('class')=='Tool'}
        cls.rifle_named={i.findtext('./Properties/string[@name="Name"]'):i for i in cls.tools['Rifle'].iter('Item')}
        cls.pistol_named={i.findtext('./Properties/string[@name="Name"]'):i for i in cls.tools['Pistol'].iter('Item')}

    def test_archive_identity_and_both_licenses_are_retained(self):
        folder=ROOT/'third_party/roblox-weapon-kit'
        source=json.loads((folder/'SOURCE.json').read_text())
        self.assertEqual(hashlib.sha256((folder/source['file']).read_bytes()).hexdigest(),source['sha256'])
        self.assertIn('Copyright (c) 2025 JustATortoise',(folder/'MIT-FIX-LICENSE.txt').read_text())
        self.assertIn('LIMITED USE LICENSE',(folder/'ROBLOX-LIMITED-USE-LICENSE.md').read_text())

    def test_runtime_templates_cannot_start_another_combat_system(self):
        executable={'Script','LocalScript','ModuleScript','RemoteEvent','RemoteFunction','UnreliableRemoteEvent',
                    'BindableEvent','BindableFunction','PackageLink'}
        self.assertFalse(any(i.get('class') in executable for i in self.items))
        self.assertEqual(set(self.tools),{'Rifle','Pistol','SMG','Shotgun','Classic','Gold','Bronze','White','Sand','Silver'})
        weapons=next(i for i in self.tree.find('Item').findall('Item') if i.findtext('./Properties/string[@name="Name"]')=='Weapons')
        self.assertEqual({i.findtext('./Properties/string[@name="Name"]') for i in weapons.findall('Item')},{'Rifle','Pistol','SMG','Shotgun'})
        for tool in self.tools.values():
            self.assertEqual(tool.findtext('./Properties/bool[@name="CanBeDropped"]'),'false')
            self.assertEqual(tool.findtext('./Properties/bool[@name="Enabled"]'),'false')
            self.assertEqual(tool.findtext('./Properties/bool[@name="ManualActivationOnly"]'),'true')
        self.assertNotIn('WeaponsSystem',self.named)
        self.assertNotIn('WeaponType',self.named)
        self.assertNotIn('RifleCasing',self.named)
        self.assertNotIn('Bullet',self.named)

    def test_rifle_is_a_real_mesh_with_its_original_sounds_and_joints(self):
        expected={'Rifle':'2492890820','Magazine':'2492891824','Bolt':'2492892116'}
        for name,asset in expected.items():
            item=self.rifle_named[name]
            self.assertEqual(item.get('class'),'MeshPart')
            self.assertIn(asset,item.findtext('./Properties/Content[@name="MeshContent"]/uri'))
        self.assertEqual(self.rifle_named['Fired'].findtext('./Properties/Content[@name="AudioContent"]/uri'),'rbxassetid://3806349898')
        self.assertEqual(self.rifle_named['Reload'].findtext('./Properties/Content[@name="AudioContent"]/uri'),'rbxassetid://3821787597')
        for name in ('HandleAttachment','TipAttachment','CasingEjectPoint','MuzzleFlash','BoltMotor','BoltMotorStart','BoltMotorTarget'):
            self.assertIn(name,self.rifle_named)
        self.assertEqual(self.rifle_named['MuzzleFlash'].get('class'),'Beam')
        self.assertEqual(self.rifle_named['BoltMotor'].get('class'),'Motor6D')
        references={i.get('referent') for i in self.items}
        for item in self.items:
            for ref in item.findall('./Properties/Ref'):
                self.assertTrue(ref.text=='null' or ref.text in references,(item.get('class'),ref.get('name'),ref.text))

    def test_uploaded_pistol_archive_is_pinned_and_keeps_reviewable_sources(self):
        expected={
            'Pistol':('OriginalPistol.rbxmx','9a0adb1e26e6fa15f0a46f04e24900b11d3fe9cfdf00e226e766b5e66202a16f'),
            'Pistol2':('OriginalPistol2.rbxmx','704f204cd3eb51a361c449f8718dd30b10869e7dcc823a1d186598176f89993e'),
            'Pistol3':('OriginalPistol3.rbxmx','4ed7e278a77756ab82ea0c374f055f12f0cc229cb8b7ed9ff711bc9401c14ad8'),
        }
        script_sources=[]
        for original,(filename,sha256) in expected.items():
            path=ROOT/'third_party/roblox-weapon-kit/pistol'/filename
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),sha256)
            archive=ET.parse(path)
            tool=archive.find('Item')
            self.assertEqual(tool.get('class'),'Tool')
            self.assertEqual(tool.findtext('./Properties/string[@name="Name"]'),original)
            self.assertEqual(tool.findtext('./Properties/int64[@name="SourceAssetId"]'),'118912302094201')
            scripts=[i for i in archive.findall('.//Item') if i.get('class') in ('Script','LocalScript','ModuleScript')]
            self.assertEqual(len(scripts),16)
            sources={i.findtext('./Properties/string[@name="Name"]'):i.findtext('./Properties/*[@name="Source"]') for i in scripts}
            self.assertEqual(len(sources),16)
            self.assertTrue(all(sources.values()),'Original sources must remain present as review data')
            script_sources.append(sources)
            available={i.get('md5') for i in archive.findall('./SharedStrings/SharedString')}
            self.assertEqual({p.text for p in archive.findall('.//Properties/SharedString')},available)
        self.assertEqual(script_sources[0],script_sources[1])
        self.assertEqual(script_sources[1],script_sources[2])

    def test_black_pistol_uses_the_actual_uploaded_mesh_texture_audio_and_grip(self):
        expected={
            'Pistol':('2492922600','3361038943'),
            'Bolt':('2492923497','3361041283'),
            'Magazine':('2492925447','3361041283'),
        }
        self.assertEqual(sum(i.get('class')=='MeshPart' for i in self.items),24)
        for name,(mesh,texture) in expected.items():
            item=self.pistol_named[name]
            self.assertEqual(item.get('class'),'MeshPart')
            self.assertEqual(item.findtext('./Properties/Content[@name="MeshContent"]/uri'),'rbxassetid://'+mesh)
            self.assertEqual(item.findtext('./Properties/Content[@name="TextureContent"]/uri'),'rbxassetid://'+texture)
        self.assertEqual(self.pistol_named['Fired'].findtext('./Properties/Content[@name="AudioContent"]/uri'),'rbxassetid://3806566911')
        self.assertEqual(self.pistol_named['Reload'].findtext('./Properties/Content[@name="AudioContent"]/uri'),'rbxassetid://3821789416')
        self.assertEqual(self.tools['Pistol'].findtext('./Properties/int64[@name="SourceAssetId"]'),'118912302094201')
        grip=self.pistol_named['HandleAttachment']
        self.assertEqual(grip.findtext('./Properties/CoordinateFrame[@name="CFrame"]/Y'),'-0.2')
        self.assertEqual(grip.findtext('./Properties/CoordinateFrame[@name="CFrame"]/R00'),'-1')
        self.assertEqual(self.pistol_named['MuzzleFlash'].get('class'),'Beam')
        self.assertEqual(self.pistol_named['BoltMotor'].get('class'),'Motor6D')

    def test_classic_and_gold_are_native_cosmetic_variants_of_the_same_pistol(self):
        package=self.tree.find('Item')
        skins=next(i for i in package.findall('Item') if i.findtext('./Properties/string[@name="Name"]')=='Skins')
        pistol=skins.find('Item')
        self.assertEqual(pistol.findtext('./Properties/string[@name="Name"]'),'Pistol')
        self.assertEqual({i.findtext('./Properties/string[@name="Name"]') for i in pistol.findall('Item')},{'Classic','Gold'})
        expected={
            'Classic':{'Pistol':'2492931263','Bolt':'2492931686','Magazine':None},
            'Gold':{'Pistol':'3361055083','Bolt':'3361057436','Magazine':'3361057436'},
        }
        for variant,textures in expected.items():
            tool=self.tools[variant]
            named={i.findtext('./Properties/string[@name="Name"]'):i for i in tool.iter('Item')}
            self.assertEqual(sum(i.get('class')=='MeshPart' for i in tool.iter('Item')),3)
            for name,texture in textures.items():
                self.assertEqual(named[name].findtext('./Properties/Content[@name="MeshContent"]/uri'),
                                 self.pistol_named[name].findtext('./Properties/Content[@name="MeshContent"]/uri'))
                self.assertEqual(named[name].findtext('./Properties/Content[@name="TextureContent"]/uri'),
                                 'rbxassetid://'+texture if texture else None)
                if texture is None:self.assertIsNotNone(named[name].find('./Properties/Content[@name="TextureContent"]/null'))
            for name in ('Fired','Reload'):
                self.assertEqual(named[name].findtext('./Properties/Content[@name="AudioContent"]/uri'),
                                 self.pistol_named[name].findtext('./Properties/Content[@name="AudioContent"]/uri'))
            def grip_values(item):
                return {p.tag:p.text for p in item.find('./Properties/CoordinateFrame[@name="CFrame"]')}
            self.assertEqual(grip_values(named['HandleAttachment']),grip_values(self.pistol_named['HandleAttachment']))
            data=base64.b64decode(tool.findtext('./Properties/BinaryString[@name="AttributesSerialize"]'))
            count=struct.unpack_from('<I',data)[0];offset=4;attributes={}
            def read_string():
                nonlocal offset
                size=struct.unpack_from('<I',data,offset)[0];offset+=4
                value=data[offset:offset+size].decode('utf-8');offset+=size
                return value
            for _ in range(count):
                key=read_string();self.assertEqual(data[offset],2);offset+=1
                attributes[key]=read_string()
            self.assertEqual(offset,len(data))
            self.assertEqual(attributes,{'ZO_WeaponId':'Pistol','ZO_SkinId':variant})
            # Source Configuration includes presentation tuning; the cosmetic
            # template does not introduce any different weapon values.
            def values(item):
                config=item.find('Item[@class="Configuration"]')
                return {i.findtext('./Properties/string[@name="Name"]'):i.findtext('./Properties/*[@name="Value"]') for i in config.findall('Item')}
            self.assertEqual(values(tool),values(self.tools['Pistol']))

    def test_combined_templates_have_resolved_unique_references_and_no_physical_contacts(self):
        referents=[i.get('referent') for i in self.items]
        self.assertEqual(len(referents),len(set(referents)))
        available=set(referents)
        strings={x.get('md5') for x in self.tree.findall('./SharedStrings/SharedString')}
        for item in self.items:
            for ref in item.findall('./Properties/Ref'):
                self.assertIn(ref.text,available|{'null'})
            for ref in item.findall('./Properties/SharedString'):
                self.assertIn(ref.text,strings)
            if item.get('class') in ('Part','MeshPart'):
                for prop in ('Anchored','CanCollide','CanQuery','CanTouch'):
                    self.assertEqual(item.findtext(f'./Properties/bool[@name="{prop}"]'),'false')
                self.assertEqual(item.findtext('./Properties/bool[@name="Massless"]'),'true')

    def test_official_native_prefabs_are_pinned_and_contain_only_already_reviewed_sources(self):
        from scripts.inspect_studio_binary import parse
        folder=ROOT/'third_party/roblox-weapon-kit/official-prefabs'
        records=json.loads((folder/'SOURCE.json').read_text())
        reviewed=ET.parse(ROOT/'third_party/roblox-weapon-kit/pistol/OriginalPistol2.rbxmx')
        source_texts={i.findtext('./Properties/*[@name="Source"]') for i in reviewed.findall('.//Item')
                      if i.get('class') in ('Script','LocalScript','ModuleScript')}
        self.assertEqual(set(records),{'SMG','Shotgun'})
        for weapon,record in records.items():
            path=folder/record['file']
            self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),record['sha256'])
            self.assertEqual(path.stat().st_size,record['bytes'])
            classes,_,sources=parse(path)
            self.assertEqual(sum(count for kind,count in classes.values() if kind=='Tool'),3)
            self.assertEqual(len(sources),48)
            # XML normalizes CRLF. Compare complete normalized bodies without
            # dumping thousands of source lines on an audit failure.
            def digest(source):return hashlib.sha256(source.replace('\r\n','\n').encode()).hexdigest()
            self.assertEqual({digest(s) for s in sources},{digest(s) for s in source_texts},
                             'New executable sources require a fresh review')
            metadata=json.loads((folder/(weapon+'.metadata.json')).read_text())
            self.assertEqual(metadata['Creator']['Name'],'Roblox Resources')
            self.assertTrue(metadata['Creator']['HasVerifiedBadge'])
            self.assertEqual(metadata['AssetTypeId'],10)

    def test_smg_and_shotgun_keep_real_geometry_finishes_audio_and_original_grips(self):
        expected={
            'SMG':('SMG','3361646593','2492936134',4812801977,3821793228,1),
            'Bronze':('SMG','3361510036','2492936134',4812801977,3821793228,1),
            'White':('SMG','3361512453','2492936134',4812801977,3821793228,1),
            'Shotgun':('Shotgun','2492974190','2492972199',3821792787,3821792115,-1),
            'Sand':('Shotgun','3361578179','2492972199',3821792787,3821792115,-1),
            'Silver':('Shotgun','3361579798','2492972199',3821792787,3821792115,-1),
        }
        for label,(body_name,texture,mesh,fired,reload,rotation) in expected.items():
            tool=self.tools[label]
            named={i.findtext('./Properties/string[@name="Name"]'):i for i in tool.iter('Item')}
            self.assertEqual(sum(i.get('class')=='MeshPart' for i in tool.iter('Item')),2)
            self.assertEqual(named[body_name].findtext('./Properties/Content[@name="MeshContent"]/uri'),'rbxassetid://'+mesh)
            self.assertEqual(named[body_name].findtext('./Properties/Content[@name="TextureContent"]/uri'),'rbxassetid://'+texture)
            self.assertEqual(named['Fired'].findtext('./Properties/Content[@name="AudioContent"]/uri'),'rbxassetid://'+str(fired))
            self.assertEqual(named['Reload'].findtext('./Properties/Content[@name="AudioContent"]/uri'),'rbxassetid://'+str(reload))
            self.assertEqual(float(named['HandleAttachment'].findtext('./Properties/CoordinateFrame[@name="CFrame"]/R00')),rotation)
            self.assertIn('TipAttachment',named)
            self.assertEqual(named['MuzzleFlash'].get('class'),'Beam')
            self.assertNotIn('BoltMotor',named,'Do not invent a motor absent from the real source')
            model=next(i for i in tool.findall('Item') if i.get('class')=='Model')
            self.assertIn(model.findtext('./Properties/Ref[@name="PrimaryPart"]'),{i.get('referent') for i in model.iter('Item')})

    def test_r15_animations_are_retained_without_claiming_r6_compatibility(self):
        self.assertEqual(sum(i.get('class')=='Animation' for i in self.items),3)
        for name,asset in {'RifleAim':'3972164452','RifleReload':'3972131105','RifleAimDownSights':'3972157449'}.items():
            self.assertEqual(self.named[name].get('class'),'Animation')
            self.assertIn(asset,self.named[name].findtext('./Properties/Content[@name="AnimationContent"]/uri'))

    def test_archived_impact_audio_is_excluded_without_discarding_particles(self):
        effect=self.named['HitEffect']
        self.assertEqual(effect.get('class'),'Attachment')
        particles=effect.find('Item[@class="ParticleEmitter"]')
        self.assertIsNotNone(particles)
        self.assertEqual(particles.findtext('./Properties/string[@name="Name"]'),'HitParticles')
        self.assertEqual(particles.findtext('./Properties/Content[@name="TextureContent"]/uri'),
                         'rbxasset://textures/particles/smoke_main.dds')
        references=[node.text or '' for node in self.tree.findall('.//Properties/Content/uri')]
        self.assertFalse(any('1489924400' in reference for reference in references),
                         'Archived impact audio must not return to the runtime package')


if __name__=='__main__':unittest.main()
