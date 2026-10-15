--!strict
-- Studio-only checks and a repeatable solo target. No live-server practice bypass.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local RunService=game:GetService("RunService")
local Teams=game:GetService("Teams")
local Audit={}
local function studio()
    assert(RunService:IsStudio() and RunService:IsRunning() and RunService:IsServer(),"Use Studio Play, SERVER Command Bar")
end
function Audit.run()
    studio()
    local passed,failed=0,0
    local function record(ok: boolean,label: string)
        if ok then passed+=1;print("[GAMEPLAY AUDIT] PASS "..label)
        else failed+=1;warn("[GAMEPLAY AUDIT] FAIL "..label) end
    end
    record(RS:GetAttribute("ZO_GameplayRoundReady")==true,"round authority ready")
    record(RS:GetAttribute("ZO_GameplayCombatReady")==true,"combat authority ready")
    for _,name in {"ZO_Melee","ZO_FireRifle","ZO_CombatFX"} do
        local remote=RS:FindFirstChild(name)
        record(remote~=nil and remote:IsA("RemoteEvent"),name)
    end
    local internal=SS:FindFirstChild("ZO_Gameplay")
    for _,name in {"Infect","DamageBarricade"} do
        local item=internal and internal:FindFirstChild(name)
        record(item~=nil and item:IsA("BindableFunction"),"server-only "..name)
    end
    record(require(RS.Shared.RoundConfig).MotherZombieTeleport==false,"classic in-place first infection")
    record(require(RS.K17Barricades.Config).EnablePlacement==false,"placement preview disabled")
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances={workspace:WaitForChild("ZO_K17Foundry")}
    record(workspace:Raycast(Vector3.new(-228,5,123),Vector3.new(8,0,0),params)==nil,"stockroom doorway ray clear")
    record(workspace:Raycast(Vector3.new(-228,5,112),Vector3.new(8,0,0),params)~=nil,"stockroom wall blocks ray")
    print(("[GAMEPLAY AUDIT] COMPLETE: %d passed, %d failed. Controls, damage, reload and multiplayer require the manual checklist."):format(passed,failed))
    return {passed=passed,failed=failed}
end
local function dummy(parent: Instance,position: Vector3,role: string): Model
    local config=require(RS.Shared.RoundConfig)
    local model=Instance.new("Model");model.Name="Alvo_"..role;model:SetAttribute("ZO_PracticeRole",role)
    local parts: {[string]: Part}={}
    local color=if role=="Zombies" then Color3.fromRGB(112,130,104) else Color3.fromRGB(85,113,138)
    local function limb(name: string,size: Vector3,offset: Vector3,collide: boolean): Part
        local part=Instance.new("Part");part.Name=name;part.Size=size;part.Color=color
        part.Material=Enum.Material.SmoothPlastic;part.CFrame=CFrame.new(position+offset)
        part.CanCollide=collide;part.CanTouch=false;part.Parent=model;parts[name]=part;return part
    end
    local root=limb("HumanoidRootPart",Vector3.new(2,2,1),Vector3.zero,false);root.Transparency=1
    limb("Torso",Vector3.new(2,2,1),Vector3.zero,true)
    limb("Head",Vector3.new(2,1,1),Vector3.new(0,1.5,0),true)
    limb("Left Arm",Vector3.new(1,2,1),Vector3.new(-1.5,0,0),false)
    limb("Right Arm",Vector3.new(1,2,1),Vector3.new(1.5,0,0),false)
    limb("Left Leg",Vector3.new(1,2,1),Vector3.new(-.5,-2,0),false)
    limb("Right Leg",Vector3.new(1,2,1),Vector3.new(.5,-2,0),false)
    local function joint(name: string,a: string,b: string,c0: CFrame,c1: CFrame)
        local motor=Instance.new("Motor6D");motor.Name=name;motor.Part0=parts[a];motor.Part1=parts[b]
        motor.C0=c0;motor.C1=c1;motor.Parent=parts[a]
    end
    joint("RootJoint","HumanoidRootPart","Torso",CFrame.identity,CFrame.identity)
    joint("Neck","Torso","Head",CFrame.new(0,1,0),CFrame.new(0,-.5,0))
    joint("Left Shoulder","Torso","Left Arm",CFrame.new(-1,.5,0),CFrame.new(.5,.5,0))
    joint("Right Shoulder","Torso","Right Arm",CFrame.new(1,.5,0),CFrame.new(-.5,.5,0))
    joint("Left Hip","Torso","Left Leg",CFrame.new(-.5,-1,0),CFrame.new(0,1,0))
    joint("Right Hip","Torso","Right Leg",CFrame.new(.5,-1,0),CFrame.new(0,1,0))
    local hum=Instance.new("Humanoid");hum.DisplayName=if role=="Humans" then "Alvo humano — use o golpe" else "Alvo zumbi — teste tiro/knockback"
    hum.MaxHealth=if role=="Zombies" then config.ZombieHealth else config.HumanHealth
    hum.Health=hum.MaxHealth;hum.WalkSpeed=0;hum.AutoRotate=false;hum.Parent=model
    model.PrimaryPart=root;model.Parent=parent
    root:SetNetworkOwner(nil)
    return model
end
function Audit.practice(teamName: string?)
    studio()
    assert(#Players:GetPlayers()==1 and RS:GetAttribute("ZO_RoundState")=="Waiting","Use one player, Waiting state")
    assert(RS:GetAttribute("ZO_GameplayCombatReady")==true and RS:GetAttribute("ZO_GameplayRoundReady")==true,"Wait for gameplay startup")
    local name=teamName or "Humans"
    assert(name=="Humans" or name=="Zombies","Use Humans or Zombies")
    local player=Players:GetPlayers()[1]
    local char=player.Character
    local hum=char and char:FindFirstChildOfClass("Humanoid")
    assert(char and hum and hum.Health>0,"Wait for a living character")
    local team=Teams:FindFirstChild(name)
    assert(team and team:IsA("Team"))
    local old=workspace:FindFirstChild("ZO_PracticeTargets")
    if old then old:Destroy() end
    local folder=Instance.new("Folder");folder.Name="ZO_PracticeTargets";folder.Parent=workspace
    workspace:SetAttribute("ZO_BarricadePractice",true)
    player.Team=team;player.Neutral=false;player:SetAttribute("ZO_Role",name)
    workspace:SetAttribute("ZO_PracticeRevision",(workspace:GetAttribute("ZO_PracticeRevision") or 0)+1)
    local round=require(RS.Shared.RoundConfig)
    hum.MaxHealth=if name=="Zombies" then round.ZombieHealth else round.HumanHealth;hum.Health=hum.MaxHealth
    hum.WalkSpeed=if name=="Zombies" then round.ZombieWalkSpeed else round.HumanWalkSpeed
    local origin=Vector3.new(-248,4,123)
    local destination=if name=="Humans" then Vector3.new(-238,4,123) else Vector3.new(-242,4,123)
    char:PivotTo(CFrame.lookAt(origin,Vector3.new(destination.X,4,destination.Z)))
    dummy(folder,destination,if name=="Humans" then "Zombies" else "Humans")
    local head=char:FindFirstChild("Head")
    local effects=RS:FindFirstChild("ZO_CombatFX")
    if head and head:IsA("BasePart") and effects and effects:IsA("RemoteEvent") then
        effects:FireClient(player,"PracticeAim",head.Position,destination+Vector3.new(0,1.5,0))
    end
    print("[GAMEPLAY PRACTICE] "..name.." — target ahead. Hold click to fire/attack; R reloads. Solo Studio only; round HUD stays Waiting. Repeat command to reset target.")
end
return Audit
