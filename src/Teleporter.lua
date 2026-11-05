--[[
	Teleporter
	Placed in: ServerScriptService

	Teleports the player to the "best" enemy NPC (highest priority) that is
	still alive. When that NPC dies, it automatically switches to the next
	best alive NPC.

	The feature is toggled on/off per player via a RemoteEvent that the GUI
	button (client-side) fires.

	Enemies are NPCs. They must have a Humanoid whose Name appears in the
	priority list below, and (optionally) a CollectionService tag.
]]

local Teleporter = {}

-- List of enemy names in priority order. The first entry is the "best".
Teleporter.EnemyPriority = {
	"Boss",
	"Miniboss",
	"Elite",
	"Ranger",
	"Melee Minion",
	"Grunt",
}

-- Optional CollectionService tag that marks NPCs as enemies.
-- Set to "" to disable tag matching (match by Humanoid.Name only).
Teleporter.EnemyTag = "Enemy"

-- Interval (seconds) between teleport attempts.
Teleporter.TeleportInterval = 1

-- The name of the RemoteEvent used to receive toggle commands.
Teleporter.ToggleEventName = "TeleportToggle"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

-- Build the priority ranks once.
local RankOf = {}
for index, name in ipairs(Teleporter.EnemyPriority) do
	RankOf[name] = index
end

-- Cache the RemoteEvent so the client can find it easily.
local toggleEvent

-- Map: player -> true/false (whether teleporting is active).
local enabledMap = {}
-- Map: player -> coroutine thread handling their teleport loop.
local threads = {}

local function getToggleEvent()
	if not toggleEvent then
		local parent = ReplicatedStorage:FindFirstChild("Remotes")
		if not parent then
			parent = Instance.new("Folder")
			parent.Name = "Remotes"
			parent.Parent = ReplicatedStorage
		end
		toggleEvent = Instance.new("RemoteEvent")
		toggleEvent.Name = Teleporter.ToggleEventName
		toggleEvent.Parent = parent
	end
	return toggleEvent
end

-- Returns the name from the Humanoid (fallback: the NPC's instance name).
local function enemyName(npc)
	local hum = npc:FindFirstChildOfClass("Humanoid")
	if hum then
		return hum.Name
	end
	return npc.Name
end

local function isEnemy(npc)
	if Teleporter.EnemyTag ~= "" and not CollectionService:HasTag(npc, Teleporter.EnemyTag) then
		return false
	end
	return RankOf[enemyName(npc)] ~= nil
end

-- Returns a list of candidate NPC instances.
local function getCandidates()
	if Teleporter.EnemyTag ~= "" then
		return CollectionService:GetTagged(Teleporter.EnemyTag)
	end
	local candidates = {}
	for _, npc in ipairs(workspace:GetDescendants()) do
		if npc:FindFirstChildOfClass("Humanoid") then
			table.insert(candidates, npc)
		end
	end
	return candidates
end

local function isAlive(npc)
	local hum = npc:FindFirstChildOfClass("Humanoid")
	if not hum then
		return false
	end
	return hum.Health > 0
end

-- Returns the best alive enemy within reach, or nil.
local function findBestTarget(player)
	local character = player.Character
	if not character then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return nil
	end

	local best = nil
	local bestRank = math.huge

	for _, npc in ipairs(getCandidates()) do
		if npc ~= character and isEnemy(npc) and isAlive(npc) then
			local name = enemyName(npc)
			local rank = RankOf[name]
			if rank and rank < bestRank then
				local enemyRoot = npc:FindFirstChild("HumanoidRootPart")
				if enemyRoot then
					best = npc
					bestRank = rank
				end
			end
		end
	end

	return best
end

local function teleportPlayer(player)
	local character = player.Character
	if not character then
		return
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end

	local target = findBestTarget(player)
	if not target then
		return
	end

	local targetRoot = target:FindFirstChild("HumanoidRootPart")
	if not targetRoot then
		return
	end

	local cameraCFrame = targetRoot.CFrame
	-- Place the player a few studs in front of the target, facing it.
	local position = cameraCFrame.Position + cameraCFrame.LookVector * 4

	local hum = character:FindFirstChildOfClass("Humanoid")
	if hum and hum.Sit then
		hum.Sit = false
	end

	root.CFrame = CFrame.new(position, targetRoot.Position)
end

local function stopThread(player)
	local thread = threads[player]
	if thread then
		task.cancel(thread)
		threads[player] = nil
	end
end

local function startThread(player)
	if enabledMap[player] == false then
		return
	end
	stopThread(player)
	threads[player] = task.spawn(function()
		while true do
			if not enabledMap[player] then
				break
			end
			teleportPlayer(player)
			task.wait(Teleporter.TeleportInterval)
		end
		threads[player] = nil
	end)
end

local function setEnabled(player, enabled)
	enabledMap[player] = enabled
	if enabled then
		startThread(player)
	else
		stopThread(player)
	end
end

-- Client fires this to set the feature on/off.
local function onToggle(player, enabled)
	setEnabled(player, enabled == true)
end

-- Initialise for a player joining.
local function setupPlayer(player)
	enabledMap[player] = false
	getToggleEvent():FireClient(player, false) -- start disabled

	player.CharacterAdded:Connect(function()
		if enabledMap[player] then
			startThread(player)
		end
	end)

	player:AncestryChanged:Connect(function()
		if not player.Parent then
			enabledMap[player] = nil
			stopThread(player)
		end
	end)
end

getToggleEvent().OnServerEvent:Connect(onToggle)

Players.PlayerAdded:Connect(setupPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

return Teleporter
