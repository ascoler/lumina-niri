pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode defaultSink: Pipewire.defaultAudioSink
    readonly property PwNode defaultSource: Pipewire.defaultAudioSource

    readonly property real volume: (defaultSink && defaultSink.audio && !isNaN(defaultSink.audio.volume)) ? defaultSink.audio.volume : 0
    readonly property bool muted: !!(defaultSink && defaultSink.audio && defaultSink.audio.muted)
    readonly property real micVolume: (defaultSource && defaultSource.audio && !isNaN(defaultSource.audio.volume)) ? defaultSource.audio.volume : 0
    readonly property bool micMuted: !!(defaultSource && defaultSource.audio && defaultSource.audio.muted)

    readonly property var sinks: {
        const list = Pipewire.nodes ? Pipewire.nodes.values : [];
        return list.filter(n => n && !n.isStream && n.isSink && n.audio);
    }

    property bool _ready: false
    signal osdTriggered(string kind, real value, bool isMuted)

    PwObjectTracker {
        objects: Pipewire.nodes ? Pipewire.nodes.values : []
    }

    Timer {
        interval: 1200
        running: true
        onTriggered: root._ready = true
    }

    Connections {
        target: root.defaultSink ? root.defaultSink.audio : null
        ignoreUnknownSignals: true
        function onVolumeChanged() {
            if (root._ready) root.osdTriggered("volume", root.volume, root.muted);
        }
        function onMutedChanged() {
            if (root._ready) root.osdTriggered("volume", root.volume, root.muted);
        }
    }

    Connections {
        target: root.defaultSource ? root.defaultSource.audio : null
        ignoreUnknownSignals: true
        function onMutedChanged() {
            if (root._ready) root.osdTriggered("mic", root.micVolume, root.micMuted);
        }
    }

    function setVolume(v) {
        if (!defaultSink || !defaultSink.audio) return;
        defaultSink.audio.volume = Math.max(0, Math.min(1.0, v));
    }

    function toggleMute() {
        if (!defaultSink || !defaultSink.audio) return;
        defaultSink.audio.muted = !defaultSink.audio.muted;
    }

    function toggleMicMute() {
        if (!defaultSource || !defaultSource.audio) return;
        defaultSource.audio.muted = !defaultSource.audio.muted;
    }

    function setDefaultSink(node) {
        if (node) Pipewire.preferredDefaultAudioSink = node;
    }
}
