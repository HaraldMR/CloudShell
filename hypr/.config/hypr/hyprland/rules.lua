-- Window, workspace and layer rules

local function windowRule(match, props)
	props.match = match
	hl.window_rule(props)
end

local function layerRule(namespace, props)
	props.match = { namespace = namespace }
	hl.layer_rule(props)
end

---------------------------------------------------------------- Windows

-- No blur behind windows
windowRule({ class = ".*" }, { no_blur = true })

-- No shadow for tiled windows
windowRule({ float = 0 }, { no_shadow = true })

-- File pickers and dialogs: float, centred
for _, title in ipairs({
	"^(Open File)(.*)$",
	"^(Select a File)(.*)$",
	"^(Open Folder)(.*)$",
	"^(Save As)(.*)$",
	"^(Library)(.*)$",
	"^(File Upload)(.*)$",
	"^(.*)(wants to save)$",
	"^(.*)(wants to open)$",
}) do
	windowRule({ title = title }, { float = true, center = true })
end
windowRule(
	{ class = "org.freedesktop.impl.portal.desktop.kde" },
	{ float = true, size = { "(monitor_w*0.60)", "(monitor_h*0.65)" } }
)

-- Small settings windows: float, centred
for _, class in ipairs({ "^(pavucontrol)$", "^(org.pulseaudio.pavucontrol)$", "^(nm-connection-editor)$" }) do
	windowRule({ class = class }, { float = true, center = true, size = { "(monitor_w*0.45)", "(monitor_h*0.45)" } })
end
windowRule({ class = ".*plasmawindowed.*" }, { float = true })
windowRule({ class = "kcm_.*" }, { float = true })
windowRule({ class = ".*bluedevilwizard" }, { float = true })
windowRule({ title = "^(Cloudshell Settings)$" }, {
	no_blur = false, -- the shell blurs it itself in liquid glass mode
	float = true,
	center = true,
	size = { "(monitor_w*0.45)", "(monitor_h*0.65)" },
})

-- Dolphin's copy progress window
windowRule({ title = "^(Copying — Dolphin)$" }, { move = { 40, 80 } })

-- Picture-in-Picture: small, pinned, bottom right
windowRule({ title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" }, {
	float = true,
	pin = true,
	keep_aspect_ratio = true,
	move = { "(monitor_w*0.73)", "(monitor_h*0.72)" },
	size = { "(monitor_w*0.25)", "(monitor_h*0.25)" },
})

-- Screen sharing indicator: pinned, bottom centre
windowRule({ title = ".*is sharing (a window|your screen).*" }, {
	float = true,
	pin = true,
	move = { "(monitor_w*.5-window_w*.5)", "(monitor_h-window_h-12)" },
})

-- Fullscreen viewers
windowRule({ class = "^(mpv)$" }, { fullscreen = true })
windowRule({ class = "^(swayimg.*)$" }, { fullscreen = true })

-- Apps on fixed workspaces
windowRule({ class = "steam" }, { workspace = 1 })
windowRule({ class = "^(discord)$" }, { workspace = 10 })
windowRule({ class = "^(vesktop)$" }, { workspace = 10 })

-- Steam windows
windowRule({ class = "^(steam)$", title = "^(Friends List)$" }, {
	float = true,
	center = true,
	size = { "(monitor_w*0.2)", "(monitor_h*0.7)" },
})
windowRule({ class = "^(steam)$", title = "^(Steam Settings)$" }, {
	float = true,
	center = true,
	size = { "(monitor_w*0.4)", "(monitor_h*0.7)" },
})

-- Untitled floating windows (tooltips, drag icons) shouldn't take focus
windowRule({ class = "()", title = "()", float = 1 }, { no_focus = true })

-- Games: allow tearing
windowRule({ title = ".*\\.exe" }, { immediate = true })
windowRule({ title = ".*minecraft.*" }, { immediate = true })
windowRule({ class = "^(steam_app).*" }, { immediate = true })

---------------------------------------------------------------- Workspaces
-- Which monitor each workspace lives on is managed by hyprmoncfg (hyprmoncfg-monitors.lua)

hl.workspace_rule({ workspace = "special:special", gaps_out = 30 })

---------------------------------------------------------------- Layers

layerRule(".*", { xray = true })
layerRule("hyprpicker", { no_anim = true })
layerRule("noanim", { no_anim = true })

-- Fallback tools used when the shell isn't running (fuzzel, wlogout)
layerRule("launcher", { blur = true, ignore_alpha = 0.5 })
layerRule("logout_dialog", { blur = true })
layerRule("gtk-layer-shell", { blur = true, ignore_alpha = 0 })
layerRule("gtk4-layer-shell", { no_anim = true })

-- Cloudshell
-- Blur for the liquid glass look is requested by the shell itself (ext-background-effect), so no
-- blanket blur rules here; `ignore_alpha` would stop that blur on see-through surfaces.
-- Glass blurs what's actually behind the shell (windows too), not just the wallpaper
layerRule("quickshell:.*", { xray = false })
layerRule("cloudshell:.*", { xray = false })
layerRule("quickshell:bar", { animation = "slide" })
layerRule("quickshell:popup", { xray = false })
layerRule("quickshell:notificationPopup", { animation = "fade" })
layerRule("quickshell:reloadPopup", { animation = "slide" })
layerRule("quickshell:overview", { no_anim = true })
layerRule("quickshell:polkit", { no_anim = true })
layerRule("quickshell:regionSelector", { no_anim = true })
layerRule("quickshell:session", { blur = true, xray = true, no_anim = true, ignore_alpha = 0 }) -- frosted power menu
-- Wallpaper drawn by the shell when skwd-wall isn't running
layerRule("cloudshell:background", { no_anim = true, xray = false })
-- These animate themselves
layerRule("cloudshell:dropdown", { no_anim = true })
layerRule("cloudshell:calendar", { no_anim = true })
layerRule("cloudshell:gameBar", { no_anim = true })
