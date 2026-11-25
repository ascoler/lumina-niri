import QtQuick
import "../services"

Rectangle {
    id: card

    property real radiusValue: 14
    property real topLeftRad: radiusValue
    property real topRightRad: radiusValue
    property real bottomLeftRad: radiusValue
    property real bottomRightRad: radiusValue

    property bool highlighted: false
    property bool strong: false
    property bool specular: true
    property real glassAlpha: strong ? 0.90 : 0.80
    property color customBorderColor: "transparent"

    topLeftRadius: topLeftRad
    topRightRadius: topRightRad
    bottomLeftRadius: bottomLeftRad
    bottomRightRadius: bottomRightRad

    color: strong
        ? Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, glassAlpha)
        : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, glassAlpha)
    border.width: 1
    border.color: customBorderColor.a > 0
        ? customBorderColor
        : (highlighted ? Theme.accentBorder : Theme.glassBorder)

    Behavior on border.color {
        ColorAnimation { duration: Theme.animFast }
    }
    Behavior on color {
        ColorAnimation { duration: Theme.animFast }
    }

    // Subtle liquid-glass top specular sheen
    Rectangle {
        visible: card.specular && card.height >= 20 && card.width >= 20
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 1
        height: Math.min(20, parent.height * 0.42)
        topLeftRadius: Math.max(0, card.topLeftRad - 1)
        topRightRadius: Math.max(0, card.topRightRad - 1)
        bottomLeftRadius: 2
        bottomRightRadius: 2
        z: 0
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, card.highlighted ? 0.12 : 0.07) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }
}
