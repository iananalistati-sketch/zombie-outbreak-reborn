--!strict
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui");gui.Name="ZO_RoundHUD";gui.ResetOnSpawn=false
gui.Parent=player:WaitForChild("PlayerGui")
local panel=Instance.new("TextLabel");panel.Name="RoundStatus"
panel.AnchorPoint=Vector2.new(.5,0);panel.Position=UDim2.new(.5,0,0,10);panel.Size=UDim2.new(.9,0,0,108)
panel.BackgroundTransparency=.4;panel.BackgroundColor3=Color3.fromRGB(14,17,17)
panel.TextColor3=Color3.fromRGB(232,219,182);panel.Font=Enum.Font.RobotoMono;panel.TextSize=14;panel.TextWrapped=true;panel.Parent=gui
local limit=Instance.new("UISizeConstraint");limit.MaxSize=Vector2.new(620,120);limit.Parent=panel
local names={Waiting="Aguardando jogadores",Intermission="Próxima rodada",Preparation="Prepare sua defesa",Active="Sobreviva",Results="Fim da rodada"}
local winners={Humans="Humanos venceram",Zombies="Zumbis venceram",Cancelled="Rodada cancelada"}
local function device(): string
    local input=UIS:GetLastInputType()
    if string.sub(input.Name,1,7)=="Gamepad" then return "Gamepad" end
    if input==Enum.UserInputType.Touch or (UIS.TouchEnabled and not UIS.KeyboardEnabled) then return "Touch" end
    return "Keyboard"
end
local function controls(zombie: boolean): string
    local input=device()
    if input=="Gamepad" then
        return if zombie then "RT atacar · View mapa" else "↑ arsenal · Y troca · X recarga · View mapa"
    elseif input=="Touch" then
        return if zombie then "Toque Atacar · Mapa" else "Toque Arsenal · Primária/Secundária · Recarregar · Mapa"
    end
    return if zombie then "Botão esquerdo atacar · M mapa" else "B arsenal · 1/2 ou Q troca · R recarga · M mapa"
end
local function credits(): number
    local value=player:GetAttribute("ZO_Credits")
    return if typeof(value)=="number" then math.max(0,math.floor(value)) else 0
end
local function refresh()
    local state=RS:GetAttribute("ZO_RoundState") or "Starting"
    local health=RS:GetAttribute("ZO_GameplayStatus")
    if health=="Error" or state=="Error" then
        panel.Size=UDim2.new(.9,0,0,120)
        panel.TextColor3=Color3.fromRGB(255,175,154)
        panel.Text="FALHA NO SERVIDOR — rodada interrompida\n"..tostring(RS:GetAttribute("ZO_GameplayError") or "Abra View > Output no servidor para ver o erro.")
        return
    end
    panel.TextColor3=Color3.fromRGB(232,219,182)
    panel.Size=UDim2.new(.9,0,0,108)
    if health=="Starting" or state=="Starting" then
        panel.Text="INICIANDO SOBREVIVÊNCIA\n"..tostring(RS:GetAttribute("ZO_StartupStep") or "Aguardando sinal do servidor…")
        return
    end
    if RunService:IsStudio() and #Players:GetPlayers()==1 and state=="Waiting" and workspace:GetAttribute("ZO_BarricadePractice")==true then
        local zombie=player.Team and player.Team.Name=="Zombies"
        panel.Text="TREINO SOLO\n"..(if zombie then "Ataque o alvo humano para infectar" else "Teste as armas e a recarga no alvo zumbi").."\n"..controls(zombie==true)
        return
    end
    if state=="Waiting" then
        local count=#Players:GetPlayers()
        local minimum=RS:GetAttribute("ZO_MinimumPlayers") or 2
        local ready=RS:GetAttribute("ZO_ReadyPlayers") or 0
        if count>=minimum then
            panel.Text=("CARREGANDO PERSONAGENS   %d/%d prontos\nA rodada começa automaticamente quando os personagens carregarem."):format(ready,minimum)
        else
            panel.Text=("AGUARDANDO JOGADORES   %d/%d\nCom %d jogadores prontos: intervalo → preparação → primeiro infectado."):format(count,minimum,minimum)
        end
        return
    end
    local title=if state=="Results" then winners[RS:GetAttribute("ZO_LastWinner")] or names.Results else names[state] or state
    local seconds=RS:GetAttribute("ZO_Remaining") or 0
    local zombie=player.Team and player.Team.Name=="Zombies"
    local human=player.Team and player.Team.Name=="Humans"
    local playing=state=="Preparation" or state=="Active"
    local instruction=if state=="Preparation" then ("Infecção ao final · CRÉDITOS %d"):format(credits())
        elseif state=="Intermission" then "Rodada confirmada · aguarde a preparação"
        elseif zombie then "ZUMBI · infecte os humanos e rompa as barricadas"
        elseif human then ("HUMANO · CRÉDITOS %d"):format(credits())
        else "Aguardando a próxima rodada"
    local hint=if playing and (human or zombie) then "\n"..controls(zombie==true) else ""
    local warning=if health=="Degraded" then "\nBarricadas incompletas — veja Output do servidor" else ""
    panel.Size=UDim2.new(.9,0,0,if warning~="" then 120 else 108)
    panel.Text=("%s   %02d:%02d\nHUMANOS %d   |   ZUMBIS %d\n%s%s%s"):format(title,math.floor(seconds/60),seconds%60,RS:GetAttribute("ZO_Humans") or 0,RS:GetAttribute("ZO_Zombies") or 0,instruction,hint,warning)
end
for _,name in {"ZO_RoundState","ZO_Remaining","ZO_Humans","ZO_Zombies","ZO_LastWinner","ZO_GameplayStatus","ZO_GameplayError","ZO_StartupStep","ZO_ReadyPlayers","ZO_MinimumPlayers"} do RS:GetAttributeChangedSignal(name):Connect(refresh) end
workspace:GetAttributeChangedSignal("ZO_BarricadePractice"):Connect(refresh)
player:GetPropertyChangedSignal("Team"):Connect(refresh)
player:GetAttributeChangedSignal("ZO_Credits"):Connect(refresh)
UIS.LastInputTypeChanged:Connect(refresh)
Players.PlayerAdded:Connect(refresh);Players.PlayerRemoving:Connect(function() task.defer(refresh) end)
refresh()
task.delay(15,function()
    if RS:GetAttribute("ZO_RoundState")==nil then
        panel.Text="SEM SINAL DO SERVIDOR\nO controlador K-17 não iniciou. Abra View > Output no servidor e envie o primeiro erro vermelho."
    end
end)
