import QtQuick
import QtQuick.Effects
import qs.core

RectangularShadow {
    required property var target
    anchors.fill: target
    radius: target.radius
    blur: 0.9 * Appearance.sizes.elevationMargin
    offset: Qt.vector2d(0.0, 1.0)
    spread: 1
    color: Appearance.colors.colShadow
    cached: true
    // Glass surfaces are see-through, a shadow underneath would darken them
    visible: !Appearance.glass
}
