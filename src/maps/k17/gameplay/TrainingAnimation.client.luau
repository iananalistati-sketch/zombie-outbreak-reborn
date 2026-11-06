--!strict
-- Cosmetic local gait for the cloned training rigs, with no animation asset IDs.
local Run=game:GetService("RunService")
local tracked={}
local folder: Instance?=nil
local function register(model)
    if not model:IsA("Model") or model:GetAttribute("ZO_TrainingEnemy")~=true then return end
    local joints={}
    for _,item in model:GetDescendants() do
        if item:IsA("Motor6D") then
            local n=item.Name:gsub(" ","")
            if n=="LeftHip" or n=="RightHip" or n=="LeftShoulder" or n=="RightShoulder" then
                local rotation=item.C0.Rotation
                joints[n]={joint=item,rotation=rotation,inverse=rotation:Inverse()}
            end
        end
    end
    tracked[model]={root=model:FindFirstChild("HumanoidRootPart"),hum=model:FindFirstChildOfClass("Humanoid"),joints=joints,phase=0,swing=0}
end
Run.RenderStepped:Connect(function(dt)
    local current=workspace:FindFirstChild("ZO_PracticeTargets")
    if current~=folder then table.clear(tracked);folder=current end
    if not folder then return end
    for _,model in folder:GetChildren() do
        local entry=tracked[model]
        if not entry or not entry.root or not entry.hum or not entry.joints.LeftHip or not entry.joints.RightHip then register(model) end
    end
    for model,entry in tracked do
        if not model.Parent then tracked[model]=nil;continue end
        if not entry.root or not entry.hum or entry.hum.Health<=0 then continue end
        local velocity=entry.root.AssemblyLinearVelocity
        local speed=math.min(20,Vector3.new(velocity.X,0,velocity.Z).Magnitude)
        entry.phase=(entry.phase+dt*speed*1.15)%(math.pi*2)
        local desired=math.sin(entry.phase)*.45*math.clamp(speed/4,0,1)
        entry.swing+=(desired-entry.swing)*(1-math.exp(-12*math.min(dt,.1)))
        for name,value in entry.joints do
            local angle=if name=="LeftHip" then entry.swing elseif name=="RightHip" then -entry.swing
                elseif name=="LeftShoulder" then .65-entry.swing*.4 else .65+entry.swing*.4
            -- R6 hip axes differ from R15; express the gait in parent space.
            if value.joint.Parent then value.joint.Transform=value.inverse*CFrame.Angles(angle,0,0)*value.rotation end
        end
    end
end)
