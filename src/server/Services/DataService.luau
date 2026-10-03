--[[
	Player save data with session locking, retries, autosave and safe shutdown.
	Only this module talks to the player DataStore.
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)

local AUTOSAVE_INTERVAL = 90
local SESSION_LOCK_TIMEOUT = 30 * 60
local LOAD_ATTEMPTS = 6
local MAX_RECEIPTS = 50

local DataService = {}

local profiles: { [Player]: any } = {}
local canSave: { [Player]: boolean } = {}
local saving: { [Player]: boolean } = {}

local store: DataStore? = nil

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for key, inner in value do
		copy[key] = deepCopy(inner)
	end
	return copy
end

local function template()
	return {
		Cash = Config.StartingCash,
		Uncollected = 0,
		Rebirths = 0,
		TotalEarned = 0,
		Steals = 0,
		Plushies = {
			{ Id = Config.StartingPlushie, Mutation = "None", Slot = 1 },
		},
		LastOnline = 0,
		DailyStreak = 0,
		LastDailyDay = 0,
		ShieldUntil = 0,
		Receipts = {},
	}
end

-- Adds any keys that were introduced after a player's data was first created.
local function reconcile(data, defaults)
	for key, value in defaults do
		if data[key] == nil then
			data[key] = deepCopy(value)
		end
	end
	return data
end

local function keyFor(player: Player): string
	return "Player_" .. player.UserId
end

function DataService:Init()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStoreName)
	end)
	if ok then
		store = result
	else
		warn("[DataService] DataStore unavailable:", result)
	end
end

function DataService:Start()
	while true do
		task.wait(AUTOSAVE_INTERVAL)
		for player in profiles do
			task.spawn(self.Save, self, player, false)
		end
	end
end

function DataService:Get(player: Player)
	return profiles[player]
end

function DataService:Load(player: Player)
	local loaded = nil
	local saveAllowed = false

	if store then
		for attempt = 1, LOAD_ATTEMPTS do
			local lockedElsewhere = false
			local isLastAttempt = attempt == LOAD_ATTEMPTS
			local ok, result = pcall(function()
				return (store :: DataStore):UpdateAsync(keyFor(player), function(old)
					lockedElsewhere = false
					old = old or template()
					local lock = old.SessionLock
					if
						lock
						and lock.JobId ~= game.JobId
						and os.time() - (lock.Time or 0) < SESSION_LOCK_TIMEOUT
						and not isLastAttempt
					then
						-- Another server is still saving this player; wait for it.
						lockedElsewhere = true
						return nil
					end
					old.SessionLock = { JobId = game.JobId, Time = os.time() }
					return old
				end)
			end)
			if ok and result and not lockedElsewhere then
				loaded = result
				saveAllowed = true
				break
			end
			if not ok then
				warn(`[DataService] Load attempt {attempt} failed for {player.Name}: {result}`)
				if RunService:IsStudio() and string.find(tostring(result), "API", 1, true) then
					-- Studio without "Enable Studio Access to API Services": play without saving.
					break
				end
			end
			if not player.Parent then
				return nil
			end
			task.wait(3)
		end
	end

	if not player.Parent then
		if loaded and saveAllowed then
			-- They left while loading: hand the session lock straight back.
			profiles[player] = loaded
			canSave[player] = true
			self:Release(player)
		end
		return nil
	end

	if not loaded then
		if RunService:IsStudio() then
			warn("[DataService] Using temporary data (not saved). Enable Studio API access to test saving.")
			loaded = template()
		else
			player:Kick("We couldn't load your data. Please rejoin in a minute - your progress is safe.")
			return nil
		end
	end

	loaded.SessionLock = nil
	reconcile(loaded, template())
	profiles[player] = loaded
	canSave[player] = saveAllowed
	return loaded
end

function DataService:Save(player: Player, release: boolean): boolean
	local data = profiles[player]
	if not data or not store or not canSave[player] then
		return false
	end
	while saving[player] do
		task.wait(0.1)
	end
	saving[player] = true
	data.LastOnline = os.time()
	local snapshot = deepCopy(data)
	local ok, err = pcall(function()
		(store :: DataStore):UpdateAsync(keyFor(player), function(old)
			if old and old.SessionLock and old.SessionLock.JobId ~= game.JobId then
				-- Another server took over this session; never overwrite its data.
				return nil
			end
			snapshot.SessionLock = if release then nil else { JobId = game.JobId, Time = os.time() }
			return snapshot
		end)
	end)
	saving[player] = nil
	if not ok then
		warn(`[DataService] Save failed for {player.Name}: {err}`)
	end
	return ok
end

function DataService:Release(player: Player)
	if profiles[player] then
		self:Save(player, true)
	end
	profiles[player] = nil
	canSave[player] = nil
end

function DataService:SaveAll()
	local pending = 0
	for player in profiles do
		pending += 1
		task.spawn(function()
			self:Save(player, true)
			pending -= 1
		end)
	end
	local started = os.clock()
	while pending > 0 and os.clock() - started < 25 do
		task.wait(0.1)
	end
end

-- Receipt bookkeeping so a developer product is never granted twice.
function DataService:HasReceipt(player: Player, receiptId: string): boolean
	local data = profiles[player]
	return data ~= nil and table.find(data.Receipts, receiptId) ~= nil
end

function DataService:AddReceipt(player: Player, receiptId: string)
	local data = profiles[player]
	if not data then
		return
	end
	table.insert(data.Receipts, receiptId)
	while #data.Receipts > MAX_RECEIPTS do
		table.remove(data.Receipts, 1)
	end
end

function DataService:CanSave(player: Player): boolean
	return canSave[player] == true
end

return DataService
