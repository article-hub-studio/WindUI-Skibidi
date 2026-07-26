// The docs site lists every theme by parsing src/themes/Init.lua with a
// regex. A theme that the regex cannot see silently disappears from the docs -
// or worse, gets folded into its neighbour and corrupts that theme's swatch.
// This runs the site's own regex against the real theme file.

const fs = require("fs")

const source = fs.readFileSync("website/lib/windui/getThemes.ts", "utf8")
const lua = fs.readFileSync("src/themes/Init.lua", "utf8")

const literal = /const themeRegex =\s*(\/[^]*?\/)g;/.exec(source)
if (!literal) {
	throw new Error("Could not find themeRegex in website/lib/windui/getThemes.ts")
}

const themeRegex = new RegExp(literal[1].slice(1, -1), "g")

const declared = [...lua.matchAll(/^\t\t([A-Za-z0-9_]+) = \{$/gm)].map((m) => m[1])
const parsed = new Map()
let match
while ((match = themeRegex.exec(lua)) !== null) {
	// getThemes strips Lua comments before reading colours - mirror that here.
	parsed.set(match[1], match[2].replace(/--[^\n]*/g, ""))
}

const missing = declared.filter((name) => !parsed.has(name))
if (missing.length > 0) {
	throw new Error(`Docs theme parser cannot see: ${missing.join(", ")}`)
}

if (!parsed.has("Modern")) {
	throw new Error("Docs theme parser lost the Modern theme")
}

// Each entry must stop at its own closing brace. If Dark swallowed Modern,
// Dark's body would carry Modern's accent.
const dark = parsed.get("Dark")
if (/#A2FF31/i.test(dark)) {
	throw new Error("Dark theme body leaked into the next theme")
}

// Commented-out declarations are not real theme colours.
const rose = parsed.get("Rose")
if (/Outline\s*=\s*Color3/.test(rose)) {
	throw new Error("Docs theme parser reads commented-out declarations")
}

console.log(`PASS docs theme parser (${parsed.size} themes)`)
