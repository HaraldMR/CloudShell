//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Remove two slashes below and adjust the value to change the UI scale
////@ pragma Env QT_SCALE_FACTOR=1

import qs.core
import qs.services
import qs.modules.bar
import qs.modules.calendar
import qs.modules.dropdown
import qs.modules.gameBar
import qs.modules.mediaControls
import qs.modules.notificationPopup
import qs.modules.onScreenDisplay
import qs.modules.overview
import qs.modules.polkit
import qs.modules.regionSelector
import qs.modules.sessionScreen
import qs.modules.settings

import QtQuick
import Quickshell

ShellRoot {
    id: root

    ReloadPopup {}
    CompatShortcuts {}

    Component.onCompleted: {
        Theme.load();
        Cliphist.refresh();
    }

    // Lock right after login (hyprlock), like ii's lock.launchOnStartup.
    // Only when Hyprland itself just started, so restarting/switching the shell never locks.
    Connections {
        target: Config
        function onReadyChanged() {
            if (!Config.ready || !Config.options.lock.launchOnStartup)
                return;
            Quickshell.execDetached(["bash", "-c", `pid=$(pidof -s Hyprland) && [ "$(ps -o etimes= -p "$pid" | tr -d ' ')" -lt 60 ] && { ${Config.options.lock.command}; }`]);
        }
    }

    // A module is loaded when it is enabled in the config ("auto" = when its programs are installed)
    component Module: LazyLoader {
        required property string name
        active: Config.ready && Deps.moduleEnabled(name)
    }

    Module { name: "bar"; component: Bar {} }
    Module { name: "calendar"; component: CalendarDropdown {} }
    Module { name: "dropdown"; component: Dropdown {} }
    Module { name: "gameBar"; component: GameBar {} }
    Module { name: "mediaControls"; component: MediaControls {} }
    Module { name: "notificationPopups"; component: NotificationPopup {} }
    Module { name: "osd"; component: OnScreenDisplay {} }
    Module { name: "overview"; component: Overview {} }
    Module { name: "polkit"; component: Polkit {} }
    Module { name: "regionSelector"; component: RegionSelector {} }
    Module { name: "session"; component: SessionScreen {} }
    SettingsWindow {}
}
