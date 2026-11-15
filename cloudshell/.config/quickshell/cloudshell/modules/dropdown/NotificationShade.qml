import qs
import qs.core
import qs.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

// Pixel-style notification shade: alerting notifications grouped by app, then a "Silent" section
ColumnLayout {
    id: root
    property real maxHeight: 600
    readonly property bool empty: Notifications.list.length === 0
    readonly property real listsHeight: alertingList.contentHeight + (silentSection.visible ? silentHeader.implicitHeight + silentList.contentHeight + 8 : 0)
    spacing: 8

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 6
        spacing: 4

        StyledText {
            text: qsTr("Notifications")
            font.pixelSize: Appearance.font.pixelSize.larger
            font.family: Appearance.font.family.title
            color: Appearance.colors.colOnLayer0
        }
        MaterialSymbol {
            visible: Notifications.dnd
            text: "do_not_disturb_on"
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colPrimary
        }
        Item {
            Layout.fillWidth: true
        }
        HeaderButton {
            iconName: "history"
            text: qsTr("History")
            onClicked: {
                GlobalStates.dropdownOpen = false;
                GlobalStates.openSettings("notifications");
            }
        }
        HeaderButton {
            visible: !root.empty
            iconName: "clear_all"
            text: qsTr("Clear all")
            onClicked: Notifications.discardAllNotifications()
        }
    }

    StyledFlickable {
        id: flickable
        Layout.fillWidth: true
        Layout.preferredHeight: root.empty ? placeholder.implicitHeight : Math.min(root.listsHeight, root.maxHeight)
        contentHeight: listsColumn.implicitHeight
        clip: true
        visible: !root.empty

        ColumnLayout {
            id: listsColumn
            width: flickable.width
            spacing: 8

            NotificationListView {
                id: alertingList
                Layout.fillWidth: true
                Layout.preferredHeight: contentHeight
                interactive: false
                section: "alerting"
            }

            ColumnLayout {
                id: silentSection
                Layout.fillWidth: true
                visible: Notifications.silentAppNameList.length > 0
                spacing: 4

                RowLayout {
                    id: silentHeader
                    Layout.fillWidth: true
                    Layout.leftMargin: 6
                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Silent")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                    HeaderButton {
                        iconName: "close"
                        text: qsTr("Clear")
                        onClicked: Notifications.discardSilentNotifications()
                    }
                }

                NotificationListView {
                    id: silentList
                    Layout.fillWidth: true
                    Layout.preferredHeight: contentHeight
                    interactive: false
                    section: "silent"
                }
            }
        }
    }

    Item {
        id: placeholder
        visible: root.empty
        Layout.fillWidth: true
        implicitHeight: 72
        RowLayout {
            anchors.centerIn: parent
            spacing: 8
            MaterialSymbol {
                text: "notifications_none"
                iconSize: Appearance.font.pixelSize.huge
                color: Appearance.colors.colSubtext
            }
            StyledText {
                text: Notifications.snoozed.length > 0 ? qsTr("No notifications · %1 snoozed").arg(Notifications.snoozed.length) : qsTr("No notifications")
                color: Appearance.colors.colSubtext
            }
        }
    }

    component HeaderButton: RippleButton {
        id: headerButton
        property string iconName
        implicitHeight: 30
        implicitWidth: headerRow.implicitWidth + 20
        buttonRadius: Appearance.rounding.full
        colBackground: Appearance.colors.colLayer1
        colBackgroundHover: Appearance.colors.colLayer1Hover
        colRipple: Appearance.colors.colLayer1Active
        contentItem: Item {
            RowLayout {
                id: headerRow
                anchors.centerIn: parent
                spacing: 4
                MaterialSymbol {
                    text: headerButton.iconName
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    text: headerButton.text
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnLayer1
                }
            }
        }
    }
}
