--!strict
local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local player=Players.LocalPlayer
local gui=Instance.new("ScreenGui");gui.Name="ZO_RoundHUD";gui.ResetOnSpawn=false
gui.Parent=player:WaitForChild("PlayerGui")
local panel=Instance.new("TextLabel");panel.Name="RoundStatus"
panel.AnchorPoint=Vector2.new(.5,0);panel.Position=UDim2.new(.5,0,0,10);panel.Size=UDim2.new(.85,0,0,62)
panel.BackgroundTransparency=.4;panel.BackgroundColor3=Color3.fromRGB(14,17,17)
panel.TextColor3=Color3.fromRGB(232,219,182);panel.Font=Enum.Font.RobotoMono;panel.TextSize=15;panel.Parent=gui
local limit=Instance.new("UISizeConstraint");limit.MaxSize=Vector2.new(420,62);limit.Parent=panel
local names={Waiting="Aguardando jogadores",Intermission="Próxima rodada",Preparation="Prepare sua defesa",Active="Sobreviva",Results="Fim da rodada"}
local winners={Humans="Humanos venceram",Zombies="Zumbis venceram",Cancelled="Rodada cancelada"}
local function refresh()
    local state=RS:GetAttribute("ZO_RoundState") or "Waiting"
    if RunService:IsStudio() and #Players:GetPlayers()==1 and state=="Waiting" and workspace:GetAttribute("ZO_BarricadePractice")==true then
        panel.Text="TREINO SOLO\n"..(if player.Team and player.Team.Name=="Zombies" then "Ataque o alvo humano para infectar" else "Teste o fuzil e a recarga no alvo zumbi")
        return
    end
    local title=if state=="Results" then winners[RS:GetAttribute("ZO_LastWinner")] or names.Results else names[state] or state
    local seconds=RS:GetAttribute("ZO_Remaining") or 0
    panel.Text=("%s   %02d:%02d\nHUMANOS %d   |   ZUMBIS %d"):format(title,math.floor(seconds/60),seconds%60,RS:GetAttribute("ZO_Humans") or 0,RS:GetAttribute("ZO_Zombies") or 0)
end
for _,name in {"ZO_RoundState","ZO_Remaining","ZO_Humans","ZO_Zombies","ZO_LastWinner"} do RS:GetAttributeChangedSignal(name):Connect(refresh) end
workspace:GetAttributeChangedSignal("ZO_BarricadePractice"):Connect(refresh)
player:GetPropertyChangedSignal("Team"):Connect(refresh)
Players.PlayerAdded:Connect(refresh);Players.PlayerRemoving:Connect(function() task.defer(refresh) end)
refresh()
