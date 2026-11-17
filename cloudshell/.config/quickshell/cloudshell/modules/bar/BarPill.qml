import QtQuick
import QtQuick.Layouts
import qs.core
import qs.widgets
import qs.core.functions

/**
 * Pill-shaped background behind a group of bar items. Its look comes from Config.options.bar.pills;
 * with liquid glass on it becomes a glass pill (the bar window blurs behind `background`).
 */
Item {
    id: root
    // Per-group switch (bar.pills.clock, .media, ...)
    property bool shown: true
    property real horizontalPadding: 3
    property real leftPadding: horizontalPadding
    property real rightPadding: horizontalPadding
    default property alias content: row.data
    property alias spacing: row.spacing
    readonly property bool active: Config.options.bar.pills.enable && shown
    readonly property Item background: background

    readonly property real pillHeight: Appearance.sizes.baseBarHeight - 6
    readonly property color baseColor: {
        switch (Config.options.bar.pills.style) {
        case "tonal":
            return Appearance.m3colors.m3secondaryContainer;
        case "primary":
            return Appearance.m3colors.m3primaryContainer;
        default:
            return Appearance.m3colors.m3surfaceContainer;
        }
    }

    implicitWidth: row.implicitWidth + (active ? leftPadding + rightPadding : 0)
    implicitHeight: Math.max(row.implicitHeight, pillHeight)

    Rectangle {
        id: background
        visible: root.active
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.pillHeight
        radius: height / 2
        color: ColorUtils.transparentize(root.baseColor, 1 - Config.options.bar.pills.opacity * (Appearance.glass ? Appearance.glassOpacity : 1))
        border.width: Config.options.bar.pills.outline && !Appearance.glass ? 1 : 0
        border.color: Appearance.colors.colOutlineVariant
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        GlassRim {
            radius: background.radius
            strength: 0.8
        }
    }

    RowLayout {
        id: row
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            leftMargin: root.active ? root.leftPadding : 0
        }
        spacing: 4
    }
}
