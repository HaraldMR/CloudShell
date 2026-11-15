#!/usr/bin/env bash
# Regenerate colours with matugen.
#   apply.sh [--mode dark|light] [--type scheme-*] [--image PATH]
# Without --image the current skwd-wall wallpaper is used, falling back to theme.fallbackWallpaper.
set -uo pipefail
config="${XDG_CONFIG_HOME:-$HOME/.config}/cloudshell/config.json"
matugen_config="${XDG_CONFIG_HOME:-$HOME/.config}/cloudshell/matugen/config.toml"

mode=$(jq -r '.theme.mode // "dark"' "$config" 2>/dev/null || echo dark)
type=$(jq -r '.theme.scheme // "scheme-content"' "$config" 2>/dev/null || echo scheme-content)
image=""
while (($#)); do
    case "$1" in
    --mode) mode="$2"; shift ;;
    --type) type="$2"; shift ;;
    --image) image="$2"; shift ;;
    esac
    shift
done

command -v matugen >/dev/null || { echo "matugen not installed" >&2; exit 1; }

if [[ -z "$image" ]] && command -v skwd-helm >/dev/null; then
    image=$(skwd-helm current --json 2>/dev/null | jq -r '
        [.. | objects | (.thumb // .path // .current // empty) | strings | select(test("\\.(png|jpe?g|webp|bmp|gif)$"; "i"))] | first // empty' 2>/dev/null)
fi
[[ -z "$image" ]] && image=$(jq -r '.theme.fallbackWallpaper // empty' "$config" 2>/dev/null)
image="${image/#\~/$HOME}"
[[ -f "$image" ]] || { echo "No wallpaper image to generate colours from" >&2; exit 1; }

matugen -c "$matugen_config" image "$image" -m "$mode" -t "$type" --prefer saturation -q
