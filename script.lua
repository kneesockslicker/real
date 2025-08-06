-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Configuration for speed adjustment
local walkSpeedNormal = 16
local walkSpeedMin = 16
local walkSpeedMax = 150

-- Initial walk speed
local currentWalkSpeed = walkSpeedNormal
humanoid.WalkSpeed = currentWalkSpeed

-- === Function to instantly trigger all ProximityPrompts in range every frame ===

RunService.Stepped:Connect(function()
    -- Find all ProximityPrompts in workspace - optionally you can narrow down to certain containers
    for _, prompt in pairs(workspace:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") then
            -- Check distance to player, optional to optimize performance
            local promptParent = prompt.Parent
            if promptParent and promptParent:IsA("BasePart") and character and character:FindFirstChild("HumanoidRootPart") then
                local distance = (promptParent.Position - character.HumanoidRootPart.Position).Magnitude
                if distance <= prompt.MaxActivationDistance then
                    -- Fire proximity prompt instantly
                    -- Use :InputHoldBegin() / :InputHoldEnd() instead of :InputHoldBegin() for hold duration prompts,
                    -- but here we just trigger :InputHoldBegin() + :InputHoldEnd() to simulate instant press
                    prompt:InputHoldBegin()
                    prompt:InputHoldEnd()
                end
            end
        end
    end
end)

-- === GUI Creation for WalkSpeed Adjustment (Textbox + Slider) ===

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SpeedAdjustGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 100)
frame.Position = UDim2.new(0.02, 0, 0.7, 0)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.BorderSizePixel = 0
frame.Parent = screenGui
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Adjust Walk Speed"
title.Font = Enum.Font.GothamBold
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(220, 220, 220)
title.Parent = frame

-- TextBox to input speed value
local speedInputBox = Instance.new("TextBox")
speedInputBox.Size = UDim2.new(0, 80, 0, 25)
speedInputBox.Position = UDim2.new(0, 15, 0, 40)
speedInputBox.PlaceholderText = tostring(walkSpeedNormal)
speedInputBox.Text = tostring(currentWalkSpeed)
speedInputBox.ClearTextOnFocus = false
speedInputBox.Font = Enum.Font.GothamSemibold
speedInputBox.TextSize = 18
speedInputBox.TextColor3 = Color3.new(1,1,1)
speedInputBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
speedInputBox.BorderSizePixel = 0
speedInputBox.Parent = frame

-- Slider background frame
local sliderBackground = Instance.new("Frame")
sliderBackground.Size = UDim2.new(0, 150, 0, 25)
sliderBackground.Position = UDim2.new(0, 110, 0, 40)
sliderBackground.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
sliderBackground.BorderSizePixel = 0
sliderBackground.Parent = frame

local sliderUICorner = Instance.new("UICorner")
sliderUICorner.CornerRadius = UDim.new(0, 5)
sliderUICorner.Parent = sliderBackground

-- Slider handle
local sliderHandle = Instance.new("Frame")
sliderHandle.Size = UDim2.new(0, 20, 1, 0)
local initialProportion = (currentWalkSpeed - walkSpeedMin) / (walkSpeedMax - walkSpeedMin)
sliderHandle.Position = UDim2.new(initialProportion, 0, 0, 0)
sliderHandle.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
sliderHandle.BorderSizePixel = 0
sliderHandle.Parent = sliderBackground

local sliderHandleCorner = Instance.new("UICorner")
sliderHandleCorner.CornerRadius = UDim.new(0, 10)
sliderHandleCorner.Parent = sliderHandle

-- Helper function: update speed from slider position
local function updateSpeedFromSlider()
    local sliderWidth = sliderBackground.AbsoluteSize.X - sliderHandle.AbsoluteSize.X
    local sliderX = sliderHandle.Position.X.Offset
    local proportion = math.clamp(sliderX / sliderWidth, 0, 1)
    local newSpeed = math.floor(proportion * (walkSpeedMax - walkSpeedMin) + walkSpeedMin)
    currentWalkSpeed = newSpeed
    speedInputBox.Text = tostring(newSpeed)
    humanoid.WalkSpeed = speedEnabled and currentWalkSpeed or walkSpeedNormal
end

-- Slider dragging logic
local dragging = false
local dragStart = nil
local handleStartPos = nil

sliderHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position.X
        handleStartPos = sliderHandle.Position.X.Offset
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

sliderBackground.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local relativeX = input.Position.X - sliderBackground.AbsolutePosition.X
        local posOffset = math.clamp(relativeX - sliderHandle.AbsoluteSize.X/2, 0, sliderBackground.AbsoluteSize.X - sliderHandle.AbsoluteSize.X)
        sliderHandle.Position = UDim2.new(0, posOffset, 0, 0)
        updateSpeedFromSlider()
    end
end)

RunService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position.X - dragStart
        local newPos = math.clamp(handleStartPos + delta, 0, sliderBackground.AbsoluteSize.X - sliderHandle.AbsoluteSize.X)
        sliderHandle.Position = UDim2.new(0, newPos, 0, 0)
        updateSpeedFromSlider()
    end
end)

-- InputBox focus lost event to update speed from typed value
speedInputBox.FocusLost:Connect(function(enterPressed)
    local val = tonumber(speedInputBox.Text)
    if val then
        val = math.clamp(val, walkSpeedMin, walkSpeedMax)
        currentWalkSpeed = val
        humanoid.WalkSpeed = speedEnabled and currentWalkSpeed or walkSpeedNormal
        -- Update slider position accordingly
        local sliderWidth = sliderBackground.AbsoluteSize.X - sliderHandle.AbsoluteSize.X
        local proportion = (val - walkSpeedMin) / (walkSpeedMax - walkSpeedMin)
        sliderHandle.Position = UDim2.new(0, proportion * sliderWidth, 0, 0)
        speedInputBox.Text = tostring(val) -- ensure formatting is fixed
    else
        -- Reset to current speed if input invalid
        speedInputBox.Text = tostring(currentWalkSpeed)
    end
end)

-- WalkSpeed toggle flag and button for it
local speedEnabled = true

-- Optional: Create a simple button to toggle speed ON/OFF
-- You can add it below if you want; for simplicity, it's omitted. Otherwise,
-- just set `speedEnabled` to true always.

print("Instant ProximityPrompt activator and WalkSpeed adjuster loaded")
