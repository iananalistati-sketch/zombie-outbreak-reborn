#!/usr/bin/env python3
"""Authored Santa Aurora block. Standard library only; no downloads or Studio plugins.

Coordinates are Roblox studs, Y up, north = -Z. Emit edit-time Roblox XML,
a collision manifest for independent route checks and a labelled floor plan.
Do not hand-edit the generated files; adjust this architectural source instead.
"""
from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "src/maps/santa-aurora"
PALETTE = {
    "brick": (126, 73, 56), "brickDark": (82, 55, 48),
    "plaster": (191, 180, 154), "trim": (218, 208, 182),
    "concrete": (126, 126, 117), "paving": (153, 151, 136),
    "asphalt": (54, 60, 61), "steel": (55, 66, 67),
    "teal": (47, 91, 88), "rust": (142, 94, 60),
    "glass": (133, 172, 174), "wood": (126, 96, 65),
    "white": (229, 224, 203), "yellow": (216, 169, 62),
    "light": (255, 223, 166), "green": (69, 91, 61),
}


class Scene:
    def __init__(self):
        self.root = ET.Element("roblox", version="4")
        self.model = self.item(self.root, "Model", "ZO_SantaAurora")
        self.parts = []
        self.portals = []
        self.groups = {}
        self.lights = 0
        self.serial = 0

    @staticmethod
    def prop(parent, tag, name, value):
        e = ET.SubElement(parent, tag, name=name)
        if isinstance(value, (tuple, list)):
            for key, number in zip({"Vector3": "XYZ", "Vector2": "XY", "Color3": "RGB"}[tag], value):
                ET.SubElement(e, key).text = str(number)
        else:
            e.text = str(value).lower() if isinstance(value, bool) else str(value)
        return e

    def item(self, parent, cls, name):
        item = ET.SubElement(parent, "Item", {"class": cls})
        props = ET.SubElement(item, "Properties")
        self.prop(props, "string", "Name", name)
        return item

    def group(self, name):
        if name not in self.groups:
            self.groups[name] = self.item(self.model, "Model", name)
        return self.groups[name]

    def part(self, group, name, pos, size, color="concrete", material="Concrete",
             collide=True, transparency=0, rotation=(0, 0, 0), shape=1):
        assert all(n > 0 for n in size), (name, size)
        parent = self.group(group) if isinstance(group, str) else group
        item = self.item(parent, "Part", name)
        p = item.find("Properties")
        self.prop(p, "Vector3", "size", size)
        self.prop(p, "Color3", "Color", tuple(v / 255 for v in PALETTE.get(color, color)))
        # Material tokens are stable engine values, unlike display names.
        materials = {"Plastic": 256, "SmoothPlastic": 272, "Neon": 288,
                     "Wood": 512, "WoodPlanks": 528, "Concrete": 816,
                     "Brick": 848, "Cobblestone": 880, "Metal": 1088,
                     "DiamondPlate": 1056, "Glass": 1568, "Asphalt": 1376}
        self.prop(p, "token", "Material", materials[material])
        self.prop(p, "token", "shape", shape)
        for name_, value in [("Anchored", True), ("CanCollide", collide),
                             ("CanTouch", False), ("CanQuery", collide),
                             ("CastShadow", transparency < .5)]:
            self.prop(p, "bool", name_, value)
        self.prop(p, "float", "Transparency", transparency)
        self.prop(p, "token", "TopSurface", 0)
        self.prop(p, "token", "BottomSurface", 0)
        rx, ry, rz = map(math.radians, rotation)
        sx, cx, sy, cy, sz, cz = math.sin(rx), math.cos(rx), math.sin(ry), math.cos(ry), math.sin(rz), math.cos(rz)
        matrix = [cy*cz, -cy*sz, sy, cx*sz+sx*sy*cz, cx*cz-sx*sy*sz, -sx*cy,
                  sx*sz-cx*sy*cz, sx*cz+cx*sy*sz, cx*cy]
        cf = ET.SubElement(p, "CoordinateFrame", name="CFrame")
        for key, value in zip(["X", "Y", "Z"] + [f"R{i}{j}" for i in range(3) for j in range(3)], list(pos) + matrix):
            ET.SubElement(cf, key).text = str(round(value, 6))
        self.parts.append({"group": group if isinstance(group, str) else "Detail",
                           "name": name, "position": list(pos), "size": list(size),
                           "rotation": list(rotation), "collide": collide})
        self.serial += 1
        return item

    def box(self, group, name, x0, x1, y0, y1, z0, z1, **kw):
        return self.part(group, name, ((x0+x1)/2, (y0+y1)/2, (z0+z1)/2),
                         (x1-x0, y1-y0, z1-z0), **kw)

    def beam(self, group, name, a, b, width=.22, color="steel", collide=False):
        # Thin box whose local Z follows the line; all rails are non-physical detail.
        dx, dy, dz = (b[i]-a[i] for i in range(3))
        length = math.sqrt(dx*dx+dy*dy+dz*dz)
        yaw = math.degrees(math.atan2(dx, dz))
        pitch = -math.degrees(math.atan2(dy, math.hypot(dx, dz)))
        # R_y * R_x is represented directly, matching the CFrame XML convention.
        item = self.part(group, name, tuple((a[i]+b[i])/2 for i in range(3)),
                         (width, width, length), color, "Metal", collide=collide)
        cf = item.find('Properties/CoordinateFrame')
        p, y = math.radians(pitch), math.radians(yaw)
        matrix = [math.cos(y), math.sin(y)*math.sin(p), math.sin(y)*math.cos(p),
                  0, math.cos(p), -math.sin(p),
                  -math.sin(y), math.cos(y)*math.sin(p), math.cos(y)*math.cos(p)]
        for key, value in zip([f"R{i}{j}" for i in range(3) for j in range(3)], matrix):
            cf.find(key).text = str(round(value, 6))
        return item

    def sign(self, group, name, center, size, text, face=5, color="teal"):
        item = self.part(group, name, center, size, color, "Metal", collide=False)
        gui = self.item(item, "SurfaceGui", "Lettering")
        p = gui.find("Properties")
        self.prop(p, "token", "Face", face)  # Front=-Z; Back=+Z
        self.prop(p, "Vector2", "CanvasSize", (1024, 256))
        self.prop(p, "bool", "AlwaysOnTop", False)
        self.prop(p, "float", "LightInfluence", .3)
        self.prop(p, "float", "MaxDistance", 160)
        label = self.item(gui, "TextLabel", "Text")
        p = label.find("Properties")
        self.prop(p, "string", "Text", text)
        self.prop(p, "Color3", "TextColor3", tuple(v/255 for v in PALETTE["white"]))
        self.prop(p, "float", "BackgroundTransparency", 1)
        self.prop(p, "bool", "TextScaled", True)
        self.prop(p, "token", "Font", 19)  # GothamBold
        dim = ET.SubElement(p, "UDim2", name="Size")
        for k, v in [("XS", 1), ("XO", -24), ("YS", .8), ("YO", 0)]:
            ET.SubElement(dim, k).text = str(v)
        dim = ET.SubElement(p, "UDim2", name="Position")
        for k, v in [("XS", 0), ("XO", 12), ("YS", .1), ("YO", 0)]:
            ET.SubElement(dim, k).text = str(v)

    def light(self, group, x, y, z, warm=True, outdoor=False):
        fixture = self.part(group, f"Luminaire_{self.lights:02}", (x,y,z),
                            (2.8,.22,1.2), "light", "Neon", collide=False)
        lamp = self.item(fixture, "PointLight", "PracticalLight")
        p = lamp.find("Properties")
        self.prop(p, "Color3", "Color", (1,.79,.53) if warm else (.66,.81,1))
        self.prop(p, "float", "Brightness", 1.3 if outdoor else .8)
        self.prop(p, "float", "Range", 34 if outdoor else 26)
        self.prop(p, "bool", "Shadows", outdoor)
        self.lights += 1

    def wall(self, group, name, axis, fixed, start, end, bottom, top,
             openings=(), material="Brick", color="brick", thickness=1):
        """Subtract actual rectangular doors/windows from a wall, never fake black doors.

        opening = (start, end, sill, head, kind). Windows receive framed glazing;
        door rectangles remain physically empty. All dimensions are absolute.
        """
        cuts_x = sorted({start, end} | {x for o in openings for x in o[:2]})
        cuts_y = sorted({bottom, top} | {y for o in openings for y in o[2:4]})
        assert all(start <= o[0] < o[1] <= end and bottom <= o[2] < o[3] <= top for o in openings), name
        for i, (a,b) in enumerate(zip(cuts_x,cuts_x[1:])):
            # Merge vertically adjacent solid cells to avoid needless Instances.
            run = None
            for lo,hi in list(zip(cuts_y,cuts_y[1:])) + [(top,top)]:
                empty = hi == lo or any(o[0] <= (a+b)/2 <= o[1] and o[2] <= (lo+hi)/2 <= o[3] for o in openings)
                if not empty and run is None:
                    run = lo
                if empty and run is not None:
                    if axis == "X":
                        self.box(group, f"{name}_{i}_{run}", a,b,run,lo,fixed-thickness/2,fixed+thickness/2,color=color,material=material)
                    else:
                        self.box(group, f"{name}_{i}_{run}", fixed-thickness/2,fixed+thickness/2,run,lo,a,b,color=color,material=material)
                    run = None
        for index, (a,b,lo,hi,kind) in enumerate(openings):
            label = f"{name}_{kind}_{index}"
            self.portals.append({"name":label,"axis":axis,"fixed":fixed,"start":a,"end":b,"bottom":lo,"top":hi,"kind":kind})
            if kind == "window":
                center = ((a+b)/2,(lo+hi)/2,fixed) if axis == "X" else (fixed,(lo+hi)/2,(a+b)/2)
                size = (b-a,hi-lo,.12) if axis == "X" else (.12,hi-lo,b-a)
                self.part(group,label+"_Glass",center,size,"glass","Glass",transparency=.58)
                mid = (a+b)/2
                for s,e,y0,y1 in [(a,a+.22,lo,hi),(b-.22,b,lo,hi),(a,b,lo,lo+.22),
                                  (a,b,hi-.22,hi),(mid-.1,mid+.1,lo,hi)]:
                    if axis == "X":
                        self.box(group,label+f"_Frame_{self.serial}",s,e,y0,y1,fixed-.17,fixed+.17,color="trim",material="Metal",collide=False)
                    else:
                        self.box(group,label+f"_Frame_{self.serial}",fixed-.17,fixed+.17,y0,y1,s,e,color="trim",material="Metal",collide=False)
            else:
                for at in (a,b):
                    center = (at,(lo+hi)/2,fixed) if axis == "X" else (fixed,(lo+hi)/2,at)
                    size = (.2,hi-lo,thickness+.15) if axis == "X" else (thickness+.15,hi-lo,.2)
                    self.part(group,label+"_Jamb",center,size,"trim","Metal",collide=False)

    def stairs(self, group, name, x, z_start, direction, width, run, rise, base, steps=20):
        for i in range(steps):
            z = z_start + direction*(i+.5)*run/steps
            top = base+(i+1)*rise/steps
            self.part(group,f"{name}_Tread_{i+1:02}",(x,top-.375,z),(width,.75,run/steps+.04),"concrete")
            self.part(group,f"{name}_Nosing_{i+1:02}",(x,top+.015,z-direction*run/steps*.45),
                      (width,.03,.13),"yellow","Metal",collide=False)
        for side in (-1,1):
            xx = x+side*(width/2+.25)
            a,b = (xx,base+3.6,z_start),(xx,base+rise+3.6,z_start+direction*run)
            self.beam(group,name+"_Handrail",a,b,.18)
            self.beam(group,name+"_Stringer",(xx,base-.4,z_start),(xx,base+rise-.4,z_start+direction*run),.4)
            for i in range(0,steps+1,4):
                zz, yy = z_start+direction*i*run/steps, base+i*rise/steps
                self.part(group,name+"_Baluster",(xx,yy+1.7,zz),(.18,3.4,.18),"steel","Metal",collide=False)


def build():
    s = Scene()
    # Civil works: all floor heights reference the same street datum.
    s.box("01_Street", "DistrictFoundation", -134,134,-2,0,-114,114)
    s.box("01_Street", "RuaAurora_Asphalt", -126,126,0,.08,-18,18,color="asphalt",material="Asphalt")
    for z0,z1 in [(-30,-18),(18,30)]:
        s.box("01_Street","Sidewalk",-126,126,0,.6,z0,z1,color="paving")
        edge = -18 if z1 < 0 else 18
        s.part("01_Street","Curb",(0,.3,edge),(252,.6,.35),"trim")
        for x in range(-120,125,12):
            s.part("01_Street","PavingJoint",(x,.605,(z0+z1)/2),(.045,.015,z1-z0),"concrete",collide=False)
    for x in range(-116,117,16):
        s.part("01_Street","LaneDash",(x,.095,0),(8,.025,.18),"yellow",collide=False)
    for z in range(-15,16,5):
        s.part("01_Street","PedestrianCrossing",(-10,.105,z),(10,.03,2.5),"white",collide=False)
    for x,z in [(-102,-16),(68,-16),(-68,16),(102,16)]:
        s.part("01_Street","StormDrain",(x,.12,z),(3,.12,1.5),"steel","Metal",collide=False)
        for dx in (-1,-.5,0,.5,1):
            s.part("01_Street","DrainSlot",(x+dx,.19,z),(.14,.03,1.2),"asphalt","Metal",collide=False)
    for x,z in [(-88,-21),(8,-21),(102,-21),(-105,21),(-12,21),(92,21)]:
        s.part("01_Street","LampPost",(x,10.6,z),(.45,20,.45),"steel","Metal")
        s.part("01_Street","LampBase",(x,1.1,z),(1.2,1,1.2),"steel","Metal")
        s.part("01_Street","LampArm",(x,20.5,z+(2 if z<0 else -2)),(.35,.35,4),"steel","Metal",collide=False)
        s.light("01_Street",x,20.2,z+(3.7 if z<0 else -3.7),outdoor=True)
    s.sign("01_Street","StreetName",(5,8,-20),(11,2,.25),"RUA AURORA",face=2)
    s.part("01_Street","StreetSignPole",(5,4,-20),(.2,8,.2),"steel","Metal",collide=False)

    # North-west corner: retail at grade, offices upstairs. Two independent stairs.
    g = "02_MerceariaAurora"
    s.box(g,"RetailFloor",-108,-28,0,1,-94,-30,color="paving")
    for a,b,c,d in [(-108,-46,-94,-30),(-32,-28,-94,-30),(-46,-32,-94,-66),(-46,-32,-34,-30)]:
        s.box(g,"OfficeSlab",a,b,15.4,16,c,d,color="wood",material="WoodPlanks")
    s.box(g,"RoofSlab",-109,-27,31,32,-95,-29,color="concrete")
    s.wall(g,"Shopfront","X",-30,-108,-28,1,16,
           [(-102,-84,4,11,"window"),(-78,-68,1,12,"door"),(-62,-48,4,11,"window"),(-44,-34,4,11,"window")])
    s.wall(g,"RearGround","X",-94,-108,-28,1,16,[(-90,-80,1,12,"door"),(-64,-48,6,12,"window")])
    s.wall(g,"WestGround","Z",-108,-94,-30,1,16,[(-62,-50,5,12,"window")])
    s.wall(g,"EastGround","Z",-28,-94,-30,1,16,[(-84,-76,1,12,"door"),(-58,-46,5,12,"window")])
    for axis,fixed,start,end,ops in [
        ("X",-30,-108,-28,[(-102,-90,20,27,"window"),(-78,-66,20,27,"window"),(-54,-42,20,27,"window")]),
        ("X",-94,-108,-28,[(-100,-88,20,27,"window"),(-62,-50,20,27,"window")]),
        ("Z",-108,-94,-30,[(-78,-70,16,27,"door"),(-54,-42,20,27,"window")]),
        ("Z",-28,-94,-30,[(-90,-80,20,27,"window"),(-58,-46,20,27,"window")])]:
        s.wall(g,"OfficeFacade",axis,fixed,start,end,16,31,ops,color="plaster",material="Concrete")
    for y in (1.3,15.1,30.6,32.4):
        for z in (-94.6,-29.4):
            s.part(g,"Cornice",(-68,y,z),(81,.45,.4),"trim",collide=False)
        for x in (-108.6,-27.4):
            s.part(g,"SideCornice",(x,y,-62),(.4,.45,64),"trim",collide=False)
    for x in (-107,-81,-53,-29):
        s.part(g,"FacadePilaster",(x,8,-29.35),(.7,13.5,.35),"brickDark",collide=False)
    for x in (-93,-55):
        s.part(g,"ShopAwning",(x,12.4,-27.8),(20,.35,4),"teal","Metal",collide=False,rotation=(-8,0,0))
        s.part(g,"AwningValance",(x,11.9,-25.9),(20,.7,.18),"teal","Metal",collide=False)
    s.sign(g,"ShopName",(-73,14,-29.1),(58,2,.35),"MERCEARIA AURORA  •  DESDE 1984",face=2)
    s.sign(g,"Number",(-81,6,-29.25),(2.4,1.5,.2),"84",face=2)
    s.sign(g,"OfficeName",(-68,29,-29.3),(48,1.7,.2),"AURORA  /  ADMINISTRAÇÃO",face=2)
    # Real partitions; storage/reception and offices have traversable door cuts.
    s.wall(g,"StockPartition","X",-72,-107.5,-28.5,1,15.4,[(-90,-80,1,12,"door")],color="plaster",material="Concrete",thickness=.6)
    s.wall(g,"StairHallPartition","Z",-48,-72,-30.5,1,15.4,[(-42,-32,1,12,"door")],color="plaster",material="Concrete",thickness=.6)
    s.wall(g,"OfficeCorridor","X",-66,-107.5,-46,16,31,[(-100,-92,16,27,"door"),(-66,-58,16,27,"door")],color="plaster",material="Concrete",thickness=.6)
    s.wall(g,"OfficeDivider","Z",-78,-65.5,-30.5,16,31,[(-48,-40,16,27,"door")],color="plaster",material="Concrete",thickness=.6)
    s.stairs(g,"InternalStair",-39,-36,-1,10,30,15,1)
    s.stairs(g,"ExternalFireStair",-116,-36,-1,10,30,15,1)
    s.box(g,"FireStairFooting",-122,-110,0,1,-38,-32)
    s.box(g,"FireStairLanding",-122,-107.5,15.4,16,-82,-66,color="steel",material="DiamondPlate")
    for x in (-120,-110):
        s.part(g,"FireLandingColumn",(x,7.7,-80),(.4,15.4,.4),"steel","Metal")
    # Landing guard rails leave the west door and stair mouth open.
    for x in (-122,-46,-32):
        za,zb = (-82,-66) if x==-122 else (-64,-34)
        s.part(g,"LandingGuard",(x,17.7,(za+zb)/2),(.18,3.4,zb-za),"steel","Metal")
    s.part(g,"FireLandingEnd",(-115,17.7,-82),(14,3.4,.18),"steel","Metal")
    s.part(g,"VoidEndGuard",(-39,17.7,-34),(14,3.4,.18),"steel","Metal")
    # Furnish to scale, kept out of the main routes; fixtures sit against walls.
    for x in (-100,-64):
        for z in (-58,-47):
            s.part(g,"GroceryShelf",(x,3.5,z),(7,5,2),"wood","Wood")
            for yy in (2,3.7,5.4):
                s.part(g,"ShelfBoard",(x,yy,z),(7.2,.15,2.2),"trim","Wood",collide=False)
                for dx in (-2.5,0,2.5):
                    s.part(g,"PackagedGoods",(x+dx,yy+.6,z),(.9,1,.9),"teal" if dx==0 else "rust","SmoothPlastic",collide=False)
    s.part(g,"Checkout",(-95,2.7,-36),(12,3.4,3),"teal","Wood")
    s.part(g,"CheckoutTop",(-95,4.5,-36),(12.4,.25,3.4),"wood","Wood",collide=False)
    s.part(g,"Register",(-92,5,-36),(1.6,.8,1),"steel","Metal",collide=False)
    s.part(g,"ColdCabinet",(-104,4.5,-65),(3,7,8),"white","Metal")
    s.part(g,"StockShelves",(-102,4,-84),(3,6,14),"wood","Wood")
    s.part(g,"PackingTable",(-54,2.8,-88),(12,3.6,4),"wood","Wood")
    for x,z in [(-98,-38),(-88,-58),(-62,-36),(-58,-59),(-68,-84)]:
        s.light(g,x,14.5,z)
    for x,z in [(-95,-86),(-62,-86),(-94,-52),(-62,-52)]:
        s.light(g,x,29.8,z,warm=False)
    for x,z in [(-98,-39),(-88,-58),(-59,-38)]:
        desk(s,g,x,16,z)
    s.part(g,"MeetingTable",(-61,18,-56),(12,4,5),"wood","Wood")
    for x in (-65,-57):
        for z in (-60,-52):
            chair(s,g,x,16,z)
    s.part(g,"Kitchenette",(-49,17.7,-90),(22,3.4,3),"teal","Wood")
    s.sign(g,"StockExit",(-85,12.8,-71.55),(8,1.2,.15),"SERVIÇO",face=2)
    # Roof service details: modest equipment with attached ducts, never random props.
    for x in (-94,-60):
        s.part(g,"RoofVent",(x,33.2,-82),(6,2.4,5),"steel","Metal",collide=False)
        for dx in (-2,-1,0,1,2):
            s.part(g,"VentLouvre",(x+dx,33.3,-79.4),(.15,1.7,.15),"concrete","Metal",collide=False)
    for z in (-94,-30):
        s.part(g,"RoofParapet",(-68,32.8,z),(80,1.6,.5),"brick")
    for x in (-108,-28):
        s.part(g,"RoofSideParapet",(x,32.8,-62),(.5,1.6,64),"brick")
    for x in (-107,-29):
        s.part(g,"Downpipe",(x,15.5,-29),(.2,29,.2),"steel","Metal",collide=False)

    # North-east: an actual garage and reception, plus a shared rear service lane.
    g = "03_OficinaLuz"
    s.box(g,"WorkshopSlab",12,80,0,1,-82,-30,color="concrete")
    s.box(g,"WorkshopRoof",11,81,16,17,-83,-29,color="steel",material="Metal")
    s.wall(g,"GarageFront","X",-30,12,80,1,16,[(22,46,1,13,"door"),(60,68,1,12,"door"),(71,77,5,11,"window")],color="plaster",material="Concrete")
    s.wall(g,"GarageRear","X",-82,12,80,1,16,[(36,44,1,12,"door"),(59,73,6,12,"window")],color="plaster",material="Concrete")
    s.wall(g,"GarageWest","Z",12,-82,-30,1,16,[(-66,-54,5,12,"window")],color="plaster",material="Concrete")
    s.wall(g,"GarageEast","Z",80,-82,-30,1,16,[(-68,-60,1,12,"door")],color="plaster",material="Concrete")
    s.wall(g,"ReceptionDivider","Z",52,-81.5,-30.5,1,16,[(-51,-41,1,12,"door")],color="plaster",material="Concrete",thickness=.6)
    s.sign(g,"WorkshopName",(46,14.5,-29.3),(56,2,.3),"OFICINA LUZ  /  AUTO ELÉTRICA",face=2,color="rust")
    for x in (22,46):
        s.part(g,"GarageTrack",(x,7,-29.3),(.3,12,.35),"steel","Metal",collide=False)
    s.part(g,"RaisedShutter",(34,13.6,-29.5),(24,1.1,.4),"steel","Metal",collide=False)
    s.part(g,"ServicePitPlate",(33,1.05,-59),(12,.1,17),"steel","DiamondPlate",collide=False)
    for x in (24,44):
        s.part(g,"VehicleLiftPost",(x,5.5,-64),(.9,9,1),"yellow","Metal")
    s.part(g,"ToolBench",(18,2.8,-75),(8,3.6,5),"teal","Metal")
    s.part(g,"ToolPegboard",(18,7,-81.3),(8,4,.2),"wood","Wood",collide=False)
    for x in (15,17,19,21):
        s.part(g,"HangingTool",(x,7,-81),(.2,1.7,.25),"steel","Metal",collide=False)
    s.part(g,"ReceptionCounter",(72,2.8,-54),(10,3.6,3),"teal","Wood")
    for x in (59,65,71):
        chair(s,g,x,1,-74)
    for x,z in [(32,-48),(33,-72),(66,-63)]:
        s.light(g,x,14.5,z,warm=False)

    # South-east: freight hall, three ground entrances and two mezzanine approaches.
    g = "04_ArmazemFerrovia"
    s.box(g,"WarehouseFloor",0,104,0,1,32,100,color="concrete")
    s.wall(g,"WarehouseFront","X",32,0,104,1,24,[(20,44,1,18,"door"),(80,88,1,12,"door"),(54,70,9,16,"window")])
    s.wall(g,"WarehouseRear","X",100,0,104,1,24,[(44,54,1,12,"door"),(10,30,17,22,"window"),(72,92,17,22,"window")])
    s.wall(g,"WarehouseWest","Z",0,32,100,1,24,[(56,66,1,12,"door"),(76,84,14,24,"door")])
    s.wall(g,"WarehouseEast","Z",104,32,100,1,24,[(45,60,12,19,"window")])
    # Clerestory band and stepped gable infill close the pitched roof at both ends.
    s.box(g,"GableClosureFront",0,104,24,29,31.5,32.5,color="steel",material="Metal")
    s.box(g,"GableClosureRear",0,104,24,29,99.5,100.5,color="steel",material="Metal")
    for y in range(10):
        inset=(y+.5)*5.2
        for z in (32,100):
            s.box(g,"GableInfill",inset,104-inset,29+y*.5,29+(y+1)*.5,z-.5,z+.5,color="steel",material="Metal")
    # Pitched roof ridge sits above the closure bands, eaves at Y29.
    for x,angle in [(25.5,5.5),(78.5,-5.5)]:
        s.part(g,"PitchedMetalRoof",(x,31.5,66),(53.3,.6,71),"steel","Metal",rotation=(0,0,angle))
    for z in (33,50,67,84,99):
        s.part(g,"RoofTieBeam",(52,23.5,z),(103,.45,.45),"steel","Metal",collide=False)
        s.beam(g,"RoofBrace",(2,23.5,z),(52,28,z),.25)
        s.beam(g,"RoofBrace",(52,28,z),(102,23.5,z),.25)
    for x in (1,103):
        for z in (34,55,76,98):
            s.part(g,"BrickPier",(x,12,z),(1.6,22,1.6),"brickDark",collide=False)
    s.sign(g,"WarehouseName",(52,21,31.25),(84,3,.3),"ARMAZÉM FERROVIA  /  CARGAS & ENCOMENDAS",color="teal")
    s.sign(g,"LoadingBay",(32,18.8,31.2),(22,1.2,.25),"RECEBIMENTO  02",color="rust")
    s.sign(g,"Personnel",(84,13,31.3),(12,1.2,.2),"ACESSO PESSOAL")
    for a,b,c,d in [(0,76,76,98),(90,102,76,98),(76,90,82,98)]:
        s.box(g,"MezzanineSlab",a,b,13.4,14,c,d,color="wood",material="WoodPlanks")
    for x in (4,36,70,100):
        s.part(g,"MezzanineColumn",(x,7,78),(.65,12.8,.65),"steel","Metal")
    for a,b in [(2,76),(90,102)]:
        s.part(g,"MezzanineGuard",((a+b)/2,15.7,76),(b-a,3.4,.18),"steel","Metal")
    for x in (76,90):
        s.part(g,"StairVoidGuard",(x,15.7,79),(.18,3.4,6),"steel","Metal")
    s.stairs(g,"WarehouseInternalStair",83,50,1,10,32,13,1)
    s.stairs(g,"WarehouseEscapeStair",-9,42,1,10,32,13,1)
    s.box(g,"WarehouseStairFooting",-15,-3,0,1,38,44)
    s.box(g,"WarehouseEscapeLanding",-16,.5,13.4,14,74,86,color="steel",material="DiamondPlate")
    for x in (-14,-3):
        s.part(g,"EscapeLandingColumn",(x,6.7,84),(.4,13.4,.4),"steel","Metal")
    s.part(g,"WarehouseLandingGuard",(-16,15.7,80),(.18,3.4,12),"steel","Metal")
    s.part(g,"WarehouseLandingEnd",(-8,15.7,86),(16,3.4,.18),"steel","Metal")
    for x in (20,44,64):
        for z in (56,68):
            rack(s,g,x,z)
    desk(s,g,27,14,92)
    desk(s,g,57,14,92)
    s.part(g,"MezzanineRecords",(98,17,92),(3,6,9),"teal","Metal")
    for x,z in [(20,46),(58,45),(20,88),(58,88)]:
        s.light(g,x,22,z,warm=True)
    for x,z in [(18.5,34),(45.5,34),(42.5,98),(55.5,98)]:
        s.part(g,"LoadingBollard",(x,2,z),(.6,3,.6),"yellow","Metal")

    # South-west: marked parking courtyard and a delivery stop, not piles of cover.
    g = "05_PatioDeServico"
    s.box(g,"ParkingSurface",-110,-26,0,.15,32,94,color="asphalt",material="Asphalt")
    for x in range(-108,-33,12):
        s.part(g,"ParkingStripe",(x,.17,52),(.18,.03,22),"white",collide=False)
        s.part(g,"WheelStop",(x+6,.45,62),(7,.6,.7),"concrete")
    car(s,g,-102,51,"teal")
    car(s,g,-78,51,"rust")
    s.sign(g,"ParkingSign",(-105,7,34),(8,3,.2),"P  /  CLIENTES",color="teal")
    s.part(g,"ParkingSignPost",(-105,3.5,34),(.2,7,.2),"steel","Metal",collide=False)
    for x in (-85,-71):
        s.part(g,"Planter",(x,1.8,85),(9,3.6,4),"brick")
        s.part(g,"PlanterSoil",(x,3.65,85),(8.5,.15,3.5),"brickDark",collide=False)
        s.part(g,"ClippedShrub",(x,4.6,85),(8,1.9,3),"green","SmoothPlastic",collide=False)
    for x,z in [(-102,-101),(73,-91)]:
        s.part(g,"ServiceWasteBin",(x,2.4,z),(4,4.8,3),"teal","Metal")
        s.part(g,"BinLid",(x,4.9,z),(4.3,.25,3.3),"steel","Metal",collide=False)
    for x,z in [(61,43),(65,43)]:
        s.part(g,"DeliveryPallet",(x,1.3,z),(3,.6,4),"wood","Wood")
    # Legible service lanes in the ground plane.
    for x0,x1,z0,z1 in [(-126,112,-110,-96),(-26,10,-94,-30),(82,114,-92,-30),(-24,-18,30,108),(-110,114,102,110)]:
        s.box(g,"ServiceLane",x0,x1,0,.12,z0,z1,color="paving")

    # Perimeter reads as a closed industrial block; quarantine gates end the street.
    g = "06_Perimetro"
    for z in (-113,113):
        s.part(g,"BoundaryBrickWall",(0,6,z),(268,12,1.2),"brickDark","Brick")
        s.part(g,"WallCoping",(0,12.2,z),(269,.4,1.6),"trim")
    for x in (-133,133):
        for z in (-65,65):
            s.part(g,"SideBoundary",(x,6,z),(1.2,12,94),"brickDark","Brick")
        s.part(g,"QuarantineGate",(x,7,0),(1,14,36),"steel","Metal",transparency=.12)
        for z in range(-16,17,4):
            s.part(g,"GateStiffener",(x+(.6 if x<0 else -.6),7,z),(.25,14,.2),"rust","Metal",collide=False)
    for x in (-116,114):
        s.sign(g,"QuarantineNotice",(x,7,-17),(14,3,.2),"QUARENTENA  /  ACESSO RESTRITO",face=2,color="rust")
    # Spawn markers are authored with the map; round code uses these exact positions.
    for name,pos in [("HumanSpawn",(-73,1,-24)),("ZombieSpawn",(85,1,106)),("LobbySpawn",(-10,1,24))]:
        marker=s.part("Spawns",name,pos,(2,.2,2),"teal",collide=False,transparency=1)
        p=marker.find("Properties")
        # Markers deliberately have no physics or spawn behavior of their own.
    return s


def chair(s,g,x,y,z):
    s.part(g,"ChairSeat",(x,y+1.8,z),(2.2,.3,2.2),"teal","Wood")
    s.part(g,"ChairBack",(x,y+3,z+1),(2.2,2.4,.25),"teal","Wood",collide=False)
    for dx in (-.8,.8):
        for dz in (-.8,.8):
            s.part(g,"ChairLeg",(x+dx,y+.8,z+dz),(.15,1.6,.15),"steel","Metal",collide=False)


def desk(s,g,x,y,z):
    s.part(g,"DeskTop",(x,y+3.2,z),(9,.35,4),"wood","Wood")
    for dx in (-3.8,3.8):
        s.part(g,"DeskPedestal",(x+dx,y+1.5,z),(1.2,3,3),"steel","Metal")
    s.part(g,"Monitor",(x,y+4.5,z+1),(2.6,1.9,.3),"steel","SmoothPlastic",collide=False)
    s.part(g,"MonitorScreen",(x,y+4.5,z+.82),(2.3,1.5,.03),"teal","SmoothPlastic",collide=False)
    chair(s,g,x,y,z-3.5)


def rack(s,g,x,z):
    for dx in (-4.5,4.5):
        for dz in (-1.8,1.8):
            s.part(g,"RackUpright",(x+dx,5.8,z+dz),(.3,9.6,.3),"teal","Metal")
    for yy in (1.5,5,8.5):
        s.part(g,"RackShelf",(x,yy,z),(9.4,.25,4),"steel","Metal")
        for dx in (-2.5,2.5):
            s.part(g,"FreightCarton",(x+dx,yy+1.1,z),(3.2,1.9,3),"wood","Wood",collide=False)


def car(s,g,x,z,color):
    s.part(g,"ParkedCarBody",(x,2,z),(6.8,2.8,14),color,"Metal")
    s.part(g,"CarCabin",(x,4,z+1),(5.8,2.6,7),color,"Metal")
    for zz in (z-2.55,z+4.55):
        s.part(g,"CarWindshield",(x,4.1,zz),(5.2,1.8,.08),"glass","Glass",collide=False,transparency=.2)
    for xx in (x-2.94,x+2.94):
        s.part(g,"CarSideWindow",(xx,4.1,z+1),(.08,1.8,5.8),"glass","Glass",collide=False,transparency=.2)
    for xx in (x-3.2,x+3.2):
        for zz in (z-4.3,z+4.3):
            s.part(g,"Wheel",(xx,1.4,zz),(1,2.8,2.8),"asphalt","SmoothPlastic",collide=False,shape=2)
            s.part(g,"WheelHub",(xx+(-.55 if xx<x else .55),1.4,zz),(.1,1.4,1.4),"steel","Metal",collide=False,shape=2)
    for xx in (x-2.3,x+2.3):
        s.part(g,"Headlamp",(xx,2,z-7.05),(1.5,.65,.12),"white","Glass",collide=False)
        s.part(g,"TailLamp",(xx,2,z+7.05),(1.5,.65,.12),"rust","Glass",collide=False)
    for zz in (z-7,z+7):
        s.part(g,"Bumper",(x,1.2,zz),(6.8,.5,.4),"steel","Metal",collide=False)


ROUTES = [
    {"name":"Rua e travessia", "points":[[-120,.1,8],[-10,.1,8],[-10,.1,-10],[112,.1,-10]]},
    {"name":"Mercearia: entrada, loja e estoque", "points":[[-73,.6,-24],[-73,1,-36],[-73,1,-63],[-85,1,-63],[-85,1,-84],[-85,.12,-102],[-12,.12,-102],[-12,.12,-24]]},
    {"name":"Mercearia: saída lateral", "points":[[-85,1,-84],[-38,1,-84],[-38,1,-80],[-18,.12,-80],[-18,.12,-36]]},
    {"name":"Escritórios: escada interna", "points":[[-73,1,-36],[-51,1,-36],[-39,1,-34],[-39,1,-36],[-39,16,-66],[-39,16,-74],[-62,16,-74],[-62,16,-63],[-70,16,-63],[-70,16,-44],[-86,16,-44]]},
    {"name":"Escritórios: escada de incêndio", "points":[[-116,.12,-24],[-116,1,-36],[-116,16,-66],[-116,16,-74],[-98,16,-74],[-96,16,-74],[-96,16,-56]]},
    {"name":"Oficina: garagem e saída traseira", "points":[[34,.6,-24],[34,1,-40],[34,1,-48],[40,1,-48],[40,1,-76],[40,.12,-96],[100,.12,-96],[100,.12,-24]]},
    {"name":"Oficina: recepção e saída lateral", "points":[[64,.6,-24],[64,1,-40],[64,1,-46],[60,1,-46],[60,1,-64],[88,.12,-64],[100,.12,-64]]},
    {"name":"Oficina: ligação interna", "points":[[64,1,-46],[44,1,-46]]},
    {"name":"Armazém: carga e saída traseira", "points":[[32,.6,24],[32,1,44],[32,1,74],[49,1,74],[49,1,106],[85,.12,106]]},
    {"name":"Armazém: acesso de pessoal", "points":[[84,.6,24],[84,1,44],[84,1,47]]},
    {"name":"Armazém: saída oeste", "points":[[32,1,44],[8,1,44],[8,1,61],[-22,.12,61],[-22,.12,26]]},
    {"name":"Mezanino: escada interna", "points":[[84,1,44],[83,1,50],[83,14,82],[83,14,84.5],[10,14,84.5],[10,14,80]]},
    {"name":"Mezanino: escada externa", "points":[[-9,.12,36],[-9,1,42],[-9,14,74],[-9,14,80],[10,14,80]]},
    {"name":"Circuito externo sul", "points":[[-118,.12,26],[-118,.12,106],[118,.12,106],[118,.12,24]]},
]


def floorplan():
    # Intentionally a measured diagram, not a render or a claim about in-game art.
    svg=['<svg xmlns="http://www.w3.org/2000/svg" viewBox="-150 -145 300 310" width="1000" height="1033">',
         '<style>text{font:4px sans-serif;fill:#ede7d5} .title{font-size:7px;font-weight:bold} .small{font-size:3px} .route{fill:none;stroke:#e3af5c;stroke-width:1;stroke-dasharray:3 2} .door{stroke:#86dec5;stroke-width:3}</style>',
         '<rect x="-150" y="-145" width="300" height="310" fill="#172529"/>',
         '<text x="-134" y="-130" class="title">SANTA AURORA — PLANTA TÉRREA</text>',
         '<rect x="-134" y="-114" width="268" height="228" rx="2" fill="#434a48" stroke="#b7a78c"/>',
         '<rect x="-126" y="-30" width="252" height="60" fill="#99978a"/>',
         '<rect x="-126" y="-18" width="252" height="36" fill="#303b40"/>']
    for x in range(-116,117,16):
        svg.append(f'<path d="M{x} 0h8" stroke="#d9b45f" stroke-width=".5"/>')
    for x0,x1,z0,z1,label,color in [(-108,-28,-94,-30,"MERCEARIA / ESCRITÓRIOS","#9d7059"),(12,80,-82,-30,"OFICINA LUZ","#8f9883"),(0,104,32,100,"ARMAZÉM FERROVIA","#836252")]:
        svg.append(f'<rect x="{x0}" y="{z0}" width="{x1-x0}" height="{z1-z0}" fill="{color}" stroke="#dfcdb0" stroke-width="1"/>')
        svg.append(f'<text x="{(x0+x1)/2}" y="{(z0+z1)/2}" text-anchor="middle">{label}</text>')
    svg += ['<text x="-100" y="74">ESTACIONAMENTO</text>', '<text x="-82" y="-102">ACESSO DE SERVIÇO</text>',
            '<text x="-124" y="-3">RUA AURORA</text>', '<text x="-22" y="124">NORTE = -Z  /  UNIDADE: STUD</text>']
    scene=build()
    for portal in scene.portals:
        if portal['kind']!='door' or portal['bottom']>1: continue
        a,b,f=portal['start'],portal['end'],portal['fixed']
        d=f'M{a} {f}H{b}' if portal['axis']=='X' else f'M{f} {a}V{b}'
        svg.append(f'<path class="door" d="{d}"/>')
    for route in ROUTES:
        if 'escada' in route['name'].lower() or 'Mezanino' in route['name']: continue
        points=' '.join(f'{p[0]},{p[2]}' for p in route['points'])
        svg.append(f'<polyline class="route" points="{points}"/>')
    svg += ['<text x="-134" y="138">VERDE: VÃOS REAIS  ·  TRACEJADO: PERCURSOS A VALIDAR</text>',
            '<text x="-134" y="147">Andar superior: 2 acessos / Mezanino: 2 acessos</text>',
            '<text x="-134" y="156" class="small">Diagrama de projeto. Não representa uma captura do Roblox Studio.</text>', '</svg>']
    return '\n'.join(svg)+'\n'


def outputs():
    s=build()
    ET.indent(s.root,space="  ")
    xml=ET.tostring(s.root,encoding="unicode")+'\n'
    manifest={"map":"SantaAurora","units":"studs","avatar":{"radius":1.5,"height":5.5,"step":1},
              "parts":s.parts,"portals":s.portals,"routes":ROUTES,"lights":s.lights}
    return {OUT/"SantaAurora.rbxmx":xml,
            ROOT/"docs/santa-aurora-geometry.json":json.dumps(manifest,separators=(',',':'),ensure_ascii=False)+'\n',
            ROOT/"docs/SANTA_AURORA_PLAN.svg":floorplan()}


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check',action='store_true',help='Fail if checked-in outputs differ; never write.')
    args=parser.parse_args()
    for path,content in outputs().items():
        if args.check:
            if not path.exists() or path.read_text()!=content:
                raise SystemExit(f'Generated output is stale: {path.relative_to(ROOT)}')
        else:
            path.parent.mkdir(parents=True,exist_ok=True)
            path.write_text(content)
    s=build()
    print(f'Santa Aurora: {len(s.parts)} anchored parts, {s.lights} lights, {len(s.portals)} real wall openings')


if __name__=='__main__':
    main()
