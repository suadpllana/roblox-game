-- Toast messages (bottom of screen) and big server-wide announcements (top).

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)

local Notifications = {}

local MAX_TOASTS = 4
local KIND_COLORS = {
	cash = Theme.Colors.Green,
	success = Theme.Colors.Green,
	error = Theme.Colors.Red,
	alert = Color3.fromRGB(255, 120, 40),
	info = Theme.Colors.Blue,
}

local container: Frame
local banner: TextLabel
local bannerToken = 0
local alertSound: Sound
local cashSound: Sound

function Notifications.Init(gui: ScreenGui)
	container = Theme.Create("Frame", {
		Name = "Toasts",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -100),
		Size = UDim2.new(0.9, 0, 0, 190),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		Theme.Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 6),
		}),
		Theme.Create("UISizeConstraint", { MaxSize = Vector2.new(520, 190) }),
	})

	banner = Theme.Label({
		Name = "Announcement",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 130),
		Size = UDim2.new(0.8, 0, 0, 40),
		Text = "",
		Visible = false,
		Parent = gui,
	})
	Theme.Create("UISizeConstraint", { MaxSize = Vector2.new(800, 40), Parent = banner })

	alertSound = Theme.Create("Sound", { SoundId = "rbxasset://sounds/electronicpingshort.wav", Volume = 0.8, Parent = SoundService })
	cashSound = Theme.Create("Sound", { SoundId = "rbxasset://sounds/clickfast.wav", Volume = 0.5, Parent = SoundService })
end

local order = 0
function Notifications.Toast(text: string, kind: string?)
	kind = kind or "info"
	order += 1
	local toasts = {}
	for _, child in container:GetChildren() do
		if child:IsA("TextLabel") then
			table.insert(toasts, child)
		end
	end
	table.sort(toasts, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	while #toasts >= MAX_TOASTS do
		local oldest = table.remove(toasts, 1)
		if oldest then
			oldest:Destroy()
		end
	end

	local label = Theme.Label({
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 0.15,
		BackgroundColor3 = KIND_COLORS[kind] or Theme.Colors.Blue,
		Text = text,
		Parent = container,
	})
	Theme.Corner(10).Parent = label
	Theme.Create("UIPadding", {
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
		Parent = label,
	})

	if kind == "alert" then
		alertSound:Play()
	elseif kind == "cash" then
		cashSound:Play()
	end

	task.delay(kind == "alert" and 6 or 3.5, function()
		if label.Parent then
			local tween = TweenService:Create(label, TweenInfo.new(0.4), { BackgroundTransparency = 1, TextTransparency = 1 })
			tween:Play()
			tween.Completed:Wait()
			label:Destroy()
		end
	end)
end

function Notifications.Announce(text: string, color: Color3?)
	bannerToken += 1
	local token = bannerToken
	banner.Text = text
	banner.TextColor3 = color or Theme.Colors.Gold
	banner.Visible = true
	alertSound:Play()
	task.delay(6, function()
		if bannerToken == token then
			banner.Visible = false
		end
	end)
end

return Notifications
