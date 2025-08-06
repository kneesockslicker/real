-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- === Config ===
local walkSpeedNormal = 16
local walkSpeedFast = 50
local flySpeed = 50

-- State variables
local speedEnabled = true
local flying = false
local noclip = false

local flyVelocity = Instance.new("BodyVelocity")
flyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
flyVelocity.Velocity = Vector3.new(0, 0, 0)
flyVelocity.Parent = nil

-- === Functions ===

local function setSpeed(enabled)
    speedEnabled = enabled
    humanoid.WalkSpeed = enabled and walkSpeedFast or walkSpeedNormal
    updateButtonStates()
end

local function setNoclip(state)
    noclip = state
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide ~= not state then
            part.CanCollide = not state
        end
    end
    updateButtonStates()
end

local function startFly()
    flying = true
    humanoid.PlatformStand = true
    flyVelocity.Parent = rootPart
    updateButtonStates()
end

local function stopFly()
    flying = false
    humanoid.PlatformStand = false
    flyVelocity.Parent = nil
    flyVelocity.Velocity = Vector3.new(0, 0, 0)
    updateButtonStates()
end

local function toggleFly()
    if flying then
        stopFly()
    else
        startFly()
    end
end

-- Update fly movement
RunService.RenderStepped:Connect(function()
    if flying then
        local moveDirection = Vector3.zero

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection += workspace.CurrentCamera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection -= workspace.CurrentCamera.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection -= workspace.CurrentCamera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection += workspace.CurrentCamera.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection += Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDirection -= Vector3.new(0, 1, 0)
        end

        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit
            flyVelocity.Velocity = moveDirection * flySpeed
        else
            flyVelocity.Velocity = Vector3.zero
        end
    end
end)

-- Reset character references and states on respawn
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")

    -- Reset to defaults
    setSpeed(false)
    stopFly()
    setNoclip(false)
end)

-- === GUI Creation ===

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MovementHelperGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 240, 0, 140)
frame.Position = UDim2.new(0.02, 0, 0.7, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.Parent = screenGui
frame.Active = true
frame.Draggable = true

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundTransparency = 1
title.Text = "Movement Helper"
title.TextColor3 = Color3.fromRGB(220, 220, 220)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.Parent = frame

-- Button creation helper
local function createButton(text, posY)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 210, 0, 35)
    btn.Position = UDim2.new(0, 15, 0, posY)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 16
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = text
    btn.Parent = frame
    return btn
end

-- Buttons
local btnSpeed = createButton("Toggle Speed: ON", 40)
local btnFly = createButton("Toggle Fly: OFF", 80)
local btnNoclip = createButton("Toggle Noclip: OFF", 120)

-- Update button text and colors based on state
function updateButtonStates()
    btnSpeed.Text = "Toggle Speed: " .. (speedEnabled and "ON" or "OFF")
    btnFly.Text = "Toggle Fly: " .. (flying and "ON" or "OFF")
    btnNoclip.Text = "Toggle Noclip: " .. (noclip and "ON" or "OFF")

    btnSpeed.BackgroundColor3 = speedEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(100, 100, 100)
    btnFly.BackgroundColor3 = flying and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(100, 100, 100)
    btnNoclip.BackgroundColor3 = noclip and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(100, 100, 100)
end

updateButtonStates()

-- Button click events
btnSpeed.MouseButton1Click:Connect(function()
    setSpeed(not speedEnabled)
end)

btnFly.MouseButton1Click:Connect(function()
    toggleFly()
end)

btnNoclip.MouseButton1Click:Connect(function()
    setNoclip(not noclip)
end)

-- Optional: Also keep existing keyboard toggles
local flyToggleKey = Enum.KeyCode.F
local noclipToggleKey = Enum.KeyCode.G

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == flyToggleKey then
        toggleFly()
    elseif input.KeyCode == noclipToggleKey then
        setNoclip(not noclip)
    end
end)
