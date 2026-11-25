import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"
import "../components"

PanelWindow {
    id: clipWin

    property bool isOpen: false
    property var items: []
    property var filtered: []
    property int selectedIndex: 0

    signal closeRequested()

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: Qt.rgba(0, 0, 0, 0.38)
    visible: isOpen
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "lumina-clipboard"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    onIsOpenChanged: {
        if (isOpen) {
            searchInput.text = "";
            refresh();
            searchInput.forceActiveFocus();
        }
    }

    function refresh() {
        items = [];
        listProc.running = true;
    }

    function filterItems() {
        const q = searchInput.text.trim().toLowerCase();
        filtered = q === "" ? items : items.filter(it => it.preview.toLowerCase().includes(q));
        selectedIndex = 0;
    }

    function copyItem(it) {
        if (!it) return;
        Quickshell.execDetached(["sh", "-c", "printf '%s' " + JSON.stringify(it.raw) + " | cliphist decode | wl-copy"]);
        closeRequested();
    }

    function deleteItem(it) {
        if (!it) return;
        actionProc.exec(["sh", "-c", "printf '%s' " + JSON.stringify(it.raw) + " | cliphist delete"]);
        refresh();
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: SplitParser {
            onRead: line => {
                if (!line) return;
                const tabIdx = line.indexOf("\t");
                const preview = tabIdx !== -1 ? line.slice(tabIdx + 1) : line;
                clipWin.items.push({ raw: line, preview: preview });
            }
        }
        onExited: clipWin.filterItems()
    }

    Process { id: actionProc }

    MouseArea {
        anchors.fill: parent
        onClicked: clipWin.closeRequested()
    }

    GlassCard {
        anchors.centerIn: parent
        width: 560
        height: 480
        radiusValue: 18
        strong: true
        highlighted: true

        MouseArea { anchors.fill: parent; z: -1 }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "󰅌  Clipboard History"
                    font.family: Theme.fontSans
                    font.pixelSize: 15
                    font.bold: true
                    color: Theme.fg
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: 78; height: 26; radius: 8
                    color: Theme.glassSurface
                    border.width: 1; border.color: Theme.glassBorder
                    Text { anchors.centerIn: parent; text: "Wipe All"; font.family: Theme.fontSans; font.pixelSize: 11; color: Theme.error }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { actionProc.exec(["cliphist", "wipe"]); clipWin.items = []; clipWin.filtered = []; }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 40
                radius: 10
                color: Theme.glassSurface
                border.width: 1
                border.color: Theme.accentBorder

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    font.family: Theme.fontSans
                    font.pixelSize: 13
                    onTextChanged: clipWin.filterItems()
                    Keys.onEscapePressed: clipWin.closeRequested()
                    Keys.onReturnPressed: {
                        if (clipWin.selectedIndex >= 0 && clipWin.selectedIndex < clipWin.filtered.length) {
                            clipWin.copyItem(clipWin.filtered[clipWin.selectedIndex]);
                        }
                    }
                    Keys.onUpPressed: if (clipWin.selectedIndex > 0) clipWin.selectedIndex--
                    Keys.onDownPressed: if (clipWin.selectedIndex < clipWin.filtered.length - 1) clipWin.selectedIndex++
                }
                Text {
                    visible: searchInput.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    text: "Filter clipboard entries..."
                    font.family: Theme.fontSans
                    font.pixelSize: 12
                    color: Theme.muted
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 4
                model: clipWin.filtered

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool sel: index === clipWin.selectedIndex

                    width: ListView.view.width
                    height: 42
                    radius: 10
                    color: sel ? Theme.accentSoft : (cM.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
                    border.width: 1
                    border.color: sel ? Theme.accentBorder : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            text: modelData.preview
                            elide: Text.ElideRight
                            font.family: Theme.fontMono
                            font.pixelSize: 12
                            color: sel ? Theme.accent : Theme.fg
                        }

                        Text {
                            text: "✕"
                            font.pixelSize: 11
                            color: Theme.muted
                            MouseArea {
                                anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor
                                onClicked: clipWin.deleteItem(modelData)
                            }
                        }
                    }

                    MouseArea {
                        id: cM
                        anchors.fill: parent
                        z: -1
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: clipWin.selectedIndex = index
                        onClicked: clipWin.copyItem(modelData)
                    }
                }
            }
        }
    }
}
