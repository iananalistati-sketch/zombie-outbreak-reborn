--!strict
-- Harbor Locks authored GLB scene validator. Always runs on server.
-- This cannot import the GLB: Roblox Studio Importer uploads MeshParts.
local Workspace = game:GetService("Workspace")
local mapName = "HarborLocks_Survival_Visual"
local found = Workspace:FindFirstChild(mapName)
local physics = Workspace:FindFirstChild("ZO_HarborCollision")
if physics then
    print("[ZO HARBOR] Collision proxy present; "+tostring(#physics:GetChildren())+" parts")
else
    warn("[ZO HARBOR] Missing collision proxy. Check Rojo sync of default.project.json.")
end
if not found then
    warn("[ZO HARBOR] 3D map has not been imported into Workspace yet. File > Import > assets/maps/HarborLocks_Survival_Visual.glb. Rename model exactly HarborLocks_Survival_Visual.")
    return
end
local meshes,parts,unanchored=0,0,0
for _,v in ipairs(found:GetDescendants()) do
    if v:IsA("BasePart") then
        parts+=1
        if not v.Anchored then
            unanchored+=1
            v.Anchored=true -- don't let the imported scene fall during testing
        end
        if v:IsA("MeshPart") then meshes+=1 end
    end
end
print(("[ZO HARBOR] Imported authored map found: %d BaseParts, %d MeshParts; anchored %d."):format(parts,meshes,unanchored))
if meshes < 12 then
    warn("[ZO HARBOR] Few or no MeshParts. Verify GLB import options or hierarchy.")
end
print("[ZO HARBOR] Routes and collision STILL require in-Studio testing. This message is not gameplay approval.")
