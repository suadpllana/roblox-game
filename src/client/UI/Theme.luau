-- Small helpers so every UI element shares the same look.

local Theme = {}

Theme.Font = Enum.Font.FredokaOne
Theme.Colors = {
	Panel = Color3.fromRGB(35, 30, 55),
	PanelLight = Color3.fromRGB(60, 52, 90),
	Text = Color3.fromRGB(255, 255, 255),
	Muted = Color3.fromRGB(190, 185, 215),
	Cash = Color3.fromRGB(110, 255, 140),
	Pink = Color3.fromRGB(255, 110, 170),
	Gold = Color3.fromRGB(255, 205, 60),
	Red = Color3.fromRGB(255, 80, 90),
	Blue = Color3.fromRGB(90, 170, 255),
	Green = Color3.fromRGB(70, 210, 110),
}

function Theme.Create(className: string, props: { [string]: any }, children: { Instance }?): any
	local instance = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			(instance :: any)[key] = value
		end
	end
	if children then
		for _, child in children do
			child.Parent = instance
		end
	end
	if props.Parent then
		instance.Parent = props.Parent
	end
	return instance
end

function Theme.Corner(radius: number?): UICorner
	return Theme.Create("UICorner", { CornerRadius = UDim.new(0, radius or 12) })
end

function Theme.Stroke(color: Color3?, thickness: number?): UIStroke
	return Theme.Create("UIStroke", {
		Color = color or Color3.fromRGB(20, 15, 35),
		Thickness = thickness or 3,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function Theme.Label(props: { [string]: any }): TextLabel
	local defaults = {
		BackgroundTransparency = 1,
		Font = Theme.Font,
		TextColor3 = Theme.Colors.Text,
		TextScaled = true,
	}
	for key, value in props do
		defaults[key] = value
	end
	local label = Theme.Create("TextLabel", defaults)
	Theme.Create("UIStroke", { Thickness = 2, Color = Color3.fromRGB(20, 15, 35), Parent = label })
	return label
end

function Theme.Button(props: { [string]: any }): TextButton
	local defaults = {
		BackgroundColor3 = Theme.Colors.Pink,
		Font = Theme.Font,
		TextColor3 = Theme.Colors.Text,
		TextScaled = true,
		AutoButtonColor = true,
	}
	for key, value in props do
		defaults[key] = value
	end
	local button = Theme.Create("TextButton", defaults)
	Theme.Corner(10).Parent = button
	Theme.Stroke().Parent = button
	Theme.Create("UIPadding", {
		PaddingTop = UDim.new(0.12, 0),
		PaddingBottom = UDim.new(0.12, 0),
		PaddingLeft = UDim.new(0.06, 0),
		PaddingRight = UDim.new(0.06, 0),
		Parent = button,
	})
	return button
end

-- A centered popup window with a title and close button. Returns (frame, content).
function Theme.Window(parent: Instance, title: string, size: UDim2): (Frame, Frame)
	local frame = Theme.Create("Frame", {
		Name = title,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = size,
		BackgroundColor3 = Theme.Colors.Panel,
		Visible = false,
		Parent = parent,
	}, { Theme.Corner(16), Theme.Stroke(Theme.Colors.Pink, 4) })
	Theme.Create("UISizeConstraint", { MaxSize = Vector2.new(720, 560), Parent = frame })
	Theme.Label({
		Size = UDim2.new(1, -80, 0, 44),
		Position = UDim2.fromOffset(16, 8),
		Text = title,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Colors.Gold,
		Parent = frame,
	})
	local close = Theme.Button({
		Size = UDim2.fromOffset(44, 44),
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 8),
		Text = "X",
		BackgroundColor3 = Theme.Colors.Red,
		Parent = frame,
	})
	close.Activated:Connect(function()
		frame.Visible = false
	end)
	local content = Theme.Create("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 60),
		Size = UDim2.new(1, -24, 1, -72),
		Parent = frame,
	})
	return frame, content
end

return Theme
