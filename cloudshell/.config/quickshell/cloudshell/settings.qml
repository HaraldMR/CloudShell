// Compatibility entry point: `qs -p ~/.config/quickshell/cloudshell/settings.qml`
// (used by the Hyprland settingsApp variable) opens the settings window inside the running shell.
import QtQuick
import Quickshell

ShellRoot {
    Component.onCompleted: {
        Quickshell.execDetached(["qs", "-c", "cloudshell", "ipc", "call", "settings", "open"]);
        Qt.quit();
    }
}
