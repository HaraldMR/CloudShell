#!/usr/bin/env bash
# Write hyprlock background blocks that match the skwd-wall wallpaper on each monitor.
#   Output: ~/.config/hypr/hyprlock/wallpaper.conf (sourced by hyprlock.conf)
# Static images are used as-is, videos get a still frame (ffmpeg). Anything else, or when
# skwd-wall isn't running, falls back to $background_image from matugen (colors.conf).
set -uo pipefail

out="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprlock/wallpaper.conf"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/cloudshell/lock"
config="${XDG_CONFIG_HOME:-$HOME/.config}/cloudshell/config.json"
mkdir -p "$(dirname "$out")" "$cache"

blur=$(jq -r 'if .lock.blur == false then "false" else "true" end' "$config" 2>/dev/null || echo true)
if [[ "$blur" == true ]]; then
  effects="    blur_passes = 2
    blur_size = 1
    brightness = 0.75
    vibrancy = 0.15"
else
  effects="    blur_passes = 0"
fi

block() { # monitor path
  cat <<EOF
background {
    monitor = $1
    path = $2
    color = rgba(181818FF)
$effects
}

EOF
}

# A still image hyprlock can show for this wallpaper, or empty
still_for() { # output type path
  local output=$1 type=$2 path=$3
  [[ -f "$path" ]] || return 0
  case "${path,,}" in
  *.png | *.jpg | *.jpeg | *.webp | *.bmp)
    [[ "$type" != "video" ]] && {
      echo "$path"
      return 0
    }
    ;;
  esac
  command -v ffmpeg >/dev/null || return 0
  local frame="$cache/$output.png" src="$cache/$output.src"
  if [[ ! -f "$frame" || "$(cat "$src" 2>/dev/null)" != "$path" || "$path" -nt "$frame" ]]; then
    ffmpeg -y -loglevel error -ss 2 -i "$path" -frames:v 1 "$frame" 2>/dev/null ||
      ffmpeg -y -loglevel error -i "$path" -frames:v 1 "$frame" 2>/dev/null || return 0
    echo "$path" >"$src"
  fi
  echo "$frame"
}

tmp=$(mktemp)
written=0
if command -v skwd-helm >/dev/null && json=$(skwd-helm current --json 2>/dev/null); then
  while IFS=$'\t' read -r name type path; do
    [[ -z "$name" ]] && continue
    still=$(still_for "$name" "$type" "$path")
    block "$name" "${still:-\$background_image}" >>"$tmp"
    written=1
  done < <(jq -r '.outputs[]? | select(.connected != false) | [.name, (.type // ""), (.path // .current // "")] | @tsv' <<<"$json")
fi
# Fallback for every monitor (also covers monitors skwd-wall doesn't know about)
((written)) || block "" "\$background_image" >>"$tmp"

mv "$tmp" "$out"
