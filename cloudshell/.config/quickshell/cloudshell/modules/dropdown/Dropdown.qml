import qs
import qs.services
import qs.core
import qs.widgets
import qs.core.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Hyprland

import qs.modules.dropdown.quickToggles
import qs.modules.dropdown.bluetoothDevices
import qs.modules.dropdown.volumeMixer
import qs.modules.dropdown.wifiNetworks

/**
 * Quick settings dropdown (top right), based on the tripathiji1312 control center:
 * header with clock and actions, Pixel-style quick toggles, sliders, stats and the notification shade.
 */
DropdownWindow {
    id: root
    open: GlobalStates.dropdownOpen
    alignRight: true
    panelWidth: Appearance.sizes.dropdownWidth
    namespace: "cloudshell:dropdown"
    onDismissed: GlobalStates.dropdownOpen = false

    property bool editMode: false
    property bool showAudioOutputDialog: false
    property bool showAudioInputDialog: false
    property bool showBluetoothDialog: false
    property bool showDndDialog: false
    property bool showWifiDialog: false
    readonly property bool anyDialog: showAudioOutputDialog || showAudioInputDialog || showBluetoothDialog || showDndDialog || showWifiDialog
    minimumPanelHeight: anyDialog ? 660 : 0
    contentHeight: mainColumn.implicitHeight

    onOpenChanged: {
        if (!open) {
            showWifiDialog = false;
            showBluetoothDialog = false;
            showAudioOutputDialog = false;
            showAudioInputDialog = false;
            showDndDialog = false;
            editMode = false;
        }
    }

    ColumnLayout {
        id: mainColumn
        anchors {
            left: parent.left
            right: parent.right
        }
        spacing: 10

        // Header: clock + actions
        RowLayout {
            id: headerRow
            Layout.fillWidth: true
            Layout.leftMargin: 6
            spacing: 6

            ColumnLayout {
                spacing: -2
                StyledText {
                    text: DateTime.time
                    font.pixelSize: 34
                    font.family: Appearance.font.family.numbers
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer0
                }
                StyledText {
                    text: Qt.locale().toString(DateTime.clock.date, "dddd d MMMM")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
            }
            Item {
                Layout.fillWidth: true
            }
            HeaderIconButton {
                iconName: "edit"
                toggled: root.editMode
                tooltip: root.editMode ? qsTr("Done editing\nClick: add/remove · Right-click: resize · Scroll: move") : qsTr("Edit quick toggles")
                onClicked: root.editMode = !root.editMode
            }
            HeaderIconButton {
                iconName: "settings"
                tooltip: qsTr("Settings")
                onClicked: {
                    GlobalStates.dropdownOpen = false;
                    GlobalStates.openSettings("");
                }
            }
            HeaderIconButton {
                iconName: "power_settings_new"
                tooltip: qsTr("Power")
                onClicked: {
                    GlobalStates.dropdownOpen = false;
                    GlobalStates.sessionOpen = true;
                }
            }
        }

        AndroidQuickPanel {
            id: quickPanel
            Layout.fillWidth: true
            editMode: root.editMode
            onOpenAudioOutputDialog: root.showAudioOutputDialog = true
            onOpenAudioInputDialog: root.showAudioInputDialog = true
            onOpenBluetoothDialog: root.showBluetoothDialog = true
            onOpenDndDialog: root.showDndDialog = true
            onOpenWifiDialog: root.showWifiDialog = true
        }

        QuickSliders {
            id: sliders
            Layout.fillWidth: true
            visible: hasContent
            onOpenAudioOutputDialog: root.showAudioOutputDialog = true
            onOpenAudioInputDialog: root.showAudioInputDialog = true
        }

        StatsRow {
            id: stats
            Layout.fillWidth: true
            visible: Config.options.dropdown.sections.stats && count > 0
        }

        NotificationShade {
            id: shade
            Layout.fillWidth: true
            visible: Config.options.dropdown.sections.notifications
            // Whatever room is left on screen goes to the notification list.
            // Computed from the other sections only (never from the shade itself) to avoid a layout feedback loop.
            readonly property real otherSectionsHeight: headerRow.implicitHeight + quickPanel.implicitHeight
                + (sliders.visible ? sliders.implicitHeight + mainColumn.spacing : 0)
                + (stats.visible ? stats.implicitHeight + mainColumn.spacing : 0)
                + mainColumn.spacing * 2
            maxHeight: Math.max(160, root.availableContentHeight - otherSectionsHeight - 50)
        }
    }

    ToggleDialog {
        shownPropertyString: "showAudioOutputDialog"
        dialog: VolumeDialog {
            isSink: true
        }
    }

    ToggleDialog {
        shownPropertyString: "showAudioInputDialog"
        dialog: VolumeDialog {
            isSink: false
        }
    }

    ToggleDialog {
        shownPropertyString: "showBluetoothDialog"
        dialog: BluetoothDialog {}
        onShownChanged: {
            if (!Bluetooth.defaultAdapter)
                return;
            if (!shown) {
                Bluetooth.defaultAdapter.discovering = false;
            } else {
                Bluetooth.defaultAdapter.enabled = true;
                Bluetooth.defaultAdapter.discovering = true;
            }
        }
    }

    ToggleDialog {
        shownPropertyString: "showDndDialog"
        dialog: DndDialog {}
    }

    ToggleDialog {
        shownPropertyString: "showWifiDialog"
        dialog: WifiDialog {}
        onShownChanged: {
            if (!shown)
                return;
            Network.enableWifi();
            Network.rescanWifi();
        }
    }

    component ToggleDialog: Loader {
        id: toggleDialogLoader
        required property string shownPropertyString
        property alias dialog: toggleDialogLoader.sourceComponent
        readonly property bool shown: root[shownPropertyString]
        x: 0
        y: 0
        width: root.contentWidth
        height: root.currentContentHeight

        onShownChanged: if (shown)
            toggleDialogLoader.active = true
        active: shown
        onActiveChanged: {
            if (active) {
                item.show = true;
                item.forceActiveFocus();
            }
        }
        Connections {
            target: toggleDialogLoader.item
            function onDismiss() {
                toggleDialogLoader.item.show = false;
                root[toggleDialogLoader.shownPropertyString] = false;
            }
            function onVisibleChanged() {
                if (!toggleDialogLoader.item.visible && !root[toggleDialogLoader.shownPropertyString])
                    toggleDialogLoader.active = false;
            }
        }
    }

    component HeaderIconButton: RippleButton {
        id: headerButton
        property string iconName
        property string tooltip
        implicitWidth: 40
        implicitHeight: 40
        buttonRadius: toggled ? Appearance.rounding.normal : Appearance.rounding.full
        colBackground: Appearance.colors.colLayer1
        colBackgroundHover: Appearance.colors.colLayer1Hover
        colRipple: Appearance.colors.colLayer1Active
        contentItem: MaterialSymbol {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            text: headerButton.iconName
            iconSize: 20
            fill: headerButton.toggled ? 1 : 0
            color: headerButton.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer1
        }
        StyledToolTip {
            text: headerButton.tooltip
        }
    }
}
