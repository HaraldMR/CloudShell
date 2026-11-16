pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.core
import qs.widgets

ContentPage {
    forceWidth: true

    readonly property list<var> modules: [
        { "id": "background", "name": qsTr("Wallpaper without skwd-wall"), "icon": "image" },
        { "id": "bar", "name": qsTr("Top bar"), "icon": "toolbar" },
        { "id": "dropdown", "name": qsTr("Quick settings dropdown"), "icon": "toggle_on" },
        { "id": "calendar", "name": qsTr("Calendar dropdown"), "icon": "calendar_month" },
        { "id": "notificationPopups", "name": qsTr("Notification popups"), "icon": "notifications" },
        { "id": "overview", "name": qsTr("Super window (search + overview)"), "icon": "overview_key" },
        { "id": "osd", "name": qsTr("Volume / brightness popup"), "icon": "volume_up" },
        { "id": "session", "name": qsTr("Power menu"), "icon": "power_settings_new" },
        { "id": "polkit", "name": qsTr("Password prompt (polkit)"), "icon": "password" },
        { "id": "mediaControls", "name": qsTr("Media controls (Super+M)"), "icon": "music_note" },
        { "id": "regionSelector", "name": qsTr("Screenshot / OCR region selector"), "icon": "screenshot_region" },
        { "id": "gameBar", "name": qsTr("Game bar (Super+G)"), "icon": "sports_esports" },
        { "id": "wallpaper", "name": qsTr("Wallpaper (skwd-wall)"), "icon": "wallpaper" },
        { "id": "theming", "name": qsTr("Colours from wallpaper (matugen)"), "icon": "palette" }
    ]

    ContentSection {
        icon: "widgets"
        title: qsTr("Modules")

        StyledText {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            color: Appearance.colors.colSubtext
            text: qsTr("\"Auto\" turns a module on only when the programs it needs are installed. Changes apply immediately.")
        }

        Repeater {
            model: modules
            delegate: RowLayout {
                id: moduleRow
                required property var modelData
                readonly property var missing: Deps.missingFor(modelData.id)
                Layout.fillWidth: true
                spacing: 10

                MaterialSymbol {
                    text: moduleRow.modelData.icon
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnLayer1
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    StyledText {
                        Layout.fillWidth: true
                        text: moduleRow.modelData.name
                        color: Appearance.colors.colOnLayer1
                    }
                    StyledText {
                        Layout.fillWidth: true
                        visible: moduleRow.missing.length > 0
                        wrapMode: Text.Wrap
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colError
                        text: qsTr("Missing: %1").arg(moduleRow.missing.map(b => `${b} (${Deps.packageHints[b] ?? b})`).join(", "))
                    }
                    StyledText {
                        visible: moduleRow.missing.length === 0
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        text: Deps.moduleEnabled(moduleRow.modelData.id) ? qsTr("Running") : qsTr("Off")
                    }
                }
                ConfigSelectionArray {
                    Layout.fillWidth: false
                    currentValue: {
                        const v = Config.options.modules[moduleRow.modelData.id];
                        return (v === true || v === "true") ? "on" : (v === false || v === "false") ? "off" : "auto";
                    }
                    onSelected: newValue => {
                        Config.options.modules[moduleRow.modelData.id] = newValue === "on" ? true : newValue === "off" ? false : "auto";
                    }
                    options: [
                        { "displayName": qsTr("Auto"), "icon": "auto_mode", "value": "auto" },
                        { "displayName": qsTr("On"), "icon": "check", "value": "on" },
                        { "displayName": qsTr("Off"), "icon": "close", "value": "off" }
                    ]
                }
            }
        }
    }

    ContentSection {
        icon: "inventory_2"
        title: qsTr("Detected programs")

        RippleButtonWithIcon {
            materialIcon: "refresh"
            mainText: qsTr("Check again")
            onClicked: Deps.refresh()
        }
        Flow {
            Layout.fillWidth: true
            spacing: 6
            Repeater {
                model: Deps.binaries
                delegate: Rectangle {
                    id: chip
                    required property string modelData
                    readonly property bool present: Deps.has(modelData)
                    implicitWidth: chipRow.implicitWidth + 16
                    implicitHeight: 28
                    radius: height / 2
                    color: present ? Appearance.colors.colSecondaryContainer : Appearance.colors.colErrorContainer
                    RowLayout {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 4
                        MaterialSymbol {
                            text: chip.present ? "check" : "close"
                            iconSize: Appearance.font.pixelSize.normal
                            color: chip.present ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnErrorContainer
                        }
                        StyledText {
                            text: chip.modelData
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: chip.present ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnErrorContainer
                        }
                    }
                }
            }
        }
    }
}
