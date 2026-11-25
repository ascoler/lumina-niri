import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../services"
import "../components"

PanelWindow {
    id: barWin

    signal toggleLauncher()
    signal toggleControlCenter(int initialTab)
    signal toggleWallpaper()
    signal toggleTheme()
    signal togglePower()
    signal randomWallpaper()

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 44
    color: "transparent"
    WlrLayershell.namespace: "lumina-bar"

    property string clockStr: ""
    property string dateStr: ""

    function updateClock() {
        const d = new Date();
        clockStr = Qt.formatTime(d, "hh:mm");
        dateStr = Qt.formatDate(d, "ddd d MMM");
    }

    Component.onCompleted: updateClock()

    Timer {
        interval: 5000
        repeat: true
        running: true
        onTriggered: barWin.updateClock()
    }

    Item {
        anchors.fill: parent
        anchors.topMargin: 6
        anchors.leftMargin: 10
        anchors.rightMargin: 10

        // LEFT ISLANDS
        RowLayout {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            // Arch / Launcher Pill
            GlassCard {
                id: launcherPill
                Layout.preferredWidth: 36
                Layout.preferredHeight: 34
                radiusValue: 11
                highlighted: launcherMouse.containsMouse

                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: Theme.fontMono
                    font.pixelSize: 15
                    color: Theme.accent
                }

                MouseArea {
                    id: launcherMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: barWin.toggleLauncher()
                }
            }

            // Niri Workspaces Island
            GlassCard {
                Layout.preferredHeight: 34
                Layout.preferredWidth: wsRow.implicitWidth + 14
                radiusValue: 11

                Row {
                    id: wsRow
                    anchors.centerIn: parent
                    spacing: 5

                    Repeater {
                        model: Niri.workspaces.filter(w => !barWin.screen || w.output === barWin.screen.name)

                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool isActive: !!modelData.is_active
                            readonly property int winCount: Niri.windowCountForWorkspace(modelData.id)

                            width: isActive ? 32 : (winCount > 0 ? 22 : 16)
                            height: 22
                            radius: 8
                            color: isActive
                                ? Theme.accent
                                : (modelData.is_urgent
                                    ? Theme.error
                                    : (wsMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.06)))

                            Behavior on width { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            Row {
                                anchors.centerIn: parent
                                spacing: 3

                                Text {
                                    text: modelData.idx
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                    font.bold: isActive
                                    color: isActive ? Theme.accentFg : (winCount > 0 ? Theme.fg : Theme.muted)
                                }

                                Rectangle {
                                    visible: !isActive && winCount > 0
                                    width: 4
                                    height: 4
                                    radius: 2
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Theme.accent
                                }
                            }

                            MouseArea {
                                id: wsMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Niri.focusWorkspace(modelData.idx)
                            }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: (w) => {
                        if (w.angleDelta.y > 0) Niri.msgAction(["focus-workspace-up"]);
                        else Niri.msgAction(["focus-workspace-down"]);
                    }
                }
            }

            // Live Media Pill (when MPRIS active) OR Active Window Title
            GlassCard {
                visible: Media.hasPlayer
                Layout.preferredHeight: 34
                Layout.preferredWidth: Math.min(270, mediaRow.implicitWidth + 16)
                radiusValue: 11
                highlighted: mediaMouse.containsMouse

                RowLayout {
                    id: mediaRow
                    anchors.fill: parent
                    anchors.leftMargin: 7
                    anchors.rightMargin: 7
                    spacing: 6

                    ClippingWrapperRectangle {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        radius: 6
                        visible: Media.artUrl !== ""

                        Image {
                            anchors.fill: parent
                            source: Media.artUrl
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 48
                            sourceSize.height: 48
                        }
                    }

                    Text {
                        visible: Media.artUrl === ""
                        text: Media.isPlaying ? "󰎈" : "󰏤"
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        color: Theme.accent
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 140
                        text: Media.title + (Media.artist ? " · " + Media.artist : "")
                        elide: Text.ElideRight
                        font.family: Theme.fontSans
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Theme.fg
                    }

                    Text {
                        text: "󰒮"
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        color: prevM.containsMouse ? Theme.accent : Theme.muted
                        MouseArea {
                            id: prevM
                            anchors.fill: parent
                            anchors.margins: -3
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Media.previous()
                        }
                    }

                    Text {
                        text: Media.isPlaying ? "󰏤" : "󰐊"
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        color: Theme.accent
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -3
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Media.togglePlaying()
                        }
                    }

                    Text {
                        text: "󰒭"
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        color: nextM.containsMouse ? Theme.accent : Theme.muted
                        MouseArea {
                            id: nextM
                            anchors.fill: parent
                            anchors.margins: -3
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Media.next()
                        }
                    }
                }

                MouseArea {
                    id: mediaMouse
                    anchors.fill: parent
                    z: -1
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: barWin.toggleControlCenter(0)
                }
            }

            // Focused App Chip (subtle, shown when no media pill or enough room)
            GlassCard {
                visible: !Media.hasPlayer && !!Niri.focusedWindow
                Layout.preferredHeight: 34
                Layout.preferredWidth: Math.min(220, winLabel.implicitWidth + 20)
                radiusValue: 11

                Text {
                    id: winLabel
                    anchors.centerIn: parent
                    width: Math.min(implicitWidth, 196)
                    text: Niri.focusedWindow ? (Niri.focusedWindow.title || Niri.focusedWindow.app_id || "") : ""
                    elide: Text.ElideRight
                    font.family: Theme.fontSans
                    font.pixelSize: 12
                    color: Theme.muted
                }
            }
        }

        // CENTER ISLAND: Clock + Weather + Focus Timer + Wallpaper Trigger
        GlassCard {
            anchors.centerIn: parent
            height: 34
            width: centerRow.implicitWidth + 20
            radiusValue: 12
            highlighted: centerMouse.containsMouse || SystemInfo.pomodoroRunning

            RowLayout {
                id: centerRow
                anchors.centerIn: parent
                spacing: 10

                Text {
                    text: barWin.clockStr
                    font.family: Theme.fontMono
                    font.pixelSize: 13
                    font.bold: true
                    color: Theme.fg
                }

                Rectangle { width: 1; height: 14; color: Theme.glassBorder }

                Text {
                    text: barWin.dateStr
                    font.family: Theme.fontSans
                    font.pixelSize: 12
                    color: Theme.muted
                }

                Rectangle {
                    visible: SystemInfo.weatherText !== ""
                    width: 1; height: 14; color: Theme.glassBorder
                }

                Row {
                    visible: SystemInfo.weatherText !== ""
                    spacing: 4
                    Text {
                        text: SystemInfo.weatherIcon
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        color: Theme.accent
                    }
                    Text {
                        text: SystemInfo.weatherText
                        font.family: Theme.fontSans
                        font.pixelSize: 12
                        color: Theme.fg
                    }
                }

                // Active Pomodoro badge
                Rectangle {
                    visible: SystemInfo.pomodoroActive
                    width: pomoTxt.implicitWidth + 12
                    height: 22
                    radius: 7
                    color: Theme.accentSoft
                    border.width: 1
                    border.color: Theme.accentBorder

                    Text {
                        id: pomoTxt
                        anchors.centerIn: parent
                        text: (SystemInfo.pomodoroMode === "focus" ? "󱎫 " : "󰅶 ") + SystemInfo.pomodoroFormatted
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        font.bold: true
                        color: Theme.accent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: barWin.toggleControlCenter(1)
                    }
                }

                Rectangle { width: 1; height: 14; color: Theme.glassBorder }

                // Wallpaper Carousel trigger
                Text {
                    text: "󰸉"
                    font.family: Theme.fontMono
                    font.pixelSize: 14
                    color: wallMouse.containsMouse ? Theme.accent : Theme.muted

                    MouseArea {
                        id: wallMouse
                        anchors.fill: parent
                        anchors.margins: -5
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (m) => {
                            if (m.button === Qt.RightButton) barWin.randomWallpaper();
                            else barWin.toggleWallpaper();
                        }
                    }
                }

                // Theme Switcher trigger
                Text {
                    text: "󰔎"
                    font.family: Theme.fontMono
                    font.pixelSize: 14
                    color: themeMouse.containsMouse ? Theme.tertiary : Theme.muted

                    MouseArea {
                        id: themeMouse
                        anchors.fill: parent
                        anchors.margins: -5
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: barWin.toggleTheme()
                    }
                }
            }

            MouseArea {
                id: centerMouse
                anchors.fill: parent
                z: -1
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: barWin.toggleControlCenter(1)
            }
        }

        // RIGHT ISLANDS
        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            // Live Screencast Warning Pill
            GlassCard {
                visible: Niri.isCasting
                Layout.preferredHeight: 34
                Layout.preferredWidth: 34
                radiusValue: 11
                highlighted: true

                Rectangle {
                    anchors.centerIn: parent
                    width: 10
                    height: 10
                    radius: 5
                    color: Theme.error
                }
            }

            // Pacman Updates Chip (only shown when > 0)
            GlassCard {
                visible: SystemInfo.updatesCount > 0
                Layout.preferredHeight: 34
                Layout.preferredWidth: updRow.implicitWidth + 16
                radiusValue: 11

                Row {
                    id: updRow
                    anchors.centerIn: parent
                    spacing: 5
                    Text {
                        text: "󰏖"
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        color: Theme.secondary
                    }
                    Text {
                        text: SystemInfo.updatesCount
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        color: Theme.fg
                    }
                }
            }

            // Keyboard Layout Pill (US / RU instant via Niri IPC)
            GlassCard {
                Layout.preferredHeight: 34
                Layout.preferredWidth: 38
                radiusValue: 11
                highlighted: kbMouse.containsMouse

                Text {
                    anchors.centerIn: parent
                    text: Niri.layoutShort
                    font.family: Theme.fontMono
                    font.pixelSize: 11
                    font.bold: true
                    color: Theme.accent
                }

                MouseArea {
                    id: kbMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Niri.switchLayout()
                }
            }

            // System Tray
            GlassCard {
                visible: SystemTray.items && SystemTray.items.values && SystemTray.items.values.length > 0
                Layout.preferredHeight: 34
                Layout.preferredWidth: trayRow.implicitWidth + 14
                radiusValue: 11

                Row {
                    id: trayRow
                    anchors.centerIn: parent
                    spacing: 6

                    Repeater {
                        model: SystemTray.items ? SystemTray.items.values : []
                        delegate: Item {
                            required property var modelData
                            width: 18
                            height: 18

                            IconImage {
                                anchors.fill: parent
                                source: modelData.icon || ""
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: (m) => {
                                    if (m.button === Qt.RightButton && modelData.hasMenu) {
                                        const pos = mapToItem(null, 0, height + 6);
                                        modelData.display(barWin, pos.x, pos.y);
                                    } else {
                                        modelData.activate();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Unified Hardware & Status Island
            GlassCard {
                Layout.preferredHeight: 34
                Layout.preferredWidth: hwRow.implicitWidth + 18
                radiusValue: 11
                highlighted: hwMouse.containsMouse

                RowLayout {
                    id: hwRow
                    anchors.centerIn: parent
                    spacing: 9

                    // Night Light indicator
                    Text {
                        visible: SystemInfo.nightLight
                        text: "󰖔"
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        color: Theme.tertiary
                    }

                    // Caffeine indicator
                    Text {
                        visible: SystemInfo.caffeine
                        text: "󰅶"
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        color: Theme.secondary
                    }

                    // Wi-Fi
                    Text {
                        text: SystemInfo.wifiEnabled
                            ? (SystemInfo.wifiSsid !== "" ? "󰤨" : "󰤯")
                            : "󰤮"
                        font.family: Theme.fontMono
                        font.pixelSize: 14
                        color: SystemInfo.wifiSsid !== "" ? Theme.secondary : Theme.muted
                    }

                    // Bluetooth
                    Text {
                        text: SystemInfo.btEnabled ? "󰂯" : "󰂲"
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        color: SystemInfo.btEnabled ? Theme.accent : Theme.muted
                    }

                    // Volume
                    Item {
                        Layout.preferredWidth: volRow.implicitWidth
                        Layout.preferredHeight: 24
                        Row {
                            id: volRow
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: Audio.muted ? "󰝟" : (Audio.volume > 0.5 ? "󰕾" : "󰖀")
                                font.family: Theme.fontMono
                                font.pixelSize: 14
                                color: Audio.muted ? Theme.error : Theme.accent
                            }
                            Text {
                                text: Audio.muted ? "Mute" : Math.round(Audio.volume * 100) + "%"
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                color: Theme.fg
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.MiddleButton | Qt.RightButton
                            onClicked: Audio.toggleMute()
                            onWheel: (w) => {
                                Audio.setVolume(Audio.volume + (w.angleDelta.y > 0 ? 0.05 : -0.05));
                            }
                        }
                    }

                    // Brightness
                    Item {
                        visible: SystemInfo.hasBacklight
                        Layout.preferredWidth: briRow.implicitWidth
                        Layout.preferredHeight: 24
                        Row {
                            id: briRow
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: "󰃠"
                                font.family: Theme.fontMono
                                font.pixelSize: 13
                                color: Theme.tertiary
                            }
                            Text {
                                text: Math.round(SystemInfo.brightness * 100) + "%"
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                color: Theme.fg
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onWheel: (w) => {
                                SystemInfo.adjustBrightness(w.angleDelta.y > 0 ? 0.05 : -0.05);
                            }
                        }
                    }

                    // Battery
                    Row {
                        visible: SystemInfo.hasBattery
                        spacing: 4
                        Text {
                            text: SystemInfo.isCharging ? "󱐋" : (SystemInfo.batteryPercent > 20 ? "󰁹" : "󰂃")
                            font.family: Theme.fontMono
                            font.pixelSize: 13
                            color: SystemInfo.isCharging
                                ? Theme.secondary
                                : (SystemInfo.batteryPercent <= 15 ? Theme.error : Theme.fg)
                        }
                        Text {
                            text: SystemInfo.batteryPercent + "%"
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: Theme.fg
                        }
                    }
                }

                MouseArea {
                    id: hwMouse
                    anchors.fill: parent
                    z: -1
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: barWin.toggleControlCenter(0)
                }
            }

            // Notifications Bell Pill
            GlassCard {
                Layout.preferredHeight: 34
                Layout.preferredWidth: bellRow.implicitWidth + 16
                radiusValue: 11
                highlighted: bellMouse.containsMouse || Notifications.unreadCount > 0

                Row {
                    id: bellRow
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        text: Notifications.dnd ? "󰂛" : (Notifications.unreadCount > 0 ? "󱅫" : "󰂚")
                        font.family: Theme.fontMono
                        font.pixelSize: 14
                        color: Notifications.dnd ? Theme.muted : (Notifications.unreadCount > 0 ? Theme.accent : Theme.fg)
                    }
                    Text {
                        visible: Notifications.unreadCount > 0 && !Notifications.dnd
                        text: Notifications.unreadCount
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.bold: true
                        color: Theme.accent
                    }
                }

                MouseArea {
                    id: bellMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: (m) => {
                        if (m.button === Qt.RightButton) Notifications.toggleDnd();
                        else barWin.toggleControlCenter(0);
                    }
                }
            }

            // Power Button Pill
            GlassCard {
                Layout.preferredHeight: 34
                Layout.preferredWidth: 34
                radiusValue: 11
                highlighted: pwrMouse.containsMouse

                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: Theme.fontMono
                    font.pixelSize: 13
                    color: pwrMouse.containsMouse ? Theme.error : Theme.muted
                }

                MouseArea {
                    id: pwrMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: barWin.togglePower()
                }
            }
        }
    }
}
