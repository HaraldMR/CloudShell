#!/usr/bin/env bash
# Stage B: remove what only ii (end-4 dots) needed. Run once you've settled on cloudshell.
# ii's config folder (~/.config/quickshell/ii) is kept as an archive; delete it yourself if you want.
# Shows the list and asks before removing anything.
set -euo pipefail

# Packages nothing in cloudshell or the Hyprland config uses
candidates=(
  illogical-impulse-microtex-git tinyxml2 gtkmm3 gtksourceviewmm cairomm
  uv songrec translate-shell kdialog go-yq ydotool wtype
  otf-space-grotesk ttf-readex-pro ttf-rubik-vf ttf-twemoji
  kirigami syntax-highlighting
)
installed=()
for p in "${candidates[@]}"; do pacman -Qq "$p" &>/dev/null && installed+=("$p"); done

echo "These packages were only needed by ii:"
printf '  %s\n' "${installed[@]}"
echo
echo "Packages that something else still needs will be skipped by pacman (it will tell you)."
read -rp "Remove them? [y/N] " ok
if [[ "$ok" == [yY] ]]; then
  systemctl --user disable --now ydotool.service 2>/dev/null || true
  # Remove one by one so a still-required package doesn't abort the rest
  for p in "${installed[@]}"; do sudo pacman -Rns --noconfirm "$p" 2>/dev/null || echo "  kept $p (still required)"; done
fi

echo
read -rp "Delete ii's Python venv (~/.local/state/quickshell/.venv, ~330 MB) and its hand-installed fonts? [y/N] " ok
if [[ "$ok" == [yY] ]]; then
  rm -rf ~/.local/state/quickshell/.venv
  rm -rf ~/.local/share/fonts/illogical-impulse-*
  fc-cache -f >/dev/null
fi

echo
echo "Remaining orphans (review before removing with: sudo pacman -Rns \$(pacman -Qdtq)):"
pacman -Qdtq || echo "  none"
