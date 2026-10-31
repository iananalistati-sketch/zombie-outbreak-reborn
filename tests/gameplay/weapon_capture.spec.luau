-- Executes the real standalone capture command. No asset network, Studio or
-- model rendering is simulated; these doubles inspect publication/lifecycle.
local checks=0
local function check(ok,label) assert(ok,label);checks+=1 end
local function simulation(options)
    options=options or {}
    local methods={}
    local ss,gameRoot
    local published=0
    local function unsafe(item)
        return item:IsA("LuaSourceContainer") or item:IsA("RemoteEvent") or item:IsA("RemoteFunction")
            or item:IsA("BindableEvent") or item:IsA("BindableFunction") or item:IsA("UnreliableRemoteEvent") or item:IsA("PackageLink")
    end
    local function instance(class,name,parent)
        local data={ClassName=class,Name=name or class,children={},attrs={}}
        local object={_data=data}
        setmetatable(object,{__index=function(_,key) return methods[key] or data[key] end,
            __newindex=function(_,key,value)
                if key=="Parent" then
                    if data.Parent then data.Parent._data.children[object]=nil end
                    data.Parent=value
                    if value then
                        value._data.children[object]=true
                        if ss and object:IsDescendantOf(ss) then
                            for _,node in object:GetDescendants() do assert(not unsafe(node),"raw executable published") end
                            assert(not unsafe(object),"executable object published")
                            published+=1
                        end
                    end
                else data[key]=value end
            end})
        if parent then object.Parent=parent end
        return object
    end
    function methods:IsA(class)
        return self.ClassName==class or class=="Instance"
            or class=="LuaSourceContainer" and (self.ClassName=="Script" or self.ClassName=="LocalScript" or self.ClassName=="ModuleScript")
    end
    function methods:GetChildren() local list={};for node in self._data.children do table.insert(list,node) end;return list end
    function methods:GetDescendants()
        local list={};for _,node in self:GetChildren() do table.insert(list,node);for _,nested in node:GetDescendants() do table.insert(list,nested) end end;return list
    end
    function methods:FindFirstChild(name) for _,node in self:GetChildren() do if node.Name==name then return node end end;return nil end
    function methods:IsDescendantOf(ancestor) local node=self.Parent;while node do if node==ancestor then return true end;node=node.Parent end;return false end
    function methods:SetAttribute(name,value) self._data.attrs[name]=value end
    function methods:GetAttribute(name) return self._data.attrs[name] end
    function methods:Destroy() self.Destroyed=true;for _,child in self:GetChildren() do child:Destroy() end;self.Parent=nil end
    gameRoot=instance("DataModel","game")
    ss=instance("ServerStorage","ServerStorage",gameRoot)
    local existing=instance("Folder","PreviousGameplay",ss)
    local rs=instance("ReplicatedStorage","ReplicatedStorage",gameRoot)
    local active=instance("Folder","ZO_WeaponAssets",rs)
    instance("Tool","Rifle",active)
    local collision=instance("Folder","ZO_OfficialWeaponReview_1234",ss)
    local loaded={}
    local requests={}
    local function prefab(id)
        local root=instance("Model","Downloaded")
        local tool=instance(if id==119916677125479 then "Model" else "Tool","ActualPrefab",root)
        tool.RequiresHandle=false
        local module=instance("ModuleScript","WeaponSource",tool)
        module.Source="return 'unreviewed upstream code'"
        local mesh=instance("MeshPart","GeometryOwnedByScript",module)
        mesh.MeshId="rbxassetid://original-test-mesh"
        local sound=instance("Sound","Fired",tool);sound.Playing=true;sound.PlayOnRemove=true
        instance("RemoteEvent","Damage",module)
        instance("UnreliableRemoteEvent","Aim",tool)
        instance("PackageLink","AutoUpdate",tool)
        local animation=instance("Animation","AimPose",tool);animation.AnimationId="rbxassetid://original-test-animation"
        table.insert(loaded,root)
        return root
    end
    local selection,prints,warnings=nil,{},{}
    local services={ServerStorage=ss,RunService={IsStudio=function() return true end,IsRunning=function() return options.running==true end},
        Selection={Set=function(_,value) selection=value end},AssetService={LoadAssetAsync=function(_,id)
            table.insert(requests,id)
            if options.failAll or options.fail and id==118912302094201 then error("User is not authorized to access Asset.") end
            return prefab(id)
        end}}
    local env=setmetatable({game={GetService=function(_,name) return assert(services[name],name) end},
        Instance={new=function(class) return instance(class) end},os={time=function() return 1234 end},
        print=function(value) table.insert(prints,tostring(value)) end,warn=function(value) table.insert(warnings,tostring(value)) end},
        {__index=getfenv()})
    local command=assert(loadstring(CAPTURE_SOURCE));setfenv(command,env)
    local ok,problem=pcall(command)
    return {ok=ok,problem=problem,ss=ss,rs=rs,existing=existing,active=active,collision=collision,loaded=loaded,
        requests=requests,selection=selection,prints=prints,warnings=warnings,published=published}
end

do
    local s=simulation();check(s.ok,tostring(s.problem))
    local review=s.selection[1]
    check(#s.requests==4,"all four whitelisted official sources are captured")
    local allowed={[96131146947811]=true,[119916677125479]=true,[104068096273092]=true,[118912302094201]=true}
    for _,id in s.requests do check(allowed[id],"only a documented source id is requested") end
    check(review.Parent==s.ss and review.Name=="ZO_OfficialWeaponReview_1234_2","review folder is isolated and does not overwrite a previous capture")
    check(not s.collision.Destroyed and not s.existing.Destroyed,"existing review and gameplay content are retained")
    check(s.rs:FindFirstChild("ZO_WeaponAssets")==s.active and #s.active:GetChildren()==1,"active templates remain untouched")
    check(review:GetAttribute("Status")=="Ready" and review:GetAttribute("CapturedCount")==4,"actual captured count is recorded")
    local noTool=review:FindFirstChild("SMG")
    check(noTool~=nil and noTool:GetAttribute("ToolCount")==0,"diagnostic capture accepts a model with no Tool instead of repeating the importer assumption")
    for _,id in {"Rifle","SMG","Shotgun","Pistol"} do
        local entry=review:FindFirstChild(id)
        local archive=entry:FindFirstChild("ReviewSources")
        check(entry:GetAttribute("MeshPartCount")==1 and entry:GetAttribute("ArchivedSourceCount")==1,"mesh and script metadata recorded")
        local text=archive:GetChildren()[1]
        check(text:IsA("StringValue") and text.Value=="return 'unreviewed upstream code'" and text:GetAttribute("SourceReadable"),"upstream code is retained as inert text")
        check(string.find(text:GetAttribute("OriginalPath"),"WeaponSource",1,true)~=nil,"original source path survives sanitization")
        check(string.find(entry:FindFirstChild("OriginalHierarchy").Value,"GeometryOwnedByScript",1,true)~=nil,"original hierarchy is captured before removing code")
        local mesh,sound
        for _,item in entry:GetDescendants() do
            check(not item:IsA("LuaSourceContainer") and not item:IsA("RemoteEvent") and not item:IsA("PackageLink"),"review contains no executable or updating objects")
            if item:IsA("MeshPart") then mesh=item elseif item:IsA("Sound") then sound=item end
        end
        check(mesh~=nil and mesh.MeshId=="rbxassetid://original-test-mesh","geometry beneath a removed script is preserved")
        check(not sound.Playing and not sound.PlayOnRemove,"review audio cannot start playing on publication or removal")
    end
end

do
    local s=simulation({fail=true});check(s.ok,tostring(s.problem))
    local review=s.selection[1]
    check(#s.requests==4 and review:GetAttribute("CapturedCount")==3 and review:GetAttribute("FailedCount")==1,"one network/permission failure does not abort the other captures")
    check(review:GetAttribute("Status")=="Partial" and review:FindFirstChild("Pistol")==nil,"failed asset is not presented as captured")
    check(#s.warnings==1 and string.find(s.warnings[1],"not authorized",1,true)~=nil,"concrete failed asset reason is reported")
end

do
    local s=simulation({failAll=true});check(s.ok,tostring(s.problem))
    local review=s.selection[1]
    check(review:GetAttribute("Status")=="Failed" and review:GetAttribute("CapturedCount")==0
        and review:GetAttribute("FailedCount")==4,"total refusal records zero captures without pretending to succeed")
    local exportInstruction=false
    for _,line in s.prints do exportInstruction=exportInstruction or string.find(line,"Exporte a pasta",1,true)~=nil end
    check(not exportInstruction,"total failure never requests an empty capture export")
end

do
    local s=simulation({running=true})
    check(not s.ok and #s.requests==0 and s.selection==nil,"Play mode is rejected before any download or review publication")
end

print(("PASS standalone weapon capture: %d assertions; source/tree/API doubles, no Roblox execution"):format(checks))
