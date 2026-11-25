import QtQuick
import "../services"

Row {
    id: eqRoot

    property bool active: false
    property color barColor: Theme.accent
    property color peakColor: Theme.tertiary
    property int barCount: 4
    property real barWidth: 2.5
    property real maxHeight: 14

    spacing: 2
    height: maxHeight

    Repeater {
        model: eqRoot.barCount

        delegate: Item {
            required property int index
            width: eqRoot.barWidth
            height: eqRoot.maxHeight

            readonly property int dur: 220 + (index * 73) % 190
            readonly property real minH: 3
            readonly property real midH: Math.max(4, eqRoot.maxHeight * (0.45 + ((index * 3) % 4) * 0.12))
            readonly property real highH: Math.max(6, eqRoot.maxHeight * (0.72 + (index % 2) * 0.25))

            Rectangle {
                id: barRect
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: eqRoot.barWidth
                radius: eqRoot.barWidth / 2
                height: minH
                color: height > eqRoot.maxHeight * 0.72 ? eqRoot.peakColor : eqRoot.barColor

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on height {
                    enabled: !eqRoot.active
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }

                SequentialAnimation on height {
                    running: eqRoot.active
                    loops: Animation.Infinite

                    NumberAnimation {
                        to: highH
                        duration: dur
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: minH + 1
                        duration: Math.round(dur * 0.85)
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: midH
                        duration: Math.round(dur * 0.9)
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: minH
                        duration: Math.round(dur * 0.75)
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
    }
}
