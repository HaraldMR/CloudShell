-- Autostart

hl.on("hyprland.start", function()
	-- Session plumbing
	hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
	hl.exec_cmd("dbus-update-activation-environment --all")
	hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")

	-- Shell (the wallpaper comes from the skwd-walld user service) and idle/lock
	hl.exec_cmd("qs -c $qsConfig")
	hl.exec_cmd("hypridle")

	-- Clipboard history, also refreshes the shell's clipboard search
	hl.exec_cmd("wl-paste --type text --watch bash -c 'cliphist store && qs -c $qsConfig ipc call cliphistService update'")
	hl.exec_cmd("wl-paste --type image --watch bash -c 'cliphist store && qs -c $qsConfig ipc call cliphistService update'")

	-- Apps
	hl.exec_cmd("steam")
	hl.exec_cmd("sleep 10 && vesktop")
end)
