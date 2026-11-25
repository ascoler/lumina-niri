import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Networking
import "../services"
import "../components"

PanelWindow {
    id: ccWin

    property int activeTab: 0 // 0=Music, 1=Focus, 2=Notes
    property string expandedPane: "" // "" | "wifi" | "bt"
    property bool isOpen: false

    signal closeRequested()
    signal openThemeSwitcher()
    signal openPowerMenu()

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: isOpen
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.namespace: "lumina-control-center"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    onIsOpenChanged: {
        if (isOpen) {
            Notifications.markRead();
            SystemInfo.vitalsWatchers++;
            if (activeTab === 0) {
                Cava.subscribers++;
                Media.positionWatchers++;
            }
        } else {
            expandedPane = "";
            SystemInfo.vitalsWatchers = Math.max(0, SystemInfo.vitalsWatchers - 1);
            Cava.subscribers = 0;
            Media.positionWatchers = 0;
        }
    }

    onActiveTabChanged: {
        if (!isOpen) return;
        if (activeTab === 0) {
            if (Cava.subscribers === 0) Cava.subscribers++;
            if (Media.positionWatchers === 0) Media.positionWatchers++;
        } else {
            Cava.subscribers = 0;
            Media.positionWatchers = 0;
        }
    }

    Process { id: cmdProc }

    FileView {
        id: notesFile
        path: Quickshell.env("HOME") + "/.local/share/lumina/notes.md"
        onLoaded: notesArea.text = text()
    }

    // Scrim click-to-close
    MouseArea {
        anchors.fill: parent
        onClicked: ccWin.closeRequested()
    }

    Shortcut {
        sequence: "Escape"
        enabled: ccWin.isOpen
        onActivated: ccWin.closeRequested()
    }

    GlassCard {
        id: drawer
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.topMargin: 52
        anchors.bottomMargin: 12
        anchors.rightMargin: 12
        width: 408
        radiusValue: 18
        strong: true
        highlighted: true

        // Absorb clicks inside drawer
        MouseArea { anchors.fill: parent; z: -1 }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // HEADER
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Control Center"
                    font.family: Theme.fontSans
                    font.pixelSize: 16
                    font.bold: true
                    color: Theme.fg
                }

                Rectangle {
                    width: presetLbl.implicitWidth + 14
                    height: 22
                    radius: 8
                    color: Theme.accentSoft
                    border.width: 1
                    border.color: Theme.accentBorder
                    Text {
                        id: presetLbl
                        anchors.centerIn: parent
                        text: Theme.presetName
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        color: Theme.accent
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ccWin.closeRequested();
                            ccWin.openThemeSwitcher();
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Backdrop widgets toggle
                Rectangle {
                    width: 28; height: 28; radius: 9
                    color: SystemInfo.backdropWidgets ? Theme.accentSoft : Theme.glassSurface
                    border.width: 1
                    border.color: SystemInfo.backdropWidgets ? Theme.accentBorder : Theme.glassBorder
                    Text { anchors.centerIn: parent; text: "󰍹"; font.family: Theme.fontMono; font.pixelSize: 13; color: SystemInfo.backdropWidgets ? Theme.accent : Theme.muted }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: SystemInfo.toggleBackdropWidgets() }
                }

                // Lock
                Rectangle {
                    width: 28; height: 28; radius: 9
                    color: Theme.glassSurface
                    border.width: 1; border.color: Theme.glassBorder
                    Text { anchors.centerIn: parent; text: "󰌾"; font.family: Theme.fontMono; font.pixelSize: 13; color: Theme.fg }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { ccWin.closeRequested(); cmdProc.exec(["hyprlock"]); }
                    }
                }

                // Power
                Rectangle {
                    width: 28; height: 28; radius: 9
                    color: Theme.glassSurface
                    border.width: 1; border.color: Theme.glassBorder
                    Text { anchors.centerIn: parent; text: ""; font.family: Theme.fontMono; font.pixelSize: 13; color: Theme.error }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { ccWin.closeRequested(); ccWin.openPowerMenu(); }
                    }
                }
            }

            // QUICK TOGGLES GRID (4x2)
            GridLayout {
                Layout.fillWidth: true
                columns: 4
                columnSpacing: 8
                rowSpacing: 8

                Repeater {
                    model: [
                        { key: "wifi", icon: SystemInfo.wifiEnabled ? "󰤨" : "󰤮", label: SystemInfo.wifiSsid || "Wi-Fi", active: SystemInfo.wifiEnabled, expandable: true },
                        { key: "bt", icon: SystemInfo.btEnabled ? "󰂯" : "󰂲", label: "Bluetooth", active: SystemInfo.btEnabled, expandable: true },
                        { key: "night", icon: "󰖔", label: "Night Light", active: SystemInfo.nightLight, expandable: false },
                        { key: "caffeine", icon: "󰅶", label: "Caffeine", active: SystemInfo.caffeine, expandable: false },
                        { key: "dnd", icon: Notifications.dnd ? "󰂛" : "󰂚", label: "DND", active: Notifications.dnd, expandable: false },
                        { key: "mic", icon: Audio.micMuted ? "󰍭" : "󰍬", label: Audio.micMuted ? "Muted" : "Mic On", active: !Audio.micMuted, expandable: false },
                        { key: "shot", icon: "󰹑", label: "Screenshot", active: false, expandable: false },
                        { key: "pick", icon: "󰈊", label: "Picker", active: false, expandable: false }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 54
                        radius: 12
                        color: modelData.active ? Theme.accent : Theme.glassSurface
                        border.width: 1
                        border.color: modelData.active ? Theme.accent : (tileM.containsMouse ? Theme.accentBorder : Theme.glassBorder)

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        Column {
                            anchors.centerIn: parent
                            spacing: 3
                            width: parent.width - 10
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.icon
                                font.family: Theme.fontMono
                                font.pixelSize: 16
                                color: modelData.active ? Theme.accentFg : Theme.accent
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                text: modelData.label
                                font.family: Theme.fontSans
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: modelData.active ? Theme.accentFg : Theme.fg
                            }
                        }

                        MouseArea {
                            id: tileM
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: (m) => {
                                const k = modelData.key;
                                if (m.button === Qt.RightButton && modelData.expandable) {
                                    ccWin.expandedPane = (ccWin.expandedPane === k) ? "" : k;
                                    return;
                                }
                                if (k === "wifi") SystemInfo.toggleWifi();
                                else if (k === "bt") SystemInfo.toggleBluetooth();
                                else if (k === "night") SystemInfo.toggleNightLight();
                                else if (k === "caffeine") SystemInfo.toggleCaffeine();
                                else if (k === "dnd") Notifications.toggleDnd();
                                else if (k === "mic") Audio.toggleMicMute();
                                else if (k === "shot") {
                                    ccWin.closeRequested();
                                    cmdProc.exec([Quickshell.env("HOME") + "/.local/bin/rice-screenshot", "region"]);
                                } else if (k === "pick") {
                                    ccWin.closeRequested();
                                    cmdProc.exec([Quickshell.env("HOME") + "/.local/bin/rice-colorpicker"]);
                                }
                            }
                        }
                    }
                }
            }

            // EXPANDABLE WI-FI / BT DRAWER (on right-click of Wi-Fi or BT tile)
            GlassCard {
                visible: ccWin.expandedPane !== ""
                Layout.fillWidth: true
                Layout.preferredHeight: 136
                radiusValue: 12

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: ccWin.expandedPane === "wifi" ? "Wi-Fi Networks (Right-click tile to close)" : "Bluetooth Devices"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.accent
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            visible: ccWin.expandedPane === "wifi"
                            text: "Full Menu"
                            font.family: Theme.fontSans
                            font.pixelSize: 11
                            color: Theme.muted
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    ccWin.closeRequested();
                                    cmdProc.exec([Quickshell.env("HOME") + "/.local/bin/rice-wifi-menu"]);
                                }
                            }
                        }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 4
                        model: {
                            if (ccWin.expandedPane === "wifi") {
                                const dev = SystemInfo.wifiDevices.length > 0 ? SystemInfo.wifiDevices[0] : null;
                                return dev && dev.networks ? dev.networks.values.slice(0, 12) : [];
                            }
                            return SystemInfo.btDevices.filter(d => d && (d.paired || d.connected));
                        }
                        delegate: Rectangle {
                            required property var modelData
                            width: ListView.view.width
                            height: 28
                            radius: 7
                            color: modelData.connected ? Theme.accentSoft : Qt.rgba(1, 1, 1, 0.04)

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name || modelData.deviceName || "Unknown"
                                    elide: Text.ElideRight
                                    font.family: Theme.fontSans
                                    font.pixelSize: 12
                                    color: modelData.connected ? Theme.accent : Theme.fg
                                }
                                Text {
                                    text: modelData.connected ? "Connected" : "Connect"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    color: modelData.connected ? Theme.secondary : Theme.muted
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (ccWin.expandedPane === "wifi") {
                                        if (modelData.connected) modelData.disconnect();
                                        else modelData.connect();
                                    } else {
                                        modelData.connected = !modelData.connected;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // SLIDERS CARD (Volume + Brightness + Audio Sink Pills)
            GlassCard {
                Layout.fillWidth: true
                Layout.preferredHeight: slidersCol.implicitHeight + 20
                radiusValue: 14

                ColumnLayout {
                    id: slidersCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Text {
                            text: Audio.muted ? "󰝟" : "󰕾"
                            font.family: Theme.fontMono
                            font.pixelSize: 16
                            color: Audio.muted ? Theme.error : Theme.accent
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Audio.toggleMute() }
                        }
                        GlassSlider {
                            Layout.fillWidth: true
                            value: Audio.volume
                            fillColor: Audio.muted ? Theme.error : Theme.accent
                            onMoved: (v) => Audio.setVolume(v)
                        }
                        Text {
                            Layout.preferredWidth: 36
                            horizontalAlignment: Text.AlignRight
                            text: Math.round(Audio.volume * 100) + "%"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: Theme.fg
                        }
                    }

                    RowLayout {
                        visible: SystemInfo.hasBacklight
                        Layout.fillWidth: true
                        spacing: 10
                        Text {
                            text: "󰃠"
                            font.family: Theme.fontMono
                            font.pixelSize: 16
                            color: Theme.tertiary
                        }
                        GlassSlider {
                            Layout.fillWidth: true
                            value: SystemInfo.brightness
                            fillColor: Theme.tertiary
                            onMoved: (v) => SystemInfo.setBrightness(v)
                        }
                        Text {
                            Layout.preferredWidth: 36
                            horizontalAlignment: Text.AlignRight
                            text: Math.round(SystemInfo.brightness * 100) + "%"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: Theme.fg
                        }
                    }

                    // Compact Audio Output Sink Selector (expands on click)
                    property bool sinksExpanded: false

                    Rectangle {
                        visible: Audio.sinks.length > 1
                        Layout.fillWidth: true
                        height: 26
                        radius: 8
                        color: Qt.rgba(1, 1, 1, 0.05)
                        border.width: 1
                        border.color: Theme.glassBorder

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            Text {
                                text: "󰓃"
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                                color: Theme.accent
                            }
                            Text {
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                text: Audio.defaultSink ? (Audio.defaultSink.description || Audio.defaultSink.name) : "Audio Output"
                                font.family: Theme.fontSans
                                font.pixelSize: 11
                                color: Theme.fg
                            }
                            Text {
                                text: slidersCol.sinksExpanded ? "▴" : "▾"
                                font.pixelSize: 11
                                color: Theme.muted
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: slidersCol.sinksExpanded = !slidersCol.sinksExpanded
                        }
                    }

                    ColumnLayout {
                        visible: slidersCol.sinksExpanded && Audio.sinks.length > 1
                        Layout.fillWidth: true
                        spacing: 4
                        Repeater {
                            model: Audio.sinks
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool isCurr: Audio.defaultSink && modelData.id === Audio.defaultSink.id
                                Layout.fillWidth: true
                                height: 24
                                radius: 7
                                color: isCurr ? Theme.accentSoft : Qt.rgba(1, 1, 1, 0.04)
                                border.width: 1
                                border.color: isCurr ? Theme.accentBorder : "transparent"
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    elide: Text.ElideRight
                                    text: (isCurr ? "✓ " : "") + (modelData.description || modelData.name || "Output")
                                    font.family: Theme.fontSans
                                    font.pixelSize: 11
                                    color: isCurr ? Theme.accent : Theme.muted
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Audio.setDefaultSink(modelData);
                                        slidersCol.sinksExpanded = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // TABBED STUDIO CARD (Music Vinyl + Cava | Focus Pomodoro | Notes)
            GlassCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 196
                radiusValue: 14

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    // Tab Bar
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: [
                                { idx: 0, label: "󰎈  Studio" },
                                { idx: 1, label: "󱎫  Focus" },
                                { idx: 2, label: "󰠮  Notes" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool sel: ccWin.activeTab === modelData.idx
                                Layout.fillWidth: true
                                height: 26
                                radius: 8
                                color: sel ? Theme.accent : Qt.rgba(1, 1, 1, 0.05)
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.family: Theme.fontSans
                                    font.pixelSize: 11
                                    font.bold: sel
                                    color: sel ? Theme.accentFg : Theme.muted
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ccWin.activeTab = modelData.idx
                                }
                            }
                        }
                    }

                    // TAB 0: VINYL + CAVA MUSIC STUDIO
                    ColumnLayout {
                        visible: ccWin.activeTab === 0
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 12

                            // Spinning Vinyl Disc
                            Item {
                                Layout.preferredWidth: 84
                                Layout.preferredHeight: 84

                                Rectangle {
                                    id: vinylDisc
                                    anchors.fill: parent
                                    radius: 42
                                    color: "#0e0e12"
                                    border.width: 2
                                    border.color: Theme.accentBorder

                                    RotationAnimation on rotation {
                                        from: 0; to: 360
                                        duration: 9000
                                        loops: Animation.Infinite
                                        running: ccWin.isOpen && ccWin.activeTab === 0 && Media.isPlaying
                                    }

                                    // Vinyl groove rings
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 70; height: 70; radius: 35
                                        color: "transparent"
                                        border.width: 1
                                        border.color: Qt.rgba(1, 1, 1, 0.08)
                                    }

                                    ClippingWrapperRectangle {
                                        anchors.centerIn: parent
                                        width: 52; height: 52; radius: 26
                                        Item {
                                            anchors.fill: parent
                                            Image {
                                                anchors.fill: parent
                                                source: Media.artUrl
                                                fillMode: Image.PreserveAspectCrop
                                                asynchronous: true
                                                sourceSize.width: 104
                                                sourceSize.height: 104
                                                visible: Media.artUrl !== ""
                                            }
                                            Rectangle {
                                                anchors.fill: parent
                                                visible: Media.artUrl === ""
                                                color: Theme.accentSoft
                                                Text { anchors.centerIn: parent; text: "󰎈"; font.family: Theme.fontMono; font.pixelSize: 20; color: Theme.accent }
                                            }
                                        }
                                    }

                                    // Center spindle hole
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 10; height: 10; radius: 5
                                        color: Theme.bg
                                        border.width: 1
                                        border.color: Theme.glassBorder
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 4

                                Text {
                                    Layout.fillWidth: true
                                    text: Media.hasPlayer ? Media.title : "Nothing Playing"
                                    elide: Text.ElideRight
                                    font.family: Theme.fontSans
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: Theme.fg
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: Media.hasPlayer ? (Media.artist || "Unknown Artist") : "Start Spotify, Zen, or mpv"
                                    elide: Text.ElideRight
                                    font.family: Theme.fontSans
                                    font.pixelSize: 12
                                    color: Theme.muted
                                }

                                // Live 18-bar Cava Spectrum
                                Row {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28
                                    spacing: 3
                                    Repeater {
                                        model: Cava.bars
                                        delegate: Item {
                                            required property real modelData
                                            width: 9
                                            height: 28
                                            Rectangle {
                                                anchors.bottom: parent.bottom
                                                width: 6
                                                radius: 3
                                                height: Math.max(3, modelData * 26)
                                                color: modelData > 0.65 ? Theme.tertiary : Theme.accent
                                                Behavior on height { NumberAnimation { duration: 45 } }
                                            }
                                        }
                                    }
                                }

                                // Controls
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 14
                                    Text {
                                        text: "󰒮"; font.family: Theme.fontMono; font.pixelSize: 16; color: Theme.fg
                                        MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: Media.previous() }
                                    }
                                    Rectangle {
                                        width: 30; height: 30; radius: 15; color: Theme.accent
                                        Text { anchors.centerIn: parent; text: Media.isPlaying ? "󰏤" : "󰐊"; font.family: Theme.fontMono; font.pixelSize: 15; color: Theme.accentFg }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Media.togglePlaying() }
                                    }
                                    Text {
                                        text: "󰒭"; font.family: Theme.fontMono; font.pixelSize: 16; color: Theme.fg
                                        MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: Media.next() }
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        visible: Media.length > 0
                                        text: Media.formatTime(Media.position) + " / " + Media.formatTime(Media.length)
                                        font.family: Theme.fontMono
                                        font.pixelSize: 10
                                        color: Theme.muted
                                    }
                                }
                            }
                        }

                        // Progress scrubber
                        GlassSlider {
                            visible: Media.length > 0
                            Layout.fillWidth: true
                            Layout.preferredHeight: 16
                            value: Media.length > 0 ? (Media.position / Media.length) : 0
                            interactive: Media.activePlayer ? Media.activePlayer.canSeek : false
                            onMoved: (v) => Media.seekTo(v * Media.length)
                        }
                    }

                    // TAB 1: POMODORO / FOCUS TIMER
                    ColumnLayout {
                        visible: ccWin.activeTab === 1
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 10

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 8
                            Repeater {
                                model: [
                                    { id: "focus", label: "Focus 25m" },
                                    { id: "break", label: "Break 5m" }
                                ]
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool sel: SystemInfo.pomodoroMode === modelData.id
                                    width: 90; height: 24; radius: 8
                                    color: sel ? Theme.accentSoft : "transparent"
                                    border.width: 1; border.color: sel ? Theme.accentBorder : Theme.glassBorder
                                    Text { anchors.centerIn: parent; text: modelData.label; font.family: Theme.fontSans; font.pixelSize: 11; color: sel ? Theme.accent : Theme.muted }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: SystemInfo.startPomodoro(modelData.id) }
                                }
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: SystemInfo.pomodoroFormatted
                            font.family: Theme.fontMono
                            font.pixelSize: 38
                            font.bold: true
                            color: SystemInfo.pomodoroRunning ? Theme.accent : Theme.fg
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 12
                            Rectangle {
                                width: 100; height: 30; radius: 10; color: Theme.accent
                                Text { anchors.centerIn: parent; text: SystemInfo.pomodoroRunning ? "Pause" : "Start"; font.family: Theme.fontSans; font.pixelSize: 12; font.bold: true; color: Theme.accentFg }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: SystemInfo.togglePomodoro() }
                            }
                            Rectangle {
                                width: 76; height: 30; radius: 10; color: Theme.glassSurface; border.width: 1; border.color: Theme.glassBorder
                                Text { anchors.centerIn: parent; text: "Reset"; font.family: Theme.fontSans; font.pixelSize: 12; color: Theme.muted }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: SystemInfo.resetPomodoro() }
                            }
                        }
                    }

                    // TAB 2: QUICK SCRATCHPAD NOTES
                    ColumnLayout {
                        visible: ccWin.activeTab === 2
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 6

                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true

                            TextArea {
                                id: notesArea
                                placeholderText: "Quick scratchpad (auto-saved)..."
                                placeholderTextColor: Theme.muted
                                color: Theme.fg
                                font.family: Theme.fontMono
                                font.pixelSize: 12
                                wrapMode: TextEdit.Wrap
                                background: Rectangle {
                                    color: Qt.rgba(0, 0, 0, 0.22)
                                    radius: 8
                                }
                                onTextChanged: saveNotesTimer.restart()
                            }
                        }

                        Timer {
                            id: saveNotesTimer
                            interval: 600
                            onTriggered: notesFile.setText(notesArea.text)
                        }
                    }
                }
            }

            // NOTIFICATION HISTORY HEADER
            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Notifications (" + Notifications.historyModel.count + ")"
                    font.family: Theme.fontSans
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.fg
                }
                Item { Layout.fillWidth: true }
                Text {
                    visible: Notifications.historyModel.count > 0
                    text: "Clear all"
                    font.family: Theme.fontSans
                    font.pixelSize: 12
                    color: clrM.containsMouse ? Theme.error : Theme.accent
                    MouseArea {
                        id: clrM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifications.clearAll()
                    }
                }
            }

            // NOTIFICATION HISTORY LIST
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    anchors.centerIn: parent
                    visible: Notifications.historyModel.count === 0
                    text: "All caught up"
                    font.family: Theme.fontSans
                    font.pixelSize: 12
                    color: Theme.muted
                }

                ListView {
                    anchors.fill: parent
                    clip: true
                    spacing: 6
                    model: Notifications.historyModel

                    delegate: GlassCard {
                        required property int uid
                        required property string appName
                        required property string summary
                        required property string body
                        required property string timeStr
                        required property int urgency

                        width: ListView.view.width
                        height: histCol.implicitHeight + 16
                        radiusValue: 11
                        highlighted: urgency === 2

                        ColumnLayout {
                            id: histCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 8
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: appName
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    color: Theme.accent
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: timeStr
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    color: Theme.muted
                                }
                                Text {
                                    text: " ✕"
                                    font.pixelSize: 10
                                    color: Theme.muted
                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -4
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Notifications.dismiss(uid)
                                    }
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                text: summary
                                elide: Text.ElideRight
                                font.family: Theme.fontSans
                                font.pixelSize: 12
                                font.bold: true
                                color: Theme.fg
                            }
                            Text {
                                visible: body !== ""
                                Layout.fillWidth: true
                                text: body
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                font.family: Theme.fontSans
                                font.pixelSize: 11
                                color: Theme.muted
                            }
                        }
                    }
                }
            }
        }
    }
}
