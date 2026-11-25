pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var workspaces: []
    property var windows: []
    property var focusedWindow: null
    property var layoutNames: ["English (US)", "Russian"]
    property int layoutIdx: 0
    property bool overviewOpen: false
    property bool isCasting: false

    readonly property string layoutShort: {
        const name = (layoutNames[layoutIdx] || "US").toLowerCase();
        if (name.indexOf("russian") !== -1 || name.indexOf("ru") !== -1) return "RU";
        if (name.indexOf("english") !== -1 || name.indexOf("us") !== -1) return "US";
        return (layoutNames[layoutIdx] || "US").substring(0, 2).toUpperCase();
    }

    signal layoutSwitched(string shortName)

    property bool _layoutInitialized: false

    function sortWorkspaces(list) {
        return list.slice().sort((a, b) => a.idx - b.idx);
    }

    function refreshFocusedWindow() {
        let found = null;
        for (let i = 0; i < windows.length; i++) {
            if (windows[i].is_focused) {
                found = windows[i];
                break;
            }
        }
        focusedWindow = found;
    }

    function windowCountForWorkspace(wsId) {
        let count = 0;
        for (let i = 0; i < windows.length; i++) {
            if (windows[i].workspace_id === wsId) count++;
        }
        return count;
    }

    function handleEvent(line) {
        if (!line || line.trim() === "") return;
        let ev;
        try {
            ev = JSON.parse(line);
        } catch (e) {
            return;
        }

        if (ev.WorkspacesChanged) {
            workspaces = sortWorkspaces(ev.WorkspacesChanged.workspaces || []);
        } else if (ev.WorkspaceActivated) {
            const id = ev.WorkspaceActivated.id;
            const focused = ev.WorkspaceActivated.focused;
            workspaces = workspaces.map(ws => {
                const copy = Object.assign({}, ws);
                if (copy.id === id) {
                    copy.is_active = true;
                    if (focused) copy.is_focused = true;
                } else {
                    copy.is_active = false;
                    if (focused) copy.is_focused = false;
                }
                return copy;
            });
        } else if (ev.WorkspaceUrgencyChanged) {
            const id = ev.WorkspaceUrgencyChanged.id;
            const urgent = ev.WorkspaceUrgencyChanged.urgent;
            workspaces = workspaces.map(ws => ws.id === id ? Object.assign({}, ws, { is_urgent: urgent }) : ws);
        } else if (ev.WindowsChanged) {
            windows = ev.WindowsChanged.windows || [];
            refreshFocusedWindow();
        } else if (ev.WindowOpenedOrChanged) {
            const w = ev.WindowOpenedOrChanged.window;
            let replaced = false;
            const next = windows.map(item => {
                if (item.id === w.id) {
                    replaced = true;
                    return w;
                }
                if (w.is_focused && item.is_focused) {
                    return Object.assign({}, item, { is_focused: false });
                }
                return item;
            });
            if (!replaced) next.push(w);
            windows = next;
            refreshFocusedWindow();
        } else if (ev.WindowClosed) {
            const id = ev.WindowClosed.id;
            windows = windows.filter(item => item.id !== id);
            refreshFocusedWindow();
        } else if (ev.WindowFocusChanged) {
            const id = ev.WindowFocusChanged.id;
            windows = windows.map(item => Object.assign({}, item, { is_focused: item.id === id }));
            refreshFocusedWindow();
        } else if (ev.KeyboardLayoutsChanged) {
            const kl = ev.KeyboardLayoutsChanged.keyboard_layouts;
            layoutNames = kl.names || ["English (US)"];
            layoutIdx = kl.current_idx || 0;
            _layoutInitialized = true;
        } else if (ev.KeyboardLayoutSwitched) {
            layoutIdx = ev.KeyboardLayoutSwitched.idx || 0;
            if (_layoutInitialized) layoutSwitched(layoutShort);
        } else if (ev.OverviewOpenedOrClosed) {
            overviewOpen = !!ev.OverviewOpenedOrClosed.is_open;
        } else if (ev.CastsChanged) {
            const casts = ev.CastsChanged.casts || [];
            isCasting = casts.some(c => c.is_active);
        }
    }

    function msgAction(args) {
        actionProc.exec(["niri", "msg", "action"].concat(args));
    }

    function focusWorkspace(idx) {
        msgAction(["focus-workspace", String(idx)]);
    }

    function focusWindow(id) {
        msgAction(["focus-window", "--id", String(id)]);
    }

    function closeWindow(id) {
        if (id !== undefined) {
            actionProc.exec(["niri", "msg", "action", "close-window", "--id", String(id)]);
        } else {
            msgAction(["close-window"]);
        }
    }

    function toggleOverview() {
        msgAction(["toggle-overview"]);
    }

    function switchLayout() {
        msgAction(["switch-layout", "next"]);
    }

    Process {
        id: streamProc
        command: ["niri", "msg", "--json", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: line => root.handleEvent(line)
        }
        onExited: restartTimer.restart()
    }

    Timer {
        id: restartTimer
        interval: 1000
        onTriggered: streamProc.running = true
    }

    Process {
        id: actionProc
    }
}
