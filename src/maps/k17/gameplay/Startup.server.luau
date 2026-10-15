--!strict
-- Independent watchdog: a broken round/combat script must not look like an empty lobby.
local RS=game:GetService("ReplicatedStorage")
local ScriptContext=game:GetService("ScriptContext")
local function status()
    if RS:GetAttribute("ZO_GameplayStatus")=="Error" then return end
    local round=RS:GetAttribute("ZO_GameplayRoundReady")==true
    local combat=RS:GetAttribute("ZO_GameplayCombatReady")==true
    local barricades=RS:GetAttribute("ZO_BarricadesReady")==true
    if round and combat then
        RS:SetAttribute("ZO_GameplayStatus",if barricades then "Ready" else "Degraded")
    else RS:SetAttribute("ZO_GameplayStatus","Starting") end
end
local function failure(name: string,message: string)
    local detail=(name..": "..message):sub(1,1500)
    if name=="Barricades" then
        -- A missing prop must not freeze infection/rounds. Its own controller reports counts.
        RS:SetAttribute("ZO_BarricadeStartupError",detail)
        RS:SetAttribute("ZO_BarricadesReady",false)
        status()
        return
    end
    RS:SetAttribute("ZO_GameplayError",detail)
    RS:SetAttribute("ZO_GameplayStatus","Error")
    RS:SetAttribute("ZO_RoundState","Error")
    warn("[K17] Gameplay startup/runtime failure: "..detail)
end
ScriptContext.Error:Connect(function(message: string,stack: string,source: Instance?)
    if not source or (source.Name~="ZombieRound" and source.Name~="Combat" and source.Name~="Barricades") then return end
    failure(source.Name,message.."\n"..stack)
end)
for _,name in {"ZO_GameplayRoundReady","ZO_GameplayCombatReady","ZO_BarricadesReady"} do
    RS:GetAttributeChangedSignal(name):Connect(status)
end
status()
task.delay(22,function()
    if RS:GetAttribute("ZO_GameplayStatus")=="Error" then return end
    local missing={}
    if RS:GetAttribute("ZO_GameplayCombatReady")~=true then table.insert(missing,"Combat") end
    if RS:GetAttribute("ZO_GameplayRoundReady")~=true then table.insert(missing,"ZombieRound") end
    if #missing>0 then failure("Startup","Controladores sem sinal de pronto após 22s: "..table.concat(missing,", ")) end
end)
