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
local walkSpeedFast = 50  -- default starting fast speed
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

-- Update GUI button colors helper
local function updateButtonColor(button, enabled)
    local targetColor = enabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(100, 100, 100)
    -- Tween background color smoothly
    TweenService:Create(button, TweenInfo.new(0.3), {BackgroundColor3 = targetColor}):Play()
end

-- Forward declarations
local btnSpeed, btnFly, btnNoclip, btnInvul, btnTeleport, speedAdjustContainer

-- Update button texts and colors including speed value display
local function updateButtonStates()
    btnSpeed.Text = "Toggle Speed: " .. (speedEnabled and ("ON (Speed: " .. walkSpeedFast .. ")") or "OFF")
    btnFly.Text = "Toggle Fly: " .. (flying and "ON" or "OFF")
    btnNoclip.Text = "Toggle Noclip: " .. (noclip and "ON" or "OFF")
    btnInvul.Text = "Toggle Invulnerability: " .. (invulnerable and "ON" or "OFF")
    btnTeleport.Text = "Toggle Teleport: " .. (teleportEnabled and "ON" or "OFF")

    updateButtonColor(btnSpeed, speedEnabled)
    updateButtonColor(btnFly, flying)
    updateButtonColor(btnNoclip, noclip)
    updateButtonColor(btnInvul, invulnerable)
    updateButtonColor(btnTeleport, teleportEnabled)
end

-- State setters
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
    if flying then stopFly() else startFly() end
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

-- Movement and feature event handlers
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

-- ==== GUI Creation (Basic with Speed Adjustment) ====

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MovementHelperGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
local collapsedHeight = 40       -- Collapsed frame height (title + toggle)
local expandedHeight = 300       -- Increased to fit speed controls

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

-- Button creation helper
local function createButton(text, posY)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 230, 0, 35)
    btn.Position = UDim2.new(0, 15, 0, posY)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false -- Disable default to handle custom hover
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 16
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextWrapped = false
    btn.Text = text
    btn.Parent = frame
    return btn
end

btnSpeed = createButton("Toggle Speed: ON", 40)
btnFly = createButton("Toggle Fly: OFF", 80)
btnNoclip = createButton("Toggle Noclip: OFF", 120)
btnInvul = createButton("Toggle Invulnerability: OFF", 160)
btnTeleport = createButton("Toggle Teleport: ON", 200)

-- Speed adjustment controls container
speedAdjustContainer = Instance.new("Frame")
speedAdjustContainer.Size = UDim2.new(0, 230, 0, 80)
speedAdjustContainer.Position = UDim2.new(0, 15, 0, 240)
speedAdjustContainer.BackgroundTransparency = 1
speedAdjustContainer.Parent = frame

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, 0, 0, 20)
speedLabel.Position = UDim2.new(0, 0, 0, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Adjust Speed:"
speedLabel.Font = Enum.Font.GothamSemibold
speedLabel.TextSize = 16
speedLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = speedAdjustContainer

local speedInputBox = Instance.new("TextBox")
speedInputBox.Size = UDim2.new(0, 80, 0, 25)
speedInputBox.Position = UDim2.new(0, 0, 0, 25)
speedInputBox.Text = tostring(walkSpeedFast)
speedInputBox.PlaceholderText = "Speed"
speedInputBox.ClearTextOnFocus = false
speedInputBox.Font = Enum.Font.Gotham
speedInputBox.TextSize = 18
speedInputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedInputBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
speedInputBox.BorderSizePixel = 0
speedInputBox.Parent = speedAdjustContainer

local sliderBackground = Instance.new("Frame")
sliderBackground.Size = UDim2.new(1, -90, 0, 25)
sliderBackground.Position = UDim2.new(0, 90, 0, 25)
sliderBackground.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
sliderBackground.BorderSizePixel = 0
sliderBackground.Parent = speedAdjustContainer
sliderBackground.AnchorPoint = Vector2.new(0, 0)

local sliderUICorner = Instance.new("UICorner")
sliderUICorner.CornerRadius = UDim.new(0, 5)
sliderUICorner.Parent = sliderBackground

local sliderHandle = Instance.new("Frame")
sliderHandle.Size = UDim2.new(0, 15, 1, 0)
local sliderPositionProportion = (walkSpeedFast - walkSpeedNormal) / (100 - walkSpeedNormal)
sliderHandle.Position = UDim2.new(sliderPositionProportion, 0, 0, 0)
sliderHandle.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
sliderHandle.BorderSizePixel = 0
sliderHandle.Parent = sliderBackground

local sliderHandleUICorner = Instance.new("UICorner")
sliderHandleUICorner.CornerRadius = UDim.new(0, 7)
sliderHandleUICorner.Parent = sliderHandle

-- Slider drag logic
local draggingSlider = false
local sliderInputStart = nil
local sliderStartPos = nil

local function updateSpeedFromSlider()
    local sliderWidth = sliderBackground.AbsoluteSize.X - sliderHandle.Size.X.Offset
    local sliderX = sliderHandle.Position.X.Offset
    local speedRangeMin, speedRangeMax = walkSpeedNormal, 100
    local newSpeed = (sliderX / sliderWidth) * (speedRangeMax - speedRangeMin) + speedRangeMin
    newSpeed = math.floor(newSpeed)
    speedInputBox.Text = tostring(newSpeed)
    walkSpeedFast = newSpeed
    if speedEnabled then
        humanoid.WalkSpeed = newSpeed
        updateButtonStates()
    end
end

sliderHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        draggingSlider = true
        sliderInputStart = input.Position
        sliderStartPos = sliderHandle.Position.X.Offset
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                draggingSlider = false
            end
        end)
    end
end)

sliderBackground.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local relativeX = input.Position.X - sliderBackground.AbsolutePosition.X
        local posOffset = math.clamp(relativeX - sliderHandle.Size.X.Offset / 2, 0, sliderBackground.AbsoluteSize.X - sliderHandle.Size.X.Offset)
        sliderHandle.Position = UDim2.new(0, posOffset, 0, 0)
        updateSpeedFromSlider()
        draggingSlider = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position.X - sliderInputStart.X
        local newPos = math.clamp(sliderStartPos + delta, 0, sliderBackground.AbsoluteSize.X - sliderHandle.Size.X.Offset)
        sliderHandle.Position = UDim2.new(0, newPos, 0, 0)
        updateSpeedFromSlider()
    end
end)

speedInputBox.FocusLost:Connect(function()
    local value = tonumber(speedInputBox.Text)
    if value then
        local clampedValue = math.clamp(value, walkSpeedNormal, 100)
        walkSpeedFast = clampedValue
        if speedEnabled then humanoid.WalkSpeed = clampedValue end
        local sliderWidth = sliderBackground.AbsoluteSize.X - sliderHandle.Size.X.Offset
        local proportion = (clampedValue - walkSpeedNormal) / (100 - walkSpeedNormal)
        sliderHandle.Position = UDim2.new(0, proportion * sliderWidth, 0, 0)
        updateButtonStates()
    else
        speedInputBox.Text = tostring(walkSpeedFast)
    end
end)

-- Collapse toggle feature
local tweenDuration = 0.3
local isCollapsed = false

local function toggleCollapse()
    isCollapsed = not isCollapsed
    local targetSize = isCollapsed and UDim2.new(0, 260, 0, collapsedHeight) or UDim2.new(0, 260, 0, expandedHeight)
    TweenService:Create(frame, TweenInfo.new(tweenDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize}):Play()

    TweenService:Create(btnCollapse, TweenInfo.new(tweenDuration/2), {TextTransparency = 1}):Play()
    delay(tweenDuration/2, function()
        btnCollapse.Text = isCollapsed and "+" or "–"
        TweenService:Create(btnCollapse, TweenInfo.new(tweenDuration/2), {TextTransparency = 0}):Play()
    end)

    local buttonsToToggle = {btnSpeed, btnFly, btnNoclip, btnInvul, btnTeleport, speedAdjustContainer}
    for _, btn in ipairs(buttonsToToggle) do
        if isCollapsed then
            local tween = TweenService:Create(btn, TweenInfo.new(tweenDuration), {BackgroundTransparency = 1, TextTransparency = 1})
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
            TweenService:Create(btn, TweenInfo.new(tweenDuration), {BackgroundTransparency = 0, TextTransparency = 0}):Play()
        end
    end
end

btnCollapse.MouseButton1Click:Connect(toggleCollapse)

-- Add hover effect that only tweens background color (no text transparency tween)
local function addHoverEffect(button, defaultColor, hoverColor)
    button.BackgroundColor3 = defaultColor
    button.AutoButtonColor = false

    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = defaultColor}):Play()
    end)
end

local hoverDefault = Color3.fromRGB(50, 50, 50)
local hoverActive = Color3.fromRGB(70, 90, 70)

addHoverEffect(btnSpeed, hoverDefault, hoverActive)
addHoverEffect(btnFly, hoverDefault, hoverActive)
addHoverEffect(btnNoclip, hoverDefault, hoverActive)
addHoverEffect(btnInvul, hoverDefault, hoverActive)
addHoverEffect(btnTeleport, hoverDefault, hoverActive)

-- Connect button click events
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

-- Initialize GUI buttons states/labels
setSpeed(speedEnabled)
setNoclip(noclip)
setInvulnerability(invulnerable)
setTeleport(teleportEnabled)
updateButtonStates()
