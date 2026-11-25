import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../services"
import "../components"

PanelWindow {
    id: wallWin

    property bool isOpen: false
    property string folderFilter: "curated" // "curated" | "all"
    property string colorFilter: "all"
    property string searchQuery: ""
    property var allWallpapers: []
    property var filteredWallpapers: []
    property int currentIndex: 0

    signal closeRequested()

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: Qt.rgba(0, 0, 0, 0.48)
    visible: isOpen
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "lumina-wallpaper"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore

    readonly property var colorBuckets: [
        { id: "all", hex: "#ffffff", label: "All" },
        { id: "red", hex: "#f38ba8", label: "Red" },
        { id: "orange", hex: "#fab387", label: "Orange" },
        { id: "yellow", hex: "#f9e2af", label: "Yellow" },
        { id: "green", hex: "#a6e3a1", label: "Green" },
        { id: "cyan", hex: "#89dceb", label: "Cyan" },
        { id: "blue", hex: "#89b4fa", label: "Blue" },
        { id: "purple", hex: "#cba6f7", label: "Purple" },
        { id: "mono", hex: "#9399b2", label: "Mono" }
    ]

    function loadIndex(raw) {
        if (!raw || raw.trim() === "") return;
        try {
            allWallpapers = JSON.parse(raw);
            applyFilters();
        } catch (e) {
            console.warn("WallpaperCarousel: JSON parse failed:", e);
        }
    }

    function applyFilters() {
        const q = searchQuery.trim().toLowerCase();
        const next = allWallpapers.filter(item => {
            if (folderFilter === "curated" && !item.curated) return false;
            if (colorFilter !== "all" && item.bucket !== colorFilter) return false;
            if (q !== "" && item.name.toLowerCase().indexOf(q) === -1) return false;
            return true;
        });
        filteredWallpapers = next;

        // Focus current active wallpaper if present
        let idx = 0;
        if (Theme.wallpaper) {
            for (let i = 0; i < next.length; i++) {
                if (next[i].path === Theme.wallpaper) {
                    idx = i;
                    break;
                }
            }
        }
        carousel.currentIndex = next.length > 0 ? idx : -1;
        if (next.length > 0) carousel.positionViewAtIndex(idx, ListView.Center);
    }

    function applyWallpaper(item) {
        if (!item) return;
        applyProc.exec([Quickshell.env("HOME") + "/.local/bin/rice-wallpaper", item.path]);
    }

    function pickRandom() {
        if (filteredWallpapers.length === 0) return;
        const r = Math.floor(Math.random() * filteredWallpapers.length);
        carousel.currentIndex = r;
        applyWallpaper(filteredWallpapers[r]);
    }

    onIsOpenChanged: {
        if (isOpen) {
            indexFile.reload();
            carousel.forceActiveFocus();
        }
    }

    FileView {
        id: indexFile
        path: Quickshell.env("HOME") + "/.cache/lumina/wallpapers.json"
        watchChanges: true
        onLoaded: wallWin.loadIndex(text())
        onFileChanged: reload()
    }

    Process { id: applyProc }
    Process {
        id: reindexProc
        command: [Quickshell.env("HOME") + "/.local/bin/rice-wallpaper-index"]
        onExited: indexFile.reload()
    }

    // Scrim click closes
    MouseArea {
        anchors.fill: parent
        onClicked: wallWin.closeRequested()
    }

    Shortcut {
        sequence: "Escape"
        enabled: wallWin.isOpen
        onActivated: wallWin.closeRequested()
    }

    // TOP FLOATING FILTER BAR (Serpantinum-inspired)
    GlassCard {
        id: topBar
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 86
        width: Math.min(parent.width - 60, topRow.implicitWidth + 28)
        height: 48
        radiusValue: 16
        strong: true
        highlighted: true

        MouseArea { anchors.fill: parent; z: -1 }

        RowLayout {
            id: topRow
            anchors.centerIn: parent
            spacing: 10

            // Folder pills
            Rectangle {
                width: 92; height: 30; radius: 10
                color: wallWin.folderFilter === "curated" ? Theme.accent : Qt.rgba(1, 1, 1, 0.06)
                Text {
                    anchors.centerIn: parent
                    text: "★ Curated"
                    font.family: Theme.fontSans
                    font.pixelSize: 12
                    font.bold: wallWin.folderFilter === "curated"
                    color: wallWin.folderFilter === "curated" ? Theme.accentFg : Theme.fg
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { wallWin.folderFilter = "curated"; wallWin.applyFilters(); }
                }
            }

            Rectangle {
                width: 68; height: 30; radius: 10
                color: wallWin.folderFilter === "all" ? Theme.accent : Qt.rgba(1, 1, 1, 0.06)
                Text {
                    anchors.centerIn: parent
                    text: "All"
                    font.family: Theme.fontSans
                    font.pixelSize: 12
                    font.bold: wallWin.folderFilter === "all"
                    color: wallWin.folderFilter === "all" ? Theme.accentFg : Theme.fg
                }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: { wallWin.folderFilter = "all"; wallWin.applyFilters(); }
                }
            }

            Rectangle { width: 1; height: 22; color: Theme.glassBorder }

            // Color Bucket Filter Dots
            Row {
                spacing: 6
                Repeater {
                    model: wallWin.colorBuckets
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool sel: wallWin.colorFilter === modelData.id
                        width: 22; height: 22; radius: 11
                        color: modelData.id === "all" ? Theme.glassSurface : modelData.hex
                        border.width: sel ? 2.5 : 1
                        border.color: sel ? Theme.fg : Qt.rgba(1, 1, 1, 0.2)
                        scale: sel ? 1.18 : 1.0
                        Behavior on scale { NumberAnimation { duration: 120 } }

                        Text {
                            visible: modelData.id === "all"
                            anchors.centerIn: parent
                            text: "✦"
                            font.pixelSize: 10
                            color: Theme.fg
                        }

                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { wallWin.colorFilter = modelData.id; wallWin.applyFilters(); }
                        }
                    }
                }
            }

            Rectangle { width: 1; height: 22; color: Theme.glassBorder }

            // Search box
            Rectangle {
                width: 170; height: 30; radius: 10
                color: Qt.rgba(1, 1, 1, 0.06)
                border.width: 1; border.color: searchField.activeFocus ? Theme.accentBorder : Theme.glassBorder

                TextInput {
                    id: searchField
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.fg
                    font.family: Theme.fontSans
                    font.pixelSize: 12
                    onTextChanged: {
                        wallWin.searchQuery = text;
                        wallWin.applyFilters();
                    }
                    Keys.onEscapePressed: wallWin.closeRequested()
                    Keys.onReturnPressed: {
                        if (carousel.currentIndex >= 0 && carousel.currentIndex < wallWin.filteredWallpapers.length) {
                            wallWin.applyWallpaper(wallWin.filteredWallpapers[carousel.currentIndex]);
                        }
                    }
                }
                Text {
                    visible: searchField.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    text: "  Search..."
                    font.family: Theme.fontSans
                    font.pixelSize: 12
                    color: Theme.muted
                }
            }

            // Random
            Rectangle {
                width: 32; height: 30; radius: 10
                color: Theme.accentSoft
                border.width: 1; border.color: Theme.accentBorder
                Text { anchors.centerIn: parent; text: ""; font.family: Theme.fontMono; font.pixelSize: 13; color: Theme.accent }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: wallWin.pickRandom() }
            }

            // Re-index
            Rectangle {
                width: 32; height: 30; radius: 10
                color: Qt.rgba(1, 1, 1, 0.06)
                Text { anchors.centerIn: parent; text: "󰑐"; font.family: Theme.fontMono; font.pixelSize: 14; color: Theme.muted }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: reindexProc.running = true }
            }
        }
    }

    // SIGNATURE SLANTED PARALLELOGRAM CAROUSEL
    ListView {
        id: carousel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 410
        orientation: ListView.Horizontal
        spacing: 14
        clip: false
        cacheBuffer: 1200
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: width / 2 - 220
        preferredHighlightEnd: width / 2 + 220
        highlightMoveDuration: 240
        snapMode: ListView.SnapToItem
        model: wallWin.filteredWallpapers

        Keys.onLeftPressed: decrementCurrentIndex()
        Keys.onRightPressed: incrementCurrentIndex()
        Keys.onPressed: (e) => {
            if (e.key === Qt.Key_H) decrementCurrentIndex();
            else if (e.key === Qt.Key_L) incrementCurrentIndex();
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                if (currentIndex >= 0 && currentIndex < wallWin.filteredWallpapers.length) {
                    wallWin.applyWallpaper(wallWin.filteredWallpapers[currentIndex]);
                }
            } else if (e.key === Qt.Key_Slash) {
                searchField.forceActiveFocus();
            }
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            acceptedButtons: Qt.NoButton
            onWheel: (w) => {
                if (w.angleDelta.y > 0 || w.angleDelta.x > 0) carousel.decrementCurrentIndex();
                else carousel.incrementCurrentIndex();
            }
        }

        delegate: Item {
            id: cardSlot
            required property var modelData
            required property int index

            readonly property bool isCurrent: ListView.isCurrentItem
            readonly property bool isApplied: modelData.path === Theme.wallpaper

            width: isCurrent ? 440 : 210
            height: 360
            y: 25
            z: isCurrent ? 20 : 1

            Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            // Parallelogram affine shear
            Item {
                anchors.centerIn: parent
                width: cardSlot.width
                height: isCurrent ? 330 : 270

                Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                transform: Matrix4x4 {
                    matrix: Qt.matrix4x4(
                        1, -0.15, 0, (cardSlot.isCurrent ? 330 : 270) * 0.075,
                        0,  1,    0, 0,
                        0,  0,    1, 0,
                        0,  0,    0, 1
                    )
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 16
                    color: Theme.bg
                    border.width: isCurrent ? 2.5 : (isApplied ? 2 : 1)
                    border.color: isCurrent ? Theme.accent : (isApplied ? Theme.secondary : Theme.glassBorder)
                    opacity: isCurrent ? 1.0 : 0.72

                    Behavior on opacity { NumberAnimation { duration: 180 } }

                    ClippingWrapperRectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: 14

                        Image {
                            anchors.fill: parent
                            source: "file://" + modelData.thumb
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 320
                            sourceSize.height: 180
                        }
                    }

                    // Active badge
                    Rectangle {
                        visible: isApplied
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 12
                        width: 66; height: 22; radius: 8
                        color: Theme.accent
                        Text {
                            anchors.centerIn: parent
                            text: "✓ Active"
                            font.family: Theme.fontSans
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.accentFg
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (isCurrent) {
                        wallWin.applyWallpaper(modelData);
                    } else {
                        carousel.currentIndex = index;
                    }
                }
            }
        }
    }

    // BOTTOM INFO PILL
    GlassCard {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 64
        width: Math.min(parent.width - 80, infoRow.implicitWidth + 32)
        height: 40
        radiusValue: 14
        strong: true

        readonly property var activeItem: (carousel.currentIndex >= 0 && carousel.currentIndex < wallWin.filteredWallpapers.length)
            ? wallWin.filteredWallpapers[carousel.currentIndex]
            : null

        RowLayout {
            id: infoRow
            anchors.centerIn: parent
            spacing: 12

            Rectangle {
                visible: !!parent.parent.activeItem
                width: 14; height: 14; radius: 7
                color: parent.parent.activeItem ? parent.parent.activeItem.hex : Theme.accent
                border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.35)
            }

            Text {
                text: parent.parent.activeItem
                    ? parent.parent.activeItem.name + "  ·  " + wallWin.filteredWallpapers.length + " wallpapers"
                    : "No wallpapers match filter"
                font.family: Theme.fontSans
                font.pixelSize: 12
                font.bold: true
                color: Theme.fg
            }

            Rectangle { width: 1; height: 14; color: Theme.glassBorder }

            Text {
                text: "←/→ Navigate  •  Enter Apply  •  / Search  •  Esc Close"
                font.family: Theme.fontMono
                font.pixelSize: 10
                color: Theme.muted
            }
        }
    }
}
