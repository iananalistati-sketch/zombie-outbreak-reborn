"""Verify Escape's connected routes, interactable controls and actual gate volume."""
import json
import math
from pathlib import Path
import sys
import unittest
import xml.etree.ElementTree as ET
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from k17_escape import CONFIG
from validate_k17 import geometry,CollisionIndex
from validate_refuges import ray_blocker


class EscapeGeometry(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.data=json.loads((ROOT/'docs/k17-navigation.json').read_text())
        cls.tree=ET.parse(ROOT/'src/maps/k17/K17Foundry.rbxmx')
        cls.boxes=geometry(cls.tree)[0]+geometry(ET.parse(ROOT/'src/maps/k17/barricades/Stockroom.rbxmx'))[0]

    def test_three_connected_legs_are_walkable_with_barricades_in_place(self):
        legs=[r for r in self.data['routes'] if r['name'].startswith('ZE ')]
        self.assertEqual(len(legs),3)
        index=CollisionIndex(self.boxes)
        for route in legs:
            self.assertIsNone(index.sweep(route,self.data['avatar'])[0],route['name'])
        self.assertEqual(legs[0]['points'][-1],CONFIG['Stages'][0]['Point'])
        self.assertEqual(legs[1]['points'][0],CONFIG['Stages'][0]['Point'])
        self.assertEqual(legs[1]['points'][-1],CONFIG['Stages'][1]['Point'])
        self.assertEqual(legs[2]['points'][0],CONFIG['Stages'][1]['Point'])
        self.assertEqual(legs[2]['points'][-1],CONFIG['Stages'][2]['Point'])

    def test_controls_have_reachable_server_range_and_clear_sight(self):
        for number,stage in enumerate(CONFIG['Stages'],1):
            p=stage['Point'];root=[p[0],p[1]+3,p[2]];eye=[p[0],p[1]+5.5,p[2]]
            self.assertLess(math.dist(root,stage['Control']),CONFIG['ActivationRange'])
            # The real server accepts the target cabinet as the first hit;
            # every other wall/prop must leave the line of sight clear.
            blockers=[box for box in self.boxes if not box[0].endswith(f'/EscapeObjectives/Control{number}')]
            self.assertIsNone(ray_blocker(eye,stage['Control'],blockers),stage['Label'])

    def test_closing_the_real_gate_blocks_the_open_approach(self):
        node=next(i for i in self.tree.iter('Item') if i.findtext('Properties/string[@name="Name"]')=='EvacuationGate')
        p=node.find('Properties');cf=p.find('CoordinateFrame');size=p.find('Vector3[@name="size"]')
        center=[float(cf.find(k).text) for k in 'XYZ'];half=[float(size.find(k).text)/2 for k in 'XYZ']
        gate=('EvacuationGate',[center[i]-half[i] for i in range(3)],[center[i]+half[i] for i in range(3)])
        route=next(r for r in self.data['routes'] if r['name']=='R50 terminal approach')
        self.assertIsNone(CollisionIndex(self.boxes).sweep(route,self.data['avatar'])[0])
        error=CollisionIndex(self.boxes+[gate]).sweep(route,self.data['avatar'])[0]
        self.assertIn('EvacuationGate',error)

    def test_mother_spawn_is_on_a_clear_supported_floor(self):
        p=CONFIG['MotherSpawn']
        self.assertIsNone(CollisionIndex(self.boxes).sweep({'points':[p,p]},self.data['avatar'])[0])

if __name__=='__main__':unittest.main()
