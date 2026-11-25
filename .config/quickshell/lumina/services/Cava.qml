pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int subscribers: 0
    property var bars: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    readonly property bool active: subscribers > 0 && Media.isPlaying

    Process {
        id: cavaProc
        running: root.active
        command: ["sh", "-c", "printf '[general]\\nbars = 18\\nframerate = 60\\n[output]\\nmethod = raw\\nraw_target = /dev/stdout\\ndata_format = ascii\\nascii_max_range = 100\\n' | cava -p /dev/stdin"]
        stdout: SplitParser {
            onRead: line => {
                const raw = line.trim();
                if (!raw) return;
                const parts = raw.split(";");
                const next = [];
                for (let i = 0; i < 18; i++) {
                    const v = parseInt(parts[i]);
                    next.push(isNaN(v) ? 0 : Math.min(1.0, v / 100.0));
                }
                root.bars = next;
            }
        }
        onRunningChanged: {
            if (!running) {
                root.bars = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
            }
        }
    }
}
