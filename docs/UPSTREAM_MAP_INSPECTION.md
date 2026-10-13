# Third-party authored FPS map — GLB inspection

**Upstream:** https://github.com/TheDahoom/FPS-Multiplayer-Template
**Exact revision:** dd9627490d5bb6f16f84b4ffd09bfc6f036140b1
**Original path:** imports/map.glb
**License:** MIT for original models (retain copyright); Kenney textures CC0 as identified by upstream.

> This is a geometry inspection, not gameplay validation. Do not claim the map supports Zombie Survival without walking and collision tests in Roblox Studio.

- GLB size: 891,936 bytes
- glTF nodes: 112
- Distinct node names: 112
- Meshes: 11
- Primitives: 11
- Materials: 1

## Scene node names

- Plane-col (1)
- Walls -col (1)
- C-colonly (1)
- Cargo (1)
- C-colonly.001 (1)
- Cargo.001 (1)
- C-colonly.002 (1)
- Cargo.002 (1)
- C-colonly.003 (1)
- Cargo.003 (1)
- C-colonly.004 (1)
- Cargo.004 (1)
- C-colonly.005 (1)
- Cargo.005 (1)
- C-colonly.006 (1)
- Cargo.006 (1)
- C-colonly.007 (1)
- Cargo.007 (1)
- C-colonly.008 (1)
- Cargo.008 (1)
- C-colonly.009 (1)
- Cargo.009 (1)
- C-colonly.010 (1)
- Cargo.010 (1)
- C-colonly.011 (1)
- Cargo.011 (1)
- C-colonly.012 (1)
- Cargo.012 (1)
- C-colonly.013 (1)
- Cargo.013 (1)
- C-colonly.014 (1)
- Cargo.014 (1)
- C both open-colonly.001 (1)
- Cargo both open (1)
- C both open-colonly (1)
- Cargo both open.001 (1)
- C side open-colonly (1)
- cargo side open (1)
- C side open-colonly.001 (1)
- cargo side open.001 (1)
- C side open-colonly.002 (1)
- cargo side open.002 (1)
- B -colonly (1)
- barrel (1)
- B -colonly.001 (1)
- barrel.001 (1)
- B -colonly.002 (1)
- barrel.002 (1)
- B -colonly.003 (1)
- barrel.003 (1)
- B -colonly.004 (1)
- barrel.004 (1)
- B -colonly.005 (1)
- barrel.005 (1)
- B -colonly.006 (1)
- barrel.006 (1)
- B -colonly.007 (1)
- barrel.007 (1)
- B -colonly.008 (1)
- barrel.008 (1)
- B -colonly.009 (1)
- barrel.009 (1)
- B -colonly.010 (1)
- barrel.010 (1)
- B -colonly.011 (1)
- barrel.011 (1)
- B -colonly.012 (1)
- barrel.012 (1)
- B -colonly.013 (1)
- barrel.013 (1)
- B -colonly.014 (1)
- barrel.014 (1)
- B -colonly.015 (1)
- barrel.015 (1)
- B -colonly.016 (1)
- barrel.016 (1)
- B -colonly.017 (1)
- barrel.017 (1)
- B -colonly.018 (1)
- barrel.018 (1)
- B -colonly.019 (1)
- barrel.019 (1)
- B -colonly.020 (1)
- barrel.020 (1)
- B -colonly.021 (1)
- barrel.021 (1)
- B -colonly.022 (1)
- barrel.022 (1)
- B -colonly.023 (1)
- barrel.023 (1)
- B -colonly.024 (1)
- barrel.024 (1)
- B -colonly.025 (1)
- barrel.025 (1)
- B -colonly.026 (1)
- barrel.026 (1)
- B -colonly.027 (1)
- barrel.027 (1)
- B -colonly.028 (1)
- barrel.028 (1)
- B -colonly.029 (1)
- barrel.029 (1)
- B -colonly.030 (1)
- barrel.030 (1)
- B -colonly.031 (1)
- barrel.031 (1)
- B -colonly.032 (1)
- barrel.032 (1)
- B -colonly.033 (1)
- barrel.033 (1)
- B -colonly.034 (1)
- barrel.034 (1)

## Named meshes

- Plane
- Plane.001
- Cube
- Cube.001
- Cube.008
- Cube.012
- Cube.011
- Cube.009
- Cube.010
- Cylinder.003
- Cylinder.004

## Recommendation

1. Check if actual architectural rooms, corridors, doorways, stairs and hiding positions exist.
2. Import this authored map into a **copy** of Roblox Studio using File > Import (glb/gltf).
3. Separate gameplay collision from decorative geometry and test paths.
4. No engine-specific code should be reused; continue server-authored Luau multiplayer systems.
