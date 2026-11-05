-- Actual LocalScript with deterministic input, lifecycle and Vector3 property
-- doubles. Does not run Roblox camera, character collisions or real networking.
local Config=assert(loadstring(MOVEMENT_CONFIG_SOURCE))()
local checks=0
local function check(ok,label) assert(ok,label);checks+=1 end
local function near(a,b) return math.abs(a-b)<.0001 end
local vmt={}
local function vector(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0,_type="Vector3"},vmt) end
vmt.__add=function(a,b) return vector(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vmt.__sub=function(a,b) return vector(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vmt.__eq=function(a,b) return a.X==b.X and a.Y==b.Y and a.Z==b.Z end
local floats=buffer.create(4)
local function f32(n) buffer.writef32(floats,0,n);return buffer.readf32(floats,0) end
local function propertyVector(v) return vector(f32(v.X),f32(v.Y),f32(v.Z)) end

local function simulation(options)
    options=options or {}
    local now=10
    local queue,errors={},{}
    local function schedule(fn,at,args) table.insert(queue,{thread=coroutine.create(fn),at=at,args=args or {}}) end
    local function signal()
        local callbacks={}
        local event={}
        function event:Connect(fn)
            local connection={Connected=true}
            callbacks[connection]=fn
            function connection:Disconnect() self.Connected=false;callbacks[self]=nil end
            return connection
        end
        function event:Fire(...) for _,fn in callbacks do schedule(fn,now,{...}) end end
        function event:FireLater(delay,...) for _,fn in callbacks do schedule(fn,now+delay,{...}) end end
        function event:Count() local count=0;for _ in callbacks do count+=1 end;return count end
        return event
    end
    local methods={}
    local function instance(class,name,parent)
        local data={ClassName=class,Name=name or class,_children={},_attrs={},_attributes={},_properties={}}
        local object={_data=data}
        setmetatable(object,{__index=function(_,key)
            if methods[key]~=nil then return methods[key] end
            if data[key]~=nil then return data[key] end
            return data._children[key]
        end,__newindex=function(_,key,value)
            assert(class~="Humanoid" or key~="WalkSpeed","the client must never author movement speed")
            if class=="Humanoid" and key=="CameraOffset" then value=propertyVector(value) end
            local previous=data[key]
            if key=="Parent" and value~=previous then
                if previous then previous._children[data.Name]=nil;previous.ChildRemoved:Fire(object) end
                data.Parent=value
                if value then value._children[data.Name]=object;value.ChildAdded:Fire(object) end
                object.AncestryChanged:Fire(object,value)
            else data[key]=value end
            if previous~=value and data._properties[key] then data._properties[key]:Fire() end
        end})
        object.ChildAdded=signal();object.ChildRemoved=signal();object.AncestryChanged=signal();object.Destroying=signal()
        if class=="Humanoid" then
            object.Health=100;object.Died=signal();object.CameraOffset=vector(2,3,4)
            data.WalkSpeed=16
        end
        if parent then object.Parent=parent end
        return object
    end
    function methods:IsA(kind) return self.ClassName==kind or kind=="Instance" end
    function methods:GetChildren() local children={};for _,v in self._children do table.insert(children,v) end;return children end
    function methods:FindFirstChild(name) return self._children[name] end
    function methods:WaitForChild(name) return assert(self:FindFirstChild(name),"unexpected wait for "..name) end
    function methods:FindFirstChildOfClass(class) for _,v in self._children do if v:IsA(class) then return v end end end
    function methods:IsDescendantOf(parent) local at=self.Parent;while at do if at==parent then return true end;at=at.Parent end;return false end
    function methods:GetAttribute(name) return self._attrs[name] end
    function methods:SetAttribute(name,value)
        local old=self._attrs[name];self._attrs[name]=value
        if old~=value and self._attributes[name] then self._attributes[name]:Fire() end
    end
    function methods:GetAttributeChangedSignal(name) self._attributes[name]=self._attributes[name] or signal();return self._attributes[name] end
    function methods:GetPropertyChangedSignal(name) self._properties[name]=self._properties[name] or signal();return self._properties[name] end
    function methods:Destroy() self.Destroying:Fire();self.Parent=nil end
    local world=instance("Workspace","Workspace")
    local rs=instance("ReplicatedStorage","ReplicatedStorage")
    rs:SetAttribute("ZO_RoundState","Preparation")
    local shared=instance("Folder","K17Gameplay",rs)
    local configModule=instance("ModuleScript","MovementConfig",shared)
    local players=instance("Players","Players")
    local player=instance("Player","Player",players);players.LocalPlayer=player
    player.Team={Name="Humans"};player.CharacterAdded=signal();player.CharacterRemoving=signal()
    local character=instance("Model","Character",world);player.Character=character
    local hum=if options.noHumanoid then nil else instance("Humanoid","Humanoid",character)
    local requests={}
    local function addRemote()
        local remote=instance("RemoteEvent","ZO_MoveIntent",rs)
        function remote:FireServer(mode) table.insert(requests,{mode=mode,time=now,remote=self}) end
        return remote
    end
    local remote=if options.noRemote then nil else addRemote()
    local runService={callbacks={}}
    function runService:BindToRenderStep(name,priority,fn) self.callbacks[name]={priority=priority,fn=fn} end
    function runService:UnbindFromRenderStep(name) self.callbacks[name]=nil end
    local cas={actions={},buttons={}}
    function cas:BindActionAtPriority(name,fn,touch,priority,...)
        self.actions[name]={fn=fn,priority=priority,keys={...}}
        if touch then self.buttons[name]=instance("TextButton",name);self.buttons[name].Visible=true end
    end
    function cas:UnbindAction(name) self.actions[name]=nil;self.buttons[name]=nil end
    function cas:GetButton(name) return self.buttons[name] end
    function cas:SetTitle(name,title) self.buttons[name].Text=title end
    function cas:SetPosition(name,position) self.buttons[name].Position=position end
    local uis={TouchEnabled=options.touch==true,focused=false,WindowFocusReleased=signal(),TextBoxFocused=signal(),TextBoxFocusReleased=signal(),JumpRequest=signal()}
    function uis:GetFocusedTextBox() return if self.focused then {} else nil end
    local gui={MenuIsOpen=false,MenuOpened=signal(),MenuClosed=signal()}
    local enum={UserInputState={Begin="Begin",End="End",Cancel="Cancel"},ContextActionResult={Pass="Pass",Sink="Sink"},
        UserInputType={Touch="Touch",Keyboard="Keyboard",Gamepad1="Gamepad1"},
        KeyCode={LeftShift="LeftShift",RightShift="RightShift",LeftControl="LeftControl",RightControl="RightControl",C="C",ButtonL3="ButtonL3",ButtonB="ButtonB"},
        RenderPriority={Camera={Value=200}}}
    local cameraSamples={}
    runService:BindToRenderStep("FakeRobloxCamera",200,function()
        local current=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if current then table.insert(cameraSamples,current.CameraOffset) end
    end)
    local localScript=instance("LocalScript","Movement")
    local services={Players=players,ReplicatedStorage=rs,RunService=runService,UserInputService=uis,ContextActionService=cas,GuiService=gui}
    local env=setmetatable({game={GetService=function(_,name) return assert(services[name],name) end},workspace=world,script=localScript,
        require=function(module) assert(module==configModule);return Config end,task={delay=function(delay,fn) schedule(fn,now+delay) end},
        os={clock=function() return now end},Enum=enum,Vector3={new=vector},UDim2={new=function(...) return {...} end,fromOffset=function(...) return {...} end},
        typeof=function(value) return if type(value)=="table" then value._type or "table" else type(value) end},{__index=getfenv()})
    local function advance(seconds)
        local deadline=now+seconds;local steps=0
        while true do
            table.sort(queue,function(a,b) return a.at<b.at end)
            if #queue==0 or queue[1].at>deadline+1e-9 then break end
            local item=table.remove(queue,1);now=item.at;steps+=1;assert(steps<10000,"scheduler runaway")
            local ok,problem=coroutine.resume(item.thread,table.unpack(item.args))
            if not ok then table.insert(errors,tostring(problem)) end
        end
        now=deadline;assert(#errors==0,table.concat(errors," | "))
    end
    local fn=assert(loadstring(MOVEMENT_CLIENT_SOURCE));setfenv(fn,env);schedule(fn,now);advance(.2)
    local s={player=player,hum=hum,character=character,world=world,rs=rs,cas=cas,uis=uis,gui=gui,run=runService,
        script=localScript,requests=requests,advance=advance,instance=instance,addRemote=addRemote,remote=remote,cameraSamples=cameraSamples}
    function s.key(name,state,key,inputType)
        local result=assert(cas.actions[name]).fn(name,state or "Begin",{KeyCode=key or "Unknown",UserInputType=inputType or "Keyboard"})
        advance(0);return result
    end
    function s.mode() return requests[#requests] and requests[#requests].mode end
    function s.render(dt)
        dt=dt or 1/60
        local calls={};for _,v in runService.callbacks do table.insert(calls,v) end
        table.sort(calls,function(a,b) return a.priority<b.priority end)
        for _,v in calls do v.fn(dt) end
        advance(dt)
    end
    function s.frames(count) for _=1,count do s.render(1/60) end end
    return s
end

do
    local s=simulation()
    check(s.mode()=="Run","initial state uses the ordinary movement mode")
    check(s.cas.actions.ZO_Walk.priority<2200 and s.cas.actions.ZO_Crouch.priority<2200,"weapon and shop controls retain higher priority")
    check(table.find(s.cas.actions.ZO_Walk.keys,"LeftShift") and table.find(s.cas.actions.ZO_Crouch.keys,"LeftControl"),"keyboard controls bind tactical walk and crouch")
    s.key("ZO_Walk","Begin","LeftShift");s.advance(.1)
    check(s.mode()=="Walk","Shift requests walking, not an invented speed")
    s.key("ZO_Crouch","Begin","LeftControl");s.advance(.1)
    check(s.mode()=="Crouch","held crouch takes precedence over walking")
    local count=#s.requests;s.key("ZO_Walk","End","LeftShift");s.advance(.1)
    check(s.mode()=="Crouch" and #s.requests==count,"releasing lower-priority walk does not cancel held crouch or spam requests")
    s.key("ZO_Crouch","End","LeftControl");s.advance(.1)
    check(s.mode()=="Run","releasing Ctrl returns to ordinary movement")
    s.frames(30);check(#s.requests==count+1,"rendering does not send per-frame movement requests")
    for _,request in s.requests do check(type(request.mode)=="string" and ({Run=true,Walk=true,Crouch=true})[request.mode],"client sends enum intent without a numeric speed") end
end

do
    local s=simulation();s.key("ZO_Walk","Begin","LeftShift");s.advance(.01)
    local before=#s.requests;s.key("ZO_Walk","End","LeftShift")
    check(#s.requests==before and s.mode()=="Walk","quick release is coalesced rather than sent inside the request interval")
    s.advance(.1);check(s.mode()=="Run" and #s.requests==before+1,"latest Run release reaches the server after the interval")
end

do
    local s=simulation();s.key("ZO_Crouch","Begin","C");s.advance(.1);s.key("ZO_Crouch","End","C")
    check(s.mode()=="Crouch","C is a toggle and key release does not stand up")
    s.key("ZO_Walk","Begin","LeftShift");s.advance(.1);s.key("ZO_Crouch","Begin","C");s.advance(.1)
    check(s.mode()=="Walk","toggling crouch off reveals the still-held walking state")
    s.uis.JumpRequest:Fire();s.advance(.1)
    check(s.mode()=="Walk","jump requests release crouch without discarding held walk")
end

do
    local s=simulation({touch=true})
    check(s.cas.buttons.ZO_Walk.Visible and s.cas.buttons.ZO_Crouch.Visible,"touch actions appear for an active player")
    check(s.cas.buttons.ZO_Walk.Text=="Andar" and s.cas.buttons.ZO_Crouch.Text=="Agachar","touch buttons identify both actions")
    s.key("ZO_Walk","Begin",nil,"Touch");s.advance(.1);s.key("ZO_Walk","End",nil,"Touch")
    check(s.mode()=="Walk","touch walking toggles instead of requiring a held finger")
    s.key("ZO_Crouch","Begin","ButtonB","Gamepad1");s.advance(.1)
    check(s.mode()=="Crouch","gamepad B toggles crouch")
    s.key("ZO_Crouch","Cancel","ButtonB","Gamepad1");s.advance(.1)
    check(s.mode()=="Walk","cancelled crouch releases only its own input")
    s.key("ZO_Walk","Begin","ButtonL3","Gamepad1");s.advance(.1)
    check(s.mode()=="Run","gamepad L3 toggles walking off")
    s.player:SetAttribute("ZO_ShopOpen",true);s.advance(.1)
    check(not s.cas.buttons.ZO_Walk.Visible and not s.cas.buttons.ZO_Crouch.Visible,"shop hides movement touch controls")
    check(s.key("ZO_Crouch","Begin","ButtonB","Gamepad1")=="Pass","shop close input is not stolen by movement")
end

do
    local s=simulation();local baseline=s.hum.CameraOffset
    s.key("ZO_Crouch","Begin","C");s.frames(10)
    check(s.hum.CameraOffset==baseline,"unconfirmed local crouch input cannot move the camera through a ceiling")
    s.hum:SetAttribute("ZO_Crouching",true);s.hum:SetAttribute("ZO_CrouchDrop",.9);s.advance(0)
    local previous=baseline.Y
    local monotonic=true
    for _=1,60 do s.render();monotonic=monotonic and s.hum.CameraOffset.Y<=previous+.00001;previous=s.hum.CameraOffset.Y end
    check(monotonic,"approved crouch camera interpolation is monotone at engine vector precision")
    check(near(s.hum.CameraOffset.Y,baseline.Y-.9) and s.hum.CameraOffset.X==baseline.X,"actual rig-scaled drop preserves the lateral camera offset")
    check(near(s.hum.CameraOffset.Z,baseline.Z+Config.CrouchForward*.9/Config.CrouchDrop),"camera forward shift matches the scaled server Root Motor pose")
    check(s.cameraSamples[#s.cameraSamples]==s.hum.CameraOffset,"camera offset updates before the default Roblox camera callback")
    s.hum:SetAttribute("ZO_StandBlocked",true);s.key("ZO_Crouch","Begin","C");s.advance(.1);s.frames(10)
    check(s.mode()=="Run" and near(s.hum.CameraOffset.Y,baseline.Y-.9),"denied standing keeps the server-approved crouch camera despite a released intent")
    s.hum:SetAttribute("ZO_Crouching",false);s.hum:SetAttribute("ZO_StandBlocked",false);s.frames(60)
    check(s.hum.CameraOffset==baseline,"standing acknowledgement restores the original camera offset")
    check(s.hum.WalkSpeed==16,"the movement client never writes character speed")
end

do
    for _,cancel in {
        function(s) s.player:SetAttribute("ZO_TacticalMapOpen",true) end,
        function(s) s.gui.MenuIsOpen=true;s.gui.MenuOpened:Fire() end,
        function(s) s.uis.focused=true;s.uis.TextBoxFocused:Fire() end,
        function(s) s.uis.WindowFocusReleased:Fire() end,
        function(s) s.player.Team={Name="Zombies"} end,
        function(s) s.rs:SetAttribute("ZO_RoundState","Results") end,
        function(s) s.hum.Health=0;s.hum.Died:Fire() end,
    } do
        local s=simulation();s.key("ZO_Crouch","Begin","C");s.advance(.1);cancel(s);s.advance(.1)
        check(s.mode()=="Run","menu/focus/team/phase/death cancels held and toggled intent")
    end
end

do
    local s=simulation();s.hum.CameraOffset=vector(7,8,9);s.frames(5)
    check(s.hum.CameraOffset==vector(7,8,9),"camera replacement before the first render is respected")
    s.script:Destroy();s.advance(.1)
    check(s.hum.CameraOffset==vector(7,8,9),"cleanup never restores a baseline it did not author")
end

do
    local s=simulation();s.hum:SetAttribute("ZO_Crouching",true);s.advance(0);s.frames(10)
    s.hum.CameraOffset=vector(8,9,10);s.frames(5)
    check(s.hum.CameraOffset==vector(8,9,10),"another camera controller's replacement offset is respected")
    s.script:Destroy();s.advance(.1)
    check(s.hum.CameraOffset==vector(8,9,10),"cleanup does not subtract stale crouch from another controller's offset")
    check(s.run.callbacks.ZO_MovementCamera==nil and s.run.callbacks.FakeRobloxCamera~=nil,"cleanup removes only the owned render binding")
    check(s.cas.actions.ZO_Walk==nil and s.cas.actions.ZO_Crouch==nil,"cleanup unbinds both movement actions")
end

do
    local s=simulation();local old=s.hum;local baseline=old.CameraOffset
    old:SetAttribute("ZO_Crouching",true);s.advance(0);s.frames(10)
    old.Died:FireLater(.3);s.character.AncestryChanged:FireLater(.3,s.character,nil)
    local nextCharacter=s.instance("Model","NextCharacter",s.world)
    local nextHum=s.instance("Humanoid","Humanoid",nextCharacter);nextHum.CameraOffset=vector(-1,.2,5)
    local nextBase=nextHum.CameraOffset
    s.player.Character=nextCharacter;s.player.CharacterAdded:Fire(nextCharacter);s.advance(.1);s.frames(4)
    check(old.CameraOffset==baseline and nextHum.CameraOffset==nextBase,"respawn restores the old owned camera and preserves the new rig baseline")
    s.character.Parent=nil;s.advance(0)
    old.Died:Fire();s.player.CharacterRemoving:Fire(s.character);s.advance(.1)
    s.key("ZO_Walk","Begin","LeftShift");s.advance(.1)
    check(s.mode()=="Walk","stale old-character callbacks cannot disable the current character")
    s.advance(.4)
    check(s.mode()=="Walk","already-queued old death and ancestry callbacks cannot reset current movement")
    s.player.CharacterAdded:Fire(s.character);s.advance(.1)
    check(s.key("ZO_Walk","End","LeftShift")=="Sink","a late CharacterAdded for an old model cannot replace the current binding")
    s.script:Destroy();s.advance(.1)
    check(nextHum.CameraOffset==nextBase,"destroying the current controller preserves its starting camera offset")
end

do
    local s=simulation({noRemote=true});s.key("ZO_Walk","Begin","LeftShift");s.key("ZO_Crouch","Begin","LeftControl");s.advance(.1)
    check(#s.requests==0,"late server remote does not block controls or invent a local speed")
    s.addRemote();s.advance(.1)
    check(#s.requests==1 and s.mode()=="Crouch","late remote receives only the latest desired mode")
    s.key("ZO_Crouch","End","LeftControl");s.advance(.1)
    check(s.mode()=="Walk","held walk remains after late-remote crouch release")
end

do
    local s=simulation({noHumanoid=true})
    check(s.key("ZO_Crouch","Begin","C")=="Pass","input rejects a character before its Humanoid arrives")
    local hum=s.instance("Humanoid","Humanoid",s.character);s.advance(.1)
    s.key("ZO_Crouch","Begin","C");s.advance(.1)
    check(s.mode()=="Crouch" and hum.WalkSpeed==16,"late Humanoid activates input without a client speed write")
end

print(("PASS actual Movement client: %d checks; input/camera/lifecycle API doubles, no Studio rendering or collision simulation"):format(checks))
