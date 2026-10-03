--[[
	Central tuning file. Almost everything you will want to change lives here:
	game pass / developer product IDs, prices shown in the shop, economy balance,
	base sizes, conveyor speed, and so on.

	AFTER PUBLISHING: create the game passes and developer products on
	https://create.roblox.com (your experience -> Monetization) and paste each ID
	into the `Id` fields below. While an Id is 0, buying it inside Roblox Studio
	grants it for free so you can test; in a live server it shows "not set up yet".
]]

local Config = {}

Config.GameName = "Steal a Plushie"

-- Bump the version suffix only if you want to wipe everyone's progress.
Config.DataStoreName = "PlayerData_v1"
Config.LeaderboardStoreName = "TopEarners_v1"

-- Optional: put your Roblox group ID here. Group members get a cash bonus,
-- which is the cheapest way to grow a community you can message later.
Config.GroupId = 0

Config.StartingCash = 100
Config.StartingPlushie = "LilBean"

Config.Base = {
	Count = 8, -- set the place's Max Players to 8 so everyone gets a base
	StartSlots = 8,
	SlotsPerRebirth = 1,
	MaxRebirthSlots = 6,
	ExtraSlotsPass = 6,
	LockDuration = 60,
	SuperLockDuration = 120,
	NewPlayerProtection = 90, -- seconds after joining before your base can be robbed
}

Config.Steal = {
	HoldDuration = 1.5,
	CarryWalkSpeed = 12,
	OwnerTagDistance = 6, -- owner touching the thief takes the plushie back
}

Config.Movement = {
	WalkSpeed = 16,
	SpeedPassWalkSpeed = 22,
}

Config.Conveyor = {
	SpawnInterval = 2.2,
	Speed = 5, -- studs per second
	MaxItems = 22,
	AnnounceRarities = { Mythic = true, Secret = true },
}

Config.Economy = {
	RebirthBaseCost = 1_000_000,
	RebirthCostGrowth = 3,
	RebirthMultiplierBonus = 0.5,
	SellRefund = 0.5,
	VIPMultiplier = 1.25,
	DoubleCashMultiplier = 2,
	PremiumMultiplier = 1.1,
	GroupMultiplier = 1.1,
	FriendBonusPer = 0.1,
	FriendBonusMax = 0.5,
}

Config.Offline = {
	Rate = 0.25,
	CapHours = 8,
	PassRate = 1,
	PassCapHours = 24,
}

Config.Daily = {
	BaseReward = 250, -- multiplied by the streak day
	IncomeSeconds = 90, -- reward also scales with your income so it never feels useless
	MysteryBoxDay = 7,
}

Config.ServerLuck = {
	Multiplier = 2,
	Duration = 15 * 60,
}

Config.Shield = {
	Duration = 30 * 60,
}

-- Game passes: one-time purchases. Order controls shop order.
Config.GamePasses = {
	{
		Key = "VIP",
		Id = 0,
		Name = "VIP",
		Price = 199,
		Icon = "👑",
		Description = "+25% cash forever, gold [VIP] chat tag.",
	},
	{
		Key = "DoubleCash",
		Id = 0,
		Name = "2x Cash",
		Price = 299,
		Icon = "💰",
		Description = "Every plushie earns double, forever.",
	},
	{
		Key = "AutoCollect",
		Id = 0,
		Name = "Auto Collect",
		Price = 99,
		Icon = "🧲",
		Description = "Cash goes straight to your wallet. No pad needed.",
	},
	{
		Key = "ExtraSlots",
		Id = 0,
		Name = "+6 Base Slots",
		Price = 149,
		Icon = "📦",
		Description = "Room for 6 more plushies in your base.",
	},
	{
		Key = "SuperLock",
		Id = 0,
		Name = "Super Lock",
		Price = 99,
		Icon = "🔒",
		Description = "Your base lock lasts twice as long.",
	},
	{
		Key = "OfflineEarnings",
		Id = 0,
		Name = "Offline Earnings+",
		Price = 129,
		Icon = "🌙",
		Description = "Earn 100% while offline (up to 24h) instead of 25% / 8h.",
	},
	{
		Key = "Speed",
		Id = 0,
		Name = "Speed Boost",
		Price = 79,
		Icon = "⚡",
		Description = "Run faster. Perfect for getaways.",
	},
}

-- Developer products: can be bought again and again.
-- Kind = "Cash": gives max(Floor, your income per second * Seconds), so packs stay
-- valuable no matter how far a player has progressed.
Config.Products = {
	{
		Key = "CashSmall",
		Id = 0,
		Name = "Pile of Cash",
		Price = 25,
		Icon = "💵",
		Kind = "Cash",
		Seconds = 5 * 60,
		Floor = 1_000,
		Description = "5 minutes of income instantly.",
	},
	{
		Key = "CashMedium",
		Id = 0,
		Name = "Bag of Cash",
		Price = 79,
		Icon = "💰",
		Kind = "Cash",
		Seconds = 20 * 60,
		Floor = 5_000,
		Description = "20 minutes of income instantly.",
	},
	{
		Key = "CashLarge",
		Id = 0,
		Name = "Vault of Cash",
		Price = 199,
		Icon = "🏦",
		Kind = "Cash",
		Seconds = 60 * 60,
		Floor = 25_000,
		Description = "1 hour of income instantly.",
	},
	{
		Key = "ServerLuck",
		Id = 0,
		Name = "2x Server Luck",
		Price = 99,
		Icon = "🍀",
		Kind = "ServerLuck",
		Description = "Rare+ plushies spawn 2x more for EVERYONE for 15 min. Stacks!",
	},
	{
		Key = "MysteryBox",
		Id = 0,
		Name = "Mystery Plushie Box",
		Price = 129,
		Icon = "🎁",
		Kind = "MysteryBox",
		Description = "Instantly get a random Epic or better plushie.",
	},
	{
		Key = "Shield",
		Id = 0,
		Name = "Steal Shield",
		Price = 49,
		Icon = "🛡️",
		Kind = "Shield",
		Description = "Nobody can steal from your base for 30 minutes.",
	},
}

function Config.GetPass(key: string)
	for _, pass in Config.GamePasses do
		if pass.Key == key then
			return pass
		end
	end
	return nil
end

function Config.GetProduct(key: string)
	for _, product in Config.Products do
		if product.Key == key then
			return product
		end
	end
	return nil
end

function Config.RebirthCost(rebirths: number): number
	return Config.Economy.RebirthBaseCost * Config.Economy.RebirthCostGrowth ^ rebirths
end

return Config
