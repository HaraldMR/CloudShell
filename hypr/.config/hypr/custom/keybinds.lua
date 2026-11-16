require("hyprland.lib")
require("hyprland.variables")
if is_file_exists(HOME .. "/.config/hypr/custom/variables.lua") then
	require("custom.variables")
end

local qsScripts = "$HOME/.config/quickshell/$qsConfig/scripts"
local hyprScripts = "$HOME/.config/hypr/hyprland/scripts"
local qsIpcCall = "qs -c $qsConfig ipc call"
local qsIsAlive = qsIpcCall .. " TEST_ALIVE"

--# Fullscreen screenshot
local grimhyprctl = "grim -o  \"$(hyprctl activeworkspace -j | jq -r '.monitor')\""
hl.bind(
	"Print",
	hl.dsp.exec_cmd(
		"mkdir -p $(xdg-user-dir PICTURES)/Screenshots && "
			.. grimhyprctl
			.. " $(xdg-user-dir PICTURES)/Screenshots/Screenshot_\"$(date '+%Y-%m-%d_%H.%M.%S')\".png"
	),
	{ locked = true, non_consuming = true, description = "Utilities: Screenshot >> clipboard & file" }
)
hl.bind("Print", hl.dsp.exec_cmd(grimhyprctl .. " - | wl-copy"), { locked = true, non_consuming = true })

hl.bind("CTRL + ALT + Print", hl.dsp.exec_cmd(qsScripts .. "/videos/record.sh --fullscreen"), { locked = true })
hl.bind(
	"CTRL + Print",
	hl.dsp.exec_cmd(qsScripts .. "/videos/record.sh --fullscreen --sound"),
	{ locked = true, description = "Utilities: Record screen (with sound)" }
)

hl.bind("SUPER + W", hl.dsp.exec_cmd("zen-browser --new-window"))
hl.bind("SUPER + Y", hl.dsp.exec_cmd("youtube-music"))
hl.bind("SHIFT + SUPER + W", hl.dsp.exec_cmd("zen-browser --private-window"))

local dp3_disabled = false
hl.bind("SUPER + SHIFT + G", function()
	dp3_disabled = not dp3_disabled
	if dp3_disabled then
		hl.monitor({ output = "DP-3", disabled = true })
	else
		hl.monitor({ output = "DP-3", disabled = false })
	end
end, { description = "Toggle DP-3 monitor on/off" })
