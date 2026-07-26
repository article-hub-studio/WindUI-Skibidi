// The site is served from the gh-pages branch and nothing kept it current -
// its last commit was pushed by hand, so the published docs and the published
// runtime both froze. pages.yml republishes the export on every push to main.
// That export also hosts every loadstring URL, so a change that drops one of
// those paths from website/public would take the runtime down with it.

const fs = require("fs")
const path = require("path")

const failures = []
const check = (label, ok) => {
	if (!ok) failures.push(label)
}

const workflowPath = ".github/workflows/pages.yml"
check("a Pages deploy workflow exists", fs.existsSync(workflowPath))

if (fs.existsSync(workflowPath)) {
	const workflow = fs.readFileSync(workflowPath, "utf8")

	check("deploys on pushes to main", /branches: \["main"\]/.test(workflow))
	// Pages serves the gh-pages branch on this repo, so publishing has to
	// push there. The Actions-artifact route needs a settings change and
	// fails instantly without it.
	check("publishes the export to gh-pages", /git push -f .* gh-pages/.test(workflow))
	check("publishes website/out", /cd website\/out/.test(workflow))
	check("can write to the repository", /contents: write/.test(workflow))
	// Jekyll would swallow Next's _next/ asset directory.
	check("disables Jekyll on the published branch", /touch website\/out\/\.nojekyll/.test(workflow))
	// A commit subject from the trigger interpolated into the shell would be
	// an injection vector.
	check("does not interpolate untrusted text into the shell", !/\$\{\{ github\.event\./.test(workflow))
	// A cancelled deploy can leave Pages serving a partial site.
	check("does not cancel in-flight deploys", /cancel-in-progress: false/.test(workflow))
	// The export has to contain a freshly built bundle, not the committed one.
	check("builds the library before exporting", /run: npm run build/.test(workflow))
	check("syncs the Pages assets", /run: npm run sync:pages/.test(workflow))
	check("builds the docs", /run: npm run docs:build/.test(workflow))
	// Rate-limited GitHub API calls used to fail the whole export.
	check("passes a token to the docs build", /GITHUB_TOKEN: \$\{\{ secrets\.GITHUB_TOKEN \}\}/.test(workflow))
}

// Everything the published runtime fetches lives in website/public, which
// becomes the root of the export.
const RUNTIME_ASSETS = [
	"loader.lua",
	"main.lua",
	"dist/main.lua",
	"main_example.lua",
	"src/themes/Init.lua",
]

for (const asset of RUNTIME_ASSETS) {
	check(`website/public/${asset} is published`, fs.existsSync(path.join("website/public", asset)))
}

// The loader hard-codes the URL it fetches; that path must be one we publish.
const loader = fs.readFileSync("loader.lua", "utf8")
const sourceUrl = /https:\/\/article-hub-studio\.github\.io\/WindUI-Skibidi\/([^"?]+)/.exec(loader)
check("the loader's source URL is parseable", sourceUrl !== null)
if (sourceUrl) {
	check(
		`the loader fetches a published path (${sourceUrl[1]})`,
		fs.existsSync(path.join("website/public", sourceUrl[1]))
	)
}

// sync:pages is what keeps those copies honest.
const sync = fs.readFileSync("build/sync-pages.sh", "utf8")
for (const asset of ["dist/main.lua", "loader.lua", "src/themes/Init.lua", "main_example.lua"]) {
	check(`sync-pages.sh copies ${asset}`, sync.includes(asset))
}

if (failures.length > 0) {
	throw new Error(`Pages deployment is broken:\n  - ${failures.join("\n  - ")}`)
}

console.log("PASS pages deploy")
