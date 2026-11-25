pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.UPower

Singleton {
    id: root

    // Battery (Native UPower)
    readonly property bool hasBattery: !!(UPower.displayDevice && UPower.displayDevice.ready && UPower.displayDevice.isLaptopBattery)
    readonly property int batteryPercent: hasBattery ? Math.round((UPower.displayDevice.percentage || 0) * 100) : 100
    readonly property bool isCharging: hasBattery && (UPower.displayDevice.state === UPowerDeviceState.Charging || UPower.displayDevice.state === UPowerDeviceState.FullyCharged)

    // Network & Bluetooth (Native Quickshell)
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property var wifiDevices: {
        const devs = Networking.devices ? Networking.devices.values : [];
        return devs.filter(d => d && d.type === DeviceType.Wifi);
    }
    readonly property var activeWifiNetwork: {
        for (let i = 0; i < wifiDevices.length; i++) {
            const nets = wifiDevices[i].networks ? wifiDevices[i].networks.values : [];
            const conn = nets.find(n => n && n.connected);
            if (conn) return conn;
        }
        return null;
    }
    readonly property string wifiSsid: activeWifiNetwork ? (activeWifiNetwork.name || "Connected") : ""
    readonly property bool btEnabled: !!(Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled)
    readonly property var btDevices: (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.devices) ? Bluetooth.defaultAdapter.devices.values : []

    // Brightness
    property real brightness: 1.0
    property bool hasBacklight: true
    signal brightnessOsd(real value)

    // Night Light (wlsunset) & Caffeine & Backdrop widgets
    property bool nightLight: false
    property bool caffeine: false
    property bool backdropWidgets: true

    // Weather & Arch Updates (cached, low frequency)
    property string weatherText: ""
    property string weatherIcon: "󰖐"
    property string weatherDesc: "Loading..."
    property int updatesCount: 0

    // Live Vitals (ONLY polled while vitalsWatchers > 0!)
    property int vitalsWatchers: 0
    property int cpuPercent: 0
    property int memPercent: 0
    property int cpuTemp: 0
    property var _prevCpu: null

    // Pomodoro / Focus Timer
    property bool pomodoroActive: false
    property bool pomodoroRunning: false
    property string pomodoroMode: "focus" // "focus" | "break"
    property int pomodoroRemaining: 25 * 60
    readonly property string pomodoroFormatted: {
        const m = Math.floor(pomodoroRemaining / 60);
        const s = pomodoroRemaining % 60;
        return String(m).padStart(2, "0") + ":" + String(s).padStart(2, "0");
    }

    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    function toggleBluetooth() {
        if (Bluetooth.defaultAdapter) {
            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
        }
    }

    function toggleNightLight() {
        nightLight = !nightLight;
        if (nightLight) {
            nightProc.running = true;
        } else {
            nightProc.running = false;
            execProc.exec(["pkill", "-x", "wlsunset"]);
        }
    }

    function toggleCaffeine() {
        caffeine = !caffeine;
    }

    function toggleBackdropWidgets() {
        backdropWidgets = !backdropWidgets;
    }

    function setBrightness(val) {
        const clamped = Math.max(0.05, Math.min(1.0, val));
        brightness = clamped;
        const pct = Math.round(clamped * 100);
        brightnessSetProc.exec(["brightnessctl", "-q", "set", pct + "%"]);
        brightnessOsd(clamped);
    }

    function adjustBrightness(delta) {
        setBrightness(brightness + delta);
    }

    function startPomodoro(mode) {
        if (mode) pomodoroMode = mode;
        pomodoroRemaining = (pomodoroMode === "focus" ? 25 : 5) * 60;
        pomodoroActive = true;
        pomodoroRunning = true;
    }

    function togglePomodoro() {
        if (!pomodoroActive) {
            startPomodoro("focus");
        } else {
            pomodoroRunning = !pomodoroRunning;
        }
    }

    function resetPomodoro() {
        pomodoroRunning = false;
        pomodoroActive = false;
        pomodoroRemaining = (pomodoroMode === "focus" ? 25 : 5) * 60;
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.pomodoroRunning
        onTriggered: {
            if (root.pomodoroRemaining > 1) {
                root.pomodoroRemaining--;
            } else {
                root.pomodoroRunning = false;
                const nextMode = root.pomodoroMode === "focus" ? "break" : "focus";
                execProc.exec(["notify-send", "-a", "Lumina Focus",
                    root.pomodoroMode === "focus" ? "Focus session complete!" : "Break is over!",
                    nextMode === "break" ? "Time for a 5-minute break." : "Ready for the next focus sprint."]);
                root.pomodoroMode = nextMode;
                root.pomodoroRemaining = (nextMode === "focus" ? 25 : 5) * 60;
            }
        }
    }

    Process {
        id: nightProc
        command: ["wlsunset", "-t", "4200", "-T", "6500"]
        running: false
    }

    Process { id: execProc }
    Process { id: brightnessSetProc }

    // Initial brightness read
    Process {
        id: brightnessReadProc
        command: ["brightnessctl", "-m"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(",");
                if (parts.length >= 4) {
                    const pct = parseInt(parts[3].replace("%", ""));
                    if (!isNaN(pct)) root.brightness = pct / 100.0;
                }
            }
        }
        onExited: (code) => { if (code !== 0) root.hasBacklight = false; }
    }

    // Weather probe (every 40 minutes)
    Process {
        id: weatherProc
        command: ["python3", Quickshell.env("HOME") + "/.config/waybar/scripts/waybar-wttr.py"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    const d = JSON.parse(line);
                    if (d.text) {
                        const trimmed = d.text.trim();
                        const parts = trimmed.split(/\s+/);
                        if (parts.length >= 2) {
                            root.weatherIcon = parts[0];
                            root.weatherText = parts.slice(1).join(" ");
                        } else {
                            root.weatherText = trimmed;
                        }
                    }
                    if (d.tooltip) {
                        const first = d.tooltip.split("\n")[0].replace(/<[^>]+>/g, "");
                        root.weatherDesc = first;
                    }
                } catch (e) {}
            }
        }
    }
    Timer {
        interval: 40 * 60 * 1000
        repeat: true
        running: true
        onTriggered: weatherProc.running = true
    }

    // Arch updates probe (every 30 minutes)
    Process {
        id: updatesProc
        command: ["sh", "-c", "checkupdates 2>/dev/null | wc -l"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                const n = parseInt(line.trim());
                if (!isNaN(n)) root.updatesCount = n;
            }
        }
    }
    Timer {
        interval: 30 * 60 * 1000
        repeat: true
        running: true
        onTriggered: updatesProc.running = true
    }

    // On-demand CPU / RAM / Temp probe (ONLY active when dashboard/backdrop vitals are visible)
    Process {
        id: vitalsProc
        command: ["sh", "-c", "head -n 1 /proc/stat; awk '/MemTotal|MemAvailable/{print $1,$2}' /proc/meminfo; cat /sys/class/hwmon/hwmon*/temp1_input 2>/dev/null | head -n 1"]
        stdout: SplitParser {
            property var lines: []
            onRead: line => lines.push(line.trim())
        }
        onExited: {
            const ls = vitalsProc.stdout.lines;
            vitalsProc.stdout.lines = [];
            if (ls.length >= 3) {
                // CPU
                const cpuCols = ls[0].split(/\s+/).slice(1).map(Number);
                if (cpuCols.length >= 4) {
                    const idle = cpuCols[3] + (cpuCols[4] || 0);
                    const total = cpuCols.reduce((a, b) => a + b, 0);
                    if (root._prevCpu) {
                        const dt = total - root._prevCpu.total;
                        const di = idle - root._prevCpu.idle;
                        if (dt > 0) root.cpuPercent = Math.round(((dt - di) / dt) * 100);
                    }
                    root._prevCpu = { total: total, idle: idle };
                }
                // RAM
                let mTotal = 1, mAvail = 0;
                for (let i = 1; i < ls.length; i++) {
                    if (ls[i].startsWith("MemTotal:")) mTotal = parseInt(ls[i].split(/\s+/)[1]) || 1;
                    else if (ls[i].startsWith("MemAvailable:")) mAvail = parseInt(ls[i].split(/\s+/)[1]) || 0;
                    else if (/^\d+$/.test(ls[i])) root.cpuTemp = Math.round(parseInt(ls[i]) / 1000);
                }
                root.memPercent = Math.round(((mTotal - mAvail) / mTotal) * 100);
            }
        }
    }
    Timer {
        interval: 2000
        repeat: true
        running: root.vitalsWatchers > 0
        triggeredOnStart: true
        onTriggered: {
            if (!vitalsProc.running) vitalsProc.running = true;
        }
    }
}
