--!strict
-- Adapted from voximity/extract Server/Weapons.lua prepareTorsoWeld and the
-- crouch/hip interpolation in its Heartbeat handler, commit 45afa80c93eeb8f4b21a84bab8a4b14a30ff33cc.
-- Copyright (c) 2019 voximity, MIT; preserved in third_party/extract-movement/.
-- K-17 keeps the existing rig's Motor6Ds and Animator instead of adding a weld.
local Pose={}
Pose.__index=Pose

function Pose.new(character: Model,config: any)
    local root=character:FindFirstChild("HumanoidRootPart")
    local head=character:FindFirstChild("Head")
    local torso=character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso")
    if not root or not root:IsA("BasePart") or not head or not head:IsA("BasePart") or not torso then return nil end
    local rootMotor: Motor6D?=nil
    local hips={}
    local knees={}
    for _,item in character:GetDescendants() do
        if item:IsA("Motor6D") and item.Part0 and item.Part1 then
            if item.Part0==root and item.Part1==torso then rootMotor=item
            elseif item.Part0==torso and (item.Name=="Left Hip" or item.Name=="Right Hip"
                or item.Name=="LeftHip" or item.Name=="RightHip") then
                table.insert(hips,{joint=item,base=item.C0})
                item:SetAttribute("ZO_StandingC0",item.C0)
            elseif item.Name=="LeftKnee" or item.Name=="RightKnee" then
                table.insert(knees,{joint=item,base=item.C0})
                item:SetAttribute("ZO_StandingC0",item.C0)
            end
        end
    end
    if not rootMotor or #hips~=2 then return nil end
    rootMotor:SetAttribute("ZO_StandingC0",rootMotor.C0)
    local params=OverlapParams.new()
    params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances={character}
    params.RespectCanCollide=true
    local scale=math.clamp(root.Size.Y/2,.6,1.5)
    local upper=character:FindFirstChild("UpperTorso")
    local width=math.max(root.Size.X,head.Size.X,torso.Size.X,if upper and upper:IsA("BasePart") then upper.Size.X else 0)
    local depth=math.max(root.Size.Z,head.Size.Z,torso.Size.Z,if upper and upper:IsA("BasePart") then upper.Size.Z else 0)
    return setmetatable({character=character,root=root,head=head,rootMotor=rootMotor,
        rootBase=rootMotor.C0,hips=hips,knees=knees,drop=config.CrouchDrop*scale,
        forward=config.CrouchForward*scale,headOffset=root.CFrame:ToObjectSpace(head.CFrame),
        width=width,depth=depth,padding=config.StandPadding,params=params,alpha=0},Pose)
end

function Pose:canStand(world: Workspace): boolean
    local target=self.root.CFrame*self.headOffset
    -- Probe the full head growth region, not an arbitrary ray that can miss a
    -- beam/cabinet beside the head. Preserve every world collision flag.
    local size=self.head.Size
    local box=target*CFrame.new(0,-self.drop/2,self.forward/2)
    local extent=Vector3.new(self.width+self.padding*2,size.Y+self.drop+self.padding,
        self.depth+math.abs(self.forward)+self.padding*2)
    return #world:GetPartBoundsInBox(box,extent,self.params)==0
end

function Pose:update(alpha: number)
    if alpha==self.alpha then return end
    self.alpha=math.clamp(alpha,0,1)
    local a=self.alpha
    if self.rootMotor.Parent then
        self.rootMotor.C0=CFrame.new(0,-self.drop*a,self.forward*a)*self.rootBase
    end
    for _,entry in self.hips do
        if entry.joint.Parent then
            entry.joint.C0=CFrame.new(0,self.drop*a,-self.forward*.6*a)*entry.base
        end
    end
    -- Small R15 knee flexion augments the reused body/hip lowering. It uses
    -- existing joints, so no external animation ID or replacement rig is needed.
    for _,entry in self.knees do
        if entry.joint.Parent then entry.joint.C0=entry.base*CFrame.Angles(.3*a,0,0) end
    end
end

function Pose:destroy()
    if self.rootMotor.Parent then self.rootMotor.C0=self.rootBase end
    for _,entry in self.hips do if entry.joint.Parent then entry.joint.C0=entry.base end end
    for _,entry in self.knees do if entry.joint.Parent then entry.joint.C0=entry.base end end
end

return table.freeze(Pose)
