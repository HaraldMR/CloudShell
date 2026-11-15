import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs
import qs.services
import qs.core
import qs.widgets
import qs.core.functions

Item { // Bar content region
    id: root

    property var screen: root.QsWindow.window?.screen
    readonly property bool narrow: (screen?.width ?? 1920) <= Appearance.sizes.barShortenScreenWidthThreshold
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    // Hidden when nothing is playing; stays visible while paused
    readonly property bool showMedia: activePlayer !== null && (activePlayer.playbackState === MprisPlaybackState.Playing || activePlayer.playbackState === MprisPlaybackState.Paused)

    component VerticalBarSeparator: Rectangle {
        Layout.topMargin: Appearance.sizes.baseBarHeight / 3
        Layout.bottomMargin: Appearance.sizes.baseBarHeight / 3
        Layout.fillHeight: true
        implicitWidth: 1
        color: Appearance.colors.colOutlineVariant
    }

    // Background shadow
    Loader {
        active: Config.options.bar.showBackground && Config.options.bar.cornerStyle === 1 && Config.options.bar.floatStyleShadow
        anchors.fill: barBackground
        sourceComponent: StyledRectangularShadow {
            anchors.fill: undefined
            target: barBackground
        }
    }
    // Background
    Rectangle {
        id: barBackground
        anchors {
            fill: parent
            margins: Config.options.bar.cornerStyle === 1 ? (Appearance.sizes.hyprlandGapsOut) : 0
        }
        color: Config.options.bar.showBackground ? Appearance.colors.colLayer0 : "transparent"
        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0
        border.width: Config.options.bar.cornerStyle === 1 ? 1 : 0
        border.color: Appearance.colors.colLayer0Border
    }

    // Left: clock/date, then media
    RowLayout {
        id: leftSection
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            leftMargin: Appearance.rounding.screenRounding
        }
        spacing: 4

        RippleButton {
            id: clockButton
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: clockWidget.implicitWidth + 12 * 2
            implicitHeight: Appearance.sizes.baseBarHeight - 8
            buttonRadius: Appearance.rounding.full
            colBackground: ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
            colBackgroundHover: Appearance.colors.colLayer1Hover
            colRipple: Appearance.colors.colLayer1Active
            colBackgroundToggled: Appearance.colors.colSecondaryContainer
            colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
            colRippleToggled: Appearance.colors.colSecondaryContainerActive
            toggled: GlobalStates.calendarOpen
            onPressed: GlobalStates.calendarOpen = !GlobalStates.calendarOpen

            ClockWidget {
                id: clockWidget
                anchors.centerIn: parent
                showDate: Config.options.bar.verbose && !root.narrow
                textColor: clockButton.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
            }
        }

        VerticalBarSeparator {
            visible: Config.options.bar.borderless && root.showMedia
        }

        Revealer {
            reveal: root.showMedia
            Layout.alignment: Qt.AlignVCenter
            BarGroup {
                implicitWidth: Math.min(media.implicitWidth + padding * 2, root.narrow ? 220 : Appearance.sizes.barCenterSideModuleWidth)
                Media {
                    id: media
                    Layout.fillWidth: true
                }
            }
        }
    }

    // Center: workspaces / app overview (unchanged from ii)
    Row {
        id: middleSection
        anchors {
            top: parent.top
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 4

        BarGroup {
            id: middleCenterGroup
            anchors.verticalCenter: parent.verticalCenter

            Workspaces {
                id: workspacesWidget
                Layout.fillHeight: true
                MouseArea {
                    // Right-click to toggle overview
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onPressed: event => {
                        if (event.button === Qt.RightButton)
                            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
                    }
                }
            }
        }
    }

    // Right: tray + status indicators (opens the dropdown)
    RowLayout {
        id: rightSection
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
            rightMargin: Appearance.rounding.screenRounding
        }
        spacing: 5
        layoutDirection: Qt.RightToLeft

        RippleButton {
            id: dropdownButton

            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            Layout.fillWidth: false

            implicitWidth: indicatorsRowLayout.implicitWidth + 10 * 2
            implicitHeight: indicatorsRowLayout.implicitHeight + 5 * 2

            buttonRadius: Appearance.rounding.full
            colBackground: ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
            colBackgroundHover: Appearance.colors.colLayer1Hover
            colRipple: Appearance.colors.colLayer1Active
            colBackgroundToggled: Appearance.colors.colSecondaryContainer
            colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
            colRippleToggled: Appearance.colors.colSecondaryContainerActive
            toggled: GlobalStates.dropdownOpen
            property color colText: toggled ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer0

            Behavior on colText {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }

            onPressed: GlobalStates.dropdownOpen = !GlobalStates.dropdownOpen

            RowLayout {
                id: indicatorsRowLayout
                anchors.centerIn: parent
                property real realSpacing: 15
                spacing: 0

                Revealer {
                    reveal: Audio.sink?.audio?.muted ?? false
                    Layout.fillHeight: true
                    Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                    Behavior on Layout.rightMargin {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                    MaterialSymbol {
                        text: "volume_off"
                        iconSize: Appearance.font.pixelSize.larger
                        color: dropdownButton.colText
                    }
                }
                Revealer {
                    reveal: Audio.source?.audio?.muted ?? false
                    Layout.fillHeight: true
                    Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                    Behavior on Layout.rightMargin {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                    MaterialSymbol {
                        text: "mic_off"
                        iconSize: Appearance.font.pixelSize.larger
                        color: dropdownButton.colText
                    }
                }
                HyprlandXkbIndicator {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.rightMargin: indicatorsRowLayout.realSpacing
                    color: dropdownButton.colText
                }
                Revealer {
                    reveal: Notifications.dnd || Notifications.unread > 0
                    Layout.fillHeight: true
                    Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                    implicitHeight: reveal ? notificationUnreadCount.implicitHeight : 0
                    implicitWidth: reveal ? notificationUnreadCount.implicitWidth : 0
                    Behavior on Layout.rightMargin {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                    NotificationUnreadCount {
                        id: notificationUnreadCount
                        color: dropdownButton.colText
                    }
                }
                MaterialSymbol {
                    text: Network.materialSymbol
                    iconSize: Appearance.font.pixelSize.larger
                    color: dropdownButton.colText
                }
                MaterialSymbol {
                    Layout.leftMargin: indicatorsRowLayout.realSpacing
                    visible: BluetoothStatus.available
                    text: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
                    iconSize: Appearance.font.pixelSize.larger
                    color: dropdownButton.colText
                }
                BatteryIndicator {
                    Layout.leftMargin: indicatorsRowLayout.realSpacing
                    Layout.alignment: Qt.AlignVCenter
                    visible: Battery.available
                    implicitHeight: indicatorsRowLayout.implicitHeight
                }
            }
        }

        SysTray {
            visible: !root.narrow
            Layout.fillWidth: false
            Layout.fillHeight: true
            invertSide: Config?.options.bar.bottom
        }
    }
}
