--!strict
-- Use the reviewed templates shipped with this build. Importing new official
-- prefabs remains an explicit Studio edit command, never a Play dependency.
local RS=game:GetService("ReplicatedStorage")
local Config=require(RS:WaitForChild("K17Gameplay"):WaitForChild("Config"))
local importer=require(script.Parent.WeaponAssetImport)
local kit,weapons=importer.ensure()
local bundled,missing=0,0
for _,id in Config.WeaponOrder do
    local template=weapons:FindFirstChild(id)
    if template and template:IsA("Tool") then
        bundled+=1
        kit:SetAttribute("Status_"..id,"Bundled")
        kit:SetAttribute("Error_"..id,nil)
    else
        missing+=1
        kit:SetAttribute("Status_"..id,"Missing")
        kit:SetAttribute("Error_"..id,"Modelo nao incluido nesta versao")
    end
end
kit:SetAttribute("BundledCount",bundled)
kit:SetAttribute("MissingCount",missing)
kit:SetAttribute("AutoImport",false)
kit:SetAttribute("ImportMethod","Bundled")
for _,attribute in {"AttemptedCount","PendingCount","ImportedCount","CachedCount","FailedCount"} do
    kit:SetAttribute(attribute,0)
end
kit:SetAttribute("Status",if missing==0 then "Ready" elseif bundled>0 then "Partial" else "Failed")
print(("[K17 ASSETS] Templates incluidos: %d; ausentes: %d. Importacao automatica desativada."):format(bundled,missing))
