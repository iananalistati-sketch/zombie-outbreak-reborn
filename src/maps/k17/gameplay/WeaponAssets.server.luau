--!strict
-- Optional official prefab loading never gates the Survival controllers.
-- Published experiences must be authorized to load these Roblox assets.
local importer=require(script.Parent.WeaponAssetImport)
local kit=importer.ensure()
kit:SetAttribute("Status_Rifle","Bundled")
task.defer(importer.loadAll)
task.delay(20,function()
    if kit:GetAttribute("Status")=="Loading" then
        kit:SetAttribute("Status","Partial")
        warn("[K17 ASSETS] Official weapon loading is still pending. Inspect Status_<weapon> and Error_<weapon>.")
    end
end)
