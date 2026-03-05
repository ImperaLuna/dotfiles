pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

QtObject {
    id: root

    property int defaultExpireTimeout: 5000
    property int historyLimit: 200
    readonly property alias model: store
    readonly property int count: store.count
    property int popupCount: 0
    property int hoverCount: 0
    property var states: []
    signal popupAdded()

    function formatAge(timestamp) {
        const diff = Date.now() - timestamp;
        const minutes = Math.floor(diff / 60000);

        if (minutes < 1)
            return "now";

        const hours = Math.floor(minutes / 60);
        const days = Math.floor(hours / 24);
        if (days > 0)
            return days + "d";
        if (hours > 0)
            return hours + "h";
        return minutes + "m";
    }

    function normalizeLine(text) {
        const normalized = String(text ?? "").replace(/\s+/g, " ").trim();
        return normalized;
    }

    function formatDisplayFields(appName, summary, body) {
        const sourceLine = normalizeLine(appName);
        let titleLine = normalizeLine(summary);
        let previewLine = normalizeLine(body);

        if (sourceLine.length > 0 && titleLine.length > 0) {
            const lowerSource = sourceLine.toLowerCase();
            const lowerTitle = titleLine.toLowerCase();
            if (lowerTitle.startsWith(lowerSource + " - "))
                titleLine = titleLine.slice(sourceLine.length + 3).trim();
            else if (lowerTitle.startsWith(lowerSource + ":"))
                titleLine = titleLine.slice(sourceLine.length + 1).trim();
        }

        const sourceIsDiscord = sourceLine.toLowerCase().indexOf("discord") !== -1;
        if (sourceIsDiscord && titleLine.length === 0 && previewLine.indexOf(":") > 0) {
            const splitAt = previewLine.indexOf(":");
            const guessedHeader = previewLine.slice(0, splitAt).trim();
            if (guessedHeader.length > 0 && guessedHeader.length < 80) {
                titleLine = guessedHeader;
                previewLine = previewLine.slice(splitAt + 1).trim();
            }
        }

        if (titleLine.length === 0) {
            if (previewLine.length > 0) {
                titleLine = previewLine;
                previewLine = "";
            } else {
                titleLine = sourceLine.length > 0 ? sourceLine : "Notification";
            }
        }

        return {
            sourceLine: sourceLine.length > 0 ? sourceLine : "Notification",
            titleLine: titleLine,
            previewLine: previewLine
        };
    }

    function resolveIconSource(raw) {
        if (!raw || raw.length === 0)
            return "";
        if (raw.startsWith("/") || raw.startsWith("file:") || raw.startsWith("qrc:")
                || raw.startsWith("http:") || raw.startsWith("https:"))
            return raw;
        // Avoid noisy theme-icon lookup warnings for missing names.
        // If appIcon is only a theme icon name, let the UI use placeholder.
        return "";
    }

    function tryInvokePrimaryNotificationAction(state) {
        const notification = state?.notification;
        if (!notification || !notification.actions || notification.actions.length === 0)
            return false;

        let chosen = null;
        for (const action of notification.actions) {
            if (action.identifier === "default") {
                chosen = action;
                break;
            }
        }
        if (!chosen)
            chosen = notification.actions[0];
        if (!chosen)
            return false;

        try {
            chosen.invoke();
            return true;
        } catch (_err) {
            return false;
        }
    }

    function launchFromState(state) {
        if (!state)
            return false;

        const desktopEntry = state.desktopEntry || "";
        if (desktopEntry.length > 0) {
            Quickshell.execDetached(["gtk-launch", desktopEntry]);
            return true;
        }

        return false;
    }

    function updateState(state) {
        if (state.modelIndex < 0 || state.modelIndex >= store.count)
            return;

        store.set(state.modelIndex, state.toRecord());
        recalcPopupCount();
    }

    function insertState(state) {
        state.modelIndex = states.length;
        states.push(state);
        store.append(state.toRecord());

        if (store.count > historyLimit)
            removeAt(0, false);

        recalcPopupCount();
        if (state.popup)
            popupAdded();
    }

    function removeState(state, dismissServer) {
        removeAt(state.modelIndex, dismissServer);
    }

    function removeAt(index, dismissServer) {
        if (index < 0 || index >= store.count)
            return;

        const state = states[index];
        if (!state)
            return;

        if (dismissServer && !state.closing && state.notification) {
            state.closing = true;
            state.notification.dismiss();
        }

        store.remove(index, 1);
        states.splice(index, 1);
        state.modelIndex = -1;
        state.destroy();

        for (let i = index; i < states.length; i++)
            states[i].modelIndex = i;

        recalcPopupCount();
    }

    function dismissByIndex(index) {
        removeAt(index, true);
    }

    function setExpanded(index, value) {
        if (index < 0 || index >= states.length)
            return;

        const state = states[index];
        if (!state)
            return;

        state.expanded = value;
        store.setProperty(index, "expanded", value);
    }

    function invokePrimaryAction(index) {
        if (index < 0 || index >= states.length)
            return;

        const state = states[index];
        if (tryInvokePrimaryNotificationAction(state))
            return;

        launchFromState(state);
    }

    function setHovered(index, hovered) {
        if (index < 0 || index >= states.length)
            return;

        const state = states[index];
        if (!state)
            return;

        if (state.hovered === hovered)
            return;

        state.hovered = hovered;
        hoverCount += hovered ? 1 : -1;
        if (hoverCount < 0)
            hoverCount = 0;

        if (hoverCount > 0) {
            for (const item of states)
                item.popupTimer.stop();
        } else {
            for (const item of states)
                item.restartPopupTimer();
        }
    }

    function recalcPopupCount() {
        let n = 0;
        for (let i = 0; i < store.count; i++) {
            if (store.get(i).popup)
                n += 1;
        }
        popupCount = n;
    }

    function handleNotification(notification) {
        const state = notifStateComp.createObject(root, {
            notification: notification
        });
        insertState(state);
    }

    readonly property Timer ageRefreshTimer: Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: {
            for (const state of root.states) {
                state.updateAgeText();
                root.updateState(state);
            }
        }
    }

    readonly property NotificationServer server: NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true;
            root.handleNotification(notification);
        }
    }

    readonly property ListModel store: ListModel {
        id: store
    }

    component NotifState: QtObject {
        id: state

        property var notification
        property int modelIndex: -1
        property bool closing: false
        property string notifId: ""
        property string appName: ""
        property string desktopEntry: ""
        property string ageText: "now"
        property string summary: ""
        property string body: ""
        property string sourceLine: ""
        property string titleLine: ""
        property string previewLine: ""
        property string iconSource: ""
        property string imageSource: ""
        property bool canLaunch: false
        property bool hasPrimaryAction: false
        property bool expanded: false
        property bool popup: true
        property bool hovered: false
        property double timestamp: Date.now()
        property int expireTimeout: root.defaultExpireTimeout

        function notificationText() {
            if (body && body.trim().length > 0)
                return body;
            return summary;
        }

        function toRecord() {
            return {
                appName: appName,
                ageText: ageText,
                sourceLine: sourceLine,
                titleLine: titleLine,
                previewLine: previewLine,
                summary: summary,
                body: body,
                iconSource: iconSource,
                imageSource: imageSource,
                hasPrimaryAction: hasPrimaryAction,
                expanded: expanded,
                popup: popup,
                timestamp: timestamp
            };
        }

        function updateAgeText() {
            ageText = root.formatAge(timestamp);
        }

        function restartPopupTimer() {
            if (root.hoverCount > 0 || hovered || !popup) {
                popupTimer.stop();
                return;
            }

            if (expireTimeout <= 0)
                popupTimer.stop();
            else {
                popupTimer.interval = expireTimeout;
                popupTimer.restart();
            }
        }

        function refreshFromNotification() {
            if (!notification)
                return;

            notifId = String(notification.id);
            appName = notification.appName || "";
            desktopEntry = notification.desktopEntry || "";
            summary = notification.summary || "";
            body = notification.body || "";
            const display = root.formatDisplayFields(appName, summary, body);
            sourceLine = display.sourceLine;
            titleLine = display.titleLine;
            previewLine = display.previewLine;
            iconSource = root.resolveIconSource(notification.appIcon || "");
            imageSource = notification.image || "";
            canLaunch = desktopEntry.length > 0;
            hasPrimaryAction = canLaunch || (notification.actions && notification.actions.length > 0);
            expireTimeout = notification.expireTimeout > 0 ? notification.expireTimeout : root.defaultExpireTimeout;
            timestamp = Date.now();
            updateAgeText();
            restartPopupTimer();
        }

        function closeFromServer() {
            // Keep history/popups when apps replace notifications with the same ID.
            // We only remove immediately when we explicitly dismiss from our UI path.
            if (closing) {
                root.removeState(state, false);
                return;
            }

            notification = null;
            restartPopupTimer();
        }

        readonly property Connections conn: Connections {
            target: state.notification
            function onClosed() {
                state.closeFromServer();
            }
            function onSummaryChanged() {
                state.refreshFromNotification();
                root.updateState(state);
            }
            function onBodyChanged() {
                state.refreshFromNotification();
                root.updateState(state);
            }
            function onAppIconChanged() {
                state.refreshFromNotification();
                root.updateState(state);
            }
            function onAppNameChanged() {
                state.refreshFromNotification();
                root.updateState(state);
            }
            function onImageChanged() {
                state.refreshFromNotification();
                root.updateState(state);
            }
            function onExpireTimeoutChanged() {
                state.refreshFromNotification();
                root.updateState(state);
            }
            function onDesktopEntryChanged() {
                state.refreshFromNotification();
                root.updateState(state);
            }
            function onActionsChanged() {
                state.refreshFromNotification();
                root.updateState(state);
            }
        }

        readonly property Timer popupTimer: Timer {
            id: popupTimer
            interval: state.expireTimeout
            running: false
            onTriggered: {
                state.popup = false;
                root.updateState(state);
            }
        }

        Component.onCompleted: {
            refreshFromNotification();
        }
    }

    readonly property Component notifStateComp: Component {
        id: notifStateComp
        NotifState {}
    }
}
