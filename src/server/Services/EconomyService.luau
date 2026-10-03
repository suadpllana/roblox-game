--[[
	Cash, income, multipliers, collecting and rebirths.
	Every cash change goes through here so the HUD always stays in sync.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Plushies = require(ReplicatedStorage.Shared.Plushies)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local EconomyService = {}

local Services
local DataService
local notify: RemoteEvent
local announce: RemoteEvent
local lastRebirthRequest: { [Player]: number } = {}

function EconomyService:Init(services)
	Services = services
	DataService = services.DataService
	notify = Remotes.Get("Notify")
	announce = Remotes.Get("Announce")

	Remotes.Get("RequestRebirth").OnServerEvent:Connect(function(player)
		local last = lastRebirthRequest[player]
		if last and os.clock() - last < 1 then
			return
		end
		lastRebirthRequest[player] = os.clock()
		self:Rebirth(player)
	end)
end

function EconomyService:Start()
	while true do
		task.wait(1)
		for _, player in Players:GetPlayers() do
			local data = DataService:Get(player)
			if not data then
				continue
			end
			local income = self:GetIncome(player)
			if income > 0 then
				if Services.MonetizationService:HasPass(player, "AutoCollect") then
					data.Cash += income
				else
					data.Uncollected += income
				end
				data.TotalEarned += income
			end
			self:RefreshStats(player)
		end
	end
end

function EconomyService:GetMultiplier(player: Player): number
	local data = DataService:Get(player)
	if not data then
		return 1
	end
	local economy = Config.Economy
	local multiplier = 1 + data.Rebirths * economy.RebirthMultiplierBonus
	if Services.MonetizationService:HasPass(player, "DoubleCash") then
		multiplier *= economy.DoubleCashMultiplier
	end
	if Services.MonetizationService:HasPass(player, "VIP") then
		multiplier *= economy.VIPMultiplier
	end
	if player.MembershipType == Enum.MembershipType.Premium then
		multiplier *= economy.PremiumMultiplier
	end
	if player:GetAttribute("InGroup") then
		multiplier *= economy.GroupMultiplier
	end
	multiplier *= 1 + ((player:GetAttribute("FriendBonus") or 0) :: number)
	return multiplier
end

function EconomyService:GetBaseIncome(player: Player): number
	local total = 0
	for _, entry in Services.BaseService:GetActiveEntries(player) do
		total += Plushies.GetIncome(entry.Id, entry.Mutation)
	end
	return total
end

function EconomyService:GetIncome(player: Player): number
	return self:GetBaseIncome(player) * self:GetMultiplier(player)
end

function EconomyService:AddCash(player: Player, amount: number)
	local data = DataService:Get(player)
	if not data or amount <= 0 or amount ~= amount then
		return
	end
	data.Cash += amount
	data.TotalEarned += amount
	self:RefreshStats(player)
end

function EconomyService:TrySpend(player: Player, amount: number): boolean
	local data = DataService:Get(player)
	if not data or amount < 0 or data.Cash < amount then
		return false
	end
	data.Cash -= amount
	self:RefreshStats(player)
	return true
end

function EconomyService:Collect(player: Player)
	local data = DataService:Get(player)
	if not data or data.Uncollected < 1 then
		return
	end
	local amount = data.Uncollected
	data.Uncollected = 0
	data.Cash += amount
	self:RefreshStats(player)
	notify:FireClient(player, "+" .. Format.Cash(amount), "cash")
end

function EconomyService:Rebirth(player: Player)
	local data = DataService:Get(player)
	if not data then
		return
	end
	local cost = Config.RebirthCost(data.Rebirths)
	if data.Cash < cost then
		notify:FireClient(player, `You need {Format.Cash(cost)} to rebirth.`, "error")
		return
	end
	Services.StealService:CancelAllFor(player)
	data.Rebirths += 1
	data.Cash = Config.StartingCash
	data.Uncollected = 0
	data.Plushies = { { Id = Config.StartingPlushie, Mutation = "None", Slot = 1 } }
	Services.BaseService:RenderAll(player)
	self:RefreshStats(player)
	local multiplier = 1 + data.Rebirths * Config.Economy.RebirthMultiplierBonus
	notify:FireClient(player, `Rebirth {data.Rebirths}! Permanent x{multiplier} cash and +1 slot.`, "success")
	announce:FireAllClients(`{player.DisplayName} just reached Rebirth {data.Rebirths}!`, Color3.fromRGB(255, 220, 80))
end

function EconomyService:RefreshStats(player: Player)
	local data = DataService:Get(player)
	if not data then
		return
	end
	local baseService = Services.BaseService
	player:SetAttribute("Cash", data.Cash)
	player:SetAttribute("Uncollected", data.Uncollected)
	player:SetAttribute("Income", self:GetIncome(player))
	player:SetAttribute("Multiplier", self:GetMultiplier(player))
	player:SetAttribute("Rebirths", data.Rebirths)
	player:SetAttribute("RebirthCost", Config.RebirthCost(data.Rebirths))
	player:SetAttribute("SlotCount", baseService:GetSlotCount(player))
	player:SetAttribute("PlushieCount", #baseService:GetActiveEntries(player))
	player:SetAttribute("ShieldUntil", data.ShieldUntil or 0)

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		(leaderstats:FindFirstChild("Cash") :: StringValue).Value = Format.Cash(data.Cash);
		(leaderstats:FindFirstChild("Rebirths") :: IntValue).Value = data.Rebirths;
		(leaderstats:FindFirstChild("Steals") :: IntValue).Value = data.Steals
	end
end

function EconomyService:OnPlayerLoaded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local cash = Instance.new("StringValue")
	cash.Name = "Cash"
	cash.Parent = leaderstats
	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Parent = leaderstats
	local steals = Instance.new("IntValue")
	steals.Name = "Steals"
	steals.Parent = leaderstats
	leaderstats.Parent = player
	self:RefreshStats(player)
end

function EconomyService:OnPlayerRemoving(player: Player)
	lastRebirthRequest[player] = nil
end

return EconomyService
