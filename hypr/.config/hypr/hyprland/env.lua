-- Environment variables

-- Wayland
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Flatpak apps in launchers
local xdgDataDirs = os.getenv("XDG_DATA_DIRS") or ""
hl.env(
	"XDG_DATA_DIRS",
	HOME .. "/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share:" .. xdgDataDirs
)

-- Cursor (also makes XWayland apps like Steam use the right size)
hl.env("XCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")

-- Qt / KDE theming
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "kde")
hl.env("XDG_MENU_PREFIX", "plasma-")
