--[ Rost Alpha Camera Aimbot Script by AI ]--
-- Совместимость: Solara v3 | ДИНАМИЧЕСКИЙ SILENT-CALC V17.3 (Точная калибровка) + Автовыстрел на F10 + Inf Jump + ПРОДВИНУТЫЙ ESP

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

-- Настройки функций
local Settings = {
    AimbotEnabled = false,
    MaxDistance = 500,
    FovEnabled = false,
    FovRadius = 150,
    EspEnabled = false,
    FullbrightEnabled = false,
    TriggerEnabled = false,
    InfJumpEnabled = false,
    UiVisible = true
}

local LastCameraRotation = Camera.CFrame.Rotation

-- Оригинальные настройки освещения
local OrigAmbient = Lighting.Ambient
local OrigOutdoorAmbient = Lighting.OutdoorAmbient
local OrigBrightness = Lighting.Brightness
local OrigClockTime = Lighting.ClockTime
local OrigGlobalShadows = Lighting.GlobalShadows

-- Создание FOV круга через Drawing API
local FovCircle = Drawing.new("Circle")
FovCircle.Color = Color3.fromRGB(255, 0, 0)
FovCircle.Thickness = 1
FovCircle.NumSides = 64
FovCircle.Radius = Settings.FovRadius
FovCircle.Filled = false
FovCircle.Visible = false

-- Создание UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RostAlphaV17Gui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 180, 0, 280)
Frame.Position = UDim2.new(0, 10, 0, 10)
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "ROST ALPHA V17.3"
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = Frame

local Toggles = {}

local function CreateToggle(name, pos, settingName, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0, 160, 0, 30)
    Btn.Position = pos
    Btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    Btn.TextColor3 = Color3.fromRGB(255, 100, 100)
    Btn.Text = name .. ": OFF"
    Btn.Font = Enum.Font.SourceSans
    Btn.TextSize = 14
    Btn.Parent = Frame

    local function UpdateVisual()
        if Settings[settingName] then
            Btn.TextColor3 = Color3.fromRGB(100, 255, 100)
            Btn.Text = name .. ": ON"
        else
            Btn.TextColor3 = Color3.fromRGB(255, 100, 100)
            Btn.Text = name .. ": OFF"
        end
    end

    Btn.MouseButton1Click:Connect(function()
        Settings[settingName] = not Settings[settingName]
        UpdateVisual()
        if callback then callback(Settings[settingName]) end
    end)

    Toggles[settingName] = UpdateVisual
end

CreateToggle("1. Aim Bot", UDim2.new(0, 10, 0, 40), "AimbotEnabled")
CreateToggle("2. Aim FOV", UDim2.new(0, 10, 0, 80), "FovEnabled", function(val) FovCircle.Visible = val end)
CreateToggle("3. ESP Info", UDim2.new(0, 10, 0, 120), "EspEnabled")
CreateToggle("4. Fullbright", UDim2.new(0, 10, 0, 160), "FullbrightEnabled")
CreateToggle("5. Trigger [F10]", UDim2.new(0, 10, 0, 200), "TriggerEnabled")
CreateToggle("6. Inf Jump", UDim2.new(0, 10, 0, 240), "InfJumpEnabled")

-- Горячие клавиши
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        if input.KeyCode == Enum.KeyCode.RightShift then
            Settings.UiVisible = not Settings.UiVisible
            Frame.Visible = Settings.UiVisible
        elseif input.KeyCode == Enum.KeyCode.F10 then
            Settings.TriggerEnabled = not Settings.TriggerEnabled
            if Toggles["TriggerEnabled"] then Toggles["TriggerEnabled"]() end
        end
    end
end)

-- Бесконечный прыжок
UserInputService.JumpRequest:Connect(function()
    if Settings.InfJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
        LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
    end
end)

-- Функция поиска ближайшего игрока
local function GetClosestPlayer(maxDist)
    local ClosestTarget = nil
    local MaxFovDistance = Settings.FovRadius

    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then 
        return nil 
    end

    local MyPos = LocalPlayer.Character.HumanoidRootPart.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            
            local TargetHead = player.Character.Head
            local TargetPos = player.Character.HumanoidRootPart.Position
            local DistanceBetween = (MyPos - TargetPos).Magnitude

            if DistanceBetween <= maxDist then
                local ScreenPos, OnScreen = Camera:WorldToViewportPoint(TargetHead.Position)
                if OnScreen then
                    local MousePos = UserInputService:GetMouseLocation()
                    local DistanceToMouse = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos).Magnitude
                    
                    if DistanceToMouse < MaxFovDistance then
                        MaxFovDistance = DistanceToMouse
                        ClosestTarget = player
                    end
                end
            end
        end
    end
    return ClosestTarget
end

-- Клик мыши
local function FireWeapon()
    mouse1press()
    task.wait(0.02)
    mouse1release()
end

-- Основной цикл работы
RunService.RenderStepped:Connect(function()
    if Settings.FovEnabled then
        FovCircle.Position = UserInputService:GetMouseLocation()
        FovCircle.Radius = Settings.FovRadius
    end

    local IsAiming = Settings.AimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)

    -- 1. ДИНАМИЧЕСКИЙ АИМБОТ СМАРТ
    if IsAiming then
        local Target = GetClosestPlayer(Settings.MaxDistance)
        if Target and Target.Character and Target.Character:FindFirstChild("Head") and Target.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            
            local Head = Target.Character.Head
            local RootPart = Target.Character.HumanoidRootPart
            local MyPos = LocalPlayer.Character.HumanoidRootPart.Position
            
            local Distance = (MyPos - RootPart.Position).Magnitude
            local ElevationDifference = Head.Position.Y - MyPos.Y
            
            -- Обновленные точные динамические формулы расчёта
            local HeightOffsetValue = (Distance * Distance) * 0.000012 
            local PredictionTime = Distance * 0.00050
            
            local ElevationModifier = ElevationDifference * 0.015
            local FinalHeightOffset = Vector3.new(0, HeightOffsetValue + ElevationModifier, 0)
            
            local TargetVelocity = RootPart.Velocity
            local MovementOffset = TargetVelocity * PredictionTime
            
            local FinalTargetPosition = Head.Position + FinalHeightOffset + MovementOffset
            
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, FinalTargetPosition)
            LastCameraRotation = Camera.CFrame.Rotation
        else
            LastCameraRotation = Camera.CFrame.Rotation
        end
    else
        LastCameraRotation = Camera.CFrame.Rotation
    end

    -- 2. ДИНАМИЧЕСКИЙ АВТОВЫСТРЕЛ
    if Settings.TriggerEnabled and not IsAiming then
        local Target = GetClosestPlayer(Settings.MaxDistance)
        if Target and Target.Character and Target.Character:FindFirstChild("Head") and Target.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            
            local Head = Target.Character.Head
            local RootPart = Target.Character.HumanoidRootPart
            local MyPos = LocalPlayer.Character.HumanoidRootPart.Position
            
            local Distance = (MyPos - RootPart.Position).Magnitude
            local ElevationDifference = Head.Position.Y - MyPos.Y
            
            local HeightOffsetValue = (Distance * Distance) * 0.000012
            local PredictionTime = Distance * 0.00050
            
            local ElevationModifier = ElevationDifference * 0.015
            local FinalHeightOffset = Vector3.new(0, HeightOffsetValue + ElevationModifier, 0)
            
            local TargetVelocity = RootPart.Velocity
            local MovementOffset = TargetVelocity * PredictionTime
            
            local FinalTargetPosition = Head.Position + FinalHeightOffset + MovementOffset
            
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, FinalTargetPosition)
            task.spawn(FireWeapon)
        end
    end

    -- ЛОГИКА LIGHTING FULLBRIGHT
    if Settings.FullbrightEnabled then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
    else
        Lighting.Ambient = OrigAmbient
        Lighting.OutdoorAmbient = OrigOutdoorAmbient
        Lighting.Brightness = OrigBrightness
        Lighting.ClockTime = OrigClockTime
        Lighting.GlobalShadows = OrigGlobalShadows
    end
end)

-- Хранилище ESP
local EspObjects = {}

local function CreateEsp(player)
    local Objects = {
        NameText = Drawing.new("Text"),
        HealthText = Drawing.new("Text"),
        DistText = Drawing.new("Text")
}
for _, text in pairs(Objects) do
text.Center = true
text.Outline = true
text.OutlineColor = Color3.fromRGB(0, 0, 0)
text.Visible = false
end
Objects.NameText.Color = Color3.fromRGB(255, 255, 255)
Objects.NameText.Size = 15
Objects.HealthText.Size = 14
Objects.DistText.Color = Color3.fromRGB(255, 255, 100)
Objects.DistText.Size = 14
EspObjects[player] = Objects
end
for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then CreateEsp(p) end end
Players.PlayerAdded:Connect(CreateEsp)
Players.PlayerRemoving:Connect(function(player)
if EspObjects[player] then
for _, text in pairs(EspObjects[player]) do text:Remove() end
EspObjects[player] = nil
end
end)
-- Логика продвинутого ESP
RunService.RenderStepped:Connect(function()
for player, objects in pairs(EspObjects) do
local char = player.Character
if char and char:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") then
local Humanoid = char.Humanoid
local Root = char.HumanoidRootPart
local Head = char:FindFirstChild("Head")
if Humanoid.Health > 0 and Head then
local ScreenPosTop, OnScreenTop = Camera:WorldToViewportPoint(Head.Position + Vector3.new(0, 2.5, 0))
local ScreenPosBottom, OnScreenBottom = Camera:WorldToViewportPoint(Root.Position + Vector3.new(0, -3.5, 0))
if Settings.EspEnabled and OnScreenTop and OnScreenBottom then
local Distance = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - Root.Position).Magnitude)
local CurrentHealth = math.floor(Humanoid.Health)
local MaxHealth = math.floor(Humanoid.MaxHealth)
if CurrentHealth > 70 then
objects.HealthText.Color = Color3.fromRGB(100, 255, 100)
elseif CurrentHealth > 35 then
objects.HealthText.Color = Color3.fromRGB(255, 200, 50)
else
objects.HealthText.Color = Color3.fromRGB(255, 50, 50)
end
objects.NameText.Position = Vector2.new(ScreenPosTop.X, ScreenPosTop.Y - 15)
objects.NameText.Text = player.Name
objects.NameText.Visible = true
objects.HealthText.Position = Vector2.new(ScreenPosTop.X, ScreenPosTop.Y)
objects.HealthText.Text = string.format("[%d/%d HP]", CurrentHealth, MaxHealth)
objects.HealthText.Visible = true
objects.DistText.Position = Vector2.new(ScreenPosBottom.X, ScreenPosBottom.Y)
objects.DistText.Text = string.format("[%dm.]", Distance)
objects.DistText.Visible = true
else
objects.NameText.Visible = false
objects.HealthText.Visible = false
objects.DistText.Visible = false
end
else
for _, text in pairs(objects) do text.Visible = false end
end
else
if EspObjects[player] then
for _, text in pairs(EspObjects[player]) do text.Visible = false end
end
end
end
end)
