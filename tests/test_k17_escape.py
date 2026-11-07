"""Measured respawn safety against shipped geometry and authored physical props."""
import json
from pathlib import Path
import sys
import unittest
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from k17_escape import CONFIG
from validate_k17 import CollisionIndex,geometry


class EscapeReturns(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data=json.loads((ROOT/'docs/k17-navigation.json').read_text())
        cls.boxes=geometry(ET.parse(ROOT/'src/maps/k17/K17Foundry.rbxmx'))[0]
        cls.boxes+=geometry(ET.parse(ROOT/'src/maps/k17/barricades/Stockroom.rbxmx'))[0]

    def test_all_candidates_connect_to_a_supported_route_with_props(self):
        index=CollisionIndex(self.boxes)
        routes=[r for r in self.data['routes'] if r['kind']=='spawn']
        self.assertEqual(len(routes),9)
        for route in routes:
            with self.subTest(route=route['name']):
                self.assertIsNone(index.sweep(route,self.data['avatar'])[0])

    def test_blocking_a_candidate_invalidates_body_clearance(self):
        p=CONFIG['Respawns'][0]['Points'][0]
        boxes=self.boxes+[('occupied_return',[p[0]-1,p[1]+1,p[2]-1],[p[0]+1,p[1]+6,p[2]+1])]
        error,_=CollisionIndex(boxes).sweep({'points':[p,p]},self.data['avatar'])
        self.assertIn('occupied_return',error)

    def test_solo_pressure_positions_are_supported_with_physical_props(self):
        index=CollisionIndex(self.boxes)
        routes=[r for r in self.data['routes'] if r['kind']=='training']
        self.assertGreater(len(routes),30)
        for route in routes:
            with self.subTest(route=route['name']):
                self.assertIsNone(index.sweep(route,self.data['avatar'])[0])


if __name__=='__main__':unittest.main()
