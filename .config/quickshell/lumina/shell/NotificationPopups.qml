import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../services"
import "../components"

PanelWindow {
    id: popWin

    anchors {
        top: true
        right: true
    }
    margins.top: 52
    margins.right: 12

    implicitWidth: 368
    implicitHeight: Math.max(10, popupCol.implicitHeight + 8)
    color: "transparent"
    visible: Notifications.popupModel.count > 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lumina-notifications"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    Column {
        id: popupCol
        width: parent.width
        spacing: 8

        Repeater {
            model: Notifications.popupModel

            delegate: GlassCard {
                id: toast
                required property int uid
                required property string appName
                required property string appIcon
                required property string image
                required property string summary
                required property string body
                required property int urgency
                required property string timeStr
                required property string actionsJson
                required property int timeoutMs

                width: popupCol.width
                implicitHeight: contentCol.implicitHeight + 22
                radiusValue: 14
                strong: true
                highlighted: urgency === 2

                property real progress: 1.0

                Component.onCompleted: {
                    if (timeoutMs > 0) {
                        expireAnim.duration = timeoutMs;
                        expireAnim.start();
                    }
                }

                NumberAnimation {
                    id: expireAnim
                    target: toast
                    property: "progress"
                    from: 1.0
                    to: 0.0
                    onFinished: Notifications.removePopup(toast.uid)
                }

                ColumnLayout {
                    id: contentCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        ClippingWrapperRectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: 8
                            visible: toast.image !== "" || toast.appIcon !== ""

                            Image {
                                anchors.fill: parent
                                visible: toast.image !== ""
                                source: toast.image
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 64
                                sourceSize.height: 64
                            }

                            IconImage {
                                anchors.fill: parent
                                visible: toast.image === "" && toast.appIcon !== ""
                                source: toast.appIcon
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: toast.appName
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    color: toast.urgency === 2 ? Theme.error : Theme.accent
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: toast.timeStr
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    color: Theme.muted
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: toast.summary
                                elide: Text.ElideRight
                                font.family: Theme.fontSans
                                font.pixelSize: 13
                                font.bold: true
                                color: Theme.fg
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            radius: 11
                            color: closeM.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.05)
                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                font.pixelSize: 10
                                color: Theme.muted
                            }
                            MouseArea {
                                id: closeM
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Notifications.removePopup(toast.uid)
                            }
                        }
                    }

                    Text {
                        visible: toast.body !== ""
                        Layout.fillWidth: true
                        text: toast.body
                        wrapMode: Text.WordWrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                        font.family: Theme.fontSans
                        font.pixelSize: 12
                        color: Theme.muted
                    }

                    // Action buttons
                    Flow {
                        visible: parsedActions.length > 0
                        Layout.fillWidth: true
                        spacing: 6

                        property var parsedActions: {
                            try { return JSON.parse(toast.actionsJson); }
                            catch (e) { return []; }
                        }

                        Repeater {
                            model: parent.parsedActions
                            delegate: Rectangle {
                                required property var modelData
                                width: actTxt.implicitWidth + 18
                                height: 26
                                radius: 8
                                color: actM.containsMouse ? Theme.accent : Theme.accentSoft
                                border.width: 1
                                border.color: Theme.accentBorder

                                Text {
                                    id: actTxt
                                    anchors.centerIn: parent
                                    text: modelData.text
                                    font.family: Theme.fontSans
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: actM.containsMouse ? Theme.accentFg : Theme.accent
                                }

                                MouseArea {
                                    id: actM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Notifications.invokeAction(toast.uid, modelData.identifier)
                                }
                            }
                        }
                    }
                }

                // Timeout progress line
                Rectangle {
                    visible: toast.timeoutMs > 0
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    height: 2
                    radius: 1
                    width: Math.max(0, (parent.width - 20) * toast.progress)
                    color: toast.urgency === 2 ? Theme.error : Theme.accent
                }

                MouseArea {
                    anchors.fill: parent
                    z: -1
                    hoverEnabled: true
                    onEntered: expireAnim.pause()
                    onExited: expireAnim.resume()
                }
            }
        }
    }
}
