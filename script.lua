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
frame.Size = UDim2.new(0.35, 0, 0.22, 0)
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
title.Parent = frame

-- TextBox for speed input
local speedInputBox = Instance.new("TextBox")
speedInputBox.Size = UDim2.new(0.28, 0, 0, 40)
speedInputBox.Position = UDim2.new(0, 15, 0, 60)
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
sliderBack.Size = UDim2.new(0.6, 0, 0, 40)
sliderBack.Position = UDim2.new(0.38, 0, 0, 60)
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

-- Function to update speed from slider position
local function updateSpeedFromSlider()
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
    local val = tonumber(speedInputBox.Text)
    if val then
        local clampedVal = math.clamp(val, WALK_SPEED_MIN, WALK_SPEED_MAX)
        currentSpeed = clampedVal
        humanoid.WalkSpeed = currentSpeed
        
        -- Update slider position accordingly
        local maxPos = sliderBack.AbsoluteSize.X - sliderHandle.AbsoluteSize.X
        local proportion = (clampedVal - WALK_SPEED_MIN) / (WALK_SPEED_MAX - WALK_SPEED_MIN)
        sliderHandle.Position = UDim2.new(0, proportion * maxPos, 0, 0)
        
        speedInputBox.Text = tostring(clampedVal)  -- update text to clamped valid number
    else
        -- Revert text if invalid input
        speedInputBox.Text = tostring(currentSpeed)
    end
end)

-- Initialize humanoid walk speed
humanoid.WalkSpeed = currentSpeed

print("[WalkSpeed GUI] Loaded. Use slider or input box to adjust speed.")
