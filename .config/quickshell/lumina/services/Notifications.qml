pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property bool dnd: false
    property int unreadCount: 0
    property int _nextUid: 1
    property var _liveMap: ({})

    property ListModel historyModel: ListModel {}
    property ListModel popupModel: ListModel {}

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: (n) => {
            n.tracked = true;
            const uid = root._nextUid++;
            root._liveMap[uid] = n;

            const actions = [];
            if (n.actions) {
                for (let i = 0; i < n.actions.length; i++) {
                    actions.push({
                        identifier: n.actions[i].identifier || "",
                        text: n.actions[i].text || "Open"
                    });
                }
            }

            const now = new Date();
            const hh = String(now.getHours()).padStart(2, "0");
            const mm = String(now.getMinutes()).padStart(2, "0");

            const entry = {
                uid: uid,
                appName: n.appName || "System",
                appIcon: n.appIcon || "",
                image: n.image || "",
                summary: n.summary || "Notification",
                body: n.body || "",
                urgency: n.urgency !== undefined ? n.urgency : 1,
                timeStr: hh + ":" + mm,
                actionsJson: JSON.stringify(actions),
                timeoutMs: n.urgency === 2 ? 0 : (n.expireTimeout > 0 ? n.expireTimeout : 5500)
            };

            root.historyModel.insert(0, entry);
            if (root.historyModel.count > 40) {
                const old = root.historyModel.get(root.historyModel.count - 1);
                if (old) delete root._liveMap[old.uid];
                root.historyModel.remove(root.historyModel.count - 1, 1);
            }

            if (!root.dnd || n.urgency === 2) {
                root.popupModel.insert(0, entry);
                if (root.popupModel.count > 4) {
                    root.popupModel.remove(root.popupModel.count - 1, 1);
                }
            }
            root.unreadCount++;

            if (n.closed) {
                n.closed.connect(() => {
                    root.removePopup(uid);
                });
            }
        }
    }

    function removePopup(uid) {
        for (let i = 0; i < popupModel.count; i++) {
            if (popupModel.get(i).uid === uid) {
                popupModel.remove(i, 1);
                break;
            }
        }
    }

    function dismiss(uid) {
        removePopup(uid);
        for (let i = 0; i < historyModel.count; i++) {
            if (historyModel.get(i).uid === uid) {
                historyModel.remove(i, 1);
                break;
            }
        }
        const n = _liveMap[uid];
        if (n) {
            try { n.dismiss(); } catch (e) {}
            delete _liveMap[uid];
        }
    }

    function invokeAction(uid, actionId) {
        const n = _liveMap[uid];
        if (!n || !n.actions) return;
        for (let i = 0; i < n.actions.length; i++) {
            if ((n.actions[i].identifier || "") === actionId) {
                n.actions[i].invoke();
                break;
            }
        }
        removePopup(uid);
    }

    function clearAll() {
        popupModel.clear();
        historyModel.clear();
        for (const k in _liveMap) {
            try { _liveMap[k].dismiss(); } catch (e) {}
        }
        _liveMap = ({});
        unreadCount = 0;
    }

    function markRead() {
        unreadCount = 0;
    }

    function toggleDnd() {
        dnd = !dnd;
        if (dnd) popupModel.clear();
    }
}
