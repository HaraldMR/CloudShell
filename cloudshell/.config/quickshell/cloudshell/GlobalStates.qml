import qs.core
import qs.services
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root
    property bool barOpen: true
    property bool dropdownOpen: false
    property bool calendarOpen: false
    property bool mediaControlsOpen: false
    property bool osdBrightnessOpen: false
    property bool osdVolumeOpen: false
    property bool gameBarOpen: false
    property bool overviewOpen: false
    property bool regionSelectorOpen: false
    property bool searchOpen: false
    property bool settingsOpen: false
    property string settingsPage: ""
    property bool screenLocked: false // hyprlock handles locking; kept for ported code
    property bool sessionOpen: false
    property bool superDown: false
    property bool superReleaseMightTrigger: true
    property bool workspaceShowNumbers: false

    onDropdownOpenChanged: {
        if (root.dropdownOpen) {
            root.calendarOpen = false;
            Notifications.timeoutAll();
            Notifications.markAllRead();
        }
    }
    onCalendarOpenChanged: {
        if (root.calendarOpen)
            root.dropdownOpen = false;
    }

    function openSettings(page) {
        root.settingsPage = page ?? "";
        root.settingsOpen = true;
    }

    GlobalShortcut {
        name: "workspaceNumber"
        description: "Hold to show workspace numbers, release to show icons"

        onPressed: {
            root.superDown = true;
            root.superReleaseMightTrigger = true;
        }
        onReleased: {
            root.superDown = false;
        }
    }
}
