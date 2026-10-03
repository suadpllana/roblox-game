--[[
	The plushie catalog. Add, rename or rebalance plushies here.

	Shape controls the placeholder model built from parts: Bear, Bunny, Cat, Frog,
	Bird, Fish, Unicorn, Blob. To use a real 3D model instead, put a Model named
	exactly like the plushie's Id inside ServerStorage > PlushieModels and it will
	be used automatically.
]]

local Plushies = {}

Plushies.Rarities = {
	{ Name = "Common", Weight = 55, Color = Color3.fromRGB(200, 200, 200), Lucky = false },
	{ Name = "Uncommon", Weight = 25, Color = Color3.fromRGB(110, 220, 110), Lucky = false },
	{ Name = "Rare", Weight = 12, Color = Color3.fromRGB(80, 160, 255), Lucky = true },
	{ Name = "Epic", Weight = 5.5, Color = Color3.fromRGB(190, 90, 255), Lucky = true },
	{ Name = "Legendary", Weight = 2, Color = Color3.fromRGB(255, 190, 40), Lucky = true },
	{ Name = "Mythic", Weight = 0.45, Color = Color3.fromRGB(255, 70, 110), Lucky = true },
	{ Name = "Secret", Weight = 0.05, Color = Color3.fromRGB(30, 30, 30), Lucky = true },
}

Plushies.Mutations = {
	{ Name = "Gold", Multiplier = 2, Chance = 0.04, Color = Color3.fromRGB(255, 200, 40), Material = Enum.Material.Foil },
	{ Name = "Diamond", Multiplier = 3, Chance = 0.015, Color = Color3.fromRGB(120, 230, 255), Material = Enum.Material.Glass },
	{ Name = "Rainbow", Multiplier = 5, Chance = 0.004, Color = Color3.fromRGB(255, 80, 80), Material = Enum.Material.Neon },
}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

Plushies.List = {
	-- Common
	{ Id = "LilBean", Name = "Lil Bean", Rarity = "Common", Price = 25, Income = 1, Shape = "Blob", Color = rgb(130, 205, 95), Accent = rgb(80, 150, 60) },
	{ Id = "SockBunny", Name = "Sock Bunny", Rarity = "Common", Price = 60, Income = 2, Shape = "Bunny", Color = rgb(235, 235, 245), Accent = rgb(255, 170, 190) },
	{ Id = "ButtonBear", Name = "Button Bear", Rarity = "Common", Price = 150, Income = 4, Shape = "Bear", Color = rgb(170, 120, 80), Accent = rgb(230, 200, 160) },
	-- Uncommon
	{ Id = "MochiCat", Name = "Mochi Cat", Rarity = "Uncommon", Price = 500, Income = 10, Shape = "Cat", Color = rgb(255, 222, 232), Accent = rgb(255, 150, 180) },
	{ Id = "PuddingPup", Name = "Pudding Pup", Rarity = "Uncommon", Price = 900, Income = 16, Shape = "Bear", Color = rgb(245, 205, 120), Accent = rgb(140, 80, 40) },
	{ Id = "CloudSheep", Name = "Cloud Sheep", Rarity = "Uncommon", Price = 1_500, Income = 24, Shape = "Blob", Color = rgb(250, 250, 255), Accent = rgb(90, 90, 110) },
	-- Rare
	{ Id = "TacoTurtle", Name = "Taco Turtle", Rarity = "Rare", Price = 5_000, Income = 60, Shape = "Blob", Color = rgb(245, 185, 70), Accent = rgb(90, 180, 70) },
	{ Id = "BubbleFrog", Name = "Bubble Frog", Rarity = "Rare", Price = 9_000, Income = 95, Shape = "Frog", Color = rgb(110, 210, 120), Accent = rgb(255, 240, 160) },
	{ Id = "CactusKitty", Name = "Cactus Kitty", Rarity = "Rare", Price = 15_000, Income = 140, Shape = "Cat", Color = rgb(95, 170, 95), Accent = rgb(255, 120, 170) },
	-- Epic
	{ Id = "NinjaPanda", Name = "Ninja Panda", Rarity = "Epic", Price = 50_000, Income = 350, Shape = "Bear", Color = rgb(245, 245, 245), Accent = rgb(25, 25, 30) },
	{ Id = "DiscoDuck", Name = "Disco Duck", Rarity = "Epic", Price = 90_000, Income = 550, Shape = "Bird", Color = rgb(255, 222, 50), Accent = rgb(255, 140, 30) },
	{ Id = "AstroAxolotl", Name = "Astro Axolotl", Rarity = "Epic", Price = 150_000, Income = 800, Shape = "Frog", Color = rgb(255, 160, 205), Accent = rgb(150, 90, 230) },
	-- Legendary
	{ Id = "KingCorgi", Name = "King Corgi", Rarity = "Legendary", Price = 500_000, Income = 2_500, Shape = "Cat", Color = rgb(235, 150, 70), Accent = rgb(255, 245, 230), Hat = "Crown" },
	{ Id = "DragonPlush", Name = "Dragon Plush", Rarity = "Legendary", Price = 900_000, Income = 4_000, Shape = "Unicorn", Color = rgb(60, 180, 90), Accent = rgb(255, 210, 60) },
	{ Id = "PizzaShark", Name = "Pizza Shark", Rarity = "Legendary", Price = 1_500_000, Income = 6_000, Shape = "Fish", Color = rgb(110, 140, 170), Accent = rgb(230, 70, 50) },
	-- Mythic
	{ Id = "GalaxyUnicorn", Name = "Galaxy Unicorn", Rarity = "Mythic", Price = 5_000_000, Income = 22_000, Shape = "Unicorn", Color = rgb(120, 70, 220), Accent = rgb(255, 120, 230), Material = Enum.Material.Neon },
	{ Id = "PhoenixChick", Name = "Phoenix Chick", Rarity = "Mythic", Price = 10_000_000, Income = 40_000, Shape = "Bird", Color = rgb(255, 120, 30), Accent = rgb(255, 230, 60), Material = Enum.Material.Neon },
	{ Id = "CrystalKraken", Name = "Crystal Kraken", Rarity = "Mythic", Price = 20_000_000, Income = 70_000, Shape = "Fish", Color = rgb(90, 220, 255), Accent = rgb(200, 255, 255), Material = Enum.Material.Glass },
	-- Secret
	{ Id = "VoidBunny", Name = "Void Bunny", Rarity = "Secret", Price = 100_000_000, Income = 300_000, Shape = "Bunny", Color = rgb(20, 10, 35), Accent = rgb(170, 60, 255), Material = Enum.Material.Neon, Scale = 1.2 },
	{ Id = "GoldenGoose", Name = "Golden Goose", Rarity = "Secret", Price = 250_000_000, Income = 650_000, Shape = "Bird", Color = rgb(255, 205, 40), Accent = rgb(255, 255, 255), Material = Enum.Material.Foil, Scale = 1.25, Hat = "Crown" },
	{ Id = "OmegaBear", Name = "Omega Bear", Rarity = "Secret", Price = 500_000_000, Income = 1_200_000, Shape = "Bear", Color = rgb(255, 60, 60), Accent = rgb(255, 255, 255), Material = Enum.Material.Neon, Scale = 1.35, Hat = "Crown" },
}

local byId = {}
local byRarity = {}
for _, def in Plushies.List do
	byId[def.Id] = def
	byRarity[def.Rarity] = byRarity[def.Rarity] or {}
	table.insert(byRarity[def.Rarity], def)
end

local rarityByName = {}
for index, rarity in Plushies.Rarities do
	rarity.Order = index
	rarityByName[rarity.Name] = rarity
end

local mutationByName = {}
for _, mutation in Plushies.Mutations do
	mutationByName[mutation.Name] = mutation
end

function Plushies.Get(id: string)
	return byId[id]
end

function Plushies.GetRarity(name: string)
	return rarityByName[name]
end

function Plushies.GetMutation(name: string?)
	if not name or name == "None" then
		return nil
	end
	return mutationByName[name]
end

function Plushies.ByRarity(name: string)
	return byRarity[name] or {}
end

function Plushies.MutationMultiplier(name: string?): number
	local mutation = Plushies.GetMutation(name)
	return if mutation then mutation.Multiplier else 1
end

function Plushies.GetIncome(id: string, mutation: string?): number
	local def = byId[id]
	if not def then
		return 0
	end
	return def.Income * Plushies.MutationMultiplier(mutation)
end

function Plushies.GetPrice(id: string, mutation: string?): number
	local def = byId[id]
	if not def then
		return 0
	end
	return def.Price * Plushies.MutationMultiplier(mutation)
end

function Plushies.DisplayName(id: string, mutation: string?): string
	local def = byId[id]
	local name = if def then def.Name else id
	if mutation and mutation ~= "None" then
		return mutation .. " " .. name
	end
	return name
end

-- Picks a rarity by weight. `luck` multiplies the weight of rarities flagged Lucky.
function Plushies.RollRarity(rng: Random, luck: number, allowed: { [string]: number }?)
	local total = 0
	local weights = {}
	for _, rarity in Plushies.Rarities do
		local weight = rarity.Weight
		if allowed then
			weight = allowed[rarity.Name] or 0
		end
		if rarity.Lucky then
			weight *= luck
		end
		weights[rarity.Name] = weight
		total += weight
	end
	local roll = rng:NextNumber() * total
	for _, rarity in Plushies.Rarities do
		roll -= weights[rarity.Name]
		if roll <= 0 and weights[rarity.Name] > 0 then
			return rarity.Name
		end
	end
	return Plushies.Rarities[1].Name
end

function Plushies.RollMutation(rng: Random, luck: number): string
	-- Rarest first so a single roll can land the best result.
	for index = #Plushies.Mutations, 1, -1 do
		local mutation = Plushies.Mutations[index]
		if rng:NextNumber() < mutation.Chance * luck then
			return mutation.Name
		end
	end
	return "None"
end

function Plushies.RollPlushie(rng: Random, luck: number, allowed: { [string]: number }?)
	local rarity = Plushies.RollRarity(rng, luck, allowed)
	local options = byRarity[rarity]
	local def = options[rng:NextInteger(1, #options)]
	return def.Id, Plushies.RollMutation(rng, luck)
end

return Plushies
