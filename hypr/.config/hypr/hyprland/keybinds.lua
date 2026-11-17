-- Keybinds
-- Shell actions go through Hyprland global shortcuts (quickshell:<name>), which cloudshell registers.
-- `description` shows up in `hyprctl binds`.

local qsScripts = "$HOME/.config/quickshell/$qsConfig/scripts"
local hyprScripts = "$HOME/.config/hypr/hyprland/scripts"
local qsIpcCall = "qs -c $qsConfig ipc call"
-- Succeeds while the shell runs; the fallback binds below only act when it doesn't
local qsIsAlive = qsIpcCall .. " TEST_ALIVE"

local function shell(name)
	return hl.dsp.global("quickshell:" .. name)
end

---------------------------------------------------------------- Shell

-- Tap Super: search + window overview
hl.bind("SUPER + SUPER_L", shell("searchToggleRelease"), { release = true, description = "Shell: Search" })
hl.bind("SUPER + SUPER_R", shell("searchToggleRelease"), { release = true })
-- Scrolling doesn't cancel the Super release binds above, so cancel the search toggle explicitly
for _, mods in ipairs({
	"SUPER",
	"CTRL + SUPER",
	"SUPER + SHIFT",
	"SUPER + ALT",
	"CTRL + SUPER + SHIFT",
	"CTRL + SUPER + ALT",
	"SUPER + SHIFT + ALT",
	"CTRL + SUPER + SHIFT + ALT",
}) do
	for _, wheel in ipairs({ "mouse_up", "mouse_down", "mouse_left", "mouse_right" }) do
		hl.bind(mods .. " + " .. wheel, shell("searchToggleReleaseInterrupt"), { non_consuming = true })
	end
end

-- Hold Super: workspace numbers in the bar
for _, key in ipairs({ "SUPER_L", "SUPER_R" }) do
	hl.bind(key, shell("workspaceNumber"), { ignore_mods = true, transparent = true })
	hl.bind(key, shell("workspaceNumber"), { ignore_mods = true, transparent = true, release = true })
end

hl.bind("SUPER + Tab", shell("overviewWorkspacesToggle"), { description = "Shell: Toggle overview" })
hl.bind("SUPER + V", shell("overviewClipboardToggle"), { description = "Shell: Clipboard history" })
hl.bind("SUPER + Period", shell("overviewEmojiToggle"), { description = "Shell: Emoji picker" })
hl.bind("SUPER + N", shell("dropdownToggle"), { description = "Shell: Toggle quick settings" })
hl.bind("SUPER + M", shell("mediaControlsToggle"), { description = "Shell: Toggle media controls" })
hl.bind("SUPER + G", shell("gameBarToggle"), { description = "Shell: Toggle game bar" })
hl.bind("SUPER + J", shell("barToggle"), { description = "Shell: Toggle bar" })
hl.bind("CTRL + ALT + Delete", shell("sessionToggle"), { description = "Shell: Power menu" })
hl.bind("CTRL + SUPER + T", shell("wallpaperSelectorToggle"), { description = "Shell: Change wallpaper" })
hl.bind(
	"CTRL + SUPER + R",
	hl.dsp.exec_cmd("killall qs quickshell; qs -c $qsConfig &"),
	{ description = "Shell: Restart" }
)

-- Fallbacks for when the shell isn't running
hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd(qsIsAlive .. " || pkill fuzzel || fuzzel"), { release = true })
hl.bind("SUPER + SUPER_R", hl.dsp.exec_cmd(qsIsAlive .. " || pkill fuzzel || fuzzel"), { release = true })
hl.bind(
	"SUPER + V",
	hl.dsp.exec_cmd(
		qsIsAlive .. " || pkill fuzzel || cliphist list | fuzzel --match-mode fzf --dmenu | cliphist decode | wl-copy"
	)
)
hl.bind("SUPER + Period", hl.dsp.exec_cmd(qsIsAlive .. " || pkill fuzzel || " .. hyprScripts .. "/fuzzel-emoji.sh copy"))
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd(qsIsAlive .. " || pkill wlogout || wlogout -p layer-shell"))

---------------------------------------------------------------- Screenshots and recording

-- Region screenshot / OCR (shell region selector)
hl.bind("SUPER + SHIFT + S", shell("regionScreenshot"), { description = "Utilities: Screenshot region" })
hl.bind("SUPER + SHIFT + X", shell("regionOcr"), { description = "Utilities: Copy text from region (OCR)" })
-- Fallbacks for when the shell isn't running
hl.bind(
	"SUPER + SHIFT + S",
	hl.dsp.exec_cmd(qsIsAlive .. " || pidof slurp || hyprshot --freeze --clipboard-only --mode region --silent")
)
hl.bind(
	"SUPER + SHIFT + X",
	hl.dsp.exec_cmd(
		qsIsAlive
			.. ' || pidof slurp || grim -g "$(slurp $SLURP_ARGS)" "/tmp/ocr_image.png"'
			.. ' && tesseract "/tmp/ocr_image.png" stdout -l $(tesseract --list-langs | awk \'NR>1{print $1}\' | paste -sd+)'
			.. ' | wl-copy && rm "/tmp/ocr_image.png"'
	)
)

-- Full screenshot of the current monitor: saved to Pictures/Screenshots and copied
local grimMonitor = "grim -o \"$(hyprctl activeworkspace -j | jq -r '.monitor')\""
hl.bind(
	"Print",
	hl.dsp.exec_cmd(
		"mkdir -p $(xdg-user-dir PICTURES)/Screenshots && "
			.. grimMonitor
			.. " $(xdg-user-dir PICTURES)/Screenshots/Screenshot_\"$(date '+%Y-%m-%d_%H.%M.%S')\".png"
	),
	{ locked = true, non_consuming = true, description = "Utilities: Screenshot (save + copy)" }
)
hl.bind("Print", hl.dsp.exec_cmd(grimMonitor .. " - | wl-copy"), { locked = true, non_consuming = true })

-- Screen recording: press again to stop
hl.bind(
	"CTRL + Print",
	hl.dsp.exec_cmd(qsScripts .. "/videos/record.sh --fullscreen --sound"),
	{ locked = true, description = "Utilities: Record screen with sound (again to stop)" }
)
hl.bind(
	"CTRL + ALT + Print",
	hl.dsp.exec_cmd(qsScripts .. "/videos/record.sh --fullscreen"),
	{ locked = true, description = "Utilities: Record screen (again to stop)" }
)

---------------------------------------------------------------- Volume, brightness, media

hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+ -l 1.5"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd(qsIpcCall .. " brightness increment || brightnessctl s 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd(qsIpcCall .. " brightness decrement || brightnessctl s 5%-"),
	{ locked = true, repeating = true }
)

local muteOutput = hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle")
local muteMic = hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle")
hl.bind("XF86AudioMute", muteOutput, { locked = true })
hl.bind("SUPER + SHIFT + M", muteOutput, { locked = true, description = "Media: Toggle mute" })
hl.bind("XF86AudioMicMute", muteMic, { locked = true })
hl.bind("ALT + XF86AudioMute", muteMic, { locked = true })
hl.bind("SUPER + ALT + M", muteMic, { locked = true, description = "Media: Toggle mic" })

-- "Next" skips to the end of the track when the player has no next
local mediaNext = hl.dsp.exec_cmd(
	'playerctl next || playerctl position `bc <<< "100 * $(playerctl metadata mpris:length) / 1000000 / 100"`'
)
local mediaPrevious = hl.dsp.exec_cmd("playerctl previous")
local mediaPlayPause = hl.dsp.exec_cmd("playerctl play-pause")
hl.bind("XF86AudioNext", mediaNext, { locked = true })
hl.bind("XF86AudioPrev", mediaPrevious, { locked = true })
hl.bind("XF86AudioPlay", mediaPlayPause, { locked = true })
hl.bind("XF86AudioPause", mediaPlayPause, { locked = true })
hl.bind("SUPER + SHIFT + N", mediaNext, { locked = true, description = "Media: Next track" })
hl.bind("SUPER + SHIFT + B", mediaPrevious, { locked = true, description = "Media: Previous track" })
hl.bind("SUPER + SHIFT + P", mediaPlayPause, { locked = true, description = "Media: Play/pause" })
hl.bind("SUPER + SHIFT + ALT + mouse:276", mediaNext)
hl.bind("SUPER + SHIFT + ALT + mouse:275", mediaPrevious)

---------------------------------------------------------------- Windows

hl.bind("SUPER + Q", hl.dsp.window.close(), { description = "Window: Close" })
hl.bind("SUPER + SHIFT + ALT + Q", hl.dsp.exec_cmd("hyprctl kill"), { description = "Window: Force kill (click a window)" })

-- Mouse: move / resize
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Window: Move" })
hl.bind("SUPER + mouse:274", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Window: Resize" })

-- Focus and move in a direction
for key, dir in pairs({ Left = "l", Right = "r", Up = "u", Down = "d" }) do
	hl.bind("SUPER + " .. key, hl.dsp.focus({ direction = dir }), { description = "Window: Focus " .. key })
	hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ direction = dir }), { description = "Window: Move " .. key })
end
hl.bind("SUPER + BracketLeft", hl.dsp.focus({ direction = "l" }))
hl.bind("SUPER + BracketRight", hl.dsp.focus({ direction = "r" }))

-- Split ratio
hl.bind("SUPER + Semicolon", hl.dsp.layout("splitratio -0.1"), { repeating = true })
hl.bind("SUPER + Apostrophe", hl.dsp.layout("splitratio +0.1"), { repeating = true })

-- State
hl.bind("SUPER + ALT + Space", hl.dsp.window.float({ action = "toggle" }), { description = "Window: Float/Tile" })
hl.bind(
	"SUPER + D",
	hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }),
	{ description = "Window: Maximize" }
)
hl.bind(
	"SUPER + F",
	hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }),
	{ description = "Window: Fullscreen" }
)
hl.bind(
	"SUPER + ALT + F",
	hl.dsp.window.fullscreen_state({ internal = 0, client = 3, action = "toggle" }),
	{ description = "Window: Fake fullscreen (app thinks it is)" }
)
hl.bind("SUPER + P", hl.dsp.window.pin(), { description = "Window: Pin" })

---------------------------------------------------------------- Workspaces

-- Number row and keypad keycodes for workspaces 1..10 (raw codes work on any keyboard layout, check with `wev`)
local numberKeys = { 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 }
local numpadKeys = { 87, 88, 89, 83, 84, 85, 79, 80, 81, 90 }

for i = 1, 10 do
	local focus = function()
		hl.dispatch(hl.dsp.focus({ workspace = workspace_in_group(i) }))
	end
	local send = function()
		hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(i), follow = false }))
	end
	hl.bind("SUPER + " .. (i % 10), focus, { description = "Workspace: Focus " .. i })
	hl.bind("SUPER + code:" .. numberKeys[i], focus)
	hl.bind("SUPER + code:" .. numpadKeys[i], focus)
	hl.bind("SUPER + ALT + " .. (i % 10), send, { description = "Window: Send to workspace " .. i })
	hl.bind("SUPER + ALT + code:" .. numpadKeys[i], send)
end

-- Focus neighbouring workspaces
hl.bind("CTRL + SUPER + Left", hl.dsp.focus({ workspace = "r-1" }), { description = "Workspace: Focus left" })
hl.bind("CTRL + SUPER + Right", hl.dsp.focus({ workspace = "r+1" }), { description = "Workspace: Focus right" })
hl.bind("CTRL + SUPER + ALT + Left", hl.dsp.focus({ workspace = "m-1" }))
hl.bind("CTRL + SUPER + ALT + Right", hl.dsp.focus({ workspace = "m+1" }))
hl.bind("SUPER + Page_Down", hl.dsp.focus({ workspace = "r+1" }))
hl.bind("SUPER + Page_Up", hl.dsp.focus({ workspace = "r-1" }))
hl.bind("CTRL + SUPER + Page_Down", hl.dsp.focus({ workspace = "r+1" }))
hl.bind("CTRL + SUPER + Page_Up", hl.dsp.focus({ workspace = "r-1" }))
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "+1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "-1" }))
hl.bind("CTRL + SUPER + mouse_down", hl.dsp.focus({ workspace = "r+1" }))
hl.bind("CTRL + SUPER + mouse_up", hl.dsp.focus({ workspace = "r-1" }))
hl.bind("CTRL + SUPER + BracketLeft", hl.dsp.focus({ workspace = "-1" }))
hl.bind("CTRL + SUPER + BracketRight", hl.dsp.focus({ workspace = "+1" }))
hl.bind("CTRL + SUPER + Up", hl.dsp.focus({ workspace = "r-5" }))
hl.bind("CTRL + SUPER + Down", hl.dsp.focus({ workspace = "r+5" }))

-- Send the window to neighbouring workspaces
hl.bind(
	"SUPER + SHIFT + Page_Up",
	hl.dsp.window.move({ workspace = "r-1" }),
	{ description = "Window: Send to workspace left" }
)
hl.bind(
	"SUPER + SHIFT + Page_Down",
	hl.dsp.window.move({ workspace = "r+1" }),
	{ description = "Window: Send to workspace right" }
)
hl.bind("SUPER + ALT + Page_Up", hl.dsp.window.move({ workspace = "r-1" }))
hl.bind("SUPER + ALT + Page_Down", hl.dsp.window.move({ workspace = "r+1" }))
hl.bind("CTRL + SUPER + SHIFT + Left", hl.dsp.window.move({ workspace = "r-1" }))
hl.bind("CTRL + SUPER + SHIFT + Right", hl.dsp.window.move({ workspace = "r+1" }))
hl.bind("SUPER + SHIFT + mouse_up", hl.dsp.window.move({ workspace = "r-1" }))
hl.bind("SUPER + SHIFT + mouse_down", hl.dsp.window.move({ workspace = "r+1" }))
hl.bind("SUPER + ALT + mouse_up", hl.dsp.window.move({ workspace = "r-1" }))
hl.bind("SUPER + ALT + mouse_down", hl.dsp.window.move({ workspace = "r+1" }))

-- Scratchpad
hl.bind("SUPER + S", hl.dsp.workspace.toggle_special("special"), { description = "Workspace: Toggle scratchpad" })
hl.bind("CTRL + SUPER + S", hl.dsp.workspace.toggle_special("special"))
hl.bind("SUPER + mouse:275", hl.dsp.workspace.toggle_special("special"))
hl.bind(
	"SUPER + ALT + S",
	hl.dsp.window.move({ workspace = "special:special", follow = false }),
	{ description = "Window: Send to scratchpad" }
)

---------------------------------------------------------------- Monitors

local dp3Disabled = false
hl.bind("SUPER + SHIFT + G", function()
	dp3Disabled = not dp3Disabled
	hl.monitor({ output = "DP-3", disabled = dp3Disabled })
end, { description = "Monitor: Toggle DP-3 on/off" })

---------------------------------------------------------------- Virtual machines

-- Super+Alt+F1 disables all other keybinds (so they go to the VM) and back
hl.define_submap("virtual-machine", function()
	hl.bind("SUPER + ALT + F1", function()
		local submap = hl.get_current_submap()
		if submap == "virtual-machine" then
			hl.dispatch(hl.dsp.exec_cmd("notify-send 'Exited Virtual Machine submap' 'Keybinds re-enabled' -a 'Hyprland'"))
			hl.dispatch(hl.dsp.submap("reset"))
		elseif submap == "" then
			hl.dispatch(
				hl.dsp.exec_cmd(
					"notify-send 'Entered Virtual Machine submap' 'Keybinds disabled. Hit SUPER+ALT+F1 to escape' -a 'Hyprland'"
				)
			)
			hl.dispatch(hl.dsp.submap("virtual-machine"))
		end
	end, { submap_universal = true })
end)

---------------------------------------------------------------- Session

hl.bind("SUPER + L", hl.dsp.exec_cmd("loginctl lock-session"), { description = "Session: Lock" })
hl.bind(
	"SUPER + SHIFT + L",
	hl.dsp.exec_cmd("systemctl suspend || loginctl suspend"),
	{ locked = true, description = "Session: Sleep" }
)
hl.bind(
	"CTRL + SHIFT + ALT + SUPER + Delete",
	hl.dsp.exec_cmd("systemctl poweroff || loginctl poweroff"),
	{ description = "Session: Shut down" }
)

---------------------------------------------------------------- Apps

-- Reads the variable when the key is pressed, so local.lua can override it
local function launch(variable)
	return function()
		hl.dispatch(hl.dsp.exec_cmd(_G[variable]))
	end
end

hl.bind("SUPER + Return", launch("terminal"), { description = "App: Terminal" })
hl.bind("SUPER + E", launch("fileManager"), { description = "App: File manager" })
hl.bind("SUPER + C", launch("codeEditor"), { description = "App: Code editor" })
hl.bind("SUPER + X", launch("textEditor"), { description = "App: Text editor" })
hl.bind("SUPER + W", launch("browser"), { description = "App: Browser" })
hl.bind("SUPER + SHIFT + W", launch("privateBrowser"), { description = "App: Private browser" })
hl.bind("SUPER + Y", launch("musicPlayer"), { description = "App: Music" })
hl.bind("SUPER + I", launch("settingsApp"), { description = "App: Settings" })
hl.bind("CTRL + SUPER + V", launch("volumeMixer"), { description = "App: Volume mixer" })
hl.bind("CTRL + SHIFT + Escape", launch("taskManager"), { description = "App: Task manager" })
