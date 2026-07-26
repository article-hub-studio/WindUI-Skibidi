// The docs site was never deployed: build.yml only committed dist/main.lua
// back to the repo, so https://article-hub-studio.github.io/WindUI-Skibidi/docs/
//404'd. pages.yml publishes the static export instead. That export doubles as
// the host for every loadstring URL, so a change that drops one of those paths
// from website/public would take the runtime down with it.

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
	check("uses the Pages deploy action", /actions\/deploy-pages@v\d/.test(workflow))
	check("uploads the static export", /actions\/upload-pages-artifact@v\d[\s\S]{0,80}path: website\/out/.test(workflow))
	check("requests the Pages OIDC permissions", /pages: write/.test(workflow) && /id-token: write/.test(workflow))
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
