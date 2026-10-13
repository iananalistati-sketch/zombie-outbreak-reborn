#!/usr/bin/env python3
"""Inspect the upstream GLB in a CI environment. Read-only, no DCC required."""
import json
import os
import pathlib
import struct
from collections import Counter

file = pathlib.Path("third_party/fps-multiplayer-template/map.glb")
data=file.read_bytes()
if len(data)<20 or data[:4]!=b"glTF":
    raise SystemExit("Invalid .glb magic")
version, length=struct.unpack_from("<II",data,4)
chunk_length,chunk_type=struct.unpack_from("<II",data,12)
if version!=2 or length!=len(data) or chunk_type!=0x4E4F534A:
    raise SystemExit(f"Invalid glTF header: version={version} size={length}/{len(data)}")
scene=json.loads(data[20:20+chunk_length].decode())
nodes=scene.get("nodes",[])
meshes=scene.get("meshes",[])
from collections import Counter
names=Counter(n.get("name","Unnamed") for n in nodes)
mesh_names=[m.get("name","Unnamed") for m in meshes]
accessors=scene.get("accessors",[])
bounds=[]
for accessor in accessors:
    if accessor.get("type")=="VEC3" and "min" in accessor and "max" in accessor:
        if all(isinstance(x,(int,float)) for x in accessor["min"]+accessor["max"]):
            bounds.append((accessor["min"],accessor["max"]))
report=[
"# Third-party authored FPS map — GLB inspection",
"",
"**Upstream:** https://github.com/TheDahoom/FPS-Multiplayer-Template",
"**Exact revision:** dd9627490d5bb6f16f84b4ffd09bfc6f036140b1",
"**Original path:** imports/map.glb",
"**License:** MIT for original models (retain copyright); Kenney textures CC0 as identified by upstream.",
"",
"> This is a geometry inspection, not gameplay validation. Do not claim the map supports Zombie Survival without walking and collision tests in Roblox Studio.",
"",
f"- GLB size: {len(data):,} bytes",
f"- glTF nodes: {len(nodes)}",
f"- Distinct node names: {len(names)}",
f"- Meshes: {len(meshes)}",
f"- Primitives: {sum(len(x.get('primitives',[])) for x in meshes)}",
f"- Materials: {len(scene.get('materials',[]))}",
"",
"## Scene node names",
"",
]
for name,count in names.most_common(120):
    report.append(f"- {name} ({count})")
report.extend(["","## Named meshes",""])
for name in mesh_names[:150]:report.append(f"- {name}")
report.extend(["","## Recommendation","",
"1. Check if actual architectural rooms, corridors, doorways, stairs and hiding positions exist.",
"2. Import this authored map into a **copy** of Roblox Studio using File > Import (glb/gltf).",
"3. Separate gameplay collision from decorative geometry and test paths.",
"4. No engine-specific code should be reused; continue server-authored Luau multiplayer systems.",
""])
pathlib.Path("docs").mkdir(exist_ok=True)
pathlib.Path("docs/UPSTREAM_MAP_INSPECTION.md").write_text("\n".join(report),encoding="utf-8")
print(f"Inspected {len(nodes)} nodes, {len(meshes)} meshes, {len(scene.get('materials',[]))} materials")
