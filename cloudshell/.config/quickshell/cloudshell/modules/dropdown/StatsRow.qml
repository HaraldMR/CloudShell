pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.core
import qs.core.functions
import qs.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

/**
 * Resource usage row in the dropdown. Each stat can be turned on/off in Settings > Quick settings.
 * Stats get equal-width cells with their content centred, so 1-6 of them always line up.
 */
Rectangle {
    id: root
    implicitHeight: 76
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1

    readonly property var statConfig: Config.options.dropdown.stats
    readonly property list<string> order: ["cpu", "gpu", "ram", "swap", "disk", "network"]
    readonly property var shownStats: order.filter(id => statConfig[id] && (id !== "gpu" || root.gpuAvailable))
    readonly property int count: shownStats.length
    readonly property bool polling: GlobalStates.dropdownOpen && root.visible
    readonly property real cellWidth: count > 0 ? (width - padding * 2) / count : 0
    readonly property real padding: 6

    // Polled values (CPU, RAM and swap come from ResourceUsage)
    property real gpuUsage: 0
    property bool gpuAvailable: true // until the first poll says otherwise
    property real diskUsage: 0
    property real rxRate: 0 // bytes per second
    property real txRate: 0
    property real netPeak: 1024 * 1024 // bar scale: highest rate seen, at least 1 MB/s
    property var lastNet: null

    function formatRate(bytesPerSecond) {
        const kb = bytesPerSecond / 1024;
        if (kb < 1000)
            return `${Math.round(kb)} KB/s`;
        const mb = kb / 1024;
        if (mb < 1000)
            return `${mb < 10 ? mb.toFixed(1) : Math.round(mb)} MB/s`;
        return `${(mb / 1024).toFixed(1)} GB/s`;
    }

    function info(id) {
        switch (id) {
        case "cpu":
            return { "label": qsTr("CPU"), "icon": "developer_board", "value": ResourceUsage.cpuUsage, "text": `${Math.round(ResourceUsage.cpuUsage * 100)}%` };
        case "gpu":
            return { "label": qsTr("GPU"), "icon": "memory", "value": root.gpuUsage, "text": `${Math.round(root.gpuUsage * 100)}%` };
        case "ram":
            return { "label": qsTr("RAM"), "icon": "memory_alt", "value": ResourceUsage.memoryUsedPercentage, "text": `${Math.round(ResourceUsage.memoryUsedPercentage * 100)}%` };
        case "swap":
            return { "label": qsTr("Swap"), "icon": "swap_horiz", "value": ResourceUsage.swapUsedPercentage, "text": `${Math.round(ResourceUsage.swapUsedPercentage * 100)}%` };
        case "disk":
            return { "label": qsTr("Disk"), "icon": "hard_drive", "value": root.diskUsage, "text": `${Math.round(root.diskUsage * 100)}%` };
        case "network": {
            const total = root.rxRate + root.txRate;
            return { "label": qsTr("Network"), "icon": "swap_vert", "value": Math.min(1, total / root.netPeak), "text": root.formatRate(total) };
        }
        }
        return { "label": "", "icon": "", "value": 0, "text": "" };
    }

    Process {
        id: pollProc
        command: [`${Directories.scriptPath}/stats/poll.sh`]
        stdout: StdioCollector {
            onStreamFinished: {
                let data;
                try {
                    data = JSON.parse(this.text);
                } catch (e) {
                    return;
                }
                root.gpuAvailable = data.gpu >= 0;
                root.gpuUsage = Math.max(0, data.gpu) / 100;
                root.diskUsage = data.disk / 100;
                const now = Date.now();
                if (root.lastNet) {
                    const seconds = Math.max(0.001, (now - root.lastNet.time) / 1000);
                    root.rxRate = Math.max(0, (data.rx - root.lastNet.rx) / seconds);
                    root.txRate = Math.max(0, (data.tx - root.lastNet.tx) / seconds);
                    root.netPeak = Math.max(root.netPeak, root.rxRate + root.txRate);
                }
                root.lastNet = {
                    "time": now,
                    "rx": data.rx,
                    "tx": data.tx
                };
            }
        }
    }
    Timer {
        running: root.polling
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: pollProc.running = true
        onRunningChanged: if (!running)
            root.lastNet = null // don't average over the time the dropdown was closed
    }

    Item {
        anchors {
            fill: parent
            leftMargin: root.padding
            rightMargin: root.padding
        }

        Repeater {
            model: root.shownStats
            delegate: Item {
                id: cell
                required property string modelData
                required property int index
                readonly property var stat: root.info(modelData)
                x: index * root.cellWidth
                width: root.cellWidth
                height: parent.height

                // Divider sits on the cell boundary, away from the content
                Rectangle {
                    visible: cell.index > 0
                    anchors.verticalCenter: parent.verticalCenter
                    x: -width / 2
                    width: 1
                    height: parent.height * 0.5
                    color: Appearance.colors.colOutlineVariant
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    width: Math.min(cell.width - 20, 88)
                    spacing: 5

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: cell.stat.text
                        font.pixelSize: root.count <= 3 ? Appearance.font.pixelSize.large : Appearance.font.pixelSize.normal
                        font.weight: Font.DemiBold
                        font.family: Appearance.font.family.numbers
                        color: Appearance.colors.colOnLayer1
                    }

                    UsageBar {
                        Layout.fillWidth: true
                        value: cell.stat.value
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 3
                        MaterialSymbol {
                            visible: root.cellWidth >= 70 // dropped when six stats share the row
                            text: cell.stat.icon
                            iconSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                        StyledText {
                            text: cell.stat.label
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colSubtext
                        }
                    }
                }

                MouseArea {
                    id: cellHover
                    anchors.fill: parent
                    hoverEnabled: cell.modelData === "network"
                    acceptedButtons: Qt.NoButton
                }
                StyledToolTip {
                    extraVisibleCondition: cell.modelData === "network" && cellHover.containsMouse
                    text: qsTr("↓ %1   ↑ %2").arg(root.formatRate(root.rxRate)).arg(root.formatRate(root.txRate))
                }
            }
        }
    }

    // Plain left-to-right meter: faint track, filled part only where there's usage
    component UsageBar: Item {
        id: bar
        property real value: 0
        implicitHeight: 4

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.88)
        }
        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            radius: height / 2
            visible: bar.value > 0.005
            width: Math.max(height, bar.width * Math.min(1, bar.value))
            color: bar.value > 0.9 ? Appearance.colors.colError : Appearance.colors.colPrimary
            Behavior on width {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }
    }
}
