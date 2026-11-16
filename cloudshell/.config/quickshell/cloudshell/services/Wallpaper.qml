pragma Singleton
pragma ComponentBehavior: Bound

import qs.core
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * Wallpaper handling.
 * - With skwd-wall: its daemon (skwd-walld) draws the wallpaper; this starts it if needed and drives
 *   the picker / random / apply through skwd-helm.
 * - Without it (not installed, or the daemon won't run): the Background module draws
 *   theme.fallbackWallpaper itself and colours are generated with matugen directly.
 */
Singleton {
    id: root
    readonly property bool available: Deps.moduleEnabled("wallpaper") // skwd-wall installed and enabled
    property bool daemonRunning: false
    readonly property string imagePath: Deps.expand(Config.options.theme.fallbackWallpaper ?? "")
    // Cloudshell draws the wallpaper itself when skwd-wall isn't drawing one
    readonly property bool selfDrawn: !root.daemonRunning && root.imagePath.length > 0
    property bool triedStartingDaemon: false

    function openSelector() {
        if (!root.available) {
            Quickshell.execDetached(["notify-send", "-a", "Shell", qsTr("Wallpaper selector unavailable"), qsTr("Install skwd-wall (skwd-wall-v2-bin), or set an image in Settings > Wallpaper & style")]);
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

    // Set the wallpaper to an image file, through skwd-wall when it's running
    function setWallpaper(path) {
        const expanded = Deps.expand(path.trim());
        if (expanded.length === 0)
            return;
        Config.options.theme.fallbackWallpaper = path.trim();
        if (root.available && root.daemonRunning) {
            // skwd-wall applies it and runs matugen (colours + lock screen)
            Quickshell.execDetached(["skwd-helm", "apply", expanded]);
        } else {
            // Colours (matugen also refreshes hyprlock's wallpaper through its hook)
            Theme.regenerate(expanded);
        }
    }

    function checkDaemon() {
        if (!root.available) {
            root.daemonRunning = false;
            return;
        }
        if (!statusProc.running)
            statusProc.running = true;
    }

    // `skwd-helm current` only succeeds when the daemon answers
    Process {
        id: statusProc
        command: ["skwd-helm", "current", "--json"]
        stdout: StdioCollector {}
        onExited: (exitCode, exitStatus) => {
            root.daemonRunning = exitCode === 0;
            if (!root.daemonRunning && !root.triedStartingDaemon) {
                // Installed but not running (e.g. the user service was never enabled): start it once
                root.triedStartingDaemon = true;
                Quickshell.execDetached(["systemctl", "--user", "start", "skwd-walld.service"]);
                recheck.restart();
            }
        }
    }
    Timer {
        id: recheck
        interval: 4000
        onTriggered: root.checkDaemon()
    }
    Timer {
        // Notice the daemon stopping or starting later on
        running: root.available
        interval: 30000
        repeat: true
        onTriggered: root.checkDaemon()
    }

    Connections {
        target: Deps
        function onReadyChanged() {
            if (Deps.ready)
                root.checkDaemon();
        }
    }
    Component.onCompleted: if (Deps.ready)
        root.checkDaemon()

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
        function set(path: string): void {
            root.setWallpaper(path);
        }
    }
}
