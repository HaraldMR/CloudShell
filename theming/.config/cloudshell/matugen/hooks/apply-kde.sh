#!/usr/bin/env bash
# Install the generated KDE colour scheme and apply it.
# plasma-apply-colorscheme ignores re-applying the active scheme, so alternate between two names.
set -euo pipefail
src="${XDG_STATE_HOME:-$HOME/.local/state}/cloudshell/kde.colors"
dir="${XDG_DATA_HOME:-$HOME/.local/share}/color-schemes"
[[ -f "$src" ]] || exit 0
command -v plasma-apply-colorscheme >/dev/null || exit 0
mkdir -p "$dir"

current=$(grep -m1 '^ColorScheme=' "${XDG_CONFIG_HOME:-$HOME/.config}/kdeglobals" 2>/dev/null | cut -d= -f2 || true)
next=CloudshellA
[[ "$current" == "CloudshellA" ]] && next=CloudshellB

sed -e "s/^ColorScheme=.*/ColorScheme=$next/" -e "s/^Name=.*/Name=$next/" "$src" >"$dir/$next.colors"
plasma-apply-colorscheme "$next" >/dev/null 2>&1 || true
