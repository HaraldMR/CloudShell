pragma Singleton
pragma ComponentBehavior: Bound

import qs.core
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * Glue to skwd-wall: the picker, random wallpaper, and the daemon that draws the wallpaper.
 * Cloudshell does not draw a wallpaper itself.
 */
Singleton {
    id: root
    readonly property bool available: Deps.moduleEnabled("wallpaper")

    function openSelector() {
        if (!root.available) {
            Quickshell.execDetached(["notify-send", "-a", "Shell", qsTr("Wallpaper selector unavailable"), qsTr("Install skwd-wall (skwd-wall-v2-bin) to pick wallpapers")]);
            return;
        }
        // Toggles the picker if it is already open
        Quickshell.execDetached(["bash", "-c", `skwd-helm ui toggle 2>/dev/null || ${Config.options.apps.wallpaperSelector}`]);
    }

    function random() {
        if (!root.available)
            return;
        Quickshell.execDetached(["skwd-helm", "random"]);
    }

    GlobalShortcut {
        name: "wallpaperSelectorToggle"
        description: "Opens the wallpaper selector"
        onPressed: root.openSelector()
    }

    GlobalShortcut {
        name: "wallpaperSelectorRandom"
        description: "Applies a random wallpaper"
        onPressed: root.random()
    }

    IpcHandler {
        target: "wallpaper"
        function open(): void {
            root.openSelector();
        }
        function random(): void {
            root.random();
        }
    }
}
