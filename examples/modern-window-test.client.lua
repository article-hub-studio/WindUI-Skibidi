--[[
	Test script for the reworked "modern" window type.

	Flip WINDOW_TYPE and re-run to check each path:

		"modern"       -> flat cards, wide gaps, Modern theme
		"Modern"       -> same (lookup is case-insensitive)
		"MODERN"       -> same
		"liquid-glass" -> resolves to the `glass` type via alias
		"Liquid Glass" -> same (separators are ignored)
		"classic"      -> resolves to `default`
		"banana"       -> warns in the console, config left untouched

	The Preset tab reads the values back off the window, so you can see what
	actually landed instead of guessing from the screenshot.
]]

local WINDOW_TYPE = "modern"

-- Set to a theme name to prove an explicit Theme beats the one the window
-- type ships with. Leave nil to let "modern" bring the Modern theme.
local FORCE_THEME = nil

local WindUI = loadstring(game:HttpGet("https://article-hub-studio.github.io/WindUI-Skibidi/loader.lua"))()

local ACCENT = Color3.fromHex("#A2FF31")
local DANGER = Color3.fromHex("#F44732")

local Window = WindUI:CreateWindow({
	Title = "Modern Type Test",
	Author = WINDOW_TYPE,
	Folder = "WindUIModernTest",
	Icon = "layout-dashboard",
	TypeWindow = WINDOW_TYPE,
	Theme = FORCE_THEME,
	ToggleKey = Enum.KeyCode.RightShift,
})

--------------------------------------------------------------------------
-- 1. The reference layout
--------------------------------------------------------------------------

local ReferenceTab = Window:Tab({ Title = "Reference", Icon = "house" })

local Session = ReferenceTab:Card({
	Title = "Baseplate",
	Desc = "@Templates",
	Icon = "box",
})

local SessionActions = Session:HStack()
SessionActions:Button({
	Title = "Rejoin",
	Icon = "rotate-cw",
	Callback = function()
		WindUI:Notify({ Title = "Rejoin", Content = "Reconnecting…", Icon = "rotate-cw" })
	end,
})
SessionActions:Button({
	Title = "Server Hop",
	Icon = "shuffle",
	Callback = function()
		WindUI:Notify({ Title = "Server Hop", Content = "Finding a server…", Icon = "shuffle" })
	end,
})

ReferenceTab:Divider()

local Recent = ReferenceTab:Section({ Title = "Recent scripts" })

for _, Script in
	{
		{ Name = "My script", When = "42 minutes ago", Starred = true },
		{ Name = "Dex explorer", When = "Yesterday", Starred = false },
	}
do
	local Row = Recent:Card({
		Title = Script.Name,
		Desc = Script.When,
		Icon = Script.Starred and "star" or "file-code",
		Color = Script.Starred and ACCENT or nil,
	})

	local Actions = Row:HStack()
	Actions:Button({
		Title = "Execute",
		Icon = "play",
		Color = ACCENT,
		Callback = function()
			WindUI:Notify({ Title = Script.Name, Content = "Executed", Icon = "play" })
		end,
	})
	Actions:Button({
		Title = "Delete",
		Icon = "trash-2",
		Color = DANGER,
		Callback = function()
			WindUI:Notify({ Title = Script.Name, Content = "Removed", Icon = "trash-2" })
		end,
	})
end

--------------------------------------------------------------------------
-- 2. Contrast check
--
-- The Modern accent is bright lime, so anything painted on top of it has to
-- switch to dark ink. Every element below draws on the accent - if a label
-- looks washed out here, that is the bug.
--------------------------------------------------------------------------

local ContrastTab = Window:Tab({ Title = "Contrast", Icon = "contrast" })

ContrastTab:Callout({
	Title = "Read every label",
	Desc = "Badges, checkboxes and tooltips all paint on the accent colour.",
	Variant = "Info",
})

local Badges = ContrastTab:HStack()
Badges:Badge({ Title = "Default", Value = "on accent" })
Badges:Badge({ Title = "Success", Value = "ok", Variant = "Success" })
Badges:Badge({ Title = "Error", Value = "fail", Variant = "Error" })

ContrastTab:CheckboxGroup({
	Title = "Checkbox group",
	Desc = "Ticks are drawn inside the accent square",
	Options = { "Auto execute", "Rejoin on kick", "Silent aim" },
	Value = { "Auto execute" },
	Callback = function() end,
})

ContrastTab:SegmentedControl({
	Title = "Segmented control",
	Desc = "The active pill stays neutral so its label survives",
	Options = { "Low", "Medium", "High" },
	Default = "Medium",
	Callback = function() end,
})

ContrastTab:Toggle({
	Title = "Toggle",
	Desc = "Accent track, white knob",
	Default = true,
	Callback = function() end,
})

ContrastTab:Slider({
	Title = "Slider",
	Desc = "Accent fill on a dark track",
	Step = 1,
	Value = { Min = 0, Max = 10, Default = 7 },
	Callback = function() end,
})

ContrastTab:ProgressBar({
	Title = "Progress bar",
	Value = 62,
	Min = 0,
	Max = 100,
	ShowValue = true,
})

--------------------------------------------------------------------------
-- 3. What actually got applied
--------------------------------------------------------------------------

local PresetTab = Window:Tab({ Title = "Preset", Icon = "sliders-horizontal" })

local function Show(Value)
	if Value == nil then
		return "nil"
	end
	return tostring(Value)
end

PresetTab:KeyValue({
	Title = "Resolved window type",
	Items = {
		{ Key = "Requested", Value = WINDOW_TYPE },
		{ Key = "Resolved", Value = Show(Window.TypeWindow) },
		{ Key = "Theme", Value = WindUI:GetCurrentTheme() },
	},
})

PresetTab:KeyValue({
	Title = "Layout",
	Items = {
		{ Key = "Element gap", Value = Show(Window.ElementGap) },
		{ Key = "Element radius", Value = Show(Window.ElementConfig.UICorner) },
		{ Key = "Window radius", Value = Show(Window.Radius) },
		{ Key = "Sidebar width", Value = Show(Window.SideBarWidth) },
		{ Key = "Topbar height", Value = Show(Window.Topbar.Height) },
		{ Key = "Topbar buttons", Value = Show(Window.Topbar.ButtonsType) },
	},
})

PresetTab:KeyValue({
	Title = "Surfaces",
	Items = {
		{ Key = "Linked corners", Value = Show(Window.LinkElementCorners) },
		{ Key = "Liquid glass", Value = Show(Window.LiquidGlass) },
		{ Key = "Element transparency", Value = Show(Window.ElementConfig.Transparency) },
		{ Key = "New elements", Value = Show(Window.NewElements) },
	},
})

-- Expected values for TypeWindow = "modern" (any casing):
--   Resolved = modern      Theme = Modern
--   Element gap = 10       Element radius = 18     Window radius = 24
--   Linked corners = false Liquid glass = false    Element transparency = 0

local Expected = {
	modern = {
		ElementGap = 10,
		Radius = 24,
		LinkElementCorners = false,
		LiquidGlass = false,
	},
	glass = {
		ElementGap = 1,
		Radius = 20,
		LinkElementCorners = true,
		LiquidGlass = true,
	},
	default = {
		ElementGap = 8,
		Radius = 16,
		LinkElementCorners = false,
		LiquidGlass = false,
	},
}

local Want = Expected[Window.TypeWindow]
if Want then
	local Mismatches = {}
	for Field, Value in Want do
		if Window[Field] ~= Value then
			table.insert(Mismatches, ("%s = %s (want %s)"):format(Field, Show(Window[Field]), Show(Value)))
		end
	end

	PresetTab:Callout({
		Title = #Mismatches == 0 and "Preset applied correctly" or "Preset mismatch",
		Desc = #Mismatches == 0 and ("Every field matches the " .. Window.TypeWindow .. " preset.")
			or table.concat(Mismatches, "\n"),
		Variant = #Mismatches == 0 and "Success" or "Error",
	})
else
	PresetTab:Callout({
		Title = "No preset applied",
		Desc = "'" .. WINDOW_TYPE .. "' did not resolve - check the console for the warning listing valid names.",
		Variant = "Warning",
	})
end

Window:SelectTab(1)
