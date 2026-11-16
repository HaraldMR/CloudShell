-- Animations (Material 3 Expressive curves, matching the shell)

-- Curves
local curves = {
	expressiveFastSpatial = { { 0.42, 1.67 }, { 0.21, 0.90 } },
	expressiveSlowSpatial = { { 0.39, 1.29 }, { 0.35, 0.98 } },
	expressiveDefaultSpatial = { { 0.38, 1.21 }, { 0.22, 1.00 } },
	emphasizedDecel = { { 0.05, 0.7 }, { 0.1, 1 } },
	emphasizedAccel = { { 0.3, 0 }, { 0.8, 0.15 } },
	standardDecel = { { 0, 0 }, { 0, 1 } },
	menu_decel = { { 0.1, 1 }, { 0, 1 } },
	menu_accel = { { 0.52, 0.03 }, { 0.72, 0.08 } },
	stall = { { 1, -0.1 }, { 0.7, 0.85 } },
}
for name, points in pairs(curves) do
	hl.curve(name, { type = "bezier", points = points })
end

local function animate(leaf, speed, bezier, style)
	hl.animation({ leaf = leaf, enabled = true, speed = speed, bezier = bezier, style = style })
end

-- Windows
animate("windowsIn", 3, "emphasizedDecel", "popin 80%")
animate("windowsOut", 2, "emphasizedDecel", "popin 90%")
animate("windowsMove", 3, "emphasizedDecel", "slide")
animate("fadeIn", 3, "emphasizedDecel")
animate("fadeOut", 2, "emphasizedDecel")
animate("border", 10, "emphasizedDecel")

-- Layers (shell panels, menus)
animate("layersIn", 2.7, "emphasizedDecel", "popin 93%")
animate("layersOut", 2.4, "menu_accel", "popin 94%")
animate("fadeLayersIn", 0.5, "menu_decel")
animate("fadeLayersOut", 2.7, "stall")

-- Workspaces
animate("workspaces", 7, "menu_decel", "slide")
animate("specialWorkspaceIn", 2.8, "emphasizedDecel", "slidevert")
animate("specialWorkspaceOut", 1.2, "emphasizedAccel", "slidevert")

-- Zoom (Super + -/=)
animate("zoomFactor", 3, "standardDecel")
