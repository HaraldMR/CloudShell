pragma Singleton
pragma ComponentBehavior: Bound

import qs.core
import qs
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

/**
 * Notification server with Pixel-like behaviour:
 *  - Grouped by app, alerting notifications first and silent ones in their own section
 *  - Per-app rules: allow / silent (shade only, no popup) / block
 *  - Keyword filters (drop matching notifications)
 *  - Do Not Disturb with optional end time
 *  - Snooze (hide and bring back later)
 *  - History of everything received since boot (stored in $XDG_RUNTIME_DIR, wiped on reboot)
 */
Singleton {
    id: root

    component Notif: QtObject {
        id: wrapper
        required property int notificationId // Could just be `id` but it conflicts with the default prop in QtObject
        property Notification notification
        property list<var> actions: notification?.actions.map(action => ({
                    "identifier": action.identifier,
                    "text": action.text
                })) ?? []
        property bool popup: false
        property bool silent: false
        property bool isTransient: notification?.hints.transient ?? false
        property string appIcon: notification?.appIcon ?? ""
        property string appName: notification?.appName ?? ""
        property string body: notification?.body ?? ""
        property string image: notification?.image ?? ""
        property string summary: notification?.summary ?? ""
        property double time
        property double snoozedUntil: 0
        property string urgency: notification?.urgency.toString() ?? "normal"
        property Timer timer

        onNotificationChanged: {
            if (notification === null && snoozedUntil === 0) {
                root.discardNotification(notificationId);
            }
        }
    }

    function notifToJSON(notif) {
        return {
            "notificationId": notif.notificationId,
            "actions": notif.actions,
            "appIcon": notif.appIcon,
            "appName": notif.appName,
            "body": notif.body,
            "image": notif.image,
            "summary": notif.summary,
            "time": notif.time,
            "urgency": notif.urgency,
            "silent": notif.silent,
            "snoozedUntil": notif.snoozedUntil
        };
    }

    ////////////////////////// Rules //////////////////////////

    function matchesFilter(notification) {
        const filters = Config?.options?.notifications?.filters ?? [];
        return filters.some(filter => {
            const matchFn = filter.matchType === "contains" ? (value, pattern) => value.toLowerCase().includes(pattern.toLowerCase()) : (value, pattern) => value.toLowerCase() === pattern.toLowerCase();
            const appMatch = !filter.appName || matchFn(notification.appName ?? "", filter.appName);
            const summaryMatch = !filter.summary || matchFn(notification.summary ?? "", filter.summary);
            const bodyMatch = !filter.body || matchFn(notification.body ?? "", filter.body);
            const hasAnyField = filter.appName || filter.summary || filter.body;
            return hasAnyField && appMatch && summaryMatch && bodyMatch;
        });
    }

    function appRule(appName) {
        return Config.options.notifications.appRules?.[appName] ?? "allow";
    }

    function setAppRule(appName, rule) {
        const rules = Object.assign({}, Config.options.notifications.appRules ?? {});
        if (rule === "allow")
            delete rules[appName];
        else
            rules[appName] = rule;
        Config.options.notifications.appRules = rules;
    }

    function addFilter(filter) {
        Config.options.notifications.filters = [...Config.options.notifications.filters, filter];
    }

    function removeFilter(index) {
        const filters = Config.options.notifications.filters.slice(0);
        filters.splice(index, 1);
        Config.options.notifications.filters = filters;
    }

    ////////////////////////// Do Not Disturb //////////////////////////

    readonly property bool dnd: Persistent.states.notifications.dnd
    readonly property real dndUntil: Persistent.states.notifications.dndUntil
    // Kept for ported code that used ii's "silent" flag
    readonly property bool silent: dnd

    // minutes: 0 = until turned off, -1 = until 07:00 tomorrow
    function setDnd(enabled, minutes) {
        let until = 0;
        if (enabled && minutes > 0) {
            until = Date.now() + minutes * 60 * 1000;
        } else if (enabled && minutes === -1) {
            const d = new Date();
            d.setDate(d.getDate() + (d.getHours() >= 7 ? 1 : 0));
            d.setHours(7, 0, 0, 0);
            until = d.getTime();
        }
        Persistent.states.notifications.dndUntil = until;
        Persistent.states.notifications.dnd = enabled;
        if (enabled)
            root.timeoutAll();
    }

    function toggleDnd() {
        root.setDnd(!root.dnd, 0);
    }

    Timer {
        id: dndTimer
        running: root.dnd && root.dndUntil > 0
        interval: 15000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (Date.now() >= root.dndUntil)
                root.setDnd(false, 0);
        }
    }

    ////////////////////////// State //////////////////////////

    property int unread: 0
    property list<Notif> list: []        // In the shade
    property list<Notif> snoozed: []
    property list<var> history: []       // Plain JSON records, newest first
    readonly property int historyLimit: 300
    property var knownApps: ({})          // appName -> { appIcon, lastSeen, count }

    property var popupList: list.filter(notif => notif.popup)
    property bool popupInhibited: (GlobalStates?.dropdownOpen ?? false)
    property var latestTimeForApp: ({})

    Component {
        id: notifComponent
        Notif {}
    }

    component NotifTimer: Timer {
        required property int notificationId
        interval: 7000
        running: true
        onTriggered: () => {
            const index = root.list.findIndex(notif => notif.notificationId === notificationId);
            const notifObject = root.list[index];
            if (notifObject?.isTransient)
                root.discardNotification(notificationId);
            else
                root.timeoutNotification(notificationId);
            destroy();
        }
    }
    Component {
        id: notifTimerComponent
        NotifTimer {}
    }

    onListChanged: {
        root.list.forEach(notif => {
            if (!root.latestTimeForApp[notif.appName] || notif.time > root.latestTimeForApp[notif.appName]) {
                root.latestTimeForApp[notif.appName] = Math.max(root.latestTimeForApp[notif.appName] || 0, notif.time);
            }
        });
        Object.keys(root.latestTimeForApp).forEach(appName => {
            if (!root.list.some(notif => notif.appName === appName)) {
                delete root.latestTimeForApp[appName];
            }
        });
    }

    function appNameListForGroups(groups) {
        return Object.keys(groups).sort((a, b) => groups[b].time - groups[a].time);
    }

    function groupsForList(list) {
        const groups = {};
        list.forEach(notif => {
            if (!groups[notif.appName]) {
                groups[notif.appName] = {
                    appName: notif.appName,
                    appIcon: notif.appIcon,
                    notifications: [],
                    time: 0
                };
            }
            groups[notif.appName].notifications.push(notif);
            groups[notif.appName].time = latestTimeForApp[notif.appName] || notif.time;
        });
        return groups;
    }

    // Shade sections
    readonly property bool splitSilent: Config.options.notifications.showSilentSection
    property var alertingList: splitSilent ? list.filter(n => !n.silent) : list
    property var silentList: splitSilent ? list.filter(n => n.silent) : []
    property var groupsByAppName: groupsForList(root.alertingList)
    property var silentGroupsByAppName: groupsForList(root.silentList)
    property var popupGroupsByAppName: groupsForList(root.popupList)
    property list<string> appNameList: appNameListForGroups(root.groupsByAppName)
    property list<string> silentAppNameList: appNameListForGroups(root.silentGroupsByAppName)
    property list<string> popupAppNameList: appNameListForGroups(root.popupGroupsByAppName)

    // Quickshell's notification IDs start at 1 on each run, while saved notifications
    // can already contain higher IDs. This avoids collisions.
    property int idOffset
    signal initDone
    signal notify(notification: var)
    signal discard(id: int)
    signal discardAll
    signal timeout(id: var)

    NotificationServer {
        id: notifServer
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        bodySupported: true
        imageSupported: true
        keepOnReload: false
        persistenceSupported: true

        onNotification: notification => {
            const rule = root.appRule(notification.appName);
            if (rule === "block" || root.matchesFilter(notification))
                return; // dropped: never tracked, stored, or shown

            notification.tracked = true;
            const critical = notification.urgency === NotificationUrgency.Critical;
            const silent = rule === "silent";
            const newNotifObject = notifComponent.createObject(root, {
                "notificationId": notification.id + root.idOffset,
                "notification": notification,
                "time": Date.now(),
                "silent": silent
            });
            root.list = [...root.list, newNotifObject];
            root.rememberApp(newNotifObject);
            root.addToHistory(newNotifObject);

            const quiet = silent || (root.dnd && !critical);
            if (!root.popupInhibited && !quiet) {
                newNotifObject.popup = true;
                if (notification.expireTimeout != 0) {
                    newNotifObject.timer = notifTimerComponent.createObject(root, {
                        "notificationId": newNotifObject.notificationId,
                        "interval": notification.expireTimeout < 0 ? (Config?.options.notifications.timeout ?? 7000) : notification.expireTimeout
                    });
                }
            }
            if (!silent)
                root.unread++;
            root.notify(newNotifObject);
            root.saveList();
        }
    }

    function rememberApp(notif) {
        if (!notif.appName)
            return;
        const apps = Object.assign({}, root.knownApps);
        const prev = apps[notif.appName] ?? {
            count: 0
        };
        apps[notif.appName] = {
            appIcon: notif.appIcon || prev.appIcon || "",
            lastSeen: notif.time,
            count: (prev.count ?? 0) + 1
        };
        root.knownApps = apps;
        appsFileView.setText(JSON.stringify(apps, null, 2));
    }

    function addToHistory(notif) {
        const record = root.notifToJSON(notif);
        delete record.actions;
        root.history = [record, ...root.history].slice(0, root.historyLimit);
        historyFileView.setText(JSON.stringify(root.history));
    }

    function clearHistory() {
        root.history = [];
        historyFileView.setText("[]");
    }

    function saveList() {
        notifFileView.setText(JSON.stringify({
            "list": root.list.map(n => root.notifToJSON(n)),
            "snoozed": root.snoozed.map(n => root.notifToJSON(n))
        }, null, 2));
    }

    function markAllRead() {
        root.unread = 0;
    }

    function discardNotification(id) {
        const index = root.list.findIndex(notif => notif.notificationId === id);
        const notifServerIndex = notifServer.trackedNotifications.values.findIndex(notif => notif.id + root.idOffset === id);
        if (index !== -1) {
            root.list.splice(index, 1);
            root.triggerListChange();
            root.saveList();
        }
        if (notifServerIndex !== -1) {
            notifServer.trackedNotifications.values[notifServerIndex].dismiss();
        }
        root.discard(id);
    }

    function discardAllNotifications() {
        root.list = [];
        root.triggerListChange();
        root.saveList();
        notifServer.trackedNotifications.values.forEach(notif => notif.dismiss());
        root.discardAll();
    }

    function discardSilentNotifications() {
        root.silentList.forEach(n => root.discardNotification(n.notificationId));
    }

    function discardAppNotifications(appName) {
        root.list.filter(n => n.appName === appName).forEach(n => root.discardNotification(n.notificationId));
    }

    // Hide a notification from the shade and bring it back after `minutes`
    function snooze(id, minutes) {
        const index = root.list.findIndex(notif => notif.notificationId === id);
        if (index === -1)
            return;
        const notif = root.list[index];
        // Freeze the values so they survive the sender closing the notification
        notif.appName = notif.appName;
        notif.appIcon = notif.appIcon;
        notif.summary = notif.summary;
        notif.body = notif.body;
        notif.image = notif.image;
        notif.urgency = notif.urgency;
        notif.snoozedUntil = Date.now() + minutes * 60 * 1000;
        notif.popup = false;
        root.list.splice(index, 1);
        root.triggerListChange();
        root.snoozed = [...root.snoozed, notif];
        root.saveList();
    }

    function unsnooze(id) {
        const index = root.snoozed.findIndex(notif => notif.notificationId === id);
        if (index === -1)
            return;
        const notif = root.snoozed[index];
        root.snoozed.splice(index, 1);
        root.snoozed = root.snoozed.slice(0);
        notif.snoozedUntil = 0;
        notif.time = Date.now();
        root.list = [...root.list, notif];
        if (!notif.silent && !root.dnd && !root.popupInhibited) {
            notif.popup = true;
            notif.timer = notifTimerComponent.createObject(root, {
                "notificationId": notif.notificationId,
                "interval": Config?.options.notifications.timeout ?? 7000
            });
        }
        root.unread++;
        root.saveList();
    }

    Timer {
        running: root.snoozed.length > 0
        interval: 10000
        repeat: true
        onTriggered: {
            const now = Date.now();
            root.snoozed.filter(n => n.snoozedUntil <= now).forEach(n => root.unsnooze(n.notificationId));
        }
    }

    function cancelTimeout(id) {
        const index = root.list.findIndex(notif => notif.notificationId === id);
        if (root.list[index] != null)
            root.list[index].timer?.stop();
    }

    function timeoutNotification(id) {
        const index = root.list.findIndex(notif => notif.notificationId === id);
        if (root.list[index] != null)
            root.list[index].popup = false;
        root.timeout(id);
    }

    function timeoutAll() {
        root.popupList.forEach(notif => root.timeout(notif.notificationId));
        root.popupList.forEach(notif => {
            notif.popup = false;
        });
    }

    function attemptInvokeAction(id, notifIdentifier) {
        const notifServerIndex = notifServer.trackedNotifications.values.findIndex(notif => notif.id + root.idOffset === id);
        if (notifServerIndex !== -1) {
            const notifServerNotif = notifServer.trackedNotifications.values[notifServerIndex];
            const action = notifServerNotif.actions.find(action => action.identifier === notifIdentifier);
            action?.invoke();
        }
        root.discardNotification(id);
    }

    function triggerListChange() {
        root.list = root.list.slice(0);
    }

    ////////////////////////// Storage //////////////////////////

    function restoreNotif(notif) {
        return notifComponent.createObject(root, {
            "notificationId": notif.notificationId,
            "actions": [], // Actions are meaningless once the sender is gone
            "appIcon": notif.appIcon,
            "appName": notif.appName,
            "body": notif.body,
            "image": notif.image,
            "summary": notif.summary,
            "time": notif.time,
            "urgency": notif.urgency,
            "silent": notif.silent ?? false,
            "snoozedUntil": notif.snoozedUntil ?? 0
        });
    }

    Component.onCompleted: {
        notifFileView.reload();
        historyFileView.reload();
        appsFileView.reload();
    }

    // Active + snoozed notifications. Runtime dir, so cleared on boot.
    FileView {
        id: notifFileView
        path: Qt.resolvedUrl(Directories.notificationsPath)
        printErrors: false
        onLoaded: {
            let data = {};
            try {
                data = JSON.parse(notifFileView.text());
            } catch (e) {}
            root.list = (data.list ?? []).map(n => root.restoreNotif(n));
            root.snoozed = (data.snoozed ?? []).map(n => root.restoreNotif(n));
            let maxId = 0;
            [...root.list, ...root.snoozed].forEach(n => maxId = Math.max(maxId, n.notificationId));
            root.idOffset = maxId;
            root.initDone();
        }
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                root.list = [];
                root.saveList();
            }
        }
    }

    FileView {
        id: historyFileView
        path: Qt.resolvedUrl(`${Directories.shellRuntime}/notification-history.json`)
        printErrors: false
        onLoaded: {
            try {
                root.history = JSON.parse(historyFileView.text());
            } catch (e) {
                root.history = [];
            }
        }
    }

    // Apps that have sent notifications, for per-app settings. Persistent.
    FileView {
        id: appsFileView
        path: Qt.resolvedUrl(Directories.notificationAppsPath)
        printErrors: false
        onLoaded: {
            try {
                root.knownApps = JSON.parse(appsFileView.text());
            } catch (e) {
                root.knownApps = {};
            }
        }
    }

    IpcHandler {
        target: "notifications"
        function dnd(minutes: int): void {
            root.setDnd(true, minutes);
        }
        function dndOff(): void {
            root.setDnd(false, 0);
        }
        function toggleDnd(): void {
            root.toggleDnd();
        }
        function clear(): void {
            root.discardAllNotifications();
        }
    }
}
