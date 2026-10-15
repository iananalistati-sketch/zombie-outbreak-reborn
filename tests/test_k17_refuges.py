"""Tactical layout checks with negative controls for sealed routes and firing ports."""
import json
from pathlib import Path
import sys
import unittest
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from validate_refuges import validate,ray_blocker
from validate_k17 import geometry


class Refuges(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data=json.loads((ROOT/'docs/k17-navigation.json').read_text())
        cls.boxes=geometry(ET.parse(ROOT/'src/maps/k17/K17Foundry.rbxmx'))[0]
        cls.boxes+=geometry(ET.parse(ROOT/'src/maps/k17/barricades/Stockroom.rbxmx'))[0]

    def test_group_positions_approaches_and_sights(self):
        self.assertEqual(validate(self.data,self.boxes),[])

    def test_sealing_stockroom_portal_fails(self):
        errors=validate(self.data,self.boxes+[('sealed_portal',[-231.3,1,120],[-230.7,10,126])])
        self.assertTrue(any('sealed_portal' in e for e in errors))

    def test_receiving_window_is_a_real_opening(self):
        a,b=[-98,6.5,97],[-98,6.5,118]
        self.assertIsNone(ray_blocker(a,b,self.boxes))
        self.assertEqual(ray_blocker(a,b,[('glazed_port',[-106,4.5,103.9],[-90,9.5,104.1])]),'glazed_port')
        self.assertIsNotNone(ray_blocker([-88,6.5,97],[-88,6.5,118],self.boxes))

    def test_removing_container_landing_fails(self):
        boxes=[box for box in self.boxes if '/R14_ContainerPost/LoadingLanding' not in box[0]]
        errors=validate(self.data,boxes)
        self.assertTrue(any('R14 leste: no support' in e for e in errors),errors)

    def test_bent_stockroom_duct_really_breaks_sight(self):
        boxes=[b for b in self.boxes if '/V_StockroomVent/DuctWall' not in b[0]]
        errors=validate(self.data,boxes)
        self.assertIn('StockroomVent: bend does not break sight',errors)

    def test_sealing_duct_entry_is_rejected(self):
        closed=self.boxes+[('sealed_vent',[-252.3,1,105],[-251.7,8.5,113])]
        self.assertTrue(any('sealed_vent' in e for e in validate(self.data,closed)))

    def test_ducts_have_solid_roofs(self):
        for duct in self.data['ducts']:
            p=duct['points'][1]
            roofs=[b for b in self.boxes if '/'+duct['model']+'/DuctRoof' in b[0]]
            self.assertIsNotNone(ray_blocker([p[0],p[1]+5,p[2]],[p[0],p[1]+9,p[2]],roofs),duct['name'])

    def test_removing_bus_roof_exposes_its_defense(self):
        boxes=[b for b in self.boxes if '/R42_StaffBus/BusRoof' not in b[0]]
        self.assertIn('Refuge 42: no overhead cover',validate(self.data,boxes))

    def test_under_stair_return_really_conceals_players(self):
        boxes=[b for b in self.boxes if '/R48_UnderStair/InnerReturn' not in b[0]]
        self.assertIn('Refuge 48: protected bay exposed to entry',validate(self.data,boxes))


if __name__=='__main__':unittest.main()
