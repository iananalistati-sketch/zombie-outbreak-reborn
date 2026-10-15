"""Resolve the forty base objects plus props authored inside the new refuge layouts."""
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]


def load_catalog(refuges):
    catalog=json.loads((ROOT/'src/maps/k17/barricades/catalog.json').read_text(encoding='utf-8'))
    for refuge in refuges:
        for index,prop in enumerate(refuge.get('props',[]),1):
            if isinstance(prop,dict):kind,x,y,z=(prop[k] for k in ('Kind','X','Y','Z'))
            else:kind,x,y,z=prop
            assert kind in catalog['Kinds'],kind
            name=f'R{refuge["id"]:02d}Prop{index:02d}'
            assert name not in catalog['Props'],name
            catalog['Props'][name]=dict(Kind=kind,X=x,Y=y,Z=z,Refuge=refuge['id'])
    return catalog
