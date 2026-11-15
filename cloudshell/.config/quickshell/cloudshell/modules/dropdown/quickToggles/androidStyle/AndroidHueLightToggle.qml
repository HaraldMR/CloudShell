import qs.core
import qs.core.models.quickToggles
import qs.core.functions
import qs.widgets
import qs.services
import Qt5Compat.GraphicalEffects
import QtQuick
import Quickshell

AndroidQuickToggleButton {
    id: root
    toggleModel: HueLightToggle {
        id: lightModel
    }

    // Brightness shown while dragging, before the bridge confirms it
    property bool dragging: false
    property real dragValue: 0
    readonly property real shownValue: dragging ? dragValue : (toggled ? lightModel.brightness : 0)
    statusText: dragging ? (dragValue > 0 ? `${Math.round(dragValue)}%` : qsTr("Off")) : lightModel.statusText

    colBackgroundToggled: Appearance.colors.colLayer2
    colBackgroundToggledHover: Appearance.colors.colLayer2Hover
    colBackgroundToggledActive: Appearance.colors.colLayer2Active
    colText: ColorUtils.transparentize(Appearance.colors.colOnLayer2, enabled ? 0 : 0.7)
    colIcon: (toggled || dragging) && enabled ? Appearance.colors.colOnPrimaryContainer : colText

    background: Rectangle {
        id: tileBackground
        topLeftRadius: root.leftRadius
        bottomLeftRadius: root.leftRadius
        topRightRadius: root.rightRadius
        bottomRightRadius: root.rightRadius
        color: root.color
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: tileBackground.width
                height: tileBackground.height
                topLeftRadius: tileBackground.topLeftRadius
                bottomLeftRadius: tileBackground.bottomLeftRadius
                topRightRadius: tileBackground.topRightRadius
                bottomRightRadius: tileBackground.bottomRightRadius
            }
        }

        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            // Never narrower than the tile height so the icon always sits on the fill while on
            width: root.shownValue > 0 ? Math.max(parent.height, parent.width * root.shownValue / 100) : 0
            color: Appearance.colors.colPrimaryContainer
            Behavior on width {
                enabled: !root.dragging
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
            }
        }
    }

    MouseArea {
        id: sliderInteraction
        visible: !root.editMode
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        preventStealing: true

        readonly property real dragThreshold: 6
        property real pressX: 0
        property real startValue: 0

        onPressed: event => {
            root.down = true;
            pressX = event.x;
            startValue = root.toggled ? lightModel.brightness : 0;
        }
        onPositionChanged: event => {
            if (!pressed)
                return;
            if (!root.dragging) {
                if (Math.abs(event.x - pressX) < dragThreshold)
                    return;
                pressX = event.x;
                root.dragValue = startValue;
                root.dragging = true;
            }
            const value = Math.max(0, Math.min(100, startValue + (event.x - pressX) / root.width * 100));
            if (Math.round(value) === Math.round(root.dragValue))
                return;
            root.dragValue = value;
            lightModel.setBrightness(value);
        }
        onReleased: event => {
            root.down = false;
            if (root.dragging) {
                lightModel.setBrightness(root.dragValue);
                root.dragging = false;
            } else if (root.enabled) {
                lightModel.mainAction();
            }
        }
        onCanceled: {
            root.down = false;
            root.dragging = false;
        }
    }
}
