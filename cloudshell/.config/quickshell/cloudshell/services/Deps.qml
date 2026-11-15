pragma Singleton
pragma ComponentBehavior: Bound

import qs.core
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Detects which external programs are installed, so modules and toggles that need
 * something missing can hide themselves instead of erroring. This is what keeps
 * cloudshell usable on systems where some packages don't exist.
 */
Singleton {
    id: root

    readonly property list<string> binaries: ["nmcli", "bluetoothctl", "pactl", "powerprofilesctl", "brightnessctl", "ddcutil", "cliphist", "wl-copy", "qalc", "grim", "slurp", "magick", "tesseract", "satty", "gpu-screen-recorder", "mangohud", "matugen", "skwd-wall-v2", "skwd-helm", "hyprlock", "jq", "curl", "playerctl", "notify-send"]

    // What each module needs. Modules set to "auto" in the config are only loaded when all are present.
    readonly property var moduleRequirements: ({
            "regionSelector": ["grim", "magick", "wl-copy"],
            "wallpaper": ["skwd-wall-v2"],
            "theming": ["matugen"]
        })

    // Install hints shown in the settings app
    readonly property var packageHints: ({
            "nmcli": "networkmanager",
            "bluetoothctl": "bluez-utils",
            "pactl": "pipewire-pulse (Arch) / pulseaudio-utils (Debian)",
            "powerprofilesctl": "power-profiles-daemon",
            "brightnessctl": "brightnessctl",
            "ddcutil": "ddcutil",
            "cliphist": "cliphist",
            "wl-copy": "wl-clipboard",
            "qalc": "libqalculate (Arch) / qalc (Debian)",
            "grim": "grim",
            "slurp": "slurp",
            "magick": "imagemagick",
            "tesseract": "tesseract + tesseract-data-eng",
            "satty": "satty",
            "gpu-screen-recorder": "gpu-screen-recorder",
            "mangohud": "mangohud",
            "matugen": "matugen",
            "skwd-wall-v2": "skwd-wall-v2-bin (AUR)",
            "skwd-helm": "skwd-deck-bin (AUR)",
            "hyprlock": "hyprlock",
            "jq": "jq",
            "curl": "curl",
            "playerctl": "playerctl",
            "notify-send": "libnotify"
        })

    property bool ready: false
    property var available: ({})
    property var files: ({})

    function has(binary: string): bool {
        return root.available[binary] === true;
    }

    function fileExists(path: string): bool {
        return root.files[root.expand(path)] === true;
    }

    function missingFor(moduleName) {
        const reqs = root.moduleRequirements[moduleName] ?? [];
        return reqs.filter(b => !root.has(b));
    }

    // true when the module should be loaded
    function moduleEnabled(moduleName: string): bool {
        const setting = Config.options.modules[moduleName];
        if (setting === false || setting === "false")
            return false;
        if (setting === true || setting === "true")
            return true;
        // "auto"
        return root.ready && root.missingFor(moduleName).length === 0;
    }

    function expand(path: string): string {
        return path.replace(/^~/, Quickshell.env("HOME"));
    }

    function refresh() {
        const fileList = [Config.options.integrations.switch2.command, Config.options.integrations.hue.envFile].map(p => root.expand(p));
        root.fileChecks = fileList;
        detectProc.command = ["bash", "-c", `for b in ${root.binaries.join(" ")}; do command -v "$b" >/dev/null 2>&1 && echo "bin:$b"; done; for f in "$@"; do [ -e "$f" ] && echo "file:$f"; done; true`, "deps"].concat(fileList);
        detectProc.running = true;
    }
    property list<string> fileChecks: []

    Process {
        id: detectProc
        stdout: StdioCollector {
            onStreamFinished: {
                const bins = {};
                const files = {};
                for (const line of this.text.split("\n")) {
                    if (line.startsWith("bin:"))
                        bins[line.slice(4)] = true;
                    else if (line.startsWith("file:"))
                        files[line.slice(5)] = true;
                }
                root.available = bins;
                root.files = files;
                root.ready = true;
            }
        }
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready)
                root.refresh();
        }
    }

    Component.onCompleted: {
        if (Config.ready)
            root.refresh();
    }

    IpcHandler {
        target: "deps"
        function refresh(): void {
            root.refresh();
        }
        function list(): string {
            return JSON.stringify({
                binaries: root.available,
                files: root.files
            });
        }
    }
}
