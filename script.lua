-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for character and humanoid
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Walkspeed config
local WALK_SPEED_MIN = 16
local WALK_SPEED_MAX = 250

-- Current speed variable
local currentSpeed = humanoid.WalkSpeed

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "WalkSpeedGui"
screenGui.Parent = playerGui

-- UIScale for mobile devices
local uiScale = Instance.new("UIScale")
uiScale.Parent = screenGui
if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
    uiScale.Scale = 1.5
else
    uiScale.Scale = 1
end

-- Main Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0.35, 0, 0.25, 0)
frame.Position = UDim2.new(0.02, 0, 0.72, 0)
frame.AnchorPoint = Vector2.new(0, 0)
frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

-- Title Label
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -30, 0, 36)
title.Position = UDim2.new(0, 15, 0, 8)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextColor3 = Color3.fromRGB(220, 220, 220)
title.Text = "Adjust Walk Speed"
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextYAlignment = Enum.TextYAlignment.Center
title.Parent = frame

-- TextBox for speed input
local speedInputBox = Instance.new("TextBox")
speedInputBox.Size = UDim2.new(0.3, 0, 0, 40)
speedInputBox.Position = UDim2.new(0.05, 0, 0, 50)
speedInputBox.Font = Enum.Font.GothamSemibold
speedInputBox.TextSize = 20
speedInputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedInputBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
speedInputBox.BorderSizePixel = 0
speedInputBox.ClearTextOnFocus = false
speedInputBox.Text = tostring(math.clamp(currentSpeed, WALK_SPEED_MIN, WALK_SPEED_MAX))
speedInputBox.Parent = frame

-- Slider background
local sliderBack = Instance.new("Frame")
sliderBack.Size = UDim2.new(0.55, 0, 0, 40)
sliderBack.Position = UDim2.new(0.4, 0, 0, 50)
sliderBack.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
sliderBack.BorderSizePixel = 0
sliderBack.Parent = frame

local sliderBackCorner = Instance.new("UICorner")
sliderBackCorner.CornerRadius = UDim.new(0, 20)
sliderBackCorner.Parent = sliderBack

-- Slider handle
local sliderHandle = Instance.new("Frame")
sliderHandle.Size = UDim2.new(0, 30, 0, 40)
sliderHandle.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
sliderHandle.BorderSizePixel = 0
sliderHandle.Position = UDim2.new((currentSpeed - WALK_SPEED_MIN) / (WALK_SPEED_MAX - WALK_SPEED_MIN), 0, 0, 0)
sliderHandle.Parent = sliderBack

local sliderHandleCorner = Instance.new("UICorner")
sliderHandleCorner.CornerRadius = UDim.new(0, 15)
sliderHandleCorner.Parent = sliderHandle

-- State variable for the speed29 toggle
local speed29Enabled = false
local savedSpeedBefore29 = currentSpeed  -- Store previous speed before toggle

-- Create the toggle button for speed 29
local btnSpeed29 = Instance.new("TextButton")
btnSpeed29.Size = UDim2.new(0, 230, 0, 40)
btnSpeed29.Position = UDim2.new(0, 15, 0, 100)  -- Below slider and textbox
btnSpeed29.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
btnSpeed29.BorderSizePixel = 0
btnSpeed29.AutoButtonColor = false
btnSpeed29.Font = Enum.Font.GothamSemibold
btnSpeed29.TextSize = 18
btnSpeed29.TextColor3 = Color3.fromRGB(255, 255, 255)
btnSpeed29.Text = "Set Speed 29: OFF"
btnSpeed29.Parent = frame

-- Function to update the toggle button appearance
local function updateSpeed29Button()
    if speed29Enabled then
        btnSpeed29.Text = "Set Speed 29: ON"
        btnSpeed29.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    else
        btnSpeed29.Text = "Set Speed 29: OFF"
        btnSpeed29.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end
end

-- Function to enable/disable the slider and textbox
local function setSpeedControlsEnabled(enabled)
    speedInputBox.Active = enabled
    speedInputBox.TextEditable = enabled
    sliderBack.Active = enabled
    sliderHandle.Active = enabled
    sliderHandle.Selectable = enabled
    -- Optional: adjust transparency to indicate disabled state
    local transparency = enabled and 0 or 0.5
    speedInputBox.BackgroundTransparency = transparency
    sliderBack.BackgroundTransparency = transparency
    sliderHandle.BackgroundTransparency = transparency
end

-- Function to update speed from slider position
local function updateSpeedFromSlider()
    if speed29Enabled then return end -- ignore if speed29 toggle is ON
    local maxPosX = sliderBack.AbsoluteSize.X - sliderHandle.AbsoluteSize.X
    local posX = sliderHandle.Position.X.Offset
    local proportion = math.clamp(posX / maxPosX, 0, 1)
    local newSpeed = math.floor(WALK_SPEED_MIN + proportion * (WALK_SPEED_MAX - WALK_SPEED_MIN))
    
    currentSpeed = newSpeed
    humanoid.WalkSpeed = currentSpeed
    speedInputBox.Text = tostring(newSpeed)
end

-- Slider dragging variables
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

sliderBack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        local relativeX = input.Position.X - sliderBack.AbsolutePosition.X
        local maxPos = sliderBack.AbsoluteSize.X - sliderHandle.AbsoluteSize.X
        local clamped = math.clamp(relativeX - sliderHandle.AbsoluteSize.X / 2, 0, maxPos)
        sliderHandle.Position = UDim2.new(0, clamped, 0, 0)
        updateSpeedFromSlider()
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position.X - dragStartX
        local maxPos = sliderBack.AbsoluteSize.X - sliderHandle.AbsoluteSize.X
        local newPos = math.clamp(handleStartPosX + delta, 0, maxPos)
        sliderHandle.Position = UDim2.new(0, newPos, 0, 0)
        updateSpeedFromSlider()
    end
end)

-- Update speed from TextBox input
speedInputBox.FocusLost:Connect(function()
    if speed29Enabled then 
        -- Ignore text updates when speed29 toggle is on
        speedInputBox.Text = tostring(currentSpeed)
        return 
    end
    local val = tonumber(speedInputBox.Text)
    if val then
        local clampedVal = math.clamp(val, WALK_SPEED_MIN, WALK_SPEED_MAX)
