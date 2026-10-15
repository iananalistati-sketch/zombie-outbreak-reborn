--!strict
-- Engine checks and a direct tour. Never enables a bypass on a published server.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Teams=game:GetService("Teams")
local Data=require(script.Parent:WaitForChild("RefugeData"))
local Audit={}
local function studio()
    assert(RunService:IsStudio() and RunService:IsRunning() and RunService:IsServer(),"Use Studio Play, SERVER Command Bar")
end
local function vector(p): Vector3
    return Vector3.new(p[1],p[2],p[3])
end
function Audit.visit(id: number)
    studio()
    assert(#Players:GetPlayers()==1 and RS:GetAttribute("ZO_RoundState")=="Waiting","Solo tour: one player, Waiting state")
    local data=Data[id];assert(data,"Use 2 (archive), 7 (stockroom), 10 (dispatch), 14 (container), 15 (pumps)")
    local player=Players:GetPlayers()[1]
    local char=player.Character;local hum=char and char:FindFirstChildOfClass("Humanoid")
    assert(char and hum and hum.Health>0,"Wait for a living character")
    local team=Teams:FindFirstChild("Humans");assert(team and team:IsA("Team"))
    local old=workspace:FindFirstChild("ZO_PracticeTargets");if old then old:Destroy() end
    workspace:SetAttribute("ZO_BarricadePractice",true)
    player.Team=team;player.Neutral=false;player:SetAttribute("ZO_Role","Humans")
    local round=require(RS.Shared.RoundConfig)
    hum.MaxHealth=round.HumanHealth;hum.Health=hum.MaxHealth;hum.WalkSpeed=round.HumanWalkSpeed
    workspace:SetAttribute("ZO_PracticeRevision",(workspace:GetAttribute("ZO_PracticeRevision") or 0)+1)
    local origin,look=vector(data.View),vector(data.Look)
    char:PivotTo(CFrame.lookAt(origin,Vector3.new(look.X,origin.Y,look.Z)))
    local effects=RS:FindFirstChild("ZO_CombatFX");local head=char:FindFirstChild("Head")
    if effects and effects:IsA("RemoteEvent") and head and head:IsA("BasePart") then effects:FireClient(player,"PracticeAim",head.Position,look) end
    print(("[REFUGE TOUR] %02d / %s — inspect both approaches, push props by contact or rifle shots. R reloads. Stop Play resets the scene."):format(id,data.Label))
end
function Audit.run()
    studio()
    local map=workspace:WaitForChild("ZO_K17Foundry");local props=workspace:WaitForChild("ZO_Barricades")
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={map,props}
    local overlap=OverlapParams.new();overlap.FilterType=Enum.RaycastFilterType.Include;overlap.FilterDescendantsInstances={map,props};overlap.RespectCanCollide=true
    local passed,failed=0,0
    local function record(ok: boolean,label: string)
        if ok then passed+=1;print("[REFUGE AUDIT] PASS "..label) else failed+=1;warn("[REFUGE AUDIT] FAIL "..label) end
    end
    for id,data in Data do
        record(map:FindFirstChild(data.Model)~=nil,tostring(id).." authored interior")
        for i,p in data.Stands do
            local foot=vector(p)
            local hit=workspace:Raycast(foot+Vector3.new(0,1,0),Vector3.new(0,-2.2,0),params)
            local occupied=workspace:GetPartBoundsInBox(CFrame.new(foot+Vector3.new(0,2.8,0)),Vector3.new(2.8,5.2,2.8),overlap)
            record(hit~=nil and #occupied==0,("%02d group position %d"):format(id,i))
        end
        for i,line in data.Sights do
            local a,b=vector(line[1])+Vector3.new(0,5.5,0),vector(line[2])+Vector3.new(0,5.5,0)
            record(workspace:Raycast(a,b-a,params)==nil,("%02d firing line %d"):format(id,i))
        end
    end
    print(("[REFUGE AUDIT] COMPLETE: %d passed, %d failed. Run before moving props; walk routes and test physics separately."):format(passed,failed))
    return {passed=passed,failed=failed}
end
return Audit
