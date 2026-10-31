-- Real importer, simulated AssetService/tree only. No asset download or engine.
local passed=0
local function check(ok,label) assert(ok,label);passed+=1 end
local methods={}
local make
local rs
make=function(class,name)
    local data={ClassName=class,Name=name or class,children={},attributes={}}
    local object={_data=data}
    return setmetatable(object,{__index=function(_,key) return methods[key] or data[key] end,
        __newindex=function(_,key,value)
            if key=="Parent" then
                if data.Parent then data.Parent._data.children[object]=nil end
                data.Parent=value
                if value then
                    value._data.children[object]=true
                    if class=="Tool" and object:IsDescendantOf(rs) then
                        for _,child in object:GetDescendants() do
                            assert(not child:IsA("LuaSourceContainer") and not child:IsA("RemoteEvent"),"upstream executable published")
                        end
                    end
                end
            else data[key]=value end
        end})
end
function methods:IsA(class)
    return self.ClassName==class or class=="Instance"
        or (class=="BasePart" and (self.ClassName=="Part" or self.ClassName=="MeshPart"))
        or (class=="LuaSourceContainer" and (self.ClassName=="Script" or self.ClassName=="ModuleScript" or self.ClassName=="LocalScript"))
end
function methods:GetChildren() local result={};for child in self._data.children do table.insert(result,child) end;return result end
function methods:GetDescendants()
    local result={}
    for _,child in self:GetChildren() do
        table.insert(result,child);for _,nested in child:GetDescendants() do table.insert(result,nested) end
    end
    return result
end
function methods:FindFirstChild(name,recursive)
    for _,child in self:GetChildren() do if child.Name==name then return child end end
    if recursive then for _,child in self:GetChildren() do local item=child:FindFirstChild(name,true);if item then return item end end end
    return nil
end
function methods:FindFirstChildOfClass(class) for _,child in self:GetChildren() do if child:IsA(class) then return child end end end
function methods:FindFirstChildWhichIsA(class,recursive)
    for _,child in if recursive then self:GetDescendants() else self:GetChildren() do if child:IsA(class) then return child end end
end
function methods:IsDescendantOf(ancestor) local p=self.Parent;while p do if p==ancestor then return true end;p=p.Parent end;return false end
function methods:SetAttribute(name,value) self._data.attributes[name]=value end
function methods:GetAttribute(name) return self._data.attributes[name] end
function methods:Destroy() for _,child in self:GetChildren() do child:Destroy() end;self.Parent=nil end
function methods:Clone()
    local copies={}
    local function clone(source)
        local result=make(source.ClassName,source.Name);copies[source]=result
        for key,value in source._data do
            if key~="children" and key~="attributes" and key~="Parent" then result[key]=value end
        end
        for name,value in source._data.attributes do result:SetAttribute(name,value) end
        for _,child in source:GetChildren() do clone(child).Parent=result end
        return result
    end
    local result=clone(self)
    for source,copy in copies do if source.PrimaryPart then copy.PrimaryPart=copies[source.PrimaryPart] end end
    return result
end
local function add(parent,class,name) local result=make(class,name);result.Parent=parent;return result end
local function prefab(mesh)
    local root=make("Model","Prefab")
    local tool=add(root,"Tool","Original")
    add(tool,"Part","Handle")
    local model=add(tool,"Model","Geometry")
    local body=add(model,if mesh==false then "Part" else "MeshPart","Body");model.PrimaryPart=body
    add(body,"Attachment","HandleAttachment")
    local fired=add(body,"Sound","Fired");fired.SoundId="rbxassetid://test-fire"
    local reload=add(body,"Sound","Reload");reload.SoundId="rbxassetid://test-reload"
    add(tool,"Script","UnsafeServer");add(tool,"LocalScript","UnsafeClient");add(tool,"ModuleScript","UpstreamCombat")
    add(tool,"RemoteEvent","UpstreamHit");add(tool,"PackageLink","AutoUpdate")
    local animation=add(root,"Animation","RifleAim");animation.AnimationId="rbxassetid://test-animation"
    return root
end
rs=make("ReplicatedStorage","ReplicatedStorage")
local failPistol=false
local failRifle=false
local failAll=false
local downloads=0
local serviceRequests={}
local ids={Rifle=96131146947811,SMG=119916677125479,Shotgun=104068096273092,Pistol=118912302094201}
local assetService=setmetatable({LoadAssetAsync=function(_,id)
    downloads+=1
    if failAll then error("User is not authorized to access Asset.") end
    if (failPistol and id==ids.Pistol) or (failRifle and id==ids.Rifle) then error("asset permission denied") end
    return prefab()
end},{__index=function(_,key) error("Unexpected or privileged AssetService property: "..key) end,
    __newindex=function(_,key) error("Unexpected or privileged AssetService write: "..key) end})
local env=setmetatable({game={GetService=function(_,name)
    table.insert(serviceRequests,name)
    if name=="ReplicatedStorage" then return rs end
    assert(name=="AssetService","importer must use the supported AssetService API")
    return assetService
end},Instance={new=function(class) return make(class) end},task={spawn=function(fn) fn() end},warn=function() end},{__index=getfenv()})
local module=assert(loadstring(IMPORT_SOURCE));setfenv(module,env);local Import=module()
check(table.find(serviceRequests,"AssetService")~=nil and table.find(serviceRequests,"InsertService")==nil,"supported asset service replaces the legacy loader")
local kit,weapons,animations=Import.ensure()
local source=prefab()
local installed=Import.install(source,"Pistol",ids.Pistol)
check(source.Parent==nil,"source inspected outside DataModel")
check(installed.Parent==weapons and installed.Name=="Pistol","sanitized Tool published under its actual catalogue id")
check(installed:FindFirstChild("UnsafeServer",true)==nil and installed:FindFirstChild("UpstreamHit",true)==nil,"code and remotes removed")
check(installed:FindFirstChild("AutoUpdate",true)==nil,"package auto-updates cannot reintroduce upstream code")
check(installed:GetAttribute("ZO_SourceAssetId")==ids.Pistol,"original source id retained")
check(animations:FindFirstChild("RifleAim")~=nil,"actual source animation retained")
check(not pcall(function() Import.install(prefab(),"Unknown",123) end),"unknown external asset rejected")
check(not pcall(function() Import.install(prefab(false),"SMG",ids.SMG) end),"primitive stand-in is not accepted as imported mesh")
installed:Destroy();failPistol=true
Import.loadAll()
check(kit:GetAttribute("ImportMethod")=="AssetService:LoadAssetAsync","diagnostics identify the actual supported loader")
check(kit:GetAttribute("Status")=="Partial" and kit:GetAttribute("FailedCount")==1,"one failure yields partial status without aborting other weapons")
check(weapons:FindFirstChild("Rifle")~=nil and weapons:FindFirstChild("SMG")~=nil,"successful imports remain available")
check(weapons:FindFirstChild("Pistol")==nil and kit:GetAttribute("Status_Pistol")=="Failed","failed import never invents a replacement gun")
failPistol=false;local before=downloads;Import.loadAll()
check(downloads==before+1,"retry only downloads the missing source")
check(kit:GetAttribute("Status")=="Ready" and kit:GetAttribute("Error_Pistol")==nil,"successful retry clears its error")
local previous=weapons:FindFirstChild("Rifle")
previous:SetAttribute("ZO_SourceAssetId",nil)
failRifle=true;Import.loadAll()
check(weapons:FindFirstChild("Rifle")==previous,"failed official update preserves the already bundled rifle")
check(kit:GetAttribute("Status")=="Partial" and kit:GetAttribute("Status_Rifle")=="Failed","preserved rifle does not hide a failed update")
failRifle=false;Import.loadAll()
check(weapons:FindFirstChild("Rifle")~=previous and kit:GetAttribute("Status")=="Ready","later successful update replaces the preserved rifle only after validation")
local retained=weapons:FindFirstChild("Rifle")
for _,tool in weapons:GetChildren() do
    if tool==retained then tool:SetAttribute("ZO_SourceAssetId",nil) else tool:Destroy() end
end
failAll=true;Import.loadAll()
check(kit:GetAttribute("Status")=="Failed" and kit:GetAttribute("ImportedCount")==0
    and kit:GetAttribute("FailedCount")==4,"four denied official assets report total failure rather than partial import")
check(kit:GetAttribute("AttemptedCount")==4 and kit:GetAttribute("PendingCount")==0
    and kit:GetAttribute("CachedCount")==0,"denied batch accounts for every completed attempt without pretending models were cached")
check(weapons:FindFirstChild("Rifle")==retained and #weapons:GetChildren()==1,"total authorization failure preserves the previous playable rifle")
for id in ids do
    check(kit:GetAttribute("Status_"..id)=="Failed"
        and string.find(kit:GetAttribute("Error_"..id),"User is not authorized",1,true)~=nil,
        id.." retains the concrete authorization error")
end
failAll=false;Import.loadAll()
check(kit:GetAttribute("Status")=="Ready" and kit:GetAttribute("ImportedCount")==4
    and kit:GetAttribute("FailedCount")==0,"retry after authorization becomes available can install all official models")
local beforeCached=downloads;Import.loadAll()
check(downloads==beforeCached and kit:GetAttribute("CachedCount")==4
    and kit:GetAttribute("ImportedCount")==0 and kit:GetAttribute("AttemptedCount")==0
    and kit:GetAttribute("Status")=="Ready","fully cached arsenal stays ready without claiming a new download")
print(("PASS official weapon importer: %d assertions; tree/AssetService doubles, no network or engine execution"):format(passed))
