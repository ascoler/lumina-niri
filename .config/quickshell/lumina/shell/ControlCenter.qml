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
    signal openBarStyleSwitcher()
    signal openPowerMenu()

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: Qt.rgba(0, 0, 0, 0.28)
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
            hubEnterAnim.restart();
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
        id: hub
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 60
        width: Math.min(768, parent.width - 36)
        height: Math.min(
            parent.height - 90,
            536
            + (ccWin.expandedPane !== "" ? 122 : 0)
            + (slidersCol.sinksExpanded && Audio.sinks.length > 1 ? Math.min(96, Audio.sinks.length * 28 + 4) : 0)
        )
        radiusValue: 20
        strong: true
        highlighted: true

        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        property real slideOffset: 0
        transform: Translate { y: hub.slideOffset }
        transformOrigin: Item.Top

        ParallelAnimation {
            id: hubEnterAnim
            NumberAnimation { target: hub; property: "slideOffset"; from: -14; to: 0; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { target: hub; property: "scale"; from: 0.96; to: 1.0; duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.08 }
            NumberAnimation { target: hub; property: "opacity"; from: 0.0; to: 1.0; duration: 160; easing.type: Easing.OutCubic }
        }

        // Absorb clicks inside hub
        MouseArea { anchors.fill: parent; z: -1 }

        ColumnLayout {
            id: hubMainCol
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // ==================== CLEAN HUB HEADER ====================
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

                // Active Color Theme pill
                Rectangle {
                    width: presetLbl.implicitWidth + 16
                    height: 24
                    radius: 8
                    color: themePillM.containsMouse ? Theme.accent : Theme.accentSoft
                    border.width: 1
                    border.color: Theme.accentBorder
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        id: presetLbl
                        anchors.centerIn: parent
                        text: "󰔎 " + Theme.presetName
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                        color: themePillM.containsMouse ? Theme.accentFg : Theme.accent
                    }
                    MouseArea {
                        id: themePillM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ccWin.closeRequested();
                            ccWin.openThemeSwitcher();
                        }
                    }
                }

                // Active Bar Style pill
                Rectangle {
                    width: stylePillLbl.implicitWidth + 16
                    height: 24
                    radius: 8
                    color: stylePillM.containsMouse ? Theme.glassHigh : Theme.glassSurface
                    border.width: 1
                    border.color: stylePillM.containsMouse ? Theme.accentBorder : Theme.glassBorder
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        id: stylePillLbl
                        anchors.centerIn: parent
                        text: "󰕮 " + Theme.barStyleInfo(Theme.barStyle).name
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        color: stylePillM.containsMouse ? Theme.fg : Theme.muted
                    }
                    MouseArea {
                        id: stylePillM
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (m) => {
                            if (m.button === Qt.RightButton) {
                                Theme.cycleBarStyle(1);
                            } else {
                                ccWin.closeRequested();
                                ccWin.openBarStyleSwitcher();
                            }
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
                    scale: bdM.containsMouse ? 1.08 : 1.0
                    Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutBack } }
                    Text { anchors.centerIn: parent; text: "󰍹"; font.family: Theme.fontMono; font.pixelSize: 13; color: SystemInfo.backdropWidgets ? Theme.accent : Theme.muted }
                    MouseArea { id: bdM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: SystemInfo.toggleBackdropWidgets() }
                }

                // Lock
                Rectangle {
                    width: 28; height: 28; radius: 9
                    color: lockM.containsMouse ? Theme.glassHigh : Theme.glassSurface
                    border.width: 1; border.color: lockM.containsMouse ? Theme.accentBorder : Theme.glassBorder
                    scale: lockM.containsMouse ? 1.08 : 1.0
                    Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutBack } }
                    Text { anchors.centerIn: parent; text: "󰌾"; font.family: Theme.fontMono; font.pixelSize: 13; color: Theme.fg }
                    MouseArea {
                        id: lockM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { ccWin.closeRequested(); cmdProc.exec(["hyprlock"]); }
                    }
                }

                // Power
                Rectangle {
                    width: 28; height: 28; radius: 9
                    color: pwrHubM.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.18) : Theme.glassSurface
                    border.width: 1; border.color: pwrHubM.containsMouse ? Theme.error : Theme.glassBorder
                    scale: pwrHubM.containsMouse ? 1.08 : 1.0
                    Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutBack } }
                    Text { anchors.centerIn: parent; text: ""; font.family: Theme.fontMono; font.pixelSize: 13; color: Theme.error }
                    MouseArea {
                        id: pwrHubM; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { ccWin.closeRequested(); ccWin.openPowerMenu(); }
                    }
                }
            }

            // ==================== SYMMETRIC TWO-COLUMN BENTO ====================
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                // ---------- LEFT COLUMN: NOTIFICATIONS + VITALS (Fixed 316px) ----------
                ColumnLayout {
                    Layout.fillWidth: false
                    Layout.preferredWidth: 316
                    Layout.minimumWidth: 316
                    Layout.maximumWidth: 316
                    Layout.fillHeight: true
                    spacing: 10

                    // NOTIFICATIONS CARD
                    GlassCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radiusValue: 16

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 7

                                Text {
                                    text: Notifications.dnd ? "󰂛" : "󰂚"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 15
                                    color: Notifications.dnd ? Theme.muted : Theme.accent
                                }

                                Text {
                                    text: "Notifications"
                                    font.family: Theme.fontSans
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: Theme.fg
                                }

                                Rectangle {
                                    visible: Notifications.historyModel.count > 0
                                    width: Math.max(20, cntTxt.implicitWidth + 10)
                                    height: 18
                                    radius: 9
                                    color: Theme.accentSoft
                                    border.width: 1; border.color: Theme.accentBorder
                                    Text {
                                        id: cntTxt
                                        anchors.centerIn: parent
                                        text: Notifications.historyModel.count
                                        font.family: Theme.fontMono
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: Theme.accent
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    width: dndTxt.implicitWidth + 14
                                    height: 22
                                    radius: 8
                                    color: Notifications.dnd ? Theme.accent : Qt.rgba(1, 1, 1, 0.05)
                                    border.width: 1
                                    border.color: Notifications.dnd ? Theme.accent : Theme.glassBorder
                                    Text {
                                        id: dndTxt
                                        anchors.centerIn: parent
                                        text: Notifications.dnd ? "DND On" : "DND"
                                        font.family: Theme.fontSans
                                        font.pixelSize: 10
                                        font.bold: Notifications.dnd
                                        color: Notifications.dnd ? Theme.accentFg : Theme.muted
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Notifications.toggleDnd()
                                    }
                                }

                                Rectangle {
                                    visible: Notifications.historyModel.count > 0
                                    width: clrTxt.implicitWidth + 14
                                    height: 22
                                    radius: 8
                                    color: clrM.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.18) : Qt.rgba(1, 1, 1, 0.05)
                                    border.width: 1
                                    border.color: clrM.containsMouse ? Theme.error : Theme.glassBorder
                                    Text {
                                        id: clrTxt
                                        anchors.centerIn: parent
                                        text: "Clear"
                                        font.family: Theme.fontSans
                                        font.pixelSize: 10
                                        color: clrM.containsMouse ? Theme.error : Theme.muted
                                    }
                                    MouseArea {
                                        id: clrM
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Notifications.clearAll()
                                    }
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                Column {
                                    anchors.centerIn: parent
                                    visible: Notifications.historyModel.count === 0
                                    spacing: 8
                                    width: parent.width - 24

                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 50; height: 50; radius: 25
                                        color: Theme.accentSoft
                                        border.width: 1
                                        border.color: Theme.accentBorder

                                        Text {
                                            anchors.centerIn: parent
                                            text: Notifications.dnd ? "󰂛" : "󰂚"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 20
                                            color: Theme.accent
                                        }
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: Notifications.dnd ? "Do Not Disturb is active" : "All caught up"
                                        font.family: Theme.fontSans
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: Theme.fg
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                        wrapMode: Text.WordWrap
                                        text: Notifications.dnd
                                            ? "Popups are silenced until you turn DND off"
                                            : "Incoming app notifications & alerts appear here"
                                        font.family: Theme.fontSans
                                        font.pixelSize: 11
                                        color: Theme.muted
                                    }
                                }

                                ListView {
                                    anchors.fill: parent
                                    visible: Notifications.historyModel.count > 0
                                    clip: true
                                    spacing: 8
                                    model: Notifications.historyModel

                                    add: Transition {
                                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
                                        NumberAnimation { property: "x"; from: -14; to: 0; duration: 200; easing.type: Easing.OutCubic }
                                    }
                                    displaced: Transition {
                                        NumberAnimation { properties: "x,y"; duration: 180; easing.type: Easing.OutCubic }
                                    }

                                    delegate: GlassCard {
                                        id: histCard
                                        required property int uid
                                        required property string appName
                                        required property string appIcon
                                        required property string image
                                        required property string summary
                                        required property string body
                                        required property string timeStr
                                        required property int urgency
                                        required property string actionsJson

                                        width: ListView.view.width
                                        height: histCol.implicitHeight + 18
                                        radiusValue: 12
                                        specular: false
                                        highlighted: urgency === 2 || cardHover.containsMouse
                                        color: cardHover.containsMouse
                                            ? Qt.rgba(Theme.surfaceHigh.r, Theme.surfaceHigh.g, Theme.surfaceHigh.b, 0.85)
                                            : Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.55)

                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            anchors.leftMargin: 4
                                            anchors.topMargin: 8
                                            anchors.bottomMargin: 8
                                            width: 3
                                            radius: 1.5
                                            color: histCard.urgency === 2 ? Theme.error : Theme.accent
                                        }

                                        ColumnLayout {
                                            id: histCol
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.leftMargin: 13
                                            anchors.rightMargin: 10
                                            anchors.topMargin: 9
                                            spacing: 5

                                            RowLayout {
                                                Layout.fillWidth: true
                                                spacing: 8

                                                ClippingWrapperRectangle {
                                                    Layout.preferredWidth: 26
                                                    Layout.preferredHeight: 26
                                                    radius: 7
                                                    visible: histCard.image !== "" || histCard.appIcon !== ""

                                                    Item {
                                                        anchors.fill: parent
                                                        Image {
                                                            anchors.fill: parent
                                                            visible: histCard.image !== ""
                                                            source: histCard.image
                                                            fillMode: Image.PreserveAspectCrop
                                                            asynchronous: true
                                                            sourceSize.width: 52
                                                            sourceSize.height: 52
                                                        }
                                                        IconImage {
                                                            anchors.fill: parent
                                                            visible: histCard.image === "" && histCard.appIcon !== ""
                                                            source: histCard.appIcon
                                                        }
                                                    }
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 1
                                                    RowLayout {
                                                        Layout.fillWidth: true
                                                        Text {
                                                            text: histCard.appName
                                                            font.family: Theme.fontMono
                                                            font.pixelSize: 10
                                                            font.bold: true
                                                            color: histCard.urgency === 2 ? Theme.error : Theme.accent
                                                        }
                                                        Item { Layout.fillWidth: true }
                                                        Text {
                                                            text: histCard.timeStr
                                                            font.family: Theme.fontMono
                                                            font.pixelSize: 10
                                                            color: Theme.muted
                                                        }
                                                    }
                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: histCard.summary
                                                        elide: Text.ElideRight
                                                        font.family: Theme.fontSans
                                                        font.pixelSize: 12
                                                        font.bold: true
                                                        color: Theme.fg
                                                    }
                                                }

                                                Rectangle {
                                                    width: 20; height: 20; radius: 10
                                                    color: disM.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.22) : Qt.rgba(1, 1, 1, 0.06)
                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: "✕"
                                                        font.pixelSize: 9
                                                        color: disM.containsMouse ? Theme.error : Theme.muted
                                                    }
                                                    MouseArea {
                                                        id: disM
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: Notifications.dismiss(histCard.uid)
                                                    }
                                                }
                                            }

                                            Text {
                                                visible: histCard.body !== ""
                                                Layout.fillWidth: true
                                                text: histCard.body
                                                wrapMode: Text.WordWrap
                                                maximumLineCount: 3
                                                elide: Text.ElideRight
                                                font.family: Theme.fontSans
                                                font.pixelSize: 11
                                                color: Theme.muted
                                            }

                                            Flow {
                                                visible: parsedActions.length > 0
                                                Layout.fillWidth: true
                                                spacing: 5
                                                property var parsedActions: {
                                                    try { return JSON.parse(histCard.actionsJson); }
                                                    catch (e) { return []; }
                                                }
                                                Repeater {
                                                    model: parent.parsedActions
                                                    delegate: Rectangle {
                                                        required property var modelData
                                                        width: hActTxt.implicitWidth + 14
                                                        height: 22
                                                        radius: 7
                                                        color: hActM.containsMouse ? Theme.accent : Theme.accentSoft
                                                        border.width: 1; border.color: Theme.accentBorder
                                                        Text {
                                                            id: hActTxt
                                                            anchors.centerIn: parent
                                                            text: modelData.text
                                                            font.family: Theme.fontSans
                                                            font.pixelSize: 10
                                                            font.bold: true
                                                            color: hActM.containsMouse ? Theme.accentFg : Theme.accent
                                                        }
                                                        MouseArea {
                                                            id: hActM
                                                            anchors.fill: parent
                                                            hoverEnabled: true
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: Notifications.invokeAction(histCard.uid, modelData.identifier)
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: cardHover
                                            anchors.fill: parent
                                            z: -1
                                            hoverEnabled: true
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // COMPACT LIVE SYSTEM VITALS CARD
                    GlassCard {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 82
                        radiusValue: 16

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "󰍛  SYSTEM VITALS"
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
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: SystemInfo.cpuTemp > 80 ? Theme.error : Theme.tertiary
                                }
                            }

                            Row {
                                id: vitalsRow
                                Layout.fillWidth: true
                                spacing: 14

                                ColumnLayout {
                                    width: Math.floor((vitalsRow.width - 14) / 2)
                                    spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "CPU"; font.family: Theme.fontMono; font.pixelSize: 10; color: Theme.muted }
                                        Item { Layout.fillWidth: true }
                                        Text { text: SystemInfo.cpuPercent + "%"; font.family: Theme.fontMono; font.pixelSize: 10; font.bold: true; color: Theme.fg }
                                    }
                                    Rectangle {
                                        Layout.fillWidth: true; height: 6; radius: 3; color: Qt.rgba(1, 1, 1, 0.08)
                                        Rectangle {
                                            width: Math.max(4, (SystemInfo.cpuPercent / 100.0) * parent.width)
                                            height: parent.height; radius: 3; color: Theme.accent
                                            Behavior on width { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
                                        }
                                    }
                                }

                                ColumnLayout {
                                    width: Math.floor((vitalsRow.width - 14) / 2)
                                    spacing: 4
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "RAM"; font.family: Theme.fontMono; font.pixelSize: 10; color: Theme.muted }
                                        Item { Layout.fillWidth: true }
                                        Text { text: SystemInfo.memPercent + "%"; font.family: Theme.fontMono; font.pixelSize: 10; font.bold: true; color: Theme.fg }
                                    }
                                    Rectangle {
                                        Layout.fillWidth: true; height: 6; radius: 3; color: Qt.rgba(1, 1, 1, 0.08)
                                        Rectangle {
                                            width: Math.max(4, (SystemInfo.memPercent / 100.0) * parent.width)
                                            height: parent.height; radius: 3; color: Theme.secondary
                                            Behavior on width { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ---------- RIGHT COLUMN: QUICK TOGGLES + SLIDERS + STUDIO ----------
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 360
                    Layout.fillHeight: true
                    spacing: 10

                    // QUICK TOGGLES GRID (Exact Uniform 4x2 Columns)
                    Grid {
                        id: toggleGrid
                        Layout.fillWidth: true
                        columns: 4
                        columnSpacing: 8
                        rowSpacing: 8

                        Repeater {
                            model: [
                                { key: "wifi", icon: SystemInfo.wifiEnabled ? "󰤨" : "󰤮", label: "Wi-Fi", sub: SystemInfo.wifiSsid || (SystemInfo.wifiEnabled ? "On" : "Off"), active: SystemInfo.wifiEnabled, expandable: true },
                                { key: "bt", icon: SystemInfo.btEnabled ? "󰂯" : "󰂲", label: "Bluetooth", sub: SystemInfo.btEnabled ? "On" : "Off", active: SystemInfo.btEnabled, expandable: true },
                                { key: "night", icon: "󰖔", label: "Night Light", sub: SystemInfo.nightLight ? "Warm" : "Off", active: SystemInfo.nightLight, expandable: false },
                                { key: "caffeine", icon: "󰅶", label: "Caffeine", sub: SystemInfo.caffeine ? "Awake" : "Off", active: SystemInfo.caffeine, expandable: false },
                                { key: "dnd", icon: Notifications.dnd ? "󰂛" : "󰂚", label: "Silent", sub: Notifications.dnd ? "DND" : "Normal", active: Notifications.dnd, expandable: false },
                                { key: "mic", icon: Audio.micMuted ? "󰍭" : "󰍬", label: "Mic", sub: Audio.micMuted ? "Muted" : "Live", active: !Audio.micMuted, expandable: false },
                                { key: "shot", icon: "󰹑", label: "Capture", sub: "Region", active: false, expandable: false },
                                { key: "pick", icon: "󰈊", label: "Picker", sub: "Hex", active: false, expandable: false }
                            ]

                            delegate: Rectangle {
                                id: tileRect
                                required property var modelData
                                width: Math.floor((toggleGrid.width - 24) / 4)
                                height: 58
                                radius: 13
                                color: modelData.active ? Theme.accent : Theme.glassSurface
                                border.width: 1
                                border.color: modelData.active ? Theme.accent : (tileM.containsMouse ? Theme.accentBorder : Theme.glassBorder)

                                scale: tileM.pressed ? 0.94 : (tileM.containsMouse ? 1.03 : 1.0)
                                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 1
                                    width: parent.width - 12
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: tileRect.modelData.icon
                                        font.family: Theme.fontMono
                                        font.pixelSize: 16
                                        color: tileRect.modelData.active ? Theme.accentFg : Theme.accent
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                        text: tileRect.modelData.label
                                        font.family: Theme.fontSans
                                        font.pixelSize: 10
                                        font.bold: true
                                        color: tileRect.modelData.active ? Theme.accentFg : Theme.fg
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                        text: tileRect.modelData.sub
                                        font.family: Theme.fontSans
                                        font.pixelSize: 9
                                        color: tileRect.modelData.active ? Qt.rgba(Theme.accentFg.r, Theme.accentFg.g, Theme.accentFg.b, 0.78) : Theme.muted
                                    }
                                }

                                MouseArea {
                                    id: tileM
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: (m) => {
                                        const k = tileRect.modelData.key;
                                        if (m.button === Qt.RightButton && tileRect.modelData.expandable) {
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

                                Rectangle {
                                    visible: tileRect.modelData.expandable
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 4
                                    width: 16; height: 16; radius: 5
                                    color: expM.containsMouse ? Qt.rgba(0, 0, 0, 0.22) : "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        text: ccWin.expandedPane === tileRect.modelData.key ? "▴" : "▾"
                                        font.pixelSize: 9
                                        color: tileRect.modelData.active ? Theme.accentFg : Theme.muted
                                    }
                                    MouseArea {
                                        id: expM
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: ccWin.expandedPane = (ccWin.expandedPane === tileRect.modelData.key) ? "" : tileRect.modelData.key
                                    }
                                }
                            }
                        }
                    }

                    // EXPANDABLE WI-FI / BT DRAWER
                    GlassCard {
                        visible: ccWin.expandedPane !== ""
                        Layout.fillWidth: true
                        Layout.preferredHeight: 112
                        radiusValue: 14

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: ccWin.expandedPane === "wifi" ? "Wi-Fi Networks" : "Bluetooth Devices"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: Theme.accent
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    visible: ccWin.expandedPane === "wifi"
                                    text: "Full Menu"
                                    font.family: Theme.fontSans
                                    font.pixelSize: 10
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
                                    height: 26
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
                                            font.pixelSize: 11
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

                    // SLIDERS CARD
                    GlassCard {
                        Layout.fillWidth: true
                        Layout.preferredHeight: slidersCol.implicitHeight + 24
                        radiusValue: 15

                        ColumnLayout {
                            id: slidersCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 12
                            spacing: 8

                            property bool sinksExpanded: false

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

                    // TABBED STUDIO CARD
                    GlassCard {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 204
                        radiusValue: 16

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            Row {
                                id: tabRow
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
                                        width: Math.floor((tabRow.width - 12) / 3)
                                        height: 28
                                        radius: 9
                                        color: sel ? Theme.accent : Qt.rgba(1, 1, 1, 0.05)
                                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
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
                                    spacing: 14

                                    Item {
                                        Layout.preferredWidth: 86
                                        Layout.preferredHeight: 86
                                        Layout.alignment: Qt.AlignVCenter

                                        Rectangle {
                                            id: vinylDisc
                                            anchors.fill: parent
                                            radius: 43
                                            color: "#0e0e12"
                                            border.width: 2
                                            border.color: Media.isPlaying ? Theme.accent : Theme.accentBorder

                                            RotationAnimation on rotation {
                                                from: 0; to: 360
                                                duration: 9000
                                                loops: Animation.Infinite
                                                running: ccWin.isOpen && ccWin.activeTab === 0 && Media.isPlaying
                                            }

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

                                        Row {
                                            id: cavaRow
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 28
                                            spacing: 3
                                            Repeater {
                                                model: Cava.bars
                                                delegate: Item {
                                                    required property real modelData
                                                    width: Math.max(4, Math.floor((cavaRow.width - 17 * 3) / 18))
                                                    height: 28
                                                    Rectangle {
                                                        anchors.bottom: parent.bottom
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        width: Math.min(7, parent.width)
                                                        radius: 3
                                                        height: Math.max(3, modelData * 26)
                                                        color: modelData > 0.65 ? Theme.tertiary : Theme.accent
                                                        Behavior on height { NumberAnimation { duration: 45 } }
                                                    }
                                                }
                                            }
                                        }

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
                            Item {
                                visible: ccWin.activeTab === 1
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 12

                                    Row {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 8
                                        Repeater {
                                            model: [
                                                { id: "focus", label: "Focus 25m" },
                                                { id: "break", label: "Break 5m" }
                                            ]
                                            delegate: Rectangle {
                                                required property var modelData
                                                readonly property bool sel: SystemInfo.pomodoroMode === modelData.id
                                                width: 100; height: 28; radius: 9
                                                color: sel ? Theme.accentSoft : "transparent"
                                                border.width: 1; border.color: sel ? Theme.accentBorder : Theme.glassBorder
                                                Text { anchors.centerIn: parent; text: modelData.label; font.family: Theme.fontSans; font.pixelSize: 11; font.bold: sel; color: sel ? Theme.accent : Theme.muted }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: SystemInfo.startPomodoro(modelData.id) }
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: SystemInfo.pomodoroFormatted
                                        font.family: Theme.fontMono
                                        font.pixelSize: 42
                                        font.bold: true
                                        color: SystemInfo.pomodoroRunning ? Theme.accent : Theme.fg
                                    }

                                    Row {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 10
                                        Rectangle {
                                            width: 106; height: 32; radius: 10; color: Theme.accent
                                            Text { anchors.centerIn: parent; text: SystemInfo.pomodoroRunning ? "Pause" : "Start"; font.family: Theme.fontSans; font.pixelSize: 12; font.bold: true; color: Theme.accentFg }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: SystemInfo.togglePomodoro() }
                                        }
                                        Rectangle {
                                            width: 84; height: 32; radius: 10; color: Theme.glassSurface; border.width: 1; border.color: Theme.glassBorder
                                            Text { anchors.centerIn: parent; text: "Reset"; font.family: Theme.fontSans; font.pixelSize: 12; color: Theme.muted }
                                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: SystemInfo.resetPomodoro() }
                                        }
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
                }
            }
        }
    }
}
