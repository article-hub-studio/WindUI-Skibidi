local Checkbox = {}

local Creator = require("../../modules/Creator")
local Motion = require("../../modules/Motion")
local New = Creator.New

function Checkbox.New(Value, Icon, IconSize, Parent, Callback, Config)
	local Checkbox = {}

	Icon = Icon or "sfsymbols:checkmark"

	local Radius = 9

	local IconCheckboxFrame = Creator.Image(
		Icon,
		Icon,
		0,
		(Config and Config.Window.Folder or "Temp"),
		"Checkbox",
		true,
		false,
		"CheckboxIcon"
	)
	IconCheckboxFrame.Size = UDim2.new(1, -26 + IconSize, 1, -26 + IconSize)
	IconCheckboxFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	IconCheckboxFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

	local CheckboxFrame = Creator.NewRoundFrame(Radius, "Squircle", {
		ImageTransparency = 0.85, -- 0
		ThemeTag = {
			ImageColor3 = "Text",
		},
		Parent = Parent,
		Size = UDim2.new(0, 26, 0, 26),
	}, {
		Creator.NewRoundFrame(Radius, "Squircle", {
			Size = UDim2.new(1, 0, 1, 0),
			Name = "Layer",
			ThemeTag = {
				ImageColor3 = "Checkbox",
			},
			ImageTransparency = 1, -- 0
		}),
		Creator.NewRoundFrame(Radius, "Glass-1.4", {
			Size = UDim2.new(1, 0, 1, 0),
			Name = "Stroke",
			ThemeTag = {
				ImageColor3 = "CheckboxBorder",
				ImageTransparency = "CheckboxBorderTransparency",
			},
		}, {
			-- New("UIGradient", {
			--     Rotation = 90,
			--     Transparency = NumberSequence.new({
			--         NumberSequenceKeypoint.new(0, 0),
			--         NumberSequenceKeypoint.new(1, 1),
			--     })
			-- })
		}),

		IconCheckboxFrame,
	}, true)

	-- IsCallback and Instant mirror Toggle:Set. Without them the initial
	-- render at construction fired the user's callback, and restoring a saved
	-- config animated every checkbox on screen.
	function Checkbox:Set(Toggled, IsCallback, Instant)
		Toggled = Toggled == true

		local LayerTransparency = if Toggled then 0 else 1
		local IconTransparency = if Toggled then 0 else 1

		if Instant == true then
			CheckboxFrame.Layer.ImageTransparency = LayerTransparency
			IconCheckboxFrame.ImageLabel.ImageTransparency = IconTransparency
		else
			Motion.Play(CheckboxFrame.Layer, "Fast", {
				ImageTransparency = LayerTransparency,
			}, nil, nil, "State")
			Motion.Play(IconCheckboxFrame.ImageLabel, "Fast", {
				ImageTransparency = IconTransparency,
			}, nil, nil, "State")
		end

		if Callback and IsCallback ~= false then
			task.defer(function()
				Creator.SafeCallback(Callback, Toggled)
			end)
		end
	end

	return CheckboxFrame, Checkbox
end

return Checkbox
