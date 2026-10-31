"""Check the actual reused native assets and their integration contract."""
import hashlib
import json
from pathlib import Path
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
        self.assertEqual(set(self.tools),{'Rifle','Pistol'})
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
        path=ROOT/'third_party/roblox-weapon-kit/pistol/OriginalPistol2.rbxmx'
        self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(),
                         '704f204cd3eb51a361c449f8718dd30b10869e7dcc823a1d186598176f89993e')
        archive=ET.parse(path)
        tool=archive.find('Item')
        self.assertEqual(tool.get('class'),'Tool')
        self.assertEqual(tool.findtext('./Properties/string[@name="Name"]'),'Pistol2')
        self.assertEqual(tool.findtext('./Properties/int64[@name="SourceAssetId"]'),'118912302094201')
        self.assertEqual(sum(i.get('class') in ('Script','LocalScript','ModuleScript') for i in archive.findall('.//Item')),16)

    def test_black_pistol_uses_the_actual_uploaded_mesh_texture_audio_and_grip(self):
        expected={
            'Pistol':('2492922600','3361038943'),
            'Bolt':('2492923497','3361041283'),
            'Magazine':('2492925447','3361041283'),
        }
        self.assertEqual(sum(i.get('class')=='MeshPart' for i in self.items),6)
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

    def test_r15_animations_are_retained_without_claiming_r6_compatibility(self):
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
