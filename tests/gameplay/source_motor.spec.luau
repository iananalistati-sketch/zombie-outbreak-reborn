-- Actual LocalScript with deterministic keyboard, default-input and rig doubles.
-- These tests check requested analog movement, never native engine locomotion.
local Movement=assert(loadstring(SOURCE_MOVEMENT_SOURCE))()
local checks=0
local function check(ok,label) assert(ok,label);checks+=1 end
local function near(a,b) return math.abs(a-b)<1e-6 end
local vectorMeta={}
local function vector(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vectorMeta) end
vectorMeta.__eq=function(a,b) return a.X==b.X and a.Y==b.Y and a.Z==b.Z end
vectorMeta.__index=function(v,key)
    local length=math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z)
    if key=="Magnitude" then return length end
    if key=="Unit" then return vector(v.X/length,v.Y/length,v.Z/length) end
end
local zero=vector()
local function requested(humanoid) return assert(humanoid.Moves[#humanoid.Moves],"no submitted Move").direction end

local function simulation(options)
    options=options or {}
    local function signal()
        local callbacks={}
        local event={}
        function event:Connect(fn)
            local connection={Connected=true};callbacks[connection]=fn
            function connection:Disconnect() self.Connected=false;callbacks[self]=nil end
            return connection
        end
        function event:Fire(...)
            local pending={};for connection,fn in callbacks do table.insert(pending,{connection,fn}) end
            for _,item in pending do if item[1].Connected then item[2](...) end end
        end
        function event:Count() local count=0;for _ in callbacks do count+=1 end;return count end
        return event
    end
    local methods={}
    local protected={WalkSpeed=true,Jump=true,JumpPower=true,JumpHeight=true,AutoRotate=true,
        CanCollide=true,CanTouch=true,CanQuery=true,CustomPhysicalProperties=true,Anchored=true,
        CFrame=true,Position=true,AssemblyLinearVelocity=true,AssemblyAngularVelocity=true}
    local function instance(class,name,parent)
        local data={ClassName=class,Name=name or class,Parent=parent,_children={},_attrs={}}
        local object={_data=data}
        setmetatable(object,{__index=function(_,key) return methods[key] or data[key] or data._children[key] end,
            __newindex=function(_,key,value)
                assert(not protected[key],"Source adapter must not author "..key)
                assert(class~="Humanoid" and class~="Part","Source adapter must not assign rig property "..key)
                data[key]=value
            end})
        data.Destroying=signal()
        if parent then parent._data._children[data.Name]=object end
        return object
    end
    function methods:IsA(class) return self.ClassName==class or (class=="BasePart" and self.ClassName=="Part") end
    function methods:FindFirstChild(name) return self._data._children[name] end
    function methods:WaitForChild(name) return assert(self:FindFirstChild(name),"unexpected wait for "..name) end
    function methods:FindFirstChildOfClass(class) for _,child in self._data._children do if child:IsA(class) then return child end end end
    function methods:IsDescendantOf(parent) local at=self.Parent;while at do if at==parent then return true end;at=at.Parent end;return false end
    function methods:GetAttribute(name) return self._data._attrs[name] end
    function methods:SetAttribute(name,value) self._data._attrs[name]=value end
    function methods:GetState() return self._data.State end
    function methods:Move(direction,relative)
        table.insert(self._data.Moves,{direction=direction,relative=relative})
        -- The observable engine property is unit/zero; the submitted argument
        -- above retains its magnitude for analog-request assertions.
        self._data.MoveDirection=if direction.Magnitude>0 then direction.Unit else zero
    end
    function methods:Destroy() self.Destroying:Fire();self._data.Parent=nil end
    local world=instance("Workspace","Workspace")
    world:SetAttribute("ZO_BarricadePractice",options.practice==true)
    world.CurrentCamera={CFrame={LookVector=vector(0,0,-1)}}
    local rs=instance("ReplicatedStorage","ReplicatedStorage")
    rs:SetAttribute("ZO_RoundState",options.phase or "Preparation")
    local shared=instance("Folder","K17Gameplay",rs)
    local movementModule=instance("ModuleScript","SourceMovement",shared)
    local players=instance("Players","Players")
    local player=instance("Player","Player",players);players.LocalPlayer=player
    player.Team={Name=options.team or "Humans"}
    local function character(name)
        local model=instance("Model",name or "Character",world)
        local hum=instance("Humanoid","Humanoid",model)
        local root=instance("Part","HumanoidRootPart",model)
        local h=hum._data;h.Health=100;h.WalkSpeed=16;h.Sit=false;h.PlatformStand=false
        h.State="Running";h.FloorMaterial="Concrete";h.MoveDirection=zero;h.Moves={}
        h.Jump=true;h.JumpPower=50;h.JumpHeight=7.2;h.AutoRotate=true
        local r=root._data;r.AssemblyLinearVelocity=vector();r.Anchored=false
        r.CanCollide=true;r.CanTouch=true;r.CanQuery=true;r.CustomPhysicalProperties={friction=.3}
        r.CFrame={LookVector=vector(0,0,-1)}
        return model,hum,root
    end
    local model,hum,root=character();player.Character=model
    local allPlayers={player};if options.multiplayer then table.insert(allPlayers,{}) end
    function players:GetPlayers() return allPlayers end
    local run={callbacks={}}
    function run:IsStudio() return options.studio==true end
    function run:BindToRenderStep(name,priority,fn) self.callbacks[name]={priority=priority,fn=fn} end
    function run:UnbindFromRenderStep(name) self.callbacks[name]=nil end
    local uis={keys={W=true},lastInput=options.device or "Keyboard",focused=nil,
        WindowFocusReleased=signal(),WindowFocused=signal()}
    function uis:GetLastInputType() return {Name=self.lastInput} end
    function uis:IsKeyDown(key) return self.keys[key]==true end
    function uis:GetFocusedTextBox() return self.focused end
    local gui={MenuIsOpen=false}
    local localScript=instance("LocalScript","SourceMotor")
    local calls={}
    local services={Players=players,ReplicatedStorage=rs,RunService=run,UserInputService=uis,GuiService=gui}
    local enum={RenderPriority={Input={Value=100}},Material={Air="Air"},HumanoidStateType={},KeyCode={}}
    for _,name in {"Running","RunningNoPhysics","Landed","Jumping","Freefall","Swimming","Climbing","Seated","Dead","Physics","Ragdoll","FallingDown","GettingUp"} do
        enum.HumanoidStateType[name]=name
    end
    for _,name in {"W","A","S","D","Up","Down","Left","Right"} do enum.KeyCode[name]=name end
    local env=setmetatable({game={GetService=function(_,name) return assert(services[name],name) end},workspace=world,
        script=localScript,Enum=enum,Vector3={zero=zero,new=vector},require=function(module)
            assert(module==movementModule,"unexpected module dependency")
            return {step=function(...) table.insert(calls,{...});return Movement.step(...) end}
        end},{__index=getfenv()})
    local s={world=world,rs=rs,players=players,player=player,character=model,hum=hum,root=root,run=run,uis=uis,gui=gui,
        script=localScript,calls=calls,native=vector(0,0,1),newCharacter=character,allPlayers=allPlayers}
    run:BindToRenderStep("FakeDefaultInput",100,function()
        local current=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if current then current._data.MoveDirection=s.native end
    end)
    function s.render(dt)
        local bindings={};for _,binding in run.callbacks do table.insert(bindings,binding) end
        table.sort(bindings,function(a,b) return a.priority<b.priority end)
        for _,binding in bindings do binding.fn(dt or 1/60) end
    end
    function s.observe(x,y,z) root._data.AssemblyLinearVelocity=vector(x,y,z) end
    local fn=assert(loadstring(SOURCE_MOTOR_SOURCE));setfenv(fn,env);fn()
    return s
end

do
    local s=simulation()
    check(s.script:GetAttribute("ZO_SourceMotorReady")==true,"the actual adapter reaches startup")
    check(s.run.callbacks.ZO_SourceInput.priority==102,"desktop filtering runs after the default input priority")
    s.observe(4,37,2);s.render()
    local call=s.calls[1]
    check(call[1]==4 and call[2]==2 and call[3]==0 and call[4]==-1,"the kernel receives observed root velocity and camera-relative keyboard wish")
    check(call[5]==16 and call[6]==true and near(call[7],1/60),"the current server-composed speed, floor status and frame delta reach the real kernel")
    local x,z=Movement.step(4,2,0,-1,16,true,1/60)
    local drive=requested(s.hum)
    check(near(drive.X,x/16) and near(drive.Z,z/16) and drive.Y==0,"kernel output becomes proportional horizontal analog movement after default input")
    check(near(s.hum.MoveDirection.Magnitude,1) and drive.Magnitude<1,"the double keeps observed direction separate from the submitted analog magnitude")
    check(#s.hum.Moves==1 and s.hum.Moves[1].relative==false and s.hum:GetAttribute("ZO_SourceMovement")==true,"the owned input is submitted once in world space")
    check(s.root.AssemblyLinearVelocity==vector(4,37,2) and s.hum.Jump and s.hum.JumpPower==50 and s.hum.JumpHeight==7.2,"the adapter preserves observed velocity and native jump properties")
    check(s.hum.WalkSpeed==16 and s.hum.AutoRotate and s.root.CanCollide and s.root.CanTouch and s.root.CanQuery and s.root.CustomPhysicalProperties.friction==.3,"server speed, rig rotation and collision properties retain their values")
    s.hum._data.WalkSpeed=8;s.hum._data.FloorMaterial="Air";s.hum._data.State="Freefall"
    s.observe(6,-22,2);s.render()
    check(s.calls[2][5]==8 and s.calls[2][6]==false and s.root.AssemblyLinearVelocity.Y==-22,"each frame reads new containment speed and airborne velocity without changing falling motion")
    s.observe(-3,8,1);s.render()
    check(s.calls[3][1]==-3 and s.calls[3][2]==1,"a later observed contact response replaces the previous solver input")
    s.observe(100,8,100);s.render()
    check(near(requested(s.hum).Magnitude,1),"large physical impulses cannot request analog input above unit magnitude")
end

do
    local s=simulation();s.uis.keys={D=true};local previous=0;local increasing=true
    for _=1,15 do
        s.render();local direction=requested(s.hum)
        increasing=increasing and direction.Magnitude>=previous-1e-6 and direction.Magnitude<=1.000001
        previous=direction.Magnitude
        -- Ideal tracking of the requested drive is a test input, not simulated physics.
        s.observe(direction.X*16,0,direction.Z*16)
    end
    check(increasing and near(previous,1),"under ideal response inputs, desired analog speed ramps to the server target")
    s.uis.keys={};s.observe(16,0,0);s.render();local coast=requested(s.hum).X
    check(coast>0 and coast<1,"releasing keys requests a lower analog speed from observed motion")
    s.uis.keys={A=true};s.observe(16,0,0);s.render()
    check(requested(s.hum).X<coast,"opposite keyboard input requests stronger braking than coasting")
    s.hum._data.WalkSpeed=0;s.render()
    check(requested(s.hum)==zero,"a disabled server speed yields zero requested movement")
end

do
    for _,entry in {
        {keys={W=true},look=vector(1,.7,0),wx=1,wz=0},
        {keys={D=true},look=vector(1,.7,0),wx=0,wz=1},
        {keys={Up=true},look=vector(0,0,-1),wx=0,wz=-1},
        {keys={Down=true},look=vector(0,0,-1),wx=0,wz=1},
        {keys={Left=true},look=vector(0,0,-1),wx=-1,wz=0},
        {keys={Right=true},look=vector(0,0,-1),wx=1,wz=0},
        {keys={W=true,D=true},look=vector(0,0,-1),wx=1,wz=-1},
        {keys={W=true,Up=true,D=true},look=vector(0,0,-1),wx=1,wz=-1},
        {keys={W=true,Up=true,S=true},look=vector(0,0,-1),wx=0,wz=0},
        {keys={D=true,Right=true,A=true},look=vector(0,0,-1),wx=0,wz=0},
        {keys={W=true,S=true,A=true,D=true},look=vector(0,0,-1),wx=0,wz=0},
    } do
        local s=simulation();s.uis.keys=entry.keys;s.world.CurrentCamera.CFrame.LookVector=entry.look;s.render()
        check(near(s.calls[1][3],entry.wx) and near(s.calls[1][4],entry.wz),"camera heading maps WASD and arrows to the intended world-space wish")
    end
    local s=simulation();s.world.CurrentCamera.CFrame.LookVector=vector(0,1,0)
    s.root._data.CFrame.LookVector=vector(1,0,0);s.render()
    check(near(s.calls[1][3],1) and near(s.calls[1][4],0),"a vertical camera falls back to the rig heading")
    s.root._data.CFrame.LookVector=vector(0,1,0);s.render()
    check(s.calls[2][3]==0 and s.calls[2][4]==-1,"degenerate camera and rig headings keep a finite default direction")
end

do
    for _,capture in {function(t) t.uis.focused={} end,function(t) t.gui.MenuIsOpen=true end} do
        for _,airborne in {false,true} do
            local s=simulation();s.observe(16,if airborne then -22 else 0,0)
            if airborne then s.hum._data.FloorMaterial="Air";s.hum._data.State="Freefall" end
            local observed=s.root.AssemblyLinearVelocity
            capture(s);s.render();s.render()
            check(#s.calls==0 and #s.hum.Moves==2 and requested(s.hum)==zero,
                "chat or Roblox menu capture submits zero drive despite nonzero ground or air momentum")
            check(s.root.AssemblyLinearVelocity==observed and s.hum:GetAttribute("ZO_SourceMovement")==true,
                "captured input preserves observed physical momentum while retaining explicit input ownership")
        end
    end
    local s=simulation();s.observe(16,8,0);s.render();local calls=#s.calls
    s.uis.WindowFocusReleased:Fire();s.render();s.render()
    check(#s.calls==calls and requested(s.hum)==zero and s.root.AssemblyLinearVelocity==vector(16,8,0),
        "window focus loss suppresses held keys and drive without touching observed velocity")
    s.uis.WindowFocused:Fire();s.render()
    check(#s.calls==calls+1 and requested(s.hum).Magnitude>0,
        "window focus gain resumes filtering fresh eligible keyboard input")
end

do
    for _,state in {"Running","RunningNoPhysics","Landed","Jumping","Freefall"} do
        local s=simulation();s.hum._data.State=state;s.render()
        check(#s.calls==1,"ordinary ground, jump and falling states accept human movement")
    end
    local exclusions={
        function(s) s.player.Team={Name="Zombies"} end,
        function(s) s.player.Team=nil end,
        function(s) s.hum._data.Health=0 end,
        function(s) s.root._data.Anchored=true end,
        function(s) s.hum._data.Sit=true end,
        function(s) s.hum._data.PlatformStand=true end,
        function(s) s.character._data.Parent=nil end,
        function(s) s.player.Character=nil end,
        function(s) s.character._data._children.Humanoid=nil end,
        function(s) s.character._data._children.HumanoidRootPart=nil end,
        function(s) s.world.CurrentCamera=nil end,
    }
    for _,state in {"Swimming","Climbing","Seated","Dead","Physics","Ragdoll","FallingDown","GettingUp"} do
        local blocked=state;table.insert(exclusions,function(s) s.hum._data.State=blocked end)
    end
    for _,phase in {"Waiting","Results","Intermission"} do
        local blocked=phase;table.insert(exclusions,function(s) s.rs:SetAttribute("ZO_RoundState",blocked) end)
    end
    for _,device in {"Touch","Gamepad1","Gamepad8"} do
        local blocked=device;table.insert(exclusions,function(s) s.uis.lastInput=blocked end)
    end
    for _,exclude in exclusions do
        local s=simulation();exclude(s);s.render()
        check(#s.calls==0 and #s.hum.Moves==0,"ineligible characters or fallback devices never receive a solver movement override")
    end
    for _,phase in {"Preparation","Active"} do
        local s=simulation({phase=phase});s.render()
        check(#s.calls==1,"both live human round phases enable the desktop filter")
    end
end

do
    for _,handoff in {
        function(s) s.player.Team={Name="Zombies"} end,
        function(s) s.uis.lastInput="Touch" end,
        function(s) s.uis.lastInput="Gamepad1" end,
        function(s) s.hum._data.Health=0 end,
    } do
        local s=simulation();s.render();local calls=#s.calls;local moves=#s.hum.Moves
        handoff(s);s.render();s.render()
        check(s.hum:GetAttribute("ZO_SourceMovement")==false and #s.calls==calls and #s.hum.Moves==moves,"team, device or death handoff clears ownership and stops analog writes")
        check(s.hum.MoveDirection==s.native,"handoff preserves fresh movement from the default controller")
    end
    local s=simulation();s.render();local old=s.hum
    local model,hum=s.newCharacter("Replacement");s.player.Character=model;s.render()
    check(old:GetAttribute("ZO_SourceMovement")==false and #old.Moves==1 and hum:GetAttribute("ZO_SourceMovement")==true and #hum.Moves==1,"respawn releases the old rig and gives the replacement its own fresh input")
    check(s.uis.WindowFocusReleased:Count()==1 and s.uis.WindowFocused:Count()==1,"the active motor owns one listener per window focus signal")
    s.script:Destroy()
    check(s.run.callbacks.ZO_SourceInput==nil and s.run.callbacks.FakeDefaultInput~=nil,"destroy removes only the owned render binding")
    check(hum:GetAttribute("ZO_SourceMovement")==false,"destroy clears the current movement ownership attribute")
    check(s.uis.WindowFocusReleased:Count()==0 and s.uis.WindowFocused:Count()==0,"destroy disconnects both owned window focus listeners")
    s.render();check(#hum.Moves==1 and hum.MoveDirection==s.native,"disposed callbacks cannot overwrite subsequent default input")
end

do
    for _,options in {
        {phase="Waiting",studio=true,practice=true},
        {phase="Waiting",studio=false,practice=true},
        {phase="Waiting",studio=true,practice=false},
        {phase="Waiting",studio=true,practice=true,multiplayer=true},
    } do
        local s=simulation(options);s.render()
        local expected=options.studio and options.practice and not options.multiplayer
        check((#s.calls==1)==expected,"waiting-room practice requires Studio, the explicit practice flag and a solo player")
    end
end

print(("PASS Source motor client: %d checks; actual source and API doubles, no engine locomotion/physics"):format(checks))
