import qs
import qs.services
import qs.core
import qs.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

WindowDialog {
    id: root
    backgroundHeight: 460

    readonly property list<var> choices: [
        { "label": qsTr("Until you turn it off"), "minutes": 0 },
        { "label": qsTr("For 15 minutes"), "minutes": 15 },
        { "label": qsTr("For 1 hour"), "minutes": 60 },
        { "label": qsTr("For 8 hours"), "minutes": 480 },
        { "label": qsTr("Until 07:00"), "minutes": -1 }
    ]

    WindowDialogTitle {
        text: qsTr("Do Not Disturb")
    }
    WindowDialogParagraph {
        text: qsTr("Notifications still arrive in the shade, but don't pop up. Critical ones still show.")
    }
    WindowDialogSeparator {}
    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: -Appearance.rounding.large
        Layout.rightMargin: -Appearance.rounding.large
        spacing: 0

        Repeater {
            model: root.choices
            DialogListItem {
                required property var modelData
                Layout.fillWidth: true
                onClicked: {
                    Notifications.setDnd(true, modelData.minutes);
                    root.dismiss();
                }
                contentItem: RowLayout {
                    spacing: 12
                    MaterialSymbol {
                        text: modelData.minutes === 0 ? "do_not_disturb_on" : "schedule"
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: modelData.label
                        color: Appearance.colors.colOnLayer3
                    }
                }
            }
        }
    }
    WindowDialogSeparator {}
    WindowDialogButtonRow {
        DialogButton {
            buttonText: qsTr("Settings")
            onClicked: {
                GlobalStates.dropdownOpen = false;
                GlobalStates.openSettings("notifications");
            }
        }
        Item {
            Layout.fillWidth: true
        }
        DialogButton {
            visible: Notifications.dnd
            buttonText: qsTr("Turn off")
            onClicked: {
                Notifications.setDnd(false, 0);
                root.dismiss();
            }
        }
        DialogButton {
            buttonText: qsTr("Done")
            onClicked: root.dismiss()
        }
    }
}
