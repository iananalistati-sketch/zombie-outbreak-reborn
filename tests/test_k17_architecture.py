"""Geometry regressions for usable daylight apertures and retained roof access."""
import json
from pathlib import Path
import sys
import unittest
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from validate_k17 import geometry,roof_aperture_errors


class IndustrialArchitecture(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data=json.loads((ROOT/'docs/k17-navigation.json').read_text())
        cls.boxes,_=geometry(ET.parse(ROOT/'src/maps/k17/K17Foundry.rbxmx'))

    def test_monitors_open_through_the_original_roof_slab(self):
        self.assertEqual(roof_aperture_errors(self.boxes,self.data['architecture']),[])

    def test_opaque_cap_under_glazing_is_rejected(self):
        feature=next(f for f in self.data['architecture'] if 'apertures' in f)
        a,b,c,d=feature['apertures'][0];height=feature['aperture_floor']
        boxes=self.boxes+[('InjectedOpaqueRoofCap',[a,height-.6,c],[b,height,d])]
        errors=roof_aperture_errors(boxes,self.data['architecture'])
        self.assertTrue(any('InjectedOpaqueRoofCap' in error for error in errors))


if __name__=='__main__':unittest.main()
