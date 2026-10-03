--[[
	Everyone spawns with a Bonk Bat. Hitting a thief makes them drop the plushie
	they're carrying; hitting anyone knocks them back.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPack = game:GetService("StarterPack")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local TOOL_NAME = "Bonk Bat"
local COOLDOWN = 0.7
local RANGE = 9
local GRIP = CFrame.new(0, -1.3, 0)

local CombatService = {}

local Services
local knockback: RemoteEvent
local lastSwing: { [Player]: number } = {}
local hooked = setmetatable({}, { __mode = "k" })

local function buildTool(): Tool
	local tool = Instance.new("Tool")
	tool.Name = TOOL_NAME
	tool.ToolTip = "Bonk thieves to make them drop your plushie!"
	tool.CanBeDropped = false
	tool.Grip = GRIP

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.45, 3.2, 0.45)
	handle.Color = Color3.fromRGB(150, 100, 60)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local barrel = Instance.new("Part")
	barrel.Name = "Barrel"
	barrel.Shape = Enum.PartType.Cylinder
	barrel.Size = Vector3.new(1.8, 1, 1)
	barrel.CFrame = handle.CFrame * CFrame.new(0, 1.6, 0) * CFrame.Angles(0, 0, math.rad(90))
	barrel.Color = Color3.fromRGB(255, 120, 170)
	barrel.Material = Enum.Material.SmoothPlastic
	barrel.CanCollide = false
	barrel.Massless = true
	barrel.Parent = tool
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = barrel
	weld.Parent = barrel

	local sound = Instance.new("Sound")
	sound.Name = "Swing"
	sound.SoundId = "rbxasset://sounds/swordslash.wav"
	sound.Volume = 0.6
	sound.Parent = handle

	return tool
end

function CombatService:_swing(player: Player, tool: Tool)
	local last = lastSwing[player]
	if last and os.clock() - last < COOLDOWN then
		return
	end
	lastSwing[player] = os.clock()

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return
	end

	local handle = tool:FindFirstChild("Handle")
	local sound = handle and handle:FindFirstChild("Swing") :: Sound?
	if sound then
		sound:Play()
	end
	tool.Grip = GRIP * CFrame.Angles(math.rad(-90), 0, 0)
	task.delay(0.2, function()
		tool.Grip = GRIP
	end)

	for _, other in Players:GetPlayers() do
		if other == player or not other.Character then
			continue
		end
		local otherRoot = other.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local otherHumanoid = other.Character:FindFirstChildOfClass("Humanoid")
		if not otherRoot or not otherHumanoid or otherHumanoid.Health <= 0 then
			continue
		end
		local offset = otherRoot.Position - root.Position
		local distance = offset.Magnitude
		if distance > RANGE or distance < 0.01 then
			continue
		end
		local direction = offset.Unit
		if distance > 4 and root.CFrame.LookVector:Dot(direction) < 0.2 then
			continue
		end
		local flat = Vector3.new(direction.X, 0, direction.Z)
		flat = if flat.Magnitude > 0 then flat.Unit else root.CFrame.LookVector
		knockback:FireClient(other, flat * 55 + Vector3.new(0, 30, 0))
		if Services.StealService:IsCarrying(other) then
			Services.StealService:Drop(other, `bonked by {player.DisplayName}`)
		end
	end
end

function CombatService:_hookTool(player: Player, tool: Instance)
	if not tool:IsA("Tool") or tool.Name ~= TOOL_NAME or hooked[tool] then
		return
	end
	hooked[tool] = true
	tool.Activated:Connect(function()
		self:_swing(player, tool)
	end)
end

function CombatService:Init(services)
	Services = services
	knockback = Remotes.Get("Knockback")

	if not StarterPack:FindFirstChild(TOOL_NAME) then
		buildTool().Parent = StarterPack
	end

	local function watch(player: Player)
		local function watchContainer(container: Instance)
			for _, child in container:GetChildren() do
				self:_hookTool(player, child)
			end
			container.ChildAdded:Connect(function(child)
				self:_hookTool(player, child)
			end)
		end
		local backpack = player:WaitForChild("Backpack", 10)
		if backpack then
			watchContainer(backpack)
		end
		player.CharacterAdded:Connect(function(character)
			watchContainer(character)
			local newBackpack = player:WaitForChild("Backpack", 10)
			if newBackpack and newBackpack ~= backpack then
				backpack = newBackpack
				watchContainer(newBackpack)
			end
		end)
		if player.Character then
			watchContainer(player.Character)
		end
	end
	Players.PlayerAdded:Connect(function(player)
		task.spawn(watch, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(watch, player)
	end
end

function CombatService:OnPlayerRemoving(player: Player)
	lastSwing[player] = nil
end

return CombatService
