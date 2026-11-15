for i = 1, 9 do
	hl.workspace_rule({ workspace = tostring(i), monitor = "DP-1", default = true })
end
for i = 10, 18 do
	hl.workspace_rule({ workspace = tostring(i), monitor = "DP-3", default = true })
end

hl.window_rule({ match = { class = "^(mpv)$" }, fullscreen = true })
hl.window_rule({ match = { class = "^(swayimg.*)$" }, fullscreen = true })

hl.window_rule({ match = { class = "^(discord)$" }, workspace = 10 })
hl.window_rule({ match = { class = "^(vesktop)$" }, workspace = 10 })

hl.window_rule({ match = { class = "steam" }, workspace = 1 })
hl.window_rule({
	match = {
		title = "^(Friends List)$",
		class = "^(steam)$",
	},
	float = true,
	center = true,
	size = { "(monitor_w*0.2)", "(monitor_h*0.7)" },
})

hl.window_rule({
	float = true,
	size = { "(monitor_w*0.4)", "(monitor_h*0.7)" },
	center = true,
	match = {
		title = "^(Steam Settings)$",
		class = "^(steam)$",
	},
})

hl.window_rule({
	no_focus = true,
	match = {
		class = "()",
		title = "()",
		float = 1,
	},
})

-- Cloudshell settings window
hl.window_rule({
	match = { title = "^(Cloudshell Settings)$" },
	float = true,
	center = true,
	size = { "(monitor_w*0.45)", "(monitor_h*0.65)" },
})
