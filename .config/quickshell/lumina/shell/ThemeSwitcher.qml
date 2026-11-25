import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../services"
import "../components"

PanelWindow {
    id: themeWin

    property bool isOpen: false
    property int initialTab: 0
    property int activeTab: 0 // 0=Color Palette, 1=Bar Style
    property int selectedIndex: 0

    signal closeRequested()

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: Qt.rgba(0, 0, 0, 0.36)
    visible: isOpen
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "lumina-theme"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    readonly property var presets: [
        { name: "Matugen Dynamic", desc: "Extracted from active wallpaper", swatches: [Theme.bg, Theme.surface, Theme.accent, Theme.secondary, Theme.tertiary] },
        { name: "Lucid Material 3", desc: "Obsidian teal glass", swatches: ["#141a1b", "#1d2627", "#80d4dc", "#72d8a5", "#e2c478"] },
        { name: "Catppuccin Mocha", desc: "Soothing pastel lavender", swatches: ["#181825", "#1e1e2e", "#89b4fa", "#a6e3a1", "#cba6f7"] },
        { name: "Tokyo Night", desc: "Crisp neon indigo", swatches: ["#16161e", "#1a1b26", "#7aa2f7", "#9ece6a", "#bb9af7"] },
        { name: "Nord", desc: "Arctic slate frost", swatches: ["#242933", "#2e3440", "#88c0d0", "#a3be8c", "#b48ead"] },
        { name: "Gruvbox Dark", desc: "Retro warm amber", swatches: ["#1d2021", "#282828", "#fabd2f", "#b8bb26", "#d3869b"] }
    ]

    function syncSelectedIndex() {
        selectedIndex = 0;
        if (activeTab === 0) {
            for (let i = 0; i < presets.length; i++) {
                if (presets[i].name === Theme.presetName) { selectedIndex = i; break; }
            }
        } else {
            for (let i = 0; i < Theme.barStyles.length; i++) {
                if (Theme.barStyles[i].id === Theme.barStyle) { selectedIndex = i; break; }
            }
        }
    }

    function applyPalette(idx, closeAfter) {
        if (idx < 0 || idx >= presets.length) return;
        const p = presets[idx];
        Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/rice-theme", p.name]);
        if (closeAfter) closeRequested();
    }

    function applyBarStyle(idx, closeAfter) {
        if (idx < 0 || idx >= Theme.barStyles.length) return;
        Theme.setBarStyle(Theme.barStyles[idx].id, false);
        if (closeAfter) closeRequested();
    }

    onIsOpenChanged: {
        if (isOpen) {
            activeTab = initialTab;
            syncSelectedIndex();
            themeFocus.forceActiveFocus();
            cardPopAnim.restart();
        }
    }

    onActiveTabChanged: syncSelectedIndex()

    MouseArea {
        anchors.fill: parent
        onClicked: themeWin.closeRequested()
    }

    Item {
        id: themeFocus
        anchors.fill: parent
        Keys.onEscapePressed: themeWin.closeRequested()
        Keys.onLeftPressed: themeWin.activeTab = 0
        Keys.onRightPressed: themeWin.activeTab = 1
        Keys.onTabPressed: themeWin.activeTab = (themeWin.activeTab === 0 ? 1 : 0)
        Keys.onUpPressed: {
            if (themeWin.selectedIndex > 0) themeWin.selectedIndex--;
        }
        Keys.onDownPressed: {
            const maxIdx = (themeWin.activeTab === 0 ? themeWin.presets.length : Theme.barStyles.length) - 1;
            if (themeWin.selectedIndex < maxIdx) themeWin.selectedIndex++;
        }
        Keys.onReturnPressed: {
            if (themeWin.activeTab === 0) themeWin.applyPalette(themeWin.selectedIndex, true);
            else themeWin.applyBarStyle(themeWin.selectedIndex, true);
        }

        GlassCard {
            id: switcherCard
            anchors.centerIn: parent
            width: 500
            height: 468
            radiusValue: 20
            strong: true
            highlighted: true

            ParallelAnimation {
                id: cardPopAnim
                NumberAnimation { target: switcherCard; property: "scale"; from: 0.94; to: 1.0; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.15 }
                NumberAnimation { target: switcherCard; property: "opacity"; from: 0.0; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
            }

            MouseArea { anchors.fill: parent; z: -1 }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                // Header + Close
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: themeWin.activeTab === 0 ? "󰔎  Color Palette" : "󰕮  Top Bar Theme"
                        font.family: Theme.fontSans
                        font.pixelSize: 16
                        font.bold: true
                        color: Theme.fg
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: themeWin.activeTab === 1 ? "Live preview · Esc to close" : "Esc to close"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        color: Theme.muted
                    }

                    Rectangle {
                        width: 24; height: 24; radius: 12
                        color: clsM.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.06)
                        Text { anchors.centerIn: parent; text: "✕"; font.pixelSize: 10; color: Theme.muted }
                        MouseArea {
                            id: clsM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: themeWin.closeRequested()
                        }
                    }
                }

                // Segmented Tab Bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: 11
                    color: Qt.rgba(0, 0, 0, 0.25)
                    border.width: 1
                    border.color: Theme.glassBorder

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 4

                        Repeater {
                            model: [
                                { idx: 0, label: "󰔎  Color Palette" },
                                { idx: 1, label: "󰕮  Bar Style (5)" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool sel: themeWin.activeTab === modelData.idx
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 8
                                color: sel ? Theme.accent : "transparent"
                                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.family: Theme.fontSans
                                    font.pixelSize: 12
                                    font.bold: sel
                                    color: sel ? Theme.accentFg : Theme.muted
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: themeWin.activeTab = modelData.idx
                                }
                            }
                        }
                    }
                }

                // TAB 0: COLOR PALETTES
                ListView {
                    visible: themeWin.activeTab === 0
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 7
                    model: themeWin.presets

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool sel: index === themeWin.selectedIndex
                        readonly property bool active: modelData.name === Theme.presetName

                        width: ListView.view.width
                        height: 54
                        radius: 13
                        color: sel ? Theme.accentSoft : Theme.glassSurface
                        border.width: sel || active ? 1.5 : 1
                        border.color: sel ? Theme.accent : (active ? Theme.secondary : Theme.glassBorder)
                        Behavior on color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 12

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1
                                Text {
                                    text: modelData.name + (active ? "  ✓" : "")
                                    font.family: Theme.fontSans
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: sel ? Theme.accent : Theme.fg
                                }
                                Text {
                                    text: modelData.desc
                                    font.family: Theme.fontSans
                                    font.pixelSize: 11
                                    color: Theme.muted
                                }
                            }

                            Row {
                                spacing: 4
                                Repeater {
                                    model: modelData.swatches
                                    delegate: Rectangle {
                                        required property var modelData
                                        width: 14; height: 14; radius: 7
                                        color: modelData
                                        border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.25)
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: themeWin.selectedIndex = index
                            onClicked: themeWin.applyPalette(index, true)
                        }
                    }
                }

                // TAB 1: BAR STYLES (WITH LIVE WIREFRAME PREVIEWS)
                ListView {
                    visible: themeWin.activeTab === 1
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 8
                    model: Theme.barStyles

                    delegate: Rectangle {
                        id: styleRow
                        required property var modelData
                        required property int index
                        readonly property bool sel: index === themeWin.selectedIndex
                        readonly property bool active: modelData.id === Theme.barStyle

                        width: ListView.view.width
                        height: 64
                        radius: 13
                        color: sel || active ? Theme.accentSoft : Theme.glassSurface
                        border.width: active ? 1.5 : (sel ? 1.5 : 1)
                        border.color: active ? Theme.accent : (sel ? Theme.accentBorder : Theme.glassBorder)
                        Behavior on color { ColorAnimation { duration: 120 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 12

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    text: modelData.name + (active ? "  ✓" : "")
                                    font.family: Theme.fontSans
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: active || sel ? Theme.accent : Theme.fg
                                }
                                Text {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    text: modelData.desc
                                    font.family: Theme.fontSans
                                    font.pixelSize: 11
                                    color: Theme.muted
                                }
                            }

                            // Mini Bar Wireframe Preview
                            Rectangle {
                                Layout.preferredWidth: 112
                                Layout.preferredHeight: 34
                                radius: 8
                                color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.85)
                                border.width: 1
                                border.color: Theme.glassBorder

                                // Eclipse Pills preview (full-pill obsidian capsules with accent rim)
                                RowLayout {
                                    visible: styleRow.modelData.id === "eclipse"
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.margins: 4
                                    height: 11
                                    spacing: 4

                                    Rectangle {
                                        Layout.preferredWidth: 11; Layout.fillHeight: true; radius: 5.5
                                        color: Theme.bg; border.width: 1; border.color: Theme.accent
                                    }
                                    Rectangle {
                                        Layout.preferredWidth: 22; Layout.fillHeight: true; radius: 5.5
                                        color: Theme.bg; border.width: 1; border.color: Theme.accentBorder
                                        Rectangle { anchors.centerIn: parent; width: 10; height: 4; radius: 2; color: Theme.accent }
                                    }
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        Layout.preferredWidth: 30; Layout.fillHeight: true; radius: 5.5
                                        color: Theme.bg; border.width: 1; border.color: Theme.accent
                                    }
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        Layout.preferredWidth: 22; Layout.fillHeight: true; radius: 5.5
                                        color: Theme.bg; border.width: 1; border.color: Theme.accentBorder
                                    }
                                }

                                // Dynamic Notch preview
                                Item {
                                    visible: styleRow.modelData.id === "notch"
                                    anchors.fill: parent
                                    Rectangle {
                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        anchors.margins: 4
                                        width: 24; height: 9; radius: 4.5
                                        color: Theme.surfaceHigh
                                        Rectangle { anchors.centerIn: parent; width: 12; height: 4; radius: 2; color: Theme.accent }
                                    }
                                    Rectangle {
                                        anchors.top: parent.top
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 36; height: 12
                                        topLeftRadius: 0; topRightRadius: 0; bottomLeftRadius: 6; bottomRightRadius: 6
                                        color: "#0b0c10"
                                        border.width: 1; border.color: Theme.accent
                                    }
                                    Rectangle {
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: 4
                                        width: 24; height: 9; radius: 4.5
                                        color: Theme.surfaceHigh
                                    }
                                }

                                // Aurora / Cyber / Minimal previews
                                RowLayout {
                                    visible: styleRow.modelData.id === "aurora" || styleRow.modelData.id === "cyber" || styleRow.modelData.id === "minimal"
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.margins: 4
                                    height: 11
                                    spacing: 4

                                    Rectangle {
                                        Layout.preferredWidth: 26
                                        Layout.fillHeight: true
                                        radius: styleRow.modelData.id === "cyber" ? 2 : 5
                                        color: styleRow.modelData.id === "minimal" ? "transparent" : Theme.surfaceHigh
                                        border.width: styleRow.modelData.id === "cyber" ? 1 : 0
                                        border.color: Theme.accent
                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 2
                                            Rectangle { width: styleRow.modelData.id === "minimal" ? 8 : 10; height: 4; radius: 2; color: Theme.accent }
                                            Rectangle { width: 4; height: 4; radius: 2; color: Theme.muted }
                                        }
                                    }
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        Layout.preferredWidth: 32
                                        Layout.fillHeight: true
                                        radius: styleRow.modelData.id === "cyber" ? 2 : 5
                                        color: Theme.surfaceHigh
                                        border.width: styleRow.modelData.id === "cyber" ? 1 : 0
                                        border.color: Theme.tertiary
                                    }
                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        Layout.preferredWidth: 26
                                        Layout.fillHeight: true
                                        radius: styleRow.modelData.id === "cyber" ? 2 : 5
                                        color: styleRow.modelData.id === "minimal" ? "transparent" : Theme.surfaceHigh
                                        border.width: styleRow.modelData.id === "cyber" ? 1 : 0
                                        border.color: Theme.secondary
                                        Rectangle { visible: styleRow.modelData.id === "minimal"; anchors.centerIn: parent; width: 16; height: 4; radius: 2; color: Theme.muted }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: themeWin.selectedIndex = index
                            onClicked: themeWin.applyBarStyle(index, false)
                            onDoubleClicked: themeWin.applyBarStyle(index, true)
                        }
                    }
                }
            }
        }
    }
}
