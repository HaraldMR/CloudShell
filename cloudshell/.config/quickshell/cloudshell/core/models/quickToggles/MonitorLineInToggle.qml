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
    readonly property string script: `${Directories.scriptPath}/audio/line-in.sh`
    name: qsTr("Line in")
    statusText: toggled ? qsTr("Monitoring") : qsTr("Off")
    toggled: false
    available: Deps.has("pactl")
    icon: "cable"

    mainAction: () => {
        root.toggled = !root.toggled;
        actionProc.command = root.toggled ? [root.script, "on", Config.options.integrations.lineIn.sourceMatch, Config.options.integrations.lineIn.sinkMatch] : [root.script, "off"];
        actionProc.running = true;
    }

    Process {
        id: actionProc
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                Quickshell.execDetached(["notify-send", qsTr("Line in"), qsTr("Couldn't find the line-in device. Check the device names in Settings > Integrations."), "-a", "Shell"]);
            fetchActiveState.running = true;
        }
    }

    Process {
        id: fetchActiveState
        running: root.available
        command: [root.script, "status"]
        onExited: (exitCode, exitStatus) => root.toggled = exitCode === 0
    }

    tooltipText: qsTr("Hear the line-in input through your speakers")
}
