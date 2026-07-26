#!/bin/bash
# Copies the files GitHub Pages serves alongside the docs site into
# website/public. These used to be updated by hand and drifted out of sync
# with dist/ and src/, so run this after `npm run build`.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PUBLIC="$ROOT/website/public"

P='\033[38;2;48;255;106m'
E='\033[38;2;255;74;50m'
R='\033[0m'

if [ ! -f "$ROOT/dist/main.lua" ]; then
    echo -e "${E}[ × ]${R} dist/main.lua is missing - run 'npm run build' first"
    exit 1
fi

copy() {
    local src="$1" dest="$2"
    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
    echo -e "${P}[ > ]${R} ${dest#$ROOT/}"
}

# The loader and the direct-build URL both serve the bundled library.
copy "$ROOT/dist/main.lua" "$PUBLIC/dist/main.lua"
copy "$ROOT/dist/main.lua" "$PUBLIC/main.lua"

# The canonical entry point: loadstring(HttpGet(".../loader.lua")).
copy "$ROOT/loader.lua" "$PUBLIC/loader.lua"

# The docs read the theme list from here when the repo checkout is unavailable.
copy "$ROOT/src/themes/Init.lua" "$PUBLIC/src/themes/Init.lua"

copy "$ROOT/main_example.lua" "$PUBLIC/main_example.lua"

echo -e "${P}[ ✓ ]${R} Pages assets synced"
