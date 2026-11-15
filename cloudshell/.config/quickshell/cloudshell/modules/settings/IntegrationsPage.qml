import QtQuick
import QtQuick.Layouts
import qs.services
import qs.core
import qs.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "cable"
        title: qsTr("Monitor line in")

        StyledText {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            color: Appearance.colors.colSubtext
            text: qsTr("Part of the device names from `pactl list short sources` / `sinks`. The first match is used.")
        }
        ConfigRow {
            uniform: true
            MaterialTextField {
                Layout.fillWidth: true
                placeholderText: qsTr("Input (source)")
                text: Config.options.integrations.lineIn.sourceMatch
                onEditingFinished: Config.options.integrations.lineIn.sourceMatch = text
            }
            MaterialTextField {
                Layout.fillWidth: true
                placeholderText: qsTr("Output (sink)")
                text: Config.options.integrations.lineIn.sinkMatch
                onEditingFinished: Config.options.integrations.lineIn.sinkMatch = text
            }
        }
    }

    ContentSection {
        icon: "stadia_controller"
        title: qsTr("Switch 2 mode")

        ContentSubsection {
            title: qsTr("Script (called with on / off / status)")
            MaterialTextField {
                Layout.fillWidth: true
                text: Config.options.integrations.switch2.command
                onEditingFinished: {
                    Config.options.integrations.switch2.command = text;
                    Deps.refresh();
                }
            }
        }
        StatusLine {
            ok: Deps.fileExists(Config.options.integrations.switch2.command)
            okText: qsTr("Script found")
            missingText: qsTr("Script not found, the toggle is hidden")
        }
    }

    ContentSection {
        icon: "lightbulb"
        title: qsTr("Room light (Philips Hue)")

        ContentSubsection {
            title: qsTr("Bridge config file (HUE_BRIDGE, HUE_KEY, HUE_GROUP)")
            MaterialTextField {
                Layout.fillWidth: true
                text: Config.options.integrations.hue.envFile
                onEditingFinished: {
                    Config.options.integrations.hue.envFile = text;
                    Deps.refresh();
                }
            }
        }
        StatusLine {
            ok: Deps.fileExists(Config.options.integrations.hue.envFile)
            okText: qsTr("Bridge config found")
            missingText: qsTr("No bridge config, the toggle is hidden")
        }
    }

    ContentSection {
        icon: "apps"
        title: qsTr("Apps")

        Repeater {
            model: [
                { "key": "terminal", "label": qsTr("Terminal (for shell commands)") },
                { "key": "volumeMixer", "label": qsTr("Volume mixer") },
                { "key": "network", "label": qsTr("Network settings") },
                { "key": "bluetooth", "label": qsTr("Bluetooth settings") },
                { "key": "taskManager", "label": qsTr("Task manager") }
            ]
            delegate: ContentSubsection {
                required property var modelData
                title: modelData.label
                MaterialTextField {
                    Layout.fillWidth: true
                    text: Config.options.apps[modelData.key]
                    onEditingFinished: Config.options.apps[modelData.key] = text
                }
            }
        }
    }

    component StatusLine: RowLayout {
        id: statusLine
        property bool ok
        property string okText
        property string missingText
        MaterialSymbol {
            text: statusLine.ok ? "check_circle" : "error"
            iconSize: Appearance.font.pixelSize.larger
            color: statusLine.ok ? Appearance.colors.colPrimary : Appearance.colors.colError
        }
        StyledText {
            text: statusLine.ok ? statusLine.okText : statusLine.missingText
            color: Appearance.colors.colOnLayer1
        }
    }
}
