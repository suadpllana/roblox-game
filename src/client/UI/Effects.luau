-- Small client-side behaviours: prompt visibility, rainbow plushies, knockback, VIP chat tag.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

local player = Players.LocalPlayer

local Effects = {}

-- Owners only see "Sell" on their plushies; everyone else only sees "Steal".
local function setupPromptFilter()
	local function apply(prompt: Instance, ownerOnly: boolean)
		if not prompt:IsA("ProximityPrompt") then
			return
		end
		local isMine = prompt:GetAttribute("OwnerId") == player.UserId
		prompt.Enabled = if ownerOnly then isMine else not isMine
	end
	for tag, ownerOnly in { OwnerOnlyPrompt = true, OthersOnlyPrompt = false } do
		for _, prompt in CollectionService:GetTagged(tag) do
			apply(prompt, ownerOnly)
		end
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(prompt)
			apply(prompt, ownerOnly)
		end)
	end
end

local function setupRainbow()
	local models: { [Instance]: boolean } = {}
	for _, model in CollectionService:GetTagged("Rainbow") do
		models[model] = true
	end
	CollectionService:GetInstanceAddedSignal("Rainbow"):Connect(function(model)
		models[model] = true
	end)
	CollectionService:GetInstanceRemovedSignal("Rainbow"):Connect(function(model)
		models[model] = nil
	end)
	RunService.RenderStepped:Connect(function()
		local hue = (os.clock() * 0.25) % 1
		for model in models do
			if not model.Parent then
				models[model] = nil
				continue
			end
			for _, part in model:GetChildren() do
				if part:IsA("BasePart") and part.Name ~= "Root" and part.Material == Enum.Material.Neon then
					part.Color = Color3.fromHSV(hue, 0.8, 1)
				end
			end
		end
	end)
end

local function setupKnockback()
	Remotes.Get("Knockback").OnClientEvent:Connect(function(velocity: Vector3)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid then
			humanoid:ChangeState(Enum.HumanoidStateType.FallingDown)
			root.AssemblyLinearVelocity = velocity
		end
	end)
end

local function setupChatTags()
	TextChatService.OnIncomingMessage = function(message: TextChatMessage)
		local properties = Instance.new("TextChatMessageProperties")
		local source = message.TextSource
		local speaker = source and Players:GetPlayerByUserId(source.UserId)
		if speaker and speaker:GetAttribute("Pass_VIP") then
			properties.PrefixText = `<font color="#FFCD3C">[VIP]</font> {message.PrefixText}`
		end
		return properties
	end
end

function Effects.Init()
	setupPromptFilter()
	setupRainbow()
	setupKnockback()
	pcall(setupChatTags)
end

return Effects
