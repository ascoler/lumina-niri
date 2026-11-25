import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../services"
import "../components"

PanelWindow {
    id: backdropWin

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: SystemInfo.backdropWidgets
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "lumina-backdrop"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    property string bigTime: ""
    property string bigDate: ""

    function updateTime() {
        const d = new Date();
        bigTime = Qt.formatTime(d, "hh:mm");
        bigDate = Qt.formatDate(d, "dddd, d MMMM");
    }

    Component.onCompleted: {
        updateTime();
        if (visible) SystemInfo.vitalsWatchers++;
    }

    onVisibleChanged: {
        if (visible) SystemInfo.vitalsWatchers++;
        else SystemInfo.vitalsWatchers = Math.max(0, SystemInfo.vitalsWatchers - 1);
    }

    Component.onDestruction: {
        if (visible) SystemInfo.vitalsWatchers = Math.max(0, SystemInfo.vitalsWatchers - 1);
    }

    Timer {
        interval: 10000
        repeat: true
        running: backdropWin.visible
        onTriggered: backdropWin.updateTime()
    }

    // Top-right subtle Glass System Vitals Card
    GlassCard {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 64
        anchors.rightMargin: 28
        width: 240
        height: 112
        radiusValue: 18
        glassAlpha: 0.56

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "SYSTEM VITALS"
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    font.bold: true
                    color: Theme.muted
                }
                Item { Layout.fillWidth: true }
                Text {
                    visible: SystemInfo.cpuTemp > 0
                    text: SystemInfo.cpuTemp + "°C"
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    color: SystemInfo.cpuTemp > 80 ? Theme.error : Theme.tertiary
                }
            }

            // CPU bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text { text: "CPU"; font.family: Theme.fontMono; font.pixelSize: 11; color: Theme.muted; Layout.preferredWidth: 30 }
                Rectangle {
                    Layout.fillWidth: true
                    height: 6
                    radius: 3
                    color: Qt.rgba(1, 1, 1, 0.10)
                    Rectangle {
                        width: Math.max(4, (SystemInfo.cpuPercent / 100.0) * parent.width)
                        height: parent.height
                        radius: 3
                        color: Theme.accent
                        Behavior on width { NumberAnimation { duration: 400 } }
                    }
                }
                Text { text: SystemInfo.cpuPercent + "%"; font.family: Theme.fontMono; font.pixelSize: 11; color: Theme.fg; Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight }
            }

            // RAM bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text { text: "RAM"; font.family: Theme.fontMono; font.pixelSize: 11; color: Theme.muted; Layout.preferredWidth: 30 }
                Rectangle {
                    Layout.fillWidth: true
                    height: 6
                    radius: 3
                    color: Qt.rgba(1, 1, 1, 0.10)
                    Rectangle {
                        width: Math.max(4, (SystemInfo.memPercent / 100.0) * parent.width)
                        height: parent.height
                        radius: 3
                        color: Theme.secondary
                        Behavior on width { NumberAnimation { duration: 400 } }
                    }
                }
                Text { text: SystemInfo.memPercent + "%"; font.family: Theme.fontMono; font.pixelSize: 11; color: Theme.fg; Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight }
            }
        }
    }

    // Material-3 Scalloped Clock & Date Badge (inspired by Serpantinum preview_4)
    Column {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.bottomMargin: 36
        anchors.leftMargin: 36
        spacing: 4

        Text {
            text: backdropWin.bigTime
            font.family: Theme.fontSans
            font.pixelSize: 64
            font.weight: Font.Bold
            color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.88)
        }

        Row {
            spacing: 10
            Text {
                text: backdropWin.bigDate
                font.family: Theme.fontSans
                font.pixelSize: 15
                font.weight: Font.Medium
                color: Theme.accent
            }
            Text {
                visible: SystemInfo.weatherText !== ""
                text: "·  " + SystemInfo.weatherIcon + " " + SystemInfo.weatherText
                font.family: Theme.fontSans
                font.pixelSize: 15
                color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.72)
            }
        }
    }
}
