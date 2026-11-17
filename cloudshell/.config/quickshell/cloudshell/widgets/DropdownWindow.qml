import qs
import qs.core
import qs.services
import qs.widgets
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * A Material 3 surface that drops down from the bar on the focused monitor.
 * Closes on Escape and on clicks outside. Used by the calendar and the quick settings dropdown.
 *
 * The window itself has a fixed size (the most the panel can grow to) and an input mask on the
 * visible surface. Only the surface animates, so growing/shrinking never resizes the Wayland
 * window every frame, which is what made the animation stutter.
 */
PanelWindow {
    id: root

    required property bool open
    property bool alignRight: true
    property real panelWidth: 400
    property real minimumPanelHeight: 0
    property real maxPanelHeight: (screen?.height ?? 1080) - Appearance.sizes.barHeight - 24
    property string namespace: "cloudshell:dropdown"
    property real padding: 14
    // Height of the content (set by the user of this component)
    property real contentHeight: 0
    default property alias contentData: contentArea.data
    readonly property real contentWidth: panelWidth - padding * 2
    readonly property real availableContentHeight: maxPanelHeight - padding * 2
    readonly property real targetPanelHeight: Math.min(Math.max(contentHeight + padding * 2, minimumPanelHeight), maxPanelHeight)
    // Height of the content area right now (follows the animated surface)
    readonly property real currentContentHeight: surface.height - padding * 2
    signal dismissed

    // Space for the elevation shadow around the surface
    readonly property real shadowMargin: Appearance.sizes.elevationMargin

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
    visible: open || surface.opacity > 0
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.namespace: root.namespace
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    anchors {
        top: true
        right: root.alignRight
        left: !root.alignRight
    }
    margins {
        top: 0
        right: root.alignRight ? Appearance.sizes.hyprlandGapsOut : 0
        left: root.alignRight ? 0 : Appearance.sizes.hyprlandGapsOut
    }

    implicitWidth: panelWidth + shadowMargin * 2
    implicitHeight: maxPanelHeight + shadowMargin * 2

    mask: Region {
        item: surface
    }
    // Liquid glass: blur what's behind the surface
    BackgroundEffect.blurRegion: Appearance.glass ? glassRegion : null
    Region {
        id: glassRegion
        item: surface
        radius: surface.radius
    }

    function dismiss() {
        root.dismissed();
    }

    // The focus grab only works once the surface is mapped
    function updateGrab() {
        if (root.open && root.visible)
            grabDelay.restart();
        else
            GlobalFocusGrab.removeDismissable(root);
    }
    onOpenChanged: updateGrab()
    onVisibleChanged: updateGrab()
    Timer {
        id: grabDelay
        interval: 50
        onTriggered: if (root.open)
            GlobalFocusGrab.addDismissable(root)
    }
    Connections {
        target: GlobalFocusGrab
        function onDismissed() {
            if (root.open)
                root.dismiss();
        }
    }

    StyledRectangularShadow {
        target: surface
        opacity: surface.opacity
    }

    Rectangle {
        id: surface
        x: root.shadowMargin
        y: root.shadowMargin + (root.open ? 0 : -16)
        width: root.panelWidth
        height: root.targetPanelHeight
        radius: Appearance.rounding.verylarge
        color: Appearance.colors.colLayer0
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        clip: true

        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.94
        transformOrigin: root.alignRight ? Item.TopRight : Item.TopLeft

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on scale {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
        Behavior on y {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
        // Expressive spatial spring: quick, with a slight settle
        Behavior on height {
            enabled: root.open
            NumberAnimation {
                duration: Appearance.animationCurves.expressiveFastSpatialDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
            }
        }

        GlassRim {
            radius: surface.radius
        }

        Item {
            id: contentArea
            anchors {
                fill: parent
                margins: root.padding
            }
            focus: root.open
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.dismiss();
                    event.accepted = true;
                }
            }
        }
    }
}
