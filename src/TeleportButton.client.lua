--[[
	TeleportButton
	Placed in: StarterPlayerScripts (or StarterGui)

	Creates a draggable on/off GUI button that toggles teleporting to the
	best alive enemy NPC. Dragging is done by holding the left mouse button
	and moving; releasing keeps the button where it is.

	The button fires a RemoteEvent on the server to turn teleporting on/off.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local toggleEvent = remotesFolder:WaitForChild("TeleportToggle")

-- ---------------------------------------------------------------------------
-- Build the UI
-- ---------------------------------------------------------------------------

local screen = Instance.new("ScreenGui")
screen.Name = "TeleportButtonGui"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.Parent = playerGui

local button = Instance.new("TextButton")
button.Name = "TeleportToggleButton"
button.Size = UDim2.fromOffset(140, 40)
button.Position = UDim2.fromOffset(16, 16)
button.BackgroundColor3 = Color3.fromRGB(40, 160, 60)
button.BackgroundTransparency = 0.25
button.BorderSizePixel = 2
button.BorderColor3 = Color3.fromRGB(20, 90, 35)
button.Text = "Teleport: ON"
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.Font = Enum.Font.GothamBold
button.TextSize = 16
button.Parent = screen

local healthbarShadow = Instance.new("UIStroke")
healthbarShadow.Color = Color3.fromRGB(0, 0, 0)
healthbarShadow.Thickness = 2
healthbarShadow.Parent = button

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------

local enabled = false
local dragging = false
local moved = false
local dragOffset = Vector2.zero

local function setEnabled(newValue)
	enabled = newValue
	button.Text = enabled and "Teleport: ON" or "Teleport: OFF"
	button.BackgroundColor3 = enabled and Color3.fromRGB(40, 160, 60) or Color3.fromRGB(180, 40, 40)
	button.BorderColor3 = enabled and Color3.fromRGB(20, 90, 35) or Color3.fromRGB(100, 20, 20)
	toggleEvent:FireServer(enabled)
end

-- ---------------------------------------------------------------------------
-- Dragging
-- ---------------------------------------------------------------------------

button.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end
	dragging = true
	moved = false
	dragOffset = input.Position - button.AbsolutePosition
end)

button.InputChanged:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - (button.AbsolutePosition + dragOffset)
		if delta.Magnitude > 2 then
			moved = true
		end
		local newPos = input.Position - dragOffset
		-- Keep the button within the screen bounds.
		local maxX = math.max(0, screen.AbsoluteSize.X - button.AbsoluteSize.X)
		local maxY = math.max(0, screen.AbsoluteSize.Y - button.AbsoluteSize.Y)
		newPos = Vector2.new(
			math.clamp(newPos.X, 0, maxX),
			math.clamp(newPos.Y, 0, maxY)
		)
		button.Position = UDim2.fromOffset(newPos.X, newPos.Y)
	end
end)

button.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

-- ---------------------------------------------------------------------------
-- Toggle on click (only when not dragging)
-- ---------------------------------------------------------------------------

button.MouseButton1Click:Connect(function()
	if not moved then
		setEnabled(not enabled)
	end
end)

-- ---------------------------------------------------------------------------
-- Startup
-- ---------------------------------------------------------------------------

local function updateUI(newEnabled)
	enabled = newEnabled
	button.Text = enabled and "Teleport: ON" or "Teleport: OFF"
	button.BackgroundColor3 = enabled and Color3.fromRGB(40, 160, 60) or Color3.fromRGB(180, 40, 40)
	button.BorderColor3 = enabled and Color3.fromRGB(20, 90, 35) or Color3.fromRGB(100, 20, 20)
end

-- Listen for the server's initial state so the button matches.
toggleEvent.OnClientEvent:Connect(function(initialEnabled)
	updateUI(initialEnabled == true)
end)

updateUI(false)
