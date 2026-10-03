-- Always-visible HUD: cash, income, side buttons, status line, carry banner.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Shared.Format)
local Popups = require(script.Parent.Popups)
local Shop = require(script.Parent.Shop)
local Theme = require(script.Parent.Theme)

local player = Players.LocalPlayer

local Hud = {}

local function sideButton(parent: Instance, order: number, icon: string, text: string, color: Color3): (TextButton, TextLabel)
	local button = Theme.Button({
		LayoutOrder = order,
		Size = UDim2.fromScale(1, 0.3),
		BackgroundColor3 = color,
		Text = icon,
		Parent = parent,
	})
	Theme.Create("UIAspectRatioConstraint", { AspectRatio = 1, Parent = button })
	Theme.Label({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, 14),
		Size = UDim2.new(1.3, 0, 0.32, 0),
		Text = text,
		ZIndex = 2,
		Parent = button,
	})
	local badge = Theme.Label({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.92, 0.08),
		Size = UDim2.fromScale(0.36, 0.36),
		BackgroundTransparency = 0,
		BackgroundColor3 = Theme.Colors.Red,
		Text = "!",
		Visible = false,
		ZIndex = 3,
		Parent = button,
	})
	Theme.Corner(100).Parent = badge
	return button, badge
end

function Hud.Init(gui: ScreenGui)
	-- Cash panel (top center)
	local cashPanel = Theme.Create("Frame", {
		Name = "CashPanel",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 6),
		Size = UDim2.fromOffset(280, 74),
		BackgroundColor3 = Theme.Colors.Panel,
		BackgroundTransparency = 0.15,
		Parent = gui,
	}, { Theme.Corner(14), Theme.Stroke(Theme.Colors.Green, 3) })
	local cashLabel = Theme.Label({
		Position = UDim2.fromOffset(10, 4),
		Size = UDim2.new(1, -60, 0, 42),
		Text = "$0",
		TextColor3 = Theme.Colors.Cash,
		Parent = cashPanel,
	})
	local incomeLabel = Theme.Label({
		Position = UDim2.fromOffset(10, 46),
		Size = UDim2.new(1, -60, 0, 22),
		Text = "+$0/s",
		TextColor3 = Theme.Colors.Muted,
		Parent = cashPanel,
	})
	local plus = Theme.Button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(44, 44),
		BackgroundColor3 = Theme.Colors.Green,
		Text = "+",
		Parent = cashPanel,
	})
	plus.Activated:Connect(function()
		Shop.Show("Boosts")
	end)

	local statusLabel = Theme.Label({
		Name = "Status",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 84),
		Size = UDim2.fromOffset(420, 24),
		Text = "",
		Parent = gui,
	})
	local luckLabel = Theme.Label({
		Name = "Luck",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 108),
		Size = UDim2.fromOffset(420, 22),
		Text = "",
		TextColor3 = Color3.fromRGB(120, 255, 140),
		Visible = false,
		Parent = gui,
	})

	-- Side buttons (left)
	local side = Theme.Create("Frame", {
		Name = "SideButtons",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 10, 0.5, 0),
		Size = UDim2.new(0, 70, 0.5, 0),
		BackgroundTransparency = 1,
		Parent = gui,
	}, {
		Theme.Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 22),
		}),
		Theme.Create("UISizeConstraint", { MaxSize = Vector2.new(80, 330), MinSize = Vector2.new(50, 180) }),
	})
	local shopButton = sideButton(side, 1, "🛒", "Shop", Theme.Colors.Pink)
	local rebirthButton, rebirthBadge = sideButton(side, 2, "♻️", "Rebirth", Theme.Colors.Gold)
	local dailyButton, dailyBadge = sideButton(side, 3, "🎁", "Daily", Theme.Colors.Blue)
	shopButton.Activated:Connect(Shop.Toggle)
	rebirthButton.Activated:Connect(Popups.ToggleRebirth)
	dailyButton.Activated:Connect(Popups.ToggleDaily)

	-- Carry banner (bottom)
	local carryLabel = Theme.Label({
		Name = "Carry",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -300),
		Size = UDim2.new(0.8, 0, 0, 44),
		Text = "",
		TextColor3 = Color3.fromRGB(255, 120, 60),
		Visible = false,
		Parent = gui,
	})
	Theme.Create("UISizeConstraint", { MaxSize = Vector2.new(700, 44), Parent = carryLabel })

	-- New player hint
	local hint = Theme.Label({
		Name = "Hint",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -300),
		Size = UDim2.new(0.9, 0, 0, 30),
		Text = "Buy plushies on the conveyor 💰  •  Collect cash on the green pad  •  Steal from other bases 😈  •  Lock your base 🔒",
		TextColor3 = Theme.Colors.Gold,
		Visible = false,
		Parent = gui,
	})
	Theme.Create("UISizeConstraint", { MaxSize = Vector2.new(900, 30), Parent = hint })
	task.spawn(function()
		if not player:GetAttribute("Loaded") then
			player:GetAttributeChangedSignal("Loaded"):Wait()
		end
		if (player:GetAttribute("Rebirths") or 0) == 0 and (player:GetAttribute("PlushieCount") or 0) <= 2 then
			hint.Visible = true
			task.wait(90)
			hint.Visible = false
		end
	end)

	local function refresh()
		local cash = player:GetAttribute("Cash") or 0
		cashLabel.Text = Format.Cash(cash)
		local multiplier = player:GetAttribute("Multiplier") or 1
		incomeLabel.Text = `+{Format.Cash(player:GetAttribute("Income") or 0)}/s   x{Format.Number(multiplier)}`

		local now = workspace:GetServerTimeNow()
		local parts = {}
		local lockedUntil = player:GetAttribute("LockedUntil") or 0
		if lockedUntil > now then
			table.insert(parts, `🔒 Locked {math.ceil(lockedUntil - now)}s`)
		end
		local shieldUntil = player:GetAttribute("ShieldUntil") or 0
		if shieldUntil > os.time() then
			table.insert(parts, `🛡️ Shield {Format.Time(shieldUntil - os.time())}`)
		end
		local protectedUntil = player:GetAttribute("ProtectedUntil") or 0
		if protectedUntil > now then
			table.insert(parts, `✨ New player protection {math.ceil(protectedUntil - now)}s`)
		end
		local friends = player:GetAttribute("FriendsInServer") or 0
		if friends > 0 then
			table.insert(parts, `👥 +{math.floor((player:GetAttribute("FriendBonus") or 0) * 100)}% friend bonus`)
		end
		statusLabel.Text = table.concat(parts, "   ")

		local luckUntil = ReplicatedStorage:GetAttribute("ServerLuckUntil") or 0
		luckLabel.Visible = luckUntil > now
		if luckUntil > now then
			luckLabel.Text = `🍀 2x SERVER LUCK {Format.Time(luckUntil - now)} (thanks {ReplicatedStorage:GetAttribute("ServerLuckBy") or "someone"}!)`
		end

		local carrying = player:GetAttribute("Carrying")
		carryLabel.Visible = carrying ~= nil
		if carrying then
			carryLabel.Text = `😈 Carrying {carrying}! RUN BACK TO YOUR BASE!`
			hint.Visible = false
		end

		rebirthBadge.Visible = cash >= (player:GetAttribute("RebirthCost") or math.huge)
		dailyBadge.Visible = player:GetAttribute("DailyCanClaim") == true
	end

	task.spawn(function()
		while true do
			refresh()
			task.wait(0.2)
		end
	end)
end

return Hud
