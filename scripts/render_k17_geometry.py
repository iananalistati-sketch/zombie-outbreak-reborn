#!/usr/bin/env python3
"""Optional technical map previews from XML; requires numpy and Pillow."""
from pathlib import Path
import xml.etree.ElementTree as ET
import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT=Path(__file__).resolve().parents[1]
src=ROOT/'src/maps/k17/K17Foundry.rbxmx'
root=ET.parse(src)
parts=[]
def walk(item,path=''):
 p={v.attrib['name']:v for v in item.find('Properties')};name=p['Name'].text;path+='/'+name
 if item.attrib['class']=='Part':
  cf=p['CFrame'];center=np.array([float(cf.find(k).text) for k in 'XYZ']);size=np.array([float(p['size'].find(k).text) for k in 'XYZ'])
  matrix=np.array([[float(cf.find(f'R{i}{j}').text) for j in range(3)] for i in range(3)])
  color=np.array([float(p['Color'].find(k).text) for k in 'RGB'])*255
  alpha=float(p['Transparency'].text)
  if alpha<.9:parts.append((path,name,center,size,matrix,color,alpha))
 for child in item.findall('Item'):walk(child,path)
for i in root.getroot().findall('Item'):walk(i)
for i in ET.parse(ROOT/"src/maps/k17/barricades/Stockroom.rbxmx").getroot().findall("Item"):walk(i)
W,H=1700,1400
camera=np.array([720.,570.,820.]);target=np.array([0.,4.,0.]);forward=target-camera;forward/=np.linalg.norm(forward)
right=np.cross(forward,[0,1,0]);right/=np.linalg.norm(right);up=np.cross(right,forward)
light=np.array([-.4,1,.4]);light/=np.linalg.norm(light)
verts=np.array([[x,y,z] for x in (-.5,.5) for y in (-.5,.5) for z in (-.5,.5)])
faces=[[0,1,3,2],[4,6,7,5],[0,4,5,1],[2,3,7,6],[0,2,6,4],[1,5,7,3]]
font_path=next((str(p) for p in (Path('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'),Path('C:/Windows/Fonts/arial.ttf')) if p.exists()),'DejaVuSans.ttf')
for mode in ('overview','ground','underground'):
 colorbuf=np.zeros((H,W,3),np.uint8);colorbuf[:]=[23,36,36];depthbuf=np.full((H,W),np.inf)
 scale=1.8 if mode!='underground' else 2.05
 for path,name,c,size,rgbmat,color,alpha in parts:
  if mode=='underground' and (('U1_MaintenanceNetwork' not in path and 'R15_PumpBay' not in path and not any(n in path for n in ('PumpCrate','PumpBayCrate'))) or name=='TunnelCeiling'):continue
  if mode!='underground' and ('U1_MaintenanceNetwork' in path or 'R15_PumpBay' in path or any(n in path for n in ('PumpCrate','PumpBayCrate'))):continue
  if mode=='ground' and (c[1]-size[1]/2>8 or name in ('GuardRail','RailPost')):continue
  if mode=='ground' and alpha>.4:continue
  pts=(verts*size)@rgbmat.T+c
  if mode=='ground':pts[:,1]=np.minimum(pts[:,1],8)
  if mode=='underground':pts[:,1]=np.minimum(pts[:,1],-19)
  for ids in faces:
   face=pts[ids];normal=np.cross(face[1]-face[0],face[2]-face[0]);norm=np.linalg.norm(normal)
   if norm<1e-6:continue
   normal/=norm
   if np.dot(normal,camera-face.mean(axis=0))<0:continue
   shade=.52+.48*max(0,np.dot(normal,light));fc=np.clip(color*shade,0,255)
   # Transparent glazing gets a reduced-opacity geometric representation.
   proj=np.column_stack(((face-target)@right*scale+W/2,H*.53-(face-target)@up*scale,(face-camera)@forward))
   for indices in ((0,1,2),(0,2,3)):
    tri=proj[list(indices)];xmin=max(0,int(np.floor(tri[:,0].min())));xmax=min(W-1,int(np.ceil(tri[:,0].max())))
    ymin=max(100,int(np.floor(tri[:,1].min())));ymax=min(H-70,int(np.ceil(tri[:,1].max())))
    if xmin>xmax or ymin>ymax:continue
    x0,y0,z0=tri[0];x1,y1,z1=tri[1];x2,y2,z2=tri[2]
    den=(y1-y2)*(x0-x2)+(x2-x1)*(y0-y2)
    if abs(den)<1e-8:continue
    xx,yy=np.meshgrid(np.arange(xmin,xmax+1)+.5,np.arange(ymin,ymax+1)+.5)
    a=((y1-y2)*(xx-x2)+(x2-x1)*(yy-y2))/den;b=((y2-y0)*(xx-x2)+(x0-x2)*(yy-y2))/den;cc=1-a-b
    dep=a*z0+b*z1+cc*z2;view=depthbuf[ymin:ymax+1,xmin:xmax+1]
    mask=(a>=-.0001)&(b>=-.0001)&(cc>=-.0001)&(dep<view)
    view[mask]=dep[mask]
    colorbuf[ymin:ymax+1,xmin:xmax+1][mask]=fc
 image=Image.fromarray(colorbuf);d=ImageDraw.Draw(image)
 d.text((55,30),'K-17 | COMPLEXO DE CONTENÇÃO',font=ImageFont.truetype(font_path,32),fill='#e4ddc8')
 label={'overview':'VISTA EXTERNA','ground':'CORTE DO TÉRREO','underground':'CORTE DA REDE SUBTERRÂNEA'}[mode]
 d.text((55,80),label,font=ImageFont.truetype(font_path,19),fill='#b5c8b9')
 d.text((55,H-55),'Prévia geométrica do .rbxmx. Não representa materiais, luz ou captura do Roblox Studio.',font=ImageFont.truetype(font_path,19),fill='#c0cbbd')
 out=ROOT/('docs/K17_'+mode.upper()+'.png');image.save(out);print(out,flush=True)
