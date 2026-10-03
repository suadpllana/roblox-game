--[[
	Builds plushie models. By default each plushie is assembled from simple parts
	(cute, readable, zero assets needed). Drop a Model named after a plushie's Id
	into ServerStorage > PlushieModels to replace it with a real 3D model.

	Every model has an invisible "Root" part at its feet; all other parts are
	welded to it, so moving or anchoring the Root moves the whole plushie.
]]

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Format = require(ReplicatedStorage.Shared.Format)
local Plushies = require(ReplicatedStorage.Shared.Plushies)

local PlushieFactory = {}

export type Mode = "Static" | "Conveyor" | "Carry"

local function ball(size: number, color: Color3, material: Enum.Material, cframe: CFrame, parent: Instance): Part
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(size, size, size)
	part.Color = color
	part.Material = material
	part.CFrame = cframe
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function block(size: Vector3, color: Color3, material: Enum.Material, cframe: CFrame, parent: Instance): Part
	local part = Instance.new("Part")
	part.Size = size
	part.Color = color
	part.Material = material
	part.CFrame = cframe
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function buildProcedural(def, mutation, model: Model, ground: CFrame): number
	local s = def.Scale or 1
	local mutationDef = Plushies.GetMutation(mutation)
	local color = if mutationDef then mutationDef.Color else def.Color
	local accent = def.Accent
	local material = if mutationDef then mutationDef.Material else (def.Material or Enum.Material.Fabric)
	local black = Color3.fromRGB(25, 25, 30)

	local bodyY = 0.4 + 1.2 * s
	local headY = bodyY + 1.1 * s + 0.75 * s
	local body = ball(2.4 * s, color, material, ground * CFrame.new(0, bodyY, 0), model)
	body.Name = "Body"
	local head = ball(1.9 * s, color, material, ground * CFrame.new(0, headY, 0), model)
	head.Name = "Head"
	local headCF = head.CFrame
	local bodyCF = body.CFrame

	-- Belly patch, eyes and blush give everything a plushie face.
	ball(1.4 * s, accent, Enum.Material.Fabric, bodyCF * CFrame.new(0, -0.1 * s, -0.55 * s), model)
	if def.Shape ~= "Frog" then
		for _, side in { -1, 1 } do
			ball(0.32 * s, black, Enum.Material.SmoothPlastic, headCF * CFrame.new(side * 0.35 * s, 0.12 * s, -0.82 * s), model)
			ball(0.28 * s, Color3.fromRGB(255, 150, 170), Enum.Material.Fabric, headCF * CFrame.new(side * 0.6 * s, -0.22 * s, -0.68 * s), model)
		end
	end

	local shape = def.Shape
	if shape == "Bear" or shape == "Unicorn" then
		for _, side in { -1, 1 } do
			ball(0.75 * s, color, material, headCF * CFrame.new(side * 0.7 * s, 0.75 * s, 0), model)
			ball(0.4 * s, accent, Enum.Material.Fabric, headCF * CFrame.new(side * 0.7 * s, 0.75 * s, -0.22 * s), model)
		end
	end
	if shape == "Unicorn" then
		block(Vector3.new(0.35, 1.3, 0.35) * s, accent, Enum.Material.Neon, headCF * CFrame.new(0, 1.15 * s, -0.35 * s) * CFrame.Angles(math.rad(-20), 0, 0), model)
	elseif shape == "Bunny" then
		for _, side in { -1, 1 } do
			block(Vector3.new(0.45, 1.7, 0.3) * s, color, material, headCF * CFrame.new(side * 0.42 * s, 1.5 * s, 0) * CFrame.Angles(0, 0, math.rad(side * -10)), model)
			block(Vector3.new(0.25, 1.3, 0.1) * s, accent, Enum.Material.Fabric, headCF * CFrame.new(side * 0.42 * s, 1.5 * s, -0.16 * s) * CFrame.Angles(0, 0, math.rad(side * -10)), model)
		end
	elseif shape == "Cat" then
		for _, side in { -1, 1 } do
			block(Vector3.new(0.65, 0.65, 0.25) * s, color, material, headCF * CFrame.new(side * 0.55 * s, 0.85 * s, 0) * CFrame.Angles(0, 0, math.rad(45)), model)
		end
		block(Vector3.new(0.3, 0.3, 1.6) * s, color, material, bodyCF * CFrame.new(0, 0.2 * s, 1.3 * s) * CFrame.Angles(math.rad(-35), 0, 0), model)
	elseif shape == "Frog" then
		for _, side in { -1, 1 } do
			ball(0.8 * s, color, material, headCF * CFrame.new(side * 0.5 * s, 0.75 * s, -0.25 * s), model)
			ball(0.4 * s, black, Enum.Material.SmoothPlastic, headCF * CFrame.new(side * 0.5 * s, 0.8 * s, -0.55 * s), model)
		end
		block(Vector3.new(0.9, 0.12, 0.1) * s, black, Enum.Material.SmoothPlastic, headCF * CFrame.new(0, -0.25 * s, -0.9 * s), model)
	elseif shape == "Bird" then
		block(Vector3.new(0.6, 0.3, 0.7) * s, Color3.fromRGB(255, 150, 40), Enum.Material.SmoothPlastic, headCF * CFrame.new(0, -0.15 * s, -0.95 * s), model)
		for _, side in { -1, 1 } do
			block(Vector3.new(0.3, 1.1, 1.3) * s, accent, material, bodyCF * CFrame.new(side * 1.15 * s, 0.1 * s, 0) * CFrame.Angles(0, 0, math.rad(side * 20)), model)
		end
		ball(0.5 * s, accent, material, headCF * CFrame.new(0, 0.95 * s, 0), model)
	elseif shape == "Fish" then
		block(Vector3.new(0.25, 1.2, 1.2) * s, accent, material, bodyCF * CFrame.new(0, 1.15 * s, 0.2 * s) * CFrame.Angles(math.rad(45), 0, 0), model)
		block(Vector3.new(0.25, 1.3, 1.3) * s, accent, material, bodyCF * CFrame.new(0, 0, 1.5 * s) * CFrame.Angles(math.rad(45), 0, 0), model)
		for _, side in { -1, 1 } do
			block(Vector3.new(0.6, 0.12, 0.25) * s, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, headCF * CFrame.new(side * 0.25 * s, -0.4 * s, -0.85 * s), model)
		end
	elseif shape == "Blob" then
		ball(0.55 * s, accent, Enum.Material.Fabric, headCF * CFrame.new(0, 0.95 * s, 0), model)
	end

	if def.Hat == "Crown" then
		local gold = Color3.fromRGB(255, 205, 50)
		block(Vector3.new(1.2, 0.35, 1.2) * s, gold, Enum.Material.Foil, headCF * CFrame.new(0, 1.0 * s, 0), model)
		for corner = 0, 3 do
			local angle = corner * math.pi / 2
			block(Vector3.new(0.25, 0.45, 0.25) * s, gold, Enum.Material.Foil, headCF * CFrame.new(math.cos(angle) * 0.45 * s, 1.35 * s, math.sin(angle) * 0.45 * s), model)
		end
	end

	return headY + 1.5 * s
end

local function buildCustom(template: Model, model: Model, ground: CFrame): number
	local clone = template:Clone()
	local _, size = clone:GetBoundingBox()
	clone:PivotTo(ground * CFrame.new(0, 0.4 + size.Y / 2, 0))
	for _, descendant in clone:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Parent = model
		end
	end
	clone:Destroy()
	return 0.4 + size.Y
end

local function addBillboard(root: BasePart, def, mutation: string, height: number, compact: boolean)
	local rarity = Plushies.GetRarity(def.Rarity)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Info"
	gui.Size = if compact then UDim2.fromOffset(160, 36) else UDim2.fromOffset(200, 84)
	gui.StudsOffsetWorldSpace = Vector3.new(0, height + 0.5, 0)
	gui.MaxDistance = if compact then 60 else 45
	gui.LightInfluence = 0
	gui.Parent = root

	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.Parent = gui

	local function line(order: number, text: string, color: Color3, scale: number)
		local label = Instance.new("TextLabel")
		label.LayoutOrder = order
		label.Size = UDim2.new(1, 0, scale, 0)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = color
		label.TextStrokeTransparency = 0.1
		label.Text = text
		label.Parent = gui
		return label
	end

	local mutationDef = Plushies.GetMutation(mutation)
	if compact then
		line(1, Plushies.DisplayName(def.Id, mutation), rarity.Color, 1)
		return
	end
	if mutationDef then
		line(0, mutationDef.Name:upper(), mutationDef.Color, 0.2)
	end
	line(1, def.Name, Color3.new(1, 1, 1), 0.28)
	local rarityLabel = line(2, def.Rarity, rarity.Color, 0.2)
	if def.Rarity == "Secret" then
		rarityLabel.TextColor3 = Color3.new(1, 1, 1)
		rarityLabel.TextStrokeColor3 = Color3.fromRGB(170, 60, 255)
	end
	line(3, Format.Cash(Plushies.GetIncome(def.Id, mutation)) .. "/s", Color3.fromRGB(120, 255, 140), 0.2)
end

-- `ground` is where the plushie's feet go; the model faces ground's LookVector.
function PlushieFactory.Build(id: string, mutation: string?, mode: Mode, ground: CFrame): Model?
	local def = Plushies.Get(id)
	if not def then
		warn("[PlushieFactory] Unknown plushie", id)
		return nil
	end
	local mutationName: string = mutation or "None"

	local model = Instance.new("Model")
	model.Name = def.Id
	model:SetAttribute("PlushieId", def.Id)
	model:SetAttribute("Mutation", mutationName)
	model:SetAttribute("Rarity", def.Rarity)

	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = if mode == "Conveyor" then Vector3.new(2.8, 0.8, 2.8) else Vector3.new(2.6, 0.8, 2.6)
	root.CFrame = ground * CFrame.new(0, 0.4, 0)
	root.Transparency = 1
	root.CanCollide = mode == "Conveyor"
	root.CanTouch = false
	root.Anchored = mode == "Static"
	root.Parent = model
	model.PrimaryPart = root

	local customFolder = ServerStorage:FindFirstChild("PlushieModels")
	local custom = customFolder and customFolder:FindFirstChild(def.Id)
	local height
	if custom and custom:IsA("Model") then
		height = buildCustom(custom, model, ground)
	else
		height = buildProcedural(def, mutationName, model, ground)
	end

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part ~= root then
			part.Anchored = false
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = mode ~= "Carry"
			part.Massless = true
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = part
			weld.Parent = part
		end
	end

	if mode == "Conveyor" then
		root.CollisionGroup = "Plushies"
		root.CustomPhysicalProperties = PhysicalProperties.new(2, 0.05, 0, 1, 1)
	elseif mode == "Carry" then
		root.Massless = true
		root.CanQuery = false
	end

	if mutationName == "Rainbow" then
		CollectionService:AddTag(model, "Rainbow")
	end

	addBillboard(root, def, mutationName, height, mode == "Carry")
	return model
end

return PlushieFactory
