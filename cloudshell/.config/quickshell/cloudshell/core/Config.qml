pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.core.functions

/**
 * User configuration, stored at ~/.config/cloudshell/config.json.
 * Every option has a default here; the file only needs to contain what differs.
 */
Singleton {
    id: root
    property string filePath: Directories.shellConfigPath
    property alias options: configOptionsJsonAdapter
    property bool ready: false
    property int readWriteDelay: 50 // milliseconds
    property bool blockWrites: false

    function setNestedValue(nestedKey, value) {
        let keys = nestedKey.split(".");
        let obj = root.options;
        for (let i = 0; i < keys.length - 1; ++i) {
            if (!obj[keys[i]] || typeof obj[keys[i]] !== "object") {
                obj[keys[i]] = {};
            }
            obj = obj[keys[i]];
        }
        let convertedValue = value;
        if (typeof value === "string") {
            let trimmed = value.trim();
            if (trimmed === "true" || trimmed === "false" || !isNaN(Number(trimmed))) {
                try {
                    convertedValue = JSON.parse(trimmed);
                } catch (e) {
                    convertedValue = value;
                }
            }
        }
        obj[keys[keys.length - 1]] = convertedValue;
    }

    Timer {
        id: fileReloadTimer
        interval: root.readWriteDelay
        repeat: false
        onTriggered: configFileView.reload()
    }

    Timer {
        id: fileWriteTimer
        interval: root.readWriteDelay
        repeat: false
        onTriggered: configFileView.writeAdapter()
    }

    FileView {
        id: configFileView
        path: root.filePath
        watchChanges: true
        blockWrites: root.blockWrites
        onFileChanged: fileReloadTimer.restart()
        onAdapterUpdated: fileWriteTimer.restart()
        onLoaded: root.ready = true
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                writeAdapter();
                root.ready = true;
            }
        }

        JsonAdapter {
            id: configOptionsJsonAdapter

            // "auto": enabled when the programs it needs are installed (see Deps)
            // true / false: force on or off
            property JsonObject modules: JsonObject {
                property var background: true // only draws when skwd-wall isn't running
                property var bar: true
                property var dropdown: true
                property var calendar: true
                property var notificationPopups: true
                property var overview: true
                property var osd: true
                property var session: true
                property var polkit: "auto"
                property var mediaControls: true
                property var regionSelector: "auto"
                property var gameBar: "auto"
                property var wallpaper: "auto"
                property var theming: "auto"
            }

            property JsonObject appearance: JsonObject {
                property bool extraBackgroundTint: true
                property int fakeScreenRounding: 0 // 0: None | 1: Always | 2: When not fullscreen
                property JsonObject fonts: JsonObject {
                    property string main: "Google Sans Flex"
                    property string numbers: "Google Sans Flex"
                    property string title: "Google Sans Flex"
                    property string iconNerd: "JetBrains Mono NF"
                    property string monospace: "JetBrains Mono NF"
                    property string reading: "Google Sans Flex"
                    property string expressive: "Google Sans Flex"
                }
                // Liquid glass: translucent, blurred surfaces with a bright edge
                property JsonObject glass: JsonObject {
                    property bool enable: false
                    // Blur strength behind glass panels: 1 = heavy frost, 0 = almost none.
                    // Applied to Hyprland's blur settings by services/Glass.qml
                    property real blur: 0.5
                }
                property JsonObject transparency: JsonObject {
                    property bool enable: false
                    property bool automatic: false
                    property real backgroundTransparency: 0.11
                    property real contentTransparency: 0.57
                }
            }

            property JsonObject theme: JsonObject {
                property string mode: "dark" // "dark" | "light"
                property string scheme: "scheme-content" // matugen -t value
                // Used when skwd-wall is not installed: matugen is run directly on this image
                property string fallbackWallpaper: ""
            }

            property JsonObject apps: JsonObject {
                property string bluetooth: "kcmshell6 kcm_bluetooth"
                property string network: "plasmawindowed org.kde.plasma.networkmanagement"
                property string networkEthernet: "kcmshell6 kcm_networkmanagement"
                property string taskManager: "plasma-systemmonitor --page-name Processes"
                property string terminal: "kitty -1"
                property string volumeMixer: "pavucontrol-qt"
                property string wallpaperSelector: "skwd-wall-v2"
            }

            property JsonObject audio: JsonObject {
                property JsonObject protection: JsonObject {
                    property bool enable: false
                    property real maxAllowedIncrease: 10
                    property real maxAllowed: 90
                }
            }

            property JsonObject bar: JsonObject {
                property JsonObject autoHide: JsonObject {
                    property bool enable: false
                    property int hoverRegionWidth: 2
                    property bool pushWindows: false
                    property JsonObject showWhenPressingSuper: JsonObject {
                        property bool enable: true
                        property int delay: 140
                    }
                }
                property bool bottom: false
                property int cornerStyle: 2 // 0: Hug | 1: Float | 2: Plain rectangle
                property bool floatStyleShadow: true
                property bool borderless: true
                property bool showBackground: false
                property bool verbose: true
                property bool vertical: false // Not supported, kept for ported code
                property list<string> screenList: []
                // Pill backgrounds behind the bar's groups
                property JsonObject pills: JsonObject {
                    property bool enable: true
                    property real opacity: 1 // 0..1
                    property string style: "surface" // "surface" | "tonal" | "primary"
                    property bool outline: false
                    property bool clock: true
                    property bool media: true
                    property bool workspaces: true
                    property bool status: true // tray, battery, network/bluetooth
                }
                property JsonObject workspaces: JsonObject {
                    property bool monochromeIcons: false
                    property int shown: 9
                    property bool showAppIcons: true
                    property bool alwaysShowNumbers: false
                    property int showNumberDelay: 300
                    property list<string> numberMap: ["1", "2"]
                    property bool useNerdFont: false
                }
                property JsonObject indicators: JsonObject {
                    property JsonObject notifications: JsonObject {
                        property bool showUnreadCount: true
                    }
                }
                property JsonObject tooltips: JsonObject {
                    property bool clickToShow: false
                }
            }

            property JsonObject battery: JsonObject {
                property int low: 20
                property int critical: 5
                property int full: 101
                property bool automaticSuspend: false
                property int suspend: 3
            }

            property JsonObject calendar: JsonObject {
                property string locale: "en-GB"
            }

            property JsonObject dropdown: JsonObject {
                property JsonObject sections: JsonObject {
                    property bool volume: true
                    property bool mic: false
                    property bool brightness: true
                    property bool stats: false
                    property bool notifications: true
                }
                // Which resources the usage row shows (when sections.stats is on)
                property JsonObject stats: JsonObject {
                    property bool cpu: true
                    property bool gpu: false
                    property bool ram: true
                    property bool swap: false
                    property bool disk: true
                    property bool network: false
                }
                property int columns: 4
                // Each toggle: { type: string, size: 1 | 2 }. Types: network, bluetooth, audio, mic,
                // notifications, idleInhibitor, powerProfile, monitorLineIn, switch2Mode, hueLight
                property list<var> toggles: [
                    { "size": 2, "type": "network" },
                    { "size": 2, "type": "bluetooth" },
                    { "size": 1, "type": "audio" },
                    { "size": 1, "type": "mic" },
                    { "size": 1, "type": "notifications" },
                    { "size": 1, "type": "idleInhibitor" },
                    { "size": 2, "type": "hueLight" },
                    { "size": 1, "type": "switch2Mode" },
                    { "size": 1, "type": "powerProfile" }
                ]
            }

            property JsonObject gameBar: JsonObject {
                property real backgroundOpacity: 0.55
                property string mangohudConfig: "~/.config/MangoHud/MangoHud.conf"
                property list<int> fpsPresets: [30, 60, 90, 120, 144, 165]
                property int replaySeconds: 60
            }

            property JsonObject integrations: JsonObject {
                property JsonObject lineIn: JsonObject {
                    // Substrings matched against `pactl list short sources/sinks` names
                    property string sourceMatch: "Line__source"
                    property string sinkMatch: "Focusrite"
                }
                property JsonObject switch2: JsonObject {
                    property string command: "~/.local/bin/switch2-mode"
                }
                property JsonObject hue: JsonObject {
                    property string envFile: "~/.config/hue/bridge.env"
                }
            }

            property JsonObject interactions: JsonObject {
                property JsonObject scrolling: JsonObject {
                    property bool fasterTouchpadScroll: false
                    property int mouseScrollDeltaThreshold: 120
                    property int mouseScrollFactor: 120
                    property int touchpadScrollFactor: 450
                }
                property JsonObject deadPixelWorkaround: JsonObject {
                    property bool enable: false
                }
            }

            property JsonObject launcher: JsonObject {
                property list<string> pinnedApps: ["org.kde.dolphin", "kitty"]
            }

            property JsonObject lock: JsonObject {
                property bool launchOnStartup: true
                property bool blur: true // Blur the wallpaper behind hyprlock
                property string command: "pidof hyprlock || hyprlock"
            }

            property JsonObject media: JsonObject {
                property bool filterDuplicatePlayers: true
            }

            property JsonObject notifications: JsonObject {
                property int timeout: 7000
                property JsonObject forceMonitor: JsonObject {
                    property bool enable: false
                    property string name: ""
                }
                // Each filter: { appName, summary, body, matchType: "contains" | "exact" }
                // All non-empty fields must match (AND). Multiple filters use OR logic.
                property list<var> filters: []
                // appName -> "allow" | "silent" | "block"
                property var appRules: ({})
                property bool showSilentSection: true
            }

            property JsonObject osd: JsonObject {
                property int timeout: 1000
            }

            property JsonObject overview: JsonObject {
                property bool enable: true
                property real scale: 0.18
                property real rows: 3
                property real columns: 3
                property bool orderRightLeft: false
                property bool orderBottomUp: false
                property bool centerIcons: false
            }

            property JsonObject regionSelector: JsonObject {
                property JsonObject targetRegions: JsonObject {
                    property bool windows: true
                    property bool layers: false
                    property bool content: true
                    property bool showLabel: false
                    property real opacity: 0.3
                    property real contentRegionOpacity: 0.8
                    property int selectionPadding: 5
                }
                property JsonObject rect: JsonObject {
                    property bool showAimLines: true
                }
                property JsonObject circle: JsonObject {
                    property int strokeWidth: 6
                    property int padding: 10
                }
            }

            property JsonObject resources: JsonObject {
                property int updateInterval: 3000
                property int historyLength: 60
            }

            property JsonObject screenRecord: JsonObject {
                property string savePath: Directories.videos.replace("file://", "")
            }

            property JsonObject screenSnip: JsonObject {
                property string savePath: "" // only copy to clipboard when empty
            }

            property JsonObject search: JsonObject {
                property int nonAppResultDelay: 30
                property string engineBaseUrl: "https://www.google.com/search?q="
                property list<string> excludedSites: ["quora.com"]
                property bool sloppy: false
                property JsonObject prefix: JsonObject {
                    property bool showDefaultActionsWithoutPrefix: true
                    property string action: "/"
                    property string app: ">"
                    property string clipboard: ";"
                    property string emojis: ":"
                    property string math: "="
                    property string shellCommand: "$"
                    property string webSearch: "?"
                }
            }

            property JsonObject sounds: JsonObject {
                property bool battery: false
                property string theme: "freedesktop"
            }

            property JsonObject time: JsonObject {
                property string format: "hh:mm"
                property string shortDateFormat: "dd/MM"
                property string dateWithYearFormat: "dd/MM/yyyy"
                property string dateFormat: "ddd, dd/MM"
                property bool secondPrecision: false
            }

            property JsonObject tray: JsonObject {
                property bool monochromeIcons: true
                property bool showItemId: false
                property bool invertPinnedItems: true
                property list<var> pinnedItems: ["Fcitx"]
                property bool filterPassive: true
            }

            property JsonObject windows: JsonObject {
                property bool showTitlebar: true
                property bool centerTitle: true
            }

            property JsonObject hacks: JsonObject {
                property int arbitraryRaceConditionDelay: 20
            }
        }
    }
}
