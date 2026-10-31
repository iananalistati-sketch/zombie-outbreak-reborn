-- Protocol/control-flow regression harness. Presentation is stubbed; this does
-- not render Roblox UI, load assets, animate arms or simulate multiplayer.
local Config=assert(loadstring(CONFIG_SOURCE))()
local Rules=assert(loadstring(RULES_SOURCE))()
local checks=0
local function check(ok,label) assert(ok,label);checks+=1 end
local function close(a,b) return math.abs(a-b)<1e-5 end

local vectorMeta={}
local function vector(x,y,z) return setmetatable({_type="Vector3",X=x or 0,Y=y or 0,Z=z or 0},vectorMeta) end
vectorMeta.__index=function(v,k)
    if k=="Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end
    if k=="Unit" then local m=v.Magnitude;return vector(v.X/m,v.Y/m,v.Z/m) end
end
vectorMeta.__add=function(a,b) return vector(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vectorMeta.__sub=function(a,b) return vector(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vectorMeta.__mul=function(a,b) if type(a)=="number" then a,b=b,a end;return vector(a.X*b,a.Y*b,a.Z*b) end
vectorMeta.__div=function(a,b) return vector(a.X/b,a.Y/b,a.Z/b) end
local cfMeta={}
local function cf(x,y,z,pitch) return setmetatable({_type="CFrame",Position=vector(x,y,z),pitch=pitch or 0},cfMeta) end
cfMeta.__mul=function(a,b) return cf(a.Position.X+b.Position.X,a.Position.Y+b.Position.Y,a.Position.Z+b.Position.Z,a.pitch+b.pitch) end
cfMeta.__eq=function(a,b)
    return a.pitch==b.pitch and a.Position.X==b.Position.X and a.Position.Y==b.Position.Y and a.Position.Z==b.Position.Z
end
cfMeta.__index=function(v,k)
    if k=="LookVector" then return vector(0,math.sin(v.pitch),-math.cos(v.pitch)) end
    if k=="Lerp" then return function(a,b,t) return cf(0,0,0,a.pitch+(b.pitch-a.pitch)*t) end end
end
local CFrame={new=cf,identity=cf(),Angles=function(p,y,r) return cf(0,0,0,p) end,
    lookAt=function(p,t) return cf(p.X,p.Y,p.Z) end}

local function simulation(options)
    options=options or {}
    local now=10
    local queue,errors={},{}
    local function schedule(thread,at,args) table.insert(queue,{thread=thread,at=at,args=args or {}}) end
    local tasks={}
    function tasks.spawn(fn,...) local thread=if type(fn)=="thread" then fn else coroutine.create(fn);schedule(thread,now,{...});return thread end
    tasks.defer=tasks.spawn
    function tasks.delay(seconds,fn,...) schedule(coroutine.create(fn),now+seconds,{...}) end
    function tasks.wait(seconds) return coroutine.yield(seconds or .03) end
    local function signal()
        local callbacks={}
        local result={}
        function result:Connect(fn)
            table.insert(callbacks,fn)
            return {Disconnect=function() local i=table.find(callbacks,fn);if i then table.remove(callbacks,i) end end}
        end
        function result:Once(fn)
            local connection
            connection=self:Connect(function(...) connection:Disconnect();fn(...) end)
            return connection
        end
        function result:Fire(...) for _,fn in table.clone(callbacks) do tasks.spawn(fn,...) end end
        return result
    end
    local methods={}
    local function instance(class,name,parent)
        local data={ClassName=class,Name=name or class,_children={},_attrs={},_attributeSignals={},_propertySignals={},_destroyed=false}
        local result={_data=data}
        setmetatable(result,{__index=function(_,key) return methods[key] or data[key] or data._children[key] end,
            __newindex=function(_,key,value)
                local previous=data[key]
                if key=="Parent" then
                    if previous then
                        previous._children[data.Name]=nil;previous.ChildRemoved:Fire(result)
                        local ancestor=previous;while ancestor do ancestor.DescendantRemoving:Fire(result);ancestor=ancestor.Parent end
                    end
                    data.Parent=value
                    if value then
                        value._children[data.Name]=result;value.ChildAdded:Fire(result)
                        local ancestor=value;while ancestor do ancestor.DescendantAdded:Fire(result);ancestor=ancestor.Parent end
                    end
                elseif key=="Name" then
                    if data.Parent then data.Parent._children[data.Name]=nil;data.Parent._children[value]=result end
                    data[key]=value
                else data[key]=value end
                if value~=previous and data._propertySignals[key] then data._propertySignals[key]:Fire() end
                if key=="Health" and value~=previous and data.HealthChanged then
                    data.HealthChanged:Fire(value);if value<=0 then data.Died:Fire() end
                end
            end})
        result.ChildAdded=signal();result.ChildRemoved=signal();result.DescendantAdded=signal();result.DescendantRemoving=signal()
        result.Destroying=signal();result.AncestryChanged=signal();result.AttributeChanged=signal()
        result.Visible=true;result.Active=true
        if class=="Humanoid" then result.HealthChanged=signal();result.Died=signal();result.Health=100;result.MoveDirection=vector() end
        if parent then result.Parent=parent end
        return result
    end
    function methods:IsA(class)
        return self.ClassName==class or class=="Instance" or (class=="BasePart" and (self.ClassName=="Part" or self.ClassName=="MeshPart"))
            or (class=="GuiButton" and (self.ClassName=="TextButton" or self.ClassName=="ImageButton"))
    end
    function methods:GetChildren() local r={};for _,v in self._children do table.insert(r,v) end;return r end
    function methods:GetDescendants()
        local r={};for _,v in self:GetChildren() do table.insert(r,v);for _,d in v:GetDescendants() do table.insert(r,d) end end;return r
    end
    function methods:FindFirstChild(name,recursive)
        if self._children[name] then return self._children[name] end
        if recursive then for _,v in self:GetChildren() do local f=v:FindFirstChild(name,true);if f then return f end end end
        return nil
    end
    function methods:WaitForChild(name) return assert(self:FindFirstChild(name),"Unexpected missing dependency: "..self.Name.."."..name) end
    function methods:FindFirstChildOfClass(class) for _,v in self:GetChildren() do if v:IsA(class) then return v end end end
    function methods:IsDescendantOf(parent) local n=self.Parent;while n do if n==parent then return true end;n=n.Parent end;return false end
    function methods:GetAttribute(name) return self._attrs[name] end
    function methods:SetAttribute(name,value)
        local before=self._attrs[name];self._attrs[name]=value
        if before~=value then if self._attributeSignals[name] then self._attributeSignals[name]:Fire() end;self.AttributeChanged:Fire(name) end
    end
    function methods:GetAttributeChangedSignal(name) self._attributeSignals[name]=self._attributeSignals[name] or signal();return self._attributeSignals[name] end
    function methods:GetPropertyChangedSignal(name) self._propertySignals[name]=self._propertySignals[name] or signal();return self._propertySignals[name] end
    function methods:Destroy()
        if self._destroyed then return end;self._destroyed=true;self.Destroying:Fire()
        for _,v in self:GetChildren() do v:Destroy() end;self.Parent=nil
    end
    function methods:GetGuiObjectsAtPosition() return self._guiObjects or {} end
    local rs=instance("ReplicatedStorage","ReplicatedStorage")
    local world=instance("Workspace","Workspace")
    function world:GetServerTimeNow() return now end
    local camera=instance("Camera","Camera",world);camera.CFrame=cf();camera.FieldOfView=80;camera.ViewportSize={X=1000,Y=700};world.CurrentCamera=camera
    local players=instance("Players","Players");players.PlayerAdded=signal();players.PlayerRemoving=signal()
    local player=instance("Player","LocalPlayer",players);players.LocalPlayer=player
    player.UserId=123;player.Team={Name="Humans"};player.CharacterAdded=signal();player.CharacterRemoving=signal();player.CharacterAppearanceLoaded=signal()
    local playerGui=instance("PlayerGui","PlayerGui",player)
    local oldHUD=instance("ScreenGui","ZO_RifleHUD",playerGui);local oldWeaponHUD=instance("ScreenGui","ZO_WeaponHUD",playerGui)
    local oldModel=instance("Model","ZO_LocalWeapon",camera)
    local character=instance("Model","Character",world);local hum=instance("Humanoid","Humanoid",character);player.Character=character
    local other=instance("Player","Other",players);other.UserId=456;other.CharacterAdded=signal();other.Character=instance("Model","OtherCharacter",world)
    function players:GetPlayers() return {player,other} end
    function players:GetPlayerByUserId(id) for _,p in self:GetPlayers() do if p.UserId==id then return p end end end
    for name,value in {ZO_WeaponId="Rifle",ZO_PrimaryWeapon="Rifle",ZO_SecondaryWeapon="Pistol",ZO_Ammo=30,ZO_Reserve=120,ZO_EquipReadyAt=0} do player:SetAttribute(name,value) end
    rs:SetAttribute("ZO_RoundState","Preparation")
    local shared=instance("Folder","K17Gameplay",rs)
    local modules={}
    local logs={new={},localShots={},worldShots={},distantShots={},impacts={},observed={},stops=0,updates={},destroyed=0}
    local Presentation={}
    function Presentation.new(template,parent,id,actor)
        table.insert(logs.new,{template=template,id=id,actor=actor})
        local p={id=id}
        function p:fire() table.insert(logs.localShots,id) end
        function p:stop() logs.stops+=1 end
        function p:destroy() logs.destroyed+=1 end
        function p:update(camera,pose,visible,alpha) table.insert(logs.updates,{id=id,visible=visible,alpha=alpha}) end
        function p:setReloading(value,remaining) self.reloading=value;self.remaining=remaining end
        return p,"Ready"
    end
    function Presentation.newArms(actor,parent) return {actor=actor},"Ready" end
    function Presentation.updateArms() end
    function Presentation.destroyArms() end
    function Presentation.observeWorld(tool) table.insert(logs.observed,tool) end
    function Presentation.playWorldShot(tool) table.insert(logs.worldShots,tool) end
    function Presentation.playDistantShot(template,origin,id) table.insert(logs.distantShots,{template=template,origin=origin,id=id}) end
    function Presentation.impact(position,normal) table.insert(logs.impacts,{position=position,normal=normal}) end
    local PresentationConfig={get=function(id) return {AimFov=58,ViewKick=.09,RecoilPitch=.65} end}
    for name,value in {Config=Config,Rules=Rules,WeaponPresentation=Presentation,PresentationConfig=PresentationConfig} do modules[instance("ModuleScript",name,shared)]=value end
    local requests={}
    local remotes={}
    for _,name in {"ZO_FireRifle","ZO_Melee","ZO_CombatFX","ZO_LoadoutAction"} do
        local remote=instance("RemoteEvent",name,rs);remote.OnClientEvent=signal();remotes[name]=remote
        function remote:FireServer(...) table.insert(requests,{remote=self.Name,args={...}}) end
    end
    local function addAssets(ids)
        local assets=rs:FindFirstChild("ZO_WeaponAssets") or instance("Folder","ZO_WeaponAssets",rs)
        local weapons=assets:FindFirstChild("Weapons") or instance("Folder","Weapons",assets)
        for _,id in ids do local t=instance("Tool",id,weapons);t:SetAttribute("ZO_WeaponId",id);assets:SetAttribute("Status_"..id,"Ready") end
        return assets
    end
    if not options.noAssets then addAssets(Config.WeaponOrder) end
    local uis={TouchEnabled=options.touch==true,GamepadEnabled=false,WindowFocusReleased=signal(),TextBoxFocused=signal(),focused=false}
    function uis:GetFocusedTextBox() return if self.focused then {} else nil end
    function uis:GetMouseLocation() return {X=0,Y=0} end
    local guiService={MenuOpened=signal(),MenuIsOpen=false}
    local cas={actions={},buttons={}}
    function cas:BindActionAtPriority(name,callback,createButton,priority,...)
        self.actions[name]={callback=callback,createButton=createButton,priority=priority,keys={...}}
        if createButton then self.buttons[name]=instance("TextButton",name) end
    end
    function cas:UnbindAction(name) self.actions[name]=nil;self.buttons[name]=nil end
    function cas:GetButton(name) return self.buttons[name] end
    function cas:SetTitle(name,title) if self.buttons[name] then self.buttons[name].Text=title end end
    function cas:SetPosition(name,position) if self.buttons[name] then self.buttons[name].Position=position end end
    local runService={callbacks={},IsStudio=function() return false end}
    function runService:BindToRenderStep(name,priority,callback) self.callbacks[name]={priority=priority,callback=callback} end
    function runService:UnbindFromRenderStep(name) self.callbacks[name]=nil end
    local cameraBase=cf()
    local inputPitch=0
    logs.cameraBases={}
    -- CameraModule writes a frame at priority 200 before the weapon pass. One
    -- mode rebuilds from controller state; another reads the previous camera so
    -- an unremoved overlay would feed back into later frames.
    runService:BindToRenderStep("FakeRobloxCameraModule",200,function()
        local current=world.CurrentCamera
        table.insert(logs.cameraBases,current.CFrame.pitch)
        if options.cameraMode=="feedback" then current.CFrame*=CFrame.Angles(inputPitch,0,0)
        else current.CFrame=cameraBase end
        inputPitch=0
    end)
    local enum={Font={RobotoMono="RobotoMono"},CoreGuiType={Backpack="Backpack"},AssetFetchStatus={Success="Success"},
        UserInputState={Begin="Begin",End="End",Cancel="Cancel"},ContextActionResult={Pass="Pass",Sink="Sink"},
        UserInputType={MouseButton1="MouseButton1",MouseButton2="MouseButton2",Touch="Touch",Gamepad1="Gamepad1"},
        KeyCode={One="One",Two="Two",Q="Q",R="R",ButtonY="ButtonY",ButtonX="ButtonX",ButtonR2="ButtonR2",ButtonL2="ButtonL2"},
        RenderPriority={Camera={Value=200}},CameraMode={Classic="Classic",LockFirstPerson="LockFirstPerson"},Material={Neon="Neon"}}
    local services={Players=players,ReplicatedStorage=rs,UserInputService=uis,ContextActionService=cas,GuiService=guiService,RunService=runService,
        Debris={AddItem=function(_,obj,lifetime) tasks.delay(lifetime,function() obj:Destroy() end) end},
        ContentProvider={PreloadAsync=function(_,items,callback) for _,item in items do callback(item.Name,"Success") end end},
        StarterGui={SetCoreGuiEnabled=function() end}}
    local localScript=instance("LocalScript","Weapons")
    local env=setmetatable({game={GetService=function(_,name) return assert(services[name],name) end},workspace=world,script=localScript,
        Instance={new=function(class) return instance(class) end},Enum=enum,task=tasks,os={clock=function() return now end},CFrame=CFrame,
        require=function(module) return assert(modules[module],"Unexpected module") end,
        typeof=function(v) return if type(v)=="table" then rawget(v,"_type") or "table" else type(v) end,
        Color3={fromRGB=function(r,g,b) return {R=r,G=g,B=b} end},Vector2={new=function(x,y) return {X=x,Y=y} end},
        Vector3={new=vector,one=vector(1,1,1),zero=vector()},UDim2={new=function(...) return {...} end,
            fromOffset=function(x,y) return {X=x,Y=y} end,fromScale=function(x,y) return {XS=x,YS=y} end}}, {__index=getfenv()})
    local function advance(seconds)
        local deadline=now+seconds;local limit=0
        while true do
            table.sort(queue,function(a,b) return a.at<b.at end)
            if #queue==0 or queue[1].at>deadline+1e-9 then break end
            local job=table.remove(queue,1);now=job.at;limit+=1;assert(limit<100000,"scheduler runaway")
            local ok,delay=coroutine.resume(job.thread,table.unpack(job.args))
            if not ok then table.insert(errors,tostring(delay))
            elseif coroutine.status(job.thread)~="dead" then schedule(job.thread,now+(delay or .03)) end
        end
        now=deadline;assert(#errors==0,"real Weapons LocalScript error: "..table.concat(errors," | "))
    end
    local fn=assert(loadstring(WEAPONS_CLIENT_SOURCE,"Weapons.client.luau"));setfenv(fn,env);tasks.spawn(fn);advance(0)
    local s={player=player,other=other,hum=hum,character=character,rs=rs,world=world,camera=camera,cas=cas,guiService=guiService,
        uis=uis,logs=logs,requests=requests,remotes=remotes,advance=advance,addAssets=addAssets,instance=instance,oldHUD=oldHUD,oldWeaponHUD=oldWeaponHUD,oldModel=oldModel,
        gui=playerGui:FindFirstChild("ZO_WeaponHUD"),playerGui=playerGui,script=localScript,runService=runService}
    function s.key(name,state,inputType,keyCode)
        local action=assert(cas.actions[name],name)
        local result=action.callback(name,state or "Begin",{UserInputType=inputType or "MouseButton1",KeyCode=keyCode or "Unknown"});advance(0);return result
    end
    function s.render(dt)
        local ordered={};for _,entry in runService.callbacks do table.insert(ordered,entry) end
        table.sort(ordered,function(a,b) return a.priority<b.priority end)
        for _,entry in ordered do entry.callback(dt or .1) end
        advance(0)
    end
    function s.input(pitch) inputPitch=pitch end
    function s.base(frame) cameraBase=frame end
    function s.event(name,...) remotes[name].OnClientEvent:Fire(...);advance(0) end
    return s
end

local function singleShot(s)
    s.key("ZO_Trigger","Begin","MouseButton1")
    s.key("ZO_Trigger","End","MouseButton1")
end

do
    for _,mode in {"reset","feedback"} do
        local s=simulation({cameraMode=mode});s.render(1/60);singleShot(s)
        local previous=math.huge
        local positive,monotone,bounded=true,true,true
        for frame=1,120 do
            s.advance(1/60);s.render(1/60)
            local pitch=math.deg(s.camera.CFrame.pitch)
            positive=positive and pitch>=-1e-8
            monotone=monotone and pitch<=previous+1e-8
            bounded=bounded and pitch<=.65+1e-8
            if frame==1 then check(close(pitch,.65),mode.." camera receives the full initial recoil") end
            previous=pitch
        end
        check(positive and monotone and bounded,mode.." camera recoil recovers upward-to-neutral without a downward reversal or accumulation")
        check(close(s.camera.CFrame.pitch,0),mode.." camera has no residual recoil after recovery")
        local baseClean=true;for _,pitch in s.logs.cameraBases do baseClean=baseClean and math.abs(pitch)<1e-8 end
        check(baseClean,mode.." camera controller never reads back the weapon overlay as input")
    end
end

do
    local s=simulation({cameraMode="feedback"});s.render(1/60);singleShot(s);s.render(1/60)
    s.input(math.rad(4));s.render(1/60)
    check(s.camera.CFrame.pitch>math.rad(4),"mouse rotation and remaining recoil coexist on the fresh base")
    for _=1,120 do s.advance(1/60);s.render(1/60) end
    check(close(s.camera.CFrame.pitch,math.rad(4)),"recoil recovery preserves the player's new camera direction")
    local beforeRequests=#s.requests
    singleShot(s);s.render(1/60)
    check(#s.requests==beforeRequests+1 and s.requests[#s.requests].args[1]=="Fire",
        "replacement-frame scenario delivers a new shot after the previous cooldown")
    s.camera.CFrame=cf(0,0,0,math.rad(12))
    s.render(1/60)
    check(s.camera.CFrame.pitch>math.rad(12),"pre-camera removal respects a replacement frame supplied by another controller")
    s.player:SetAttribute("ZO_ShopOpen",true);s.advance(0)
    check(close(s.camera.CFrame.pitch,math.rad(12)),"cancelling recoil removes only the overlay from the external replacement base")
end

do
    local s=simulation({cameraMode="feedback"});s.render(1/60)
    s.key("ZO_Trigger","Begin","MouseButton1")
    for _=1,10 do s.advance(1/60);s.render(1/60) end
    s.key("ZO_Trigger","End","MouseButton1")
    local shots={};for _,request in s.requests do
        if request.remote=="ZO_FireRifle" and request.args[1]=="Fire" then table.insert(shots,request) end
    end
    check(#shots>=2 and shots[2].args[2].Y>0,"held automatic fire samples the visible recoiled direction after CameraModule updates")
end

do
    for _,cancel in {
        function(s) s.player:SetAttribute("ZO_ShopOpen",true);s.advance(0) end,
        function(s) s.key("ZO_Equip","Begin","Keyboard","Two") end,
        function(s) s.uis.WindowFocusReleased:Fire();s.advance(0) end,
        function(s) s.player.Team={Name="Zombies"};s.advance(0) end,
    } do
        local s=simulation({cameraMode="feedback"});s.render(1/60)
        s.key("ZO_Aim","Begin","MouseButton2");s.render(.1);singleShot(s);s.render(1/60)
        check(s.camera.CFrame.pitch>0 and s.camera.FieldOfView<80,"cancellation scenario begins with ADS and visible recoil")
        cancel(s);s.render(1/60)
        check(close(s.camera.CFrame.pitch,0) and close(s.camera.FieldOfView,80),"menu/equip/focus/infection clears recoil and FOV without camera drift")
    end
end

do
    local s=simulation({cameraMode="feedback"});s.render(1/60);singleShot(s);s.render(1/60)
    local replacement=s.instance("Camera","Replacement",s.world)
    replacement.CFrame=cf(0,0,0,math.rad(7));replacement.FieldOfView=75;replacement.ViewportSize={X=1000,Y=700}
    s.world.CurrentCamera=replacement;s.render(1/60)
    check(close(s.camera.CFrame.pitch,0) and close(replacement.CFrame.pitch,math.rad(7)),"camera replacement restores owned old frame without applying stale recoil to the new camera")
    s.script:Destroy();s.advance(0)
    local count=0;for _ in s.runService.callbacks do count+=1 end
    check(count==1 and s.runService.callbacks.FakeRobloxCameraModule~=nil,"destruction removes both recoil render passes while preserving the camera controller")
end

do
    local s=simulation({noAssets=true});s.render(1/60);singleShot(s);s.render(1/60)
    check(close(s.camera.CFrame.pitch,0),"an unavailable template cannot produce fake recoil")
end

local function beginAim(s,inputType,keyCode)
    check(s.key("ZO_Aim","Begin",inputType or "MouseButton2",keyCode)=="Sink","aim starts for active living human")
    s.render(.1);check(s.camera.FieldOfView<80,"aim narrows current camera FOV")
end
local function restored(s,label) check(close(s.camera.FieldOfView,80),label) end

do
    local s=simulation();s.render(.1)
    check(s.oldHUD._destroyed and s.oldWeaponHUD._destroyed and s.oldModel._destroyed,"startup removes both old HUD names and old local model")
    check(s.cas.actions.ZO_Aim.createButton and s.cas:GetButton("ZO_Aim").Text=="Mira","touch aim action has a named button")
    check(table.find(s.cas.actions.ZO_Aim.keys,"MouseButton2")~=nil and table.find(s.cas.actions.ZO_Aim.keys,"ButtonL2")~=nil,"aim binds mouse 2 and gamepad L2")
    check(s.logs.new[1].id=="Rifle","initial generic rifle template constructs presentation")
    beginAim(s)
    local ammo,reserve=s.player:GetAttribute("ZO_Ammo"),s.player:GetAttribute("ZO_Reserve")
    s.key("ZO_Trigger","Begin","MouseButton1")
    local request=s.requests[#s.requests]
    check(request.remote=="ZO_FireRifle" and request.args[1]=="Fire" and request.args[2]._type=="Vector3" and request.args[3]==true,"aimed shot sends direction and optional true ADS through existing fire remote")
    check(#s.logs.localShots==1 and s.logs.localShots[1]=="Rifle","predicted generic rifle presentation fires once")
    check(s.player:GetAttribute("ZO_Ammo")==ammo and s.player:GetAttribute("ZO_Reserve")==reserve,"firing does not mutate server-owned clip or reserve")
    s.key("ZO_Trigger","End");s.key("ZO_Reload","Begin")
    restored(s,"reload action immediately restores pre-ADS FOV")
    check(s.requests[#s.requests].args[1]=="Reload","reload protocol stays unchanged")
    beginAim(s,"Gamepad1","ButtonL2")
    s.player:SetAttribute("ZO_Reloading",true);s.advance(0);restored(s,"server reload attribute cancels ADS and restores FOV")
    check(s.key("ZO_Aim","Begin","MouseButton2")=="Pass","ADS rejected during authoritative reload")
    s.player:SetAttribute("ZO_Reloading",false);s.advance(0);beginAim(s)
    s.player:SetAttribute("ZO_ShopOpen",true);s.advance(0);restored(s,"shop attribute restores FOV")
    check(s.key("ZO_Trigger","Begin","MouseButton1")=="Pass","shop blocks firing")
    s.player:SetAttribute("ZO_ShopOpen",false);s.advance(0);beginAim(s)
    s.player:SetAttribute("ZO_TacticalMapOpen",true);s.advance(0);restored(s,"tactical map restores FOV")
    s.player:SetAttribute("ZO_TacticalMapOpen",false);s.advance(0);beginAim(s)
    s.guiService.MenuIsOpen=true;s.guiService.MenuOpened:Fire();s.advance(0);restored(s,"Roblox menu opening restores FOV")
    s.guiService.MenuIsOpen=false;beginAim(s)
    s.player.Team={Name="Zombies"};s.advance(0);restored(s,"infection team transition restores FOV")
    s.player.Team={Name="Humans"};s.advance(0);beginAim(s)
    s.hum.Health=0;s.advance(0);restored(s,"Humanoid Died restores FOV")
    check(s.key("ZO_Aim","Begin","MouseButton2")=="Pass","dead player cannot begin aim")
end

do
    local s=simulation({touch=true});s.render(.1)
    beginAim(s,"Touch")
    s.key("ZO_Aim","End","Touch");s.render(1);s.render(1);restored(s,"touch aim release recovers original FOV")
    beginAim(s,"Touch")
    s.key("ZO_Equip","Begin","Keyboard","Two");restored(s,"equip action cancels ADS and restores FOV")
    check(s.requests[#s.requests].remote=="ZO_LoadoutAction" and s.requests[#s.requests].args[2]=="Secondary","slot 2 equip remains server request")
    s.player:SetAttribute("ZO_WeaponId","Pistol");s.advance(0);s.render(.1)
    check(s.logs.new[#s.logs.new].id=="Pistol","equipping pistol constructs same generic presentation API")
    s.key("ZO_Trigger","Begin","Touch")
    local request=s.requests[#s.requests]
    check(request.args[1]=="Fire" and request.args[3]==false,"hip shot explicitly sends false ADS")
    check(s.logs.localShots[#s.logs.localShots]=="Pistol","pistol uses imported tool fire presentation")
    s.key("ZO_Trigger","End","Touch")
    beginAim(s,"Touch");s.uis.WindowFocusReleased:Fire();s.advance(0);restored(s,"window focus loss restores ADS FOV")
    beginAim(s,"Touch");s.uis.TextBoxFocused:Fire();s.advance(0);restored(s,"text focus restores ADS FOV")
    beginAim(s,"Touch");s.event("ZO_Melee","Infected");restored(s,"infection event clears ADS immediately")
end

do
    local s=simulation({noAssets=true});s.render(.1)
    check(#s.logs.new==0,"missing initial assets do not invent a weapon model")
    s.addAssets({"Rifle","SMG"});s.advance(0);s.render(.1)
    check(#s.logs.new==1 and s.logs.new[1].id=="Rifle","late replicated weapon package and templates construct current presentation")
    s.player:SetAttribute("ZO_WeaponId","SMG");s.advance(0);s.render(.1)
    check(s.logs.new[#s.logs.new].id=="SMG","late imported SMG is selected generically")
    local origin,destination,normal=vector(0,2,0),vector(0,2,-30),vector(0,1,0)
    s.key("ZO_Trigger","Begin");s.key("ZO_Trigger","End")
    local localCount=#s.logs.localShots
    s.event("ZO_CombatFX","Shot",origin,destination,123,"SMG",nil)
    check(#s.logs.localShots==localCount and #s.logs.worldShots==0 and #s.logs.distantShots==0,"own server echo adds no local or world shot audio")
    check(#s.logs.impacts==0,"miss without hit normal produces no impact effect")
    s.event("ZO_CombatFX","Shot",origin,destination,456,"SMG",normal)
    check(#s.logs.distantShots==1 and s.logs.distantShots[1].id=="SMG","other player without replicated tool uses matching template positional shot audio")
    check(#s.logs.impacts==1 and close(s.logs.impacts[1].normal.Magnitude,1),"authoritative hit normal dispatches real impact API")
    local tool=s.instance("Tool","ZO_EquippedWeapon",s.other.Character);tool:SetAttribute("ZO_WeaponId","SMG");s.advance(0)
    check(s.logs.observed[#s.logs.observed]==tool,"other player's late generic world tool subscribes to reload observer")
    s.event("ZO_CombatFX","Shot",origin,destination,456,"SMG",nil)
    check(#s.logs.worldShots==1 and s.logs.worldShots[1]==tool and #s.logs.distantShots==1,"matching world tool plays shot once without positional fallback duplicate")
    s.event("ZO_CombatFX","Shot",origin,destination,456,"SMG",normal,false)
    check(#s.logs.worldShots==1 and #s.logs.distantShots==1,"extra pellet traces do not replay the same gunshot audio")
    local own=s.instance("Tool","ZO_EquippedWeapon",s.character);own:SetAttribute("ZO_WeaponId","SMG");s.advance(0)
    check(s.logs.observed[#s.logs.observed]~=own,"local world tool is not observed for duplicate reload audio")
    s.script:Destroy();s.advance(0)
    check(s.gui._destroyed and s.cas.actions.ZO_Aim==nil,"script destruction cleans HUD and action bindings")
end
print(("PASS actual Weapons client: %d assertions; ADS/control cancellation, generic tool imports, audio/impact dispatch and server-owned ammo (Roblox API doubles; presentation stubbed)"):format(checks))
