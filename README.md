# dotfiles

Personal desktop setup: Hyprland + **cloudshell** (a Quickshell config), themed from the wallpaper.
Managed with GNU stow, so every folder at the top level is a "package" that gets symlinked into `~`.

| Package | What it links |
|---|---|
| `cloudshell` | `~/.config/quickshell/cloudshell` – the shell |
| `theming` | `~/.config/cloudshell/matugen` – matugen config + templates (shell, Hyprland, hyprlock, GTK, KDE/Qt, fuzzel) |
| `fonts` | Google Sans Flex (OFL, bundled so no package is needed) |
| `hypr` | `~/.config/hypr`: `hyprland.lua` loads one file per area from `hyprland/` (variables, env, execs, general, animations, rules, keybinds). Generated files stay local: `colors.lua` (matugen, default in `hypr-defaults/`) and `hyprmoncfg-monitors.lua` (monitors + workspace placement) |
| `kitty`, `fish` | terminal + shell config |
| `scripts` | `~/.local/bin`: `switch2-mode` |
| `packages/` | package lists (`arch-repo.txt`, `aur.txt`, `debian.txt`, `flatpak.txt`) and the ii transition scripts |

## New machine

```sh
git clone <this repo> ~/.config/dotfiles
~/.config/dotfiles/install.sh           # packages, links, skwd-wall setup, imports ii settings if present
```

`./install.sh --links` only (re)creates the symlinks. Everything installs from the official repos or the AUR
(`-bin` packages), so a normal `cachy-update` keeps it all up to date.

## Which Quickshell config runs

`qsConfig` in `hypr/hyprland/variables.lua` (cloudshell). Shell keybinds dispatch Hyprland global shortcuts
(`quickshell:<name>`) that cloudshell registers. ii (end-4) was retired on 2026-11-15.

## How cloudshell is put together

```
cloudshell/
├─ shell.qml            loads each module if enabled ("auto" = only when its programs are installed)
├─ Shortcuts.qml        global shortcuts (quickshell:<name>) and IPC targets used by the Hyprland binds
├─ settings.qml         `qs -p settings.qml` forwards to the in-shell settings window
├─ core/                Config (~/.config/cloudshell/config.json), Appearance (Material 3 tokens), Persistent state
├─ services/            Audio, Network, Notifications, Theme, Deps (program detection), Wallpaper (skwd-wall), ...
├─ widgets/             Material 3 widgets (ported from end-4's ii)
├─ modules/             bar, calendar, dropdown, notificationPopup, overview, osd, sessionScreen, polkit,
│                       mediaControls, regionSelector, gameBar, settings
└─ scripts/             record.sh (gpu-screen-recorder), theme/apply.sh (matugen), audio/line-in.sh, hue/, migrate-from-ii.sh
```

Every module and quick toggle checks for the programs it needs (`services/Deps.qml`). On a system without, say,
skwd-wall or matugen, those parts switch themselves off and the rest keeps working. Settings > Modules shows what
is missing and which package provides it.

### Colours

skwd-wall applies the wallpaper and runs matugen with `~/.config/cloudshell/matugen/config.toml`.
Matugen writes `~/.local/state/cloudshell/colors.json` (the shell reloads it live) and themes Hyprland borders,
hyprlock, GTK 3/4 (adw-gtk3) and Qt/KDE apps (`plasma-apply-colorscheme`). Without skwd-wall, set a fallback
wallpaper in Settings > Wallpaper & style and press "Regenerate colours".

### Machine-specific settings

`~/.config/cloudshell/config.json` is not in the repo. It holds per-machine things like the line-in device names,
Hue bridge file, quick-toggle layout and notification rules. `~/.config/hue/bridge.env` (Hue API key) is also
kept out of git; see `cloudshell/.config/quickshell/cloudshell/scripts/hue/hueLight.sh` for its format.

## Leaving ii behind

`packages/stage-a.sh` swapped the end-4 packages for repo/AUR ones without removing anything.
`packages/stage-b.sh` removes what only ii used (packages, venv, installer cache). It asks before every step.

## Formatting

Lua files are formatted with [stylua](https://github.com/JohnnyMorganz/StyLua) using `.stylua.toml`:
`stylua hypr/`
