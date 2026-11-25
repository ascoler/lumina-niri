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

    function apply(idx) {
        if (idx < 0 || idx >= presets.length) return;
        const p = presets[idx];
        themeProc.exec([Quickshell.env("HOME") + "/.local/bin/rice-theme", p.name]);
        closeRequested();
    }

    onIsOpenChanged: {
        if (isOpen) {
            selectedIndex = 0;
            for (let i = 0; i < presets.length; i++) {
                if (presets[i].name === Theme.presetName) { selectedIndex = i; break; }
            }
            themeFocus.forceActiveFocus();
        }
    }

    Process { id: themeProc }

    MouseArea {
        anchors.fill: parent
        onClicked: themeWin.closeRequested()
    }

    Item {
        id: themeFocus
        anchors.fill: parent
        Keys.onEscapePressed: themeWin.closeRequested()
        Keys.onUpPressed: if (themeWin.selectedIndex > 0) themeWin.selectedIndex--
        Keys.onDownPressed: if (themeWin.selectedIndex < themeWin.presets.length - 1) themeWin.selectedIndex++
        Keys.onReturnPressed: themeWin.apply(themeWin.selectedIndex)

        GlassCard {
            anchors.centerIn: parent
            width: 440
            height: 410
            radiusValue: 18
            strong: true
            highlighted: true

            MouseArea { anchors.fill: parent; z: -1 }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                Text {
                    text: "󰔎  Color Theme"
                    font.family: Theme.fontSans
                    font.pixelSize: 16
                    font.bold: true
                    color: Theme.fg
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 6
                    model: themeWin.presets

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool sel: index === themeWin.selectedIndex
                        readonly property bool active: modelData.name === Theme.presetName

                        width: ListView.view.width
                        height: 52
                        radius: 12
                        color: sel ? Theme.accentSoft : Theme.glassSurface
                        border.width: sel || active ? 1.5 : 1
                        border.color: sel ? Theme.accent : (active ? Theme.secondary : Theme.glassBorder)

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
                            onClicked: themeWin.apply(index)
                        }
                    }
                }
            }
        }
    }
}
