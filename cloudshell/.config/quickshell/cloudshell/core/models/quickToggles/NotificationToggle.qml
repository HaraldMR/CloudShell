import QtQuick
import Quickshell
import qs
import qs.services
import qs.core
import qs.core.functions
import qs.widgets

QuickToggleModel {
    name: qsTr("Do Not Disturb")
    statusText: !toggled ? qsTr("Off") : (Notifications.dndUntil > 0 ? qsTr("Until %1").arg(Qt.formatDateTime(new Date(Notifications.dndUntil), Config.options.time.format)) : qsTr("On"))
    toggled: Notifications.dnd
    icon: toggled ? "do_not_disturb_on" : "do_not_disturb_off"

    mainAction: () => Notifications.toggleDnd()
    hasMenu: true

    tooltipText: qsTr("Do Not Disturb | Right-click for durations")
}
