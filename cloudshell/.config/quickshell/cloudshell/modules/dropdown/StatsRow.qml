import qs.services
import qs.core
import qs.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// CPU / RAM / Disk usage, from the tripathi dropdown design
Rectangle {
    id: root
    implicitHeight: row.implicitHeight + 20
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1

    property real diskUsage: 0

    Process {
        id: diskProc
        command: ["bash", "-c", "df --output=pcent / | tail -1 | tr -dc '0-9'"]
        stdout: StdioCollector {
            onStreamFinished: root.diskUsage = (parseInt(this.text) || 0) / 100
        }
    }
    Timer {
        running: root.visible
        interval: 30000
        repeat: true
        triggeredOnStart: true
        onTriggered: diskProc.running = true
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        width: parent.width - 24
        spacing: 0

        Stat {
            icon: "developer_board"
            label: qsTr("CPU")
            value: ResourceUsage.cpuUsage
        }
        Rectangle {
            Layout.fillHeight: true
            Layout.topMargin: 6
            Layout.bottomMargin: 6
            implicitWidth: 1
            color: Appearance.colors.colOutlineVariant
        }
        Stat {
            icon: "memory_alt"
            label: qsTr("RAM")
            value: ResourceUsage.memoryUsedPercentage
        }
        Rectangle {
            Layout.fillHeight: true
            Layout.topMargin: 6
            Layout.bottomMargin: 6
            implicitWidth: 1
            color: Appearance.colors.colOutlineVariant
        }
        Stat {
            icon: "hard_drive"
            label: qsTr("Disk")
            value: root.diskUsage
        }
    }

    component Stat: ColumnLayout {
        id: stat
        required property string icon
        required property string label
        required property real value
        // Equal-width cells with everything centred
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        spacing: 4

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4
            MaterialSymbol {
                text: stat.icon
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer1
            }
            StyledText {
                text: `${Math.round(stat.value * 100)}%`
                font.pixelSize: Appearance.font.pixelSize.large
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer1
            }
        }
        StyledProgressBar {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 72
            implicitWidth: 72
            valueBarWidth: 72
            value: stat.value
        }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: stat.label
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
        }
    }
}
