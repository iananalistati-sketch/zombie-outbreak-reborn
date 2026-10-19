--!strict
-- Engine checks and explicit solo practice. These commands only work in Studio Play.
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Teams=game:GetService("Teams")
local Config=require(RS:WaitForChild("K17Barricades"):WaitForChild("Config"))
local Placement=require(RS:WaitForChild("K17Barricades"):WaitForChild("Placement"))
local Audit={}
local sampling=false
local function studio()
    assert(RunService:IsStudio() and RunService:IsRunning() and RunService:IsServer(),"Use Play in Studio, SERVER Command Bar")
end
local function supported(model: Model,hull: BasePart): boolean
    local cf,size=hull.CFrame,hull.Size
    local halfHeight=(math.abs(cf.RightVector.Y)*size.X+math.abs(cf.UpVector.Y)*size.Y+math.abs(cf.LookVector.Y)*size.Z)/2
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={model};params.RespectCanCollide=true
    local hit=workspace:Raycast(hull.Position,Vector3.new(0,-halfHeight-Config.Physics.SupportProbe,0),params)
    return hit~=nil and hit.Normal.Y>.5
end

function Audit.run()
    studio()
    local folder=workspace:WaitForChild("ZO_Barricades")
    local map=workspace:WaitForChild("ZO_K17Foundry")
    local passed,failed=0,0
    local supportChecks: {{model: Model,hull: BasePart,brake: LinearVelocity,frame: CFrame,supported: boolean}}={}
    local function record(ok: boolean,name: string)
        if ok then passed+=1;print("[BARRICADE AUDIT] PASS "..name)
        else failed+=1;warn("[BARRICADE AUDIT] FAIL "..name) end
    end
    record(RS:GetAttribute("ZO_BarricadesReady")==true,"server ready")
    local expected=0
    for _ in Config.Props do expected+=1 end
    record(#folder:GetChildren()==expected,tostring(expected).." catalog props")
    for name,prop in Config.Props do
        local model=folder:FindFirstChild(name)
        local hull=model and model:FindFirstChild("Hull")
        if model and model:IsA("Model") and hull and hull:IsA("BasePart") then
            local kind=Config.Kinds[prop.Kind]
            record((hull.Size-Vector3.new(kind.Width,kind.Height,kind.Depth)).Magnitude<.01,name.." catalog dimensions")
            local ok=Placement.clear(model,hull.CFrame,hull.Size,map)
            record(ok and model:GetAttribute("ZO_Destroyed")==false,name.." supported, unoccupied placement")
            record(model.PrimaryPart==hull and not hull.Anchored and hull.CanCollide and hull.CanQuery,name.." dynamic, solid primary hull")
            record(hull:GetNetworkOwner()==nil,name.." server network ownership")
            record(math.abs(hull.AssemblyMass-kind.Mass)<.1,name.." configured assembly mass")
            local connected=hull:GetConnectedParts(true)
            local visuals=0
            for _,part in model:GetDescendants() do if part:IsA("BasePart") and part~=hull then visuals+=1 end end
            record(#connected==visuals,name.." all visuals welded to hull")
            local attachment=hull:FindFirstChild("ZO_ResistanceAttachment")
            local brake=hull:FindFirstChild("ZO_BodyResistance")
            local attachments,brakes=0,0
            for _,child in hull:GetChildren() do
                if child.Name=="ZO_ResistanceAttachment" and child:IsA("Attachment") then attachments+=1 end
                if child.Name=="ZO_BodyResistance" and child:IsA("LinearVelocity") then brakes+=1 end
            end
            record(attachments==1 and attachment~=nil and attachment:IsA("Attachment"),name.." one resistance attachment")
            record(brakes==1 and brake~=nil and brake:IsA("LinearVelocity"),name.." one horizontal body brake")
            if attachment and attachment:IsA("Attachment") and brake and brake:IsA("LinearVelocity") then
                record(brake.Attachment0==attachment and brake.RelativeTo==Enum.ActuatorRelativeTo.World
                    and brake.VelocityConstraintMode==Enum.VelocityConstraintMode.Plane,name.." attached world-space plane brake")
                record((brake.PrimaryTangentAxis-Vector3.new(1,0,0)).Magnitude<.001
                    and (brake.SecondaryTangentAxis-Vector3.new(0,0,1)).Magnitude<.001
                    and brake.PlaneVelocity.Magnitude<.001,name.." zero target velocity on XZ only")
                record(brake.ForceLimitsEnabled and brake.ForceLimitMode==Enum.ForceLimitMode.PerAxis,name.." finite per-axis force limits")
                local force=kind.Mass*Config.Physics.BodyResistance
                record((brake.MaxPlanarAxesForce-Vector2.new(force,force)).Magnitude<.01,name.." catalog mass × body resistance force")
                table.insert(supportChecks,{model=model,hull=hull,brake=brake,frame=hull.CFrame,supported=supported(model,hull)})
            end
        else record(false,name.." missing model/hull") end
    end
    -- The controller probes support at 10 Hz with players, 1 Hz without players.
    -- Check only after a complete maintenance interval and unchanged support/pose.
    task.wait(if #Players:GetPlayers()>0 then .2 else 1.1)
    for _,check in supportChecks do
        local model,hull,brake=check.model,check.hull,check.brake
        if model.Parent==folder and hull.Parent and brake.Parent==hull and hull.CFrame==check.frame
            and check.supported and supported(model,hull) and model:GetAttribute("ZO_Destroyed")~=true then
            record(brake.Enabled,model.Name.." brake enabled on stable support after maintenance")
        else
            print("[BARRICADE AUDIT] INFO "..model.Name.." support changed or airborne; Enabled check skipped")
        end
    end
    local model=folder:FindFirstChild("Cabinet01") :: Model
    local hull=model and model:FindFirstChild("Hull") :: BasePart
    if hull then
        local clear=Placement.clear(model,CFrame.new(-225,4.15,112),hull.Size,map)
        record(not clear,"room wall rejects cabinet placement")
        local unsupported=Placement.clear(model,CFrame.new(-247,10.15,123),hull.Size,map)
        record(not unsupported,"unsupported height rejected")
    end
    print(("[BARRICADE AUDIT] COMPLETE: %d passed, %d failed. Run before moving props; stand away from their bounds."):format(passed,failed))
    return {passed=passed,failed=failed}
end

local function nearbyRig(position: Vector3): string
    local closest: Player?=nil
    local distance=math.huge
    for _,player in Players:GetPlayers() do
        local char=player.Character
        local root=char and char:FindFirstChild("HumanoidRootPart")
        if root and root:IsA("BasePart") then
            local delta=(root.Position-position).Magnitude
            if delta<distance then closest=player;distance=delta end
        end
    end
    local hum=closest and closest.Character and closest.Character:FindFirstChildOfClass("Humanoid")
    if closest and hum then return ("%s:%s (%.1f studs)"):format(closest.Name,hum.RigType.Name,distance) end
    return "nenhum personagem próximo"
end

function Audit.sample(name: string,seconds: number?)
    studio()
    assert(not sampling,"Another barricade sample is already running; wait for its result")
    assert(type(name)=="string" and Config.Props[name],"Use an exact Config.Props name, for example Cabinet01")
    local duration=seconds or 5
    assert(type(duration)=="number" and duration==duration and math.abs(duration)<math.huge,"Seconds must be finite")
    duration=math.clamp(duration,1,10)
    local folder=workspace:FindFirstChild("ZO_Barricades")
    local model=folder and folder:FindFirstChild(name)
    local hull=model and model:FindFirstChild("Hull")
    assert(folder and model and model:IsA("Model") and hull and hull:IsA("BasePart"),"Missing model/Hull: "..name)
    assert(model:GetAttribute("ZO_Destroyed")~=true,"Choose a live barricade prop")
    local prop=model :: Model
    local body=hull :: BasePart
    local container=folder :: Instance
    local function present(): boolean
        return container:IsDescendantOf(workspace) and prop.Parent==container and body.Parent~=nil and body:IsDescendantOf(prop)
    end
    sampling=true
    task.spawn(function()
        local ok,message=xpcall(function()
            print(("[BARRICADE SAMPLE] %s — janela %.1fs; início em 2s. Volte ao jogo e teste UMA ação: contato, tiros ou golpes. O auditor só observa."):format(name,duration))
            for remaining=2,1,-1 do
                if not present() or prop:GetAttribute("ZO_Destroyed")==true then
                    print("[BARRICADE SAMPLE] CANCELADO "..name..": objeto removido/destruído antes da medição")
                    return
                end
                print(("[BARRICADE SAMPLE] %s — começa em %ds"):format(name,remaining))
                task.wait(1)
            end
            if not present() or prop:GetAttribute("ZO_Destroyed")==true then
                print("[BARRICADE SAMPLE] CANCELADO "..name..": objeto removido/destruído antes da medição")
                return
            end
            local initial=body.Position
            local healthInitial=prop:GetAttribute("ZO_Health")
            local healthFinal=healthInitial
            local mass=body.AssemblyMass
            local rig=nearbyRig(initial)
            local elapsed,maxDisplacement,peakSpeed,maxY=0,0,0,0
            local final=initial
            local reason="janela concluída"
            local function collect()
                final=body.Position
                local delta=final-initial
                maxDisplacement=math.max(maxDisplacement,Vector2.new(delta.X,delta.Z).Magnitude)
                maxY=math.max(maxY,math.abs(delta.Y))
                local velocity=body.AssemblyLinearVelocity
                peakSpeed=math.max(peakSpeed,Vector2.new(velocity.X,velocity.Z).Magnitude)
                healthFinal=prop:GetAttribute("ZO_Health")
            end
            collect()
            print(("[BARRICADE SAMPLE] INÍCIO %s — %.1fs; massa=%.2f; saúde=%s; rig próximo=%s (não identifica quem aplicou a ação)"):format(name,duration,mass,tostring(healthInitial),rig))
            while elapsed<duration do
                local dt=RunService.Heartbeat:Wait()
                elapsed+=dt
                if not present() then reason="objeto removido/substituído";break end
                collect()
                if prop:GetAttribute("ZO_Destroyed")==true then reason="objeto destruído";break end
            end
            healthFinal=prop:GetAttribute("ZO_Health")
            local delta=final-initial
            local displacement=Vector2.new(delta.X,delta.Z).Magnitude
            print(("[BARRICADE SAMPLE] RESULTADO %s | %.2fs | %s | deslocamentoXZ final=%.3f máximo=%.3f studs | picoVelXZ=%.3f studs/s | deltaY=%+.3f máximoAbsY=%.3f studs | saúde=%s→%s | massa=%.2f | rig próximo inicial=%s"):format(
                name,elapsed,reason,displacement,maxDisplacement,peakSpeed,delta.Y,maxY,tostring(healthInitial),tostring(healthFinal),mass,rig))
            print("[BARRICADE SAMPLE] Medição observacional; não aprova física nem distingue automaticamente contato, tiro ou golpe.")
        end,debug.traceback)
        sampling=false
        if not ok then warn("[BARRICADE SAMPLE] ERRO "..name..": "..tostring(message)) end
    end)
    return {name=name,seconds=duration,startsIn=2}
end

function Audit.practice(teamName: string?)
    studio()
    assert(#Players:GetPlayers()==1 and RS:GetAttribute("ZO_RoundState")=="Waiting","Solo practice only: one player, Waiting state")
    local name=teamName or "Humans"
    assert(name=="Humans" or name=="Zombies","Use Humans or Zombies")
    local player=Players:GetPlayers()[1]
    local team=Teams:FindFirstChild(name)
    local char=player.Character
    assert(team and team:IsA("Team") and char,"Wait for character and teams")
    local hum=char:FindFirstChildOfClass("Humanoid")
    assert(hum and hum.Health>0,"Character must be alive")
    workspace:SetAttribute("ZO_BarricadePractice",true)
    player.Team=team;player.Neutral=false;player:SetAttribute("ZO_Role",name)
    local round=require(RS.Shared.RoundConfig)
    hum.MaxHealth=if name=="Zombies" then round.ZombieHealth else round.HumanHealth
    hum.Health=hum.MaxHealth
    hum.WalkSpeed=if name=="Zombies" then round.ZombieWalkSpeed else round.HumanWalkSpeed
    char:PivotTo(CFrame.new(-247,4,124))
    print("[BARRICADE PRACTICE] "..name.." — solo Studio. Placement preview is disabled in the classic profile. Use GameplayAudit.practice for rifle/melee targets. Stop Play restores props.")
end

return Audit
