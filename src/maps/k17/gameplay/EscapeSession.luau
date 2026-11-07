--!nonstrict
-- Round owns this session and its lifetime; there is no second round ticker.
local Session={}
local HoldGates=require(script.Parent.HoldGates)
function Session.new(map,rs,config,policy,valid,participants)
    local controls=assert(map:FindFirstChild("EscapeObjectives"),"EscapeObjectives ausente")
    local bay=assert(map:FindFirstChild("R50_EvacuationBay"),"Terminal de evacuação ausente")
    local gate=assert(bay:FindFirstChild("EvacuationGate"),"Portão de evacuação ausente")
    local self={state=policy.new(config),connections={},controls={},escaped={},destroyed=false,checkpoint=0,spawnCursor=0}
    local board=assert(bay:FindFirstChild("EvacuationStatus"),"Painel de extração ausente"):FindFirstChild("Text",true)
    local doors=HoldGates.new(map,config)
    local function safe()
        local count,list=0,{}
        for player in participants do
            if valid(player) then
                local root=player.Character:FindFirstChild("HumanoidRootPart")
                local p=root and root.Position
                if p and policy.contains({p.X,p.Y,p.Z},config.Extraction) then count+=1;list[player]=true end
            end
        end
        return count,list
    end
    local function humanPositions()
        local positions={}
        for player in participants do
            local char=player.Character
            local hum=char and char:FindFirstChildOfClass("Humanoid")
            -- Spawn distance also applies while first mothers are selected in
            -- Preparation; the interaction predicate intentionally requires Active.
            if player.Parent and player.Team and player.Team.Name=="Humans" and hum and hum.Health>0
                and char:IsDescendantOf(workspace) then
                local root=char:FindFirstChild("HumanoidRootPart")
                if root then table.insert(positions,{root.Position.X,root.Position.Y,root.Position.Z}) end
            end
        end
        return positions
    end
    function self:spawn(clear)
        local point,group=policy.chooseSpawn(config,self.checkpoint,humanPositions(),clear,self.spawnCursor)
        if point then self.spawnCursor+=1 end
        return point,group
    end
    function self:publish(now)
        local s=self.state
        local extracting=s.status=="Extraction" or s.status=="Done"
        rs:SetAttribute("ZO_HoldGateStatus",doors:update(s.stage,s.status))
        gate.CanCollide=not extracting;gate.CanQuery=not extracting;gate.Transparency=if extracting then 1 else .15
        for i,item in self.controls do
            item.prompt.Enabled=not self.destroyed and rs:GetAttribute("ZO_RoundState")=="Active" and s.stage==i and s.status=="Ready"
            local status=if i<s.stage or extracting then "Complete" elseif i==s.stage then s.status else "Locked"
            item.part:SetAttribute("ZO_ObjectiveState",status)
            item.indicator.Color=if status=="Complete" then Color3.fromRGB(116,211,154)
                elseif status=="Holding" then Color3.fromRGB(242,166,66)
                elseif status=="Ready" then Color3.fromRGB(233,210,115) else Color3.fromRGB(155,63,49)
        end
        self.checkpoint=policy.advanceCheckpoint(config,self.checkpoint,s.stage,humanPositions())
        rs:SetAttribute("ZO_InfectionCheckpoint",self.checkpoint)
        rs:SetAttribute("ZO_InfectionSector",if self.checkpoint>0 then config.Respawns[self.checkpoint].Label else "Administração norte")
        rs:SetAttribute("ZO_EscapeStage",s.stage);rs:SetAttribute("ZO_EscapeStatus",s.status)
        rs:SetAttribute("ZO_EscapeLabel",if extracting then "Terminal de evacuação" else config.Stages[s.stage].Label)
        rs:SetAttribute("ZO_EscapeRemaining",if s.deadline>0 then math.max(0,math.ceil(s.deadline-now)) else 0)
        rs:SetAttribute("ZO_EscapeInside",if extracting then safe() else 0)
        if board then
            board.Text=if extracting then ("EXTRAÇÃO %ds / %d HUMANOS NO TERMINAL"):format(math.max(0,math.ceil(s.deadline-now)),safe())
                else ("ZE %d/3 / %s"):format(s.stage,if s.status=="Holding" then "DEFENDA A POSIÇÃO" else "ACIONE O OBJETIVO")
        end
    end
    for i=1,#config.Stages do
        local part=assert(controls:FindFirstChild("Control"..i),"Control"..i.." ausente")
        local prompt=assert(part:FindFirstChild("Activate"),"Prompt do objetivo ausente")
        self.controls[i]={part=part,prompt=prompt,indicator=assert(controls:FindFirstChild("Indicator"..i),"Indicador ausente")}
        table.insert(self.connections,prompt.Triggered:Connect(function(player)
            if self.destroyed or not valid(player) or rs:GetAttribute("ZO_RoundState")~="Active" then return end
            local char=player.Character;local root=char:FindFirstChild("HumanoidRootPart");local head=char:FindFirstChild("Head")
            if not root or not head or (root.Position-part.Position).Magnitude>config.ActivationRange then return end
            local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={char}
            local delta=part.Position-head.Position
            local hit=if delta.Magnitude>.01 then workspace:Raycast(head.Position,delta,params) else nil
            if hit and hit.Instance~=part then return end
            if self.state:activate(i,os.clock()) then
                player:SetAttribute("ZO_RoundObjectives",(player:GetAttribute("ZO_RoundObjectives") or 0)+1)
                self:publish(os.clock())
            end
        end))
    end
    function self:update(now,remaining)
        local count,list=safe()
        local result=self.state:step(now,remaining,count)
        if result=="Humans" then self.escaped=list end
        self:publish(now)
        return result
    end
    function self:destroy()
        if self.destroyed then return end
        self.destroyed=true
        doors:destroy();rs:SetAttribute("ZO_HoldGateStatus",nil)
        for _,connection in self.connections do connection:Disconnect() end
        for _,item in self.controls do
            item.prompt.Enabled=false;item.part:SetAttribute("ZO_ObjectiveState",nil);item.indicator.Color=Color3.fromRGB(197,161,66)
        end
        if board then board.Text="ZE / AGUARDE A SEQUÊNCIA" end
        gate.CanCollide=false;gate.CanQuery=false;gate.Transparency=1
        for _,key in {"ZO_EscapeStage","ZO_EscapeStatus","ZO_EscapeLabel","ZO_EscapeRemaining","ZO_EscapeInside","ZO_InfectionCheckpoint","ZO_InfectionSector"} do rs:SetAttribute(key,nil) end
    end
    self:publish(os.clock())
    return self
end
return table.freeze(Session)
