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

    property string barStyle: "aurora"

    readonly property var barStyles: [
        { id: "aurora",  name: "Aurora Glass",   desc: "Floating liquid-glass islands & glowing pills" },
        { id: "notch",   name: "Dynamic Notch",  desc: "Unified top-center Dynamic Island & side wings" },
        { id: "cyber",   name: "Neon Prism",     desc: "Sharp tech badges with dual-tone neon borders" },
        { id: "eclipse", name: "Eclipse Pills",  desc: "Full-pill obsidian capsules with luminous rim" },
        { id: "minimal", name: "Zen Minimal",    desc: "Airy floating chips & morphing workspace dots" }
    ]

    signal barStyleChangedOsd(string label)

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

    function isValidBarStyle(id) {
        for (let i = 0; i < barStyles.length; i++) {
            if (barStyles[i].id === id) return true;
        }
        return false;
    }

    function barStyleInfo(id) {
        for (let i = 0; i < barStyles.length; i++) {
            if (barStyles[i].id === id) return barStyles[i];
        }
        return barStyles[0];
    }

    function setBarStyle(id, showOsd) {
        const clean = (id || "").trim();
        if (!isValidBarStyle(clean)) return;
        if (barStyle !== clean) {
            barStyle = clean;
        }
        barStyleFile.setText(clean + "\n");
        if (showOsd) {
            barStyleChangedOsd(barStyleInfo(clean).name);
        }
    }

    function cycleBarStyle(step) {
        const delta = step === undefined ? 1 : step;
        let idx = 0;
        for (let i = 0; i < barStyles.length; i++) {
            if (barStyles[i].id === barStyle) {
                idx = i;
                break;
            }
        }
        const nextIdx = (idx + delta + barStyles.length) % barStyles.length;
        setBarStyle(barStyles[nextIdx].id, true);
    }

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

    FileView {
        id: barStyleFile
        path: Quickshell.env("HOME") + "/.cache/theme/bar_style"
        watchChanges: true
        onLoaded: {
            const val = (text() || "").trim();
            if (root.isValidBarStyle(val) && val !== root.barStyle) {
                root.barStyle = val;
            }
        }
        onFileChanged: reload()
    }
}
