--!strict
-- Tiro validado no servidor, munição e knockback para zumbis.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Remote=Instance.new("RemoteEvent")
Remote.Name="ZO_FireRifle"
Remote.Parent=ReplicatedStorage
local magazine: {[Player]:number}={}
local reserve: {[Player]:number}={}
local lastShot: {[Player]:number}={}
local MAX_AMMO=30
local MAX_RESERVE=120
local SHOT_DELAY=.105
local MAX_DISTANCE=280
local function sync(p:Player)
    p:SetAttribute("ZO_Ammo",magazine[p] or MAX_AMMO)
    p:SetAttribute("ZO_Reserve",reserve[p] or MAX_RESERVE)
end
local function reset(p:Player)
    magazine[p]=MAX_AMMO
    reserve[p]=MAX_RESERVE
    lastShot[p]=0
    sync(p)
end
Players.PlayerAdded:Connect(function(p)
    reset(p)
    p:GetPropertyChangedSignal("Team"):Connect(function()
        if p.Team and p.Team.Name=="Humans" then reset(p) end
    end)
end)
for _,p in ipairs(Players:GetPlayers()) do reset(p) end
Players.PlayerRemoving:Connect(function(p)
    magazine[p]=nil
    reserve[p]=nil
    lastShot[p]=nil
end)
Remote.OnServerEvent:Connect(function(p:Player,action:any,direction:any)
    if not p.Team or p.Team.Name~="Humans" then return end
    if ReplicatedStorage:GetAttribute("ZO_RoundState")~="Active" then return end
    local character=p.Character
    local head=character and character:FindFirstChild("Head")
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not head or not head:IsA("BasePart") or not humanoid or humanoid.Health<=0 then return end
    if action=="Reload" then
        local needed=MAX_AMMO-(magazine[p] or 0)
        local take=math.min(needed,reserve[p] or 0)
        magazine[p]=(magazine[p] or 0)+take
        reserve[p]=(reserve[p] or 0)-take
        sync(p)
        return
    end
    if action~="Fire" or typeof(direction)~="Vector3" then return end
    local magnitude=direction.Magnitude
    if magnitude<.98 or magnitude>1.02 then return end
    if direction:Dot(head.CFrame.LookVector)<0.55 then return end
    local now=os.clock()
    if now-(lastShot[p] or 0)<SHOT_DELAY then return end
    if (magazine[p] or 0)<=0 then return end
    lastShot[p]=now
    magazine[p]-=1
    sync(p)
    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={character}
    local hit=workspace:Raycast(head.Position,direction*MAX_DISTANCE,params)
    if not hit then return end
    local part=hit.Instance
    local victimChar=part:FindFirstAncestorOfClass("Model")
    local victim=victimChar and Players:GetPlayerFromCharacter(victimChar)
    if not victim or not victim.Team or victim.Team.Name~="Zombies" then return end
    local targetHumanoid=victimChar:FindFirstChildOfClass("Humanoid")
    local root=victimChar:FindFirstChild("HumanoidRootPart")
    if not targetHumanoid or targetHumanoid.Health<=0 then return end
    local damage=if part.Name=="Head" then 38 else 18
    targetHumanoid:TakeDamage(damage)
    if root and root:IsA("BasePart") then
        local away=root.Position-head.Position
        local horizontal=Vector3.new(away.X,0,away.Z)
        if horizontal.Magnitude>.1 then
            local impulse=horizontal.Unit * root.AssemblyMass * (if part.Name == "Head" then 45 else 30)
            root:ApplyImpulse(impulse)
        end
    end
    Remote:FireClient(p,"Hit",damage)
end)
print("[Zombie Outbreak] Combat server online")
