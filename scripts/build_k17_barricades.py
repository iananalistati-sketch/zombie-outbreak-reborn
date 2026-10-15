#!/usr/bin/env python3
"""Author the five stockroom props separately; never rewrite K-17 architecture."""
import argparse
from pathlib import Path
import xml.etree.ElementTree as ET
from build_k17 import Map

ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT/'src/maps/k17/barricades/Stockroom.rbxmx'


def build():
    m=Map();m.root.find('Properties/string[@name="Name"]').text='ZO_Barricades'
    # Hull dimensions and homes are checked against the runtime catalog in Studio.
    for name,kind,x,z in [('Cabinet01','Cabinet',-253,138),('Cabinet02','Cabinet',-245,138),
                          ('Table01','Table',-253,119),('Crate01','Crate',-241,132),('Crate02','Crate',-237,138)]:
        w,h,d={'Cabinet':(4.8,6.3,2.2),'Table':(6,3.6,2.4),'Crate':(3.5,3.5,3.5)}[kind]
        hull=m.box(name,'Hull',(x-w/2,x+w/2,z-d/2,z+d/2),1,1+h,alpha=1,shadow=False)
        hull.set('referent',name+'Hull')
        m.prop(m.group(name).find('Properties'),'Ref','PrimaryPart',name+'Hull')
        def box(label,rect,low,high,color='steel',material='Metal'):
            return m.box(name,label,(x+rect[0],x+rect[1],z+rect[2],z+rect[3]),1+low,1+high,color,material,physical=False)
        if kind=='Cabinet':
            box('SteelCarcass',(-2.35,2.35,-1,1),.15,6.2,'olive')
            for a,b in [(-2.2,-.07),(.07,2.2)]:
                box('DoorPanel',(a,b,-1.09,-1.01),.4,5.95,'steel')
                for y in (4.85,5.1,5.35): box('VentSlot',(a+.28,b-.28,-1.1,-1.09),y,y+.07,'dark')
            for a in (-.28,.18):box('DoorLatch',(a,a+.1,-1.1,-1.02),2.8,3.4,'yellow')
            box('KickPlate',(-2.3,2.3,-1.08,-1.01),.15,.4,'rust')
            for a in (-2.2,1.9):box('Foot',(a,a+.3,-.9,.9),0,.15,'dark')
        elif kind=='Table':
            # An overturned workshop table: timber face toward -Z, folded steel legs behind.
            box('TimberTop',(-3,3,-1.2,-.88),0,3.6,'wood','WoodPlanks')
            for y in (.16,3.14):
                box('EdgeFrame',(-2.95,2.95,-.88,-.68),y,y+.3,'steel')
                for a in (-2.8,2.5):box('Leg',(a,a+.3,-.68,1.2),y,y+.3,'steel')
            box('CrossBrace',(-2.8,2.8,.9,1.15),.26,.46,'rust')
        else:
            box('CrateBody',(-1.7,1.7,-1.7,1.7),.2,3.4,'wood','WoodPlanks')
            for a in (-1.75,1.5):
                box('SteelBand',(a,a+.25,-1.75,1.75),.2,3.5,'steel')
            for y in (.35,2.9):box('FaceBrace',(-1.7,1.7,-1.75,-1.7),y,y+.18,'rust')
            for a in (-1.6,1.1):box('PalletRunner',(a,a+.5,-1.7,1.7),0,.2,'dark','Wood')
    ET.indent(m.xml,space='  ')
    return ET.tostring(m.xml,encoding='unicode')+'\n'


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--check',action='store_true');args=parser.parse_args()
    output=build()
    if args.check:
        assert TARGET.read_text()==output,'Stockroom props are stale; run scripts/build_k17_barricades.py'
    else:TARGET.write_text(output)
    print('PASS stockroom authoring: five props, three types, separate from preserved architecture')
