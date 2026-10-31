--!strict
-- Official Roblox Weapons Kit prefabs, documented in the preserved attribution.
-- Imported containers stay outside the DataModel. Only a sanitized Tool and
-- Animation instances are copied; upstream combat/network scripts never run.
-- LoadAssetAsync is the supported loader documented in Roblox/creator-docs
-- c8f5276703948ef4868c9b9fd44fae619dbe2f11, AssetService.yaml. The experience's
-- third-party asset setting is managed in Studio, never read/set by this script.
local AssetService=game:GetService("AssetService")
local RS=game:GetService("ReplicatedStorage")
local Import={}
local sources={
    Rifle=96131146947811,
    Pistol=118912302094201,
    Shotgun=104068096273092,
    SMG=119916677125479,
}
local sourceURL="https://create.roblox.com/docs/resources/weapons-kit"
-- The uploaded official Pistol asset contains three cosmetic Tools. Pistol2 is
-- the reviewed black variant; no naming assumption is made for other assets.
local preferredVariants={Pistol="Pistol2"}
local running=false

local function folder(parent: Instance,name: string): Folder
    local existing=parent:FindFirstChild(name)
    if existing then assert(existing:IsA("Folder"),name.." must be a Folder");return existing end
    local result=Instance.new("Folder");result.Name=name;result.Parent=parent;return result
end
local function sound(tool: Tool,names: {string}): Sound?
    for _,name in names do
        local item=tool:FindFirstChild(name,true)
        if item and item:IsA("Sound") then return item end
    end
    return nil
end

function Import.ensure(): (Folder,Folder,Folder)
    local kit=folder(RS,"ZO_WeaponAssets")
    return kit,folder(kit,"Weapons"),folder(kit,"Animations")
end

function Import.install(container: Model,id: string,assetId: number): Tool
    assert(sources[id]==assetId,"Unknown weapon source")
    assert(container.Parent==nil,"Inspect imported containers before parenting")
    -- No entry script or client/server remote can survive into the live tree.
    for _,item in container:GetDescendants() do
        if item:IsA("LuaSourceContainer") or item:IsA("RemoteEvent") or item:IsA("UnreliableRemoteEvent") or item:IsA("RemoteFunction")
            or item:IsA("BindableEvent") or item:IsA("BindableFunction") or item:IsA("PackageLink") then item:Destroy() end
    end
    local candidates={}
    for _,item in container:GetDescendants() do
        if item:IsA("Tool") and item:FindFirstChild("Handle") then table.insert(candidates,item) end
    end
    local tool: Tool?=nil
    if #candidates==1 then tool=candidates[1] :: Tool
    else
        local preferred=preferredVariants[id]
        local matches=0
        for _,candidate in candidates do
            if candidate.Name==preferred then tool=candidate :: Tool;matches+=1 end
        end
        if matches~=1 then
            local names={}
            for _,candidate in candidates do table.insert(names,candidate.Name) end
            table.sort(names)
            error(("Prefab contains %d candidate Tools [%s]; cannot choose a unique reviewed variant for %s")
                :format(#candidates,table.concat(names,", "),id))
        end
    end
    local tool=tool :: Tool
    local handle=tool:FindFirstChild("Handle")
    local model=tool:FindFirstChildOfClass("Model")
    local grip=model and model:FindFirstChild("HandleAttachment",true)
    local fired=sound(tool,{"Fired","FiredSound","FireSound"})
    local reload=sound(tool,{"Reload","ReloadSound"})
    assert(handle and handle:IsA("BasePart") and model and model.PrimaryPart
        and grip and grip:IsA("Attachment"),"Unsupported prefab grip hierarchy")
    assert(tool:FindFirstChildWhichIsA("MeshPart",true),"Prefab lacks imported mesh geometry")
    assert(fired and fired:IsA("Sound") and fired.SoundId~=""
        and reload and reload:IsA("Sound") and reload.SoundId~="","Prefab lacks original firing/reload audio")
    local kit,weapons,animations=Import.ensure()
    -- Collect the original rig animations without cloning their containing code.
    for _,item in container:GetDescendants() do
        if item:IsA("Animation") then
            local old=animations:FindFirstChild(item.Name)
            if old and old:IsA("Animation") and old.AnimationId~=item.AnimationId then old:Destroy();old=nil end
            if not old then item:Clone().Parent=animations end
        end
    end
    local copy=tool:Clone()
    copy.Name=id;copy.CanBeDropped=false;copy.Enabled=false;copy.ManualActivationOnly=true
    copy:SetAttribute("ZO_WeaponId",id);copy:SetAttribute("ZO_SourceAssetId",assetId)
    copy:SetAttribute("ZO_SourceVariant",tool.Name)
    copy:SetAttribute("ZO_SourceDocumentation",sourceURL)
    -- The complete kit includes its own camera, network, damage and effects.
    -- Keep only this reviewed Tool's presentation, not a second live system or
    -- the archived global HitSound retained under its unused effect templates.
    local fullKit=copy:FindFirstChild("WeaponsSystem")
    if fullKit then fullKit:Destroy() end
    local weaponType=copy:FindFirstChild("WeaponType")
    if weaponType then weaponType:Destroy() end
    copy:RemoveTag("WeaponsSystemWeapon")
    for _,item in copy:GetDescendants() do
        if item:IsA("BasePart") then
            item.Anchored=false;item.CanCollide=false;item.CanQuery=false;item.CanTouch=false;item.Massless=true
        elseif item:IsA("Sound") then item.Playing=false end
    end
    local previous=weapons:FindFirstChild(id)
    local published,problem=pcall(function() copy.Parent=weapons end)
    if not published then copy:Destroy();error(tostring(problem),0) end
    if previous then previous:Destroy() end
    kit:SetAttribute("Status_"..id,"Ready")
    kit:SetAttribute("Error_"..id,nil)
    return copy
end

function Import.loadAll()
    if running then return end
    running=true
    local kit,weapons=Import.ensure()
    local jobs={}
    local cached=0
    for id,assetId in sources do
        local existing=weapons:FindFirstChild(id)
        if existing and existing:GetAttribute("ZO_SourceAssetId")==assetId then
            kit:SetAttribute("Status_"..id,"Ready")
            kit:SetAttribute("Error_"..id,nil)
            cached+=1
        else table.insert(jobs,{id=id,assetId=assetId}) end
    end
    local pending=#jobs
    local failures=0
    local imported=0
    kit:SetAttribute("ImportMethod","AssetService:LoadAssetAsync")
    kit:SetAttribute("AttemptedCount",pending)
    kit:SetAttribute("PendingCount",pending)
    kit:SetAttribute("ImportedCount",0)
    kit:SetAttribute("CachedCount",cached)
    kit:SetAttribute("FailedCount",0)
    kit:SetAttribute("Status","Loading")
    local function complete()
        if pending>0 then return end
        running=false
        kit:SetAttribute("Status",if failures==0 then "Ready" elseif imported+cached>0 then "Partial" else "Failed")
    end
    for _,job in jobs do
        local id,assetId=job.id,job.assetId
        kit:SetAttribute("Status_"..id,"Loading");kit:SetAttribute("Error_"..id,nil)
        task.spawn(function()
            local container: Model?=nil
            local ok,problem=pcall(function()
                -- The supported API also returns sandboxed containers. Keep
                -- our explicit detached inspection and code removal regardless.
                container=AssetService:LoadAssetAsync(assetId) :: Model
                assert(container,"Empty official prefab")
                Import.install(container :: Model,id,assetId)
            end)
            if container then container:Destroy() end
            if not ok then
                failures+=1;kit:SetAttribute("Status_"..id,"Failed")
                kit:SetAttribute("Error_"..id,tostring(problem):sub(1,600))
                warn(("[K17 ASSETS] %s (%d): %s"):format(id,assetId,tostring(problem)))
            else imported+=1 end
            pending-=1
            kit:SetAttribute("ImportedCount",imported)
            kit:SetAttribute("FailedCount",failures)
            kit:SetAttribute("PendingCount",pending)
            complete()
        end)
    end
    complete()
end

return Import
