pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var players: Mpris.players ? Mpris.players.values : []

    readonly property MprisPlayer activePlayer: {
        const list = players || [];
        let playing = list.find(p => p && p.playbackState === MprisPlaybackState.Playing && (p.trackTitle || "") !== "");
        if (playing) return playing;
        let active = list.find(p => p && p.playbackState !== MprisPlaybackState.Stopped && (p.trackTitle || "") !== "");
        return active || (list.length > 0 ? list[0] : null);
    }

    readonly property bool hasPlayer: !!(activePlayer && (activePlayer.trackTitle || "") !== "")
    readonly property bool isPlaying: !!(activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing)
    readonly property string title: activePlayer ? (activePlayer.trackTitle || "") : ""
    readonly property string artist: activePlayer ? (activePlayer.trackArtist || activePlayer.identity || "") : ""
    readonly property string artUrl: activePlayer ? (activePlayer.trackArtUrl || "") : ""
    readonly property real length: activePlayer && activePlayer.lengthSupported ? (activePlayer.length || 0) : 0
    property real position: 0

    // Reference counter so the 1s progress timer ONLY ticks while a music widget is actually visible
    property int positionWatchers: 0

    onActivePlayerChanged: syncPosition()

    Connections {
        target: root.activePlayer
        ignoreUnknownSignals: true
        function onPositionChanged() { root.syncPosition(); }
        function onTrackTitleChanged() { root.syncPosition(); }
    }

    function syncPosition() {
        if (activePlayer && activePlayer.positionSupported) {
            position = activePlayer.position || 0;
        } else {
            position = 0;
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.positionWatchers > 0 && root.isPlaying && root.length > 0
        onTriggered: {
            if (root.activePlayer && root.activePlayer.positionSupported) {
                root.position = Math.min(root.length, root.position + 1);
            }
        }
    }

    function togglePlaying() {
        if (activePlayer && activePlayer.canTogglePlaying) activePlayer.togglePlaying();
    }

    function next() {
        if (activePlayer && activePlayer.canGoNext) activePlayer.next();
    }

    function previous() {
        if (activePlayer && activePlayer.canGoPrevious) activePlayer.previous();
    }

    function seekTo(sec) {
        if (!activePlayer || !activePlayer.canSeek) return;
        const delta = sec - position;
        activePlayer.seek(delta);
        position = sec;
    }

    function formatTime(sec) {
        if (!sec || sec < 0 || isNaN(sec)) return "0:00";
        const total = Math.floor(sec);
        const m = Math.floor(total / 60);
        const s = total % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }
}
