--[[
	Server entry point. Loads every service in a fixed order, then drives the
	player lifecycle so services always see a player's data in a consistent state.

	Service modules may implement:
		Init(services)              -- wire up references, create instances
		Start()                     -- start loops (runs in its own thread)
		OnPlayerLoaded(player, data)
		OnPlayerRemoving(player)
]]

local Players = game:GetService("Players")

local servicesFolder = script.Parent:WaitForChild("Services")

local ORDER = {
	"DataService",
	"MapBuilder",
	"MonetizationService",
	"EconomyService",
	"BaseService",
	"ConveyorService",
	"StealService",
	"CombatService",
	"RewardsService",
	"LeaderboardService",
}

local Services = {}
for _, name in ORDER do
	Services[name] = require(servicesFolder:WaitForChild(name))
end

for _, name in ORDER do
	local service = Services[name]
	if service.Init then
		service:Init(Services)
	end
end

for _, name in ORDER do
	local service = Services[name]
	if service.Start then
		task.spawn(service.Start, service)
	end
end

local function onPlayerAdded(player: Player)
	local data = Services.DataService:Load(player)
	if not data or not player.Parent then
		return
	end
	for _, name in ORDER do
		local service = Services[name]
		if name ~= "DataService" and service.OnPlayerLoaded then
			local ok, err = pcall(service.OnPlayerLoaded, service, player, data)
			if not ok then
				warn(`[{name}] OnPlayerLoaded failed for {player.Name}: {err}`)
			end
		end
	end
	player:SetAttribute("Loaded", true)
end

local function onPlayerRemoving(player: Player)
	for index = #ORDER, 1, -1 do
		local name = ORDER[index]
		local service = Services[name]
		if name ~= "DataService" and service.OnPlayerRemoving then
			local ok, err = pcall(service.OnPlayerRemoving, service, player)
			if not ok then
				warn(`[{name}] OnPlayerRemoving failed for {player.Name}: {err}`)
			end
		end
	end
	Services.DataService:Release(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

game:BindToClose(function()
	Services.DataService:SaveAll()
end)
