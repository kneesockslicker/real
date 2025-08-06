-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mouse = player:GetMouse()

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Config
local walkSpeedNormal = 16
local walkSpeedFast = 50
local flySpeed = 50

local hotkeys = {
    Speed = Enum.KeyCode.None, -- No hotkey for speed toggle, since it's a simple toggle
    Fly = Enum.KeyCode.F,
    Noclip = Enum.KeyCode.G,
    Invul = Enum.KeyCode.H,
    Teleport = Enum.KeyCode.T,
}

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

-- Helper functions
local function formatHotkey(key)
    if key == Enum.KeyCode.None then return "" end
    return "[" .. tostring(key.Name) .. "]"
end

local function tweenButtonColor(button, enabled)
    local targetColor = enabled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(140, 140, 140)
    TweenService:Create(button, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {BackgroundColor3 = targetColor}):Play()
end

-- Forward declarations for buttons
local btnSpeed, btnFly, btnNoclip, btnInvul, btnTeleport

-- Update GUI Toggle Buttons
local function updateButtonStates()
    btnSpeed.Status.Text = speedEnabled and "ON" or "OFF"
    tweenButtonColor(btnSpeed.ToggleButton, speedEnabled)

    btnFly.Status.Text = flying and "ON" or "OFF"
    tweenButtonColor(btnFly.ToggleButton, flying)

    btnNoclip.Status.Text = noclip and "ON" or "OFF"
    tweenButtonColor(btnNoclip.ToggleButton, noclip)

    btnInvul.Status.Text = invulnerable and "ON" or "OFF"
    tweenButtonColor(btnInvul.ToggleButton, invulnerable)

    btnTeleport.Status.Text = teleportEnabled and "ON" or "OFF"
    tweenButtonColor(btnTeleport.ToggleButton, teleportEnabled)
end

-- Functions to set states and update GUI
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

-- Movement/event handlers (same as before)
RunService.RenderStepped:Connect(function()
    if flying then
        local moveDirection = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection += workspace.CurrentCamera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection -= workspace.CurrentCamera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection -= workspace.CurrentCamera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection += workspace.CurrentCamera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDirection -= Vector3.new(0,1,0) end

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

    setSpeed(false)
    stopFly()
    setNoclip(false)
    setInvulnerability(false)
    setTeleport(true)
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == hotkeys.Fly then toggleFly()
    elseif input.KeyCode == hotkeys.Noclip then setNoclip(not noclip)
    elseif input.KeyCode == hotkeys.Invul then setInvulnerability(not invulnerable)
    elseif input.KeyCode == hotkeys.Teleport then setTeleport(not teleportEnabled)
    end
end)

mouse.Button1Down:Connect(function()
    teleportToMousePosition()
end)

-- Create GUI ------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MovementHelperGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 280, 0, 320)
frame.Position = UDim2.new(0.02, 0, 0.6, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.BorderColor3 = Color3.fromRGB(45, 45, 45)
frame.BorderSizePixel = 2
frame.ClipsDescendants = true
frame.Parent = screenGui
frame.Active = true

-- Custom drag support for smooth dragging
local UserInputService = game:GetService("UserInputService")
local dragging, dragInput, dragStart, startPos

local function update(input)
    local delta = input.Position - dragStart
    frame.Position = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )
end

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
titleBar.BorderSizePixel = 0
titleBar.Parent = frame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -30, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Movement Helper"
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 22
titleLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.TextYAlignment = Enum.TextYAlignment.Center
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.Parent = titleBar

-- Collapse Button on TitleBar
local collapseBtn = Instance.new("TextButton")
collapseBtn.Size = UDim2.new(0, 30, 0, 30)
collapseBtn.Position = UDim2.new(1, -40, 0, 5)
collapseBtn.BackgroundColor3 = Color3.fromRGB(85, 85, 85)
collapseBtn.BorderSizePixel = 0
collapseBtn.Text = "–"
collapseBtn.Font = Enum.Font.GothamBold
collapseBtn.TextSize = 24
collapseBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
collapseBtn.AutoButtonColor = false
collapseBtn.Parent = titleBar

-- Container frame to hold all toggle buttons
local container = Instance.new("Frame")
container.Size = UDim2.new(1, 0, 1, -40)
container.Position = UDim2.new(0, 0, 0, 40)
container.BackgroundTransparency = 1
container.Parent = frame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 12)
UIListLayout.Parent = container

-- Button creation helper (with icon placeholder and tooltip helper)
local function createToggleButton(name, hotkeyName)
    local button = Instance.new("Frame")
    button.Size = UDim2.new(1, -20, 0, 45)
    button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    button.BorderSizePixel = 0
    button.AnchorPoint = Vector2.new(0, 0)
    button.LayoutOrder = 1
    button.Parent = container
    button.Name = name .. "Button"

    local buttonLayout = Instance.new("UICorner")
    buttonLayout.CornerRadius = UDim.new(0, 8)
    buttonLayout.Parent = button

    -- TextLabel for Name
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Position = UDim2.new(0, 15, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamSemibold
    label.TextSize = 18
    label.TextColor3 = Color3.fromRGB(235, 235, 235)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Text = name
    label.Parent = button

    -- Hotkey label
    local hotkeyLabel = Instance.new("TextLabel")
    hotkeyLabel.Size = UDim2.new(0, 50, 0, 20)
    hotkeyLabel.AnchorPoint = Vector2.new(1, 0.5)
    hotkeyLabel.Position = UDim2.new(1, -10, 0.5, 0)
    hotkeyLabel.BackgroundTransparency = 0.3
    hotkeyLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    hotkeyLabel.Text = hotkeyName
    hotkeyLabel.Font = Enum.Font.GothamSemibold
    hotkeyLabel.TextSize = 14
    hotkeyLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    hotkeyLabel.TextXAlignment = Enum.TextXAlignment.Center
    hotkeyLabel.TextYAlignment = Enum.TextYAlignment.Center
    hotkeyLabel.Parent = button

    local hotkeyRound = Instance.new("UICorner")
    hotkeyRound.CornerRadius = UDim.new(1, 0)
    hotkeyRound.Parent = hotkeyLabel

    -- Status label (ON/OFF)
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(0, 48, 0, 28)
    statusLabel.AnchorPoint = Vector2.new(1, 0.5)
    statusLabel.Position = UDim2.new(1, -70, 0.5, 0)
    statusLabel.BackgroundColor3 = Color3.fromRGB(85, 85, 85)
    statusLabel.Font = Enum.Font.GothamBold
    statusLabel.TextSize = 18
    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    statusLabel.Text = "OFF"
    statusLabel.TextXAlignment = Enum.TextXAlignment.Center
    statusLabel.TextYAlignment = Enum.TextYAlignment.Center
    statusLabel.Parent = button

    local statusRound = Instance.new("UICorner")
    statusRound.CornerRadius = UDim.new(0, 6)
    statusRound.Parent = statusLabel

    -- Button (actual clickable, transparent overlay)
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Size = UDim2.new(1, 0, 1, 0)
    toggleBtn.Parent = button
    toggleBtn.AutoButtonColor = false
    toggleBtn.Text = ""

    -- Tooltip on hover (Optional)
    local tooltip = Instance.new("TextLabel")
    tooltip.Name = "Tooltip"
    tooltip.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    tooltip.BackgroundTransparency = 0.85
    tooltip.BorderColor3 = Color3.fromRGB(50, 50, 50)
    tooltip.BorderSizePixel = 1
    tooltip.TextColor3 = Color3.fromRGB(200, 200, 200)
    tooltip.TextSize = 14
    tooltip.Font = Enum.Font.Gotham
    tooltip.TextXAlignment = Enum.TextXAlignment.Left
    tooltip.TextYAlignment = Enum.TextYAlignment.Top
    tooltip.Visible = false
    tooltip.Text = "Toggle " .. name
    tooltip.Size = UDim2.new(0, 170, 0, 40)
    tooltip.Parent = button
    tooltip.Position = UDim2.new(1, 10, 0, 0)
    tooltip.ZIndex = 10

    toggleBtn.MouseEnter:Connect(function() tooltip.Visible = true end)
    toggleBtn.MouseLeave:Connect(function() tooltip.Visible = false end)

    return {
        Frame = button,
        ToggleButton = toggleBtn,
        Label = label,
        Status = statusLabel,
        HotkeyLabel = hotkeyLabel
    }
end

-- Create all toggle buttons
btnSpeed = createToggleButton("Speed", formatHotkey(hotkeys.Speed))
btnFly = createToggleButton("Fly", formatHotkey(hotkeys.Fly))
btnNoclip = createToggleButton("Noclip", formatHotkey(hotkeys.Noclip))
btnInvul = createToggleButton("Invulnerability", formatHotkey(hotkeys.Invul))
btnTeleport = createToggleButton("Teleport", formatHotkey(hotkeys.Teleport))

-- Add margins layout for nice padding around container
local padding = Instance.new("UIPadding")
padding.PaddingBottom = UDim.new(0, 10)
padding.PaddingTop = UDim.new(0, 10)
padding.PaddingLeft = UDim.new(0, 12)
padding.PaddingRight = UDim.new(0, 12)
padding.Parent = container

-- Collapse/Expand functionality
local isCollapsed = false
local expandedHeight = 320
local collapsedHeight = 40

local function toggleCollapse()
    isCollapsed = not isCollapsed

    -- Tween frame size
    local targetSize = isCollapsed and UDim2.new(0, 280, 0, collapsedHeight) or UDim2.new(0, 280, 0, expandedHeight)
    TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = targetSize}):Play()

    -- Animate collapse button symbol
    TweenService:Create(collapseBtn, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
    delay(0.2, function()
        collapseBtn.Text = isCollapsed and "+" or "–"
        TweenService:Create(collapseBtn, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
    end)

    -- Animate buttons fade out/in and visibility toggle
    for _, btn in ipairs({btnSpeed.Frame, btnFly.Frame, btnNoclip.Frame, btnInvul.Frame, btnTeleport.Frame}) do
        if isCollapsed then
            local fadeOut = TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextTransparency = 1})
            fadeOut:Play()
            fadeOut.Completed:Connect(function()
                btn.Visible = false
                btn.BackgroundTransparency = 0
                -- Also reset TextTransparency of children
                for _, c in pairs(btn:GetChildren()) do
                    if c:IsA("TextLabel") or c:IsA("TextButton") then
                        c.TextTransparency = 0
                    end
                end
            end)
        else
            btn.Visible = true
            btn.BackgroundTransparency = 1
            for _, c in pairs(btn:GetChildren()) do
                if c:IsA("TextLabel") or c:IsA("TextButton") then
                    c.TextTransparency = 1
                end
            end
            TweenService:Create(btn, TweenInfo.new(0.3), {BackgroundTransparency = 0, TextTransparency = 0}):Play()
            for _, c in pairs(btn:GetChildren()) do
                if c:IsA("TextLabel") or c:IsA("TextButton") then
                    TweenService:Create(c, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
                end
            end
        end
    end
end

collapseBtn.MouseButton1Click:Connect(toggleCollapse)

-- Button click functionality wired to toggles
btnSpeed.ToggleButton.MouseButton1Click:Connect(function()
    setSpeed(not speedEnabled)
end)

btnFly.ToggleButton.MouseButton1Click:Connect(function()
    toggleFly()
end)

btnNoclip.ToggleButton.MouseButton1Click:Connect(function()
    setNoclip(not noclip)
end)

btnInvul.ToggleButton.MouseButton1Click:Connect(function()
    setInvulnerability(not invulnerable)
end)

btnTeleport.ToggleButton.MouseButton1Click:Connect(function()
    setTeleport(not teleportEnabled)
end)

-- Initialize GUI states on script start
setSpeed(speedEnabled)
setNoclip(noclip)
setInvulnerability(invulnerable)
setTeleport(teleportEnabled)
updateButtonStates()
