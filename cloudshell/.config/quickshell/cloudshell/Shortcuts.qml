import qs
import qs.core
import qs.services
import qs.core.functions
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

/**
 * Global shortcuts (quickshell:<name> in Hyprland) and IPC targets that don't belong to a single module.
 */
Scope {
    id: root

    function lock() {
        Session.lock();
    }

    // hypridle's lock_cmd and Super+L dispatch this
    GlobalShortcut {
        name: "lock"
        description: "Locks the screen (hyprlock)"
        onPressed: root.lock()
    }

    GlobalShortcut {
        name: "dropdownToggle"
        description: "Toggles the dropdown"
        onPressed: GlobalStates.dropdownOpen = !GlobalStates.dropdownOpen
    }

    GlobalShortcut {
        name: "gameBarToggle"
        description: "Toggles the game bar"
        onPressed: GlobalStates.gameBarOpen = !GlobalStates.gameBarOpen
    }

    GlobalShortcut {
        name: "calendarToggle"
        description: "Toggles the calendar"
        onPressed: GlobalStates.calendarOpen = !GlobalStates.calendarOpen
    }

    GlobalShortcut {
        name: "settingsToggle"
        description: "Toggles the settings window"
        onPressed: GlobalStates.settingsOpen = !GlobalStates.settingsOpen
    }

    IpcHandler {
        target: "lock"
        function lock(): void {
            root.lock();
        }
    }

    IpcHandler {
        target: "dropdown"
        function toggle(): void {
            GlobalStates.dropdownOpen = !GlobalStates.dropdownOpen;
        }
        function open(): void {
            GlobalStates.dropdownOpen = true;
        }
        function close(): void {
            GlobalStates.dropdownOpen = false;
        }
    }

    IpcHandler {
        target: "calendar"
        function toggle(): void {
            GlobalStates.calendarOpen = !GlobalStates.calendarOpen;
        }
    }

    IpcHandler {
        target: "gameBar"
        function toggle(): void {
            GlobalStates.gameBarOpen = !GlobalStates.gameBarOpen;
        }
    }

    IpcHandler {
        target: "settings"
        function open(): void {
            GlobalStates.openSettings("");
        }
        function openPage(page: string): void {
            GlobalStates.openSettings(page);
        }
        function toggle(): void {
            GlobalStates.settingsOpen = !GlobalStates.settingsOpen;
        }
    }
}
