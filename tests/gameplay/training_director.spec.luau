-- Real director/state; rigs/navigation/physics are API doubles, not engine tests.
local Config=table.clone(assert(loadstring(CONFIG_SOURCE))())
Config.Mode="Survival" -- Preserve finite-wave regression cases; integrated ZE runs separately.
local State=assert(loadstring(STATE_SOURCE))()
local Movement=assert(loadstring(MOVEMENT_SOURCE))()
local checks=0
local function check(v,label)assert(v,label);checks+=1 end
local vm={}
local function vec(x,y,z)return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vm)end
vm.__add=function(a,b)return vec(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
vm.__sub=function(a,b)return vec(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
vm.__mul=function(a,b)return vec(a.X*b,a.Y*b,a.Z*b)end
vm.__div=function(a,b)return vec(a.X/b,a.Y/b,a.Z/b)end
vm.__index=function(v,k)if k=="Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z)elseif k=="Unit" then return v/v.Magnitude end end
local cm={}
local function cf(x,y,z)return setmetatable({Position=if type(x)=="table" then x else vec(x,y,z)},cm)end
cm.__mul=function(a,b)return cf(a.Position+b.Position)end
local function simulation()
    local now=0;local queue={};local errors={};local warnings={}
    local function schedule(fn,at)table.insert(queue,{thread=if type(fn)=="thread" then fn else coroutine.create(fn),at=at})end
    local tasks={spawn=function(fn)schedule(fn,now)end,wait=function(t)return coroutine.yield(t)end}
    local function signal()
        local callbacks={}
        return {Connect=function(_,fn)
            local connection={Connected=true};callbacks[connection]=fn
            function connection:Disconnect()self.Connected=false;callbacks[self]=nil end
            return connection
        end,Fire=function(_,...)for c,fn in callbacks do if c.Connected then fn(...)end end end}
    end
    local methods={}
    local function object(class,name,parent)
        local data={ClassName=class,Name=name,_children={},_attrs={}}
        local o
        o=setmetatable({data=data},{__index=function(_,k)return methods[k] or data[k]end,
            __newindex=function(_,k,v)
                if k=="Parent" then
                    if data.Parent then data.Parent.data._children[data.Name]=nil end
                    data.Parent=v;if v then v.data._children[data.Name]=o end
                else data[k]=v end
            end})
        if parent then o.Parent=parent end;return o
    end
    function methods:GetChildren()local a={};for _,v in self.data._children do table.insert(a,v)end;return a end
    function methods:FindFirstChild(n)return self.data._children[n]end
    function methods:WaitForChild(n)return assert(self:FindFirstChild(n),self.Name.."."..n)end
    function methods:FindFirstChildOfClass(c)for _,v in self:GetChildren()do if v.ClassName==c then return v end end end
    function methods:SetAttribute(n,v)self.data._attrs[n]=v end
    function methods:GetAttribute(n)return self.data._attrs[n]end
    function methods:IsDescendantOf(p)local n=self.Parent;while n do if n==p then return true end;n=n.Parent end;return false end
    function methods:Destroy()for _,child in self:GetChildren()do child:Destroy()end;self.Parent=nil end
    function methods:PivotTo(at)self.HRP.Position=at.Position;self.Pivots=(self.Pivots or 0)+1 end
    function methods:SetNetworkOwner(owner)self.Owner=owner end
    function methods:MoveTo(p)self.LastMove=p end
    local world=object("Workspace","Workspace")
    local rs=object("ReplicatedStorage","ReplicatedStorage")
    local shared=object("Folder","K17Gameplay",rs);local cfg=object("Folder","Shared",rs)
    local moduleNames={}
    for _,n in {'TrainingConfig','TrainingState','TrainingRig','MovementState'}do moduleNames[object('ModuleScript',n,shared)]=n end
    moduleNames[object('ModuleScript','RoundConfig',cfg)]='RoundConfig'
    local teams=object("Teams","Teams");local humanTeam=object("Team","Humans",teams)
    local map=object("Model","ZO_K17Foundry",world);local spawns=object("Model","Spawns",map)
    local marker=object("Part","HumanSpawn",spawns);marker.CFrame=cf(-68,1,-136);marker.Position=marker.CFrame.Position
    local function character()
        local model=object("Model","Character",world)
        local h=object("Humanoid","Humanoid",model);h.Health=100;h.WalkSpeed=16;h.Died=signal()
        local root=object("Part","HumanoidRootPart",model);root.Position=vec(-68,5,-136);model.HRP=root
        return model,h,root
    end
    local player=object("Player","Player");local model,hum,root=character();player.Character=model
    local list={player};local players={GetPlayers=function()return table.clone(list)end}
    rs:SetAttribute("ZO_RoundState","Training");rs:SetAttribute("ZO_GameplayStatus","Ready")
    local rigs={};local failRig=false
    local Rig={new=function(_,at,health,speed)
        if failRig then error("rig fixture failure")end
        local b,h,r=character();b.Parent=nil;h.Health=health;h.WalkSpeed=speed;r.Position=at.Position
        table.insert(rigs,b);return b
    end}
    local ss=object('ServerStorage','ServerStorage')
    local internal=object('Folder','ZO_Gameplay',ss)
    local damage=object('BindableFunction','DamageBarricade',internal)
    local barricadeCalls={}
    function damage:Invoke(bot,part)table.insert(barricadeCalls,{bot,part,now});return 100 end
    local services={Players=players,ReplicatedStorage=rs,Teams=teams,ServerStorage=ss,
        Debris={AddItem=function(_,item,t)schedule(function()item:Destroy()end,now+t)end},
        PathfindingService={CreatePath=function()return {Status="Success",ComputeAsync=function()end,GetWaypoints=function()return{}end}end}}
    function world:Raycast()return nil end
    local modules={TrainingConfig=Config,TrainingState=State,TrainingRig=Rig,MovementState=Movement,RoundConfig={HumanHealth=100,HumanWalkSpeed=16}}
    local env=setmetatable({game={GetService=function(_,n)return assert(services[n],n)end},workspace=world,
        Instance={new=function(c)return object(c,c)end},task=tasks,os={clock=function()return now end},
        Vector3={new=vec},CFrame={new=cf},warn=function(s)table.insert(warnings,s)end,
        RaycastParams={new=function()return{}end},Enum={PathStatus={Success="Success"},PathWaypointAction={Jump="Jump"},RaycastFilterType={Exclude="Exclude"}},
        require=function(m)return assert(modules[moduleNames[m]],"unexpected module")end},{__index=getfenv()})
    local s={rs=rs,world=world,player=player,hum=hum,model=model,root=root,list=list,rigs=rigs,warnings=warnings,character=character,errors=errors,
        object=object,barricadeCalls=barricadeCalls}
    function s.advance(delta)
        local finish=now+delta;local iterations=0
        while true do
            table.sort(queue,function(a,b)return a.at<b.at end)
            if not queue[1] or queue[1].at>finish then break end
            local job=table.remove(queue,1);now=job.at;iterations+=1;assert(iterations<20000,'scheduler runaway')
            local ok,delay=coroutine.resume(job.thread)
            if not ok then table.insert(errors,tostring(delay))
            elseif coroutine.status(job.thread)~='dead' then schedule(job.thread,now+(delay or .01))end
        end
        now=finish;assert(#errors==0,table.concat(errors,' | '))
    end
    function s.kill(bot)local h=bot:FindFirstChildOfClass('Humanoid');h.Health=0;h.Died:Fire()end
    function s.failRig()failRig=true end
    local fn=assert(loadstring(DIRECTOR_SOURCE));setfenv(fn,env);schedule(fn,0)
    return s
end
do
    local s=simulation();s.advance(1)
    check(s.rs:GetAttribute('ZO_TrainingStage')=='Intro','solo player enters an actual training session automatically: '..tostring(s.rs:GetAttribute('ZO_TrainingError')))
    check(s.player.Team.Name=='Humans' and s.model.Pivots==1,'training prepares human role and a spawn exactly once')
    check(s.world:GetAttribute('ZO_BarricadePractice')==true,'server enables the scoped practice capability')
    check(s.world:GetAttribute('ZO_PracticeRevision')==1,'starter inventory reset revision is published')
    s.advance(6)
    check(#s.rigs==1 and s.rigs[1].HRP.Owner==nil,'server creates and owns the first actor after intro')
    check(s.rigs[1]:FindFirstChildOfClass('Humanoid').LastMove~=nil,'real agent loop requests pursuit movement')
    s.kill(s.rigs[1]);s.advance(2);s.kill(s.rigs[2]);s.advance(2);s.kill(s.rigs[3]);s.advance(.3)
    check(s.rs:GetAttribute('ZO_TrainingWave')==2 and s.rs:GetAttribute('ZO_TrainingStage')=='Between','confirmed deaths advance the wave')
    check(s.rs:GetAttribute('ZO_TrainingKills')==3,'total confirmed kills are published')
    s.advance(11)
    check(s.rs:GetAttribute('ZO_TrainingAlive')<=Config.MaxAlive,'concurrent enemies stay bounded')
    table.insert(s.list,{}) -- client arrives before the Round service changes its phase
    s.advance(.3)
    check(s.world:GetAttribute('ZO_BarricadePractice')==false,'a second connection revokes solo capabilities immediately')
    check(not s.world:FindFirstChild('ZO_PracticeTargets'),'handoff removes every training rig')
    local created=#s.rigs;s.rs:SetAttribute('ZO_RoundState','Active');s.advance(5)
    check(#s.rigs==created,'multiplayer cannot receive stray solo enemies')
end
do
    local s=simulation();s.advance(7);s.hum.Health=0;s.advance(.4)
    check(s.rs:GetAttribute('ZO_TrainingStage')=='Lost','player death produces a visible loss')
    check(not s.world:FindFirstChild('ZO_PracticeTargets'),'loss removes active attackers')
    local model,hum=s.character();s.player.Character=model;s.advance(7)
    check(s.rs:GetAttribute('ZO_TrainingStage')=='Intro' and model.Pivots==1,'respawn automatically starts a fresh attempt')
end
do
    local s=simulation();s.advance(1);s.failRig();s.advance(6)
    check(string.find(s.rs:GetAttribute('ZO_TrainingError') or '', 'rig fixture failure',1,true)~=nil,'rig failures are reported instead of an endless waiting screen')
    check(s.world:GetAttribute('ZO_BarricadePractice')==false and not s.world:FindFirstChild('ZO_PracticeTargets'),'runtime failure cleans up the practice capability and actors')
end
do
    local body={}
    local function item(class,name)
        local o={ClassName=class,Name=name,attrs={}}
        function o:IsA(c)return c==self.ClassName or (c=='BasePart' and self.ClassName=='Part') or (c=='LuaSourceContainer' and self.ClassName=='LocalScript')end
        function o:Destroy()self.destroyed=true end
        function o:GetAttribute(n)return self.attrs[n]end
        return o
    end
    local clone=item('Model','Copy')
    local root=item('Part','HumanoidRootPart');root.Parent=clone
    local torso=item('Part','Torso');torso.Parent=clone
    local hum=item('Humanoid','Humanoid');hum.Health=17;hum.WalkSpeed=8
    local scriptCopy=item('LocalScript','Animate');local tool=item('Tool','Gun')
    local carried=item('Model','WorldGun')
    local joint=item('Motor6D','Root');local standing=cf();joint.attrs.ZO_StandingC0=standing;joint.C0=cf(0,-.5,0)
    local children={root,torso,hum,scriptCopy,tool,carried,joint}
    function clone:GetDescendants()local out={};for _,i in children do if not i.destroyed then table.insert(out,i)end end;return out end
    clone.GetChildren=clone.GetDescendants
    function clone:FindFirstChild(n)for _,i in children do if i.Name==n and not i.destroyed then return i end end end
    function clone:FindFirstChildOfClass(c)for _,i in children do if i.ClassName==c and not i.destroyed then return i end end end
    function clone:SetAttribute(n,v)self.attrs[n]=v end
    function clone:PivotTo(at)self.pivot=at end
    local template={Archivable=false}
    function template:Clone()assert(self.Archivable,'clone requires temporary permission');return clone end
    local identity=cf();local zero=vec()
    local fn=assert(loadstring(RIG_SOURCE))
    setfenv(fn,setmetatable({Color3={fromRGB=function()return 'tint'end},Vector3={zero=zero},CFrame={identity=identity},
        typeof=function(v)return if getmetatable(v)==cm then 'CFrame' else type(v)end},{__index=getfenv()}))
    local Rig=fn();local at=cf(1,2,3);local model=Rig.new(template,at,130,8)
    check(template.Archivable==false,'rig factory restores the original player archive flag')
    check(model==clone and hum.Health==130 and hum.WalkSpeed==8,'factory prepares an independent healthy enemy')
    check(scriptCopy.destroyed and tool.destroyed and carried.destroyed,'cloned scripts and carried weapons are removed')
    check(root.Color==nil and torso.Color=='tint','body is tinted without exposing the root')
    check(joint.C0==standing and joint.Transform==identity,'clone does not inherit crouch/weapon animation pose')
    check(root.AssemblyLinearVelocity==zero and root.AssemblyAngularVelocity==zero,'enemy does not inherit player launch velocity')
    check(clone.pivot==at and clone.PrimaryPart==root,'complete rig is placed at its authored spawn')
    check(clone.attrs.ZO_PracticeRole=='Zombies' and clone.attrs.ZO_TrainingEnemy==true,'server combat tags are assigned')
    function template:Clone()error('clone failure')end
    local ok=pcall(function()Rig.new(template,at,130,8)end)
    check(not ok and template.Archivable==false,'failed cloning also restores the original archive flag')
end
do
    local s=simulation()
    local props=s.object('Folder','ZO_Barricades',s.world)
    local prop=s.object('Model','Crate',props);local hull=s.object('Part','Hull',prop)
    function s.world:Raycast()return {Instance=hull}end
    s.advance(6)
    check(#s.barricadeCalls>0,'agent forwards an obstructing barricade to the private damage authority')
    s.advance(1)
    local previous={}
    for _,call in s.barricadeCalls do
        if previous[call[1]] then check(call[3]-previous[call[1]]>=Config.AttackCooldown,'agent barricade attacks respect the attack interval') end
        previous[call[1]]=call[3]
    end
    s.list[2]={};s.advance(.4);local after=#s.barricadeCalls;s.advance(2)
    check(#s.barricadeCalls==after,'handoff stops all bot barricade attacks')
end
print('PASS actual training director/rig: '..checks..' checks; rig/path API doubles, no engine simulation')
