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
    signal toggleBarStyle()
    signal togglePower()
    signal randomWallpaper()

    readonly property string st: Theme.barStyle
    readonly property bool isAurora: st === "aurora"
    readonly property bool isNotch: st === "notch"
    readonly property bool isCyber: st === "cyber"
    readonly property bool isEclipse: st === "eclipse"
    readonly property bool isMinimal: st === "minimal"

    readonly property int pillHeight: isNotch ? 34 : (isEclipse ? 36 : 36)
    readonly property real pillRadius: isCyber ? 6 : (isEclipse ? pillHeight / 2 : (isNotch ? 17 : (isMinimal ? 15 : 13)))
    readonly property real islandAlpha: isMinimal ? 0.34 : (isEclipse ? 0.91 : (isCyber ? 0.86 : 0.78))

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: isNotch ? 46 : 48
    color: "transparent"
    WlrLayershell.namespace: "lumina-bar"

    property string clockHour: "00"
    property string clockMin: "00"
    property string dateStr: ""
    property bool colonBright: true

    function updateClock() {
        const d = new Date();
        clockHour = Qt.formatTime(d, "hh");
        clockMin = Qt.formatTime(d, "mm");
        dateStr = Qt.formatDate(d, "ddd d MMM");
    }

    Component.onCompleted: {
        updateClock();
        entranceAnim.start();
    }

    Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: {
            barWin.updateClock();
            barWin.colonBright = !barWin.colonBright;
        }
    }

    Connections {
        target: Theme
        function onBarStyleChanged() {
            styleMorphAnim.restart();
        }
    }

    Item {
        id: barContainer
        anchors.fill: parent
        anchors.topMargin: barWin.isNotch ? 6 : 8
        anchors.leftMargin: barWin.isMinimal ? 14 : 12
        anchors.rightMargin: barWin.isMinimal ? 14 : 12
        anchors.bottomMargin: 2

        Behavior on anchors.topMargin { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Behavior on anchors.leftMargin { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Behavior on anchors.rightMargin { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        property real enterY: -14
        transform: Translate { y: barContainer.enterY }

        ParallelAnimation {
            id: entranceAnim
            NumberAnimation { target: barContainer; property: "enterY"; from: -16; to: 0; duration: 360; easing.type: Easing.OutCubic }
            NumberAnimation { target: barContainer; property: "opacity"; from: 0.0; to: 1.0; duration: 280; easing.type: Easing.OutCubic }
        }

        ParallelAnimation {
            id: styleMorphAnim
            NumberAnimation { target: barContainer; property: "opacity"; from: 0.55; to: 1.0; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { target: barContainer; property: "scale"; from: 0.985; to: 1.0; duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
        }

        // ==================== LEFT WING ====================
        RowLayout {
            id: leftWing
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: barWin.isMinimal ? 8 : 6

            // Arch / Launcher Pill
            GlassCard {
                id: launcherPill
                Layout.preferredWidth: barWin.isEclipse ? barWin.pillHeight : (barWin.pillHeight + 2)
                Layout.preferredHeight: barWin.pillHeight
                radiusValue: barWin.pillRadius
                strong: barWin.isEclipse
                specular: !barWin.isMinimal
                glassAlpha: launcherMouse.containsMouse ? 0.92 : barWin.islandAlpha
                color: barWin.isMinimal && !launcherMouse.containsMouse
                    ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.28)
                    : (barWin.isEclipse
                        ? Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, glassAlpha)
                        : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, glassAlpha))
                border.width: barWin.isCyber ? 1.5 : (barWin.isMinimal && !launcherMouse.containsMouse ? 0 : 1)
                highlighted: launcherMouse.containsMouse || barWin.isEclipse

                scale: launcherMouse.pressed ? 0.92 : (launcherMouse.containsMouse ? 1.05 : 1.0)
                Behavior on scale { NumberAnimation { duration: 170; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }

                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: Theme.fontMono
                    font.pixelSize: 15
                    color: launcherMouse.containsMouse ? Theme.fg : Theme.accent
                    Behavior on color { ColorAnimation { duration: 130 } }
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
                id: wsIsland
                Layout.preferredHeight: barWin.pillHeight
                Layout.preferredWidth: wsRow.implicitWidth + (barWin.isMinimal ? 12 : (barWin.isEclipse ? 18 : 16))
                radiusValue: barWin.pillRadius
                strong: barWin.isEclipse
                specular: !barWin.isMinimal
                color: barWin.isMinimal
                    ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.22)
                    : (barWin.isEclipse
                        ? Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, barWin.islandAlpha)
                        : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, barWin.islandAlpha))
                border.width: barWin.isCyber ? 1.5 : (barWin.isMinimal ? 0 : 1)
                customBorderColor: (barWin.isCyber || barWin.isEclipse) ? Theme.accentBorder : "transparent"

                Behavior on Layout.preferredWidth {
                    NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
                }

                Row {
                    id: wsRow
                    anchors.centerIn: parent
                    spacing: barWin.isMinimal ? 7 : 5

                    Repeater {
                        model: Niri.workspaces.filter(w => !barWin.screen || w.output === barWin.screen.name)

                        delegate: Item {
                            id: wsDelegate
                            required property var modelData
                            readonly property bool isActive: !!modelData.is_active
                            readonly property bool isUrgent: !!modelData.is_urgent
                            readonly property int winCount: Niri.windowCountForWorkspace(modelData.id)

                            width: {
                                if (barWin.isMinimal) return isActive ? 28 : (winCount > 0 ? 12 : 8);
                                if (barWin.isEclipse) return isActive ? 38 : 24;
                                return isActive ? 34 : (winCount > 0 ? 24 : 18);
                            }
                            height: barWin.isMinimal ? (isActive ? 14 : (winCount > 0 ? 12 : 8)) : (barWin.isEclipse ? 24 : 23)
                            anchors.verticalCenter: parent.verticalCenter

                            Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.25 } }
                            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                            scale: wsMouse.pressed ? 0.90 : (wsMouse.containsMouse && !isActive ? 1.12 : 1.0)
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }

                            Rectangle {
                                id: wsPill
                                anchors.fill: parent
                                radius: barWin.isCyber ? 4 : (barWin.isEclipse || barWin.isMinimal ? height / 2 : 8)

                                gradient: isActive && !barWin.isCyber ? activeWsGrad : null
                                color: {
                                    if (isActive) return barWin.isCyber ? Theme.accentSoft : Theme.accent;
                                    if (isUrgent) return Theme.error;
                                    if (wsMouse.containsMouse) return Qt.rgba(1, 1, 1, 0.16);
                                    if (barWin.isMinimal) return winCount > 0 ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.50) : Qt.rgba(1, 1, 1, 0.20);
                                    return winCount > 0 ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.035);
                                }
                                border.width: (barWin.isCyber && isActive) ? 1.5 : 0
                                border.color: Theme.accent

                                Gradient {
                                    id: activeWsGrad
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: Theme.accent }
                                    GradientStop { position: 1.0; color: Qt.lighter(Theme.tertiary, 1.02) }
                                }

                                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                SequentialAnimation on opacity {
                                    running: wsDelegate.isUrgent && !wsDelegate.isActive
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.35; duration: 480; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: 1.0; duration: 480; easing.type: Easing.InOutSine }
                                }

                                Rectangle {
                                    visible: barWin.isCyber && wsDelegate.isActive
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: parent.width - 8
                                    height: 2
                                    radius: 1
                                    color: Theme.accent
                                }

                                Row {
                                    visible: !barWin.isMinimal
                                    anchors.centerIn: parent
                                    spacing: 3

                                    Text {
                                        text: modelData.idx
                                        font.family: Theme.fontMono
                                        font.pixelSize: 11
                                        font.bold: wsDelegate.isActive
                                        color: wsDelegate.isActive
                                            ? (barWin.isCyber ? Theme.accent : Theme.accentFg)
                                            : (wsDelegate.winCount > 0 ? Theme.fg : Theme.muted)
                                    }

                                    Rectangle {
                                        visible: !wsDelegate.isActive && wsDelegate.winCount > 0
                                        width: 4
                                        height: 4
                                        radius: 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: Theme.accent
                                    }
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

            // Live Media Pill
            GlassCard {
                id: mediaPill
                visible: Media.hasPlayer && !barWin.isNotch
                Layout.preferredHeight: barWin.pillHeight
                Layout.preferredWidth: Math.min(286, mediaRow.implicitWidth + 20)
                radiusValue: barWin.pillRadius
                strong: barWin.isEclipse
                specular: !barWin.isMinimal
                highlighted: mediaMouse.containsMouse || Media.isPlaying || barWin.isEclipse
                color: barWin.isMinimal
                    ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, mediaMouse.containsMouse ? 0.70 : 0.35)
                    : (barWin.isEclipse
                        ? Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, barWin.islandAlpha)
                        : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, barWin.islandAlpha))
                border.width: barWin.isCyber ? 1.5 : (barWin.isMinimal && !mediaMouse.containsMouse ? 0 : 1)

                Behavior on Layout.preferredWidth { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                scale: mediaMouse.containsMouse ? 1.02 : 1.0
                Behavior on scale { NumberAnimation { duration: 170; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }

                RowLayout {
                    id: mediaRow
                    anchors.fill: parent
                    anchors.leftMargin: barWin.isEclipse ? 10 : 8
                    anchors.rightMargin: barWin.isEclipse ? 10 : 8
                    spacing: 7

                    ClippingWrapperRectangle {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        radius: barWin.isCyber ? 4 : (barWin.isEclipse ? 11 : 7)
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

                    EqualizerBars {
                        visible: Media.isPlaying || Media.artUrl === ""
                        active: Media.isPlaying
                        barCount: 4
                        barWidth: 2.5
                        maxHeight: 13
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 138
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
                        scale: prevM.containsMouse ? 1.18 : 1.0
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
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
                        font.pixelSize: 14
                        color: playM.containsMouse ? Theme.fg : Theme.accent
                        scale: playM.containsMouse ? 1.2 : 1.0
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                        MouseArea {
                            id: playM
                            anchors.fill: parent
                            anchors.margins: -3
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Media.togglePlaying()
                        }
                    }

                    Text {
                        text: "󰒭"
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        color: nextM.containsMouse ? Theme.accent : Theme.muted
                        scale: nextM.containsMouse ? 1.18 : 1.0
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
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

            // Focused Window Title Chip
            GlassCard {
                visible: (!Media.hasPlayer || barWin.isNotch) && !!Niri.focusedWindow
                Layout.preferredHeight: barWin.pillHeight
                Layout.preferredWidth: Math.min(220, winLabel.implicitWidth + 24)
                radiusValue: barWin.pillRadius
                strong: barWin.isEclipse
                specular: !barWin.isMinimal
                color: barWin.isMinimal
                    ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.22)
                    : (barWin.isEclipse
                        ? Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, barWin.islandAlpha)
                        : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, barWin.islandAlpha))
                border.width: barWin.isCyber ? 1.5 : (barWin.isMinimal ? 0 : 1)

                Behavior on Layout.preferredWidth { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                Text {
                    id: winLabel
                    anchors.centerIn: parent
                    width: Math.min(implicitWidth, 196)
                    text: Niri.focusedWindow ? (Niri.focusedWindow.title || Niri.focusedWindow.app_id || "") : ""
                    elide: Text.ElideRight
                    font.family: barWin.isCyber ? Theme.fontMono : Theme.fontSans
                    font.pixelSize: barWin.isCyber ? 11 : 12
                    color: Theme.muted
                }
            }
        }

        // ==================== CENTER ISLAND / DYNAMIC NOTCH ====================
        GlassCard {
            id: centerIsland
            anchors.horizontalCenter: parent.horizontalCenter
            y: barWin.isNotch ? -barContainer.anchors.topMargin : Math.round((parent.height - height) / 2)
            height: barWin.isNotch ? 38 : barWin.pillHeight
            width: Math.min(parent.width * 0.42, centerRow.implicitWidth + (barWin.isNotch || barWin.isEclipse ? 28 : 22))

            topLeftRad: barWin.isNotch ? 0 : barWin.pillRadius
            topRightRad: barWin.isNotch ? 0 : barWin.pillRadius
            bottomLeftRad: barWin.isNotch ? 18 : barWin.pillRadius
            bottomRightRad: barWin.isNotch ? 18 : barWin.pillRadius

            strong: barWin.isNotch || barWin.isEclipse
            specular: !barWin.isNotch && !barWin.isMinimal
            highlighted: centerMouse.containsMouse || SystemInfo.pomodoroRunning || (barWin.isNotch && Media.isPlaying) || barWin.isEclipse
            glassAlpha: barWin.isNotch ? 0.94 : (barWin.isEclipse ? 0.92 : (barWin.isMinimal ? 0.48 : 0.82))
            color: barWin.isNotch
                ? Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.95)
                : (barWin.isEclipse
                    ? Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, glassAlpha)
                    : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, glassAlpha))
            border.width: barWin.isCyber ? 1.5 : 1
            customBorderColor: (barWin.isNotch && Media.isPlaying) || barWin.isCyber || barWin.isEclipse
                ? Theme.accentBorder
                : "transparent"

            Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }
            Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            scale: (!barWin.isNotch && centerMouse.containsMouse) ? 1.025 : 1.0
            Behavior on scale { NumberAnimation { duration: 170; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }

            // Dynamic Notch subtle bottom accent glow line
            Rectangle {
                visible: barWin.isNotch
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.max(48, parent.width * 0.46)
                height: 2
                radius: 1
                opacity: Media.isPlaying || centerMouse.containsMouse ? 0.9 : 0.45
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: Media.isPlaying ? Theme.tertiary : Theme.accent }
                    GradientStop { position: 1.0; color: "transparent" }
                }
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            RowLayout {
                id: centerRow
                anchors.centerIn: parent
                spacing: 9

                Row {
                    spacing: 1
                    Text {
                        text: barWin.clockHour
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.fg
                    }
                    Text {
                        text: ":"
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.accent
                        opacity: barWin.colonBright ? 1.0 : 0.45
                        Behavior on opacity { NumberAnimation { duration: 700; easing.type: Easing.InOutSine } }
                    }
                    Text {
                        text: barWin.clockMin
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        font.bold: true
                        color: Theme.fg
                    }
                }

                Rectangle { width: 1; height: 13; color: Theme.glassBorder }

                Text {
                    text: barWin.dateStr
                    font.family: Theme.fontSans
                    font.pixelSize: 12
                    color: Theme.muted
                }

                Rectangle {
                    visible: SystemInfo.weatherText !== ""
                    width: 1; height: 13; color: Theme.glassBorder
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

                RowLayout {
                    visible: barWin.isNotch && Media.hasPlayer
                    spacing: 6

                    Rectangle { width: 1; height: 13; color: Theme.glassBorder }

                    EqualizerBars {
                        active: Media.isPlaying
                        barCount: 3
                        barWidth: 2.5
                        maxHeight: 12
                    }

                    Text {
                        Layout.maximumWidth: 120
                        text: Media.title
                        elide: Text.ElideRight
                        font.family: Theme.fontSans
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        color: Theme.fg
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
                }

                Rectangle {
                    visible: SystemInfo.pomodoroActive
                    width: pomoRow.implicitWidth + 12
                    height: 22
                    radius: barWin.isEclipse ? 11 : 8
                    color: Theme.accentSoft
                    border.width: 1
                    border.color: Theme.accentBorder

                    Row {
                        id: pomoRow
                        anchors.centerIn: parent
                        spacing: 4
                        Rectangle {
                            visible: SystemInfo.pomodoroRunning
                            width: 6; height: 6; radius: 3
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.accent
                            SequentialAnimation on opacity {
                                running: SystemInfo.pomodoroRunning
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.3; duration: 750; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1.0; duration: 750; easing.type: Easing.InOutSine }
                            }
                        }
                        Text {
                            text: (SystemInfo.pomodoroMode === "focus" ? "󱎫 " : "󰅶 ") + SystemInfo.pomodoroFormatted
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.bold: true
                            color: Theme.accent
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: barWin.toggleControlCenter(1)
                    }
                }

                Rectangle { width: 1; height: 13; color: Theme.glassBorder }

                Text {
                    text: "󰸉"
                    font.family: Theme.fontMono
                    font.pixelSize: 14
                    color: wallMouse.containsMouse ? Theme.accent : Theme.muted
                    scale: wallMouse.containsMouse ? 1.18 : 1.0
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                    Behavior on color { ColorAnimation { duration: 120 } }

                    MouseArea {
                        id: wallMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (m) => {
                            if (m.button === Qt.RightButton) barWin.randomWallpaper();
                            else barWin.toggleWallpaper();
                        }
                    }
                }

                Text {
                    text: "󰔎"
                    font.family: Theme.fontMono
                    font.pixelSize: 14
                    color: themeMouse.containsMouse ? Theme.tertiary : Theme.muted
                    scale: themeMouse.containsMouse ? 1.18 : 1.0
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                    Behavior on color { ColorAnimation { duration: 120 } }

                    MouseArea {
                        id: themeMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: barWin.toggleTheme()
                    }
                }

                Text {
                    text: "󰕮"
                    font.family: Theme.fontMono
                    font.pixelSize: 14
                    color: styleMouse.containsMouse ? Theme.secondary : Theme.muted
                    scale: styleMouse.containsMouse ? 1.18 : 1.0
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                    Behavior on color { ColorAnimation { duration: 120 } }

                    MouseArea {
                        id: styleMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: (m) => {
                            if (m.button === Qt.RightButton) Theme.cycleBarStyle(1);
                            else barWin.toggleBarStyle();
                        }
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

        // ==================== RIGHT WING ====================
        RowLayout {
            id: rightWing
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: barWin.isMinimal ? 8 : 6

            // Live Screencast Warning Pill
            GlassCard {
                visible: Niri.isCasting
                Layout.preferredHeight: barWin.pillHeight
                Layout.preferredWidth: barWin.pillHeight
                radiusValue: barWin.pillRadius
                highlighted: true

                Rectangle {
                    anchors.centerIn: parent
                    width: 10
                    height: 10
                    radius: 5
                    color: Theme.error
                    SequentialAnimation on opacity {
                        running: Niri.isCasting
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.35; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                    }
                }
            }

            // Pacman Updates Chip
            GlassCard {
                visible: SystemInfo.updatesCount > 0
                Layout.preferredHeight: barWin.pillHeight
                Layout.preferredWidth: updRow.implicitWidth + 16
                radiusValue: barWin.pillRadius
                strong: barWin.isEclipse
                specular: !barWin.isMinimal
                color: barWin.isEclipse
                    ? Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, barWin.islandAlpha)
                    : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, barWin.islandAlpha)
                border.width: barWin.isCyber ? 1.5 : (barWin.isMinimal ? 0 : 1)

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

            // Keyboard Layout Pill
            GlassCard {
                Layout.preferredHeight: barWin.pillHeight
                Layout.preferredWidth: barWin.isEclipse ? barWin.pillHeight : 38
                radiusValue: barWin.pillRadius
                strong: barWin.isEclipse
                specular: !barWin.isMinimal
                highlighted: kbMouse.containsMouse || barWin.isEclipse
                color: barWin.isMinimal && !kbMouse.containsMouse
                    ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.28)
                    : (barWin.isEclipse
                        ? Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, barWin.islandAlpha)
                        : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, barWin.islandAlpha))
                border.width: barWin.isCyber ? 1.5 : (barWin.isMinimal && !kbMouse.containsMouse ? 0 : 1)

                scale: kbMouse.pressed ? 0.92 : (kbMouse.containsMouse ? 1.05 : 1.0)
                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }

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
                Layout.preferredHeight: barWin.pillHeight
                Layout.preferredWidth: trayRow.implicitWidth + (barWin.isEclipse ? 18 : 14)
                radiusValue: barWin.pillRadius
                strong: barWin.isEclipse
                specular: !barWin.isMinimal
                color: barWin.isMinimal
                    ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.25)
                    : (barWin.isEclipse
                        ? Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, barWin.islandAlpha)
                        : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, barWin.islandAlpha))
                border.width: barWin.isCyber ? 1.5 : (barWin.isMinimal ? 0 : 1)

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

                            scale: trayItemMouse.containsMouse ? 1.15 : 1.0
                            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }

                            IconImage {
                                anchors.fill: parent
                                source: modelData.icon || ""
                            }

                            MouseArea {
                                id: trayItemMouse
                                anchors.fill: parent
                                hoverEnabled: true
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
                Layout.preferredHeight: barWin.pillHeight
                Layout.preferredWidth: hwRow.implicitWidth + (barWin.isEclipse ? 24 : 20)
                radiusValue: barWin.pillRadius
                strong: barWin.isEclipse
                specular: !barWin.isMinimal
                highlighted: hwMouse.containsMouse || barWin.isEclipse
                color: barWin.isMinimal && !hwMouse.containsMouse
                    ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.30)
                    : (barWin.isEclipse
                        ? Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, barWin.islandAlpha)
                        : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, barWin.islandAlpha))
                border.width: barWin.isCyber ? 1.5 : (barWin.isMinimal && !hwMouse.containsMouse ? 0 : 1)

                scale: hwMouse.containsMouse ? 1.02 : 1.0
                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }

                RowLayout {
                    id: hwRow
                    anchors.centerIn: parent
                    spacing: barWin.isMinimal ? 10 : 9

                    Text {
                        visible: SystemInfo.nightLight
                        text: "󰖔"
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        color: Theme.tertiary
                    }

                    Text {
                        visible: SystemInfo.caffeine
                        text: "󰅶"
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        color: Theme.secondary
                    }

                    Text {
                        text: SystemInfo.wifiEnabled
                            ? (SystemInfo.wifiSsid !== "" ? "󰤨" : "󰤯")
                            : "󰤮"
                        font.family: Theme.fontMono
                        font.pixelSize: 14
                        color: SystemInfo.wifiSsid !== "" ? Theme.secondary : Theme.muted
                    }

                    Text {
                        text: SystemInfo.btEnabled ? "󰂯" : "󰂲"
                        font.family: Theme.fontMono
                        font.pixelSize: 13
                        color: SystemInfo.btEnabled ? Theme.accent : Theme.muted
                    }

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
                                visible: !barWin.isMinimal || volArea.containsMouse
                                text: (barWin.isCyber ? "VOL " : "") + (Audio.muted ? "Mute" : Math.round(Audio.volume * 100) + "%")
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                color: Theme.fg
                            }
                        }
                        MouseArea {
                            id: volArea
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.MiddleButton | Qt.RightButton
                            onClicked: Audio.toggleMute()
                            onWheel: (w) => {
                                Audio.setVolume(Audio.volume + (w.angleDelta.y > 0 ? 0.05 : -0.05));
                            }
                        }
                    }

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
                                visible: !barWin.isMinimal || briArea.containsMouse
                                text: (barWin.isCyber ? "BRI " : "") + Math.round(SystemInfo.brightness * 100) + "%"
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                                color: Theme.fg
                            }
                        }
                        MouseArea {
                            id: briArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onWheel: (w) => {
                                SystemInfo.adjustBrightness(w.angleDelta.y > 0 ? 0.05 : -0.05);
                            }
                        }
                    }

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

                            SequentialAnimation on opacity {
                                running: SystemInfo.isCharging
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.45; duration: 900; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                            }
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
                Layout.preferredHeight: barWin.pillHeight
                Layout.preferredWidth: (Notifications.unreadCount > 0 && !Notifications.dnd)
                    ? (bellRow.implicitWidth + 18)
                    : (barWin.isEclipse ? barWin.pillHeight : (bellRow.implicitWidth + 16))
                radiusValue: barWin.pillRadius
                strong: barWin.isEclipse
                specular: !barWin.isMinimal
                highlighted: bellMouse.containsMouse || (Notifications.unreadCount > 0 && !Notifications.dnd) || barWin.isEclipse
                color: {
                    if (Notifications.unreadCount > 0 && !Notifications.dnd) return Theme.accentSoft;
                    if (barWin.isMinimal && !bellMouse.containsMouse) return Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.28);
                    if (barWin.isEclipse) return Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, barWin.islandAlpha);
                    return Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, barWin.islandAlpha);
                }
                border.width: barWin.isCyber ? 1.5 : (barWin.isMinimal && !bellMouse.containsMouse && Notifications.unreadCount === 0 ? 0 : 1)

                scale: bellMouse.pressed ? 0.92 : (bellMouse.containsMouse ? 1.06 : 1.0)
                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }

                Row {
                    id: bellRow
                    anchors.centerIn: parent
                    spacing: 5
                    Text {
                        text: Notifications.dnd ? "󰂛" : (Notifications.unreadCount > 0 ? "󱅫" : "󰂚")
                        font.family: Theme.fontMono
                        font.pixelSize: 14
                        color: Notifications.dnd ? Theme.muted : (Notifications.unreadCount > 0 ? Theme.accent : Theme.fg)

                        SequentialAnimation on scale {
                            running: Notifications.unreadCount > 0 && !Notifications.dnd
                            loops: Animation.Infinite
                            NumberAnimation { to: 1.15; duration: 750; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 750; easing.type: Easing.InOutSine }
                        }
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
                Layout.preferredHeight: barWin.pillHeight
                Layout.preferredWidth: barWin.pillHeight
                radiusValue: barWin.pillRadius
                strong: barWin.isEclipse
                specular: !barWin.isMinimal
                highlighted: pwrMouse.containsMouse || barWin.isEclipse
                color: barWin.isMinimal && !pwrMouse.containsMouse
                    ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.28)
                    : (barWin.isEclipse
                        ? Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, barWin.islandAlpha)
                        : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, barWin.islandAlpha))
                border.width: barWin.isCyber ? 1.5 : (barWin.isMinimal && !pwrMouse.containsMouse ? 0 : 1)
                customBorderColor: pwrMouse.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.6) : (barWin.isEclipse ? Theme.accentBorder : "transparent")

                scale: pwrMouse.pressed ? 0.90 : (pwrMouse.containsMouse ? 1.08 : 1.0)
                Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }

                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: Theme.fontMono
                    font.pixelSize: 13
                    color: pwrMouse.containsMouse ? Theme.error : Theme.muted
                    Behavior on color { ColorAnimation { duration: 130 } }
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
