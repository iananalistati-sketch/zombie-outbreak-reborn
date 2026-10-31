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
print("[K17 ASSETS] Loading official prefabs via AssetService:LoadAssetAsync; imported code will be removed before publishing templates.")
importer.loadAll()
local kit=RS:WaitForChild("ZO_WeaponAssets")
local deadline=os.clock()+25
while kit:GetAttribute("Status")=="Loading" and os.clock()<deadline do task.wait(.1) end
local permissionIssue=false
for _,id in {"Rifle","SMG","Shotgun","Pistol"} do
    print("[K17 ASSETS] "..id..": "..tostring(kit:GetAttribute("Status_"..id)))
    local issue=kit:GetAttribute("Error_"..id)
    if issue then
        local message=tostring(issue)
        warn("[K17 ASSETS] "..id..": "..message)
        local lower=string.lower(message)
        if string.find(lower,"permission",1,true) or string.find(lower,"not owned",1,true)
            or string.find(lower,"not trusted",1,true) or string.find(lower,"third party",1,true)
            or string.find(lower,"not authorized",1,true) then permissionIssue=true end
    end
end
if permissionIssue then
    warn("[K17 ASSETS] Ownership/permission error: review Experience Settings > Allow Loading Third Party Assets for public free models, or acquire the official model in the experience creator's inventory. This setting is only needed when the asset does not already meet Roblox ownership/sharing rules.")
end
game:GetService("Selection"):Set({kit})
if kit:GetAttribute("Status")=="Loading" then
    warn("[K17 ASSETS] Still loading after 25 seconds. Wait and run this command again before exporting; these are pending requests, not confirmed imports.")
    return
end
if (kit:GetAttribute("FailedCount") or 0)>0 then
    warn("[K17 ASSETS] Partial import: inspect the per-weapon errors above. Existing bundled models were preserved when their update failed.")
end
print("[K17 ASSETS] Review the selected templates. Save AS a separate place outside builds, keeping the verified release unchanged.")
print("[K17 ASSETS] Export the selected Folder as ZO_WeaponAssets_Official.rbxmx to preserve the models actually fetched for Git.")
