import QtQuick
import Qt5Compat.GraphicalEffects
import qs.core

/**
 * Liquid glass edge: a faint rim, a brighter specular highlight along the top and bottom edges,
 * and a soft sheen. Put it inside a rounded surface (it fills its parent); it only shows while
 * the glass look is on. Blur behind the surface is requested by the surface's window.
 */
Item {
    id: root
    property real radius: 0
    property real strength: 1
    anchors.fill: parent
    visible: Appearance.glass
    // Light glass on light themes needs a darker rim to stay visible
    readonly property color edge: Appearance.m3colors.darkmode ? "#ffffff" : "#000000"

    // Sheen: light falling from the top
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.10 * root.strength) }
            GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.04 * root.strength) }
        }
    }

    // Base rim all around
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(root.edge.r, root.edge.g, root.edge.b, 0.12 * root.strength)
    }

    // Specular highlight: a brighter rim, faded out towards the middle of the sides
    Rectangle {
        id: highlight
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: 1.5
        border.color: Qt.rgba(1, 1, 1, 0.55 * root.strength)
        visible: false
    }
    Rectangle {
        id: highlightMask
        anchors.fill: parent
        visible: false
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 1) }
            GradientStop { position: 0.35; color: Qt.rgba(0, 0, 0, 0) }
            GradientStop { position: 0.75; color: Qt.rgba(0, 0, 0, 0) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.5) }
        }
    }
    OpacityMask {
        anchors.fill: parent
        source: highlight
        maskSource: highlightMask
    }
}
