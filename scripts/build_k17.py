#!/usr/bin/env python3
"""K-17: original 600-stud Zombie Mod foundry, authored independently of Santa Aurora.

No external assets, old scene imports, geometry conversion or Python dependencies.
Coordinates are Roblox studs; +Y is up, -Z is north. Every building is an edit-time
Model. The XML, measured route specification and plans are deterministic outputs.
"""
from __future__ import annotations
import argparse
from collections import defaultdict
import json
import math
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
COLORS = {
    'concrete': (132,136,129), 'aged': (101,109,102), 'plaster': (171,171,153),
    'dark': (42,50,49), 'steel': (72,85,81), 'rust': (139,89,60),
    'olive': (94,104,76), 'brick': (116,81,64), 'glass': (124,157,153),
    'light': (240,209,148), 'white': (208,207,184), 'yellow': (197,161,66),
    'red': (165,65,48), 'wood': (119,100,73), 'asphalt': (58,66,65),
    'water': (49,77,67), 'blue': (69,100,111),
}
MATERIALS = {'Concrete':816,'Brick':848,'Metal':1088,'DiamondPlate':1056,
             'CorrodedMetal':1040,'Glass':1568,'WoodPlanks':528,'Wood':512,
             'Asphalt':1376,'SmoothPlastic':272,'Neon':288,'Slate':800}


def union_cells(rects, holes=()):
    """Nonoverlapping rectangular cover of a union, subtracting holes.

    Merge equal strips horizontally and vertically to keep the instance count low.
    Rectangles are (x0,x1,z0,z1); no voxel grids or tiny decorative floor tiles.
    """
    xs=sorted({v for r in [*rects,*holes] for v in r[:2]})
    zs=sorted({v for r in [*rects,*holes] for v in r[2:]})
    active={}; result=[]
    for z0,z1 in zip(zs,zs[1:]):
        intervals=[]; start=None
        for x0,x1 in list(zip(xs,xs[1:]))+[(xs[-1],xs[-1])]:
            x,z=(x0+x1)/2,(z0+z1)/2
            filled=x0<x1 and any(a<=x<=b and c<=z<=d for a,b,c,d in rects) and not any(a<x<b and c<z<d for a,b,c,d in holes)
            if filled and start is None: start=x0
            if not filled and start is not None:
                intervals.append((start,x0)); start=None
        fresh={}
        for key in intervals:
            fresh[key]=active.pop(key,(key[0],key[1],z0,z0))[:3]+(z1,)
        result.extend(active.values()); active=fresh
    return result+list(active.values())


def boundary(rects):
    """Outer boundary of a union, with adjacent collinear edges merged."""
    cells=union_cells(rects)
    xs=sorted({v for r in cells for v in r[:2]});zs=sorted({v for r in cells for v in r[2:]})
    occupied={(i,j) for i in range(len(xs)-1) for j in range(len(zs)-1)
              if any(a<=(xs[i]+xs[i+1])/2<=b and c<=(zs[j]+zs[j+1])/2<=d for a,b,c,d in cells)}
    edges=defaultdict(list)
    for i,j in occupied:
        for di,dj,axis,fixed,a,b in [(0,-1,'X',zs[j],xs[i],xs[i+1]),(0,1,'X',zs[j+1],xs[i],xs[i+1]),
                                    (-1,0,'Z',xs[i],zs[j],zs[j+1]),(1,0,'Z',xs[i+1],zs[j],zs[j+1])]:
            if (i+di,j+dj) not in occupied: edges[axis,fixed].append((a,b))
    result=[]
    for (axis,fixed), spans in sorted(edges.items()):
        start,end=sorted(spans)[0]
        for a,b in sorted(spans)[1:]:
            if abs(a-end)<.001: end=b
            else: result.append((axis,fixed,start,end));start,end=a,b
        result.append((axis,fixed,start,end))
    return result


class Map:
    def __init__(self):
        self.xml=ET.Element('roblox',version='4')
        self.root=self.item(self.xml,'Model','ZO_K17Foundry')
        self.models={}; self.parts=0; self.lights=0; self.shadow_lights=0
        self.routes=[]; self.defenses=[]; self.buildings=[]; self.openings=[]

    @staticmethod
    def prop(p,kind,name,value):
        out=ET.SubElement(p,kind,name=name)
        if isinstance(value,(list,tuple)):
            for k,v in zip({'Vector3':'XYZ','Vector2':'XY','Color3':'RGB'}[kind],value): ET.SubElement(out,k).text=str(v)
        else: out.text=str(value).lower() if isinstance(value,bool) else str(value)
        return out

    def item(self,parent,cls,name):
        item=ET.SubElement(parent,'Item',{'class':cls})
        self.prop(ET.SubElement(item,'Properties'),'string','Name',name)
        return item

    def group(self,name):
        if name not in self.models:
            self.models[name]=self.item(self.root,'Model',name)
        return self.models[name]

    def box(self,group,name,rect,bottom,top,color='concrete',material='Concrete',
            physical=True,alpha=0,shadow=True):
        x0,x1,z0,z1=rect
        assert x1>x0 and z1>z0 and top>bottom,(name,rect,bottom,top)
        item=self.item(self.group(group),'Part',name); p=item.find('Properties')
        self.prop(p,'Vector3','size',(x1-x0,top-bottom,z1-z0))
        self.prop(p,'Color3','Color',tuple(c/255 for c in COLORS[color]))
        self.prop(p,'token','Material',MATERIALS[material])
        for key,value in [('Anchored',True),('CanCollide',physical),('CanTouch',False),('CanQuery',physical),('CastShadow',shadow and alpha<.5)]:
            self.prop(p,'bool',key,value)
        self.prop(p,'float','Transparency',alpha)
        self.prop(p,'token','TopSurface',0);self.prop(p,'token','BottomSurface',0)
        cf=ET.SubElement(p,'CoordinateFrame',name='CFrame')
        for key,value in [('X',(x0+x1)/2),('Y',(bottom+top)/2),('Z',(z0+z1)/2)]+[(f'R{i}{j}',int(i==j)) for i in range(3) for j in range(3)]:
            ET.SubElement(cf,key).text=str(value)
        self.parts+=1
        return item

    def slab(self,group,name,rects,top,holes=(),thick=.6,**kw):
        for rect in union_cells(rects,holes):self.box(group,name,rect,top-thick,top,**kw)

    def line(self,group,name,a,b,width=.2,color='steel',physical=False):
        dx,dy,dz=[b[i]-a[i] for i in range(3)];length=math.dist(a,b)
        item=self.box(group,name,(-width/2,width/2,-length/2,length/2),-width/2,width/2,color,'Metal',physical=physical)
        p=item.find('Properties');cf=p.find('CoordinateFrame')
        yaw=math.atan2(dx,dz);pitch=-math.atan2(dy,math.hypot(dx,dz))
        matrix=[math.cos(yaw),math.sin(yaw)*math.sin(pitch),math.sin(yaw)*math.cos(pitch),
                0,math.cos(pitch),-math.sin(pitch),-math.sin(yaw),math.cos(yaw)*math.sin(pitch),math.cos(yaw)*math.cos(pitch)]
        for key,value in zip(['X','Y','Z']+[f'R{i}{j}' for i in range(3) for j in range(3)],[(a[i]+b[i])/2 for i in range(3)]+matrix):
            cf.find(key).text=str(round(value,6))
        return item

    def pipe(self,g,a,b,diameter=.75):
        item=self.line(g,'SteamDistribution',a,b,diameter,'rust')
        p=item.find('Properties');cf=p.find('CoordinateFrame')
        r=[[float(cf.find(f'R{i}{j}').text) for j in range(3)] for i in range(3)]
        for i in range(3):
            for j,value in enumerate((r[i][2],r[i][1],-r[i][0])):cf.find(f'R{i}{j}').text=str(value)
        size=p.find('Vector3[@name="size"]')
        for key,value in zip('XYZ',(math.dist(a,b),diameter,diameter)):size.find(key).text=str(value)
        self.prop(p,'token','shape',2)

    def wall(self,g,name,axis,fixed,a,b,low,high,holes=(),color='aged',material='Concrete',thick=1):
        # hole=(start,end,sill,head,kind); windows get real framed glazing.
        assert all(a<=h[0]<h[1]<=b and low<=h[2]<h[3]<=high for h in holes),(g,name,holes)
        for u0,u1,v0,v1 in union_cells([(a,b,low,high)],[(h[0],h[1],h[2],h[3]) for h in holes]):
            rect=(u0,u1,fixed-thick/2,fixed+thick/2) if axis=='X' else (fixed-thick/2,fixed+thick/2,u0,u1)
            self.box(g,name,rect,v0,v1,color,material)
        for i,(u0,u1,v0,v1,kind) in enumerate(holes):
            self.openings.append({'model':g,'name':name,'axis':axis,'fixed':fixed,'start':u0,'end':u1,'bottom':v0,'top':v1,'kind':kind})
            if kind=='window':
                rect=(u0,u1,fixed-.08,fixed+.08) if axis=='X' else (fixed-.08,fixed+.08,u0,u1)
                self.box(g,name+'_Glass',rect,v0,v1,'glass','Glass',alpha=.5,shadow=False)
                # One outer frame and one mullion; limited repetition per bay.
                for aa,bb,cc,dd in [(u0,u1,v0,v0+.2),(u0,u1,v1-.2,v1),((u0+u1)/2-.1,(u0+u1)/2+.1,v0,v1)]:
                    r=(aa,bb,fixed-.2,fixed+.2) if axis=='X' else (fixed-.2,fixed+.2,aa,bb)
                    self.box(g,name+'_Frame',r,cc,dd,'steel','Metal',physical=False)

    def rail(self,g,a,b,foot):
        # Actual bars stop bodies; gaps between bars remain visible and shootable.
        for h in (1.5,3.4): self.line(g,'GuardRail',(a[0],foot+h,a[1]),(b[0],foot+h,b[1]),.18,physical=True)
        count=max(1,math.ceil(math.dist(a,b)/12))
        for i in range(count+1):
            x,z=[a[j]+(b[j]-a[j])*i/count for j in range(2)]
            self.box(g,'RailPost',(x-.1,x+.1,z-.1,z+.1),foot,foot+3.5,'steel','Metal',physical=False)

    def stair(self,g,name,x,z,axis,direction,width,run,rise,base,steps=None):
        steps=steps or math.ceil(abs(rise)/.5)
        for i in range(steps):
            u=direction*(i+.5)*run/steps;yy=base+rise*(i+1)/steps
            xx,zz=(x+u,z) if axis=='X' else (x,z+u)
            rect=(xx-run/steps/2-.01,xx+run/steps/2+.01,zz-width/2,zz+width/2) if axis=='X' else (xx-width/2,xx+width/2,zz-run/steps/2-.01,zz+run/steps/2+.01)
            self.box(g,name+'_Tread',rect,yy-.55,yy,'steel' if base<0 else 'concrete','DiamondPlate' if base<0 else 'Concrete')
        for side in (-1,1):
            aa=(x,base+3.4,z+side*(width/2+.2)) if axis=='X' else (x+side*(width/2+.2),base+3.4,z)
            bb=(x+direction*run,base+rise+3.4,z+side*(width/2+.2)) if axis=='X' else (x+side*(width/2+.2),base+rise+3.4,z+direction*run)
            self.line(g,name+'_Handrail',aa,bb,.18)
            for i in sorted({*range(0,steps+1,7),steps}):
                point=tuple(aa[j]+(bb[j]-aa[j])*i/steps for j in range(3))
                self.box(g,name+'_RailPost',(point[0]-.08,point[0]+.08,point[2]-.08,point[2]+.08),point[1]-3.4,point[1],'steel','Metal',physical=False)

    def lamp(self,g,x,y,z,emergency=False,shadow=False,range_=38):
        item=self.box(g,'EmergencyFixture' if emergency else 'IndustrialLuminaire',(x-1.4,x+1.4,z-.5,z+.5),y-.2,y,'red' if emergency else 'light','Neon',physical=False,shadow=False)
        p=self.item(item,'PointLight','PracticalLight').find('Properties')
        self.prop(p,'Color3','Color',(1,.35,.18) if emergency else (1,.86,.65))
        self.prop(p,'float','Range',range_);self.prop(p,'float','Brightness',1.1 if shadow else .8)
        self.prop(p,'bool','Shadows',shadow)
        self.lights+=1;self.shadow_lights+=int(shadow)

    def sign(self,g,x,y,z,text,width=24,face=5,color='olive'):
        item=self.box(g,'Wayfinding',(x-width/2,x+width/2,z-.12,z+.12),y-1.1,y+1.1,color,'Metal',physical=False)
        gui=self.item(item,'SurfaceGui','Lettering');p=gui.find('Properties')
        self.prop(p,'token','Face',face);self.prop(p,'Vector2','CanvasSize',(1024,128))
        self.prop(p,'float','LightInfluence',.25);self.prop(p,'float','MaxDistance',190)
        label=self.item(gui,'TextLabel','Text')
        q=label.find('Properties');self.prop(q,'string','Text',text);self.prop(q,'bool','TextScaled',True)
        self.prop(q,'float','BackgroundTransparency',1);self.prop(q,'Color3','TextColor3',tuple(v/255 for v in COLORS['white']))
        self.prop(q,'token','Font',19)
        dim=ET.SubElement(q,'UDim2',name='Size')
        for k,v in [('XS',1),('XO',0),('YS',1),('YO',0)]:ET.SubElement(dim,k).text=str(v)

    def route(self,name,points,kind='circulation'):
        self.routes.append({'name':name,'kind':kind,'points':points})

    def defend(self,id_,name,point,advantages,risks,approaches):
        self.defenses.append({'id':id_,'name':name,'point':point,'advantages':advantages,'risks':risks,'approaches':approaches})
        x,y,z=point
        marker=self.box('DefensePoints',f'{id_:02}_{name}',(x-.5,x+.5,z-.5,z+.5),y+.1,y+.2,physical=False,alpha=1)
        for key,value in [('Advantages',advantages),('Risks',risks)]:
            p=self.item(marker,'StringValue',key).find('Properties');self.prop(p,'string','Value',value)


def bench(m,g,x,z,y=1):
    m.box(g,'Workbench',(x-5,x+5,z-2,z+2),y+3,y+3.35,'wood','Wood')
    for dx in (-4,4): m.box(g,'BenchLeg',(x+dx-.15,x+dx+.15,z-1.6,z+1.6),y,y+3,'steel','Metal',physical=False)
    m.box(g,'Instrument',(x-1.4,x+1.4,z+.8,z+1.2),y+3.35,y+5,'dark','Metal',physical=False)
    m.box(g,'InstrumentScreen',(x-1.1,x+1.1,z+.77,z+.8),y+3.6,y+4.8,'olive','SmoothPlastic',physical=False)
    m.box(g,'Chair',(x-1,x+1,z-4,z-2),y+1.6,y+1.9,'olive','Metal')


def shelves(m,g,x,z,y=1,length=12):
    for dx in (-1.6,1.6):
        for dz in (-length/2+.2,length/2-.2):
            m.box(g,'ShelfUpright',(x+dx-.12,x+dx+.12,z+dz-.12,z+dz+.12),y,y+8,'steel','Metal',physical=False)
    for h in (1,4,7):
        m.box(g,'StorageShelf',(x-1.8,x+1.8,z-length/2,z+length/2),y+h,y+h+.2,'steel','Metal')
        for dz in (0,):
            m.box(g,'ArchivedMaterials',(x-1.3,x+1.3,z+dz-1.2,z+dz+1.2),y+h+.2,y+h+1.6,'wood','Wood',physical=False)


def office_block(m,name,rect,levels,color,bridges=()):
    """Two stair cores, a continuous central spine and accessible rooms on each floor.

    All buildings have distinct footprints/materials/programmes. The full stair
    wing prevents corridors ending at a staircase slot or doors opening into voids.
    """
    x0,x1,z0,z1=rect;cx=(x0+x1)/2; width=x1-x0
    stairs=[x0+16,x1-16];slots=[(x-7,x+7,z0+32,z0+64) for x in stairs]
    front=z0+76; rows=max(1,math.ceil((z1-2-front)/48))
    cuts=[front+i*(z1-2-front)/rows for i in range(rows+1)]
    m.buildings.append({'name':name,'rect':list(rect),'floors':levels,'floor_top':1,'storey':14,'roof':1+levels*14,'stairs':stairs})
    for level in range(levels+1):
        floor=1+level*14
        m.slab(name,'RoofSlab' if level==levels else 'OccupiedFloor',[rect],floor,slots if level else (),thick=1 if not level else .6,color='aged')
        if level:
            for x in stairs:
                for side in (-7,7):m.rail(name,(x+side,z0+32),(x+side,z0+64),floor)
                if level==levels:m.rail(name,(x-7,z0+32),(x+7,z0+32),floor)
                m.route(f'{name} landing connection {level}-{x}',[[x,floor,z0+69],[cx,floor,z0+69]])
        if level==levels:
            for axis,fixed,a,b in [('X',z0,x0,x1),('X',z1,x0,x1),('Z',x0,z0,z1),('Z',x1,z0,z1)]:
                m.wall(name,'RoofParapet',axis,fixed,a,b,floor,floor+3,color='aged')
            for x in stairs:
                m.box(name,'StairWeatherCanopy',(x-9,x+9,z0+30,z0+66),floor+7,floor+7.4,'steel','Metal')
                for dx in (-8,8):
                    for dz in (31,65):m.box(name,'CanopyPost',(x+dx-.12,x+dx+.12,z0+dz-.12,z0+dz+.12),floor,floor+7,'steel','Metal',physical=False)
            # Equipment sits on a service plinth on the roof, with a real approach.
            m.box(name,'VentilationPlinth',(cx+16,cx+34,z1-26,z1-10),floor,floor+.4,'concrete')
            m.box(name,'VentilationUnit',(cx+18,cx+32,z1-24,z1-12),floor+.4,floor+5,'steel','Metal')
            continue
        high=floor+13.4
        # Repeated structural bays, actual glazing and deliberate facade apertures.
        for fixed,face in [(z0,5),(z1,2)]:
            holes=[(cx-6,cx+6,floor,floor+11,'door')] if level==0 else []
            for xx in range(math.ceil(x0+16),math.floor(x1-8),24):
                if any(a-4<xx<b+4 for a,b,*_ in holes):continue
                holes.append((xx-6,xx+6,floor+4,floor+10,'window'))
            m.wall(name,'Frontage','X',fixed,x0,x1,floor,high,holes,color=color,material='Brick' if color=='brick' else 'Concrete')
            m.box(name,'FloorStringcourse',(x0-.4,x1+.4,fixed-.65,fixed+.65),high-.4,high,'concrete',physical=False)
        for side,fixed in [('west',x0),('east',x1)]:
            holes=[(z0+21,z0+31,floor,floor+11,'door')] if level==0 else []
            holes += [(z-6,z+6,floor,floor+11,'door') for s,l,z in bridges if s==side and l==level]
            for zz in range(math.ceil(z0+14),math.floor(z1-8),28):
                if any(a-9<zz<b+9 for a,b,*_ in holes):continue
                holes.append((zz-5,zz+5,floor+4,floor+10,'window'))
            m.wall(name,'SideFacade','Z',fixed,z0,z1,floor,high,holes,color=color,material='Brick' if color=='brick' else 'Concrete')
        # Cross-circulation wing, front room rows, rear rooms and main spine.
        for wall_x in (cx-8,cx+8):
            m.wall(name,'RearSpine','Z',wall_x,z0+.5,z0+20,floor,high,
                   [(z0+6,z0+16,floor,floor+11,'door')],color='plaster',thick=.6)
            for a,b in zip(cuts,cuts[1:]):
                mid=(a+b)/2
                m.wall(name,'RoomSpine','Z',wall_x,a,b,floor,high,[(mid-5,mid+5,floor,floor+11,'door')],color='plaster',thick=.6)
        for a,b in [(x0+.5,cx-8.3),(cx+8.3,x1-.5)]:
            mid=(a+b)/2
            m.wall(name,'RearRooms','X',z0+20,a,b,floor,high,[(mid-5,mid+5,floor,floor+11,'door')],color='plaster',thick=.6)
            for cut in cuts[:-1]:m.wall(name,'RoomDivider','X',cut,a,b,floor,high,[(mid-5,mid+5,floor,floor+11,'door')],color='plaster',thick=.6)
            for begin,end in [(z0+1,z0+20),*zip(cuts,cuts[1:])]:
                outer=a+9 if a<cx else b-9
                divided=b-a>55 and begin>=front
                if divided:
                    # A foyer connects two actual offices, avoiding oversized empty rooms.
                    middle=(a+b)/2;door=(begin+end)/2
                    m.wall(name,'OfficeSuiteDivider','Z',middle,begin+12,end,floor,high,
                           [(door-5,door+5,floor,floor+11,'door')],color='plaster',thick=.6)
                    bench(m,name,(a+middle)/2,begin+18,floor)
                    bench(m,name,(middle+b)/2,begin+18,floor)
                    m.route(f'{name} inner office {level}-{a}-{begin}',[[cx,floor,door],[middle,floor,door],[a+8,floor,door]])
                else:bench(m,name,outer,begin+6.5,floor)
                shelf_x=a+2 if a<cx else b-2
                shelf_z=end-6
                side='west' if a<cx else 'east'
                if any(s==side and l==level and abs(shelf_z-z)<12 for s,l,z in bridges):shelf_z=begin+8
                shelves(m,name,shelf_x,shelf_z,floor,8)
                if name=='D_Warehouse' and begin>=front:
                    inner=a+4 if a>cx else b-4
                    shelves(m,name,inner,begin+8,floor,8)
        for x in stairs:
            m.stair(name,'CoreStair',x,z0+32,'Z',1,10,32,14,floor)
        m.lamp(name,cx,floor+12,z0+28,emergency=level>0)
        for a,b in zip(cuts,cuts[1:]):m.lamp(name,cx,floor+12,(a+b)/2)
        for xx in (x0+25,x1-25):m.lamp(name,xx,floor+12,z0+77+(z1-z0-77)/2,range_=44)
        for xx in (x0+.7,x1-.7):
            # Discoloured skirting belongs to the architecture, not random rubble.
            m.box(name,'DampSkirting',(xx-.2,xx+.2,z0+.5,z1-.5),floor,floor+.8,'aged',physical=False)
    for xx in range(math.ceil(x0),math.floor(x1)+1,32):
        m.box(name,'FacadeColumn',(xx-.4,xx+.4,z1-.2,z1+.8),1,1+levels*14,'concrete',physical=False)
    m.sign(name,cx,12,z1+.7,name.replace('_',' ').upper(),width=min(width-8,62),face=2)
    for level in range(levels):
        y=1+14*level
        # The stair test ends on the landing rather than on the last tread.
        for i,x in enumerate(stairs):
            m.route(f'{name} stair {i+1} floor {level+1}',[[x,y,z0+29],[x,y,z0+32],[x,y+14,z0+64],[x,y+14,z0+69]],'stair')
        m.route(f'{name} main corridor {level}',[[cx,y,z0+4],[cx,y,z1-4]])
        for side in (-1,1):
            xx=(x0+cx-8)/2 if side<0 else (cx+8+x1)/2
            m.route(f'{name} rear room {level}-{side}',[[cx,y,z0+11],[xx,y,z0+11]])
            for j,(a,b) in enumerate(zip(cuts,cuts[1:])):
                zz=(a+b)/2
                m.route(f'{name} room {level}-{side}-{j}',[[cx,y,zz],[xx,y,zz]])
    m.route(f'{name} street entrance',[[cx,0,z1+6],[cx,1,z1-8]])
    m.route(f'{name} rear entrance',[[cx,0,z0-6],[cx,1,z0+8]])
    for x,end in [(x0,x0+16),(x1,x1-16)]:
        outside=x-6 if x==x0 else x+6
        m.route(f'{name} side entrance {x}',[[outside,0,z0+26],[end,1,z0+26],[cx,1,z0+26]])


SHAFTS=[(22,38,-112,-60),(132,148,122,174),(-260,-208,180,196)]
TUNNELS=[(-10,10,-228,228),(-230,230,-222,-202),(-230,-210,-212,188),
         (-230,230,168,188),(210,230,-212,188),(-10,38,-130,-110),
         (132,148,172,188),(-212,-198,180,196),(-220,-36,134,154),(-100,-36,122,164),(-36,0,134,154)]


def underground(m):
    g='U1_MaintenanceNetwork'
    m.slab(g,'TunnelFloor',TUNNELS,-24,thick=1,color='aged')
    m.slab(g,'TunnelCeiling',TUNNELS,-13.5,holes=SHAFTS,color='aged')
    for axis,fixed,a,b in boundary(TUNNELS):
        openings=[]
        for x0,x1,z0,z1 in SHAFTS:
            if axis=='X' and z0<=fixed<=z1:
                lo,hi=max(a,x0),min(b,x1)
            elif axis=='Z' and x0<=fixed<=x1:
                lo,hi=max(a,z0),min(b,z1)
            else:continue
            if hi>lo:openings.append((lo,hi,-24,-13.5,'shaft'))
        m.wall(g,'TunnelLining',axis,fixed,a,b,-24,-13.5,openings,color='aged')
    for x in (-100,-36):
        m.wall(g,'TechnicalRoomPortal','Z',x,134,154,-24,-13.5,[(139,149,-24,-14,'door')],color='steel',material='Metal',thick=.5)
    # Sewer water is a shallow visual channel; continuous walkable slab remains below.
    for x in (0,-220,220):
        m.box(g,'DrainChannel',(x-2,x+2,-200,160),-24,-23.96,'water','Glass',physical=False,alpha=.25)
        for z in (-180,-100,-20,60,140):
            m.lamp(g,x,-14.3,z,emergency=(z==-20),range_=47)
    for z in (-212,178):
        for x in (-160,-80,80,160):m.lamp(g,x,-14.3,z,range_=47)
    for x in (-97,-39):
        m.box(g,'PumpControlCabinet',(x-1,x+1,124,131),-24,-17,'olive','Metal')
        m.line(g,'PipeRiser',(x,-23,126),(x,-14.5,126),.6,'rust')
    m.lamp(g,-70,-14,144,emergency=True,range_=40)
    m.sign(g,-68,-16.8,122.6,'P-03  /  ESTAÇÃO DE BOMBAS',width=28,face=2)
    # Three independent, human-sized stair shafts. Ceiling and surface holes match.
    m.stair(g,'NorthAccess',30,-62,'Z',-1,12,48,-24,0,48)
    m.stair(g,'EastAccess',140,124,'Z',1,12,48,-24,0,48)
    m.stair(g,'WestAccess',-258,188,'X',1,12,48,-24,0,48)
    for rect in [(22,38,-62,-60),(132,148,122,124),(-260,-258,180,196)]:m.box(g,'ShaftEntranceThreshold',rect,-.4,0,'steel','DiamondPlate')
    for rect in SHAFTS:
        x0,x1,z0,z1=rect
        # Shaft side walls prevent leaving the stairs into unmodelled earth.
        if x1-x0<z1-z0:
            for x in (x0,x1):m.box(g,'AccessRetainingWall',(x-.3,x+.3,z0,z1),-24,1.2,'concrete')
            for x in (x0,x1):m.rail(g,(x,z0),(x,z1),0)
        else:
            for z in (z0,z1):m.box(g,'AccessRetainingWall',(x0,x1,z-.3,z+.3),-24,1.2,'concrete')
            for z in (z0,z1):m.rail(g,(x0,z),(x1,z),0)
    m.route('North sewer descent',[[30,0,-56],[30,0,-62],[30,-24,-110],[30,-24,-120],[0,-24,-120]],'underground')
    m.route('East sewer descent',[[140,0,116],[140,0,124],[140,-24,172],[140,-24,178],[0,-24,178]],'underground')
    m.route('West sewer descent',[[-266,0,188],[-258,0,188],[-210,-24,188],[-204,-24,188],[-204,-24,178]],'underground')
    m.route('Sewer main loop',[[0,-24,-120],[0,-24,-212],[-220,-24,-212],[-220,-24,178],[220,-24,178],[220,-24,-212],[0,-24,-212]],'underground')
    m.route('Pump room cross connection',[[-220,-24,144],[-72,-24,144],[0,-24,144]],'underground')


def foundry(m):
    g='C_FoundryHall'; rect=(-142,124,68,246)
    m.buildings.append({'name':g,'rect':list(rect),'floors':2,'floor_top':1,'storey':14,'roof':29,'stairs':[-131,113]})
    m.slab(g,'ProductionFloor',[rect],1,thick=1)
    catwalk=[(-142,124,70,88),(-142,124,226,244),(-142,-116,88,226),(98,124,88,226)]
    slots=[(-138,-124,96,128),(106,120,180,212)]
    m.slab(g,'ServiceGallery',catwalk,15,slots,color='steel',material='DiamondPlate')
    m.slab(g,'FactoryRoof',[rect],29,color='aged')
    m.wall(g,'ReceivingFacade','X',68,-142,124,1,28.4,[(-92,-72,1,17,'door'),(64,76,1,12,'door'),(-26,-6,8,15,'window'),(18,38,8,15,'window')],color='brick',material='Brick')
    m.wall(g,'DispatchFacade','X',246,-142,124,1,28.4,[(-20,-8,1,12,'door'),(64,76,1,12,'door'),(-120,-96,17,24,'window'),(8,32,17,24,'window')],color='brick',material='Brick')
    m.wall(g,'WestFactoryWall','Z',-142,68,246,1,28.4,[(152,164,1,12,'door'),(134,146,15,26,'door'),(190,210,17,24,'window')],color='aged')
    m.wall(g,'EastFactoryWall','Z',124,68,246,1,28.4,[(100,112,1,12,'door'),(150,170,17,24,'window')],color='aged')
    for x in (-140,-44,52,122):
        for z in (70,174,244):
            m.box(g,'SteelFrameColumn',(x-.5,x+.5,z-.5,z+.5),1,28.4,'steel','Metal')
    for z in (72,116,160,204,242):
        m.box(g,'RoofBeam',(-142,124,z-.35,z+.35),26,26.8,'steel','Metal',physical=False)
    for x in (-78,24):
        # Two machine lines, with feeder belts and surrounding circulation aisles.
        m.box(g,'PressFoundation',(x-18,x+18,124,160),1,1.6,'concrete')
        for xx in (x-13,x+13):m.box(g,'PressColumn',(xx-2,xx+2,134,150),1.6,18,'olive','Metal')
        m.box(g,'PressHead',(x-15,x+15,133,151),16,20,'olive','Metal')
        m.box(g,'PressBed',(x-12,x+12,135,149),4,6,'steel','Metal')
        m.box(g,'FeedConveyor',(x-6,x+6,104,134),2.5,3.4,'dark','Metal')
        for z in (109,116,123,130):m.box(g,'ConveyorRoller',(x-6,x+6,z-.3,z+.3),3.4,3.7,'steel','Metal',physical=False)
        m.sign(g,x,9,133,'PRENSA  /  MANTENHA DISTÂNCIA',width=25,color='yellow')
    # The crane is suspended from structural rails, directly above the press line.
    for x in (-116,98):m.box(g,'CraneRunway',(x-.4,x+.4,90,224),23,23.6,'steel','Metal',physical=False)
    m.box(g,'CraneCrossBeam',(-116,98,186,189),23.6,25,'yellow','Metal',physical=False)
    m.box(g,'HoistCarriage',(-20,-12,184,191),21,23.6,'steel','Metal',physical=False)
    m.line(g,'HoistCable',(-16,21,187),(-16,13,187),.1,'dark')
    for a,b in [((-116,88),(98,88)),((-116,226),(98,226)),((-116,88),(-116,226)),((98,88),(98,226))]:m.rail(g,a,b,15)
    m.stair(g,'WestGalleryStair',-131,96,'Z',1,10,32,14,1)
    m.stair(g,'EastGalleryStair',113,180,'Z',1,10,32,14,1)
    m.stair(g,'WestRoofStair',-156,80,'Z',1,10,64,28,1)
    m.stair(g,'EastRoofStair',160,132,'Z',1,10,64,28,1)
    for x,za,zb in [(-156,78,82),(160,130,134)]:m.box(g,'RoofStairFooting',(x-7,x+7,za,zb),0,1)
    m.box(g,'WestRoofLanding',(-163,-141,144,160),28.4,29,'steel','DiamondPlate')
    m.box(g,'EastRoofLanding',(123,167,196,212),28.4,29,'steel','DiamondPlate')
    for x,z in [(-162,158),(166,210)]:m.box(g,'LandingSupport',(x-.3,x+.3,z-.3,z+.3),0,28.4,'steel','Metal')
    for axis,fixed,a,b,holes in [('X',68,-142,124,[]),('X',246,-142,124,[]),
        ('Z',-142,68,246,[(148,158,29,32.4,'roofAccess')]),('Z',124,68,246,[(200,210,29,32.4,'roofAccess')])]:
        m.wall(g,'FactoryRoofParapet',axis,fixed,a,b,29,32.4,holes,color='aged')
    for x in (-80,20):
        for z in (112,214):
            m.box(g,'SkylightCurb',(x-16,x+16,z-8,z+8),29,30,'steel','Metal')
            m.box(g,'SkylightGlazing',(x-15.6,x+15.6,z-7.6,z+7.6),30,30.25,'glass','Glass',alpha=.35)
            for xx in (x-8,x,x+8):m.box(g,'SkylightMullion',(xx-.1,xx+.1,z-8,z+8),30.25,30.4,'steel','Metal',physical=False)
    for x,z in [(-92,80),(66,80),(-115,180),(86,180),(-72,230),(42,230)]:m.lamp(g,x,24,z,range_=52)
    m.sign(g,-82,20,67.3,'K-17  /  FUNDIÇÃO E PRENSAGEM',width=55)
    m.sign(g,70,13,67.3,'PESSOAL',width=16)
    for x,z in [(-112,206),(86,124)]:shelves(m,g,x,z,1,18)
    for x in (-106,-62,42,86):bench(m,g,x,236)
    for x in (60,75,90):m.box(g,'WeldingScreen',(x-.15,x+.15,154,188),1,10,'olive','Metal')
    m.box(g,'WeldingBackScreen',(60,90,187.8,188.2),1,10,'olive','Metal')
    for x in (67.5,82.5):
        bench(m,g,x,180)
        m.lamp(g,x,11,180,range_=24)
        m.route(f'Welding booth {x}',[[x,1,148],[x,1,164]])
    # Low timber barricade with a bypass: scenery, not a destructible system.
    for z in (73,80):m.box(g,'LoadingTimberCover',(-105,-96,z-1,z+1),1,4.5,'wood','WoodPlanks')
    m.route('Foundry receiving to dispatch',[[-82,0,58],[-82,1,78],[-48,1,94],[-48,1,174],[-48,1,214],[-14,1,214],[-14,1,252]])
    m.route('Foundry west ground access',[[-150,0,158],[-131,1,158],[-112,1,174]])
    m.route('West gallery ascent',[[-131,1,92],[-131,1,96],[-131,15,128],[-131,15,136],[-131,15,160]],'stair')
    m.route('East gallery ascent',[[113,1,174],[113,1,180],[113,15,212],[113,15,232],[80,15,232]],'stair')
    m.route('Factory gallery circuit',[[-131,15,160],[-131,15,232],[102,15,232],[102,15,176],[113,15,176],[113,15,79],[-120,15,79],[-120,15,136],[-131,15,136]])
    m.route('Foundry west roof access',[[-156,0,72],[-156,1,80],[-156,29,144],[-156,29,153],[-132,29,153],[-115,29,153],[-115,29,183],[-80,29,183]],'stair')
    m.route('Foundry east roof access',[[160,0,124],[160,1,132],[160,29,196],[160,29,205],[116,29,205],[88,29,205],[88,29,183],[-80,29,183]],'stair')


def container(m,name,x,z,y=1,plate=True):
    g='L_'+name
    if plate:m.box(g,'ContainerFloor',(x-16,x+16,z-7,z+7),y-.4,y,'rust','DiamondPlate')
    m.box(g,'ContainerRoof',(x-16,x+16,z-7,z+7),y+11.5,y+12,'rust','Metal')
    for zz in (z-7,z+7):
        m.box(g,'ContainerSide',(x-16,x+16,zz-.2,zz+.2),y,y+11.5,'olive','CorrodedMetal')
        for xx in range(round(x-15),round(x+16),5):m.box(g,'Corrugation',(xx-.12,xx+.12,zz-.35,zz+.35),y+.5,y+11,'rust','Metal',physical=False)
    m.box(g,'FreightPackage',(x-6,x+1,z+3,z+6),y,y+3,'wood','Wood')


def gantries(m):
    g='Y_ServiceGantry'
    m.box(g,'InspectionWalkway',(-44,136,-6,6),14.4,15,'steel','DiamondPlate')
    for z in (-6,6):m.rail(g,(-44,z),(136,z),15)
    for x in (-40,20,80,132):
        for z in (-5.2,5.2):m.box(g,'GantryColumn',(x-.3,x+.3,z-.3,z+.3),0,14.4,'steel','Metal')
    for z in (-7,7):m.pipe(g,(-40,11,z),(134,11,z))
    for a,b in [((134,11,-124),(134,11,120)),((134,11,120),(124,11,120)),
                ((-40,11,-7),(-40,11,-20)),((-40,11,-20),(-170,11,-20))]:m.pipe(g,a,b)
    m.stair(g,'GantryWestStair',-76,0,'X',1,10,32,14,1)
    m.stair(g,'GantryEastStair',168,0,'X',-1,10,32,14,1)
    for x in (-76,168):m.box(g,'GantryFooting',(x-2,x+2,-6,6),0,1)
    for x in (-40,80):m.lamp(g,x,19,0,range_=40)
    # Above-ground bridges have doors at both ends and supporting columns.
    for rect in [(12,40,-158,-146),(-170,-142,134,146)]:
        x0,x1,z0,z1=rect;m.box(g,'BuildingLink',rect,14.4,15,'steel','DiamondPlate')
        for z in (z0,z1):m.rail(g,(x0,z),(x1,z),15)
        for z in (z0+.7,z1-.7):m.box(g,'BridgeSupport',((x0+x1)/2-.3,(x0+x1)/2+.3,z-.3,z+.3),0,14.4,'steel','Metal')
    m.route('Gantry west ascent',[[-82,0,0],[-76,1,0],[-44,15,0],[48,15,0]],'stair')
    m.route('Gantry east ascent',[[168,1,0],[136,15,0],[48,15,0]],'stair')
    m.route('Administration power bridge',[[-68,15,-150],[144,15,-150]])
    m.route('Warehouse foundry bridge',[[-217,15,123],[-190,15,123],[-190,15,140],[-131,15,140]])


def vehicle(m,x,z,color='olive'):
    g='E_TransportYard'
    m.box(g,'AbandonedVanChassis',(x-3.7,x+3.7,z-9,z+9),.8,3.3,color,'Metal')
    m.box(g,'VanCargoBody',(x-3.5,x+3.5,z-3,z+8.6),3.3,7,color,'Metal')
    m.box(g,'VanCabin',(x-3.3,x+3.3,z-6.5,z-3),3.3,6,'steel','Metal')
    m.box(g,'VanWindscreen',(x-3,x+3,z-6.6,z-6.5),3.8,5.7,'glass','Glass',physical=False,alpha=.2)
    for xx in (x-3.8,x+3.8):
        for zz in (z-5.8,z+5.8):
            item=m.box(g,'VehicleWheel',(xx-.5,xx+.5,zz-1.4,zz+1.4),0,2.8,'dark','SmoothPlastic',physical=False)
            m.prop(item.find('Properties'),'token','shape',2)
    for zz in (z-9,z+9):m.box(g,'Bumper',(x-3.8,x+3.8,zz-.2,zz+.2),.7,1.2,'steel','Metal',physical=False)
    for xx in (x-2.6,x+2.6):m.box(g,'Headlamp',(xx-.7,xx+.7,z-9.1,z-9),2,2.7,'white','Glass',physical=False)


def exterior(m):
    g='E_TransportYard'
    m.slab(g,'SiteFoundation',[(-300,300,-300,300)],0,SHAFTS,thick=2,color='aged')
    road=[(-292,292,-292,-268),(-292,292,268,292),(-292,-268,-268,268),(268,292,-268,268)]
    m.slab(g,'PerimeterServiceRoad',road,.08,SHAFTS,thick=.08,color='asphalt',material='Asphalt')
    m.slab(g,'DispatchCourtyard',[(-158,166,-112,60)],.1,SHAFTS,thick=.1,color='concrete')
    m.box(g,'StaffParking',(180,260,104,248),0,.1,'asphalt','Asphalt')
    for z in range(112,241,16):
        m.box(g,'ParkingBay',(186,207,z-.08,z+.08),.1,.13,'white',physical=False)
        m.box(g,'WheelStop',(185,185.8,z+3,z+11),.1,.7,'aged')
    for x,z,color in [(194,120,'olive'),(194,168,'blue'),(-246,162,'rust')]:vehicle(m,x,z,color)
    for x in range(-264,265,32):
        for z in (-280,280):m.box(g,'RoadCentreDash',(x-6,x+6,z-.1,z+.1),.09,.12,'yellow',physical=False)
    for z in range(-248,249,32):
        for x in (-280,280):m.box(g,'RoadCentreDash',(x-.1,x+.1,z-6,z+6),.09,.12,'yellow',physical=False)
    for x,z in [(-275,-248),(-275,-80),(-275,100),(-120,278),(100,278),(275,120),(275,-100),(100,-278)]:
        m.box(g,'FloodlightMast',(x-.25,x+.25,z-.25,z+.25),0,26,'steel','Metal')
        m.lamp(g,x,26,z,shadow=True,range_=65)
    for x in (-299,299):m.box(g,'BoundaryRetainingWall',(x-.5,x+.5,-300,300),-2,14,'aged')
    for z in (-299,299):m.box(g,'BoundaryRetainingWall',(-298.5,298.5,z-.5,z+.5),-2,14,'aged')
    for n in range(-280,281,40):
        for x,z in [(-298,n),(298,n),(n,-298),(n,298)]:m.box(g,'RetainingButtress',(x-.6,x+.6,z-.8,z+.8),0,14.5,'concrete',physical=False)
    # Isolation fence has a deliberate open gateway; no sealed decorative room.
    for a,b in [((250,88),(264,88)),((264,88),(264,246)),((264,246),(250,246))]:
        m.rail(g,a,b,0);m.rail(g,a,b,4)
    m.sign(g,224,7,103,'ESTACIONAMENTO  /  FUNCIONÁRIOS',width=44,face=2)
    m.sign(g,0,8,298,'K-17  /  SETOR EM QUARENTENA',width=70)
    m.box(g,'SealedQuarantineGate',(-14,14,297.9,298.2),.2,12,'steel','CorrodedMetal')
    for x in (-15,15):m.box(g,'GatePost',(x-.4,x+.4,297.5,298.5),0,14,'concrete')
    for x,z in [(-52,48),(108,-94)]:
        m.box(g,'StormDrain',(x-4,x+4,z-1,z+1),.1,.15,'steel','Metal',physical=False)
        for xx in range(x-3,x+4):m.box(g,'DrainSlot',(xx-.08,xx+.08,z-.8,z+.8),.15,.17,'dark','Metal',physical=False)
    container(m,'Freight01',-80,-82)
    container(m,'Freight02',-80,-50)
    container(m,'FreightUpper',-80,-82,13,plate=False)
    m.stair('L_FreightAccess','ContainerStair',-136,-82,'X',1,10,32,12,1,24)
    m.box('L_FreightAccess','StairFooting',(-139,-133,-88,-76),0,1)
    m.box('L_FreightAccess','ContainerLanding',(-104,-96,-88,-76),12.4,13,'steel','DiamondPlate')
    m.route('Container ground passage',[[-102,1,-50],[-58,1,-50]])
    m.route('Stacked container access',[[-142,0,-82],[-136,1,-82],[-104,13,-82],[-80,13,-82]],'stair')
    m.route('Perimeter road circuit',[[-280,.08,-280],[280,.08,-280],[280,.08,280],[-280,.08,280],[-280,.08,-280]])
    m.route('Central distribution',[[0,.1,-112],[0,.1,56],[-154,.1,56],[-154,.1,-112],[-68,.1,-112]])
    m.route('North alley',[[20,0,-280],[20,0,-134],[20,.1,-50]])
    m.route('South dispatch circuit',[[-217,0,158],[-196,0,158],[-196,0,260],[266,0,260],[266,0,92],[266,0,-100]])


def defenses(m):
    data=[
        (1,'BriefingRoom',[-108,1,-144],'Balcão e duas portas controláveis','Flanco pela ala de escadas', ['Admin room','Admin rear wing']),
        (2,'Archive',[-104,15,-239],'Sala recuada no primeiro andar','Duas portas e cobertura limitada',['Admin spine','Admin rear cross hall']),
        (3,'AdministrationRoof',[-68,43,-190],'Visão do pátio e recuo amplo','Duas escadas; exposição no telhado',['Admin stair west','Admin stair east']),
        (4,'PowerControl',[108,15,-146],'Sala de controle com visão para a ligação','Invasão pelo corredor e pela ala traseira',['Power spine','Power stair wing']),
        (5,'PowerRoof',[144,29,-190],'Altura com abrigo dos equipamentos','Dois núcleos de escada e céu aberto',['Power stair west','Power stair east']),
        (6,'PipeGantry',[48,15,0],'Linha de tiro elevada e corredor estreito','Ataque pelas duas extremidades; sem teto',['Gantry west','Gantry east']),
        (7,'WarehouseStores',[-238,1,116],'Estantes e porta estreita','Flanco pela sala vizinha',['Warehouse hall','Warehouse adjacent room']),
        (8,'WarehouseUpperHall',[-217,15,108],'Corredor de longa visibilidade','Ambas as escadas levam ao mesmo pavimento',['Warehouse west stair','Warehouse east stair']),
        (9,'WarehouseRoof',[-217,29,24],'Recuo amplo na cobertura','Duas escadas sem invulnerabilidade',['Warehouse west stair','Warehouse east stair']),
        (10,'ReceivingBarricade',[-82,1,80],'Cobertura baixa no recebimento','Laterais abertas; barricada estática',['Loading door','Production hall']),
        (11,'FactoryGallery',[-131,15,160],'Cobertura vertical e visão do maquinário','Duas escadas e ligação com o depósito',['West gallery stair','Warehouse bridge','East gallery stair']),
        (12,'FactoryRoof',[-80,29,183],'Cobertura extensa com claraboias','Duas escadas externas e exposição',['West roof stair','East roof stair']),
        (13,'TowerControl',[230,43,58],'Sala alta com gargalo de entrada','Duas escadas desembocam no corredor',['Tower west stair','Tower east stair']),
        (14,'FreightContainer',[-80,13,-82],'Interior comprido e acesso elevado','Ataque pela escada; saída oposta exige queda',['Container stair']),
        (15,'PumpRoom',[-72,-24,144],'Sala técnica subterrânea com duas portas','Pode ser cercada pelos dois túneis',['West maintenance line','Central maintenance line']),
    ]
    for row in data:m.defend(*row)
    # A real route to every named position, in addition to floor/stair circulation.
    for name,points in [
        ('D01 hall',[[-68,1,-150],[-108,1,-150],[-108,1,-144]]),
        ('D01 rear',[[-112,1,-181],[-112,1,-164],[-108,1,-164],[-108,1,-144]]),
        ('D02 hall',[[-68,15,-239],[-104,15,-239]]),
        ('D02 rear',[[-112,15,-224],[-112,15,-239],[-104,15,-239]]),
        ('D03 west',[[-132,43,-181],[-68,43,-181],[-68,43,-190]]),
        ('D03 east',[[-4,43,-181],[-68,43,-181],[-68,43,-190]]),
        ('D04 hall',[[144,15,-150],[108,15,-150],[108,15,-146]]),
        ('D04 rear',[[88,15,-181],[88,15,-164],[104,15,-164],[104,15,-146],[108,15,-146]]),
        ('D05 west',[[56,29,-181],[144,29,-181],[144,29,-190]]),
        ('D05 east',[[232,29,-181],[144,29,-181],[144,29,-190]]),
        ('D07 hall',[[-217,1,123],[-238,1,123],[-238,1,116]]),
        ('D07 rear',[[-244,1,96],[-244,1,116],[-238,1,116]]),
        ('D08 corridor',[[-217,15,1],[-217,15,108]]),
        ('D09 west',[[-248,29,1],[-217,29,1],[-217,29,24]]),
        ('D09 east',[[-186,29,1],[-217,29,1],[-217,29,24]]),
        ('D10 loading',[[-82,0,58],[-82,1,80]]),
        ('D10 rear',[[-48,1,94],[-82,1,94],[-82,1,80]]),
        ('D13 tower',[[210,43,33],[210,43,57],[230,43,57],[230,43,58]]),
    ]:m.route(name,points,'defense')


def build():
    m=Map()
    exterior(m)
    office_block(m,'A_Administration',(-148,12,-250,-124),3,'aged',[('east',1,-152)])
    office_block(m,'B_PowerStation',(40,248,-250,-124),2,'plaster',[('west',1,-152)])
    for x in (96,192):
        m.box('B_PowerStation','PowerConverter',(x-10,x+10,-146,-132),1,8,'olive','Metal')
        for xx in (x-8,x-4,x,x+4,x+8):m.box('B_PowerStation','CoolingFin',(xx-.15,xx+.15,-147,-131),2,7,'steel','Metal',physical=False)
    office_block(m,'D_Warehouse',(-264,-170,-68,148),2,'brick',[('east',1,140)])
    office_block(m,'T_ControlTower',(172,248,-36,76),4,'aged')
    foundry(m)
    gantries(m)
    underground(m)
    defenses(m)
    for name,point in [('HumanSpawn',(-68,1,-136)),('ZombieSpawn',(-217,1,136)),('LobbySpawn',(-30,.1,36))]:
        x,y,z=point;m.box('Spawns',name,(x-1,x+1,z-1,z+1),y,y+.1,physical=False,alpha=1)
    return m


def plan_svg(m):
    svg=['<svg xmlns="http://www.w3.org/2000/svg" viewBox="-330 -350 660 720" width="1100" height="1200">',
         '<style>text{font:9px sans-serif;fill:#e6dec9}.label{font-weight:bold;font-size:10px}.route{fill:none;stroke:#7cad9c;stroke-width:2;stroke-dasharray:6 4}</style>',
         '<rect x="-330" y="-350" width="660" height="720" fill="#182626"/>',
         '<text x="-300" y="-326" style="font-size:19px">K-17 / COMPLEXO DE CONTENÇÃO</text>',
         '<text x="-300" y="-308">Planta medida · 600 × 600 studs · norte = -Z</text>',
         '<rect x="-300" y="-300" width="600" height="600" fill="#66706a" stroke="#b4b09a" stroke-width="2"/>']
    for r in [(-292,292,-292,-268),(-292,292,268,292),(-292,-268,-268,268),(268,292,-268,268)]:
        a,b,c,d=r;svg.append(f'<rect x="{a}" y="{c}" width="{b-a}" height="{d-c}" fill="#354340"/>')
    for b in m.buildings:
        a,c,z,d=b['rect'];svg.append(f'<rect x="{a}" y="{z}" width="{c-a}" height="{d-z}" fill="#927b61" stroke="#ded1b5"/>')
        svg.append(f'<text class="label" x="{(a+c)/2}" y="{(z+d)/2}" text-anchor="middle">{b["name"]}</text>')
        svg.append(f'<text x="{(a+c)/2}" y="{(z+d)/2+13}" text-anchor="middle">{b["floors"]} pavimentos + cobertura</text>')
    for a,b,c,d in SHAFTS:svg.append(f'<rect x="{a}" y="{c}" width="{b-a}" height="{d-c}" fill="#334b53" stroke="#cba564"/>')
    for route in m.routes:
        if route['name'] in ('Central distribution','Perimeter road circuit'):
            pts=' '.join(f'{p[0]},{p[2]}' for p in route['points']);svg.append(f'<polyline class="route" points="{pts}"/>')
    for p in m.defenses:
        x,y,z=p['point'];svg.append(f'<circle cx="{x}" cy="{z}" r="8" fill="#c5a862"/><text x="{x}" y="{z+3}" text-anchor="middle" style="fill:#182626;font-weight:bold">{p["id"]}</text>')
    svg+=['<text x="-300" y="323">15 posições registradas · circuitos vertical e subterrâneo independentes</text>',
          '<text x="-300" y="339">Diagrama de arquitetura; não é captura de tela nem teste de jogabilidade.</text>','</svg>']
    return '\n'.join(svg)+'\n'


def output_files():
    m=build();ET.indent(m.xml,space='  ')
    manifest={'map':'ZO_K17Foundry','bounds':[-300,300,-300,300],'avatar':{'radius':1.5,'height':5.5,'step':1},
              'parts':m.parts,'lights':m.lights,'shadow_lights':m.shadow_lights,'buildings':m.buildings,
              'routes':m.routes,'defenses':m.defenses,'openings':m.openings,'underground':TUNNELS}
    return {ROOT/'src/maps/k17/K17Foundry.rbxmx':ET.tostring(m.xml,encoding='unicode')+'\n',
            ROOT/'docs/k17-navigation.json':json.dumps(manifest,ensure_ascii=False,separators=(',',':'))+'\n',
            ROOT/'docs/K17_PLAN.svg':plan_svg(m)}


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--check',action='store_true');args=p.parse_args()
    for path,text in output_files().items():
        if args.check:
            if not path.exists() or path.read_text()!=text:raise SystemExit(f'Stale generated file: {path.relative_to(ROOT)}')
        else:path.parent.mkdir(parents=True,exist_ok=True);path.write_text(text)
    m=build();print(f'K-17: {m.parts} anchored parts, {m.lights} lights ({m.shadow_lights} shadowed), {len(m.routes)} authored routes, {len(m.defenses)} defenses')


if __name__=='__main__':main()
