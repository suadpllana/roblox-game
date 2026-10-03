--[[
	Builds the whole map from code: ground, the plushie conveyor lane, 8 player
	bases, and the leaderboard. Everything is generated at runtime so the game
	works straight from the repository. You can decorate around it freely in
	Studio; just keep new parts out of the base and lane areas.
]]

local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local MapBuilder = {}

MapBuilder.BASE_WIDTH = 44
MapBuilder.BASE_DEPTH = 52
MapBuilder.WALL_HEIGHT = 14
MapBuilder.SLOT_COLUMNS = 4
MapBuilder.MAX_SLOTS = 20
MapBuilder.LANE_START_X = -165
MapBuilder.LANE_END_X = 165
MapBuilder.LANE_WIDTH = 12
MapBuilder.LANE_TOP = 0.5

MapBuilder.Bases = {}
MapBuilder.LeaderboardList = nil :: Frame?

local BASE_COLORS = {
	Color3.fromRGB(255, 120, 150),
	Color3.fromRGB(120, 180, 255),
	Color3.fromRGB(140, 220, 120),
	Color3.fromRGB(255, 200, 90),
	Color3.fromRGB(190, 130, 255),
	Color3.fromRGB(90, 220, 210),
	Color3.fromRGB(255, 150, 80),
	Color3.fromRGB(240, 240, 120),
}

local function makePart(props: { [string]: any }): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(part :: any)[key] = value
	end
	return part
end

local function makeSurfaceText(part: BasePart, face: Enum.NormalId, text: string, color: Color3?): TextLabel
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.4
	label.Text = text
	label.Parent = gui
	return label
end

local function makeBillboard(part: BasePart, size: UDim2, offset: Vector3, maxDistance: number): (BillboardGui, TextLabel)
	local gui = Instance.new("BillboardGui")
	gui.Size = size
	gui.StudsOffsetWorldSpace = offset
	gui.MaxDistance = maxDistance
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.2
	label.Parent = gui
	return gui, label
end

local function setupCollisionGroups()
	local groups = { "Players", "Plushies", "PlushieRails" }
	for index = 1, Config.Base.Count do
		table.insert(groups, "Barrier" .. index)
		table.insert(groups, "Owner" .. index)
	end
	for _, name in groups do
		if not PhysicsService:IsCollisionGroupRegistered(name) then
			PhysicsService:RegisterCollisionGroup(name)
		end
	end
	-- Plushies on the conveyor never get pushed around by players.
	PhysicsService:CollisionGroupSetCollidable("Plushies", "Players", false)
	-- Invisible rails keep plushies on the lane but never block players.
	PhysicsService:CollisionGroupSetCollidable("PlushieRails", "Default", false)
	PhysicsService:CollisionGroupSetCollidable("PlushieRails", "Players", false)
	for index = 1, Config.Base.Count do
		local owner = "Owner" .. index
		PhysicsService:CollisionGroupSetCollidable("Plushies", owner, false)
		PhysicsService:CollisionGroupSetCollidable("PlushieRails", owner, false)
		-- A base's laser barrier blocks everyone except that base's owner.
		PhysicsService:CollisionGroupSetCollidable("Barrier" .. index, owner, false)
		PhysicsService:CollisionGroupSetCollidable("Barrier" .. index, "Plushies", false)
	end
end

local function buildGround(map: Folder)
	makePart({
		Name = "Ground",
		Size = Vector3.new(420, 1, 240),
		Position = Vector3.new(0, -0.5, 0),
		Color = Color3.fromRGB(110, 190, 95),
		Material = Enum.Material.Grass,
		Parent = map,
	})

	local laneLength = MapBuilder.LANE_END_X - MapBuilder.LANE_START_X
	local laneCenterX = (MapBuilder.LANE_END_X + MapBuilder.LANE_START_X) / 2
	makePart({
		Name = "Conveyor",
		Size = Vector3.new(laneLength, 1, MapBuilder.LANE_WIDTH),
		Position = Vector3.new(laneCenterX, 0, 0),
		Color = Color3.fromRGB(55, 55, 70),
		Material = Enum.Material.DiamondPlate,
		Parent = map,
	})
	for _, side in { -1, 1 } do
		makePart({
			Name = "LaneStripe",
			Size = Vector3.new(laneLength, 0.2, 0.5),
			Position = Vector3.new(laneCenterX, 0.6, side * (MapBuilder.LANE_WIDTH / 2 - 0.25)),
			Color = Color3.fromRGB(255, 220, 80),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Parent = map,
		})
		makePart({
			Name = "PlushieRail",
			Size = Vector3.new(laneLength, 4, 1),
			Position = Vector3.new(laneCenterX, 2.5, side * (MapBuilder.LANE_WIDTH / 2 + 0.5)),
			Transparency = 1,
			CanQuery = false,
			CanTouch = false,
			CollisionGroup = "PlushieRails",
			Parent = map,
		})
	end
	-- Direction arrows along the lane.
	for x = MapBuilder.LANE_START_X + 20, MapBuilder.LANE_END_X - 20, 30 do
		local arrow = makePart({
			Name = "Arrow",
			Size = Vector3.new(4, 0.1, 3),
			CFrame = CFrame.new(x, 0.55, 0) * CFrame.Angles(0, math.rad(-90), 0),
			Color = Color3.fromRGB(85, 85, 105),
			CanCollide = false,
			Parent = map,
		})
		makeSurfaceText(arrow, Enum.NormalId.Top, "▲", Color3.fromRGB(255, 220, 80))
	end

	-- Factory arch where plushies come out, and the drain at the other end.
	for _, info in { { MapBuilder.LANE_START_X, "PLUSHIE FACTORY", Color3.fromRGB(255, 120, 170) }, { MapBuilder.LANE_END_X, "LAST CHANCE!", Color3.fromRGB(120, 120, 140) } } do
		local x, text, color = info[1], info[2], info[3]
		for _, side in { -1, 1 } do
			makePart({
				Name = "ArchPillar",
				Size = Vector3.new(3, 14, 3),
				Position = Vector3.new(x, 7, side * 8),
				Color = color,
				Parent = map,
			})
		end
		local top = makePart({
			Name = "ArchTop",
			Size = Vector3.new(3, 4, 19),
			Position = Vector3.new(x, 15, 0),
			Color = color,
			Parent = map,
		})
		makeSurfaceText(top, Enum.NormalId.Right, text)
		makeSurfaceText(top, Enum.NormalId.Left, text)
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(MapBuilder.LANE_START_X + 20, 0, -14)
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = Color3.fromRGB(255, 255, 255)
	spawn.Parent = map
end

local function buildLeaderboard(map: Folder)
	local position = Vector3.new(0, 9, 40)
	local board = makePart({
		Name = "Leaderboard",
		Size = Vector3.new(16, 14, 1),
		CFrame = CFrame.lookAt(position, position + Vector3.new(0, 0, -1)),
		Color = Color3.fromRGB(40, 40, 60),
		Parent = map,
	})
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = board

	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 0.14)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 220, 80)
	title.Text = "🏆 RICHEST PLAYERS"
	title.Parent = gui

	local list = Instance.new("Frame")
	list.Name = "List"
	list.Position = UDim2.fromScale(0.05, 0.16)
	list.Size = UDim2.fromScale(0.9, 0.82)
	list.BackgroundTransparency = 1
	list.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list

	for _, side in { -1, 1 } do
		makePart({
			Name = "BoardLeg",
			Size = Vector3.new(1, 3, 1),
			Position = Vector3.new(side * 6, 1, 40),
			Color = Color3.fromRGB(40, 40, 60),
			Parent = map,
		})
	end
	MapBuilder.LeaderboardList = list
end

local function buildBase(map: Folder, index: number, origin: CFrame)
	local width, depth, height = MapBuilder.BASE_WIDTH, MapBuilder.BASE_DEPTH, MapBuilder.WALL_HEIGHT
	local color = BASE_COLORS[(index - 1) % #BASE_COLORS + 1]
	local folder = Instance.new("Folder")
	folder.Name = "Base" .. index
	folder.Parent = map

	-- Local helper: x = left/right, y = up, d = depth into the base from the entrance.
	local function at(x: number, y: number, d: number): CFrame
		return origin * CFrame.new(x, y, -d)
	end

	makePart({
		Name = "Floor",
		Size = Vector3.new(width, 1, depth),
		CFrame = at(0, 0, depth / 2),
		Color = color:Lerp(Color3.new(1, 1, 1), 0.65),
		Material = Enum.Material.SmoothPlastic,
		Parent = folder,
	})
	for _, side in { -1, 1 } do
		makePart({
			Name = "SideWall",
			Size = Vector3.new(1, height, depth),
			CFrame = at(side * width / 2, height / 2 + 0.5, depth / 2),
			Color = color,
			Parent = folder,
		})
		makePart({
			Name = "Pillar",
			Size = Vector3.new(2.5, height + 3, 2.5),
			CFrame = at(side * width / 2, (height + 3) / 2, 0),
			Color = color:Lerp(Color3.new(0, 0, 0), 0.25),
			Parent = folder,
		})
	end
	makePart({
		Name = "BackWall",
		Size = Vector3.new(width, height, 1),
		CFrame = at(0, height / 2 + 0.5, depth),
		Color = color,
		Parent = folder,
	})

	local sign = makePart({
		Name = "Sign",
		Size = Vector3.new(width, 3, 1),
		CFrame = at(0, height + 2, 0),
		Color = color:Lerp(Color3.new(0, 0, 0), 0.25),
		CanCollide = false,
		Parent = folder,
	})
	local signOutside = makeSurfaceText(sign, Enum.NormalId.Back, "Empty Base")
	local signInside = makeSurfaceText(sign, Enum.NormalId.Front, "Empty Base")

	local barrier = makePart({
		Name = "Barrier",
		Size = Vector3.new(width, height, 0.6),
		CFrame = at(0, height / 2 + 0.5, 0),
		Color = Color3.fromRGB(255, 50, 70),
		Material = Enum.Material.ForceField,
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CollisionGroup = "Barrier" .. index,
		Parent = folder,
	})

	local pedestals = {}
	for slot = 1, MapBuilder.MAX_SLOTS do
		local row = math.ceil(slot / MapBuilder.SLOT_COLUMNS)
		local column = (slot - 1) % MapBuilder.SLOT_COLUMNS + 1
		local x = -13.5 + (column - 1) * 9
		local d = 16 + (row - 1) * 7
		local pedestal = makePart({
			Name = "Pedestal" .. slot,
			Size = Vector3.new(6, 1, 5),
			CFrame = at(x, 1, d),
			Color = Color3.fromRGB(245, 245, 250),
			Material = Enum.Material.SmoothPlastic,
			Parent = folder,
		})
		pedestal:SetAttribute("Slot", slot)
		local lockGui, lockLabel = makeBillboard(pedestal, UDim2.fromOffset(120, 40), Vector3.new(0, 2.5, 0), 50)
		lockGui.Name = "LockedLabel"
		lockLabel.Text = "🔒 Rebirth"
		lockLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
		lockGui.Enabled = false
		pedestals[slot] = {
			Part = pedestal,
			-- Plushies stand on top of the pedestal and face the entrance.
			StandCFrame = at(x, 1.5, d) * CFrame.Angles(0, math.pi, 0),
			LockedGui = lockGui,
		}
	end

	local collectPad = makePart({
		Name = "CollectPad",
		Size = Vector3.new(8, 0.4, 6),
		CFrame = at(-14, 0.7, 6),
		Color = Color3.fromRGB(80, 230, 120),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = folder,
	})
	local _, collectLabel = makeBillboard(collectPad, UDim2.fromOffset(200, 70), Vector3.new(0, 4, 0), 80)
	collectLabel.Text = "COLLECT\n$0"
	collectLabel.TextColor3 = Color3.fromRGB(140, 255, 160)

	local lockPad = makePart({
		Name = "LockPad",
		Size = Vector3.new(8, 0.4, 6),
		CFrame = at(14, 0.7, 6),
		Color = Color3.fromRGB(255, 80, 90),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = folder,
	})
	local _, lockLabel = makeBillboard(lockPad, UDim2.fromOffset(200, 70), Vector3.new(0, 4, 0), 80)
	lockLabel.Text = "🔒 LOCK BASE"

	MapBuilder.Bases[index] = {
		Index = index,
		Origin = origin,
		Folder = folder,
		Barrier = barrier,
		SignLabels = { signOutside, signInside },
		Pedestals = pedestals,
		CollectPad = collectPad,
		CollectLabel = collectLabel,
		LockPad = lockPad,
		LockLabel = lockLabel,
		SpawnCFrame = at(0, 4, 9) * CFrame.Angles(0, math.pi, 0),
		OutsideCFrame = at(0, 4, -8) * CFrame.Angles(0, math.pi, 0),
	}
end

function MapBuilder:Init()
	setupCollisionGroups()

	local existing = workspace:FindFirstChild("Map")
	if existing then
		existing:Destroy()
	end
	local map = Instance.new("Folder")
	map.Name = "Map"
	map.Parent = workspace

	buildGround(map)
	buildLeaderboard(map)

	local perSide = math.ceil(Config.Base.Count / 2)
	local spacing = 64
	local laneGap = MapBuilder.LANE_WIDTH / 2 + 12
	for index = 1, Config.Base.Count do
		local north = index <= perSide
		local column = if north then index else index - perSide
		local x = (column - (perSide + 1) / 2) * spacing
		local z = if north then laneGap else -laneGap
		local direction = if north then 1 else -1
		local position = Vector3.new(x, 0, z)
		buildBase(map, index, CFrame.lookAt(position, position + Vector3.new(0, 0, direction)))
	end
end

-- Returns the position relative to a base: x (sideways), depth (into base), y.
function MapBuilder:ToBaseSpace(base, position: Vector3): (number, number, number)
	local relative = base.Origin:PointToObjectSpace(position)
	return relative.X, -relative.Z, relative.Y
end

function MapBuilder:IsInsideBase(base, position: Vector3): boolean
	local x, depth, y = self:ToBaseSpace(base, position)
	return math.abs(x) <= self.BASE_WIDTH / 2 and depth >= 0.5 and depth <= self.BASE_DEPTH and y > -4 and y < 30
end

return MapBuilder
