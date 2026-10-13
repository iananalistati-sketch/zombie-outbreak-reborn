#!/usr/bin/env python3
"""Recompose original Harbor Locks authored industrial buildings into one Roblox-importable GLB.
MIT layout reference: AetherRadar/operation-steel-tide, pinned upstream commit.
Visual building meshes: Kenney City Kit (Industrial), CC0.
This is a visual scene; authoritative gameplay triggers are created in Luau separately.
"""
import json
import pathlib
import numpy as np
import trimesh
from trimesh.transformations import rotation_matrix, translation_matrix, scale_matrix

SRC=pathlib.Path("third_party/harbor-locks")
OUT=pathlib.Path("assets/maps")
OUT.mkdir(parents=True,exist_ok=True)

# Exact original layout positions and yaw, with enterable original mesh variants where available.
# (name, source file, x, z, yaw in radians, source scale).
BUILDINGS=[
 ("WestControlHall","building-a", -43,-33,0.0,8.5),
 ("WestTurbineHall","building-c", -43,-4,0.0,8.0),
 ("NorthFreightHall","building-q", -16,-32,0.0,7.8),
 ("NorthAdministration","building-h",8,-33,3.14159265,7.5),
 ("EastBoilerHall","building-l",43,-14,3.14159265,8.0),
 ("EastPumpHall","building-b",42,33,3.14159265,8.5),
 ("SouthFreightHall","building-e",15,33,0.0,7.8),
 ("SouthControlAnnex","building-r",-8,33,0.0,7.8),
 ("MidCoverWestOffice","building-h",-23,-14,0.0,7.0),
 ("MidCoverEastOffice","building-t",23,18,1.5707963268,7.0),
 ("MidCoverNorthPump","building-f",-3,-16,0.0,7.0),
 ("MidCoverSouthPump","building-n",3,16,3.14159265,7.0),
 ("NorthDispatchOffice","building-j",-27.5,-33,0.0,6.0),
 ("NorthSecurityOffice","building-j",-3,-32.5,3.14159265,6.8),
 ("SouthSecurityOffice","building-j",30,34,0.0,6.8),
 ("WestCustomsWorkshop","building-g",-32,13,3.14159265,7.0),
 ("WestServiceOffice","building-j",-18,9.5,1.5707963268,4.5),
 ("EastQuayWorkshop","building-g",51,5,0.0,7.0),
 ("EastServiceOffice","building-j",51,17.5,3.14159265,6.8),
]
ENTERABLE={"a","c","e","f","g","h","j","l","n","q","r","t"}
scene=trimesh.Scene()
instances=[]
def layout_transform(x,z,yaw,scale):
    return translation_matrix([x,0,z]) @ rotation_matrix(yaw,[0,1,0]) @ scale_matrix(scale)
def addbox(name,center,extents,color):
    mesh=trimesh.creation.box(extents=extents)
    mesh.visual.vertex_colors=np.array(color,dtype=np.uint8)
    scene.add_geometry(mesh,geom_name=name,node_name=name,transform=translation_matrix(center))
def put_glb(name,filename,x,z,yaw,scale):
    path=SRC/filename
    if not path.exists():raise FileNotFoundError(path)
    child=trimesh.load_scene(str(path))
    basis=layout_transform(x,z,yaw,scale)
    nodes=0
    for node in child.graph.nodes_geometry:
        matrix,meshname=child.graph[node]
        mesh=child.geometry[meshname]
        scene.add_geometry(mesh.copy(),geom_name=f"{name}_{nodes:02d}",node_name=f"{name}_{nodes:02d}",transform=basis@matrix)
        nodes+=1
    if nodes==0:raise ValueError(f"No geometry in {filename}")
    instances.append({"name":name,"source":filename,"position_m":[x,0,z],"rotation_y_rad":yaw,"scale":scale,"mesh_nodes":nodes})
for name,file,x,z,yaw,scale in BUILDINGS:
    suffix=file.replace("building-","")
    src=(f"enterable/{file}-enterable.glb" if suffix in ENTERABLE else f"{file}.glb")
    put_glb(name,src,x,z,yaw,scale)

# Harbor's source-authored spatial arrangement: two channels, three crossings,
# quays and visible perimeter. These are walkable architectural surfaces,
# not random game props. Approximate original Godot box dimensions.
addbox("HarborFoundation",(0,-.53,0),(116,.9,84),[95,99,100,255])
addbox("NorthLockChannel",(0,-.015,-5.4),(104,.07,5.8),[33,67,73,255])
addbox("SouthLockChannel",(0,-.015,5.4),(104,.07,5.8),[33,67,73,255])
for name,x,width in [("WestBridge",-43,12),("CentralControlBridge",0,22),("EastBridge",43,12)]:
    addbox(name,(x,.12,0),(width,.24,9),[108,111,105,255])
# Perimeter wall models (clear site edges rather than endless gray baseplate).
for name,center,ext in [
 ("Boundary_N",(0,2.5,-41.5),(116,5,1)),
 ("Boundary_S",(0,2.5,41.5),(116,5,1)),
 ("Boundary_W",(-57.5,2.5,0),(1,5,84)),
 ("Boundary_E",(57.5,2.5,0),(1,5,84))]:
    addbox(name,center,ext,[75,77,78,255])

output=OUT/"HarborLocks_Survival_Visual.glb"
scene.export(str(output))
if output.stat().st_size<100000:raise RuntimeError("GLB unexpectedly small")
bounds=scene.bounds.tolist()
report={
 "status":"VISUAL SCENE ASSEMBLED; GAMEPLAY UNTESTED",
 "basis":"Operation Steel Tide Harbor Locks (MIT layout) and Kenney Industrial CC0 enterable models",
 "model":str(output),"bytes":output.stat().st_size,
 "buildings":len(BUILDINGS),"instances":instances,
 "bounds_m":{"min":bounds[0],"max":bounds[1]},
 "geometry_count":len(scene.geometry),
 "warnings":["This is a 3D authored architectural composition, not a complete Roblox game map.",
 "Roblox mesh import must be performed in Studio; Rojo cannot upload a GLB as a MeshPart.",
 "Character-scale, collision proxies, door entrances, safe spots and raycast reachability require Studio tests.",
 "The original Godot game logic is NOT copied or executed in Roblox."] }
(OUT/"HarborLocks_BuildReport.json").write_text(json.dumps(report,indent=2),encoding="utf-8")
print(json.dumps({k:v for k,v in report.items() if k not in ("instances","warnings")},indent=2))
