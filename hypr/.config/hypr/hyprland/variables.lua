-- Which Quickshell config to run (~/.config/quickshell/<name>)
hl.env("qsConfig", "cloudshell")

-- Defaults for every device; override any of these in ~/.config/hypr/local.lua

-- Apps
terminal = "kitty -1"
fileManager = "dolphin"
codeEditor = "kitty -1 nvim"
textEditor = "kitty -1 micro"
volumeMixer = "pavucontrol-qt"
settingsApp = "qs -c $qsConfig ipc call settings open"
taskManager = "kitty -1 fish -c btop"
browser = "zen-browser --new-window"
privateBrowser = "zen-browser --private-window"
musicPlayer = "youtube-music"

-- Started once at login (after the shell)
autostart = {}

-- Super+1..0 stay within groups of this many workspaces
workspaceGroupSize = 10
