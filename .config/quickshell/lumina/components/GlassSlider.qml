import QtQuick
import "../services"

Item {
    id: slider

    property real value: 0.5
    property color fillColor: Theme.accent
    property bool interactive: true
    signal moved(real newValue)

    implicitHeight: 26
    implicitWidth: 200

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 8
        radius: 4
        color: Qt.rgba(1, 1, 1, 0.10)

        Rectangle {
            width: Math.max(height, Math.min(1, Math.max(0, slider.value)) * parent.width)
            height: parent.height
            radius: 4
            color: slider.fillColor

            Behavior on width {
                enabled: !mouse.pressed
                NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
            }
        }
    }

    Rectangle {
        id: knob
        width: mouse.containsMouse || mouse.pressed ? 16 : 12
        height: width
        radius: width / 2
        color: Theme.fg
        border.width: 2
        border.color: slider.fillColor
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(slider.width - width, slider.value * (slider.width - width)))

        Behavior on width {
            NumberAnimation { duration: 100 }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: slider.interactive
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        function emitAt(mx) {
            const v = Math.max(0, Math.min(1, mx / width));
            slider.moved(v);
        }

        onPressed: (m) => emitAt(m.x)
        onPositionChanged: (m) => { if (pressed) emitAt(m.x); }
        onWheel: (w) => {
            const delta = w.angleDelta.y > 0 ? 0.04 : -0.04;
            slider.moved(Math.max(0, Math.min(1, slider.value + delta)));
        }
    }
}
