-- =============================================
--    🌑 DARKWEB | SAILOR PIECE ULTIMATE v10.1
--    Premium UI | Fully Functional
--    Loadstring Ready
-- =============================================

--[[
    ✅ COMPLETE FEATURES:
    ⚔️ Auto Farm | Kill Aura | Auto Skill | Auto Quest
    🌾 Fruit Sniper | Auto Stats
    🗺️ 9 Island Teleports
    ⚙️ Fly Mode | Noclip | Infinite Jump | Auto Heal | Auto Block
    👁️ ESP System (Enemies & Fruits)
    📊 Real-time Stats
--]]

-- SERVICES & VARIABLES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local LP = Players.LocalPlayer

-- Character Setup
local Character = LP.Character or LP.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

LP.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = Character:WaitForChild("Humanoid")
    RootPart = Character:WaitForChild("HumanoidRootPart")
end)

-- QUEST DATABASE
local Quests = {
    {levelMin = 0, levelMax = 249, island = "Starter Island", coords = {x = 0, y = 50, z = 0}, mobType = "Bandit", requiredKills = 15},
    {levelMin = 250, levelMax = 499, island = "Jungle Island", coords = {x = -500, y = 50, z = -300}, mobType = "Monkey", requiredKills = 20},
    {levelMin = 500, levelMax = 999, island = "Desert Island", coords = {x = -800, y = 50, z = 1200}, mobType = "Bandit", requiredKills = 25},
    {levelMin = 1000, levelMax = 1999, island = "Snow Island", coords = {x = 500, y = 70, z = 800}, mobType = "Snow Beast", requiredKills = 30},
    {levelMin = 2000, levelMax = 3999, island = "Shibuya Station", coords = {x = 1000, y = 50, z = 500}, mobType = "Sorcerer", requiredKills = 35},
    {levelMin = 4000, levelMax = 5999, island = "Hueco Mundo", coords = {x = 0, y = 50, z = 0}, mobType = "Hollow", requiredKills = 40},
    {levelMin = 6000, levelMax = 7999, island = "Shinjuku Island", coords = {x = -500, y = 50, z = 1800}, mobType = "Yakuza", requiredKills = 45},
    {levelMin = 8000, levelMax = 99999, island = "Academy Island", coords = {x = 2500, y = 50, z = 1500}, mobType = "Guard", requiredKills = 50},
}

-- SETTINGS
local Settings = {
    AutoFarm = false, KillAura = false, AutoQuest = true, AutoSkill = false,
    FarmRadius = 50, AuraRadius = 40, AttackDelay = 0.08,
    WalkSpeed = 48, JumpPower = 50, InfiniteJump = false, FlyMode = false, Noclip = false,
    AutoHeal = false, HealPercent = 50, AutoBlock = false,
    FruitSniper = false, AutoStats = false, SelectedStat = "Strength",
    ESPEnabled = false, ESPMode = "Box", AntiAFK = true,
}

-- State
local CurrentQuest = nil
local QuestKillCount = 0
local LastQuestCompletion = 0
local ESPObjects = {}
local flyActive = false
local flyBodyVelocity, flyBodyGyro = nil, nil

-- Stats
local Stats = {
    TotalKills = 0, QuestsCompleted = 0, MoneyEarned = 0,
    GemsEarned = 0, FruitsFound = 0, StartTime = os.time(),
}

-- UTILITY FUNCTIONS
local function GetPlayerLevel()
    local stats = LP:FindFirstChild("leaderstats")
    if stats and stats:FindFirstChild("Level") then return stats.Level.Value end
    return 0
end

local function Teleport(pos)
    pcall(function()
        if type(pos) == "table" then
            RootPart.CFrame = CFrame.new(pos.x or 0, pos.y or 50, pos.z or 0)
        else
            RootPart.CFrame = CFrame.new(pos)
        end
    end)
end

local function InteractWithNPC(npc)
    pcall(function()
        if npc and npc:FindFirstChild("HumanoidRootPart") then
            RootPart.CFrame = CFrame.new(RootPart.Position, npc.HumanoidRootPart.Position)
        end
        local dialogueRemote = ReplicatedStorage:FindFirstChild("Dialogue")
        if dialogueRemote then dialogueRemote:FireServer(npc) end
        local clickRemote = ReplicatedStorage:FindFirstChild("Click")
        if clickRemote then clickRemote:FireServer(npc) end
    end)
end

-- QUEST SYSTEM
local function GetBestQuestForLevel()
    local level = GetPlayerLevel()
    for _, quest in pairs(Quests) do
        if level >= quest.levelMin and level <= quest.levelMax then return quest end
    end
    return Quests[#Quests]
end

local function AcceptQuest()
    local quest = GetBestQuestForLevel()
    if not quest then return false end
    Teleport(quest.coords)
    wait(2)
    local questNPC = nil
    for _, v in pairs(Workspace:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") then
            if v.Name:lower():find("quest") or v.Name:lower():find("npc") then
                questNPC = v; break
            end
        end
    end
    if questNPC then
        Humanoid:MoveTo(questNPC.HumanoidRootPart.Position)
        wait(1.5)
        InteractWithNPC(questNPC)
        wait(1.5)
        CurrentQuest = quest
        QuestKillCount = 0
        return true
    end
    return false
end

local function CompleteQuest()
    if not CurrentQuest then return false end
    local questNPC = nil
    for _, v in pairs(Workspace:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("Head") then
            if v.Name:lower():find("quest") then
                questNPC = v; break
            end
        end
    end
    if questNPC then
        Humanoid:MoveTo(questNPC.HumanoidRootPart.Position)
        wait(1.5)
        InteractWithNPC(questNPC)
        wait(1.5)
        Stats.QuestsCompleted = Stats.QuestsCompleted + 1
        CurrentQuest = nil
        LastQuestCompletion = tick()
        return true
    end
    return false
end

-- ENEMY DETECTION & COMBAT
local function GetAllEnemies(radius)
    local enemies, charPos = {}, RootPart.Position
    for _, v in pairs(Workspace:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") and v.Humanoid.Health > 0 and v ~= Character then
            local isPlayer = false
            for _, player in pairs(Players:GetPlayers()) do
                if player.Character == v then isPlayer = true; break end
            end
            if not isPlayer then
                local distance = (charPos - v.HumanoidRootPart.Position).Magnitude
                if not radius or distance <= radius then
                    table.insert(enemies, {
                        Object = v, Distance = distance, Name = v.Name,
                        Health = v.Humanoid.Health, IsQuestTarget = CurrentQuest and v.Name:lower():find(CurrentQuest.mobType:lower()) or false,
                    })
                end
            end
        end
    end
    table.sort(enemies, function(a, b)
        if a.IsQuestTarget ~= b.IsQuestTarget then return a.IsQuestTarget end
        return a.Distance < b.Distance
    end)
    return enemies
end

local function GetBestTarget(radius)
    local enemies = GetAllEnemies(radius)
    return #enemies > 0 and enemies[1].Object or nil
end

local function Attack(target)
    if not target or not target.Parent or not target:FindFirstChild("Humanoid") then return false end
    pcall(function()
        RootPart.CFrame = CFrame.new(RootPart.Position, target.HumanoidRootPart.Position)
        local tool = Character:FindFirstChildOfClass("Tool")
        if tool then tool:Activate() end
        local combatRemote = ReplicatedStorage:FindFirstChild("CombatRemote")
        if combatRemote then combatRemote:FireServer(target, "Attack") end
        local clickRemote = ReplicatedStorage:FindFirstChild("Click")
        if clickRemote then clickRemote:FireServer(target.HumanoidRootPart) end
    end)
    Stats.TotalKills = Stats.TotalKills + 1
    return true
end

local function UseSkill(key)
    pcall(function()
        local skillRemote = ReplicatedStorage:FindFirstChild("UseSkill")
        if skillRemote then skillRemote:FireServer(key) end
        local VirtualInput = game:GetService("VirtualInputManager")
        VirtualInput:SendKeyEvent(true, key, false, game)
        wait(0.05)
        VirtualInput:SendKeyEvent(false, key, false, game)
    end)
end

-- HEAL & BLOCK
local function Heal()
    pcall(function()
        local healItems = {"Potion", "Food", "Apple", "Bread", "Meat", "Health Potion"}
        for _, itemName in pairs(healItems) do
            local item = Character:FindFirstChild(itemName)
            if item and item:IsA("Tool") then item:Activate(); return true end
        end
        return false
    end)
end

local function Block()
    pcall(function()
        local blockRemote = ReplicatedStorage:FindFirstChild("Block")
        if blockRemote then blockRemote:FireServer() end
    end)
end

-- AUTO STATS
local function UpgradeStat()
    pcall(function()
        local statRemote = ReplicatedStorage:FindFirstChild("UpgradeStat")
        if statRemote then statRemote:FireServer(Settings.SelectedStat) end
    end)
end

-- FRUIT SNIPER
local function CheckForFruits()
    pcall(function()
        for _, v in pairs(Workspace:GetDescendants()) do
            local name = v.Name:lower()
            if name:find("fruit") or name:find("devil") then
                if v:IsA("BasePart") or v:IsA("Model") then
                    local pos = v:IsA("BasePart") and v.Position or (v:FindFirstChild("Handle") and v.Handle.Position) or (v:FindFirstChild("Part") and v.Part.Position)
                    if pos then Teleport(pos); Stats.FruitsFound = Stats.FruitsFound + 1; wait(0.5) end
                end
            end
        end
    end)
end

-- ESP SYSTEM
local function CreateESP(obj, color, name)
    if not Settings.ESPEnabled then return nil end
    local espGroup = {}
    if Settings.ESPMode == "Box" or Settings.ESPMode == "Both" then
        local highlight = Instance.new("Highlight")
        highlight.Parent = obj
        highlight.FillColor = color
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0.2
        highlight.Adornee = obj
        table.insert(espGroup, highlight)
    end
    if Settings.ESPMode == "Name Only" or Settings.ESPMode == "Both" then
        local head = obj:FindFirstChild("Head") or obj:FindFirstChild("HumanoidRootPart")
        if head then
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "ESP_Billboard"
            billboard.Parent = head
            billboard.Size = UDim2.new(0, 200, 0, 30)
            billboard.StudsOffset = Vector3.new(0, 2.5, 0)
            billboard.AlwaysOnTop = true
            local textLabel = Instance.new("TextLabel")
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.Text = name
            textLabel.TextColor3 = color
            textLabel.Font = Enum.Font.GothamBold
            textLabel.TextSize = 14
            textLabel.Parent = billboard
            table.insert(espGroup, billboard)
        end
    end
    return espGroup
end

-- ESP Loop
spawn(function()
    while true do
        if Settings.ESPEnabled then
            for _, espGroup in pairs(ESPObjects) do
                for _, esp in pairs(espGroup) do pcall(function() esp:Destroy() end) end
            end
            ESPObjects = {}
            local enemies = GetAllEnemies(200)
            for _, enemy in pairs(enemies) do
                local hpPercent = (enemy.Object.Humanoid.Health / enemy.Object.Humanoid.MaxHealth) * 100
                local color = hpPercent > 70 and Color3.fromRGB(0, 255, 0) or hpPercent > 30 and Color3.fromRGB(255, 255, 0) or Color3.fromRGB(255, 0, 0)
                local espGroup = CreateESP(enemy.Object, color, enemy.Object.Name)
                if espGroup then table.insert(ESPObjects, espGroup) end
            end
            for _, v in pairs(Workspace:GetDescendants()) do
                if v.Name:lower():find("fruit") and (v:IsA("BasePart") or v:IsA("Model")) then
                    local espGroup = CreateESP(v, Color3.fromRGB(255, 100, 0), "🍎 " .. v.Name)
                    if espGroup then table.insert(ESPObjects, espGroup) end
                end
            end
        else
            for _, espGroup in pairs(ESPObjects) do
                for _, esp in pairs(espGroup) do pcall(function() esp:Destroy() end) end
            end
            ESPObjects = {}
        end
        wait(0.5)
    end
end)

-- MAIN LOOPS
spawn(function()
    while true do
        if Settings.AutoFarm and Character and Humanoid and Humanoid.Health > 0 then
            if Settings.AutoQuest then
                if not CurrentQuest and (tick() - LastQuestCompletion) >= 5 then AcceptQuest() end
                if CurrentQuest and QuestKillCount >= CurrentQuest.requiredKills then CompleteQuest(); wait(2); AcceptQuest() end
            end
            local target = GetBestTarget(Settings.FarmRadius)
            if target then
                Humanoid:MoveTo(target.HumanoidRootPart.Position)
                if (RootPart.Position - target.HumanoidRootPart.Position).Magnitude <= 12 then
                    Attack(target)
                    if CurrentQuest and target.Name:lower():find(CurrentQuest.mobType:lower()) then QuestKillCount = QuestKillCount + 1 end
                    if Settings.AutoSkill then UseSkill("Z"); wait(0.2); UseSkill("X"); wait(0.2); UseSkill("C") end
                end
                wait(Settings.AttackDelay)
            else wait(0.5) end
        end
        wait()
    end
end)

spawn(function()
    while true do
        if Settings.KillAura and Character and Humanoid and Humanoid.Health > 0 then
            local target = GetBestTarget(Settings.AuraRadius)
            if target then Attack(target) end
            wait(0.15)
        end
        wait()
    end
end)

spawn(function()
    while true do
        if Settings.AutoHeal and Character and Humanoid then
            if (Humanoid.Health / Humanoid.MaxHealth) * 100 <= Settings.HealPercent then Heal() end
        end
        wait(1)
    end
end)

spawn(function()
    while true do
        if Settings.AutoBlock and Character and Humanoid and Humanoid.Health > 0 then
            if GetBestTarget(15) then Block() end
        end
        wait(0.5)
    end
end)

spawn(function()
    while true do
        if Settings.AutoStats then UpgradeStat() end
        wait(2)
    end
end)

spawn(function()
    while true do
        if Settings.FruitSniper then CheckForFruits() end
        wait(0.8)
    end
end)

-- MOVEMENT MODS
spawn(function()
    while true do
        pcall(function() Humanoid.WalkSpeed = Settings.WalkSpeed; Humanoid.JumpPower = Settings.JumpPower end)
        if Settings.InfiniteJump then
            UserInputService.JumpRequest:Connect(function()
                if Humanoid then Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
        end
        if Settings.FlyMode then
            if not flyActive then
                flyActive = true
                flyBodyVelocity = Instance.new("BodyVelocity")
                flyBodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
                flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
                flyBodyVelocity.Parent = RootPart
                flyBodyGyro = Instance.new("BodyGyro")
                flyBodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
                flyBodyGyro.CFrame = RootPart.CFrame
                flyBodyGyro.Parent = RootPart
            end
            local dir = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Vector3.new(0, 0, -1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir + Vector3.new(0, 0, 1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir + Vector3.new(-1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Vector3.new(1, 0, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir + Vector3.new(0, -1, 0) end
            if dir.Magnitude > 0 then
                dir = dir.Unit
                flyBodyVelocity.Velocity = dir * (Settings.WalkSpeed * 1.5)
                flyBodyGyro.CFrame = CFrame.new(RootPart.Position, RootPart.Position + dir)
            else
                flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
            end
        else
            if flyActive then
                flyActive = false
                if flyBodyVelocity then flyBodyVelocity:Destroy(); flyBodyVelocity = nil end
                if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
            end
        end
        if Settings.Noclip then
            for _, part in pairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
        wait(0.1)
    end
end)

-- ANTI-AFK
spawn(function()
    while true do
        if Settings.AntiAFK then
            pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
        end
        wait(60)
    end
end)

-- =============================================
-- PREMIUM UI CREATION
-- =============================================
local gui = Instance.new("ScreenGui")
gui.Name = "DarkwebUI"
gui.ResetOnSpawn = false
gui.Parent = LP:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 580, 0, 660)
mainFrame.Position = UDim2.new(0.5, -290, 0.5, -330)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Parent = gui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 20)
local mainGradient = Instance.new("UIGradient", mainFrame)
mainGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 15, 35)), ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 8, 25))}
mainGradient.Rotation = 90

local glowStroke = Instance.new("UIStroke", mainFrame)
glowStroke.Color = Color3.fromRGB(100, 0, 200)
glowStroke.Transparency = 0.5
glowStroke.Thickness = 2

-- Header
local header = Instance.new("Frame", mainFrame)
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundTransparency = 1

local title = Instance.new("TextLabel", header)
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.new(0, 20, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🌑 DARKWEB | SAILOR PIECE"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(200, 100, 255)

local subtitle = Instance.new("TextLabel", header)
subtitle.Size = UDim2.new(1, -60, 0.5, 0)
subtitle.Position = UDim2.new(0, 20, 0.6, 0)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Premium Auto Farm | Level-Based Quests"
subtitle.Font = Enum.Font.Gotham
subtitle.TextSize = 11
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.TextColor3 = Color3.fromRGB(150, 100, 200)

-- Close Button
local closeBtn = Instance.new("TextButton", mainFrame)
closeBtn.Size = UDim2.new(0, 36, 0, 36)
closeBtn.Position = UDim2.new(1, -46, 0, 7)
closeBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 150)
closeBtn.Text = "✕"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.AutoButtonColor = false
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

-- Status Bar
local statusBar = Instance.new("Frame", mainFrame)
statusBar.Size = UDim2.new(1, -20, 0, 40)
statusBar.Position = UDim2.new(0, 10, 0, 58)
statusBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
statusBar.BackgroundTransparency = 0.5
Instance.new("UICorner", statusBar).CornerRadius = UDim.new(0, 12)

local function CreateStatusItem(text, icon, xPos)
    local frame = Instance.new("Frame", statusBar)
    frame.Size = UDim2.new(0, 120, 1, 0)
    frame.Position = UDim2.new(0, xPos, 0, 0)
    frame.BackgroundTransparency = 1
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = icon .. " " .. text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    return label
end

local levelLabel = CreateStatusItem("Loading...", "⭐", 5)
local moneyLabel = CreateStatusItem("Loading...", "💰", 130)
local gemsLabel = CreateStatusItem("Loading...", "💎", 255)
local fpsLabel = CreateStatusItem("0 FPS", "⚡", 380)

spawn(function()
    while true do
        pcall(function()
            local stats = LP:FindFirstChild("leaderstats")
            if stats then
                levelLabel.Text = "⭐ " .. (stats:FindFirstChild("Level") and stats.Level.Value or 0)
                moneyLabel.Text = "💰 $" .. (stats:FindFirstChild("Money") and stats.Money.Value or 0)
                gemsLabel.Text = "💎 " .. (stats:FindFirstChild("Gems") and stats.Gems.Value or 0)
            end
        end)
        fpsLabel.Text = "⚡ " .. math.floor(1 / wait() + 0.5) .. " FPS"
        wait(2)
    end
end)

-- Tabs
local tabContainer = Instance.new("Frame", mainFrame)
tabContainer.Size = UDim2.new(1, -20, 0, 40)
tabContainer.Position = UDim2.new(0, 10, 0, 105)
tabContainer.BackgroundTransparency = 1

local tabs = {}
local function CreateTab(name, xPos)
    local btn = Instance.new("TextButton", tabContainer)
    btn.Size = UDim2.new(0, 80, 1, 0)
    btn.Position = UDim2.new(0, xPos, 0, 0)
    btn.BackgroundTransparency = 1
    btn.Text = name
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(150, 150, 180)
    btn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do
            if t.btn then t.btn.TextColor3 = Color3.fromRGB(150, 150, 180) end
            if t.content then t.content.Visible = false end
        end
        btn.TextColor3 = Color3.fromRGB(150, 0, 200)
        if tabs[name] and tabs[name].content then tabs[name].content.Visible = true end
    end)
    tabs[name] = {btn = btn, content = nil}
    return btn
end

CreateTab("⚔️ Combat", 0)
CreateTab("🌾 Farming", 85)
CreateTab("🗺️ Teleports", 170)
CreateTab("⚙️ Utility", 255)
CreateTab("📊 Stats", 340)
CreateTab("ℹ️ Info", 425)

-- Content Container
local contentContainer = Instance.new("ScrollingFrame", mainFrame)
contentContainer.Size = UDim2.new(1, -20, 1, -160)
contentContainer.Position = UDim2.new(0, 10, 0, 150)
contentContainer.BackgroundTransparency = 1
contentContainer.BorderSizePixel = 0
contentContainer.ScrollBarThickness = 6
contentContainer.ScrollBarImageColor3 = Color3.fromRGB(150, 0, 200)
local contentLayout = Instance.new("UIListLayout", contentContainer)
contentLayout.Padding = UDim.new(0, 12)
contentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    contentContainer.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 20)
end)

-- UI Helper Functions
local function CreateCard(parent, height)
    local card = Instance.new("Frame", parent)
    card.Size = UDim2.new(1, 0, 0, height)
    card.BackgroundColor3 = Color3.fromRGB(20, 15, 35)
    card.BackgroundTransparency = 0.3
    card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
    return card
end

local function CreateToggle(parent, text, default, callback)
    local card = CreateCard(parent, 48)
    local label = Instance.new("TextLabel", card)
    label.Size = UDim2.new(1, -100, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(230, 220, 255)
    local toggleBtn = Instance.new("Frame", card)
    toggleBtn.Size = UDim2.new(0, 50, 0, 26)
    toggleBtn.Position = UDim2.new(1, -65, 0.5, -13)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 13)
    local dot = Instance.new("Frame", toggleBtn)
    dot.Size = UDim2.new(0, 20, 0, 20)
    dot.Position = UDim2.new(0, 3, 0.5, -10)
    dot.BackgroundColor3 = Color3.fromRGB(120, 100, 150)
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    local state = default
    local function UpdateUI()
        if state then
            toggleBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 200)
            dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            dot.Position = UDim2.new(1, -23, 0.5, -10)
        else
            toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
            dot.BackgroundColor3 = Color3.fromRGB(120, 100, 150)
            dot.Position = UDim2.new(0, 3, 0.5, -10)
        end
    end
    toggleBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            state = not state
            UpdateUI()
            callback(state)
        end
    end)
    UpdateUI()
    return card
end

local function CreateSlider(parent, text, min, max, default, callback)
    local card = CreateCard(parent, 66)
    local label = Instance.new("TextLabel", card)
    label.Size = UDim2.new(1, -70, 0, 24)
    label.Position = UDim2.new(0, 15, 0, 8)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(230, 220, 255)
    local valueLabel = Instance.new("TextLabel", card)
    valueLabel.Size = UDim2.new(0, 50, 0, 24)
    valueLabel.Position = UDim2.new(1, -65, 0, 8)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(default)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextSize = 13
    valueLabel.TextColor3 = Color3.fromRGB(150, 0, 200)
    local bar = Instance.new("Frame", card)
    bar.Size = UDim2.new(1, -30, 0, 6)
    bar.Position = UDim2.new(0, 15, 0, 46)
    bar.BackgroundColor3 = Color3.fromRGB(35, 25, 55)
    Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(150, 0, 200)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    local dragging = false
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            local value = math.floor(min + (max - min) * rel)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            valueLabel.Text = tostring(value)
            callback(value)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    return card
end

local function CreateButton(parent, text, callback)
    local card = CreateCard(parent, 44)
    local btn = Instance.new("TextButton", card)
    btn.Size = UDim2.new(1, -30, 1, -8)
    btn.Position = UDim2.new(0, 15, 0, 4)
    btn.BackgroundColor3 = Color3.fromRGB(100, 0, 150)
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(150, 0, 200)}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(100, 0, 150)}):Play()
    end)
    btn.MouseButton1Click:Connect(callback)
    return card
end

local function CreateLabel(parent, text)
    local card = CreateCard(parent, 32)
    local label = Instance.new("TextLabel", card)
    label.Size = UDim2.new(1, -30, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(200, 190, 220)
    return card
end

local function CreateParagraph(parent, title, content)
    local card = CreateCard(parent, 60)
    local titleLabel = Instance.new("TextLabel", card)
    titleLabel.Size = UDim2.new(1, -30, 0, 20)
    titleLabel.Position = UDim2.new(0, 15, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextColor3 = Color3.fromRGB(150, 0, 200)
    local contentLabel = Instance.new("TextLabel", card)
    contentLabel.Size = UDim2.new(1, -30, 0, 32)
    contentLabel.Position = UDim2.new(0, 15, 0, 30)
    contentLabel.BackgroundTransparency = 1
    contentLabel.Text = content
    contentLabel.Font = Enum.Font.Gotham
    contentLabel.TextSize = 11
    contentLabel.TextXAlignment = Enum.TextXAlignment.Left
    contentLabel.TextColor3 = Color3.fromRGB(170, 150, 200)
    return card
end

local function CreateDropdown(parent, text, options, default, callback)
    local card = CreateCard(parent, 70)
    local label = Instance.new("TextLabel", card)
    label.Size = UDim2.new(1, -30, 0, 24)
    label.Position = UDim2.new(0, 15, 0, 8)
    label.BackgroundTransparency = 1
    label.Text = text
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextColor3 = Color3.fromRGB(230, 220, 255)
    local dropdownBtn = Instance.new("TextButton", card)
    dropdownBtn.Size = UDim2.new(1, -30, 0, 32)
    dropdownBtn.Position = UDim2.new(0, 15, 0, 34)
    dropdownBtn.BackgroundColor3 = Color3.fromRGB(35, 25, 55)
    dropdownBtn.Text = default
    dropdownBtn.Font = Enum.Font.Gotham
    dropdownBtn.TextSize = 13
    dropdownBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdownBtn.BorderSizePixel = 0
    Instance.new("UICorner", dropdownBtn).CornerRadius = UDim.new(0, 8)
    local dropdownOpen = false
    local dropdownFrame = nil
    dropdownBtn.MouseButton1Click:Connect(function()
        if dropdownOpen then
            if dropdownFrame then dropdownFrame:Destroy() end
            dropdownOpen = false
            return
        end
        dropdownOpen = true
        dropdownFrame = Instance.new("Frame", card)
        dropdownFrame.Size = UDim2.new(1, -30, 0, 32 * #options)
        dropdownFrame.Position = UDim2.new(0, 15, 0, 66)
        dropdownFrame.BackgroundColor3 = Color3.fromRGB(25, 20, 45)
        dropdownFrame.BorderSizePixel = 0
        dropdownFrame.ZIndex = 10
        Instance.new("UICorner", dropdownFrame).CornerRadius = UDim.new(0, 8)
        local layout = Instance.new("UIListLayout", dropdownFrame)
        layout.Padding = UDim.new(0, 0)
        for i, opt in ipairs(options) do
            local optBtn = Instance.new("TextButton", dropdownFrame)
            optBtn.Size = UDim2.new(1, 0, 0, 32)
            optBtn.BackgroundColor3 = Color3.fromRGB(30, 25, 50)
            optBtn.Text = opt
            optBtn.Font = Enum.Font.Gotham
            optBtn.TextSize = 13
            optBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            optBtn.BorderSizePixel = 0
            optBtn.MouseEnter:Connect(function()
                optBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 150)
            end)
            optBtn.MouseLeave:Connect(function()
                optBtn.BackgroundColor3 = Color3.fromRGB(30, 25, 50)
            end)
            optBtn.MouseButton1Click:Connect(function()
                dropdownBtn.Text = opt
                callback(opt)
                dropdownFrame:Destroy()
                dropdownOpen = false
            end)
        end
    end)
    return card
end

-- CREATE UI TABS
-- COMBAT TAB
local combatContent = Instance.new("Frame")
combatContent.Size = UDim2.new(1, 0, 1, 0)
combatContent.BackgroundTransparency = 1
combatContent.Visible = true
combatContent.Parent = contentContainer
tabs["⚔️ Combat"].content = combatContent

CreateToggle(combatContent, "🤖 Auto Farm", Settings.AutoFarm, function(v) Settings.AutoFarm = v end)
CreateToggle(combatContent, "💀 Kill Aura", Settings.KillAura, function(v) Settings.KillAura = v end)
CreateToggle(combatContent, "📖 Auto Quest", Settings.AutoQuest, function(v) Settings.AutoQuest = v end)
CreateToggle(combatContent, "🎯 Auto Skill", Settings.AutoSkill, function(v) Settings.AutoSkill = v end)
CreateSlider(combatContent, "Farm Radius", 20, 150, Settings.FarmRadius, function(v) Settings.FarmRadius = v end)
CreateSlider(combatContent, "Kill Aura Radius", 20, 80, Settings.AuraRadius, function(v) Settings.AuraRadius = v end)
CreateSlider(combatContent, "Attack Delay", 0.05, 0.5, Settings.AttackDelay, function(v) Settings.AttackDelay = v end)

-- FARMING TAB
local farmingContent = Instance.new("Frame")
farmingContent.Size = UDim2.new(1, 0, 1, 0)
farmingContent.BackgroundTransparency = 1
farmingContent.Visible = false
farmingContent.Parent = contentContainer
tabs["🌾 Farming"].content = farmingContent

CreateToggle(farmingContent, "🍎 Fruit Sniper", Settings.FruitSniper, function(v) Settings.FruitSniper = v end)
CreateToggle(farmingContent, "📊 Auto Stats", Settings.AutoStats, function(v) Settings.AutoStats = v end)
CreateDropdown(farmingContent, "Stat to Upgrade", {"Strength", "Defense", "Speed", "Fruit", "Sword"}, Settings.SelectedStat, function(v) Settings.SelectedStat = v end)

-- TELEPORTS TAB
local teleportContent = Instance.new("Frame")
teleportContent.Size = UDim2.new(1, 0, 1, 0)
teleportContent.BackgroundTransparency = 1
teleportContent.Visible = false
teleportContent.Parent = contentContainer
tabs["🗺️ Teleports"].content = teleportContent

local islands = {
    {"🏝️ Starter Island", 0, 50, 0},
    {"🌴 Jungle Island", -500, 50, -300},
    {"🏜️ Desert Island", -800, 50, 1200},
    {"❄️ Snow Island", 500, 70, 800},
    {"🚂 Shibuya Station", 1000, 50, 500},
    {"🌑 Hueco Mundo", 0, 50, 0},
    {"🏙️ Shinjuku Island", -500, 50, 1800},
    {"🟢 Slime Island", -2000, 50, -500},
    {"🏛️ Academy Island", 2500, 50, 1500},
}

for _, island in pairs(islands) do
    CreateButton(teleportContent, island[1], function()
        Teleport({x = island[2], y = island[3], z = island[4]})
    end)
end

-- UTILITY TAB
local utilityContent = Instance.new("Frame")
utilityContent.Size = UDim2.new(1, 0, 1, 0)
utilityContent.BackgroundTransparency = 1
utilityContent.Visible = false
utilityContent.Parent = contentContainer
tabs["⚙️ Utility"].content = utilityContent

CreateToggle(utilityContent, "🦘 Infinite Jump", Settings.InfiniteJump, function(v) Settings.InfiniteJump = v end)
CreateToggle(utilityContent, "✈️ Fly Mode", Settings.FlyMode, function(v) Settings.FlyMode = v end)
CreateToggle(utilityContent, "🌀 Noclip", Settings.Noclip, function(v) Settings.Noclip = v end)
CreateSlider(utilityContent, "Walk Speed", 16, 350, Settings.WalkSpeed, function(v) Settings.WalkSpeed = v end)
CreateSlider(utilityContent, "Jump Power", 50, 300, Settings.JumpPower, function(v) Settings.JumpPower = v end)
CreateToggle(utilityContent, "💊 Auto Heal", Settings.AutoHeal, function(v) Settings.AutoHeal = v end)
CreateSlider(utilityContent, "Heal at HP %", 10, 90, Settings.HealPercent, function(v) Settings.HealPercent = v end)
CreateToggle(utilityContent, "🛡️ Auto Block", Settings.AutoBlock, function(v) Settings.AutoBlock = v end)
CreateButton(utilityContent, "💚 Heal Now", function() Heal() end)

-- STATS TAB
local statsContent = Instance.new("Frame")
statsContent.Size = UDim2.new(1, 0, 1, 0)
statsContent.BackgroundTransparency = 1
statsContent.Visible = false
statsContent.Parent = contentContainer
tabs["📊 Stats"].content = statsContent

local function UpdateStatsDisplay()
    local elapsed = os.time() - Stats.StartTime
    local hours = math.floor(elapsed / 3600)
    local minutes = math.floor((elapsed % 3600) / 60)
    for _, child in pairs(statsContent:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    CreateLabel(statsContent, "💀 Total Kills: " .. Stats.TotalKills)
    CreateLabel(statsContent, "📖 Quests Completed: " .. Stats.QuestsCompleted)
    CreateLabel(statsContent, "🎯 Current Quest: " .. (CurrentQuest and CurrentQuest.island .. " (" .. QuestKillCount .. "/" .. CurrentQuest.requiredKills .. ")" or "None"))
    CreateLabel(statsContent, "💰 Money Earned: $" .. Stats.MoneyEarned)
    CreateLabel(statsContent, "💎 Gems Earned: " .. Stats.GemsEarned)
    CreateLabel(statsContent, "🍎 Fruits Found: " .. Stats.FruitsFound)
    CreateLabel(statsContent, "⏱️ Time Active: " .. hours .. "h " .. minutes .. "m")
end

spawn(function()
    while true do
        UpdateStatsDisplay()
        wait(5)
    end
end)

-- INFO TAB
local infoContent = Instance.new("Frame")
infoContent.Size = UDim2.new(1, 0, 1, 0)
infoContent.BackgroundTransparency = 1
infoContent.Visible = false
infoContent.Parent = contentContainer
tabs["ℹ️ Info"].content = infoContent

CreateParagraph(infoContent, "🌑 DARKWEB v10.1", "Premium Sailor Piece Script")
CreateParagraph(infoContent, "🎯 Level-Based Quests", "Auto picks best quest for your level")
CreateParagraph(infoContent, "⚡ Ultra-Fast Attack", "0.08 second attack delay")
CreateParagraph(infoContent, "🗺️ Teleports", "All major islands")
CreateParagraph(infoContent, "👁️ ESP System", "See enemies and fruits through walls")
CreateParagraph(infoContent, "🔒 Anti-AFK", "Never get kicked for inactivity")
CreateParagraph(infoContent, "🛡️ Auto Heal & Block", "Stay alive during farming")
CreateParagraph(infoContent, "🚀 Movement Mods", "Fly, Noclip, Speed boost, Infinite Jump")

-- DRAGGING FUNCTIONALITY
local dragging = false
local dragStart
local startPos

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

print([[
╔═══════════════════════════════════════════════════════════╗
║   🌑 DARKWEB | SAILOR PIECE v10.1 LOADED                 ║
║                                                           ║
║   ✅ Auto Farm      ✅ Kill Aura      ✅ Auto Quest      ║
║   ✅ Fruit Sniper   ✅ Auto Stats     ✅ Auto Skill      ║
║   ✅ ESP System     ✅ Teleports      ✅ Auto Heal       ║
║   ✅ Fly Mode       ✅ Noclip         ✅ Infinite Jump   ║
║                                                           ║
║   Status: ✅ READY                                       ║
╚═══════════════════════════════════════════════════════════╝
]])
