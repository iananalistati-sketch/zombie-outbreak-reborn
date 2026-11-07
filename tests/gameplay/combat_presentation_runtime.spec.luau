-- Actual ViewRig + WeaponPresentation with Instance/transform doubles.
-- These checks do not load animations, render avatars or play sound in Studio.
local checks=0
local function check(v,label)assert(v,label);checks+=1 end
local vm={}
local function vec(x,y,z)return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vm)end
vm.__add=function(a,b)return vec(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
vm.__sub=function(a,b)return vec(a.X-b.X,a.Y-b.Y,a.Z-b.Z)end
vm.__unm=function(a)return vec(-a.X,-a.Y,-a.Z)end
vm.__mul=function(a,b)if type(a)=='number'then a,b=b,a end;return vec(a.X*b,a.Y*b,a.Z*b)end
vm.__div=function(a,b)return a*(1/b)end
vm.__index=function(v,k)
    if k=='Magnitude'then return math.sqrt(v.X^2+v.Y^2+v.Z^2)end
    if k=='Unit'then return v/v.Magnitude end
    if k=='Cross'then return function(a,b)return vec(a.Y*b.Z-a.Z*b.Y,a.Z*b.X-a.X*b.Z,a.X*b.Y-a.Y*b.X)end end
end
local V={new=vec,zero=vec(),one=vec(1,1,1),xAxis=vec(1,0,0),yAxis=vec(0,1,0)}
local cm={}
local identity={1,0,0,0,1,0,0,0,1}
local function cf(p,r)return setmetatable({Position=p or vec(),r=r or table.clone(identity)},cm)end
local function rotate(r,p)return vec(r[1]*p.X+r[2]*p.Y+r[3]*p.Z,r[4]*p.X+r[5]*p.Y+r[6]*p.Z,r[7]*p.X+r[8]*p.Y+r[9]*p.Z)end
cm.__mul=function(a,b)
    local r={}
    for i=0,2 do for j=1,3 do local n=0;for k=1,3 do n+=a.r[i*3+k]*b.r[(k-1)*3+j]end;r[i*3+j]=n end end
    return cf(a.Position+rotate(a.r,b.Position),r)
end
cm.__index=function(c,k)
    if k=='Rotation'then return cf(vec(),c.r)end
    if k=='LookVector'then return vec(-c.r[3],-c.r[6],-c.r[9])end
    if k=='Inverse'then return function(a)local r={a.r[1],a.r[4],a.r[7],a.r[2],a.r[5],a.r[8],a.r[3],a.r[6],a.r[9]};return cf(rotate(r,-a.Position),r)end end
    if k=='ToObjectSpace'then return function(a,b)return a:Inverse()*b end end
    if k=='Lerp'then return function(a,b,t)return cf(a.Position*(1-t)+b.Position*t,if t==1 then b.r else a.r)end end
end
local C={identity=cf(),new=function(x,y,z)return cf(if type(x)=='table'then x else vec(x,y,z))end}
function C.Angles(x,y,z)
    local cx,sx,cy,sy,cz,sz=math.cos(x),math.sin(x),math.cos(y),math.sin(y),math.cos(z),math.sin(z)
    return cf(vec(),{1,0,0,0,cx,-sx,0,sx,cx})*cf(vec(),{cy,0,sy,0,1,0,-sy,0,cy})*cf(vec(),{cz,-sz,0,sz,cz,0,0,0,1})
end
function C.lookAt(p,target,up)
    local look=(target-p).Unit;local right=look:Cross(up or V.yAxis).Unit;local u=right:Cross(look)
    return cf(p,{right.X,u.X,-look.X,right.Y,u.Y,-look.Y,right.Z,u.Z,-look.Z})
end
local function signal()return{Connect=function()return{Disconnect=function()end}end,Once=function()end}end
local methods={};local im={}
local function object(class,name,parent)
    local data={ClassName=class,Name=name or class,children={},attrs={},Archivable=true,CFrame=C.identity,Size=vec(1,2,1),
        C0=C.identity,C1=C.identity,Transform=C.identity,Grip=C.identity,AncestryChanged=signal(),Destroying=signal()}
    local obj=setmetatable({data=data},im)
    if parent then obj.Parent=parent end;return obj
end
im.__index=function(o,k)
    local d=o.data
    if k=='Position'then return d.CFrame.Position end
    if k=='WorldCFrame'then return o.Parent.CFrame*d.CFrame end
    return methods[k] or d[k]
end
im.__newindex=function(o,k,v)
    local d=o.data
    if k=='Parent'then
        if d.Parent then local i=table.find(d.Parent.data.children,o);if i then table.remove(d.Parent.data.children,i)end end
        d.Parent=v;if v then table.insert(v.data.children,o)end
    else d[k]=v end
end
function methods:IsA(c)return self.ClassName==c or (c=='BasePart'and(self.ClassName=='Part'or self.ClassName=='MeshPart'))
    or(c=='LuaSourceContainer'and(self.ClassName=='Script'or self.ClassName=='LocalScript'))
    or(c=='JointInstance'and(self.ClassName=='Weld'or self.ClassName=='Motor6D'))end
function methods:GetChildren()return table.clone(self.data.children)end
function methods:GetDescendants()local list={};local function add(p)for _,v in p:GetChildren()do table.insert(list,v);add(v)end end;add(self);return list end
function methods:FindFirstChild(n,recursive)for _,v in self:GetChildren()do if v.Name==n then return v end end;if recursive then for _,v in self:GetChildren()do local f=v:FindFirstChild(n,true);if f then return f end end end end
function methods:FindFirstChildOfClass(c)for _,v in self:GetChildren()do if v:IsA(c)then return v end end end
function methods:IsDescendantOf(p)local n=self.Parent;while n do if n==p then return true end;n=n.Parent end;return false end
function methods:GetAttribute(n)return self.data.attrs[n]end
function methods:SetAttribute(n,v)self.data.attrs[n]=v end
function methods:GetAttributeChangedSignal()return signal()end
function methods:GetPropertyChangedSignal()return signal()end
function methods:Destroy()for _,v in self:GetChildren()do v:Destroy()end;self.Parent=nil;self.Destroyed=true end
function methods:Clone()
    if self.FailClone then error('clone failure')end
    local map={}
    local function clone(src)
        local dst=object(src.ClassName,src.Name);map[src]=dst;dst.data.attrs=table.clone(src.data.attrs)
        for _,child in src:GetChildren()do clone(child).Parent=dst end
        return dst
    end
    local result=clone(self)
    for src,dst in map do for k,v in src.data do
        if k~='Parent'and k~='children'and k~='attrs'and k~='Destroying'and k~='AncestryChanged'then dst[k]=map[v]or v end
    end end
    return result
end
function methods:Emit(n)self.Emitted=n end
function methods:Play()self.Played=true end
local world=object('Workspace','Workspace');local rs=object('ReplicatedStorage','ReplicatedStorage')
local kit=object('Folder','ZO_WeaponAssets',rs);local effects=object('Folder','Effects',kit)
local hit=object('Attachment','HitEffect',effects);object('ParticleEmitter','Particles',hit)
local now=0;local debris={}
local settings={HipPose=C.new(.6,-.8,-1.2),EyeRelief=.65,FireVolume=1.4,ReloadVolume=1.1,SoundDistance=160}
local modules={PresentationConfig={get=function()return settings end},WeaponAimPose={}}
local env=setmetatable({workspace=world,CFrame=C,Vector3=V,Instance={new=function(c)return object(c)end},
    Enum={HumanoidRigType={R6='R6',R15='R15'},NormalId={Front='Front'}},
    Color3={fromRGB=function(r,g,b)return{R=r,G=g,B=b}end},Vector2={new=function(x,y)return{X=x,Y=y}end},
    ColorSequence={new=function(v)return{Value=v}end},NumberRange={new=function(a,b)return{Min=a,Max=b}end},NumberSequence={new=function(v)return{Value=v}end},
    os={clock=function()return now end},Random={new=function()return{NextNumber=function()return 0 end}end},
    task={spawn=function()end,wait=function()end},
    game={GetService=function(_,n)if n=='ReplicatedStorage'then return rs elseif n=='Debris'then return {AddItem=function(_,o,t)table.insert(debris,{o,t})end}else return{}end end},
    require=function(token)return assert(modules[token])end,script={Parent={PresentationConfig='PresentationConfig',WeaponAimPose='WeaponAimPose',ViewRig='ViewRig',WeaponHandling='Handling',ImpactProfiles='Impacts'}}},{__index=getfenv()})
local function load(source)local f=assert(loadstring(source));setfenv(f,env);return f()end
modules.Handling=load(HANDLING_SOURCE);modules.Impacts=load(IMPACTS_SOURCE);modules.ViewRig=load(RIG_SOURCE)
local Rig=modules.ViewRig;local Presenter=load(PRESENTER_SOURCE)
local function character(r6)
    local rig=object('Model','Character',world);rig.Archivable=false
    local h=object('Humanoid','Humanoid',rig);h.RigType=if r6 then 'R6'else'R15'
    local root=object('Part','HumanoidRootPart',rig);root.CFrame=C.new(0,3,0)
    local torso=object('Part','Torso',rig);torso.CFrame=root.CFrame
    local head=object('Part','Head',rig);head.CFrame=C.new(0,4.5,0)
    local arm=object('Part',if r6 then 'Right Arm'else'RightHand',rig);arm.CFrame=C.new(1.5,3,0)
    local left=object('Part',if r6 then 'Left Arm'else'LeftHand',rig);left.CFrame=C.new(-1.5,3,0)
    for _,entry in {{root,torso,'RootJoint',C.identity},{torso,head,'Neck',C.new(0,1.5,0)},
        {torso,arm,if r6 then'Right Shoulder'else'RightShoulder',C.new(1.5,0,0)},{torso,left,if r6 then'Left Shoulder'else'LeftShoulder',C.new(-1.5,0,0)}} do
        local j=object('Motor6D',entry[3],entry[1]);j.Part0=entry[1];j.Part1=entry[2];j.C0=entry[4]
    end
    local grip=object('Weld','RightGrip',arm);grip.Part0=arm;grip.C0=C.new(0,-1,0)*C.Angles(-math.pi/2,0,0)
    object('Script','Animate',rig)
    local oldGun=object('Tool','OldGun',rig)
    local oldHandle=object('Part','Handle',oldGun);object('Decal','OldGunDecal',oldHandle)
    object('Decal','face',head);object('BillboardGui','Nameplate',head)
    object('Decal','ArmPaint',arm)
    return rig,grip
end
local r6,native=character(true);local original=r6:FindFirstChild('HumanoidRootPart').CFrame
local arms,status=Rig.copy(r6,world,false)
check(status=='Ready'and arms.rigType=='R6'and arms.animator==nil,'real R6 limbs use procedural pose without R15 animations')
check(r6.Archivable==false and not r6.Destroyed,'cloning restores original avatar archivable flag')
check(arms.hand.Name=='Right Arm'and arms.gripOffset==native.C0,'native R6 grip data is retained')
check(arms.hand:FindFirstChild('RightGrip')==nil,'orphan world grip is removed before first-person grip is built')
check(not arms.model:FindFirstChild('Animate')and not arms.model:FindFirstChild('OldGun'),'view rig never activates avatar scripts or tools')
check(not arms.model:FindFirstChild('face',true)and not arms.model:FindFirstChild('Nameplate',true)
    and arms.hand:FindFirstChild('ArmPaint')~=nil,'hidden body cosmetics are removed while arm paint survives; destroyed tool descendants are safe')
for _,p in arms.parts do check(p.Anchored and not p.CanQuery and not p.CanCollide,'view rig is query/physics free')end
local r15=character(false);local a15=Rig.copy(r15,world,true)
check(a15.animator~=nil and a15.rigType=='R15','R15 retains its existing animation controller')
r6.FailClone=true;local fail=Rig.copy(r6,world,false);check(fail==nil and r6.Archivable==false,'failed clone also restores avatar flag');r6.FailClone=false
local function weapon(id)
    local t=object('Tool',id);local handle=object('Part','Handle',t)
    local model=object('Model','Model',t);local body=object('MeshPart',id,model);model.PrimaryPart=body
    object('Attachment','HandleAttachment',body)
    local mag=object('MeshPart',if id=='Shotgun'then'Pump'else'Magazine',model);mag.CFrame=C.new(0,-.1,0)
    return t
end
local template=weapon('Rifle');local gun=assert(Presenter.new(template,world,'Rifle',r6))
gun:update(C.identity,C.identity,true,0);local mag=gun.instance:FindFirstChild('Magazine',true);local baseline=mag.CFrame.Position
gun:setReloading(true,2.4,2.4);now=1.08;gun:update(C.identity,C.identity,true,0)
check(mag.LocalTransparencyModifier==1 and (mag.CFrame.Position-baseline).Magnitude>.5,'actual imported magazine moves and hides during reload')
gun:setReloading(false);gun:update(C.identity,C.identity,true,0)
check(mag.LocalTransparencyModifier==0 and (mag.CFrame.Position-baseline).Magnitude<1e-5,'cancelling reload restores actual magazine mesh')
local claws,clawStatus=Presenter.newArms(r6,world);Presenter.updateArms(claws,C.identity,true,.5)
check(clawStatus=='Ready'and claws.arms.hand.LocalTransparencyModifier==0,'R6 infection also displays the real cloned limbs')
Presenter.destroyArms(claws)
local sg=assert(Presenter.new(weapon('Shotgun'),world,'Shotgun',r6));sg:update(C.identity,C.identity,true,0)
local pump=sg.instance:FindFirstChild('Pump',true);local rest=pump.CFrame.Position
sg:fire();now+=.16;sg:update(C.identity,C.identity,true,0);check((pump.CFrame.Position-rest).Magnitude>.2,'shotgun cycles its real pump mesh')
now+=1;sg:update(C.identity,C.identity,true,0);check((pump.CFrame.Position-rest).Magnitude<1e-5,'pump returns without persistent offset')
local count=#debris;Presenter.impact(vec(),V.yAxis,'Metal')
check(#debris==count+1,'actual impact function creates reviewed kit effect')
local fx=debris[#debris][1];local emitter=fx:FindFirstChild('Particles',true)
check(emitter.Emitted==6 and emitter.LightEmission>.6 and emitter.Color.Value.R==249,'metal profile configures actual emitter')
check(not fx.CanQuery and not fx.CanCollide and debris[#debris][2]<1,'impact cleanup is short and cannot obstruct shots')
for i=1,100 do Presenter.impact(vec(),V.yAxis,'WoodPlanks')end
check(#debris-count==24,'burst budget bounds actual effect allocation')
gun:destroy();sg:destroy()
check(not template.Destroyed and r6.Parent==world,'presentation cleanup never destroys source assets/avatar')
check(r6:FindFirstChild('HumanoidRootPart').CFrame==original,'viewmodel transforms never move the actual character')
print(('PASS actual view rig / reload / impact adapter: %d checks; transform/Instance doubles, no rendering'):format(checks))
