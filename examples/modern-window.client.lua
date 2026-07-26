-- The "modern" window type: flat near-black cards, wide gaps and one lime
-- accent. Everything below the CreateWindow call is ordinary WindUI code -
-- the type only supplies defaults.

local WindUI = loadstring(game:HttpGet("https://article-hub-studio.github.io/WindUI-Skibidi/loader.lua"))()

local ACCENT = Color3.fromHex("#A2FF31")
local DANGER = Color3.fromHex("#F44732")

local Window = WindUI:CreateWindow({
	Title = "WindUI Modern Example",
	Folder = "WindUIModernExample",
	Icon = "layout-dashboard",

	-- Brings NewElements, 10px element gaps, 18px element radius, 24px window
	-- radius, a Mac topbar and the Modern theme. Pass any of those yourself to
	-- override just that field.
	TypeWindow = "modern",

	ToggleKey = Enum.KeyCode.RightShift,
})

local HomeTab = Window:Tab({
	Title = "Home",
	Icon = "house",
})

-- Session card: title, subtitle, two neutral actions.
local Session = HomeTab:Card({
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

HomeTab:Divider()

-- Recent scripts: each row pairs a lime primary action with a red destructive one.
local Recent = HomeTab:Section({
	Title = "Recent scripts",
})

local RecentScripts = {
	{ Name = "My script", When = "42 minutes ago", Starred = true },
	{ Name = "Dex explorer", When = "Yesterday", Starred = false },
}

for _, Script in RecentScripts do
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

HomeTab:Divider()

-- The accent also drives toggles, sliders and progress bars.
HomeTab:Toggle({
	Title = "Auto execute on join",
	Default = true,
	Callback = function() end,
})

HomeTab:Slider({
	Title = "Execution delay",
	Step = 1,
	Value = { Min = 0, Max = 10, Default = 2 },
	Callback = function() end,
})

Window:SelectTab(1)
