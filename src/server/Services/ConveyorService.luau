--[[
	Spawns random plushies at the factory end of the lane and slides them along
	the conveyor. Anyone can buy one while it passes by - first come, first served.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Plushies = require(ReplicatedStorage.Shared.Plushies)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlushieFactory = require(script.Parent.PlushieFactory)

local ConveyorService = {}

local Services
local MapBuilder
local notify: RemoteEvent
local announce: RemoteEvent
local folder: Folder
local rng = Random.new()
local items = {}

local function removeItem(item)
	local index = table.find(items, item)
	if index then
		table.remove(items, index)
	end
	if item.Model then
		item.Model:Destroy()
		item.Model = nil
	end
end

function ConveyorService:Init(services)
	Services = services
	MapBuilder = services.MapBuilder
	notify = Remotes.Get("Notify")
	announce = Remotes.Get("Announce")
	folder = Instance.new("Folder")
	folder.Name = "ConveyorPlushies"
	folder.Parent = workspace
end

function ConveyorService:GetLuck(): number
	local luckUntil = ReplicatedStorage:GetAttribute("ServerLuckUntil") or 0
	if luckUntil > workspace:GetServerTimeNow() then
		return Config.ServerLuck.Multiplier
	end
	return 1
end

function ConveyorService:SpawnPlushie(id: string?, mutation: string?)
	if not id then
		id, mutation = Plushies.RollPlushie(rng, self:GetLuck())
	end
	local def = Plushies.Get(id :: string)
	local startX = MapBuilder.LANE_START_X + 4
	local position = Vector3.new(startX, MapBuilder.LANE_TOP, 0)
	local ground = CFrame.lookAt(position, position + Vector3.xAxis)
	local model = PlushieFactory.Build(def.Id, mutation, "Conveyor", ground)
	if not model then
		return
	end
	local root = model.PrimaryPart :: BasePart
	local price = Plushies.GetPrice(def.Id, mutation)
	local item = { Model = model, Root = root, Id = def.Id, Mutation = mutation or "None", Price = price, Sold = false }

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ActionText = "Buy " .. Format.Cash(price)
	prompt.ObjectText = Plushies.DisplayName(def.Id, mutation)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	prompt.Triggered:Connect(function(player)
		self:TryBuy(player, item)
	end)

	model.Parent = folder
	root:SetNetworkOwner(nil)
	table.insert(items, item)

	local isRainbow = item.Mutation == "Rainbow"
	if Config.Conveyor.AnnounceRarities[def.Rarity] or isRainbow then
		local rarity = Plushies.GetRarity(def.Rarity)
		announce:FireAllClients(
			`A {def.Rarity:upper()} {Plushies.DisplayName(def.Id, mutation)} is on the conveyor!`,
			rarity.Color
		)
	end
end

function ConveyorService:TryBuy(player: Player, item)
	if item.Sold or not item.Model then
		return
	end
	local baseService = Services.BaseService
	if not baseService:GetBase(player) then
		return
	end
	if not baseService:FindFreeSlot(player) then
		notify:FireClient(player, "Your base is full! Sell a plushie (hold F) or rebirth.", "error")
		return
	end
	if not Services.EconomyService:TrySpend(player, item.Price) then
		notify:FireClient(player, `You need {Format.Cash(item.Price)}!`, "error")
		return
	end
	item.Sold = true
	removeItem(item)
	baseService:AddPlushie(player, item.Id, item.Mutation)
	local name = Plushies.DisplayName(item.Id, item.Mutation)
	notify:FireClient(player, `You bought {name}! It's in your base.`, "success")
	local def = Plushies.Get(item.Id)
	if Config.Conveyor.AnnounceRarities[def.Rarity] then
		announce:FireAllClients(`{player.DisplayName} bought the {name}! Go steal it!`, Plushies.GetRarity(def.Rarity).Color)
	end
end

function ConveyorService:Start()
	task.spawn(function()
		while true do
			task.wait(Config.Conveyor.SpawnInterval)
			if #items < Config.Conveyor.MaxItems and #Players:GetPlayers() > 0 then
				local ok, err = pcall(self.SpawnPlushie, self)
				if not ok then
					warn("[ConveyorService] spawn failed:", err)
				end
			end
		end
	end)

	local speed = Config.Conveyor.Speed
	RunService.Heartbeat:Connect(function()
		for index = #items, 1, -1 do
			local item = items[index]
			local root = item.Root
			if not root or not root.Parent then
				removeItem(item)
				continue
			end
			local position = root.Position
			if position.X > MapBuilder.LANE_END_X or position.Y < -20 then
				removeItem(item)
				continue
			end
			-- Drive the plushie directly so it never stalls, tips over or drifts.
			if root.CFrame.UpVector.Y < 0.95 or math.abs(position.Z) > 3 then
				root.CFrame = CFrame.lookAt(Vector3.new(position.X, position.Y + 0.2, 0), Vector3.new(position.X + 1, position.Y + 0.2, 0))
			end
			root.AssemblyLinearVelocity = Vector3.new(speed, math.min(root.AssemblyLinearVelocity.Y, 0), 0)
			root.AssemblyAngularVelocity = Vector3.zero
		end
	end)
end

return ConveyorService
