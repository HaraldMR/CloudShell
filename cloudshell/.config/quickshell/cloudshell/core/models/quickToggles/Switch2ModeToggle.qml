import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.core
import qs.core.functions
import qs.widgets

QuickToggleModel {
    id: root
    readonly property string command: Deps.expand(Config.options.integrations.switch2.command)
    name: qsTr("Switch 2 mode")
    statusText: toggleProc.running ? qsTr("Switching...") : (toggled ? qsTr("On") : qsTr("Off"))
    toggled: false
    available: Deps.fileExists(Config.options.integrations.switch2.command)
    icon: "stadia_controller"

    mainAction: () => {
        if (toggleProc.running)
            return;
        root.toggled = !root.toggled;
        toggleProc.command = [root.command, root.toggled ? "on" : "off"];
        toggleProc.running = true;
    }

    Process {
        id: toggleProc
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                Quickshell.execDetached(["notify-send", qsTr("Switch 2 mode"), qsTr("Failed to toggle. Check <tt>switch2-mode status</tt>"), "-a", "Shell"]);
            }
            fetchActiveState.running = true;
        }
    }

    Process {
        id: fetchActiveState
        running: root.available
        command: [root.command, "status"]
        stdout: StdioCollector {
            id: statusCollector
            onStreamFinished: root.toggled = statusCollector.text.includes("ON")
        }
    }

    tooltipText: qsTr("Use this PC as Bluetooth headphones for the Switch 2")
}
