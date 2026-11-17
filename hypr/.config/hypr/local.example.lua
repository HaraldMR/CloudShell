-- This device's own Hyprland settings.
--
-- Copy this file to ~/.config/hypr/local.lua and edit it. local.lua is not part of the dotfiles
-- repo, so each device keeps its own. It's loaded after everything in hyprland/, so anything
-- here overrides the shared defaults. Uncomment and change what you need.

---------------------------------------------------------------- Apps (defaults in hyprland/variables.lua)

-- browser = "firefox --new-window"
-- privateBrowser = "firefox --private-window"
-- terminal = "kitty -1"
-- fileManager = "dolphin"
-- codeEditor = "code"

-- Started at login (replaces the default list)
-- autostart = { "vesktop" }

---------------------------------------------------------------- Input

-- Keyboard layout / options for this device
-- hl.config({ input = { kb_layout = "us", kb_options = "caps:escape" } })

-- One specific device (names from `hyprctl devices`), e.g. a laptop touchpad
-- hl.device({
-- 	name = "elan0712:00-04f3:30fd-touchpad",
-- 	sensitivity = 0.3,
-- 	natural_scroll = true,
-- 	accel_profile = "adaptive",
-- })

---------------------------------------------------------------- Look and behaviour

-- hl.config({ general = { gaps_out = 5 }, decoration = { rounding = 12 } })

---------------------------------------------------------------- Extra keybinds, rules and environment

-- hl.bind("SUPER + B", hl.dsp.exec_cmd("blueman-manager"), { description = "App: Bluetooth" })
-- hl.window_rule({ match = { class = "^(obsidian)$" }, workspace = 3 })
-- hl.env("GDK_SCALE", "2")
