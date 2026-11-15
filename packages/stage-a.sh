#!/usr/bin/env bash
# Stage A of the ii -> cloudshell transition. Safe to re-run.
# - Keeps every real package the ii meta packages pulled in (marks them explicit),
#   so nothing (hyprland, kitty, fish, dolphin, ...) gets removed as an orphan.
# - Removes only the ii *meta* packages, which contain no files.
# - Swaps ii-specific builds for repo/AUR equivalents.
# - Installs everything cloudshell needs.
# ii keeps working afterwards (it runs on the repo quickshell).
# Rollback for quickshell: sudo pacman -U ~/dotfiles-backup/illogical-impulse-quickshell-git-*.pkg.tar.zst
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"

list() { grep -vE '^\s*(#|$)' "$1" | awk '{print $1}'; }

metas=(
  illogical-impulse-audio illogical-impulse-backlight illogical-impulse-basic
  illogical-impulse-fonts-themes illogical-impulse-hyprland illogical-impulse-kde
  illogical-impulse-portal illogical-impulse-python illogical-impulse-screencapture
  illogical-impulse-toolkit illogical-impulse-widgets
)
swapped_out=(
  illogical-impulse-quickshell-git
  ttf-material-symbols-variable-git
  adw-gtk-theme-git
  illogical-impulse-bibata-modern-classic-bin
)

echo ":: Marking everything the ii packages depend on as explicitly installed"
deps=()
for p in "${metas[@]}" illogical-impulse-quickshell-git illogical-impulse-microtex-git; do
  pacman -Qq "$p" &>/dev/null || continue
  while read -r d; do
    d="${d%%[<>=]*}"
    [[ -n "$d" && "$d" != None ]] && pacman -Qq "$d" &>/dev/null && deps+=("$d")
  done < <(pacman -Qi "$p" | awk -F': *' '/^Depends On/{print $2}' | tr -s ' ' '\n')
done
deps=($(printf '%s\n' "${deps[@]}" | sort -u | grep -vxF -f <(printf '%s\n' "${swapped_out[@]}")))
((${#deps[@]})) && sudo pacman -D --asexplicit "${deps[@]}"

echo ":: Removing ii meta packages (no files, just dependency lists)"
installed_metas=($(pacman -Qq "${metas[@]}" 2>/dev/null || true))
((${#installed_metas[@]})) && sudo pacman -R --noconfirm "${installed_metas[@]}"

echo ":: Swapping ii builds for repo/AUR equivalents"
installed_swaps=($(pacman -Qq "${swapped_out[@]}" 2>/dev/null || true))
((${#installed_swaps[@]})) && sudo pacman -Rdd --noconfirm "${installed_swaps[@]}"

echo ":: Installing repo packages"
sudo pacman -S --needed --noconfirm $(list "$here/arch-repo.txt")

echo ":: Installing AUR packages"
helper=$(command -v paru || command -v yay)
"$helper" -S --needed --noconfirm $(list "$here/aur.txt")

systemctl --user daemon-reload
fc-cache -f >/dev/null
echo ":: Done. Check that ii still starts:  qs -c ii"
