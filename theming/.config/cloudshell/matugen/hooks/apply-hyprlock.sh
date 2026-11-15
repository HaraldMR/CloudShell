#!/usr/bin/env bash
# Keep hyprlock's per-monitor wallpaper in sync with skwd-wall (no-op without cloudshell).
f="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/cloudshell/scripts/lock/wallpaper.sh"
# skwd-wall runs matugen before it records the new wallpaper; wait briefly so `skwd-helm current` is up to date
[[ -x "$f" ]] && (sleep 2; "$f") >/dev/null 2>&1 &
exit 0
