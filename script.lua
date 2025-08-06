-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Configurations
local walkSpeedNormal = 16
local walkSpeedFast = 50  -- default fast speed
local flySpeed = 50

local flyToggleKey = Enum.KeyCode.F
local noclipToggleKey = Enum.KeyCode.G
local invulToggleKey = Enum.KeyCode.H
local teleportToggleKey = Enum.KeyCode.T

-- State variables
local speedEnabled = true
local flying = false
local noclip = false
local invulnerable = false
local teleportEnabled = true

local flyVelocity = Instance.new("BodyVelocity")
flyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
flyVelocity.Velocity = Vector3.new(0, 0, 0)
flyVelocity.Parent = nil

-- Helper to update button text and color
local function updateButton(button, enabled, label)
    button.Text = label .. (enabled and ": ON" or ": OFF")
    button.BackgroundColor3 = enabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(100, 100, 100)
end

-- Forward declarations for buttons
local btnSpeed, btnFly, btnNoclip, btnInvul, btnTeleport

-- Update all buttons according to states
local function updateAllButtons()
    updateButton(btnSpeed, speedEnabled, "Toggle Speed")
    updateButton(btnFly, flying, "Toggle Fly")
    updateButton(btnNoclip, noclip, "Toggle Noclip")
    updateButton(btnInvul, invulnerable, "Toggle Invulnerability")
    updateButton(btnTeleport, teleportEnabled, "Toggle Teleport")
end

-- State setters (update both state and GUI)
local function setSpeed(enabled)
    speedEnabled = enabled
    humanoid.WalkSpeed = enabled and walkSpeedFast or walkSpeedNormal
    updateAllButtons()
end

local function setNoclip(state)
    noclip = state
    updateAllButtons()
end

local function setInvulnerability(state)
    invulnerable = state
    updateAllButtons()
end

local function setTeleport(state)
    teleportEnabled = state
    updateAllButtons()
end

local function startFly()
    flying = true
    humanoid.PlatformStand = true
    flyVelocity.Parent = rootPart
    updateAllButtons()
end

local function stopFly()
    flying = false
    humanoid.PlatformStand = false
    flyVelocity.Parent = nil
    flyVelocity.Velocity = Vector3.new(0, 0, 0)
    updateAllButtons()
end

local function toggleFly()
    if flying then stopFly() else startFly() end
end

-- Teleport function on mouse click
local function teleportToMousePosition()
    if not teleportEnabled then return end
    local character = player.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart and mouse then
        local unitRay = workspace.CurrentCamera:ScreenPointToRay(mouse.X, mouse.Y)
        local ray = Ray.new(unitRay.Origin, unitRay.Direction * 1000)
        local ignoreList = {character}
        local hitPart, hitPos = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
        if hitPos then
            humanoidRootPart.CFrame = CFrame.new(hitPos + Vector3.new(0, 4, 0))
        end
    end
end

-- Movement and state event connections
RunService.RenderStepped:Connect(function()
    if flying then
        local moveDirection = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection += workspace.CurrentCamera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection -= workspace.CurrentCamera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection -= workspace.CurrentCamera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection += workspace.CurrentCamera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDirection -= Vector3.new(0, 1, 0) end
        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit
            flyVelocity.Velocity = moveDirection * flySpeed
        else
            flyVelocity.Velocity = Vector3.zero
        end
    end
end)

RunService.Stepped:Connect(function()
    if noclip and character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

RunService.Stepped:Connect(function()
    if invulnerable and humanoid and humanoid.Health < humanoid.MaxHealth then
        humanoid.Health = humanoid.MaxHealth
    end
end)

player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    -- Reset states on respawn
    setSpeed(false)
    stopFly()
    setNoclip(false)
    setInvulnerability(false)
    setTeleport(true)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == flyToggleKey then toggleFly()
    elseif input.KeyCode == noclipToggleKey then setNoclip(not noclip)
    elseif input.KeyCode == invulToggleKey then setInvulnerability(not invulnerable)
    elseif input.KeyCode == teleportToggleKey then setTeleport(not teleportEnabled)
    end
end)

mouse.Button1Down:Connect(teleportToMousePosition)

-- ==== GUI Creation (Simple Reverted Basic) ====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MovementHelperGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
local collapsedHeight = 40     -- Title + collapse button height
local expandedHeight = 210     -- Full height for buttons

frame.Size = UDim2.new(0, 260, 0, expandedHeight)
frame.Position = UDim2.new(0.02, 0, 0.65, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.Parent = screenGui
frame.Active = true
frame.Draggable = true -- Default Roblox drag

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "Movement Helper"
title.TextColor3 = Color3.fromRGB(220, 220, 220)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.Parent = frame

local btnCollapse = Instance.new("TextButton")
btnCollapse.Size = UDim2.new(0, 30, 0, 30)
btnCollapse.Position = UDim2.new(1, -35, 0, 5)
btnCollapse.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
btnCollapse.BorderSizePixel = 0
btnCollapse.Text = "–"
btnCollapse.Font = Enum.Font.GothamBold
btnCollapse.TextSize = 24
btnCollapse.TextColor3 = Color3.fromRGB(220, 220, 220)
btnCollapse.Parent = frame

local function createButton(text, yPos)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 230, 0, 35)
    btn.Position = UDim2.new(0, 15, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.AutoButtonColor = true
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 16
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Text = text
    btn.Parent = frame
    return btn
end

btnSpeed = createButton("Toggle Speed: ON", 40)
btnFly = createButton("Toggle Fly: OFF", 80)
btnNoclip = createButton("Toggle Noclip: OFF", 120)
btnInvul = createButton("Toggle Invulnerability: OFF", 160)
btnTeleport = createButton("Toggle Teleport: ON", 200)

local tweenTime = 0.3
local isCollapsed = false

local function toggleCollapse()
    isCollapsed = not isCollapsed
    local targetSize = isCollapsed and UDim2.new(0, 260, 0, collapsedHeight) or UDim2.new(0, 260, 0, expandedHeight)
    TweenService:Create(frame, TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize}):Play()
    TweenService:Create(btnCollapse, TweenInfo.new(tweenTime / 2), {TextTransparency = 1}):Play()
    delay(tweenTime / 2, function()
        btnCollapse.Text = isCollapsed and "+" or "–"
        TweenService:Create(btnCollapse, TweenInfo.new(tweenTime / 2), {TextTransparency = 0}):Play()
    end)
    for _, btn in ipairs({btnSpeed, btnFly, btnNoclip, btnInvul, btnTeleport}) do
        if isCollapsed then
            local tween = TweenService:Create(btn, TweenInfo.new(tweenTime), {BackgroundTransparency = 1, TextTransparency = 1})
            tween:Play()
            tween.Completed:Connect(function()
                btn.Visible = false
                btn.BackgroundTransparency = 0
                btn.TextTransparency = 0
            end)
        else
            btn.Visible = true
            btn.BackgroundTransparency = 1
            btn.TextTransparency = 1
            TweenService:Create(btn, TweenInfo.new(tweenTime), {BackgroundTransparency = 0, TextTransparency = 0}):Play()
        end
    end
end

btnCollapse.MouseButton1Click:Connect(toggleCollapse)

-- Connect buttons to toggle their features
btnSpeed.MouseButton1Click:Connect(function() setSpeed(not speedEnabled) end)
btnFly.MouseButton1Click:Connect(function() toggleFly() end)
btnNoclip.MouseButton1Click:Connect(function() setNoclip(not noclip) end)
btnInvul.MouseButton1Click:Connect(function() setInvulnerability(not invulnerable) end)
btnTeleport.MouseButton1Click:Connect(function() setTeleport(not teleportEnabled) end)

-- Initialize button states to sync GUI and logic
updateAllButtons()
