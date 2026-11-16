import QtQuick
import QtQuick.Layouts
import qs.services
import qs.core
import qs.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "view_agenda"
        title: qsTr("Sections")

        ConfigSwitch {
            buttonIcon: "volume_up"
            text: qsTr("Volume slider")
            checked: Config.options.dropdown.sections.volume
            onCheckedChanged: Config.options.dropdown.sections.volume = checked
        }
        ConfigSwitch {
            buttonIcon: "mic"
            text: qsTr("Microphone slider")
            checked: Config.options.dropdown.sections.mic
            onCheckedChanged: Config.options.dropdown.sections.mic = checked
        }
        ConfigSwitch {
            buttonIcon: "light_mode"
            text: qsTr("Brightness slider (hidden when the monitor doesn't support it)")
            checked: Config.options.dropdown.sections.brightness
            onCheckedChanged: Config.options.dropdown.sections.brightness = checked
        }
        ConfigSwitch {
            buttonIcon: "monitoring"
            text: qsTr("Resource usage")
            checked: Config.options.dropdown.sections.stats
            onCheckedChanged: Config.options.dropdown.sections.stats = checked
        }
        Flow {
            Layout.fillWidth: true
            Layout.leftMargin: 40
            visible: Config.options.dropdown.sections.stats
            spacing: 6
            Repeater {
                model: [
                    { "key": "cpu", "label": qsTr("CPU"), "icon": "developer_board" },
                    { "key": "gpu", "label": qsTr("GPU"), "icon": "memory" },
                    { "key": "ram", "label": qsTr("RAM"), "icon": "memory_alt" },
                    { "key": "swap", "label": qsTr("Swap"), "icon": "swap_horiz" },
                    { "key": "disk", "label": qsTr("Disk"), "icon": "hard_drive" },
                    { "key": "network", "label": qsTr("Network"), "icon": "swap_vert" }
                ]
                delegate: RippleButton {
                    id: statChip
                    required property var modelData
                    toggled: Config.options.dropdown.stats[modelData.key]
                    onClicked: Config.options.dropdown.stats[modelData.key] = !toggled
                    implicitHeight: 34
                    implicitWidth: chipRow.implicitWidth + 24
                    buttonRadius: Appearance.rounding.full
                    colBackground: Appearance.colors.colLayer2
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    colBackgroundToggled: Appearance.colors.colSecondaryContainer
                    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                    contentItem: Item {
                        RowLayout {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: 6
                            MaterialSymbol {
                                text: statChip.toggled ? "check" : statChip.modelData.icon
                                iconSize: Appearance.font.pixelSize.large
                                color: statChip.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer2
                            }
                            StyledText {
                                text: statChip.modelData.label
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: statChip.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer2
                            }
                        }
                    }
                }
            }
        }
        ConfigSwitch {
            buttonIcon: "notifications"
            text: qsTr("Notifications")
            checked: Config.options.dropdown.sections.notifications
            onCheckedChanged: Config.options.dropdown.sections.notifications = checked
        }
    }

    ContentSection {
        icon: "toggle_on"
        title: qsTr("Quick toggles")

        NoticeBox {
            Layout.fillWidth: true
            text: qsTr("Edit the toggles with the pencil button in the dropdown: click to add or remove, right-click to resize, scroll to move.")
        }
        ConfigSpinBox {
            icon: "view_column"
            text: qsTr("Columns")
            value: Config.options.dropdown.columns
            from: 2
            to: 6
            stepSize: 1
            onValueChanged: Config.options.dropdown.columns = value
        }
    }
}
