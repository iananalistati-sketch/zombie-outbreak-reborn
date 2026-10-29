--!strict
-- Run in the Studio Command Bar in EDIT mode after opening the new K-17 file.
-- Backs up the current presentation assets and imports sanitized official Tools.
local RunService=game:GetService("RunService")
assert(RunService:IsStudio() and not RunService:IsRunning(),"Use Studio edit mode")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local scripts=game:GetService("ServerScriptService"):FindFirstChild("ZO_Server")
local module=scripts and scripts:FindFirstChild("WeaponAssetImport")
assert(module and module:IsA("ModuleScript"),"Open the FPS package version of K-17 first")
local current=RS:FindFirstChild("ZO_WeaponAssets")
if current then
    local backup=current:Clone()
    backup.Name="ZO_WeaponAssets_Backup_"..tostring(os.time())
    backup.Parent=SS
    print("[K17 ASSETS] Preserved backup: ServerStorage."..backup.Name)
end
local importer=require(module)
importer.loadAll()
local kit=RS:WaitForChild("ZO_WeaponAssets")
local deadline=os.clock()+25
while kit:GetAttribute("Status")=="Loading" and os.clock()<deadline do task.wait(.1) end
for _,id in {"Rifle","SMG","Shotgun","Pistol"} do
    print("[K17 ASSETS] "..id..": "..tostring(kit:GetAttribute("Status_"..id)))
    local issue=kit:GetAttribute("Error_"..id)
    if issue then warn("[K17 ASSETS] "..id..": "..tostring(issue)) end
end
game:GetService("Selection"):Set({kit})
print("[K17 ASSETS] Review the selected templates, save the place, and export this Folder as RBXMX to preserve fetched models in Git.")
