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

    def test_archive_identity_and_both_licenses_are_retained(self):
        folder=ROOT/'third_party/roblox-weapon-kit'
        source=json.loads((folder/'SOURCE.json').read_text())
        self.assertEqual(hashlib.sha256((folder/source['file']).read_bytes()).hexdigest(),source['sha256'])
        self.assertIn('Copyright (c) 2025 JustATortoise',(folder/'MIT-FIX-LICENSE.txt').read_text())
        self.assertIn('LIMITED USE LICENSE',(folder/'ROBLOX-LIMITED-USE-LICENSE.md').read_text())

    def test_runtime_templates_cannot_start_another_combat_system(self):
        executable={'Script','LocalScript','ModuleScript','RemoteEvent','RemoteFunction'}
        self.assertFalse(any(i.get('class') in executable for i in self.items))
        # There is also a nested AR Model; find the actual Tool explicitly.
        tool=next(i for i in self.items if i.get('class')=='Tool')
        self.assertEqual(tool.findtext('./Properties/bool[@name="CanBeDropped"]'),'false')
        self.assertEqual(tool.findtext('./Properties/string[@name="Name"]'),'Rifle')
        self.assertNotIn('RifleCasing',self.named)
        self.assertNotIn('Bullet',self.named)

    def test_rifle_is_a_real_mesh_with_its_original_sounds_and_joints(self):
        expected={'Rifle':'2492890820','Magazine':'2492891824','Bolt':'2492892116'}
        for name,asset in expected.items():
            item=self.named[name]
            self.assertEqual(item.get('class'),'MeshPart')
            self.assertIn(asset,item.findtext('./Properties/Content[@name="MeshContent"]/uri'))
        self.assertEqual(self.named['Fired'].findtext('./Properties/Content[@name="AudioContent"]/uri'),'rbxassetid://3806349898')
        self.assertEqual(self.named['Reload'].findtext('./Properties/Content[@name="AudioContent"]/uri'),'rbxassetid://3821787597')
        for name in ('HandleAttachment','TipAttachment','CasingEjectPoint','MuzzleFlash','BoltMotor','BoltMotorStart','BoltMotorTarget'):
            self.assertIn(name,self.named)
        self.assertEqual(self.named['MuzzleFlash'].get('class'),'Beam')
        self.assertEqual(self.named['BoltMotor'].get('class'),'Motor6D')
        references={i.get('referent') for i in self.items}
        for item in self.items:
            for ref in item.findall('./Properties/Ref'):
                self.assertTrue(ref.text=='null' or ref.text in references,(item.get('class'),ref.get('name'),ref.text))

    def test_r15_animations_are_retained_without_claiming_r6_compatibility(self):
        for name,asset in {'RifleAim':'3972164452','RifleReload':'3972131105','RifleAimDownSights':'3972157449'}.items():
            self.assertEqual(self.named[name].get('class'),'Animation')
            self.assertIn(asset,self.named[name].findtext('./Properties/Content[@name="AnimationContent"]/uri'))


if __name__=='__main__':unittest.main()
