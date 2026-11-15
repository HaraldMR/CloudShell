#!/usr/bin/env bash
# Switch GTK between light and dark to match the generated palette.
colors="${XDG_STATE_HOME:-$HOME/.local/state}/cloudshell/colors.json"
command -v gsettings >/dev/null || exit 0
[[ -f "$colors" ]] || exit 0
bg=$(jq -r '.background' "$colors" | tr -d '#')
lum=$(( (16#${bg:0:2} * 299 + 16#${bg:2:2} * 587 + 16#${bg:4:2} * 114) / 1000 ))
if (( lum < 128 )); then
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark
    gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark
else
    gsettings set org.gnome.desktop.interface color-scheme prefer-light
    gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3
fi
