--!strict
-- Automatic solo warm-up. Round remains the sole multiplayer/role authority.
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Teams=game:GetService("Teams")
local Pathfinding=game:GetService("PathfindingService")
local Debris=game:GetService("Debris")
local cleanup: (() -> ())?=nil
local function main()
    local shared=assert(RS:WaitForChild("K17Gameplay",12),"K17Gameplay ausente")
    local Config=require(shared:WaitForChild("TrainingConfig"))
    local State=require(shared:WaitForChild("TrainingState"))
    local Rig=require(shared:WaitForChild("TrainingRig"))
    local Movement=require(shared:WaitForChild("MovementState"))
    local roundConfig=require(RS:WaitForChild("Shared"):WaitForChild("RoundConfig"))
    local map=assert(workspace:WaitForChild("ZO_K17Foundry",12),"Mapa K-17 ausente")
    local spawns=map:WaitForChild("Spawns")
    local marker=spawns:WaitForChild("HumanSpawn") :: BasePart
    local folder: Folder?=nil
    local owner: Player?=nil
    local character: Model?=nil
    local session: any=nil
    local actors={}
    local generation=0
    local protectedUntil=0
    local function clearActors()
        generation+=1
        for model,actor in actors do
            actor.stopped=true
            if actor.connection then actor.connection:Disconnect() end
            model:Destroy()
        end
        table.clear(actors)
        if folder then folder:Destroy();folder=nil end
    end
    local function stop()
        if owner or folder then clearActors() end
        owner=nil;character=nil;session=nil
        workspace:SetAttribute("ZO_BarricadePractice",false)
        RS:SetAttribute("ZO_TrainingStage",nil)
    end
    cleanup=stop
    local function liveCount()
        local count=0
        for model,actor in actors do
            if not actor.stopped and model.Parent and actor.hum.Health>0 then count+=1 end
        end
        return count
    end
    local function publish()
        RS:SetAttribute("ZO_TrainingStage",session.stage)
        RS:SetAttribute("ZO_TrainingWave",session.wave)
        RS:SetAttribute("ZO_TrainingKills",session.totalKills)
        RS:SetAttribute("ZO_TrainingAlive",liveCount())
        RS:SetAttribute("ZO_TrainingRemaining",math.max(0,math.ceil(session.deadline-os.clock())))
    end
    local function begin(player,model,hum)
        clearActors()
        folder=Instance.new("Folder");folder.Name="ZO_PracticeTargets";folder.Parent=workspace
        owner=player;character=model;session=State.new(Config,os.clock())
        protectedUntil=os.clock()+Config.SpawnProtection
        workspace:SetAttribute("ZO_BarricadePractice",true)
        player.Team=assert(Teams:FindFirstChild("Humans"));player.Neutral=false;player:SetAttribute("ZO_Role","Humans")
        hum.MaxHealth=roundConfig.HumanHealth;hum.Health=hum.MaxHealth
        Movement.setBase(hum,roundConfig.HumanWalkSpeed,os.clock())
        model:PivotTo(marker.CFrame*CFrame.new(0,4,0))
        workspace:SetAttribute("ZO_PracticeRevision",(workspace:GetAttribute("ZO_PracticeRevision") or 0)+1)
        RS:SetAttribute("ZO_TrainingError",nil)
        publish()
    end
    local function spawnActor()
        local player=owner;local model=character;local current=session
        local waveId=current.wave;local wave=Config.Waves[waveId]
        local token=generation
        local index=current.spawned
        -- Authored clear administration corridor; does not intersect walls/desks.
        local point=marker.Position+Vector3.new((index%3-1),4,-25-index%3)
        local bot=Rig.new(model,CFrame.new(point),wave.Health,wave.Speed)
        local hum=bot:FindFirstChildOfClass("Humanoid") :: Humanoid
        local root=bot:FindFirstChild("HumanoidRootPart") :: BasePart
        Movement.setBase(hum,wave.Speed,os.clock())
        bot.Parent=folder;root:SetNetworkOwner(nil)
        local actor={hum=hum,stopped=false,connection=nil}
        actors[bot]=actor
        actor.connection=hum.Died:Connect(function()
            if actor.stopped then return end
            actor.stopped=true
            if session==current and current.wave==waveId and current:kill() then publish() end
            Debris:AddItem(bot,2)
        end)
        task.spawn(function()
            local path=Pathfinding:CreatePath({AgentRadius=2,AgentHeight=6,AgentCanJump=true})
            local lastPath=-math.huge;local nextAttack=0;local waypoints={};local cursor=2
            while not actor.stopped and token==generation and bot.Parent and hum.Health>0 do
                if session~=current or RS:GetAttribute("ZO_RoundState")~="Training" or #Players:GetPlayers()~=1 then break end
                local target=player.Character
                local tr=target and target:FindFirstChild("HumanoidRootPart")
                local th=target and target:FindFirstChildOfClass("Humanoid")
                if tr and th and th.Health>0 then
                    local now=os.clock()
                    if now-lastPath>=Config.PathInterval then
                        lastPath=now
                        local ok=pcall(function() path:ComputeAsync(root.Position,tr.Position) end)
                        if actor.stopped or token~=generation or not bot.Parent then break end
                        waypoints=if ok and path.Status==Enum.PathStatus.Success then path:GetWaypoints() else {}
                        cursor=2
                    end
                    local point=waypoints[cursor]
                    if point then
                        if (point.Position-root.Position).Magnitude<3 then cursor+=1 end
                        if point.Action==Enum.PathWaypointAction.Jump then hum.Jump=true end
                        hum:MoveTo(point.Position)
                    else hum:MoveTo(tr.Position) end
                    if now>=nextAttack and now>=protectedUntil and (tr.Position-root.Position).Magnitude<=Config.AttackRange then
                        local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={bot}
                        local hit=workspace:Raycast(root.Position,tr.Position-root.Position,params)
                        if hit and hit.Instance:IsDescendantOf(target) then
                            nextAttack=now+Config.AttackCooldown;th:TakeDamage(Config.AttackDamage)
                        end
                    end
                end
                task.wait(.15)
            end
        end)
    end
    while true do
        task.wait(.2)
        if not Config.Enabled or RS:GetAttribute("ZO_RoundState")~="Training" or #Players:GetPlayers()~=1
            or RS:GetAttribute("ZO_GameplayStatus")=="Error" then
            stop();continue
        end
        local player=Players:GetPlayers()[1]
        local model=player.Character
        local hum=model and model:FindFirstChildOfClass("Humanoid")
        local ready=model and model:IsDescendantOf(workspace) and hum and hum.Health>0
            and model:FindFirstChild("HumanoidRootPart")~=nil
        if not session then
            if ready then begin(player,model,hum) else RS:SetAttribute("ZO_TrainingStage","Loading") end
            continue
        end
        local previousStage=session.stage
        session:step(os.clock(),ready and character==model)
        if session.stage=="Lost" or session.stage=="Won" then
            if previousStage~=session.stage then clearActors() end
            if session:restartDue(os.clock()) and ready then begin(player,model,hum) end
        elseif session:spawn(os.clock(),liveCount()) then spawnActor() end
        publish()
    end
end
local ok,message=xpcall(main,debug.traceback)
if not ok then
    if cleanup then pcall(cleanup) end
    workspace:SetAttribute("ZO_BarricadePractice",false)
    RS:SetAttribute("ZO_TrainingError",tostring(message):sub(1,1200))
    warn("[TRAINING] "..tostring(message))
end
