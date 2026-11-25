import QtQuick
import "../services"

Rectangle {
    id: card

    property real radiusValue: 14
    property bool highlighted: false
    property bool strong: false
    property real glassAlpha: strong ? 0.90 : 0.80

    radius: radiusValue
    color: strong
        ? Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, glassAlpha)
        : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, glassAlpha)
    border.width: 1
    border.color: highlighted ? Theme.accentBorder : Theme.glassBorder

    Behavior on border.color {
        ColorAnimation { duration: Theme.animFast }
    }
    Behavior on color {
        ColorAnimation { duration: Theme.animFast }
    }
}
