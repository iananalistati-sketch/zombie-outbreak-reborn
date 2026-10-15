--!strict
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui");gui.Name="ZO_RoundHUD";gui.ResetOnSpawn=false
gui.Parent=player:WaitForChild("PlayerGui")
local panel=Instance.new("TextLabel");panel.Name="RoundStatus"
panel.AnchorPoint=Vector2.new(.5,0);panel.Position=UDim2.new(.5,0,0,10);panel.Size=UDim2.new(.9,0,0,84)
panel.BackgroundTransparency=.4;panel.BackgroundColor3=Color3.fromRGB(14,17,17)
panel.TextColor3=Color3.fromRGB(232,219,182);panel.Font=Enum.Font.RobotoMono;panel.TextSize=14;panel.TextWrapped=true;panel.Parent=gui
local limit=Instance.new("UISizeConstraint");limit.MaxSize=Vector2.new(620,120);limit.Parent=panel
local names={Waiting="Aguardando jogadores",Intermission="Próxima rodada",Preparation="Prepare sua defesa",Active="Sobreviva",Results="Fim da rodada"}
local winners={Humans="Humanos venceram",Zombies="Zumbis venceram",Cancelled="Rodada cancelada"}
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
    panel.Size=UDim2.new(.9,0,0,84)
    if health=="Starting" or state=="Starting" then
        panel.Text="INICIANDO SOBREVIVÊNCIA\n"..tostring(RS:GetAttribute("ZO_StartupStep") or "Aguardando sinal do servidor…")
        return
    end
    if RunService:IsStudio() and #Players:GetPlayers()==1 and state=="Waiting" and workspace:GetAttribute("ZO_BarricadePractice")==true then
        panel.Text="TREINO SOLO\n"..(if player.Team and player.Team.Name=="Zombies" then "Ataque o alvo humano para infectar" else "Teste o fuzil e a recarga no alvo zumbi")
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
    local instruction=if state=="Preparation" then "Todos humanos · primeiro infectado ao fim da preparação"
        elseif state=="Intermission" then "Rodada confirmada · aguarde a preparação"
        elseif player.Team and player.Team.Name=="Zombies" then "ZUMBI · ataque com botão esquerdo para infectar"
        elseif player.Team and player.Team.Name=="Humans" then "HUMANO · botão esquerdo dispara · R recarrega"
        else "Aguardando a próxima rodada"
    local warning=if health=="Degraded" then "\nBarricadas incompletas — veja Output do servidor" else ""
    panel.Text=("%s   %02d:%02d\nHUMANOS %d   |   ZUMBIS %d\n%s%s"):format(title,math.floor(seconds/60),seconds%60,RS:GetAttribute("ZO_Humans") or 0,RS:GetAttribute("ZO_Zombies") or 0,instruction,warning)
end
for _,name in {"ZO_RoundState","ZO_Remaining","ZO_Humans","ZO_Zombies","ZO_LastWinner","ZO_GameplayStatus","ZO_GameplayError","ZO_StartupStep","ZO_ReadyPlayers","ZO_MinimumPlayers"} do RS:GetAttributeChangedSignal(name):Connect(refresh) end
workspace:GetAttributeChangedSignal("ZO_BarricadePractice"):Connect(refresh)
player:GetPropertyChangedSignal("Team"):Connect(refresh)
Players.PlayerAdded:Connect(refresh);Players.PlayerRemoving:Connect(function() task.defer(refresh) end)
refresh()
task.delay(15,function()
    if RS:GetAttribute("ZO_RoundState")==nil then
        panel.Text="SEM SINAL DO SERVIDOR\nO controlador K-17 não iniciou. Abra View > Output no servidor e envie o primeiro erro vermelho."
    end
end)
