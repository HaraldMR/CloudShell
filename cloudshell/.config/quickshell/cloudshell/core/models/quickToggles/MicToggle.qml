import QtQuick
import Quickshell
import qs
import qs.services
import qs.core
import qs.core.functions
import qs.widgets

QuickToggleModel {
    name: qsTr("Audio input")
    statusText: toggled ? qsTr("Enabled") : qsTr("Muted")
    toggled: !Audio.source?.audio?.muted
    icon: Audio.source?.audio?.muted ? "mic_off" : "mic"
    mainAction: () => {
        Audio.toggleMicMute()
    }
    hasMenu: true

    tooltipText: qsTr("Audio input | Right-click for volume mixer & device selector")
}
