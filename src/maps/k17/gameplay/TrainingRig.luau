--!strict
-- Reuse the already-loaded player rig/outfit. No asset download or API key.
local Rig={}
function Rig.new(template: Model,at: CFrame,health: number,speed: number): Model
    local previous=template.Archivable
    template.Archivable=true
    local ok,result=pcall(function() return template:Clone() end)
    template.Archivable=previous
    assert(ok and result,"Não foi possível copiar o rig do personagem para o treino")
    local model=result :: Model
    for _,item in model:GetDescendants() do
        if item:IsA("LuaSourceContainer") or item:IsA("Tool") or item:IsA("ForceField")
            or item:IsA("Highlight") or item:IsA("BillboardGui") then item:Destroy() end
    end
    for _,item in model:GetChildren() do
        if item:IsA("Model") then item:Destroy() end -- carried weapon/world models
    end
    local root=model:FindFirstChild("HumanoidRootPart")
    local hum=model:FindFirstChildOfClass("Humanoid")
    assert(root and root:IsA("BasePart") and hum,"Rig de treino incompleto")
    for _,item in model:GetDescendants() do
        if item:IsA("Motor6D") then
            local standing=item:GetAttribute("ZO_StandingC0")
            if typeof(standing)=="CFrame" then item.C0=standing end
            item.Transform=CFrame.identity
        end
        if item:IsA("BasePart") then
            item.Anchored=false;item.CollisionGroup="Default"
            if item.Name~="HumanoidRootPart" and item.Parent==model then
                item.Color=Color3.fromRGB(112,130,104)
            end
        end
    end
    model.Name="Infectado de treino";model:SetAttribute("ZO_PracticeRole","Zombies")
    model:SetAttribute("ZO_TrainingEnemy",true)
    hum.MaxHealth=health;hum.Health=health;hum.WalkSpeed=speed
    hum.DisplayName="Infectado";hum.AutoRotate=true;hum.PlatformStand=false;hum.Sit=false;hum.Jump=false
    hum.BreakJointsOnDeath=false
    model.PrimaryPart=root;model:PivotTo(at)
    root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
    return model
end
return table.freeze(Rig)
