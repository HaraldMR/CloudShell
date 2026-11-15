import qs.core
import qs.widgets
import qs.services
import qs
import qs.core.functions

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Hyprland

Item {
    id: root
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || qsTr("No media")
    readonly property bool toggled: GlobalStates.mediaControlsOpen
    readonly property color colText: toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1

    implicitWidth: rowLayout.implicitWidth + 12 * 2
    implicitHeight: Appearance.sizes.barHeight

    Timer {
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: activePlayer.positionChanged()
    }

    // Hover/toggled pill, same style as the clock and status buttons
    Rectangle {
        id: background
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        height: Appearance.sizes.baseBarHeight - 8
        radius: Appearance.rounding.full
        color: root.toggled ? (mouseArea.containsMouse ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colSecondaryContainer) : mouseArea.pressed ? Appearance.colors.colLayer1Active : mouseArea.containsMouse ? Appearance.colors.colLayer1Hover : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
        onPressed: event => {
            if (event.button === Qt.MiddleButton) {
                activePlayer.togglePlaying();
            } else if (event.button === Qt.BackButton) {
                activePlayer.previous();
            } else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
                activePlayer.next();
            } else if (event.button === Qt.LeftButton) {
                GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen;
            }
        }
    }

    RowLayout {
        id: rowLayout
        spacing: 6
        anchors {
            fill: parent
            leftMargin: 12
            rightMargin: 12
        }

        ClippedFilledCircularProgress {
            id: mediaCircProg
            Layout.alignment: Qt.AlignVCenter
            lineWidth: Appearance.rounding.unsharpen
            value: activePlayer?.position / activePlayer?.length
            implicitSize: 20
            colPrimary: root.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnSecondaryContainer
            enableAnimation: false

            Item {
                anchors.centerIn: parent
                width: mediaCircProg.implicitSize
                height: mediaCircProg.implicitSize

                MaterialSymbol {
                    anchors.centerIn: parent
                    fill: 1
                    text: activePlayer?.isPlaying ? "pause" : "music_note"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.m3colors.m3onSecondaryContainer
                }
            }
        }

        StyledText {
            visible: Config.options.bar.verbose
            Layout.alignment: Qt.AlignVCenter
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignLeft
            elide: Text.ElideRight
            color: root.colText
            text: `${cleanedTitle}${activePlayer?.trackArtist ? ' • ' + activePlayer.trackArtist : ''}`
        }
    }
}
