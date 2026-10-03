-- Rebirth, daily reward and "welcome back" windows.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Shop = require(script.Parent.Shop)
local Theme = require(script.Parent.Theme)

local player = Players.LocalPlayer

local Popups = {}

local rebirthWindow: Frame
local dailyWindow: Frame
local offlineWindow: Frame
local refreshers = {}

local function attr(name: string, default: any): any
	local value = player:GetAttribute(name)
	if value == nil then
		return default
	end
	return value
end

local function buildRebirth(gui: ScreenGui)
	local content
	rebirthWindow, content = Theme.Window(gui, "♻️ Rebirth", UDim2.fromScale(0.6, 0.55))
	local info = Theme.Label({
		Size = UDim2.new(1, 0, 0.4, 0),
		TextWrapped = true,
		Text = "",
		Parent = content,
	})
	local barBack = Theme.Create("Frame", {
		Position = UDim2.fromScale(0.05, 0.47),
		Size = UDim2.fromScale(0.9, 0.14),
		BackgroundColor3 = Theme.Colors.PanelLight,
		Parent = content,
	}, { Theme.Corner(8) })
	local barFill = Theme.Create("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundColor3 = Theme.Colors.Green,
		Parent = barBack,
	}, { Theme.Corner(8) })
	local barText = Theme.Label({ Size = UDim2.fromScale(1, 1), Text = "", Parent = barBack })
	local button = Theme.Button({
		Position = UDim2.fromScale(0.2, 0.7),
		Size = UDim2.fromScale(0.6, 0.25),
		BackgroundColor3 = Theme.Colors.Gold,
		Text = "REBIRTH",
		Parent = content,
	})
	button.Activated:Connect(function()
		Remotes.Get("RequestRebirth"):FireServer()
	end)

	table.insert(refreshers, function()
		local rebirths = attr("Rebirths", 0)
		local cost = attr("RebirthCost", Config.RebirthCost(0))
		local cash = attr("Cash", 0)
		local nextMultiplier = 1 + (rebirths + 1) * Config.Economy.RebirthMultiplierBonus
		info.Text = `Reset your cash and plushies to get a PERMANENT x{nextMultiplier} cash multiplier and +1 base slot.`
		barFill.Size = UDim2.fromScale(math.clamp(cash / cost, 0, 1), 1)
		barText.Text = `{Format.Cash(cash)} / {Format.Cash(cost)}`
		button.Text = if cash >= cost then "REBIRTH NOW!" else "Need " .. Format.Cash(cost)
	end)
end

local function buildDaily(gui: ScreenGui)
	local content
	dailyWindow, content = Theme.Window(gui, "🎁 Daily Reward", UDim2.fromScale(0.65, 0.55))
	local days = Theme.Create("Frame", {
		Size = UDim2.fromScale(1, 0.4),
		BackgroundTransparency = 1,
		Parent = content,
	}, {
		Theme.Create("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0.01, 0),
		}),
	})
	local boxes = {}
	for day = 1, 7 do
		local box = Theme.Label({
			Size = UDim2.fromScale(0.13, 1),
			BackgroundTransparency = 0,
			BackgroundColor3 = Theme.Colors.PanelLight,
			Text = if day == Config.Daily.MysteryBoxDay then `Day {day}\n🎁` else `Day {day}\n💵`,
			Parent = days,
		})
		Theme.Corner(10).Parent = box
		boxes[day] = box
	end
	local info = Theme.Label({
		Position = UDim2.fromScale(0, 0.45),
		Size = UDim2.fromScale(1, 0.2),
		Text = "",
		Parent = content,
	})
	local button = Theme.Button({
		Position = UDim2.fromScale(0.2, 0.72),
		Size = UDim2.fromScale(0.6, 0.25),
		BackgroundColor3 = Theme.Colors.Green,
		Text = "CLAIM",
		Parent = content,
	})
	button.Activated:Connect(function()
		Remotes.Get("ClaimDaily"):FireServer()
	end)

	table.insert(refreshers, function()
		local streak = attr("DailyStreak", 1)
		local canClaim = attr("DailyCanClaim", false)
		for day, box in boxes do
			box.BackgroundColor3 = if day < streak or (day == streak and not canClaim)
				then Theme.Colors.Green
				elseif day == streak then Theme.Colors.Pink
				else Theme.Colors.PanelLight
		end
		local reward = Format.Cash(attr("DailyReward", 0))
		if canClaim then
			info.Text = `Day {streak}: {reward}` .. (if streak == Config.Daily.MysteryBoxDay then " + Mystery Box!" else "")
			button.Text = "CLAIM"
			button.BackgroundColor3 = Theme.Colors.Green
		else
			local wait = attr("DailyResetAt", 0) - os.time()
			info.Text = "Come back tomorrow to keep your streak!"
			button.Text = "Next in " .. Format.Time(wait)
			button.BackgroundColor3 = Theme.Colors.PanelLight
		end
	end)
end

local function buildOffline(gui: ScreenGui)
	local content
	offlineWindow, content = Theme.Window(gui, "🌙 Welcome back!", UDim2.fromScale(0.55, 0.45))
	local info = Theme.Label({
		Size = UDim2.fromScale(1, 0.5),
		TextWrapped = true,
		Text = "",
		Parent = content,
	})
	local upsell = Theme.Button({
		Position = UDim2.fromScale(0.1, 0.6),
		Size = UDim2.fromScale(0.8, 0.3),
		BackgroundColor3 = Theme.Colors.Gold,
		Text = "Earn 4x more offline 🌙",
		Parent = content,
	})
	upsell.Activated:Connect(function()
		offlineWindow.Visible = false
		Shop.Show("Passes")
	end)

	local function show()
		local amount = player:GetAttribute("OfflineEarned")
		if not amount then
			return
		end
		local seconds = attr("OfflineSeconds", 0)
		info.Text = `Your plushies earned {Format.Cash(amount)} while you were away ({Format.Time(seconds)}).`
		upsell.Visible = player:GetAttribute("Pass_OfflineEarnings") ~= true
		offlineWindow.Visible = true
	end
	player:GetAttributeChangedSignal("OfflineEarned"):Connect(show)
	show()
end

function Popups.Init(gui: ScreenGui)
	buildRebirth(gui)
	buildDaily(gui)
	buildOffline(gui)
	task.spawn(function()
		while true do
			for _, refresh in refreshers do
				refresh()
			end
			task.wait(0.5)
		end
	end)
end

function Popups.ToggleRebirth()
	rebirthWindow.Visible = not rebirthWindow.Visible
end

function Popups.ToggleDaily()
	dailyWindow.Visible = not dailyWindow.Visible
end

return Popups
