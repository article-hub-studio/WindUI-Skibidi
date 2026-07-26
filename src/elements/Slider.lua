local cloneref = require("../utils/cloneref")
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))

local Creator = require("../modules/Creator")
local Motion = require("../modules/Motion")
local New = Creator.New

local Element = {}

function Element:New(Config)
	local Slider = {
		__type = "Slider",
		Title = Config.Title or nil,
		Desc = Config.Desc or nil,
		Locked = Config.Locked or nil,
		LockedTitle = Config.LockedTitle,
		Value = Config.Value or {
			Min = Config.Min or 0,
			Max = Config.Max or 100,
			Default = Config.Default or Config.Min or 0,
		},
		Icons = Config.Icons or nil,
		IsTooltip = Config.IsTooltip or false,
		IsTextbox = Config.IsTextbox,
		Step = Config.Step or 1, -- 1, 0.5, 0.1, 0.01, ...
		Callback = Config.Callback or function() end,
		UIElements = {},
		IsFocusing = false,

		Width = Config.Width or 130,
		TextBoxWidth = Config.Window.NewElements and 40 or 30,
		ThumbSize = 13,
		IconSize = 26,
	}
	if typeof(Slider.Icons) == "table" and next(Slider.Icons) == nil then
		Slider.Icons = {
			From = "sfsymbols:sunMinFill",
			To = "sfsymbols:sunMaxFill",
		}
	end
	if Slider.IsTextbox == nil and Slider.Title == nil then
		Slider.IsTextbox = false
	else
		Slider.IsTextbox = Slider.IsTextbox ~= false
	end

	local isTouch
	local moveconnection
	local releaseconnection
	local IsSliderHolding = false

	Slider.Value.Min = tonumber(Slider.Value.Min) or 0
	Slider.Value.Max = tonumber(Slider.Value.Max) or 100

	-- An inverted or empty range makes every delta a division by zero, so
	-- normalise it once here instead of guarding at each use site.
	if Slider.Value.Max < Slider.Value.Min then
		Slider.Value.Min, Slider.Value.Max = Slider.Value.Max, Slider.Value.Min
	end

	-- A Step of 0 (or a negative one) would divide by zero when snapping.
	Slider.Step = math.abs(tonumber(Slider.Step) or 1)
	if Slider.Step <= 0 then
		Slider.Step = 1
	end

	Slider.Value.Default = tonumber(Slider.Value.Default) or Slider.Value.Min

	local IsFloat = Slider.Step % 1 ~= 0
	local DecimalPlaces = 0
	if IsFloat then
		-- 0.1 -> 1, 0.01 -> 2
		local StepText = tostring(Slider.Step)
		local DotIndex = StepText:find("%.")
		if DotIndex then
			DecimalPlaces = #StepText:sub(DotIndex + 1)
		end
	end

	local function Round(Number)
		return math.floor(Number + 0.5)
	end

	local function FormatValue(RawValue)
		local Number = tonumber(RawValue) or Slider.Value.Min
		if IsFloat then
			local Multiplier = 10 ^ DecimalPlaces
			return tonumber(string.format("%." .. DecimalPlaces .. "f", Round(Number * Multiplier) / Multiplier))
		end
		return Round(Number)
	end

	--- Snaps to the nearest Step and keeps the result inside [Min, Max].
	--- Snapping can push a value past Max when the range is not a whole
	--- number of steps, so the clamp has to come last.
	local function CalculateValue(RawValue)
		local Number = tonumber(RawValue) or Slider.Value.Min
		local Snapped = Round(Number / Slider.Step) * Slider.Step
		return math.clamp(FormatValue(Snapped), Slider.Value.Min, Slider.Value.Max)
	end

	--- Fraction of the track a value sits at, 0 when the range is empty.
	--- Reads Min/Max live because SetMin/SetMax may move them later.
	local function DeltaFor(RawValue)
		local Span = Slider.Value.Max - Slider.Value.Min
		if Span == 0 then
			return 0
		end
		return math.clamp(((tonumber(RawValue) or Slider.Value.Min) - Slider.Value.Min) / Span, 0, 1)
	end

	local Value = CalculateValue(Slider.Value.Default)
	Slider.Value.Default = Value

	local LastValue = Value
	local delta = DeltaFor(Value)

	local CanCallback = true

	local IconFrom, IconTo
	local TotalSliderWidth = 32
	if Slider.Icons then
		if Slider.Icons.From then
			IconFrom = Creator.Image(
				Slider.Icons.From,
				Slider.Icons.From,
				0,
				Config.Window.Folder,
				"SliderIconFrom",
				true,
				true,
				"SliderIconFrom"
			)
			IconFrom.Size = UDim2.new(0, Slider.IconSize, 0, Slider.IconSize)
			TotalSliderWidth = TotalSliderWidth + Slider.IconSize - 2
		end
		if Slider.Icons.To then
			IconTo = Creator.Image(
				Slider.Icons.To,
				Slider.Icons.To,
				0,
				Config.Window.Folder,
				"SliderIconTo",
				true,
				true,
				"SliderIconTo"
			)
			IconTo.Size = UDim2.new(0, Slider.IconSize, 0, Slider.IconSize)
			TotalSliderWidth = TotalSliderWidth + Slider.IconSize - 2
		end
	end
	Slider.SliderFrame = require("../components/window/Element")({
		Title = Slider.Title,
		Desc = Slider.Desc,
		Parent = Config.Parent,
		TextOffset = Slider.Width,
		Hover = false,
		Tab = Config.Tab,
		Index = Config.Index,
		Window = Config.Window,
		ElementTable = Slider,
		ParentConfig = Config,
		Tags = Config.Tags,
	})

	Slider.UIElements.SliderIcon = Creator.NewRoundFrame(99, "Squircle", {
		ImageTransparency = 0.95,
		Size = UDim2.new(1, not Slider.IsTextbox and -TotalSliderWidth or (-Slider.TextBoxWidth - 8), 0, 4),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Name = "Frame",
		ThemeTag = {
			ImageColor3 = "Text",
		},
	}, {
		Creator.NewRoundFrame(99, "Squircle", {
			Name = "Frame",
			Size = UDim2.new(delta, 0, 1, 0),
			ImageTransparency = 0.1,
			ThemeTag = {
				ImageColor3 = "Slider",
			},
		}, {
			Creator.NewRoundFrame(99, "Squircle", {
				Size = UDim2.new(
					0,
					Config.Window.NewElements and (Slider.ThumbSize * 2) or (Slider.ThumbSize + 2),
					0,
					Config.Window.NewElements and (Slider.ThumbSize + 4) or (Slider.ThumbSize + 2)
				),
				Position = UDim2.new(1, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				ThemeTag = {
					ImageColor3 = "SliderThumb",
				},
				Name = "Thumb",
			}, {
				Creator.NewRoundFrame(999, "SquircleGlass", {
					Size = UDim2.new(1, 0, 1, 0),
					ImageColor3 = Color3.new(1, 1, 1),
					Name = "Highlight",
					ImageTransparency = 0.5,
				}),
			}),
		}),
	})

	Slider.UIElements.SliderContainer = New("Frame", {
		Size = UDim2.new(Slider.Title == nil and 1 or 0, Slider.Title == nil and 0 or Slider.Width, 0, 0),
		AutomaticSize = "Y",
		Position = UDim2.new(1, Slider.IsTextbox and (Config.Window.NewElements and -12 - 4 or 0) or 0, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Parent = Slider.SliderFrame.UIElements.Main,
	}, {
		New("UIListLayout", {
			Padding = UDim.new(0, Slider.Title ~= nil and 8 or 12),
			FillDirection = "Horizontal",
			VerticalAlignment = "Center",
			HorizontalAlignment = Slider.Icons
					and (Slider.Icons.From and (Slider.Icons.To and "Center" or "Left") or Slider.Icons.To and "Right")
				or "Center",
		}),
		IconFrom,
		Slider.UIElements.SliderIcon,
		IconTo,
		New("TextBox", {
			Size = UDim2.new(0, Slider.TextBoxWidth, 0, 0),
			TextXAlignment = "Left",
			Text = FormatValue(Value),
			ThemeTag = {
				TextColor3 = "Text",
			},
			TextTransparency = 0.4,
			AutomaticSize = "Y",
			TextSize = 15,
			FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
			BackgroundTransparency = 1,
			LayoutOrder = -1,
			Visible = Slider.IsTextbox,
		}),
	})

	local Tooltip
	if Slider.IsTooltip then
		Tooltip = require("../components/ui/Tooltip").New(
			Value,
			Slider.UIElements.SliderIcon.Frame.Thumb,
			true,
			"Secondary",
			"Small",
			false
		)
		Tooltip.Container.AnchorPoint = Vector2.new(0.5, 1)
		Tooltip.Container.Position = UDim2.new(0.5, 0, 0, -8)
	end

	local function SetFillSize(Delta, Duration)
		local Size = UDim2.new(Delta, 0, 1, 0)
		if Duration == 0 or not Motion.ShouldAnimate(Config) then
			-- Drop any tween still animating towards the previous target,
			-- otherwise it keeps writing over this assignment.
			Motion.Cancel(Slider.UIElements.SliderIcon.Frame, "Fill")
			Slider.UIElements.SliderIcon.Frame.Size = Size
		else
			Motion.Play(Slider.UIElements.SliderIcon.Frame, Duration or "Fast", { Size = Size }, nil, nil, "Fill")
		end
	end

	--- The thumb carries a SquircleGlass sheen. It used to sit at a fixed
	--- transparency, so the thumb read as flat while the toggle's glass
	--- responded to touch; brighten it while the slider is being dragged.
	local function SetThumbGlass(Active)
		local Thumb = Slider.UIElements.SliderIcon and Slider.UIElements.SliderIcon.Frame.Thumb
		local Highlight = Thumb and Thumb:FindFirstChild("Highlight")
		if not Highlight then
			return
		end

		Motion.Play(
			Highlight,
			"Focus",
			{ ImageTransparency = if Active then 0.18 else 0.5 },
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out,
			"Glass"
		)
	end

	function Slider:Lock()
		Slider.Locked = true
		CanCallback = false
		return Slider.SliderFrame:Lock(Slider.LockedTitle)
	end
	function Slider:Unlock()
		Slider.Locked = false
		CanCallback = true
		return Slider.SliderFrame:Unlock()
	end

	if Slider.Locked then
		Slider:Lock()
	end

	local ScrollingFrameParent = Config.Tab.UIElements.ContainerFrame
	local CurInput = Config.WindUI.GenerateGUID()

	local function DisconnectSliderInput()
		local WasHolding = IsSliderHolding
			or moveconnection ~= nil
			or releaseconnection ~= nil
			or Config.WindUI.CurrentInput == CurInput

		if moveconnection then
			Creator.DisconnectSignal(moveconnection)
			moveconnection = nil
		end
		if releaseconnection then
			Creator.DisconnectSignal(releaseconnection)
			releaseconnection = nil
		end

		IsSliderHolding = false
		if WasHolding then
			ScrollingFrameParent.ScrollingEnabled = true
		end
		if Config.WindUI.CurrentInput == CurInput then
			Config.WindUI.CurrentInput = nil
		end
	end

	local function FinishSliderInput()
		local WasHolding = IsSliderHolding
		DisconnectSliderInput()
		if not WasHolding then
			return
		end

		SetThumbGlass(false)

		if Config.Window.NewElements then
			Motion.Play(Slider.UIElements.SliderIcon.Frame.Thumb, "Focus", {
				ImageTransparency = 0,
				Size = UDim2.new(
					0,
					Config.Window.NewElements and (Slider.ThumbSize * 2) or (Slider.ThumbSize + 2),
					0,
					Config.Window.NewElements and (Slider.ThumbSize + 4) or (Slider.ThumbSize + 2)
				),
			}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, "Thumb")
		end
		if Tooltip then
			Tooltip:Close(false)
		end
	end
	--- True once the track has been laid out and can be measured.
	local function TrackIsMeasurable()
		local Track = Slider.UIElements.SliderIcon
		return Track ~= nil and Track.AbsoluteSize.X > 0
	end

	--- Where the pointer sits along the track, as a 0-1 fraction.
	local function DeltaForInput(Input)
		local Track = Slider.UIElements.SliderIcon
		if not Track then
			return 0
		end

		local TrackWidth = Track.AbsoluteSize.X
		if TrackWidth <= 0 then
			return 0
		end

		local PointerX = if isTouch
			then (Input.Position and Input.Position.X or 0)
			else UserInputService:GetMouseLocation().X

		return math.clamp((PointerX - Track.AbsolutePosition.X) / TrackWidth, 0, 1)
	end

	--- Single place that writes a value out: fill, textbox, tooltip, state and
	--- callback always move together, and the fill is derived from the value
	--- that was actually committed rather than from the raw pointer position.
	local function Commit(NextValue, FillDuration)
		local Committed = CalculateValue(NextValue)
		if Committed == LastValue then
			return Committed
		end

		LastValue = Committed
		Slider.Value.Default = Committed

		SetFillSize(DeltaFor(Committed), FillDuration)
		if Slider.UIElements.SliderContainer then
			Slider.UIElements.SliderContainer.TextBox.Text = tostring(Committed)
		end
		if Tooltip then
			Tooltip.TitleFrame.Text = tostring(Committed)
		end

		Creator.SafeCallback(Slider.Callback, Committed)
		return Committed
	end

	function Slider:Set(NextValue, input)
		if not CanCallback or Slider.IsFocusing or IsSliderHolding then
			return
		end

		if NextValue == nil then
			NextValue = Slider.Value.Default
		end

		if
			input
			and not (
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			input = nil
		end

		if not input then
			Value = Commit(NextValue, "Fast")
			return Value
		end

		-- Nothing to aim at until the track has a width; a press this early is
		-- a no-op rather than a warning, because layout catches up next frame.
		if not TrackIsMeasurable() then
			return Value
		end

		-- The input mutex is claimed here, at the one point a drag is certain
		-- to start. Claiming it earlier meant any guard above returned while
		-- still holding it, and only DisconnectSliderInput ever releases it -
		-- which needs the connections this branch is about to create.
		if Config.WindUI.CurrentInput and Config.WindUI.CurrentInput ~= CurInput then
			return Value
		end
		Config.WindUI.CurrentInput = CurInput

		isTouch = input.UserInputType == Enum.UserInputType.Touch
		ScrollingFrameParent.ScrollingEnabled = false
		IsSliderHolding = true
		SetThumbGlass(true)

		local Span = Slider.Value.Max - Slider.Value.Min
		local function TrackValue(Delta)
			return Slider.Value.Min + Delta * Span
		end

		Value = Commit(TrackValue(DeltaForInput(input)), 0)

		moveconnection = Creator.AddSignal(RunService.RenderStepped, function()
			if not TrackIsMeasurable() then
				return
			end
			Value = Commit(TrackValue(DeltaForInput(input)), 0)
		end)

		releaseconnection = Creator.AddSignal(UserInputService.InputEnded, function(endInput)
			local ReleasedTouch = input.UserInputType == Enum.UserInputType.Touch and endInput == input
			local ReleasedMouse = input.UserInputType == Enum.UserInputType.MouseButton1
				and endInput.UserInputType == Enum.UserInputType.MouseButton1
			if ReleasedTouch or ReleasedMouse then
				FinishSliderInput()
			end
		end)

		return Value
	end

	--- Moves a bound and re-seats the current value inside the new range.
	--- Both bounds go through here so the fill, the textbox and Value.Default
	--- can never disagree after a resize.
	local function SetBound(Field, NewBound, Fallback)
		local Bound = tonumber(NewBound) or Fallback
		Slider.Value[Field] = Bound

		if Slider.Value.Max < Slider.Value.Min then
			Slider.Value.Min, Slider.Value.Max = Slider.Value.Max, Slider.Value.Min
		end

		local Current = tonumber(Slider.Value.Default) or LastValue or Slider.Value.Min
		local Reseated = CalculateValue(Current)

		if Reseated ~= LastValue then
			-- Out of range now: Commit re-renders everything and fires the callback.
			Commit(Reseated, "Fast")
		else
			-- Still in range, but the track it sits on just changed length.
			SetFillSize(DeltaFor(Reseated), "Fast")
			if Slider.UIElements.SliderContainer then
				Slider.UIElements.SliderContainer.TextBox.Text = tostring(Reseated)
			end
		end
	end

	function Slider:SetMax(newMax)
		SetBound("Max", newMax, 100)
	end

	function Slider:SetMin(newMin)
		SetBound("Min", newMin, 0)
	end

	Creator.AddSignal(Slider.UIElements.SliderContainer.TextBox.FocusLost, function()
		local Typed = tonumber(Slider.UIElements.SliderContainer.TextBox.Text)
		if Typed then
			-- Set snaps and clamps; no need to pre-clamp here.
			Slider:Set(Typed)
		end

		-- Whatever was typed, the box shows the value that was actually kept.
		Slider.UIElements.SliderContainer.TextBox.Text = tostring(LastValue)
		if Tooltip then
			Tooltip.TitleFrame.Text = tostring(LastValue)
		end
	end)

	Creator.AddSignal(Slider.UIElements.SliderContainer.InputBegan, function(input)
		if Slider.Locked or IsSliderHolding then
			return
		end
		if
			input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch
		then
			return
		end

		Slider:Set(Value, input)

		-- Set only begins a drag once it owns the input and can measure the
		-- track. If it bailed, there is nothing to animate and no hold to show.
		if not IsSliderHolding then
			return
		end

		if Config.Window.NewElements then
			Motion.Play(Slider.UIElements.SliderIcon.Frame.Thumb, "Focus", {
				ImageTransparency = 0.85,
				Size = UDim2.new(
					0,
					(Config.Window.NewElements and (Slider.ThumbSize * 2) or Slider.ThumbSize) + 8,
					0,
					Slider.ThumbSize + 8
				),
			}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, "Thumb")
		end
		if Tooltip then
			Tooltip:Open()
		end
	end)

	function Slider:Cleanup()
		DisconnectSliderInput()
		SetThumbGlass(false)
		if Tooltip then
			Tooltip:Close(false)
		end
	end

	return Slider.__type, Slider
end

return Element
