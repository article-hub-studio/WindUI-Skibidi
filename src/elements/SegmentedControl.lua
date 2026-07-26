local Creator = require("../modules/Creator")
local Motion = require("../modules/Motion")
local New = Creator.New

local Utils = require("./ModernControlUtils")

local Element = {}

local function GetControlWidth(Config)
	return math.max(Utils.ToFiniteNumber(Config.Width) or Utils.ToFiniteNumber(Config.ControlWidth) or 220, 120)
end

function Element:New(Config)
	local SegmentedControl = {
		__type = "SegmentedControl",
		Title = Config.Title or "Segmented Control",
		Desc = Config.Desc or nil,
		Locked = Config.Locked or false,
		LockedTitle = Config.LockedTitle,
		Options = Utils.NormalizeOptions(Config.Options or Config.Values or {}),
		-- `false` is a legal option value, so this cannot use `or` - see the
		-- nil checks below, which mirror RadioGroup.
		Value = Config.Value,
		Callback = Config.Callback or function() end,
		UIElements = {},
		Segments = {},
		Animation = Config.Animation ~= false,

		Width = GetControlWidth(Config),
	}

	if SegmentedControl.Value == nil then
		SegmentedControl.Value = Config.Default
	end
	if typeof(SegmentedControl.Value) == "number" and SegmentedControl.Options[SegmentedControl.Value] then
		SegmentedControl.Value = SegmentedControl.Options[SegmentedControl.Value].Value
	end
	if SegmentedControl.Value == nil and SegmentedControl.Options[1] then
		SegmentedControl.Value = SegmentedControl.Options[1].Value
	end

	local CanCallback = true

	SegmentedControl.SegmentedControlFrame = require("../components/window/Element")({
		Title = SegmentedControl.Title,
		Desc = SegmentedControl.Desc,
		Parent = Config.Parent,
		TextOffset = SegmentedControl.Width + 14,
		Hover = false,
		Tab = Config.Tab,
		Index = Config.Index,
		Window = Config.Window,
		ElementTable = SegmentedControl,
		ParentConfig = Config,
		Tags = Config.Tags,
	})

	SegmentedControl.UIElements.Container = Creator.NewRoundFrame(13, "Squircle", {
		Name = "SegmentedControl",
		Size = UDim2.new(0, SegmentedControl.Width, 0, 36),
		Position = UDim2.new(1, 0, Config.Window.NewElements and 0 or 0.5, 0),
		AnchorPoint = Vector2.new(1, Config.Window.NewElements and 0 or 0.5),
		ImageTransparency = 0.93,
		ThemeTag = {
			ImageColor3 = "SegmentedControlBackground",
		},
		Parent = SegmentedControl.SegmentedControlFrame.UIElements.Main,
	}, {
		New("UIPadding", {
			PaddingTop = UDim.new(0, 4),
			PaddingLeft = UDim.new(0, 4),
			PaddingRight = UDim.new(0, 4),
			PaddingBottom = UDim.new(0, 4),
		}),
	})

	local function UpdateSegmentVisuals(IsAnimated)
		for _, Segment in next, SegmentedControl.Segments do
			local Selected = Segment.Option.Value == SegmentedControl.Value
			local BackgroundTransparency = Selected and 0.82 or 1
			local TextTransparency = Segment.Option.Disabled and 0.55 or (Selected and 0 or 0.25)

			if IsAnimated and SegmentedControl.Animation then
				Motion.Play(
					Segment.Button,
					"Select",
					{ ImageTransparency = BackgroundTransparency },
					nil,
					nil,
					"Select"
				)
				Motion.Play(Segment.Title, "Select", { TextTransparency = TextTransparency }, nil, nil, "Select")
			else
				Segment.Button.ImageTransparency = BackgroundTransparency
				Segment.Title.TextTransparency = TextTransparency
			end
		end
	end

	local MIN_SEGMENT_WIDTH = 24

	--- Widest each segment can be without the row leaving the container.
	--- Returns the width and whether the minimum had to kick in, because a
	--- clamped row no longer fits and has to be told to clip.
	local function SegmentWidthFor(Count, Gap)
		local Available = SegmentedControl.Width - 8 - (Gap * math.max(Count - 1, 0))
		local Exact = Available / math.max(Count, 1)
		if Exact < MIN_SEGMENT_WIDTH then
			return MIN_SEGMENT_WIDTH, true
		end
		return Exact, false
	end

	local function CreateSegment(Option, Index, Count)
		local Gap = 4
		local SegmentWidth = SegmentWidthFor(Count, Gap)

		local Title = New("TextLabel", {
			Name = "Title",
			Size = UDim2.new(1, -10, 1, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Text = Option.Title,
			TextSize = 13,
			TextTruncate = "AtEnd",
			FontFace = Font.new(Creator.Font, Enum.FontWeight.SemiBold),
			ThemeTag = {
				TextColor3 = "SegmentedControlText",
			},
		})

		local Button = Creator.NewRoundFrame(10, "Squircle", {
			Name = "Segment",
			Size = UDim2.new(0, SegmentWidth, 1, 0),
			-- No manual inset here: the container's UIPadding already moves the
			-- child origin inside the padded box, so adding 4 again pushed the
			-- whole row 4px right and 4px down and broke the vertical centring.
			Position = UDim2.new(0, (Index - 1) * (SegmentWidth + Gap), 0, 0),
			ImageTransparency = 1,
			Active = not Option.Disabled,
			ThemeTag = {
				ImageColor3 = "SegmentedControlActive",
			},
		}, {
			Title,
		}, true)

		Button.Parent = SegmentedControl.UIElements.Container

		local Segment = {
			Button = Button,
			Title = Title,
			Option = Option,
		}
		SegmentedControl.Segments[Index] = Segment

		Motion.AttachPress(Button, Creator, {
			Amount = 0.96,
			Enabled = function()
				return SegmentedControl.Animation and not SegmentedControl.Locked and not Option.Disabled
			end,
		})

		Creator.AddSignal(Button.MouseButton1Click, function()
			if not Option.Disabled then
				SegmentedControl:Select(Option.Value)
			end
		end)
	end

	local function RenderSegments()
		for _, Segment in next, SegmentedControl.Segments do
			if Segment.Button then
				Segment.Button:Destroy()
			end
		end

		SegmentedControl.Segments = {}

		local Count = #SegmentedControl.Options
		for Index, Option in next, SegmentedControl.Options do
			CreateSegment(Option, Index, Count)
		end

		-- Past a certain option count the segments hit their minimum width and
		-- the row is wider than the container. Clip rather than let it spill.
		local _, Clamped = SegmentWidthFor(Count, 4)
		SegmentedControl.UIElements.Container.ClipsDescendants = Clamped

		UpdateSegmentVisuals(false)
	end

	function SegmentedControl:Lock()
		SegmentedControl.Locked = true
		CanCallback = false
		return SegmentedControl.SegmentedControlFrame:Lock(SegmentedControl.LockedTitle)
	end
	function SegmentedControl:Unlock()
		SegmentedControl.Locked = false
		CanCallback = true
		return SegmentedControl.SegmentedControlFrame:Unlock()
	end

	function SegmentedControl:Get()
		return SegmentedControl.Value
	end

	function SegmentedControl:Select(Value, IsCallback)
		local Option = Utils.FindOption(SegmentedControl.Options, Value)
		if not Option or Option.Disabled then
			return SegmentedControl.Value
		end

		SegmentedControl.Value = Value
		UpdateSegmentVisuals(true)

		if CanCallback and IsCallback ~= false then
			Creator.SafeCallback(SegmentedControl.Callback, Value, Option)
		end

		return SegmentedControl.Value
	end

	function SegmentedControl:SetOptions(Options)
		SegmentedControl.Options = Utils.NormalizeOptions(Options)

		if not Utils.FindOption(SegmentedControl.Options, SegmentedControl.Value) then
			-- `and ... or nil` would collapse a first option whose value is
			-- `false` back to nil, leaving nothing selected.
			local First = SegmentedControl.Options[1]
			SegmentedControl.Value = if First then First.Value else nil
		end

		RenderSegments()
		return SegmentedControl.Options
	end

	RenderSegments()

	if SegmentedControl.Locked then
		SegmentedControl:Lock()
	end

	return SegmentedControl.__type, SegmentedControl
end

return Element
