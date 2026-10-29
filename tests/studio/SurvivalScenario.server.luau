--!strict
-- Separate Studio validation place only. Never mapped into the playable release.
-- Uses actual Players, Humanoids, network remotes, raycasts and round controllers.
-- Anchored test positioning excludes navigation, recoil feel and knockback physics.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() or not RunService:IsServer() then return end
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local combatConfig=require(RS:WaitForChild("K17Gameplay"):WaitForChild("Config"))
local roundConfig=require(RS:WaitForChild("Shared"):WaitForChild("RoundConfig"))
local channel=Instance.new("RemoteEvent")
channel.Name="ZO_StudioSurvivalTest"
channel.Parent=RS
local ready: {[Player]: boolean}={}
local replies: {[number]: {Player: Player,OK: boolean,Error: string}}={}
local roots: {[BasePart]: boolean}={}
local rotation: {[Humanoid]: boolean}={}
local checks=0
local serial=0
local stage="startup"
local movementConnection: RBXScriptConnection?
script:SetAttribute("Status","Running")
local function waitUntil(label: string,predicate: ()->boolean,seconds: number)
    stage=label;script:SetAttribute("Stage",label)
    local deadline=os.clock()+seconds
    repeat
        assert(RS:GetAttribute("ZO_GameplayStatus")~="Error",tostring(RS:GetAttribute("ZO_GameplayError")))
        assert(#Players:GetPlayers()<=2,"Use exactly two Studio clients")
        if predicate() then return end
        task.wait(.05)
    until os.clock()>=deadline
    error("Timeout: "..label)
end
local function check(value: boolean,label: string)
    assert(value,label);checks+=1
    script:SetAttribute("Checks",checks)
    print("[SURVIVAL STUDIO] PASS "..label)
end
local transport=channel.OnServerEvent:Connect(function(player: Player,kind: any,id: any,ok: any,problem: any)
    if kind=="Ready" then ready[player]=true
    elseif kind=="Ack" and type(id)=="number" and id==serial then
        replies[id]={Player=player,OK=ok==true,Error=tostring(problem):sub(1,300)}
    end
end)
local function living(player: Player): (Model,Humanoid,BasePart,BasePart)
    local character=player.Character
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local head=character and character:FindFirstChild("Head")
    assert(character and character:IsDescendantOf(workspace) and humanoid and humanoid.Health>0
        and root and root:IsA("BasePart") and head and head:IsA("BasePart"),"Living character required: "..player.Name)
    return character,humanoid,root,head
end
local function place(player: Player,position: Vector3,look: Vector3)
    local character,humanoid,root=living(player)
    if roots[root]==nil then roots[root]=root.Anchored end
    if rotation[humanoid]==nil then rotation[humanoid]=humanoid.AutoRotate end
    root.Anchored=true;humanoid.AutoRotate=false
    for _,child in character:GetChildren() do
        if child:IsA("ForceField") then child:Destroy() end
    end
    character:PivotTo(CFrame.lookAt(position,look))
end
local function request(player: Player,action: string,target: Vector3?)
    serial+=1
    local id=serial
    channel:FireClient(player,id,action,target)
    waitUntil("client "..action,function() return replies[id]~=nil end,5)
    local reply=replies[id];replies[id]=nil
    assert(reply.Player==player and reply.OK,"Client request failed: "..reply.Error)
end
local function rolePair(): (Player,Player)
    local human,zombie
    for _,player in Players:GetPlayers() do
        if player.Team and player.Team.Name=="Humans" then human=player
        elseif player.Team and player.Team.Name=="Zombies" then zombie=player end
    end
    assert(human and zombie,"Expected one human and one zombie")
    return human,zombie
end
local function nextPreparation(previous: number): number
    waitUntil("next preparation",function()
        return RS:GetAttribute("ZO_RoundState")=="Preparation" and (RS:GetAttribute("ZO_RoundId") or 0)>previous
    end,45)
    local id=RS:GetAttribute("ZO_RoundId") :: number
    check(RS:GetAttribute("ZO_Humans")==2 and RS:GetAttribute("ZO_Zombies")==0,"round "..id.." starts with two humans")
    return id
end
local ok,problem=xpcall(function()
    waitUntil("two ready clients",function()
        local list=Players:GetPlayers()
        if #list~=2 then return false end
        for _,player in list do if not ready[player] then return false end end
        return RS:GetAttribute("ZO_GameplayRoundReady")==true and RS:GetAttribute("ZO_GameplayCombatReady")==true
    end,55)
    check(true,"production round and combat controllers ready; two client drivers connected")
    local id=nextPreparation(RS:GetAttribute("ZO_RoundId") or 0)
    waitUntil("first infection",function() return RS:GetAttribute("ZO_RoundState")=="Active" end,8)
    local human,zombie=rolePair()
    check(RS:GetAttribute("ZO_Humans")==1 and RS:GetAttribute("ZO_Zombies")==1,"random first infection creates opposing roles")
    -- Authored stockroom passage used by the existing gameplay audit.
    place(human,Vector3.new(-248,4,123),Vector3.new(-238,4,123))
    place(zombie,Vector3.new(-238,4,123),Vector3.new(-248,4,123))
    task.wait(.5)
    local _,victim,_,target=living(zombie)
    local baseSpeed=victim.WalkSpeed
    local taggedSpeed=baseSpeed*combatConfig.Containment.TagWalkScale
    local minimumSpeed=baseSpeed
    local function near(actual: number,expected: number): boolean
        return math.abs(actual-expected)<.001
    end
    check(near(baseSpeed,roundConfig.ZombieWalkSpeed),"zombie starts with configured movement speed")
    -- Observe the property's real engine precision. A short tag may already
    -- expire while the separate client acknowledgement is travelling back.
    movementConnection=victim:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
        minimumSpeed=math.min(minimumSpeed,victim.WalkSpeed)
    end)
    local ammo=human:GetAttribute("ZO_Ammo") :: number
    local health=victim.Health
    request(human,"Fire",target.Position)
    waitUntil("server damage and ammunition",function()
        return victim.Health<health and human:GetAttribute("ZO_Ammo")==ammo-1
    end,3)
    check(true,"client fire produces real raycast damage and spends server ammunition")
    waitUntil("single hit applies movement tag",function() return minimumSpeed<baseSpeed-.001 end,2)
    check(near(minimumSpeed,taggedSpeed),"single hit applies only the configured movement slowdown")
    waitUntil("single hit movement recovery",function() return near(victim.WalkSpeed,baseSpeed) end,2)
    check(near(victim.WalkSpeed,baseSpeed),"single hit restores original zombie speed after tag expires")
    request(human,"Reload")
    waitUntil("reload starts",function() return human:GetAttribute("ZO_Reloading")==true end,2)
    local reserve=human:GetAttribute("ZO_Reserve") :: number
    waitUntil("reload completes",function()
        return human:GetAttribute("ZO_Reloading")==false and human:GetAttribute("ZO_Ammo")==ammo
    end,5)
    check(human:GetAttribute("ZO_Reserve")==reserve-1,"timed reload transfers exactly one reserve round")
    minimumSpeed=baseSpeed
    for shot=1,6 do
        local beforeAmmo=human:GetAttribute("ZO_Ammo") :: number
        local beforeHealth=victim.Health
        local nextShot=os.clock()+combatConfig.Weapons.Rifle.FireInterval+.02
        request(human,"Fire",target.Position)
        waitUntil("burst hit "..shot,function()
            return victim.Health<beforeHealth and human:GetAttribute("ZO_Ammo")==beforeAmmo-1
        end,3)
        task.wait(math.max(0,nextShot-os.clock()))
    end
    check(victim.Health>0 and near(minimumSpeed,taggedSpeed),"six confirmed hits never compound zombie movement slowdown")
    waitUntil("burst movement recovery",function() return near(victim.WalkSpeed,baseSpeed) end,2)
    check(near(victim.WalkSpeed,baseSpeed),"zombie recovers original speed after the final burst hit")
    if movementConnection then movementConnection:Disconnect();movementConnection=nil end
    place(zombie,Vector3.new(-243.5,4,123),Vector3.new(-248,4,123))
    task.wait(.3)
    local _,_,_,humanHead=living(human)
    human:SetAttribute("ZO_InfectedBy",nil)
    request(zombie,"Melee",humanHead.Position)
    -- Results may already have moved both teams to Lobby by the next poll.
    -- This persistent marker is written only by the production infection path.
    waitUntil("melee infection",function() return human:GetAttribute("ZO_InfectedBy")==zombie.UserId end,2)
    check(human:GetAttribute("ZO_InfectedBy")==zombie.UserId,"client melee infects through the production server authority")
    waitUntil("zombie victory",function() return RS:GetAttribute("ZO_RoundState")=="Results" end,3)
    check(RS:GetAttribute("ZO_LastWinner")=="Zombies","all humans infected ends the round with zombie victory")
    id=nextPreparation(id)
    waitUntil("second first infection",function() return RS:GetAttribute("ZO_RoundState")=="Active" end,8)
    local survivor,secondZombie=rolePair()
    place(survivor,Vector3.new(-248,4,123),Vector3.new(-238,4,123))
    place(secondZombie,Vector3.new(-238,4,123),Vector3.new(-248,4,123))
    waitUntil("human survival victory",function() return RS:GetAttribute("ZO_RoundState")=="Results" end,35)
    check(RS:GetAttribute("ZO_LastWinner")=="Humans" and survivor:GetAttribute("ZO_SurvivedRound")==id,
        "timer expiry declares human victory and records the living survivor")
    nextPreparation(id)
    check(true,"automatic next-round reset restores both humans")
end,debug.traceback)
if movementConnection then movementConnection:Disconnect() end
for root,anchored in roots do if root.Parent then root.Anchored=anchored end end
for humanoid,autoRotate in rotation do if humanoid.Parent then humanoid.AutoRotate=autoRotate end end
for _,player in Players:GetPlayers() do channel:FireClient(player,0,"Stop") end
transport:Disconnect();channel:Destroy()
script:SetAttribute("Status",if ok then "Passed" else "Failed")
if ok then print(("[SURVIVAL STUDIO] COMPLETE: %d checks passed in the Roblox engine."):format(checks))
else
    script:SetAttribute("Failure",tostring(problem):sub(1,1500))
    warn("[SURVIVAL STUDIO] FAIL at "..stage..": "..tostring(problem))
end
