#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
while IFS= read -r -d '' file; do tools/luau/luau-compile "$file" >/dev/null; done < <(find src tests -name '*.luau' -print0)
tools/luau/luau-analyze src/shared/Rules.luau tests/Rules.spec.luau
tools/luau/luau tests/Rules.spec.luau
python3 scripts/test_profiles.py
tools/rojo/rojo build default.project.json -o build/ELDORIA.rbxlx
python3 scripts/check_place.py
