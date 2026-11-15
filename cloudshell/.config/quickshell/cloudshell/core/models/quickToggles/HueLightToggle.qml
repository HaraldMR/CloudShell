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
    readonly property string script: `${Directories.scriptPath}/hue/hueLight.sh`

    property string roomName: ""
    property int brightness: 0
    // Ignore polled state for a moment after sending commands so the UI doesn't jump back
    property real lastCommandTime: 0
    property var queuedArgs: null

    name: roomName !== "" ? roomName : qsTr("Room light")
    statusText: !available ? qsTr("Unreachable") : toggled ? `${brightness}%` : qsTr("Off")
    icon: "lightbulb"
    available: false
    readonly property bool configured: Deps.fileExists(Config.options.integrations.hue.envFile) && Deps.has("curl") && Deps.has("jq")
    toggled: false

    mainAction: () => {
        root.toggled = !root.toggled;
        root.send([root.toggled ? "on" : "off"]);
    }

    function setBrightness(percent) {
        const value = Math.round(Math.max(0, Math.min(100, percent)));
        if (value > 0)
            root.brightness = value;
        root.toggled = value > 0;
        root.send(["set", String(value)]);
    }

    function send(args) {
        root.lastCommandTime = Date.now();
        root.queuedArgs = args;
        if (!commandProc.running)
            flushQueue();
    }

    function flushQueue() {
        if (!root.queuedArgs)
            return;
        commandProc.command = ["env", `HUE_ENV_FILE=${Deps.expand(Config.options.integrations.hue.envFile)}`, root.script, ...root.queuedArgs];
        root.queuedArgs = null;
        commandProc.running = true;
    }

    function refresh() {
        if (!fetchProc.running)
            fetchProc.running = true;
    }

    // Only the latest value is kept while a command is in flight, so dragging never floods the bridge
    Process {
        id: commandProc
        onExited: (exitCode, exitStatus) => {
            root.lastCommandTime = Date.now();
            root.flushQueue();
        }
    }

    Process {
        id: fetchProc
        command: ["env", `HUE_ENV_FILE=${Deps.expand(Config.options.integrations.hue.envFile)}`, root.script, "get"]
        stdout: StdioCollector {
            id: fetchOutput
            onStreamFinished: {
                if (commandProc.running || root.queuedArgs || Date.now() - root.lastCommandTime < 1500)
                    return;
                try {
                    const state = JSON.parse(fetchOutput.text);
                    root.roomName = state.name;
                    root.available = state.reachable;
                    root.toggled = state.on;
                    if (state.brightness > 0)
                        root.brightness = state.brightness;
                } catch (e) {
                    root.available = false;
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root.available = false;
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: GlobalStates.dropdownOpen && root.configured
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: if (configured) refresh()
    onConfiguredChanged: if (configured) refresh()

    tooltipText: qsTr("%1 | Click to toggle, drag to change brightness").arg(root.name)
}
