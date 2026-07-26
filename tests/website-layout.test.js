// global.css carried `main div { width: 100% }`. Unlayered rules beat
// Tailwind's `@layer utilities` regardless of specificity, so that one line
// silently overrode size-*, w-* and grid track sizing on every page: icon tiles
// stretched across their cards and pushed the heading off-screen on phones.
//
// It was there to stop the docs column overflowing after the sidebar and TOC
// were hidden. The real cause was flex items defaulting to min-width:auto, so
// the replacement fixes that directly and stays scoped to the docs layout.

const fs = require("fs")

const css = fs.readFileSync("website/app/global.css", "utf8")
const navbar = fs.readFileSync("website/components/Navbar.tsx", "utf8")
const animatedList = fs.readFileSync("website/components/AnimatedList.tsx", "utf8")
const gettingStarted = fs.readFileSync("website/app/(home)/getting-started/page.tsx", "utf8")

const failures = []
const check = (label, ok) => {
	if (!ok) failures.push(label)
}

// --- global.css ------------------------------------------------------------

// Any bare element selector that sets a width globally is the same trap.
check("no blanket `main div` width rule", !/^\s*main\s+div\s*\{/m.test(css))
check(
	"no global width:100% on an unscoped descendant selector",
	!/^\s*(main|body|#nd-page)\s+(div|\*)\s*\{[^}]*width:\s*100%/m.test(css)
)

check("docs column can shrink", /#nd-docs-layout > div,\s*\n#nd-docs-layout > div > main \{\s*\n\s*min-width: 0;/.test(css))
check("docs page still fills the space the sidebar left", /#nd-page,\s*\n#nd-page > article \{/.test(css))

// --- Navbar ----------------------------------------------------------------

// The link row used to be max-sm:hidden in its entirety, so a phone had no way
// to reach the docs from the top of the landing page.
const docsLink = /docsLink \? \([^)]*\n(?:.|\n)*?<\/Link>\s*\n\s*\) : null/.exec(navbar)
check("navbar renders a docs link", docsLink !== null)
if (docsLink) {
	check("the docs link is visible on mobile", !/max-sm:hidden/.test(docsLink[0]))
}

// Fumadocs' own navbar is a solid 56px bar pinned to the top; the home navbar
// matches it instead of floating in as a pill on scroll.
check("navbar is pinned and 56px tall", /fixed top-0 z-999 flex h-14 w-full/.test(navbar))
check("navbar no longer hides itself until scroll", !/translateY\(-100%\)/.test(navbar))

// The early return sat above the hooks, so the hook count changed between
// routes sharing this layout.
const earlyReturnIndex = navbar.indexOf('pathname === "/about"')
const lastHookIndex = navbar.lastIndexOf("useEffect(")
check("route bail-out runs after the hooks", earlyReturnIndex > lastHookIndex)

// --- Flex children that hold wide content ----------------------------------

check(
	"animated list items can shrink below their content",
	/max-w-full min-w-0 transform transition-/.test(animatedList)
)
check(
	"the loadstring block scrolls itself instead of widening the page",
	/flex w-full min-w-0 flex-row/.test(gettingStarted) && /w-full min-w-0 max-w-2xl/.test(gettingStarted)
)

if (failures.length > 0) {
	throw new Error(`Website layout regressions:\n  - ${failures.join("\n  - ")}`)
}

console.log("PASS website layout")
