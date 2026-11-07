--!nonstrict
-- Reuses the existing player avatar, preserving native parts and grip data.
-- Extracted from the K-17 presentation adapter; no new avatar asset downloads.
local armNames={RightUpperArm=true,RightLowerArm=true,RightHand=true,LeftUpperArm=true,LeftLowerArm=true,LeftHand=true,
    ["Right Arm"]=true,["Left Arm"]=true}
local function placeArms(arms,rootCFrame)
    arms.root.CFrame=rootCFrame
    for _,joint in arms.joints do
        joint.Part1.CFrame=joint.Part0.CFrame*joint.C0*joint.Transform*joint.C1:Inverse()
    end
    for part,offset in arms.disconnected do part.CFrame=rootCFrame*offset end
end

local function copyArms(character,parent,zombie)
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil,"NoHumanoid" end
    local r6=humanoid.RigType==Enum.HumanoidRigType.R6
    if not r6 and humanoid.RigType~=Enum.HumanoidRigType.R15 then return nil,"UnsupportedRig" end
    local sourceHand=character:FindFirstChild(if r6 then "Right Arm" else "RightHand")
    local sourceGrip=sourceHand and sourceHand:FindFirstChild("RightGripAttachment")
    local nativeGrip=sourceHand and sourceHand:FindFirstChild("RightGrip")
    local gripOffset=if sourceGrip and sourceGrip:IsA("Attachment") then sourceGrip.CFrame
        elseif nativeGrip and nativeGrip:IsA("JointInstance") then nativeGrip.C0
        elseif r6 and sourceHand then CFrame.new(0,-sourceHand.Size.Y/2,0) else CFrame.identity
    local archivable=character.Archivable
    character.Archivable=true
    local ok,rig=pcall(function() return character:Clone() end)
    character.Archivable=archivable
    if not ok or not rig then return nil,"CloneUnavailable" end
    rig.Name="ZO_FirstPersonArms"
    for _,descendant in rig:GetDescendants() do
        if descendant:IsA("LuaSourceContainer") or descendant:IsA("Tool") or descendant:IsA("Accessory")
            or descendant:IsA("Humanoid") or descendant:IsA("AnimationController") or descendant:IsA("Sound")
            or descendant:IsA("BillboardGui") or descendant:IsA("SurfaceGui") or descendant:IsA("Highlight") then
            descendant:Destroy()
        elseif (descendant:IsA("Decal") or descendant:IsA("Texture"))
            and (not descendant.Parent or not armNames[descendant.Parent.Name]) then
            descendant:Destroy()
        end
    end
    local root=rig:FindFirstChild("HumanoidRootPart")
    local hand=rig:FindFirstChild(if r6 then "Right Arm" else "RightHand")
    if not root or not root:IsA("BasePart") or not hand or not hand:IsA("BasePart") then
        rig:Destroy();return nil,"IncompleteRig"
    end
    local parts,motors,offsets={},{},{}
    for _,part in rig:GetDescendants() do
        if part:IsA("BasePart") then
            offsets[part]=root.CFrame:ToObjectSpace(part.CFrame)
            -- AnimationController writes Motor6D.Transform; positioning the cloned
            -- parts explicitly avoids a one-physics-frame lag behind the camera.
            part.Anchored=true;part.CanCollide=false;part.CanQuery=false;part.CanTouch=false
            part.Massless=true;part.CastShadow=false
            if not armNames[part.Name] then part.Transparency=1
            elseif zombie then part.Color=Color3.fromRGB(112,130,104) end
            part.LocalTransparencyModifier=1
            table.insert(parts,part)
        elseif part:IsA("Motor6D") then
            if part.Part0 and part.Part1 and part.Part0:IsDescendantOf(rig) and part.Part1:IsDescendantOf(rig) then
                part.Transform=CFrame.identity
                table.insert(motors,part)
                local name=part.Name:gsub(" ","")
                if r6 and (name=="LeftShoulder" or name=="RightShoulder") then
                    -- Pose the real R6 limb in torso space, retaining native
                    -- C0 axes/position instead of assuming R15 shoulder axes.
                    part.C0=CFrame.new(part.C0.Position)*CFrame.Angles(math.rad(78),0,if name=="LeftShoulder" then -.12 else .12)*part.C0.Rotation
                elseif zombie and (name=="LeftShoulder" or name=="RightShoulder") then
                    -- Real R15 arms, posed forward; no placeholder claw geometry.
                    part.C0*=CFrame.Angles(math.rad(78),0,if part.Name=="LeftShoulder" then -.12 else .12)
                end
            else part:Destroy() end
        elseif part:IsA("JointInstance") then
            if not part.Part0 or not part.Part1 or not part.Part0:IsDescendantOf(rig) or not part.Part1:IsDescendantOf(rig) then part:Destroy() end
        end
    end
    local ordered,connected={}, {[root]=true}
    for _=1,#motors do
        local progress=false
        for index=#motors,1,-1 do
            local motor=motors[index]
            if connected[motor.Part0] then
                connected[motor.Part1]=true;table.insert(ordered,motor);table.remove(motors,index);progress=true
            end
        end
        if not progress then break end
    end
    local disconnected={}
    for part,offset in offsets do if not connected[part] then disconnected[part]=offset end end
    local animator=nil
    if not r6 then
        local controller=Instance.new("AnimationController");controller.Name="ViewmodelAnimations";controller.Parent=rig
        animator=Instance.new("Animator");animator.Parent=controller
    end
    local head=rig:FindFirstChild("Head")
    local headOffset=if head and head:IsA("BasePart") then root.CFrame:ToObjectSpace(head.CFrame) else CFrame.new(0,2.5,0)
    local arms={model=rig,root=root,hand=hand,parts=parts,animator=animator,headOffset=headOffset,
        joints=ordered,disconnected=disconnected,gripOffset=gripOffset,rigType=if r6 then "R6" else "R15"}
    rig.PrimaryPart=root;placeArms(arms,CFrame.new(0,-10000,0));rig.Parent=parent
    return arms,"Ready"
end

return table.freeze({copy=copyArms,place=placeArms})
