--!nonstrict
-- Round owns this session and its lifetime; there is no second round ticker.
local Session={}
local HoldGates=require(script.Parent.HoldGates)
function Session.new(map,rs,config,policy,valid,participants)
    local controls=assert(map:FindFirstChild("EscapeObjectives"),"EscapeObjectives ausente")
    local bay=assert(map:FindFirstChild("R50_EvacuationBay"),"Terminal de evacuação ausente")
    local gate=assert(bay:FindFirstChild("EvacuationGate"),"Portão de evacuação ausente")
    local self={state=policy.new(config),connections={},controls={},escaped={},destroyed=false}
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
    function self:publish(now)
        local s=self.state
        local extracting=s.status=="Extraction" or s.status=="Done"
        rs:SetAttribute("ZO_HoldGateStatus",doors:update(s.stage,s.status))
        gate.CanCollide=not extracting;gate.CanQuery=not extracting;gate.Transparency=if extracting then 1 else .15
        for i,item in self.controls do
            item.prompt.Enabled=not self.destroyed and rs:GetAttribute("ZO_RoundState")=="Active" and s.stage==i and s.status=="Ready"
            item.part:SetAttribute("ZO_ObjectiveState",if i<s.stage or extracting then "Complete" elseif i==s.stage then s.status else "Locked")
        end
        rs:SetAttribute("ZO_EscapeStage",s.stage);rs:SetAttribute("ZO_EscapeStatus",s.status)
        rs:SetAttribute("ZO_EscapeLabel",if extracting then "Terminal de evacuação" else config.Stages[s.stage].Label)
        rs:SetAttribute("ZO_EscapeRemaining",if s.deadline>0 then math.max(0,math.ceil(s.deadline-now)) else 0)
        rs:SetAttribute("ZO_EscapeInside",if extracting then safe() else 0)
    end
    for i=1,#config.Stages do
        local part=assert(controls:FindFirstChild("Control"..i),"Control"..i.." ausente")
        local prompt=assert(part:FindFirstChild("Activate"),"Prompt do objetivo ausente")
        self.controls[i]={part=part,prompt=prompt}
        table.insert(self.connections,prompt.Triggered:Connect(function(player)
            if self.destroyed or not valid(player) or rs:GetAttribute("ZO_RoundState")~="Active" then return end
            local char=player.Character;local root=char:FindFirstChild("HumanoidRootPart");local head=char:FindFirstChild("Head")
            if not root or not head or (root.Position-part.Position).Magnitude>config.ActivationRange then return end
            local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={char}
            local delta=part.Position-head.Position
            local hit=if delta.Magnitude>.01 then workspace:Raycast(head.Position,delta,params) else nil
            if hit and hit.Instance~=part then return end
            if self.state:activate(i,os.clock()) then self:publish(os.clock()) end
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
        for _,item in self.controls do item.prompt.Enabled=false;item.part:SetAttribute("ZO_ObjectiveState",nil) end
        gate.CanCollide=false;gate.CanQuery=false;gate.Transparency=1
        for _,key in {"ZO_EscapeStage","ZO_EscapeStatus","ZO_EscapeLabel","ZO_EscapeRemaining","ZO_EscapeInside"} do rs:SetAttribute(key,nil) end
    end
    self:publish(os.clock())
    return self
end
return table.freeze(Session)
