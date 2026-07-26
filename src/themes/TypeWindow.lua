--[[
	Window type presets.

	A "window type" is a bundle of layout + surface defaults that gives the
	whole library a consistent look without the caller having to hand-tune a
	dozen `CreateWindow` fields. Callers still win: anything explicitly passed
	to `CreateWindow` is left untouched, presets only fill in the gaps.

		WindUI:CreateWindow({ TypeWindow = "modern" })

	`Theme` is a *meta* key. It never reaches the window config; it is read by
	src/Init.lua to pick a default palette when the caller did not ask for one.
]]

-- Keys that configure the preset itself rather than the window.
local META_KEYS = {
	Theme = true,
	Description = true,
}

local Presets = {
	-- Neutral near-black cards, generous gaps, one bright accent.
	-- Surfaces: #131617 panel / #1D2022 card, accent #A2FF31.
	modern = {
		Description = "Flat near-black cards with wide gaps and a lime accent",
		Theme = "Modern",

		NewElements = true,
		LiquidGlass = false,
		LinkElementCorners = false,
		ElementGap = 10,
		ElementsRadius = 18,
		ElementTransparency = 0,
		BackgroundOverlayTransparency = 0.35,
		BackgroundColor = Color3.fromHex("#131617"),
		ShadowTransparency = 0.35,
		Radius = 24,
		SideBarWidth = 210,
		Topbar = { Height = 46, ButtonsType = "Mac" },
		HideSearchBar = false,
	},

	-- The look "modern" had before it was rebuilt: translucent liquid-glass
	-- elements welded into a single column by linked corners.
	glass = {
		Description = "Translucent liquid-glass elements with linked corners",

		NewElements = true,
		LiquidGlass = true,
		LinkElementCorners = true,
		ElementGap = 1,
		ElementTransparency = 0.18,
		BackgroundOverlayTransparency = 0.5,
		BackgroundColor = Color3.fromHex("#101821"),
		Radius = 20,
		SideBarWidth = 210,
		Topbar = { Height = 48, ButtonsType = "Mac" },
		CornerLink = { InnerRadius = 0, BridgeHidden = true },
		HideSearchBar = false,
	},

	default = {
		Description = "The original WindUI look",

		NewElements = false,
		LiquidGlass = false,
		LinkElementCorners = false,
		ElementGap = 8,
		ElementTransparency = nil,
		BackgroundOverlayTransparency = 0.62,
		BackgroundColor = nil,
		Radius = 16,
		SideBarWidth = 200,
		Topbar = { Height = 52, ButtonsType = "Default" },
	},
}

local Aliases = {
	modern = "modern",
	card = "modern",
	cards = "modern",
	flat = "modern",

	glass = "glass",
	liquid = "glass",
	liquidglass = "glass",
	acrylic = "glass",

	default = "default",
	classic = "default",
	legacy = "default",
	original = "default",
}

local TypeWindow = {
	Presets = Presets,
	Aliases = Aliases,
}

-- "Liquid Glass", "liquid-glass" and "liquid_glass" all mean the same thing.
local function Normalize(Name)
	if typeof(Name) ~= "string" then
		return nil
	end
	return (string.gsub(string.lower(Name), "[%s_%-%./]", ""))
end

--- Returns the canonical preset name for `Name`, or nil when unknown.
function TypeWindow.Resolve(Name)
	local Key = Normalize(Name)
	if not Key then
		return nil
	end
	return Aliases[Key] or (Presets[Key] and Key) or nil
end

--- Returns the preset table for `Name`, or nil when unknown.
function TypeWindow.Get(Name)
	local Key = TypeWindow.Resolve(Name)
	return Key and Presets[Key] or nil
end

--- Returns the default theme name a window type asks for, or nil.
function TypeWindow.GetTheme(Name)
	local Preset = TypeWindow.Get(Name)
	return Preset and Preset.Theme or nil
end

--- Returns every canonical preset name, sorted.
function TypeWindow.List()
	local Names = {}
	for Key in next, Presets do
		table.insert(Names, Key)
	end
	table.sort(Names)
	return Names
end

--- Fills the blanks in `Config` from the preset named by `Config.TypeWindow`.
--- Explicit caller values always win. Returns the canonical preset name, or
--- nil when there was nothing to apply.
function TypeWindow.Apply(Config)
	if Config == nil or Config.TypeWindow == nil then
		return nil
	end

	local Key = TypeWindow.Resolve(Config.TypeWindow)
	if not Key then
		warn(
			"[ WindUI ] Unknown TypeWindow '"
				.. tostring(Config.TypeWindow)
				.. "'. Expected one of: "
				.. table.concat(TypeWindow.List(), ", ")
		)
		return nil
	end

	for Field, Value in next, Presets[Key] do
		if not META_KEYS[Field] and Config[Field] == nil then
			Config[Field] = Value
		end
	end

	Config.TypeWindow = Key
	return Key
end

return TypeWindow
