--!strict
-- Server-owned assemblies. One malformed prop must not stop round startup.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local RunService=game:GetService("RunService")
local shared=RS:WaitForChild("K17Barricades")
local Config=require(shared:WaitForChild("Config"))
local Rules=require(shared:WaitForChild("Rules"))
local Physics=require(shared:WaitForChild("Physics"))
local Placement=require(shared:WaitForChild("Placement"))
local folder=workspace:WaitForChild("ZO_Barricades")
local internal=SS:WaitForChild("ZO_Gameplay")
type Entry={model: Model,hull: BasePart,kind: any,health: number,template: Model,
    brake: LinearVelocity,supportParams: RaycastParams,probeFrame: CFrame?,probed: boolean}
local entries: {[Model]: Entry}={}
local attacks: {[Player]: number}={}
local templates: {[string]: Model}={}
local failures: {[string]: string}={}
local playerCount=#Players:GetPlayers()
local expected=0
for _ in Config.Props do expected+=1 end
RS:SetAttribute("ZO_BarricadesReady",false)
RS:SetAttribute("ZO_BarricadesAvailable",false)
RS:SetAttribute("ZO_BarricadesStatus","Starting")
RS:SetAttribute("ZO_BarricadesExpected",expected)
RS:SetAttribute("ZO_BarricadesMaintenanceHz",if playerCount==0 then 1 else 10)

local function publishStatus()
    local active,errors=0,0
    for _ in entries do active+=1 end
    for _ in failures do errors+=1 end
    RS:SetAttribute("ZO_BarricadesActive",active)
    RS:SetAttribute("ZO_BarricadesErrors",errors)
    RS:SetAttribute("ZO_BarricadesReady",active==expected and errors==0)
    RS:SetAttribute("ZO_BarricadesAvailable",active>0)
    RS:SetAttribute("ZO_BarricadesStatus",if active==expected and errors==0 then "Ready" else "Degraded")
end
local function quarantine(model: Model?,name: string,message: string)
    failures[name]=message
    RS:SetAttribute("ZO_BarricadesLastError",name..": "..string.sub(message,1,400))
    if model then
        entries[model]=nil
        model:SetAttribute("ZO_ActivationError",string.sub(message,1,400))
        -- Leave a failed assembly anchored so it cannot fall or become client-owned.
        for _,part in model:GetDescendants() do
            if part:IsA("BasePart") then part.Anchored=true end
        end
    end
    warn("[K17 BARRICADES] Failed "..name..": "..message)
end

local function phase(): string?
    return Rules.phase(RS:GetAttribute("ZO_RoundState"),RunService:IsStudio(),workspace:GetAttribute("ZO_BarricadePractice")==true,playerCount)
end
local function character(player: Player): (Model?,BasePart?,Humanoid?)
    local char=player.Character
    local head=char and char:FindFirstChild("Head")
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not char or not head or not head:IsA("BasePart") or not hum or hum.Health<=0 then return nil,nil,nil end
    return char,head,hum
end
local function role(player: Player): string?
    return player.Team and player.Team.Name
end
local function resistance(hull: BasePart,model: Model,kind: any): (LinearVelocity,RaycastParams)
    -- A finite horizontal brake separates walking contact from a validated shot.
    -- It never anchors a live prop, drives it toward a position, or holds it up.
    local attachment=Instance.new("Attachment")
    attachment.Name="ZO_ResistanceAttachment";attachment.Parent=hull
    local brake=Instance.new("LinearVelocity")
    brake.Name="ZO_BodyResistance";brake.Attachment0=attachment
    brake.RelativeTo=Enum.ActuatorRelativeTo.World
    brake.VelocityConstraintMode=Enum.VelocityConstraintMode.Plane
    brake.PrimaryTangentAxis=Vector3.new(1,0,0);brake.SecondaryTangentAxis=Vector3.new(0,0,1)
    brake.PlaneVelocity=Vector2.zero
    brake.ForceLimitsEnabled=true;brake.ForceLimitMode=Enum.ForceLimitMode.PerAxis
    local force=kind.Mass*Config.Physics.BodyResistance
    brake.MaxPlanarAxesForce=Vector2.new(force,force)
    brake.Enabled=false;brake.Parent=hull
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={model}
    params.RespectCanCollide=true
    return brake,params
end
local function activate(model: Model,kind: any,template: Model): Entry
    local hull=model:FindFirstChild("Hull") :: BasePart
    model.PrimaryPart=hull;model.ModelStreamingMode=Enum.ModelStreamingMode.Atomic
    model:SetAttribute("ZO_Health",kind.Health);model:SetAttribute("ZO_MaxHealth",kind.Health)
    model:SetAttribute("ZO_Destroyed",false);model:SetAttribute("ZO_Label",kind.Label)
    hull.CustomPhysicalProperties=PhysicalProperties.new(kind.Mass/(hull.Size.X*hull.Size.Y*hull.Size.Z),Config.Physics.Friction,0,100,100)
    hull.RootPriority=127
    for _,part in model:GetDescendants() do
        if part:IsA("BasePart") and part~=hull then
            part.CanCollide=false;part.CanQuery=false;part.CanTouch=false;part.Massless=true
            local weld=Instance.new("WeldConstraint");weld.Part0=hull;weld.Part1=part;weld.Parent=hull
            part.Anchored=false
        end
    end
    local brake,supportParams=resistance(hull,model,kind)
    hull.Anchored=false
    local canOwn,reason=hull:CanSetNetworkOwnership()
    assert(canOwn,"Cannot set server ownership: "..tostring(reason))
    hull:SetNetworkOwner(nil)
    local entry={model=model,hull=hull,kind=kind,health=kind.Health,template=template,
        brake=brake,supportParams=supportParams,probeFrame=nil,probed=false}
    entries[model]=entry
    return entry
end
local function entryFor(part: any): Entry?
    if typeof(part)~="Instance" or not part:IsA("BasePart") or not part:IsDescendantOf(folder) then return nil end
    local model=part:FindFirstAncestorOfClass("Model")
    local entry=if model then entries[model] else nil
    return if entry and entry.health>0 then entry else nil
end
local function push(entry: Entry,direction: Vector3,force: number)
    local hull=entry.hull
    if hull.Anchored then return end
    local velocity=hull.AssemblyLinearVelocity
    local x,z=Physics.impulse(hull.AssemblyMass,velocity.X,velocity.Z,direction.X,direction.Z,force,Config.Physics.MaxSpeed)
    hull:ApplyImpulse(Vector3.new(x,0,z))
end
-- Only Combat can invoke this, after consuming ammo and tracing the first hit.
local bullet=internal:WaitForChild("PushBarricade") :: BindableFunction
bullet.OnInvoke=function(player: Player,part: BasePart,direction: Vector3): boolean
    local entry=entryFor(part)
    local _,head,hum=character(player)
    if not entry or not head or not Rules.canBuild(role(player),phase(),hum~=nil) then return false end
    if typeof(direction)~="Vector3" or not Rules.finite(direction.X) or not Rules.finite(direction.Y) or not Rules.finite(direction.Z) then return false end
    push(entry,direction,Config.Physics.BulletImpulse)
    return true
end
local damage=internal:WaitForChild("DamageBarricade") :: BindableFunction
damage.OnInvoke=function(player: Player,part: BasePart): number?
    local entry=entryFor(part)
    local char,head,hum=character(player)
    if not entry or not char or not head or not Rules.canAttack(role(player),phase(),hum~=nil) then return nil end
    local now=os.clock()
    if now-(attacks[player] or -math.huge)<Config.MeleeCooldown then return nil end
    local delta=Placement.closest(entry.hull,head.Position)-head.Position
    if delta.Magnitude>Config.MeleeRange then return nil end
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={char}
    local hit=if delta.Magnitude>.05 then workspace:Raycast(head.Position,delta.Unit*(delta.Magnitude+.15),params) else nil
    if delta.Magnitude>.05 and (not hit or not hit.Instance:IsDescendantOf(entry.model)) then return nil end
    attacks[player]=now
    push(entry,entry.hull.Position-head.Position,Config.Physics.MeleeImpulse)
    entry.health=math.max(0,entry.health-Config.MeleeDamage);entry.model:SetAttribute("ZO_Health",entry.health)
    if entry.health==0 then
        entry.brake.Enabled=false
        entry.hull.AssemblyLinearVelocity=Vector3.zero;entry.hull.AssemblyAngularVelocity=Vector3.zero;entry.hull.Anchored=true
        for _,part in entry.model:GetDescendants() do
            if part:IsA("BasePart") then part.CanCollide=false;part.CanQuery=false;part.Transparency=1 end
        end
        entry.model:SetAttribute("ZO_Destroyed",true)
    end
    return entry.health
end
-- Install both private callbacks before touching any physical props. Combat may
-- invoke them during startup; an unknown or failed prop simply has no entry.
local function loadProp(name: string,prop: any,reset: boolean)
    local model: Model?=nil
    local ok,message=pcall(function()
        local template=templates[name]
        if reset and template then
            local previous=folder:FindFirstChild(name)
            if previous then entries[previous :: Model]=nil;previous:Destroy() end
            model=template:Clone();(model :: Model).Parent=folder
        else
            local found=folder:FindFirstChild(name)
            assert(found and found:IsA("Model"),"Missing authored Model")
            model=found :: Model
        end
        local current=model :: Model
        local hull=current:FindFirstChild("Hull")
        assert(hull and hull:IsA("BasePart"),"Missing solid Hull")
        local kind=Config.Kinds[prop.Kind]
        assert(kind,"Unknown prop kind "..tostring(prop.Kind))
        assert((hull.Size-Vector3.new(kind.Width,kind.Height,kind.Depth)).Magnitude<.01,"Hull/catalog mismatch")
        assert((hull.Position-Vector3.new(prop.X,prop.Y+kind.Height/2,prop.Z)).Magnitude<.01,"Home/catalog mismatch")
        current:SetAttribute("ZO_Kind",prop.Kind);current:SetAttribute("ZO_Refuge",prop.Refuge)
        if not template then template=current:Clone();templates[name]=template end
        activate(current,kind,template)
        failures[name]=nil
    end)
    if not ok then quarantine(model,name,tostring(message)) end
end
local function resetEntry(entry: Entry)
    -- A removed model is no longer discoverable in folder; drop its old entry
    -- explicitly so recovery cannot retain a second, orphaned assembly record.
    entries[entry.model]=nil
    loadProp(entry.model.Name,Config.Props[entry.model.Name],true)
end
RS:GetAttributeChangedSignal("ZO_RoundState"):Connect(function()
    if RS:GetAttribute("ZO_RoundState")=="Preparation" then
        task.defer(function()
            -- Retry previously failed entries too; successful entries restore from
            -- their original anchored template, including full health and home.
            for name,prop in Config.Props do loadProp(name,prop,true) end
            table.clear(attacks)
            publishStatus()
        end)
    end
end)
Players.PlayerAdded:Connect(function()
    playerCount+=1
    RS:SetAttribute("ZO_BarricadesMaintenanceHz",10)
end)
Players.PlayerRemoving:Connect(function(player)
    attacks[player]=nil;playerCount=math.max(0,playerCount-1)
    RS:SetAttribute("ZO_BarricadesMaintenanceHz",if playerCount==0 then 1 else 10)
end)
local elapsed=0
local maxSpeedSquared=Config.Physics.MaxSpeed*Config.Physics.MaxSpeed
local maxSpinSquared=Config.Physics.MaxSpin*Config.Physics.MaxSpin
local lost: {Entry}={}
RunService.Heartbeat:Connect(function(dt)
    -- Supported props resist body pressure in the solver, including between
    -- these safety passes. Shots never disable that brake. Falling props remain
    -- free vertically and regain ordinary horizontal physics without support.
    elapsed+=dt
    if elapsed<(if playerCount==0 then 1 else .1) then return end
    elapsed=0;table.clear(lost)
    for _,entry in entries do
        local hull=entry.hull
        if not hull.Parent or entry.model.Parent~=folder then table.insert(lost,entry);continue end
        if hull.Anchored then continue end
        local p=hull.Position
        if p.Y < -60 or math.abs(p.X)>310 or math.abs(p.Z)>310 then table.insert(lost,entry);continue end
        local velocity=hull.AssemblyLinearVelocity
        local cf=hull.CFrame
        if not entry.probed or entry.probeFrame~=cf or velocity.X~=0 or velocity.Y~=0 or velocity.Z~=0 then
            -- World-space lower extent also works after a cabinet tips over.
            -- Excluding only this model lets another prop support a stack.
            local size=hull.Size
            local halfHeight=(math.abs(cf.RightVector.Y)*size.X+math.abs(cf.UpVector.Y)*size.Y+math.abs(cf.LookVector.Y)*size.Z)/2
            local hit=workspace:Raycast(p,Vector3.new(0,-halfHeight-Config.Physics.SupportProbe,0),entry.supportParams)
            entry.brake.Enabled=hit~=nil and hit.Normal.Y>.5
            entry.probeFrame=cf;entry.probed=true
        end
        local horizontalSquared=velocity.X*velocity.X+velocity.Z*velocity.Z
        if horizontalSquared>maxSpeedSquared or velocity.Y>8 then
            local scale=if horizontalSquared>maxSpeedSquared then Config.Physics.MaxSpeed/math.sqrt(horizontalSquared) else 1
            hull.AssemblyLinearVelocity=Vector3.new(velocity.X*scale,math.min(velocity.Y,8),velocity.Z*scale)
        end
        local spin=hull.AssemblyAngularVelocity
        local spinSquared=spin.X*spin.X+spin.Y*spin.Y+spin.Z*spin.Z
        if spinSquared>maxSpinSquared then hull.AssemblyAngularVelocity=spin*(Config.Physics.MaxSpin/math.sqrt(spinSquared)) end
    end
    for _,entry in lost do resetEntry(entry) end
    if #lost>0 then publishStatus() end
end)
for name,prop in Config.Props do loadProp(name,prop,false) end
publishStatus()
print(string.format("[K17 BARRICADES] %d/%d physical props active; status=%s",RS:GetAttribute("ZO_BarricadesActive"),expected,RS:GetAttribute("ZO_BarricadesStatus")))
