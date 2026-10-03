--[[
	Game passes, developer products and Premium benefits.

	Developer products are granted inside ProcessReceipt and recorded per player,
	so a purchase is never lost and never granted twice.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Plushies = require(ReplicatedStorage.Shared.Plushies)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local MonetizationService = {}

local Services
local DataService
local notify: RemoteEvent
local announce: RemoteEvent
local rng = Random.new()

local owned: { [Player]: { [string]: boolean } } = {}
local passById: { [number]: any } = {}
local productById: { [number]: any } = {}
local lastRequest: { [Player]: number } = {}

local MYSTERY_BOX_ODDS = { Epic = 70, Legendary = 25, Mythic = 4.5, Secret = 0.5 }

function MonetizationService:Init(services)
	Services = services
	DataService = services.DataService
	notify = Remotes.Get("Notify")
	announce = Remotes.Get("Announce")

	for _, pass in Config.GamePasses do
		if pass.Id ~= 0 then
			passById[pass.Id] = pass
		end
	end
	for _, product in Config.Products do
		if product.Id ~= 0 then
			productById[product.Id] = product
		end
	end

	Remotes.Get("RequestPurchase").OnServerEvent:Connect(function(player, kind, key)
		if type(kind) ~= "string" or type(key) ~= "string" then
			return
		end
		local last = lastRequest[player]
		if last and os.clock() - last < 0.5 then
			return
		end
		lastRequest[player] = os.clock()
		self:_handlePurchaseRequest(player, kind, key)
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local pass = passById[passId]
		if purchased and pass then
			self:GrantPass(player, pass.Key)
		end
	end)

	MarketplaceService.ProcessReceipt = function(receipt)
		return self:_processReceipt(receipt)
	end

	Players.PlayerMembershipChanged:Connect(function(player)
		Services.EconomyService:RefreshStats(player)
	end)
end

function MonetizationService:_handlePurchaseRequest(player: Player, kind: string, key: string)
	if kind == "Pass" then
		local pass = Config.GetPass(key)
		if not pass then
			return
		end
		if self:HasPass(player, key) then
			notify:FireClient(player, `You already own {pass.Name}!`, "info")
		elseif pass.Id ~= 0 then
			MarketplaceService:PromptGamePassPurchase(player, pass.Id)
		elseif RunService:IsStudio() then
			self:GrantPass(player, key)
			notify:FireClient(player, "(Studio test) Pass granted for this session.", "info")
		else
			notify:FireClient(player, "This item isn't available yet - check back soon!", "error")
		end
	elseif kind == "Product" then
		local product = Config.GetProduct(key)
		if not product then
			return
		end
		if product.Id ~= 0 then
			MarketplaceService:PromptProductPurchase(player, product.Id)
		elseif RunService:IsStudio() then
			self:GrantProduct(player, product)
			notify:FireClient(player, "(Studio test) Product granted for free.", "info")
		else
			notify:FireClient(player, "This item isn't available yet - check back soon!", "error")
		end
	end
end

function MonetizationService:_processReceipt(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local product = productById[receipt.ProductId]
	if not player or not product then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	-- Data can still be loading if they bought something right after joining.
	local waited = 0
	while not DataService:Get(player) and player.Parent and waited < 15 do
		waited += task.wait(0.5)
	end
	if not DataService:Get(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local receiptId = tostring(receipt.PurchaseId)
	if DataService:HasReceipt(player, receiptId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local ok, err = pcall(self.GrantProduct, self, player, product)
	if not ok then
		warn("[MonetizationService] Failed to grant", product.Key, err)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	DataService:AddReceipt(player, receiptId)
	if DataService:CanSave(player) and not DataService:Save(player, false) then
		-- Recorded in memory, so a retry in this server will not grant it twice.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService:HasPass(player: Player, key: string): boolean
	local passes = owned[player]
	return passes ~= nil and passes[key] == true
end

function MonetizationService:GetWalkSpeed(player: Player): number
	if self:HasPass(player, "Speed") then
		return Config.Movement.SpeedPassWalkSpeed
	end
	return Config.Movement.WalkSpeed
end

function MonetizationService:_applyWalkSpeed(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and not Services.StealService:IsCarrying(player) then
		humanoid.WalkSpeed = self:GetWalkSpeed(player)
	end
end

function MonetizationService:GrantPass(player: Player, key: string)
	owned[player] = owned[player] or {}
	if owned[player][key] then
		return
	end
	owned[player][key] = true
	player:SetAttribute("Pass_" .. key, true)
	if key == "Speed" then
		self:_applyWalkSpeed(player)
	elseif key == "ExtraSlots" then
		Services.BaseService:RenderAll(player)
	end
	Services.EconomyService:RefreshStats(player)
	local pass = Config.GetPass(key)
	if pass then
		notify:FireClient(player, `Thanks for buying {pass.Name}! 💖`, "success")
	end
end

function MonetizationService:GiveMysteryBox(player: Player, source: string)
	local id, mutation = Plushies.RollPlushie(rng, 1, MYSTERY_BOX_ODDS)
	local name = Plushies.DisplayName(id, mutation)
	local def = Plushies.Get(id)
	if Services.BaseService:AddPlushie(player, id, mutation) then
		notify:FireClient(player, `{source}: you got {def.Rarity} {name}! 🎁`, "success")
	else
		local value = Plushies.GetPrice(id, mutation)
		Services.EconomyService:AddCash(player, value)
		notify:FireClient(player, `{source}: {name}! Your base was full, so you got {Format.Cash(value)} instead.`, "success")
	end
	if Config.Conveyor.AnnounceRarities[def.Rarity] then
		announce:FireAllClients(`{player.DisplayName} unboxed a {def.Rarity:upper()} {name}!`, Plushies.GetRarity(def.Rarity).Color)
	end
end

function MonetizationService:GrantProduct(player: Player, product)
	local data = DataService:Get(player)
	if not data then
		error("player data not loaded")
	end
	if product.Kind == "Cash" then
		local amount = math.max(product.Floor, Services.EconomyService:GetIncome(player) * product.Seconds)
		Services.EconomyService:AddCash(player, amount)
		notify:FireClient(player, `+{Format.Cash(amount)}! Thanks for your support 💖`, "cash")
	elseif product.Kind == "ServerLuck" then
		local now = workspace:GetServerTimeNow()
		local current = ReplicatedStorage:GetAttribute("ServerLuckUntil") or 0
		ReplicatedStorage:SetAttribute("ServerLuckUntil", math.max(now, current) + Config.ServerLuck.Duration)
		ReplicatedStorage:SetAttribute("ServerLuckBy", player.DisplayName)
		announce:FireAllClients(`🍀 {player.DisplayName} activated 2x SERVER LUCK for everyone!`, Color3.fromRGB(90, 255, 120))
	elseif product.Kind == "Shield" then
		data.ShieldUntil = math.max(os.time(), data.ShieldUntil or 0) + Config.Shield.Duration
		Services.EconomyService:RefreshStats(player)
		notify:FireClient(player, "🛡️ Steal Shield active for 30 minutes!", "success")
	elseif product.Kind == "MysteryBox" then
		self:GiveMysteryBox(player, "Mystery Box")
	else
		error("unknown product kind " .. tostring(product.Kind))
	end
end

function MonetizationService:OnPlayerLoaded(player: Player)
	owned[player] = owned[player] or {}
	for _, pass in Config.GamePasses do
		if pass.Id ~= 0 then
			local ok, result = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.Id)
			if ok and result then
				owned[player][pass.Key] = true
				player:SetAttribute("Pass_" .. pass.Key, true)
			end
		end
	end
	player.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid", 5)
		self:_applyWalkSpeed(player)
	end)
	self:_applyWalkSpeed(player)
end

function MonetizationService:OnPlayerRemoving(player: Player)
	owned[player] = nil
	lastRequest[player] = nil
end

return MonetizationService
