-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- === Config ===
local walkSpeedNormal = 16
local walkSpeedFast = 50
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

-- === Functions ===

local function updateButtonStates()
    btnSpeed.Text = "Toggle Speed: " .. (speedEnabled and "ON" or "OFF")
    btnFly.Text = "Toggle Fly: " .. (flying and "ON" or "OFF")
    btnNoclip.Text = "Toggle Noclip: " .. (noclip and "ON" or "OFF")
    btnInvul.Text = "Toggle Invulnerability: " .. (invulnerable and "ON" or "OFF")
    btnTeleport.Text = "Toggle Teleport: " .. (teleportEnabled and "ON" or "OFF")

    btnSpeed.BackgroundColor3 = speedEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(100, 100, 100)
    btnFly.BackgroundColor3 = flying and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(100, 100, 100)
    btnNoclip.BackgroundColor3 = noclip and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(100, 100, 100)
    btnInvul.BackgroundColor3 = invulnerable and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(100, 100, 100)
    btnTeleport.BackgroundColor3 = teleportEnabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(100, 100, 100)
end

local function setSpeed(enabled)
    speedEnabled = enabled
    humanoid.WalkSpeed = enabled and walkSpeedFast or walkSpeedNormal
    updateButtonStates()
end

local function setNoclip(state)
    noclip = state
    updateButtonStates()
end

local function setInvulnerability(state)
    invulnerable = state
    updateButtonStates()
end

local function setTeleport(state)
    teleportEnabled = state
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

-- === Event connections ===

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

RunService.Stepped:Connect(function()
    if noclip and character then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide == true then
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

    if input.KeyCode == flyToggleKey then
        toggleFly()
    elseif input.KeyCode == noclipToggleKey then
        setNoclip(not noclip)
    elseif input.KeyCode == invulToggleKey then
        setInvulnerability(not invulnerable)
    elseif input.KeyCode == teleportToggleKey then
        setTeleport(not teleportEnabled)
    end
end)

mouse.Button1Down:Connect(function()
    teleportToMousePosition()
end)

-- === GUI Creation ===

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MovementHelperGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
local collapsedHeight = 40       -- Height when collapsed
local expandedHeight = 250       -- Enough height for all buttons with spacing

frame.Size = UDim2.new(0, 260, 0, expandedHeight)
frame.Position = UDim2.new(0.02, 0, 0.65, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 0
frame.Parent = screenGui
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "Movement Helper"
title.TextColor3 = Color3.fromRGB(220, 220, 220)
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.Parent = frame

-- Collapse toggle button for the GUI
local isCollapsed = false

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

local function createButton(text, posY)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 230, 0, 35)
    btn.Position = UDim2.new(0, 15, 0, posY)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = true
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 16
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextWrapped = false
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Text = text
    btn.Parent = frame
    return btn
end

-- Buttons with vertical positions spaced by 40 pixels starting at 40
local btnSpeed = createButton("Toggle Speed: ON", 40)
local btnFly = createButton("Toggle Fly: OFF", 80)
local btnNoclip = createButton("Toggle Noclip: OFF", 120)
local btnInvul = createButton("Toggle Invulnerability: OFF", 160)
local btnTeleport = createButton("Toggle Teleport: ON", 200)

local function toggleCollapse()
    isCollapsed = not isCollapsed
    if isCollapsed then
        btnSpeed.Visible = false
        btnFly.Visible = false
        btnNoclip.Visible = false
        btnInvul.Visible = false
        btnTeleport.Visible = false

        frame.Size = UDim2.new(0, 260, 0, collapsedHeight)
        btnCollapse.Text = "+"
    else
        btnSpeed.Visible = true
        btnFly.Visible = true
        btnNoclip.Visible = true
        btnInvul.Visible = true
        btnTeleport.Visible = true

        frame.Size = UDim2.new(0, 260, 0, expandedHeight)
        btnCollapse.Text = "–"
    end
end

btnCollapse.MouseButton1Click:Connect(toggleCollapse)

-- Connect buttons click to toggles
btnSpeed.MouseButton1Click:Connect(function()
    setSpeed(not speedEnabled)
end)

btnFly.MouseButton1Click:Connect(function()
    toggleFly()
end)

btnNoclip.MouseButton1Click:Connect(function()
    setNoclip(not noclip)
end)

btnInvul.MouseButton1Click:Connect(function()
    setInvulnerability(not invulnerable)
end)

btnTeleport.MouseButton1Click:Connect(function()
    setTeleport(not teleportEnabled)
end)

-- Initialize states and update GUI buttons text/colors
setSpeed(speedEnabled)
setNoclip(noclip)
setInvulnerability(invulnerable)
setTeleport(teleportEnabled)
updateButtonStates()
