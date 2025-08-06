-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Configuration for speed adjustment
local walkSpeedNormal = 16
local walkSpeedMin = 16
local walkSpeedMax = 150

-- Current walk speed
local currentWalkSpeed = walkSpeedNormal
humanoid.WalkSpeed = currentWalkSpeed

-- === Function to instantly trigger all ProximityPrompts in range every frame ===

RunService.Stepped:Connect(function()
    -- Check all ProximityPrompts in the workspace (you can optimize by scanning a subset if desired)
    for _, prompt in pairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            local promptParent = prompt.Parent
            if promptParent and promptParent:IsA("BasePart") and character and character:FindFirstChild("HumanoidRootPart") then
                local distance = (promptParent.Position - character.HumanoidRootPart.Position).Magnitude
                if distance <= prompt.MaxActivationDistance then
                    -- Trigger prompt instantly
                    prompt:InputHoldBegin()
                    prompt:InputHoldEnd()
                end
            end
        end
    end
end)

-- === GUI Creation for WalkSpeed Adjustment (Textbox + Slider) with mobile-friendly scaling ===

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SpeedAdjustGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- UIScale for mobile scaling
local uiScale = Instance.new("UIScale")
uiScale.Parent = screenGui

-- Detect if mobile and scale up GUI accordingly
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
if isMobile then
    uiScale.Scale = 1.5 -- increase GUI size on mobile devices for usability
else
    uiScale.Scale = 1
end

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.35, 0, 0.45, 0)  -- 35% width, 45% height of screen for responsiveness
frame.Position = UDim2.new(0.05, 0, 0.5, 0) -- Left middle side of screen
frame.AnchorPoint = Vector2.new(0, 0.5) -- anchor middle left vertically
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.BorderSizePixel = 0
frame.Parent = screenGui
frame.Active = true
frame.Draggable = true -- Enable dragging for usability

-- Title label
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Adjust Walk Speed"
title.Font = Enum.Font.GothamBold
title.TextSize = 24
title.TextColor3 = Color3.fromRGB(220, 220, 220)
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextYAlignment = Enum.TextYAlignment.Center
title.RichText = true
title.Parent = frame
title.PaddingLeft = Instance.new("UIPadding", title)
title.PaddingLeft.PaddingLeft = UDim.new(0, 15)

-- TextBox input for speed value
local speedInputBox = Instance.new("TextBox")
speedInputBox.Size = UDim2.new(0.3, 0, 0, 50) -- 30% width, 50px height
speedInputBox.Position = UDim2.new(0.05, 0, 0, 50)
speedInputBox.PlaceholderText = tostring(walkSpeedNormal)
speedInputBox.Text = tostring(currentWalkSpeed)
speedInputBox.ClearTextOnFocus = false
speedInputBox.Font = Enum.Font.GothamSemibold
speedInputBox.TextSize = 22
speedInputBox.TextColor3 = Color3.new(1, 1, 1)
speedInputBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
speedInputBox.BorderSizePixel = 0
speedInputBox.TextWrapped = false
speedInputBox.Parent = frame

-- Slider background
local sliderBackground = Instance.new("Frame")
sliderBackground.Size = UDim2.new(0.55, 0, 0, 50)
sliderBackground.Position = UDim2.new(0.4, 0, 0, 50)
sliderBackground.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
sliderBackground.BorderSizePixel = 0
sliderBackground.Parent = frame

local sliderUICorner = Instance.new("UICorner")
sliderUICorner.CornerRadius = UDim.new(0, 10)
sliderUICorner.Parent = sliderBackground

-- Slider handle
local sliderHandle = Instance.new("Frame")
sliderHandle.Size = UDim2.new(0, 30, 1, 0)
local initialProportion = (currentWalkSpeed - walkSpeedMin) / (walkSpeedMax - walkSpeedMin)
sliderHandle.Position = UDim2.new(initialProportion, 0, 0, 0)
sliderHandle.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
sliderHandle.BorderSizePixel = 0
sliderHandle.Parent = sliderBackground

local sliderHandleCorner = Instance.new("UICorner")
sliderHandleCorner.CornerRadius = UDim.new(0, 15)
sliderHandleCorner.Parent = sliderHandle

-- Helper function: update speed from slider position
local function updateSpeedFromSlider()
    local sliderWidth = sliderBackground.AbsoluteSize.X - sliderHandle.AbsoluteSize.X
    local sliderX = sliderHandle.Position.X.Offset
    local proportion = math.clamp(sliderX / sliderWidth, 0, 1)
    local newSpeed = math.floor(proportion * (walkSpeedMax - walkSpeedMin) + walkSpeedMin)
    currentWalkSpeed = newSpeed
    speedInputBox.Text = tostring(newSpeed)
    humanoid.WalkSpeed = currentWalkSpeed
end

-- Slider dragging logic variables
local dragging = false
local dragStartX = nil
local handleStartPosX = nil

sliderHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStartX = input.Position.X
        handleStartPosX = sliderHandle.Position.X.Offset
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

sliderBackground.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local relativeX = input.Position.X - sliderBackground.AbsolutePosition.X
        local maxPos = sliderBackground.AbsoluteSize.X - sliderHandle.AbsoluteSize.X
        local clampedPos = math.clamp(relativeX - sliderHandle.AbsoluteSize.X / 2, 0, maxPos)
        sliderHandle.Position = UDim2.new(0, clampedPos, 0, 0)
        updateSpeedFromSlider()
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position.X - dragStartX
        local maxPos = sliderBackground.AbsoluteSize.X - sliderHandle.AbsoluteSize.X
        local newPos = math.clamp(handleStartPosX + delta, 0, maxPos)
        sliderHandle.Position = UDim2.new(0, newPos, 0, 0)
        updateSpeedFromSlider()
    end
end)

speedInputBox.FocusLost:Connect(function(enterPressed)
    local val = tonumber(speedInputBox.Text)
    if val then
        val = math.clamp(val, walkSpeedMin, walkSpeedMax)
        currentWalkSpeed = val
        humanoid.WalkSpeed = currentWalkSpeed
        local sliderWidth = sliderBackground.AbsoluteSize.X - sliderHandle.AbsoluteSize.X
        local proportion = (val - walkSpeedMin) / (walkSpeedMax - walkSpeedMin)
        sliderHandle.Position = UDim2.new(0, proportion * sliderWidth, 0, 0)
        speedInputBox.Text = tostring(val) -- sanitize user text
    else
        speedInputBox.Text = tostring(currentWalkSpeed) -- reset if input invalid
    end
end)

print("Instant ProximityPrompt activator and mobile-friendly WalkSpeed GUI loaded")
