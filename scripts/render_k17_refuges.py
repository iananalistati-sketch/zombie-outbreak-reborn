#!/usr/bin/env python3
"""Optional technical cutaways of actual XML; requires numpy and Pillow."""
from pathlib import Path
import xml.etree.ElementTree as ET
import numpy as np
from PIL import Image, ImageDraw, ImageFont

import json
ROOT=Path(__file__).resolve().parents[1]
root=ET.parse(ROOT/'src/maps/k17/K17Foundry.rbxmx')
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

for item in ET.parse(ROOT/"src/maps/k17/barricades/Stockroom.rbxmx").getroot().findall("Item"):walk(item)
W,H=900,580
light=np.array([-.4,1,.4]);light/=np.linalg.norm(light)
verts=np.array([[x,y,z] for x in (-.5,.5) for y in (-.5,.5) for z in (-.5,.5)])
faces=[[0,1,3,2],[4,6,7,5],[0,4,5,1],[2,3,7,6],[0,2,6,4],[1,5,7,3]]
font_path=next((str(p) for p in (Path('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf'),Path('C:/Windows/Fonts/arial.ttf')) if p.exists()),'DejaVuSans.ttf')
manifest=json.loads((ROOT/'docs/k17-navigation.json').read_text())
sheet=Image.new('RGB',(1800,2440),'#172424')
examples={21,25,31,33,42,44,46,48}
for number,refuge in enumerate(r for r in sorted(manifest['refuges'],key=lambda r:r['id']) if r['id'] in examples):
 bounds=refuge['bounds'];floor=refuge['floor']
 target=np.array([(bounds[0]+bounds[1])/2,floor+1.5,(bounds[2]+bounds[3])/2])
 camera=target+np.array([50.,110.,70.]);forward=target-camera;forward/=np.linalg.norm(forward)
 right=np.cross(forward,[0,1,0]);right/=np.linalg.norm(right);up=np.cross(right,forward)
 scale=min(11,680/max(bounds[1]-bounds[0],bounds[3]-bounds[2]))
 low=0 if refuge['id']==14 else -24.65 if refuge['id']==15 else floor-.65
 high=floor+7

 colorbuf=np.zeros((H,W,3),np.uint8);colorbuf[:]=[23,36,36];depthbuf=np.full((H,W),np.inf)
 for path,name,c,size,rgbmat,color,alpha in parts:
  pts=(verts*size)@rgbmat.T+c
  minimum,maximum=pts.min(axis=0),pts.max(axis=0)
  lo=np.array([bounds[0]-5,low,bounds[2]-5]);hi=np.array([bounds[1]+5,high,bounds[3]+5])
  if np.any(maximum<lo) or np.any(minimum>hi) or alpha>.4:continue
  pts=np.clip(pts,lo,hi)
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
    ymin=max(58,int(np.floor(tri[:,1].min())));ymax=min(H-35,int(np.ceil(tri[:,1].max())))
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
 title=f"{refuge['id']:02d} / {refuge['label'].upper()}"
 d.text((24,15),title,font=ImageFont.truetype(font_path,23),fill='#e4ddc8')
 def project(p):
  v=np.array(p)-target
  return (float(v@right*scale+W/2),float(H*.53-v@up*scale))
 for name,points in refuge['approaches']:
  d.line([project(p) for p in points],fill='#69c7c0',width=3)
 for duct in manifest['ducts']:
  if any(bounds[0]<=p[0]<=bounds[1] and bounds[2]<=p[2]<=bounds[3] for p in duct['points']):
   d.line([project(p) for p in duct['points']],fill='#d08c69',width=3)
 for p in refuge['stands']:
  x,y=project(p);d.ellipse((x-5,y-5,x+5,y+5),fill='#edca70',outline='#302c22',width=1)
 d.text((24,H-28),'Corte técnico: ciano = aproximação · amarelo = posição de defesa',font=ImageFont.truetype(font_path,15),fill='#c0cbbd')
 sheet.paste(image,((number%2)*W,(number//2)*H+65))
d=ImageDraw.Draw(sheet)
d.text((24,16),'K-17 / REFÚGIOS RECONSTRUÍDOS',font=ImageFont.truetype(font_path,30),fill='#e4ddc8')
d.text((24,2405),'8 exemplos dos 34 refúgios · 164 objetos no mapa. Corte do XML; não é captura do Studio.',font=ImageFont.truetype(font_path,20),fill='#c0cbbd')
output=ROOT/'docs/K17_REFUGES.png';sheet.save(output);print(output)
