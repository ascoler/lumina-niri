import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../services"
import "../components"

PanelWindow {
    id: launchWin

    property bool isOpen: false
    property string query: ""
    property var results: []
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
    WlrLayershell.namespace: "lumina-launcher"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    onIsOpenChanged: {
        if (isOpen) {
            searchInput.text = "";
            query = "";
            updateResults();
            Qt.callLater(updateResults);
            searchInput.forceActiveFocus();
        }
    }

    Component.onCompleted: updateResults()

    Connections {
        target: DesktopEntries.applications ?? null
        ignoreUnknownSignals: true
        function onValuesChanged() {
            if (launchWin.isOpen) launchWin.updateResults();
        }
    }

    function updateResults() {
        const q = query.trim();
        selectedIndex = 0;

        // @ Window Switcher Mode (Niri IPC!)
        if (q.startsWith("@")) {
            const needle = q.slice(1).trim().toLowerCase();
            const wins = Niri.windows || [];
            const wsMap = {};
            for (let i = 0; i < Niri.workspaces.length; i++) {
                wsMap[Niri.workspaces[i].id] = Niri.workspaces[i].idx;
            }
            results = wins
                .filter(w => !needle || (w.title || "").toLowerCase().includes(needle) || (w.app_id || "").toLowerCase().includes(needle))
                .map(w => ({
                    kind: "window",
                    title: w.title || w.app_id || "Window",
                    subtitle: "Workspace " + (wsMap[w.workspace_id] || "?") + " · " + (w.app_id || ""),
                    icon: w.app_id || "",
                    windowId: w.id
                }));
            return;
        }

        // = Calculator Mode
        if (q.startsWith("=")) {
            const expr = q.slice(1).trim();
            if (!expr) {
                results = [{ kind: "hint", title: "Type math expression, e.g. = 1920 / 3", subtitle: "Enter copies result to clipboard", icon: "" }];
                return;
            }
            try {
                if (/^[0-9+\-*/().%\s]+$/.test(expr)) {
                    const val = Function('"use strict"; return (' + expr + ')')();
                    if (val !== undefined && !isNaN(val)) {
                        results = [{ kind: "calc", title: String(val), subtitle: expr + "  (Enter to copy)", icon: "", value: String(val) }];
                        return;
                    }
                }
            } catch (e) {}
            results = [{ kind: "hint", title: "Invalid expression", subtitle: expr, icon: "" }];
            return;
        }

        // > Shell Runner Mode
        if (q.startsWith(">")) {
            const cmd = q.slice(1).trim();
            if (!cmd) {
                results = [{ kind: "hint", title: "Run shell command...", subtitle: "e.g. > btop or > alacritty", icon: "" }];
                return;
            }
            results = [{ kind: "cmd", title: "Run: " + cmd, subtitle: "Execute in background shell", icon: "", cmd: cmd }];
            return;
        }

        // Default: Desktop Applications
        const needle = q.toLowerCase();
        const apps = DesktopEntries.applications ? DesktopEntries.applications.values : [];
        const matched = [];
        for (let i = 0; i < apps.length; i++) {
            const app = apps[i];
            if (!app || !app.name) continue;
            const n = app.name.toLowerCase();
            const c = (app.comment || "").toLowerCase();
            if (!needle || n.includes(needle) || c.includes(needle)) {
                const score = !needle ? 0 : (n.startsWith(needle) ? 0 : (n.includes(needle) ? 1 : 2));
                matched.push({
                    kind: "app",
                    score: score,
                    title: app.name,
                    subtitle: app.comment || "",
                    icon: app.icon || "",
                    entry: app
                });
            }
        }
        matched.sort((a, b) => a.score !== b.score ? a.score - b.score : a.title.localeCompare(b.title));
        results = matched.slice(0, 40);
    }

    function activateCurrent() {
        if (selectedIndex < 0 || selectedIndex >= results.length) return;
        const item = results[selectedIndex];
        if (item.kind === "app" && item.entry) {
            item.entry.execute();
            closeRequested();
        } else if (item.kind === "window") {
            Niri.focusWindow(item.windowId);
            closeRequested();
        } else if (item.kind === "calc") {
            Quickshell.execDetached(["wl-copy", item.value]);
            closeRequested();
        } else if (item.kind === "cmd") {
            Quickshell.execDetached(["sh", "-c", item.cmd]);
            closeRequested();
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: launchWin.closeRequested()
    }

    GlassCard {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -40
        width: 620
        height: Math.min(540, 126 + Math.max(1, launchWin.results.length) * 52)
        radiusValue: 18
        strong: true
        highlighted: true

        MouseArea { anchors.fill: parent; z: -1 }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Search Input
            Rectangle {
                Layout.fillWidth: true
                height: 46
                radius: 12
                color: Theme.glassSurface
                border.width: 1
                border.color: Theme.accentBorder

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    Text {
                        text: launchWin.query.startsWith("@") ? "󱂬" : (launchWin.query.startsWith("=") ? "󰃬" : (launchWin.query.startsWith(">") ? "" : ""))
                        font.family: Theme.fontMono
                        font.pixelSize: 16
                        color: Theme.accent
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        color: Theme.fg
                        font.family: Theme.fontSans
                        font.pixelSize: 14
                        onTextChanged: {
                            launchWin.query = text;
                            launchWin.updateResults();
                        }
                        Keys.onEscapePressed: launchWin.closeRequested()
                        Keys.onReturnPressed: launchWin.activateCurrent()
                        Keys.onUpPressed: {
                            if (launchWin.selectedIndex > 0) {
                                launchWin.selectedIndex--;
                                list.positionViewAtIndex(launchWin.selectedIndex, ListView.Contain);
                            }
                        }
                        Keys.onDownPressed: {
                            if (launchWin.selectedIndex < launchWin.results.length - 1) {
                                launchWin.selectedIndex++;
                                list.positionViewAtIndex(launchWin.selectedIndex, ListView.Contain);
                            }
                        }
                    }

                    Text {
                        text: "@ wins  •  = calc  •  > cmd"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        color: Theme.muted
                    }
                }
            }

            // Results List
            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 4
                model: launchWin.results

                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool sel: index === launchWin.selectedIndex

                    width: ListView.view.width
                    height: 48
                    radius: 10
                    color: sel ? Theme.accentSoft : (rowM.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
                    border.width: 1
                    border.color: sel ? Theme.accentBorder : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        IconImage {
                            id: appIconImg
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            readonly property string resolvedIcon: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
                            visible: resolvedIcon !== ""
                            source: resolvedIcon
                        }

                        Text {
                            visible: appIconImg.resolvedIcon === ""
                            text: modelData.kind === "calc" ? "󰃬" : (modelData.kind === "cmd" ? "" : "󰀻")
                            font.family: Theme.fontMono
                            font.pixelSize: 18
                            color: Theme.accent
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text {
                                Layout.fillWidth: true
                                text: modelData.title
                                elide: Text.ElideRight
                                font.family: Theme.fontSans
                                font.pixelSize: 13
                                font.bold: sel
                                color: sel ? Theme.accent : Theme.fg
                            }
                            Text {
                                visible: modelData.subtitle !== ""
                                Layout.fillWidth: true
                                text: modelData.subtitle
                                elide: Text.ElideRight
                                font.family: Theme.fontSans
                                font.pixelSize: 11
                                color: Theme.muted
                            }
                        }
                    }

                    MouseArea {
                        id: rowM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: launchWin.selectedIndex = index
                        onClicked: {
                            launchWin.selectedIndex = index;
                            launchWin.activateCurrent();
                        }
                    }
                }
            }
        }
    }
}
