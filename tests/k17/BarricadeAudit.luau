--!strict
-- Engine checks and explicit solo practice. These commands only work in Studio Play.
local RunService=game:GetService("RunService")
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Teams=game:GetService("Teams")
local Config=require(RS:WaitForChild("K17Barricades"):WaitForChild("Config"))
local Placement=require(RS:WaitForChild("K17Barricades"):WaitForChild("Placement"))
local Audit={}
local function studio()
    assert(RunService:IsStudio() and RunService:IsRunning() and RunService:IsServer(),"Use Play in Studio, SERVER Command Bar")
end

function Audit.run()
    studio()
    local folder=workspace:WaitForChild("ZO_Barricades")
    local map=workspace:WaitForChild("ZO_K17Foundry")
    local passed,failed=0,0
    local function record(ok: boolean,name: string)
        if ok then passed+=1;print("[BARRICADE AUDIT] PASS "..name)
        else failed+=1;warn("[BARRICADE AUDIT] FAIL "..name) end
    end
    record(RS:GetAttribute("ZO_BarricadesReady")==true,"server ready")
    record(#folder:GetChildren()==5,"five catalog props")
    for name,prop in Config.Props do
        local model=folder:FindFirstChild(name)
        local hull=model and model:FindFirstChild("Hull")
        if model and model:IsA("Model") and hull and hull:IsA("BasePart") then
            local kind=Config.Kinds[prop.Kind]
            record((hull.Size-Vector3.new(kind.Width,kind.Height,kind.Depth)).Magnitude<.01,name.." catalog dimensions")
            local ok=Placement.clear(model,hull.CFrame,hull.Size,map)
            record(ok and model:GetAttribute("ZO_Destroyed")==false,name.." supported, unoccupied placement")
            record(model.PrimaryPart==hull and hull.Anchored and hull.CanCollide and hull.CanQuery,name.." solid, queryable primary hull")
        else record(false,name.." missing model/hull") end
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
