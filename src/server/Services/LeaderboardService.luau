-- Global "Richest Players" board (all-time cash earned), shown in the middle of the map.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)

local UPDATE_INTERVAL = 120
local MAX_SAFE_INTEGER = 2 ^ 53

local LeaderboardService = {}

local Services
local store: OrderedDataStore? = nil
local names: { [number]: string } = {}

local function nameFor(userId: number): string
	if names[userId] then
		return names[userId]
	end
	local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	names[userId] = if ok then name else "Player"
	return names[userId]
end

function LeaderboardService:Init(services)
	Services = services
	local ok, result = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, Config.LeaderboardStoreName)
	if ok then
		store = result
	end
end

function LeaderboardService:_render(entries)
	local list = Services.MapBuilder.LeaderboardList
	if not list then
		return
	end
	for _, child in list:GetChildren() do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	for rank, entry in entries do
		local label = Instance.new("TextLabel")
		label.LayoutOrder = rank
		label.Size = UDim2.fromScale(1, 0.1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.TextColor3 = if rank == 1
			then Color3.fromRGB(255, 215, 60)
			elseif rank == 2 then Color3.fromRGB(220, 220, 230)
			elseif rank == 3 then Color3.fromRGB(230, 150, 90)
			else Color3.new(1, 1, 1)
		label.Text = `#{rank}  {entry.Name}  -  {Format.Cash(entry.Value)}`
		label.Parent = list
	end
end

function LeaderboardService:_update()
	if not store then
		return
	end
	for _, player in Players:GetPlayers() do
		local data = Services.DataService:Get(player)
		if data and Services.DataService:CanSave(player) then
			local value = math.clamp(math.floor(data.TotalEarned), 0, MAX_SAFE_INTEGER)
			pcall((store :: OrderedDataStore).SetAsync, store, tostring(player.UserId), value)
		end
	end
	local ok, pages = pcall((store :: OrderedDataStore).GetSortedAsync, store, false, 10)
	if not ok then
		return
	end
	local entries = {}
	for _, item in (pages :: DataStorePages):GetCurrentPage() do
		local userId = tonumber(item.key)
		if userId then
			table.insert(entries, { Name = nameFor(userId), Value = item.value })
		end
	end
	self:_render(entries)
end

function LeaderboardService:Start()
	task.wait(15)
	while true do
		local ok, err = pcall(self._update, self)
		if not ok then
			warn("[LeaderboardService]", err)
		end
		task.wait(UPDATE_INTERVAL)
	end
end

return LeaderboardService
