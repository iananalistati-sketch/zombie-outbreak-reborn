-- Real bootstrap and real catalogue, with tree/service doubles only. This does
-- not fetch mesh/audio content or execute Roblox Studio/networking.
local Config=assert(loadstring(CONFIG_SOURCE))()
local checks=0
local function check(ok,label) assert(ok,label);checks+=1 end

local function simulation(available)
    local methods={}
    local function instance(class,name)
        return setmetatable({ClassName=class,Name=name,_children={},_attrs={}}, {__index=methods})
    end
    function methods:IsA(class) return self.ClassName==class end
    function methods:FindFirstChild(name) return self._children[name] end
    function methods:WaitForChild(name) return assert(self._children[name],self.Name.." missing "..name) end
    function methods:SetAttribute(name,value) self._attrs[name]=value end
    function methods:GetAttribute(name) return self._attrs[name] end
    local rs=instance("ReplicatedStorage","ReplicatedStorage")
    local shared=instance("Folder","K17Gameplay");rs._children.K17Gameplay=shared
    local configModule=instance("ModuleScript","Config");shared._children.Config=configModule
    local kit=instance("Folder","ZO_WeaponAssets");rs._children.ZO_WeaponAssets=kit
    local weapons=instance("Folder","Weapons");kit._children.Weapons=weapons
    for id,class in available do weapons._children[id]=instance(class,id) end
    local originals=table.clone(weapons._children)
    -- Saved edit-mode imports may leave diagnostics behind. Startup must not
    -- report stale pending requests or failures as a fresh download attempt.
    kit:SetAttribute("PendingCount",4);kit:SetAttribute("FailedCount",4)
    kit:SetAttribute("ImportedCount",3);kit:SetAttribute("Status","Loading")
    kit:SetAttribute("Error_Rifle","old denied request")
    local module=instance("ModuleScript","WeaponAssetImport")
    local ensureCalls,imports,network,schedules=0,0,0,0
    local importer={ensure=function() ensureCalls+=1;return kit,weapons end,
        loadAll=function() imports+=1;error("bootstrap attempted a remote import") end}
    local forbidSchedule=setmetatable({}, {__index=function(_,key)
        return function() schedules+=1;error("unexpected task scheduling: "..key) end
    end})
    local prints={}
    local env=setmetatable({game={GetService=function(_,name)
        if name=="ReplicatedStorage" then return rs end
        network+=1;error("unexpected service/network dependency: "..name)
    end},script={Parent={WeaponAssetImport=module}},task=forbidSchedule,
        require=function(value)
            if value==module then return importer end
            assert(value==configModule,"unexpected module dependency");return Config
        end,print=function(message) table.insert(prints,message) end}, {__index=getfenv()})
    local fn=assert(loadstring(BOOTSTRAP_SOURCE,"WeaponAssets.server.luau"));setfenv(fn,env)
    local ok,problem=pcall(fn)
    return {ok=ok,problem=problem,kit=kit,weapons=weapons,ensureCalls=ensureCalls,
        imports=imports,network=network,schedules=schedules,prints=prints,originals=originals}
end

do
    local s=simulation({Rifle="Tool",Pistol="Tool"})
    check(s.ok,tostring(s.problem))
    check(s.ensureCalls==1 and s.imports==0 and s.network==0 and s.schedules==0,
        "Play initializes bundled data without an import, network service or delayed request")
    check(s.kit:GetAttribute("Status")=="Partial" and s.kit:GetAttribute("BundledCount")==2
        and s.kit:GetAttribute("MissingCount")==2,"two included tools are distinguished from the two missing catalogue entries")
    for _,id in {"Rifle","Pistol"} do
        check(s.kit:GetAttribute("Status_"..id)=="Bundled" and s.kit:GetAttribute("Error_"..id)==nil,
            id.." publishes included status and clears previous import errors")
        check(s.weapons:FindFirstChild(id)==s.originals[id],id.." remains the exact existing Tool")
    end
    for _,id in {"SMG","Shotgun"} do
        check(s.kit:GetAttribute("Status_"..id)=="Missing" and type(s.kit:GetAttribute("Error_"..id))=="string",
            id.." is reported missing instead of downloaded or perpetually loading")
        check(s.weapons:FindFirstChild(id)==nil,id.." is not replaced with a fake model")
    end
    check(s.kit:GetAttribute("AutoImport")==false and s.kit:GetAttribute("ImportMethod")=="Bundled",
        "bootstrap exposes its actual local-only mode")
    for _,name in {"AttemptedCount","PendingCount","ImportedCount","CachedCount","FailedCount"} do
        check(s.kit:GetAttribute(name)==0,name.." cannot preserve a stale edit-mode request count")
    end
end

do
    local all={};for _,id in Config.WeaponOrder do all[id]="Tool" end
    local s=simulation(all)
    check(s.ok and s.kit:GetAttribute("Status")=="Ready" and s.kit:GetAttribute("BundledCount")==#Config.WeaponOrder
        and s.kit:GetAttribute("MissingCount")==0,"a complete bundled catalogue is immediately ready")
    check(s.imports==0 and s.network==0 and s.schedules==0,"even a complete catalogue never triggers refresh downloads")
end

do
    local s=simulation({Rifle="Folder"})
    check(s.ok and s.kit:GetAttribute("Status")=="Failed" and s.kit:GetAttribute("BundledCount")==0,
        "an empty/invalid catalogue cannot claim available weapons")
    check(s.kit:GetAttribute("Status_Rifle")=="Missing" and s.weapons:FindFirstChild("Rifle"):IsA("Folder"),
        "a same-name folder is rejected without deleting or replacing it")
    check(s.imports==0 and s.network==0 and s.schedules==0,"missing data never silently turns on network loading")
end

print(("PASS bundled weapon bootstrap: %d assertions; real script/catalogue, API doubles; no Studio execution"):format(checks))
