#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
while IFS= read -r -d '' file; do tools/luau/luau-compile "$file" >/dev/null; done < <(find src tests -name '*.luau' -print0)
tools/luau/luau-analyze src/shared/Rules.luau tests/Rules.spec.luau
tools/luau/luau-analyze src/shared/Chapter.luau tests/Chapter.spec.luau
tools/luau/luau tests/Rules.spec.luau
tools/luau/luau tests/Chapter.spec.luau
tools/luau/luau-analyze src/shared/Spellbook.luau tests/Spellbook.spec.luau
tools/luau/luau tests/Spellbook.spec.luau
python3 scripts/test_profiles.py
python3 scripts/test_spells.py
tools/rojo/rojo build default.project.json -o build/ELDORIA.rbxlx
python3 scripts/check_place.py
