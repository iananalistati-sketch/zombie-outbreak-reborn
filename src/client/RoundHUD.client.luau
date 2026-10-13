--!strict
-- Interface local: estado replicado pelo servidor, sem controles de equipe no cliente
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "ZO_RoundHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "RoundPanel"
panel.Size = UDim2.fromOffset(360, 100)
panel.Position = UDim2.new(0.5, -180, 0, 28)
panel.BackgroundColor3 = Color3.fromRGB(15, 22, 31)
panel.BackgroundTransparency = 0.09
panel.BorderSizePixel = 0
panel.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = panel

local function label(name: string, y: number, height: number, size: number): TextLabel
    local t = Instance.new("TextLabel")
    t.Name = name
    t.BackgroundTransparency = 1
    t.Size = UDim2.new(1, -16, 0, height)
    t.Position = UDim2.fromOffset(8, y)
    t.Font = Enum.Font.GothamBold
    t.TextSize = size
    t.TextColor3 = Color3.fromRGB(225, 234, 242)
    t.TextXAlignment = Enum.TextXAlignment.Center
    t.Parent = panel
    return t
end
local stateLabel = label("State", 12, 21, 16)
local timerLabel = label("Timer", 35, 29, 23)
local scoreLabel = label("Teams", 70, 22, 13)
timerLabel.TextColor3 = Color3.fromRGB(242, 192, 80)

local names = {
    Waiting = "Aguardando jogadores",
    Intermission = "Intervalo",
    Preparation = "Prepare-se",
    Active = "Sobreviva!",
    Results = "Fim da rodada",
}
local function refresh()
    local state = ReplicatedStorage:GetAttribute("ZO_RoundState") or "Waiting"
    local seconds = ReplicatedStorage:GetAttribute("ZO_Remaining") or 0
    local h = ReplicatedStorage:GetAttribute("ZO_Humans") or 0
    local z = ReplicatedStorage:GetAttribute("ZO_Zombies") or 0
    stateLabel.Text = names[state] or tostring(state)
    if state == "Results" then
        local winner = ReplicatedStorage:GetAttribute("ZO_LastWinner")
        stateLabel.Text = "Resultado: " .. tostring(winner or "—")
    end
    timerLabel.Text = string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
    scoreLabel.Text = string.format("HUMANOS: %d   |   ZUMBIS: %d", h, z)
end
for _, name in ipairs({"ZO_RoundState", "ZO_Remaining", "ZO_Humans", "ZO_Zombies", "ZO_LastWinner"}) do
    ReplicatedStorage:GetAttributeChangedSignal(name):Connect(refresh)
end
refresh()
print("[Zombie Outbreak] Round HUD online")
