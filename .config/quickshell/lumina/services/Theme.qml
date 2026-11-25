pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string presetName: "Matugen Dynamic"
    property color bg: "#121318"
    property color surface: "#1e1f26"
    property color surfaceHigh: "#282a34"
    property color fg: "#e3e1e9"
    property color muted: "#8e909e"
    property color accent: "#b9c3ff"
    property color accentFg: "#1d2759"
    property color secondary: "#72d8a5"
    property color tertiary: "#e5bad8"
    property color error: "#ffb4ab"
    property color border: "#30323c"
    property string wallpaper: ""

    readonly property color glassBg: Qt.rgba(bg.r, bg.g, bg.b, 0.80)
    readonly property color glassStrong: Qt.rgba(bg.r, bg.g, bg.b, 0.90)
    readonly property color glassSurface: Qt.rgba(surface.r, surface.g, surface.b, 0.72)
    readonly property color glassHigh: Qt.rgba(surfaceHigh.r, surfaceHigh.g, surfaceHigh.b, 0.85)
    readonly property color glassBorder: Qt.rgba(1, 1, 1, 0.11)
    readonly property color accentSoft: Qt.rgba(accent.r, accent.g, accent.b, 0.16)
    readonly property color accentBorder: Qt.rgba(accent.r, accent.g, accent.b, 0.45)

    readonly property string fontSans: "Inter"
    readonly property string fontMono: "JetBrainsMono Nerd Font"

    readonly property int animFast: 140
    readonly property int animNormal: 220
    readonly property int animSmooth: 320

    function applyJson(raw) {
        if (!raw || raw.trim() === "") return;
        try {
            const p = JSON.parse(raw);
            if (p.name) presetName = p.name;
            if (p.bg) bg = p.bg;
            if (p.surface) surface = p.surface;
            if (p.surfaceHigh) surfaceHigh = p.surfaceHigh;
            if (p.fg) fg = p.fg;
            if (p.muted) muted = p.muted;
            if (p.accent) accent = p.accent;
            if (p.accentFg) accentFg = p.accentFg;
            if (p.secondary) secondary = p.secondary;
            if (p.tertiary) tertiary = p.tertiary;
            if (p.error) error = p.error;
            if (p.border) border = p.border;
            if (p.wallpaper !== undefined) wallpaper = p.wallpaper;
        } catch (e) {
            console.warn("Theme: failed to parse palette.json:", e);
        }
    }

    FileView {
        id: paletteFile
        path: Quickshell.env("HOME") + "/.cache/theme/palette.json"
        watchChanges: true
        onLoaded: root.applyJson(text())
        onFileChanged: reload()
    }
}
