# Industrial Survival map — source attribution

- **Layout source**: Operation Steel Tide — AetherRadar
  - https://github.com/AetherRadar/operation-steel-tide
  - Exact pinned revision: `d6a33b932e00fb9016dea407eca3f909aeaf2dcb`
  - Based on `csharp/DemolitionArenaLayout.HarborLocks.cs` and its authored building positions.
  - Original project authored layout/code: MIT. Retain upstream copyright license on reuse; see upstream LICENSE.
- **3D building art**: Kenney, City Kit (Industrial), CC0 (public domain dedication).
  - https://opengameart.org/content/city-kit-industrial
  - GLB enterable exports repackaged by Operation Steel Tide at pinned revision above.
- **Gameplay systems**: Zombie Outbreak own Luau code, not copied from Godot/C#.

The adaptation uses original industrial architecture placements and enterable building meshes instead of procedural crates. The composite GLB is a **visual level asset**, not a complete collision-safe Roblox map. Validate collisions, scale, doors, stairs and connectivity in Roblox Studio before approving.

## Import flow

1. GitHub Desktop → Fetch origin → Pull origin.
2. Roblox Studio → **File → Import**. Select `assets/maps/HarborLocks_Survival_Visual.glb`.
3. Import as a model and preserve scene hierarchy; confirm preview and materials. Prefer a new testing place.
4. In Explorer inspect created model/meshes. Save the place after import.
5. This imported 3D scene is **not synced by Rojo** until Roblox mesh IDs are published, so don't assume the GitHub file appears as a MeshPart automatically.
6. Temporarily hide the older `ZO_Survival` test map for visual comparison. Its source still lives in `default.project.json`; editing it only in Studio may be overwritten by Rojo.

Never import an unknown, unlicensed third-party model as a Roblox Toolbox free model with scripts embedded.
