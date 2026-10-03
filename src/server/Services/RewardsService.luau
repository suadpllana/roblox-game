--[[
	Reasons to come back (and to bring friends):
	  * offline earnings while you're away
	  * a 7-day daily reward streak (day 7 = free Mystery Box)
	  * group member bonus and a bonus for every friend in your server
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local RewardsService = {}

local Services
local DataService
local notify: RemoteEvent
local friendCache: { [string]: boolean } = {}

local function today(): number
	return math.floor(os.time() / 86400)
end

function RewardsService:Init(services)
	Services = services
	DataService = services.DataService
	notify = Remotes.Get("Notify")
	Remotes.Get("ClaimDaily").OnServerEvent:Connect(function(player)
		self:ClaimDaily(player)
	end)
end

function RewardsService:Start()
	while true do
		task.wait(30)
		for _, player in Players:GetPlayers() do
			self:_updateDaily(player)
		end
	end
end

function RewardsService:_dailyInfo(player: Player, data)
	local day = today()
	local canClaim = data.LastDailyDay < day
	local streak
	if canClaim then
		streak = if data.LastDailyDay == day - 1 then data.DailyStreak % 7 + 1 else 1
	else
		streak = data.DailyStreak
	end
	local income = Services.EconomyService:GetIncome(player)
	local reward = math.max(Config.Daily.BaseReward * streak, income * Config.Daily.IncomeSeconds * streak)
	return canClaim, streak, reward, day
end

function RewardsService:_updateDaily(player: Player)
	local data = DataService:Get(player)
	if not data then
		return
	end
	local canClaim, streak, reward, day = self:_dailyInfo(player, data)
	player:SetAttribute("DailyCanClaim", canClaim)
	player:SetAttribute("DailyStreak", streak)
	player:SetAttribute("DailyReward", reward)
	player:SetAttribute("DailyResetAt", (day + 1) * 86400)
end

function RewardsService:ClaimDaily(player: Player)
	local data = DataService:Get(player)
	if not data then
		return
	end
	local canClaim, streak, reward, day = self:_dailyInfo(player, data)
	if not canClaim then
		return
	end
	data.LastDailyDay = day
	data.DailyStreak = streak
	Services.EconomyService:AddCash(player, reward)
	notify:FireClient(player, `Day {streak} reward: +{Format.Cash(reward)}!`, "cash")
	if streak == Config.Daily.MysteryBoxDay then
		Services.MonetizationService:GiveMysteryBox(player, "Day 7 bonus")
	end
	self:_updateDaily(player)
end

function RewardsService:_grantOffline(player: Player, data)
	if data.LastOnline <= 0 then
		return
	end
	local hasPass = Services.MonetizationService:HasPass(player, "OfflineEarnings")
	local rate = if hasPass then Config.Offline.PassRate else Config.Offline.Rate
	local capHours = if hasPass then Config.Offline.PassCapHours else Config.Offline.CapHours
	local seconds = math.clamp(os.time() - data.LastOnline, 0, capHours * 3600)
	local amount = Services.EconomyService:GetIncome(player) * seconds * rate
	if amount >= 1 and seconds >= 60 then
		Services.EconomyService:AddCash(player, amount)
		player:SetAttribute("OfflineEarned", amount)
		player:SetAttribute("OfflineSeconds", seconds)
	end
end

local function areFriends(a: Player, b: Player): boolean
	local low, high = math.min(a.UserId, b.UserId), math.max(a.UserId, b.UserId)
	local key = low .. "_" .. high
	if friendCache[key] == nil then
		local ok, result = pcall(a.IsFriendsWithAsync, a, b.UserId)
		friendCache[key] = ok and result == true
	end
	return friendCache[key]
end

function RewardsService:_refreshFriendBonuses(leaving: Player?)
	local players = Players:GetPlayers()
	for _, player in players do
		if player == leaving then
			continue
		end
		local friends = 0
		for _, other in players do
			if other ~= player and other ~= leaving and areFriends(player, other) then
				friends += 1
			end
		end
		local bonus = math.min(friends * Config.Economy.FriendBonusPer, Config.Economy.FriendBonusMax)
		player:SetAttribute("FriendBonus", bonus)
		player:SetAttribute("FriendsInServer", friends)
		Services.EconomyService:RefreshStats(player)
	end
end

function RewardsService:OnPlayerLoaded(player: Player, data)
	self:_grantOffline(player, data)
	self:_updateDaily(player)
	task.spawn(function()
		if Config.GroupId ~= 0 then
			local ok, inGroup = pcall(player.IsInGroupAsync, player, Config.GroupId)
			player:SetAttribute("InGroup", ok and inGroup == true)
		end
		self:_refreshFriendBonuses(nil)
	end)
end

function RewardsService:OnPlayerRemoving(player: Player)
	task.spawn(self._refreshFriendBonuses, self, player)
end

return RewardsService
