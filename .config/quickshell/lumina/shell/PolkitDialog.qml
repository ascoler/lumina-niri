import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit
import "../services"
import "../components"

Scope {
    id: polkitScope

    PolkitAgent {
        id: agent
    }

    PanelWindow {
        visible: agent.isActive && !!agent.flow
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: Qt.rgba(0, 0, 0, 0.45)
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "lumina-polkit"

        onVisibleChanged: {
            if (visible) {
                passInput.text = "";
                passInput.forceActiveFocus();
            }
        }

        GlassCard {
            anchors.centerIn: parent
            width: 400
            height: col.implicitHeight + 40
            radiusValue: 18
            strong: true
            highlighted: true

            ColumnLayout {
                id: col
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                RowLayout {
                    spacing: 10
                    Text {
                        text: "󰌾"
                        font.family: Theme.fontMono
                        font.pixelSize: 22
                        color: Theme.accent
                    }
                    Text {
                        Layout.fillWidth: true
                        text: "Authentication Required"
                        font.family: Theme.fontSans
                        font.pixelSize: 16
                        font.bold: true
                        color: Theme.fg
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: agent.flow ? agent.flow.message : ""
                    wrapMode: Text.WordWrap
                    font.family: Theme.fontSans
                    font.pixelSize: 12
                    color: Theme.muted
                }

                Text {
                    visible: !!(agent.flow && agent.flow.supplementaryMessage)
                    Layout.fillWidth: true
                    text: agent.flow ? agent.flow.supplementaryMessage : ""
                    wrapMode: Text.WordWrap
                    font.family: Theme.fontSans
                    font.pixelSize: 12
                    color: (agent.flow && agent.flow.supplementaryIsError) ? Theme.error : Theme.tertiary
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: 10
                    color: Theme.glassSurface
                    border.width: 1
                    border.color: Theme.accentBorder

                    TextInput {
                        id: passInput
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: (agent.flow && agent.flow.responseVisible) ? TextInput.Normal : TextInput.Password
                        color: Theme.fg
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        onAccepted: {
                            if (agent.flow) agent.flow.submit(passInput.text);
                        }
                        Keys.onEscapePressed: {
                            if (agent.flow) agent.flow.cancelAuthenticationRequest();
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 90; height: 34; radius: 10
                        color: Theme.glassSurface
                        border.width: 1; border.color: Theme.glassBorder
                        Text { anchors.centerIn: parent; text: "Cancel"; font.family: Theme.fontSans; font.pixelSize: 12; color: Theme.muted }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { if (agent.flow) agent.flow.cancelAuthenticationRequest(); }
                        }
                    }

                    Rectangle {
                        width: 110; height: 34; radius: 10
                        color: Theme.accent
                        Text { anchors.centerIn: parent; text: "Authenticate"; font.family: Theme.fontSans; font.pixelSize: 12; font.bold: true; color: Theme.accentFg }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { if (agent.flow) agent.flow.submit(passInput.text); }
                        }
                    }
                }
            }
        }
    }
}
