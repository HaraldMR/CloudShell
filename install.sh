#!/usr/bin/env bash
# Set up these dotfiles on a machine.
#   ./install.sh            packages + links + skwd-wall setup + defaults
#   ./install.sh --links    only create the symlinks (stow)
#   ./install.sh --adopt    like --links, but take over existing files (their content replaces the repo's!)
# Works on Arch/CachyOS (pacman + paru/yay) and Debian/Ubuntu (apt, best effort).
set -euo pipefail
cd "$(dirname "$0")"
repo="$PWD"

mode="${1:-all}"
list() { grep -vE '^\s*(#|$)' "$1" | awk '{print $1}'; }

install_packages() {
    if command -v pacman >/dev/null; then
        sudo pacman -S --needed $(list packages/arch-repo.txt)
        local helper
        helper=$(command -v paru || command -v yay || true)
        if [[ -n "$helper" ]]; then
            "$helper" -S --needed $(list packages/aur.txt)
        else
            echo "!! No AUR helper (paru/yay) found; install these manually: $(list packages/aur.txt | tr '\n' ' ')"
        fi
    elif command -v apt-get >/dev/null; then
        sudo apt-get install -y $(list packages/debian.txt) || true
        echo "!! On Debian/Ubuntu, quickshell, matugen and skwd-wall must be installed separately (see packages/debian.txt)."
        echo "   Cloudshell hides the modules whose programs are missing."
    else
        echo "!! Unknown package manager; see packages/*.txt for what to install."
    fi
}

link() {
    local extra=("$@")
    command -v stow >/dev/null || { echo "!! stow is not installed"; exit 1; }
    mkdir -p ~/.config/quickshell ~/.config/cloudshell ~/.local/bin ~/.local/share/fonts
    # Whole-folder links for the shell itself; per-file links where programs write generated files next to ours
    stow "${extra[@]}" -t ~ cloudshell fonts theming
    stow "${extra[@]}" --no-folding -t ~ hypr kitty fish scripts
    # Machine-specific/generated Hyprland files: create defaults if missing
    (cd hypr-defaults && find . -type f) | while read -r f; do
        [[ -e ~/.config/hypr/"$f" ]] || install -D -m 644 "hypr-defaults/$f" ~/.config/hypr/"$f"
    done
    fc-cache -f >/dev/null 2>&1 || true
}

setup_skwd() {
    command -v skwd-wall-v2 >/dev/null || return 0
    local cfg=~/.config/skwd-wall-v2/config.json
    mkdir -p "$(dirname "$cfg")"
    [[ -f "$cfg" ]] || echo '{}' >"$cfg"
    local tmp
    tmp=$(mktemp)
    jq --arg m "$HOME/.config/cloudshell/matugen/config.toml" '
        .features.matugen = true
        | .theme.engine = "matugen"
        | .theme.authority = "skwd"
        | .theme.policy = "wallpaper"
        | .theme.mode = (.theme.mode // "dark")
        | .theme.scheme = (.theme.scheme // "content")
        | .defaultMatugenConfig = $m' "$cfg" >"$tmp" && mv "$tmp" "$cfg"
    chmod 600 "$cfg"
    systemctl --user daemon-reload
    systemctl --user enable skwd-walld.service
    echo ":: skwd-wall uses matugen with ~/.config/cloudshell/matugen/config.toml; its daemon starts at login"
}

case "$mode" in
--links) link ;;
--adopt) link --adopt ;;
all)
    install_packages
    link
    setup_skwd
    ~/.config/quickshell/cloudshell/scripts/migrate-from-ii.sh || true
    echo
    echo ":: Done. Log out and back in to start Hyprland with cloudshell."
    ;;
*)
    echo "Usage: ./install.sh [--links | --adopt]" >&2
    exit 1
    ;;
esac
