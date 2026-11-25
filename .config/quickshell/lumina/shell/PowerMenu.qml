import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"
import "../components"

PanelWindow {
    id: pwrWin

    property bool isOpen: false
    property int selectedIndex: 0

    signal closeRequested()

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: Qt.rgba(0, 0, 0, 0.45)
    visible: isOpen
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "lumina-powermenu"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    readonly property var actions: [
        { key: "1", icon: "󰌾", label: "Lock", cmd: ["hyprlock"], danger: false },
        { key: "2", icon: "󰤄", label: "Suspend", cmd: ["systemctl", "suspend"], danger: false },
        { key: "3", icon: "󰜉", label: "Reboot", cmd: ["systemctl", "reboot"], danger: true },
        { key: "4", icon: "󰐥", label: "Shutdown", cmd: ["systemctl", "poweroff"], danger: true },
        { key: "5", icon: "󰍃", label: "Logout", cmd: ["niri", "msg", "action", "quit", "--skip-confirmation"], danger: false }
    ]

    function trigger(idx) {
        if (idx < 0 || idx >= actions.length) return;
        const a = actions[idx];
        closeRequested();
        pwrProc.exec(a.cmd);
    }

    onIsOpenChanged: {
        if (isOpen) {
            selectedIndex = 0;
            rootFocus.forceActiveFocus();
        }
    }

    Process { id: pwrProc }

    MouseArea {
        anchors.fill: parent
        onClicked: pwrWin.closeRequested()
    }

    Item {
        id: rootFocus
        anchors.fill: parent
        Keys.onEscapePressed: pwrWin.closeRequested()
        Keys.onLeftPressed: pwrWin.selectedIndex = (pwrWin.selectedIndex + 4) % 5
        Keys.onRightPressed: pwrWin.selectedIndex = (pwrWin.selectedIndex + 1) % 5
        Keys.onReturnPressed: pwrWin.trigger(pwrWin.selectedIndex)
        Keys.onPressed: (e) => {
            const n = parseInt(e.text);
            if (n >= 1 && n <= 5) pwrWin.trigger(n - 1);
        }

        GlassCard {
            anchors.centerIn: parent
            width: row.implicitWidth + 40
            height: 148
            radiusValue: 20
            strong: true
            highlighted: true

            MouseArea { anchors.fill: parent; z: -1 }

            Row {
                id: row
                anchors.centerIn: parent
                spacing: 12

                Repeater {
                    model: pwrWin.actions
                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool sel: index === pwrWin.selectedIndex

                        width: 104
                        height: 104
                        radius: 16
                        color: sel ? (modelData.danger ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.22) : Theme.accentSoft) : Theme.glassSurface
                        border.width: sel ? 2 : 1
                        border.color: sel ? (modelData.danger ? Theme.error : Theme.accent) : Theme.glassBorder

                        Column {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.icon
                                font.family: Theme.fontMono
                                font.pixelSize: 28
                                color: modelData.danger && sel ? Theme.error : (sel ? Theme.accent : Theme.fg)
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                font.family: Theme.fontSans
                                font.pixelSize: 12
                                font.bold: sel
                                color: Theme.fg
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "[" + modelData.key + "]"
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                color: Theme.muted
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: pwrWin.selectedIndex = index
                            onClicked: pwrWin.trigger(index)
                        }
                    }
                }
            }
        }
    }
}
