--!strict
-- Paste this entire file into Studio's Command Bar while NOT playing.
-- Imports documented Roblox Weapons Kit prefabs for inspection, not execution.
local RunService=game:GetService("RunService")
assert(RunService:IsStudio() and not RunService:IsRunning(),"Use Studio edit mode, not Play")
local InsertService=game:GetService("InsertService")
local ServerStorage=game:GetService("ServerStorage")
local Selection=game:GetService("Selection")
local source="https://create.roblox.com/docs/resources/weapons-kit"
local assets={
    {name="Pistol",id=118912302094201},
    {name="Shotgun",id=104068096273092},
    {name="AutoRifle",id=96131146947811},
    {name="SubmachineGun",id=119916677125479},
}
local folder=Instance.new("Folder")
local base="ZO_OfficialWeapons_Review"
local name=base
local index=1
while ServerStorage:FindFirstChild(name) do index+=1;name=base.."_"..index end
folder.Name=name
folder:SetAttribute("Source",source)
folder:SetAttribute("Status","Imported for review; not integrated into gameplay")
local loaded,failures=0,0
for _,asset in assets do
    local ok,result=pcall(function() return InsertService:LoadAsset(asset.id) end)
    if ok and typeof(result)=="Instance" and result:IsA("Model") then
        local disabled=0
        -- Keep the model outside the DataModel until every entry script is off.
        for _,item in result:GetDescendants() do
            if item:IsA("BaseScript") then item.Disabled=true;disabled+=1 end
        end
        result.Name=asset.name
        result:SetAttribute("SourceAssetId",asset.id)
        result:SetAttribute("SourceDocumentation",source)
        result.Parent=folder
        loaded+=1
        print(("[OFFICIAL WEAPONS] Imported %s (%d); %d scripts disabled"):format(asset.name,asset.id,disabled))
    else
        failures+=1
        if ok and typeof(result)=="Instance" then result:Destroy() end
        warn(("[OFFICIAL WEAPONS] Cannot load %s (%d): %s"):format(asset.name,asset.id,tostring(result)))
    end
end
if loaded==0 then
    folder:Destroy()
    error("No models imported. Check Output and asset access on this Studio account.")
end
folder:SetAttribute("ImportedCount",loaded)
folder:SetAttribute("FailedCount",failures)
folder.Parent=ServerStorage
Selection:Set({folder})
print(("[OFFICIAL WEAPONS] %d imported, %d failed. Selected ServerStorage.%s; existing game unchanged. Review sources and dependencies before integration."):format(loaded,failures,name))
print("[OFFICIAL WEAPONS] Save the selected folder as an .rbxmx file via Save to File so its actual sources can be reviewed in the Git repository.")
