const RELEASES_API =
    "https://api.github.com/repos/article-hub-studio/WindUI-Skibidi/releases/latest";

/**
 * Used when neither the GitHub API nor the local package.json can be read.
 * Every release is tagged with the package.json version, so this is only ever
 * a last resort.
 */
const UNKNOWN_VERSION = "latest";

let cached: string | undefined;

/** Reads the version the next release will be tagged with, from the repo root. */
function readPackageVersion(): string | undefined {
    try {
        // eval'd so the bundler does not pull node builtins into the client
        // graph - this module is reached from an MDX page. Same trick as getThemes.
        const req = eval("require");
        const fs = req("fs");
        const path = req("path");

        // The docs live in <repo>/website, the library manifest at <repo>/package.json.
        const candidates = [
            path.resolve(process.cwd(), "..", "package.json"),
            path.resolve(process.cwd(), "package.json"),
        ];

        for (const candidate of candidates) {
            try {
                const parsed = JSON.parse(fs.readFileSync(candidate, "utf8")) as {
                    name?: string;
                    version?: string;
                };
                if (parsed.name === "windui" && parsed.version) {
                    return parsed.version;
                }
            } catch {
                // Missing or unreadable - try the next candidate.
            }
        }
    } catch {
        // No filesystem access (client bundle) - fall through.
    }

    return undefined;
}

/** A build must not sit on a hung socket; getThemes uses the same budget. */
const FETCH_TIMEOUT_MS = 5000;

async function fetchLatestTag(): Promise<string | undefined> {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);

    try {
        const res = await fetch(RELEASES_API, {
            headers: {
                Accept: "application/vnd.github.v3+json",
                "User-Agent": "windui-skibidi-docs",
                // Lets CI dodge the 60 requests/hour unauthenticated rate limit.
                ...(process.env.GITHUB_TOKEN
                    ? { Authorization: `Bearer ${process.env.GITHUB_TOKEN}` }
                    : {}),
            },
            signal: controller.signal,
            next: { revalidate: 3600 },
        });

        if (!res.ok) return undefined;

        const data = (await res.json()) as { tag_name?: string };
        return data.tag_name || undefined;
    } catch {
        // Offline, rate limited, timed out, or the API is down - the docs
        // still have to build.
        return undefined;
    } finally {
        clearTimeout(timeout);
    }
}

/**
 * Returns the tag of the newest published release.
 *
 * The docs are statically exported, so this runs at build time and must never
 * throw: a rate-limited or unreachable GitHub API used to fail the whole
 * export, taking every page down with it.
 */
export async function getLatestVersion(): Promise<string> {
    if (cached) return cached;

    const version =
        process.env.NEXT_PUBLIC_WINDUI_VERSION ||
        (await fetchLatestTag()) ||
        readPackageVersion() ||
        UNKNOWN_VERSION;

    cached = version;
    return version;
}
