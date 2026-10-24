#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p tools/luau tools/rojo
fetch() {
    local url="$1" checksum="$2" output="$3" destination="$4"
    if [[ ! -f "$output" ]] || ! printf '%s  %s\n' "$checksum" "$output" | sha256sum --check --status; then
        curl --fail --location --silent --show-error --retry 2 "$url" -o "$output"
    fi
    printf '%s  %s\n' "$checksum" "$output" | sha256sum --check
    python3 -m zipfile -e "$output" "$destination"
}
fetch https://github.com/luau-lang/luau/releases/download/0.726/luau-ubuntu.zip fb4f90d5ee0a72aaf88fddc6d72421f0e7904e4f1b9d6bf1fa30467f012bb23e tools/luau.zip tools/luau
fetch https://github.com/rojo-rbx/rojo/releases/download/v7.6.1/rojo-7.6.1-linux-x86_64.zip a9542a713036897fdbd0173e7a105ea409658333133c949025fcb6f1a7ca909d tools/rojo.zip tools/rojo
chmod +x tools/luau/luau tools/luau/luau-compile tools/luau/luau-analyze tools/rojo/rojo
