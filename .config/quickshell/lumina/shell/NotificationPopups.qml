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
    margins.top: 58
    margins.right: 20

    implicitWidth: 378
    implicitHeight: Math.max(10, popupCol.implicitHeight + 10)
    color: "transparent"
    visible: Notifications.popupModel.count > 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lumina-notifications"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    Column {
        id: popupCol
        width: parent.width
        spacing: 10

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
                implicitHeight: contentCol.implicitHeight + 24
                radiusValue: 16
                strong: true
                highlighted: urgency === 2 || toastHover.containsMouse

                property real progress: 1.0
                property real slideX: 38
                transform: Translate { x: toast.slideX }

                Component.onCompleted: {
                    enterAnim.start();
                    if (timeoutMs > 0) {
                        expireAnim.duration = timeoutMs;
                        expireAnim.start();
                    }
                }

                ParallelAnimation {
                    id: enterAnim
                    NumberAnimation { target: toast; property: "slideX"; from: 38; to: 0; duration: 240; easing.type: Easing.OutCubic }
                    NumberAnimation { target: toast; property: "opacity"; from: 0.0; to: 1.0; duration: 180; easing.type: Easing.OutCubic }
                    NumberAnimation { target: toast; property: "scale"; from: 0.94; to: 1.0; duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
                }

                NumberAnimation {
                    id: expireAnim
                    target: toast
                    property: "progress"
                    from: 1.0
                    to: 0.0
                    onFinished: Notifications.removePopup(toast.uid)
                }

                // Left urgency/accent indicator stripe
                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 5
                    anchors.topMargin: 10
                    anchors.bottomMargin: 12
                    width: 3
                    radius: 1.5
                    color: toast.urgency === 2 ? Theme.error : Theme.accent
                }

                ColumnLayout {
                    id: contentCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: 16
                    anchors.rightMargin: 13
                    anchors.topMargin: 12
                    spacing: 7

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        ClippingWrapperRectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: 10
                            visible: toast.image !== "" || toast.appIcon !== ""

                            Item {
                                anchors.fill: parent
                                Image {
                                    anchors.fill: parent
                                    visible: toast.image !== ""
                                    source: toast.image
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    sourceSize.width: 72
                                    sourceSize.height: 72
                                }

                                IconImage {
                                    anchors.fill: parent
                                    visible: toast.image === "" && toast.appIcon !== ""
                                    source: toast.appIcon
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                Rectangle {
                                    width: appTag.implicitWidth + 10
                                    height: 16
                                    radius: 5
                                    color: toast.urgency === 2 ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.16) : Theme.accentSoft
                                    Text {
                                        id: appTag
                                        anchors.centerIn: parent
                                        text: toast.appName
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: toast.urgency === 2 ? Theme.error : Theme.accent
                                    }
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: toastHover.containsMouse && toast.timeoutMs > 0 ? "Paused" : toast.timeStr
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    color: toastHover.containsMouse ? Theme.accent : Theme.muted
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
                            color: closeM.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.22) : Qt.rgba(1, 1, 1, 0.06)
                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                font.pixelSize: 10
                                color: closeM.containsMouse ? Theme.error : Theme.muted
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
                    anchors.leftMargin: 12
                    height: 2.5
                    radius: 1.5
                    width: Math.max(0, (parent.width - 24) * toast.progress)
                    color: toast.urgency === 2 ? Theme.error : Theme.accent
                }

                MouseArea {
                    id: toastHover
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
