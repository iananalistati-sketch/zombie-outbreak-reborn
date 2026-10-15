"""Real authored geometry checks, including props versus all original routes."""
import importlib.util
import json
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('k17_validator',ROOT/'scripts/validate_k17.py')
validator=importlib.util.module_from_spec(spec);spec.loader.exec_module(validator)


class StockroomGeometry(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.props=ET.parse(ROOT/'src/maps/k17/barricades/Stockroom.rbxmx')
        cls.map=ET.parse(ROOT/'src/maps/k17/K17Foundry.rbxmx')
        cls.manifest=json.loads((ROOT/'docs/k17-navigation.json').read_text())
        cls.catalog=json.loads((ROOT/'src/maps/k17/barricades/catalog.json').read_text())
        cls.boxes,_=validator.geometry(cls.props)

    def test_single_solid_hull_per_prop(self):
        models=self.props.findall('./Item/Item[@class="Model"]')
        self.assertEqual({validator.props(m)['Name'].text for m in models},
                         set(self.catalog['Props']))
        self.assertEqual(len(self.boxes),40)
        for model in models:
            primary=validator.props(model)['PrimaryPart'].text
            hulls=[p for p in model.findall('Item[@class="Part"]') if validator.props(p)['CanCollide'].text=='true']
            self.assertEqual(len(hulls),1)
            self.assertEqual(hulls[0].attrib['referent'],primary)
            for part in model.findall('Item[@class="Part"]'):
                self.assertEqual(validator.props(part)['Anchored'].text,'true')
            hp=validator.props(hulls[0])
            self.assertEqual(hp['CanQuery'].text,'true')
            self.assertEqual(hp['Transparency'].text,'1')

    def test_visuals_stay_inside_the_collision_hulls(self):
        for model in self.props.findall('./Item/Item[@class="Model"]'):
            hull=next(b for b in self.boxes if '/'+validator.props(model)['Name'].text+'/' in b[0])
            for part in model.findall('Item[@class="Part"]'):
                p=validator.props(part);cf=p['CFrame'];size=p['size']
                for i,k in enumerate('XYZ'):
                    center=float(cf.find(k).text);half=float(size.find(k).text)/2
                    self.assertGreaterEqual(center-half,hull[1][i]-.001)
                    self.assertLessEqual(center+half,hull[2][i]+.001)

    def test_all_homes_have_floor_and_no_overlap(self):
        boxes,_=validator.geometry(self.map)
        for name,lo,hi in self.boxes:
            prop=self.catalog['Props'][name.split('/')[2]]
            self.assertAlmostEqual(lo[1],prop['Y'])
            for x in (lo[0]+.05,hi[0]-.05):
                for z in (lo[2]+.05,hi[2]-.05):
                    self.assertTrue(any(a[0]<=x<=b[0] and a[2]<=z<=b[2] and abs(b[1]-prop['Y'])<.01 for _,a,b in boxes),name+' floor')
            for other,a,b in boxes+self.boxes:
                if other==name:continue
                overlap=all(min(hi[i],b[i])-max(lo[i],a[i])>.01 for i in range(3))
                self.assertFalse(overlap,name+' overlaps '+other)

    def test_original_routes_and_defenses_remain_clear_with_props(self):
        boxes,_=validator.geometry(self.map)
        index=validator.CollisionIndex(boxes+self.boxes)
        for route in self.manifest['routes']:
            error,_=index.sweep(route,self.manifest['avatar'])
            self.assertIsNone(error,route['name']+': '+str(error))
        for defense in self.manifest['defenses']:
            error,_=index.sweep({'points':[defense['point'],defense['point']]},self.manifest['avatar'])
            self.assertIsNone(error,defense['name']+': '+str(error))

    def test_blocking_the_corridor_door_is_detected(self):
        boxes,_=validator.geometry(self.map)
        # A negative control: the new props must actually participate in clearance checks.
        blocker=('closed_barricade',[-226,1,118],[-224,7.3,128])
        index=validator.CollisionIndex(boxes+self.boxes+[blocker])
        route={'points':[[-217,1,123],[-244,1,123]]}
        error,_=index.sweep(route,self.manifest['avatar'])
        self.assertIn('closed_barricade',error or '')


if __name__=='__main__':unittest.main()
