--[[
	Owns the 8 player bases: assigning them, showing each player's plushies on
	their pedestals, selling, locking, collect pads, and keeping intruders out
	of locked bases.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Plushies = require(ReplicatedStorage.Shared.Plushies)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local PlushieFactory = require(script.Parent.PlushieFactory)

local BaseService = {}

local Services
local MapBuilder
local DataService

local baseOf: { [Player]: any } = {}
local touchDebounce: { [Player]: { [string]: number } } = {}
local notify: RemoteEvent

local function now(): number
	return workspace:GetServerTimeNow()
end

local function playerFromHit(hit: BasePart): Player?
	local character = hit:FindFirstAncestorOfClass("Model")
	if not character then
		return nil
	end
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return player
end

local function debounced(player: Player, pad: string): boolean
	local times = touchDebounce[player]
	if not times then
		times = {}
		touchDebounce[player] = times
	end
	local last = times[pad]
	if last and os.clock() - last < 0.5 then
		return true
	end
	times[pad] = os.clock()
	return false
end

local function collisionGroupFor(player: Player): string
	local base = baseOf[player]
	return if base then "Owner" .. base.Index else "Players"
end

local function applyCollisionGroup(player: Player, character: Model)
	local group = collisionGroupFor(player)
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = group
		end
	end
end

local function onCharacterAdded(player: Player, character: Model)
	applyCollisionGroup(player, character)
	character.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			descendant.CollisionGroup = collisionGroupFor(player)
		end
	end)
	local base = baseOf[player]
	if base then
		local root = character:WaitForChild("HumanoidRootPart", 5)
		if root then
			task.wait(0.15)
			if character.Parent and baseOf[player] == base then
				character:PivotTo(base.SpawnCFrame)
			end
		end
	end
end

function BaseService:Init(services)
	Services = services
	MapBuilder = services.MapBuilder
	DataService = services.DataService
	notify = Remotes.Get("Notify")

	for _, base in MapBuilder.Bases do
		base.Owner = nil
		base.Models = {}
		base.Stealing = {}
		base.LockedUntil = 0
		local plushieFolder = Instance.new("Folder")
		plushieFolder.Name = "Plushies"
		plushieFolder.Parent = base.Folder
		base.PlushieFolder = plushieFolder

		base.CollectPad.Touched:Connect(function(hit)
			local player = playerFromHit(hit)
			if player and baseOf[player] == base and not debounced(player, "collect") then
				Services.EconomyService:Collect(player)
			end
		end)
		base.LockPad.Touched:Connect(function(hit)
			local player = playerFromHit(hit)
			if player and baseOf[player] == base and not debounced(player, "lock") then
				self:Lock(player)
			end
		end)
	end

	local function onPlayerAdded(player: Player)
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
		if player.Character then
			task.spawn(onCharacterAdded, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

function BaseService:Start()
	while true do
		task.wait(0.25)
		local t = now()
		for _, base in MapBuilder.Bases do
			local owner = base.Owner
			if not owner then
				continue
			end
			local data = DataService:Get(owner)
			if base.LockedUntil > 0 and t >= base.LockedUntil then
				self:_setLocked(base, false)
			end
			local locked = base.LockedUntil > t
			if locked then
				base.LockLabel.Text = `🔒 LOCKED {math.ceil(base.LockedUntil - t)}s`
				-- Anyone who was already inside when the lock went up gets pushed out.
				for _, player in Players:GetPlayers() do
					if player ~= owner and player.Character then
						local root = player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
						if root and MapBuilder:IsInsideBase(base, root.Position) then
							Services.StealService:Drop(player, "pushed out of a locked base")
							player.Character:PivotTo(base.OutsideCFrame)
						end
					end
				end
			else
				base.LockLabel.Text = "🔒 LOCK BASE"
			end
			if data then
				base.CollectLabel.Text = "COLLECT\n" .. Format.Cash(data.Uncollected)
				local status = ""
				if (data.ShieldUntil or 0) > os.time() then
					status = "  🛡️"
				elseif locked then
					status = "  🔒"
				end
				for _, label in base.SignLabels do
					label.Text = owner.DisplayName .. "'s Base" .. status
				end
			end
		end
	end
end

function BaseService:GetBase(player: Player)
	return baseOf[player]
end

function BaseService:GetSlotCount(player: Player): number
	local data = DataService:Get(player)
	if not data then
		return 0
	end
	local count = Config.Base.StartSlots
		+ math.min(data.Rebirths * Config.Base.SlotsPerRebirth, Config.Base.MaxRebirthSlots)
	if Services.MonetizationService:HasPass(player, "ExtraSlots") then
		count += Config.Base.ExtraSlotsPass
	end
	return math.min(count, MapBuilder.MAX_SLOTS)
end

-- Plushies that are placed on an unlocked pedestal (the ones that earn money).
function BaseService:GetActiveEntries(player: Player)
	local data = DataService:Get(player)
	local active = {}
	if not data then
		return active
	end
	local count = self:GetSlotCount(player)
	for _, entry in data.Plushies do
		if entry.Slot >= 1 and entry.Slot <= count then
			table.insert(active, entry)
		end
	end
	return active
end

function BaseService:GetEntry(player: Player, slot: number)
	local data = DataService:Get(player)
	if not data then
		return nil, nil
	end
	for index, entry in data.Plushies do
		if entry.Slot == slot then
			return entry, index
		end
	end
	return nil, nil
end

function BaseService:FindFreeSlot(player: Player): number?
	local data = DataService:Get(player)
	if not data then
		return nil
	end
	local used = {}
	for _, entry in data.Plushies do
		used[entry.Slot] = true
	end
	for slot = 1, self:GetSlotCount(player) do
		if not used[slot] then
			return slot
		end
	end
	return nil
end

-- Fixes duplicate / missing slot numbers (e.g. after a pass was refunded).
function BaseService:_normalizeSlots(player: Player)
	local data = DataService:Get(player)
	local count = self:GetSlotCount(player)
	local used = {}
	local homeless = {}
	for _, entry in data.Plushies do
		if type(entry.Slot) ~= "number" or entry.Slot < 1 or entry.Slot > count or used[entry.Slot] then
			table.insert(homeless, entry)
		else
			used[entry.Slot] = true
		end
	end
	for _, entry in homeless do
		entry.Slot = 0
		for slot = 1, count do
			if not used[slot] then
				entry.Slot = slot
				used[slot] = true
				break
			end
		end
	end
end

function BaseService:_clearSlot(base, slot: number)
	local model = base.Models[slot]
	if model then
		model:Destroy()
		base.Models[slot] = nil
	end
end

function BaseService:RenderSlot(player: Player, slot: number)
	local base = baseOf[player]
	if not base then
		return
	end
	self:_clearSlot(base, slot)
	local pedestal = base.Pedestals[slot]
	local count = self:GetSlotCount(player)
	pedestal.LockedGui.Enabled = slot > count
	pedestal.Part.Transparency = if slot > count then 0.6 else 0
	if slot > count or base.Stealing[slot] then
		return
	end
	local entry = self:GetEntry(player, slot)
	if not entry then
		return
	end
	local model = PlushieFactory.Build(entry.Id, entry.Mutation, "Static", pedestal.StandCFrame)
	if not model then
		return
	end
	local root = model.PrimaryPart :: BasePart

	local sellValue = Plushies.GetPrice(entry.Id, entry.Mutation) * Config.Economy.SellRefund
	local sell = Instance.new("ProximityPrompt")
	sell.Name = "SellPrompt"
	sell.ActionText = "Sell " .. Format.Cash(sellValue)
	sell.ObjectText = Plushies.DisplayName(entry.Id, entry.Mutation)
	sell.HoldDuration = 0.8
	sell.MaxActivationDistance = 8
	sell.RequiresLineOfSight = false
	sell.KeyboardKeyCode = Enum.KeyCode.F
	sell:SetAttribute("OwnerId", player.UserId)
	CollectionService:AddTag(sell, "OwnerOnlyPrompt")
	sell.Parent = root
	sell.Triggered:Connect(function(who)
		if who == player then
			self:Sell(player, slot)
		end
	end)

	local steal = Instance.new("ProximityPrompt")
	steal.Name = "StealPrompt"
	steal.ActionText = "Steal"
	steal.ObjectText = Plushies.DisplayName(entry.Id, entry.Mutation)
	steal.HoldDuration = Config.Steal.HoldDuration
	steal.MaxActivationDistance = 8
	steal.RequiresLineOfSight = false
	steal:SetAttribute("OwnerId", player.UserId)
	CollectionService:AddTag(steal, "OthersOnlyPrompt")
	steal.Parent = root
	steal.Triggered:Connect(function(thief)
		Services.StealService:TryStart(thief, player, slot)
	end)

	model.Parent = base.PlushieFolder
	base.Models[slot] = model
end

function BaseService:RenderAll(player: Player)
	if not baseOf[player] then
		return
	end
	for slot = 1, MapBuilder.MAX_SLOTS do
		self:RenderSlot(player, slot)
	end
end

function BaseService:AddPlushie(player: Player, id: string, mutation: string?): boolean
	local data = DataService:Get(player)
	local slot = self:FindFreeSlot(player)
	if not data or not slot then
		return false
	end
	table.insert(data.Plushies, { Id = id, Mutation = mutation or "None", Slot = slot })
	self:RenderSlot(player, slot)
	Services.EconomyService:RefreshStats(player)
	return true
end

function BaseService:RemovePlushie(player: Player, slot: number)
	local data = DataService:Get(player)
	local entry, index = self:GetEntry(player, slot)
	if not data or not entry then
		return nil
	end
	table.remove(data.Plushies, index)
	local base = baseOf[player]
	if base then
		base.Stealing[slot] = nil
		self:_clearSlot(base, slot)
	end
	Services.EconomyService:RefreshStats(player)
	return entry
end

function BaseService:Sell(player: Player, slot: number)
	local base = baseOf[player]
	if not base or base.Stealing[slot] then
		return
	end
	local entry = self:RemovePlushie(player, slot)
	if not entry then
		return
	end
	local value = Plushies.GetPrice(entry.Id, entry.Mutation) * Config.Economy.SellRefund
	Services.EconomyService:AddCash(player, value)
	notify:FireClient(player, `Sold {Plushies.DisplayName(entry.Id, entry.Mutation)} for {Format.Cash(value)}`, "cash")
end

function BaseService:_setLocked(base, locked: boolean)
	base.Barrier.Transparency = if locked then 0.55 else 1
	base.Barrier.CanCollide = locked
	if not locked then
		base.LockedUntil = 0
	end
	if base.Owner then
		base.Owner:SetAttribute("LockedUntil", base.LockedUntil)
	end
end

function BaseService:Lock(player: Player)
	local base = baseOf[player]
	if not base then
		return
	end
	if base.LockedUntil > now() then
		return
	end
	local duration = if Services.MonetizationService:HasPass(player, "SuperLock")
		then Config.Base.SuperLockDuration
		else Config.Base.LockDuration
	base.LockedUntil = now() + duration
	self:_setLocked(base, true)
	notify:FireClient(player, `Base locked for {duration}s!`, "info")
end

function BaseService:IsLocked(player: Player): boolean
	local base = baseOf[player]
	return base ~= nil and base.LockedUntil > now()
end

-- Why `owner` can't be robbed right now, or nil if they can.
function BaseService:GetProtectionReason(owner: Player): string?
	local data = DataService:Get(owner)
	if not data then
		return "That base isn't ready yet"
	end
	if self:IsLocked(owner) then
		return "That base is locked!"
	end
	if (data.ShieldUntil or 0) > os.time() then
		return "That base has a Steal Shield!"
	end
	if (owner:GetAttribute("ProtectedUntil") or 0) > now() then
		return "That player just joined - give them a minute!"
	end
	return nil
end

function BaseService:IsInOwnBase(player: Player): boolean
	local base = baseOf[player]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	return base ~= nil and root ~= nil and MapBuilder:IsInsideBase(base, root.Position)
end

function BaseService:OnPlayerLoaded(player: Player)
	local free
	for _, base in MapBuilder.Bases do
		if not base.Owner then
			free = base
			break
		end
	end
	if not free then
		notify:FireClient(player, "All bases are taken in this server - try another server!", "error")
		return
	end
	free.Owner = player
	free.LockedUntil = 0
	free.Stealing = {}
	baseOf[player] = free
	player:SetAttribute("BaseIndex", free.Index)
	player:SetAttribute("ProtectedUntil", now() + Config.Base.NewPlayerProtection)
	self:_normalizeSlots(player)
	self:RenderAll(player)

	if player.Character then
		applyCollisionGroup(player, player.Character)
		player.Character:PivotTo(free.SpawnCFrame)
	end
end

function BaseService:OnPlayerRemoving(player: Player)
	touchDebounce[player] = nil
	local base = baseOf[player]
	if not base then
		return
	end
	for slot in base.Models do
		self:_clearSlot(base, slot)
	end
	base.Owner = nil
	base.Stealing = {}
	self:_setLocked(base, false)
	base.CollectLabel.Text = "COLLECT\n$0"
	base.LockLabel.Text = "🔒 LOCK BASE"
	for _, label in base.SignLabels do
		label.Text = "Empty Base"
	end
	for _, pedestal in base.Pedestals do
		pedestal.LockedGui.Enabled = false
		pedestal.Part.Transparency = 0
	end
	baseOf[player] = nil
end

return BaseService
