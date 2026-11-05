--!strict
-- Shop presentation only: clone the actual equipped-weapon templates, never a
-- second catalogue of block stand-ins. No firing, inventory or economy calls.
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local WeaponSkins=require(RS:WaitForChild("K17Gameplay"):WaitForChild("WeaponSkins"))
local Preview={}
Preview.__index=Preview

local function visibleBounds(model: Model): (Vector3?,Vector3?)
    local low=Vector3.new(math.huge,math.huge,math.huge)
    local high=Vector3.new(-math.huge,-math.huge,-math.huge)
    local found=false
    for _,part in model:GetDescendants() do
        if part:IsA("BasePart") and part.Transparency<.98 then
            local cf,size=part.CFrame,part.Size
            local right,up,look=cf.RightVector,cf.UpVector,cf.LookVector
            local extent=Vector3.new(
                math.abs(right.X)*size.X+math.abs(up.X)*size.Y+math.abs(look.X)*size.Z,
                math.abs(right.Y)*size.X+math.abs(up.Y)*size.Y+math.abs(look.Y)*size.Z,
                math.abs(right.Z)*size.X+math.abs(up.Z)*size.Y+math.abs(look.Z)*size.Z)*.5
            low=low:Min(part.Position-extent);high=high:Max(part.Position+extent);found=true
        end
    end
    if not found then return nil,nil end
    return (low+high)*.5,high-low
end

function Preview.new(viewport: ViewportFrame)
    local world=Instance.new("WorldModel");world.Name="WeaponDisplay";world.Parent=viewport
    local camera=Instance.new("Camera");camera.Name="PreviewCamera";camera.FieldOfView=35;camera.Parent=viewport
    viewport.CurrentCamera=camera
    viewport.Ambient=Color3.fromRGB(152,166,178)
    viewport.LightColor=Color3.fromRGB(245,235,211)
    viewport.LightDirection=Vector3.new(-.7,-.6,-.4)
    local message=viewport:FindFirstChild("AssetMissing") :: TextLabel?
    if not message then
        message=Instance.new("TextLabel");message.Name="AssetMissing"
        message.Size=UDim2.fromScale(1,1);message.BackgroundTransparency=1
        message.TextColor3=Color3.fromRGB(179,194,199);message.Font=Enum.Font.GothamMedium
        message.TextSize=12;message.TextWrapped=true;message.Parent=viewport
    end
    local self=setmetatable({viewport=viewport,world=world,camera=camera,message=message,
        model=nil,serial=0,destroyed=false,angle=.18,radius=1},Preview)
    self.render=RunService.RenderStepped:Connect(function(dt)
        if self.destroyed or not self.model then return end
        local node: Instance?=viewport
        while node do
            if node:IsA("GuiObject") and not node.Visible then return end
            node=node.Parent
        end
        self.angle+=math.min(dt,.1)*.12
        local aspect=math.max(.35,viewport.AbsoluteSize.X/math.max(1,viewport.AbsoluteSize.Y))
        local vertical=math.rad(camera.FieldOfView*.5)
        local field=math.min(vertical,math.atan(math.tan(vertical)*aspect))
        local distance=self.radius/math.sin(field)*1.08
        local direction=Vector3.new(math.cos(self.angle),.27,math.sin(self.angle)).Unit
        camera.CFrame=CFrame.lookAt(direction*distance,Vector3.zero)
        camera.Focus=CFrame.new()
    end)
    self.removed=viewport.Destroying:Connect(function() self:destroy() end)
    self.assetAdded=RS.DescendantAdded:Connect(function(item)
        if item:IsA("Tool") and self.id and WeaponSkins.resolve(RS:FindFirstChild("ZO_WeaponAssets"),self.id,self.skin)==item then
            local id,skin=self.id,self.skin;self.id=nil;self:setWeapon(id,skin)
        end
    end)
    self.assetRemoving=RS.DescendantRemoving:Connect(function(item)
        local template=self.template
        if self.destroyed or not template or (item~=template and not template:IsDescendantOf(item)) then return end
        -- DescendantRemoving precedes detachment. Invalidate immediately and
        -- cancel in-flight work; the matching arrival will retry this exact skin.
        self.serial+=1;self.template=nil
        if self.model then self.model:Destroy();self.model=nil end
        self.message.Visible=true;self.message.Text="MODELO INDISPONÍVEL\nAtualize os assets do arsenal."
        self.viewport:SetAttribute("ZO_PreviewStatus","Unavailable")
    end)
    return self
end

function Preview:setWeapon(id: string,skin: string?)
    local chosen=if WeaponSkins.valid(id,skin :: any) then skin else WeaponSkins.default(id)
    if self.destroyed or (self.id==id and self.skin==chosen) then return end
    self.id=id;self.skin=chosen;self.serial+=1
    self.template=nil
    local serial=self.serial
    if self.model then self.model:Destroy();self.model=nil end
    self.message.Visible=true;self.message.Text="CARREGANDO MODELO…"
    self.viewport:SetAttribute("ZO_PreviewStatus","Loading")
    self.viewport:SetAttribute("ZO_PreviewWeapon",id)
    self.viewport:SetAttribute("ZO_PreviewSkin",chosen)
    task.spawn(function()
        local deadline=os.clock()+10
        local template: Tool?=nil
        repeat
            if self.destroyed or self.serial~=serial then return end
            local assets=RS:FindFirstChild("ZO_WeaponAssets")
            template=WeaponSkins.resolve(assets,id,chosen)
            if template then self.template=template;break end
            task.wait(.1)
        until os.clock()>=deadline
        if self.destroyed or self.serial~=serial then return end
        if not template then
            self.message.Text="MODELO INDISPONÍVEL\nAtualize os assets do arsenal."
            self.viewport:SetAttribute("ZO_PreviewStatus","Unavailable")
            return
        end
        local model=Instance.new("Model");model.Name="PreviewWeapon"
        local clone=template:Clone()
        for _,item in clone:GetDescendants() do
            if item:IsA("LuaSourceContainer") or item:IsA("RemoteEvent") or item:IsA("RemoteFunction") then
                item:Destroy()
            elseif item:IsA("BasePart") then
                item.Anchored=true;item.CanCollide=false;item.CanQuery=false;item.CanTouch=false
                item.LocalTransparencyModifier=0;item.CastShadow=false
            elseif item:IsA("Sound") then item:Stop()
            elseif item:IsA("Beam") or item:IsA("Trail") or item:IsA("ParticleEmitter") then item.Enabled=false end
        end
        clone.Parent=model
        local center,size=visibleBounds(model)
        if not center or not size then
            model:Destroy();self.message.Text="MODELO SEM GEOMETRIA VISÍVEL"
            self.viewport:SetAttribute("ZO_PreviewStatus","Unavailable")
            return
        end
        model:PivotTo(CFrame.new(-center)*model:GetPivot())
        self.radius=math.max(.2,size.Magnitude*.5);self.angle=.18
        model.Parent=self.world;self.model=model
        self.message.Visible=false
        -- Ready means cloned native geometry; it is not an asset-permission test.
        self.viewport:SetAttribute("ZO_PreviewStatus","Ready")
    end)
end

function Preview:destroy()
    if self.destroyed then return end
    self.destroyed=true;self.serial+=1
    if self.render then self.render:Disconnect() end
    if self.removed then self.removed:Disconnect() end
    if self.assetAdded then self.assetAdded:Disconnect() end
    if self.assetRemoving then self.assetRemoving:Disconnect() end
    if self.model then self.model:Destroy() end
    self.world:Destroy();self.camera:Destroy()
end

return Preview
