"""Negative controls prove that map checks reject actual circulation regressions."""
import importlib.util
import json
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('k17_validator',ROOT/'scripts/validate_k17.py')
audit=importlib.util.module_from_spec(spec)
spec.loader.exec_module(audit)


class CirculationRegressions(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest=json.loads((ROOT/'docs/k17-navigation.json').read_text())
        cls.boxes,_=audit.geometry(ET.parse(ROOT/'src/maps/k17/K17Foundry.rbxmx'))
        cls.routes={r['name']:r for r in cls.manifest['routes']}

    def check_changed_geometry(self,boxes,route):
        return audit.CollisionIndex(boxes).sweep(self.routes[route],self.manifest['avatar'])[0]

    def test_sealing_an_entrance_is_detected(self):
        changed=self.boxes+[('Injected door obstruction',[-74,1,-125],[-62,12,-123])]
        error=self.check_changed_geometry(changed,'A_Administration street entrance')
        self.assertIsNotNone(error)
        self.assertIn('Injected door obstruction',error)

    def test_covering_the_sewer_shaft_is_detected(self):
        changed=self.boxes+[('Injected shaft cap',[22,-2,-112],[38,0,-60])]
        error=self.check_changed_geometry(changed,'North sewer descent')
        self.assertIsNotNone(error)
        self.assertIn('Injected shaft cap',error)

    def test_removing_a_bridge_floor_is_detected(self):
        changed=[box for box in self.boxes if not box[0].endswith('/BuildingLink')]
        error=self.check_changed_geometry(changed,'Warehouse foundry bridge')
        self.assertIsNotNone(error)
        self.assertIn('no support',error)


if __name__=='__main__':unittest.main()
