import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"
import "../components"

PanelWindow {
    id: osdWin

    anchors {
        bottom: true
    }
    margins.bottom: 36

    implicitWidth: 270
    implicitHeight: 56
    color: "transparent"
    visible: shown
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lumina-osd"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    property bool shown: false
    property string mode: "volume" // "volume" | "mic" | "brightness" | "layout"
    property real value: 0.5
    property bool muted: false
    property string labelText: ""

    function trigger(m, val, isMuted, text) {
        mode = m;
        value = val;
        muted = isMuted;
        labelText = text || "";
        shown = true;
        hideTimer.restart();
    }

    Timer {
        id: hideTimer
        interval: 1550
        onTriggered: osdWin.shown = false
    }

    Connections {
        target: Audio
        function onOsdTriggered(kind, val, isMuted) {
            osdWin.trigger(kind, val, isMuted, "");
        }
    }

    Connections {
        target: SystemInfo
        function onBrightnessOsd(val) {
            osdWin.trigger("brightness", val, false, "");
        }
    }

    Connections {
        target: Niri
        function onLayoutSwitched(shortName) {
            osdWin.trigger("layout", 1.0, false, shortName);
        }
    }

    GlassCard {
        anchors.fill: parent
        radiusValue: 26
        strong: true
        highlighted: true

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            spacing: 14

            Text {
                font.family: Theme.fontMono
                font.pixelSize: 18
                color: osdWin.muted ? Theme.error : Theme.accent
                text: {
                    if (osdWin.mode === "brightness") return "󰃠";
                    if (osdWin.mode === "mic") return osdWin.muted ? "󰍭" : "󰍬";
                    if (osdWin.mode === "layout") return "󰌌";
                    return osdWin.muted ? "󰝟" : (osdWin.value > 0.5 ? "󰕾" : "󰖀");
                }
            }

            // Progress bar for volume/brightness
            Rectangle {
                visible: osdWin.mode !== "layout"
                Layout.fillWidth: true
                height: 7
                radius: 4
                color: Qt.rgba(1, 1, 1, 0.12)

                Rectangle {
                    width: osdWin.muted ? 0 : Math.max(0, Math.min(1, osdWin.value)) * parent.width
                    height: parent.height
                    radius: 4
                    color: osdWin.mode === "brightness" ? Theme.tertiary : Theme.accent

                    Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                }
            }

            // Keyboard layout text
            Text {
                visible: osdWin.mode === "layout"
                Layout.fillWidth: true
                text: "Keyboard Layout: " + osdWin.labelText
                font.family: Theme.fontSans
                font.pixelSize: 13
                font.bold: true
                color: Theme.fg
            }

            Text {
                visible: osdWin.mode !== "layout"
                Layout.preferredWidth: 38
                horizontalAlignment: Text.AlignRight
                text: osdWin.muted ? "Mute" : Math.round(osdWin.value * 100) + "%"
                font.family: Theme.fontMono
                font.pixelSize: 12
                font.bold: true
                color: osdWin.muted ? Theme.error : Theme.fg
            }
        }
    }
}
