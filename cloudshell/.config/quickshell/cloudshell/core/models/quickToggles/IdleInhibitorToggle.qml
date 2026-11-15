import QtQuick
import Quickshell
import qs
import qs.services
import qs.core
import qs.core.functions
import qs.widgets

QuickToggleModel {
    name: qsTr("Keep awake")
    statusText: toggled ? qsTr("On") : qsTr("Off")
    toggled: Idle.inhibit
    icon: "coffee"
    mainAction: () => Idle.toggleInhibit()
    tooltipText: qsTr("Keep the system awake")
}
