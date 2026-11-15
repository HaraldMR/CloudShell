pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.core
import qs.core.functions
import qs.widgets

ContentPage {
    id: page
    forceWidth: true

    // ---------------- Do Not Disturb ----------------
    ContentSection {
        icon: "do_not_disturb_on"
        title: qsTr("Do Not Disturb")

        ConfigSwitch {
            buttonIcon: Notifications.dnd ? "do_not_disturb_on" : "do_not_disturb_off"
            text: Notifications.dnd ? (Notifications.dndUntil > 0 ? qsTr("On until %1").arg(Qt.formatDateTime(new Date(Notifications.dndUntil), "ddd " + Config.options.time.format)) : qsTr("On until you turn it off")) : qsTr("Off")
            checked: Notifications.dnd
            onCheckedChanged: if (checked !== Notifications.dnd)
                Notifications.setDnd(checked, 0)
        }
        ContentSubsection {
            title: qsTr("Silence for a while")
            ConfigSelectionArray {
                currentValue: null
                onSelected: newValue => Notifications.setDnd(true, newValue)
                options: [
                    { "displayName": qsTr("15 min"), "icon": "timer", "value": 15 },
                    { "displayName": qsTr("1 hour"), "icon": "timer", "value": 60 },
                    { "displayName": qsTr("2 hours"), "icon": "timer", "value": 120 },
                    { "displayName": qsTr("8 hours"), "icon": "bedtime", "value": 480 },
                    { "displayName": qsTr("Until 07:00"), "icon": "wb_sunny", "value": -1 }
                ]
            }
        }
    }

    // ---------------- Behaviour ----------------
    ContentSection {
        icon: "tune"
        title: qsTr("Behaviour")

        ConfigSpinBox {
            icon: "av_timer"
            text: qsTr("Popup duration (seconds)")
            value: Config.options.notifications.timeout / 1000
            from: 1
            to: 60
            stepSize: 1
            onValueChanged: Config.options.notifications.timeout = value * 1000
        }
        ConfigSwitch {
            buttonIcon: "notifications_off"
            text: qsTr("Show silent notifications in their own section")
            checked: Config.options.notifications.showSilentSection
            onCheckedChanged: Config.options.notifications.showSilentSection = checked
        }
        ConfigSwitch {
            buttonIcon: "monitor"
            text: qsTr("Always show popups on one monitor")
            checked: Config.options.notifications.forceMonitor.enable
            onCheckedChanged: Config.options.notifications.forceMonitor.enable = checked
        }
        ConfigSelectionArray {
            visible: Config.options.notifications.forceMonitor.enable
            currentValue: Config.options.notifications.forceMonitor.name
            onSelected: newValue => Config.options.notifications.forceMonitor.name = newValue
            options: Quickshell.screens.map(s => ({
                        "displayName": s.name,
                        "icon": "monitor",
                        "value": s.name
                    }))
        }
    }

    // ---------------- Per-app ----------------
    ContentSection {
        icon: "apps"
        title: qsTr("App notifications")

        StyledText {
            Layout.fillWidth: true
            visible: Object.keys(Notifications.knownApps).length === 0
            text: qsTr("Apps show up here after they send a notification.")
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }

        Repeater {
            model: Object.keys(Notifications.knownApps).sort((a, b) => a.localeCompare(b))
            delegate: RowLayout {
                id: appRow
                required property string modelData
                Layout.fillWidth: true
                spacing: 10

                NotificationAppIcon {
                    implicitSize: 32
                    appIcon: Notifications.knownApps[appRow.modelData]?.appIcon ?? ""
                    summary: appRow.modelData
                }
                StyledText {
                    Layout.fillWidth: true
                    text: appRow.modelData
                    elide: Text.ElideRight
                    color: Appearance.colors.colOnLayer1
                }
                ConfigSelectionArray {
                    Layout.fillWidth: false
                    currentValue: Notifications.appRule(appRow.modelData)
                    onSelected: newValue => Notifications.setAppRule(appRow.modelData, newValue)
                    options: [
                        { "displayName": qsTr("Allow"), "icon": "notifications_active", "value": "allow" },
                        { "displayName": qsTr("Silent"), "icon": "notifications_paused", "value": "silent" },
                        { "displayName": qsTr("Block"), "icon": "block", "value": "block" }
                    ]
                }
            }
        }
    }

    // ---------------- Filters ----------------
    ContentSection {
        icon: "filter_alt"
        title: qsTr("Filters")

        StyledText {
            Layout.fillWidth: true
            text: qsTr("Notifications matching a filter are dropped. Fill in one or more fields; all filled fields must match.")
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }

        Repeater {
            model: Config.options.notifications.filters
            delegate: RowLayout {
                id: filterRow
                required property var modelData
                required property int index
                Layout.fillWidth: true
                MaterialSymbol {
                    text: "filter_alt"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    color: Appearance.colors.colOnLayer1
                    text: [filterRow.modelData.appName ? qsTr("App %1").arg(filterRow.modelData.appName) : "", filterRow.modelData.summary ? qsTr("Title %1").arg(filterRow.modelData.summary) : "", filterRow.modelData.body ? qsTr("Text %1").arg(filterRow.modelData.body) : ""].filter(Boolean).join(" · ") + ` (${filterRow.modelData.matchType === "contains" ? qsTr("contains") : qsTr("exact")})`
                }
                RippleButton {
                    implicitWidth: 32
                    implicitHeight: 32
                    buttonRadius: Appearance.rounding.full
                    onClicked: Notifications.removeFilter(filterRow.index)
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        text: "delete"
                        iconSize: 18
                    }
                }
            }
        }

        ConfigRow {
            uniform: true
            MaterialTextField {
                id: filterApp
                Layout.fillWidth: true
                placeholderText: qsTr("App name")
            }
            MaterialTextField {
                id: filterSummary
                Layout.fillWidth: true
                placeholderText: qsTr("Title")
            }
            MaterialTextField {
                id: filterBody
                Layout.fillWidth: true
                placeholderText: qsTr("Text")
            }
        }
        RowLayout {
            Layout.fillWidth: true
            ConfigSelectionArray {
                id: matchTypeSelector
                property string value: "contains"
                Layout.fillWidth: false
                currentValue: value
                onSelected: newValue => value = newValue
                options: [
                    { "displayName": qsTr("Contains"), "icon": "match_word", "value": "contains" },
                    { "displayName": qsTr("Exact"), "icon": "equal", "value": "exact" }
                ]
            }
            Item {
                Layout.fillWidth: true
            }
            RippleButtonWithIcon {
                materialIcon: "add"
                mainText: qsTr("Add filter")
                enabled: filterApp.text.length > 0 || filterSummary.text.length > 0 || filterBody.text.length > 0
                onClicked: {
                    Notifications.addFilter({
                        "appName": filterApp.text,
                        "summary": filterSummary.text,
                        "body": filterBody.text,
                        "matchType": matchTypeSelector.value
                    });
                    filterApp.text = "";
                    filterSummary.text = "";
                    filterBody.text = "";
                }
            }
        }
    }

    // ---------------- Snoozed ----------------
    ContentSection {
        icon: "snooze"
        title: qsTr("Snoozed")
        visible: Notifications.snoozed.length > 0

        Repeater {
            model: Notifications.snoozed
            delegate: RowLayout {
                id: snoozedRow
                required property var modelData
                Layout.fillWidth: true
                StyledText {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    color: Appearance.colors.colOnLayer1
                    text: `${snoozedRow.modelData.appName}: ${snoozedRow.modelData.summary}`
                }
                StyledText {
                    color: Appearance.colors.colSubtext
                    text: qsTr("until %1").arg(Qt.formatDateTime(new Date(snoozedRow.modelData.snoozedUntil), Config.options.time.format))
                }
                RippleButtonWithIcon {
                    materialIcon: "notifications_active"
                    mainText: qsTr("Show now")
                    onClicked: Notifications.unsnooze(snoozedRow.modelData.notificationId)
                }
            }
        }
    }

    // ---------------- History ----------------
    ContentSection {
        icon: "history"
        title: qsTr("History since boot")

        RowLayout {
            Layout.fillWidth: true
            MaterialTextField {
                id: historySearch
                Layout.fillWidth: true
                placeholderText: qsTr("Search history")
            }
            RippleButtonWithIcon {
                materialIcon: "delete_sweep"
                mainText: qsTr("Clear history")
                enabled: Notifications.history.length > 0
                onClicked: Notifications.clearHistory()
            }
        }

        StyledText {
            visible: historyColumn.groups.length === 0
            text: qsTr("No notifications since boot")
            color: Appearance.colors.colSubtext
        }

        ColumnLayout {
            id: historyColumn
            Layout.fillWidth: true
            spacing: 10
            readonly property string query: historySearch.text.toLowerCase()
            // [{ appName, appIcon, items: [...] }] grouped by app, newest group first
            readonly property var groups: {
                const filtered = Notifications.history.filter(n => query.length === 0 || `${n.appName} ${n.summary} ${n.body}`.toLowerCase().includes(query));
                const byApp = {};
                const order = [];
                for (const n of filtered) {
                    const key = n.appName || qsTr("Unknown");
                    if (!byApp[key]) {
                        byApp[key] = {
                            "appName": key,
                            "appIcon": n.appIcon,
                            "items": []
                        };
                        order.push(key);
                    }
                    byApp[key].items.push(n);
                }
                return order.map(k => byApp[k]);
            }

            Repeater {
                model: historyColumn.groups
                delegate: Rectangle {
                    id: historyGroup
                    required property var modelData
                    property bool expanded: false
                    Layout.fillWidth: true
                    implicitHeight: groupColumn.implicitHeight + 20
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colLayer2

                    ColumnLayout {
                        id: groupColumn
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 10
                        }
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            NotificationAppIcon {
                                implicitSize: 28
                                appIcon: historyGroup.modelData.appIcon
                                summary: historyGroup.modelData.appName
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: historyGroup.modelData.appName
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colOnLayer2
                            }
                            StyledText {
                                text: qsTr("%n notification(s)", "", historyGroup.modelData.items.length)
                                color: Appearance.colors.colSubtext
                                font.pixelSize: Appearance.font.pixelSize.smaller
                            }
                            RippleButton {
                                visible: historyGroup.modelData.items.length > 3
                                implicitWidth: 30
                                implicitHeight: 30
                                buttonRadius: Appearance.rounding.full
                                onClicked: historyGroup.expanded = !historyGroup.expanded
                                contentItem: MaterialSymbol {
                                    anchors.centerIn: parent
                                    horizontalAlignment: Text.AlignHCenter
                                    text: historyGroup.expanded ? "expand_less" : "expand_more"
                                    iconSize: 20
                                }
                            }
                        }

                        Repeater {
                            model: historyGroup.expanded ? historyGroup.modelData.items : historyGroup.modelData.items.slice(0, 3)
                            delegate: RowLayout {
                                id: historyItem
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.leftMargin: 38
                                spacing: 8
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    StyledText {
                                        Layout.fillWidth: true
                                        text: historyItem.modelData.summary
                                        elide: Text.ElideRight
                                        color: Appearance.colors.colOnLayer2
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        visible: text.length > 0
                                        text: NotificationUtils.processNotificationBody(historyItem.modelData.body ?? "", historyItem.modelData.appName).replace(/<[^>]*>/g, "")
                                        elide: Text.ElideRight
                                        maximumLineCount: 2
                                        wrapMode: Text.Wrap
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colSubtext
                                    }
                                }
                                StyledText {
                                    Layout.alignment: Qt.AlignTop
                                    text: Qt.formatDateTime(new Date(historyItem.modelData.time), Config.options.time.format)
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
