import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "services"
import "shell"

ShellRoot {
    id: root

    property string activeOverlay: "" // "" | "control" | "wallpaper" | "launcher" | "clipboard" | "power" | "theme"
    property int controlTab: 0

    function openOverlay(name) {
        activeOverlay = (activeOverlay === name) ? "" : name;
    }

    function closeOverlays() {
        activeOverlay = "";
    }

    Connections {
        target: Quickshell
        function onReloadCompleted() { Quickshell.inhibitReloadPopup(); }
    }

    IpcHandler {
        target: "shell"
        function toggleLauncher(): void { root.openOverlay("launcher"); }
        function toggleWallpaper(): void { root.openOverlay("wallpaper"); }
        function toggleControlCenter(): void { root.controlTab = 0; root.openOverlay("control"); }
        function toggleClipboard(): void { root.openOverlay("clipboard"); }
        function togglePower(): void { root.openOverlay("power"); }
        function toggleTheme(): void { root.openOverlay("theme"); }
        function closeAll(): void { root.closeOverlays(); }
        function brightnessUp(): void { SystemInfo.adjustBrightness(0.05); }
        function brightnessDown(): void { SystemInfo.adjustBrightness(-0.05); }
        function volumeUp(): void { Audio.setVolume(Audio.volume + 0.05); }
        function volumeDown(): void { Audio.setVolume(Audio.volume - 0.05); }
        function volumeMute(): void { Audio.toggleMute(); }
        function micMute(): void { Audio.toggleMicMute(); }
    }

    Process { id: shellProc }

    // Top Bar on all active outputs
    Variants {
        model: Quickshell.screens
        delegate: Bar {
            required property var modelData
            screen: modelData
            onToggleLauncher: root.openOverlay("launcher")
            onToggleWallpaper: root.openOverlay("wallpaper")
            onToggleTheme: root.openOverlay("theme")
            onTogglePower: root.openOverlay("power")
            onToggleControlCenter: (tab) => {
                root.controlTab = tab;
                root.openOverlay("control");
            }
            onRandomWallpaper: shellProc.exec([Quickshell.env("HOME") + "/.local/bin/rice-wallpaper"])
        }
    }

    // Backdrop Desktop Widgets (Niri place-within-backdrop)
    Variants {
        model: Quickshell.screens
        delegate: BackdropWidgets {
            required property var modelData
            screen: modelData
        }
    }

    // Always-available lightweight surfaces
    Osd {}
    NotificationPopups {}
    PolkitDialog {}

    // Native Caffeine / Idle Inhibitor (zero extra process!)
    IdleInhibitor {
        enabled: SystemInfo.caffeine
    }

    // Lazy-loaded modal overlays (0 MB RAM until opened!)
    LazyLoader {
        active: root.activeOverlay === "control"
        ControlCenter {
            isOpen: root.activeOverlay === "control"
            activeTab: root.controlTab
            onCloseRequested: root.closeOverlays()
            onOpenThemeSwitcher: root.activeOverlay = "theme"
            onOpenPowerMenu: root.activeOverlay = "power"
        }
    }

    LazyLoader {
        active: root.activeOverlay === "wallpaper"
        WallpaperCarousel {
            isOpen: root.activeOverlay === "wallpaper"
            onCloseRequested: root.closeOverlays()
        }
    }

    LazyLoader {
        active: root.activeOverlay === "launcher"
        Launcher {
            isOpen: root.activeOverlay === "launcher"
            onCloseRequested: root.closeOverlays()
        }
    }

    LazyLoader {
        active: root.activeOverlay === "clipboard"
        Clipboard {
            isOpen: root.activeOverlay === "clipboard"
            onCloseRequested: root.closeOverlays()
        }
    }

    LazyLoader {
        active: root.activeOverlay === "power"
        PowerMenu {
            isOpen: root.activeOverlay === "power"
            onCloseRequested: root.closeOverlays()
        }
    }

    LazyLoader {
        active: root.activeOverlay === "theme"
        ThemeSwitcher {
            isOpen: root.activeOverlay === "theme"
            onCloseRequested: root.closeOverlays()
        }
    }
}
