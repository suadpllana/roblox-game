-- Robux shop: game passes and boosts (developer products).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Theme = require(script.Parent.Theme)

local player = Players.LocalPlayer
local requestPurchase = Remotes.Get("RequestPurchase")

local Shop = {}

local window: Frame
local pages: { [string]: ScrollingFrame } = {}
local tabButtons: { [string]: TextButton } = {}

local function makeCard(parent: Instance, item, kind: string, order: number)
	local card = Theme.Create("Frame", {
		LayoutOrder = order,
		BackgroundColor3 = Theme.Colors.PanelLight,
		Parent = parent,
	}, { Theme.Corner(12) })
	Theme.Label({
		Size = UDim2.new(0.28, 0, 0.55, 0),
		Position = UDim2.fromScale(0.02, 0.05),
		Text = item.Icon,
		Parent = card,
	})
	Theme.Label({
		Size = UDim2.new(0.68, 0, 0.25, 0),
		Position = UDim2.fromScale(0.31, 0.05),
		Text = item.Name,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Colors.Gold,
		Parent = card,
	})
	local description = Theme.Label({
		Size = UDim2.new(0.68, 0, 0.32, 0),
		Position = UDim2.fromScale(0.31, 0.3),
		Text = item.Description,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextWrapped = true,
		TextColor3 = Theme.Colors.Muted,
		Parent = card,
	})
	description:FindFirstChildOfClass("UIStroke"):Destroy()

	local buy = Theme.Button({
		Size = UDim2.new(0.9, 0, 0.28, 0),
		Position = UDim2.fromScale(0.05, 0.67),
		BackgroundColor3 = Theme.Colors.Green,
		Text = "R$ " .. item.Price,
		Parent = card,
	})
	buy.Activated:Connect(function()
		requestPurchase:FireServer(kind, item.Key)
	end)

	if kind == "Pass" then
		local function refresh()
			local owns = player:GetAttribute("Pass_" .. item.Key) == true
			buy.Text = if owns then "Owned ✓" else "R$ " .. item.Price
			buy.BackgroundColor3 = if owns then Theme.Colors.PanelLight else Theme.Colors.Green
			buy.Active = not owns
		end
		player:GetAttributeChangedSignal("Pass_" .. item.Key):Connect(refresh)
		refresh()
	end
end

local function makePage(content: Frame, name: string, items, kind: string)
	local page = Theme.Create("ScrollingFrame", {
		Name = name,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 50),
		Size = UDim2.new(1, 0, 1, -50),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		Visible = false,
		Parent = content,
	}, {
		Theme.Create("UIGridLayout", {
			CellSize = UDim2.new(0.5, -8, 0, 130),
			CellPadding = UDim2.fromOffset(8, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
	for index, item in items do
		makeCard(page, item, kind, index)
	end
	pages[name] = page
end

function Shop.Show(tab: string?)
	tab = tab or "Boosts"
	for name, page in pages do
		page.Visible = name == tab
		tabButtons[name].BackgroundColor3 = if name == tab then Theme.Colors.Pink else Theme.Colors.PanelLight
	end
	window.Visible = true
end

function Shop.Toggle()
	if window.Visible then
		window.Visible = false
	else
		Shop.Show()
	end
end

function Shop.Init(gui: ScreenGui)
	local content
	window, content = Theme.Window(gui, "🛒 Shop", UDim2.fromScale(0.75, 0.75))
	local tabs = { "Boosts", "Passes" }
	for index, name in tabs do
		local button = Theme.Button({
			Size = UDim2.new(0.5, -6, 0, 42),
			Position = UDim2.new((index - 1) * 0.5, (index - 1) * 6, 0, 0),
			Text = name,
			Parent = content,
		})
		button.Activated:Connect(function()
			Shop.Show(name)
		end)
		tabButtons[name] = button
	end
	makePage(content, "Boosts", Config.Products, "Product")
	makePage(content, "Passes", Config.GamePasses, "Pass")
end

return Shop
