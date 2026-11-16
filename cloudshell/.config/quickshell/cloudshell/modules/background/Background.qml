pragma ComponentBehavior: Bound
import qs.core
import qs.services
import QtQuick
import Quickshell
import Quickshell.Wayland

/**
 * Draws the wallpaper (Settings > Wallpaper & style) on every monitor, but only while skwd-wall
 * isn't running. With skwd-wall, its daemon draws the wallpaper and this stays hidden.
 */
Scope {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window
            required property ShellScreen modelData
            screen: modelData
            visible: Wallpaper.selfDrawn
            color: Appearance.m3colors.m3background

            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "cloudshell:background"
            exclusionMode: ExclusionMode.Ignore
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Image {
                id: image
                anchors.fill: parent
                source: Wallpaper.selfDrawn ? `file://${Wallpaper.imagePath}` : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                smooth: true
                // Decode at screen size instead of the full image
                sourceSize: Qt.size(window.screen.width, window.screen.height)
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }
    }
}
