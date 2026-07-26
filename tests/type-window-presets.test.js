const fs = require("fs")

const typeWindow = fs.readFileSync("src/themes/TypeWindow.lua", "utf8")
const themes = fs.readFileSync("src/themes/Init.lua", "utf8")
const init = fs.readFileSync("src/Init.lua", "utf8")
const window = fs.readFileSync("src/components/window/Init.lua", "utf8")

const failures = []
const check = (label, ok) => {
	if (!ok) failures.push(label)
}

// --- TypeWindow module surface -------------------------------------------

for (const fn of ["Resolve", "Get", "GetTheme", "List", "Apply"]) {
	check(`TypeWindow.${fn} is exported`, new RegExp(`function TypeWindow\\.${fn}\\b`).test(typeWindow))
}

// Lookup has to survive "Modern", "liquid-glass" and friends.
check(
	"preset names are normalised before lookup",
	/string\.gsub\(string\.lower\(Name\), "\[%s_%-%.\/\]", ""\)/.test(typeWindow)
)
check("unknown types warn instead of failing silently", /Unknown TypeWindow/.test(typeWindow))

// Apply must never clobber caller values, and must not leak preset metadata.
check("Apply only fills blanks", /if not META_KEYS\[Field\] and Config\[Field\] == nil then/.test(typeWindow))
check("Theme is a meta key", /META_KEYS = \{[^}]*Theme = true/.test(typeWindow))

// --- The modern preset ----------------------------------------------------

const modern = /\tmodern = \{([^]*?)\n\t\},/.exec(typeWindow)
check("modern preset exists", modern !== null)

if (modern) {
	const body = modern[1]
	const expected = {
		Theme: '"Modern"',
		NewElements: "true",
		LiquidGlass: "false",
		LinkElementCorners: "false",
		ElementGap: "10",
		ElementsRadius: "18",
		ElementTransparency: "0",
		Radius: "24",
	}
	for (const [key, value] of Object.entries(expected)) {
		check(
			`modern.${key} = ${value}`,
			new RegExp(`${key} = ${value.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")},`).test(body)
		)
	}
	check("modern uses the reference panel colour", /BackgroundColor = Color3\.fromHex\("#131617"\)/.test(body))
}

// The pre-rework look stays reachable rather than being deleted outright.
const glass = /\tglass = \{([^]*?)\n\t\},/.exec(typeWindow)
check("glass preset preserves the old modern look", glass !== null && /LiquidGlass = true,/.test(glass[1]))

// --- The Modern theme -----------------------------------------------------

const modernTheme = /\t\tModern = \{([^]*?)\n\t\t\},/.exec(themes)
check("Modern theme exists", modernTheme !== null)

if (modernTheme) {
	const body = modernTheme[1]
	check("Modern theme is named", /Name = "Modern",/.test(body))
	check("card surface matches the reference", /ElementBackground = Color3\.fromHex\("#1D2022"\)/.test(body))
	check("panel surface matches the reference", /Background = Color3\.fromHex\("#131617"\)/.test(body))
	check("accent matches the reference", /Primary = Color3\.fromHex\("#A2FF31"\)/.test(body))
	check("cards are opaque", /ElementBackgroundTransparency = 0,/.test(body))

	// White ink on the lime accent is unreadable, so anything drawn on top of
	// Primary has to opt into dark ink.
	for (const key of ["BadgeText", "BadgeIcon", "CheckboxIcon", "CheckboxGroupIcon", "TooltipSecondaryText"]) {
		check(`${key} stays readable on the accent`, new RegExp(`${key} = Color3\\.fromHex\\("#0E1112"\\)`).test(body))
	}
}

// Themes are parsed out of this file by the docs site, which needs a blank
// line (not a stray entry) between neighbours.
check("Modern theme is a top-level entry", /\n\t\tModern = \{/.test(themes))

// --- Wiring ---------------------------------------------------------------

check(
	"window config resolves its preset through the module",
	/require\("\.\.\/\.\.\/themes\/TypeWindow"\)\.Apply\(Config\)/.test(window)
)
check(
	"an explicit Theme still beats the window type's default",
	/local RequestedTheme = Config\.Theme or TypeWindowTheme or "Dark"/.test(init)
)

if (failures.length > 0) {
	throw new Error(`TypeWindow presets are broken:\n  - ${failures.join("\n  - ")}`)
}

console.log("PASS type window presets")
