import QtQuick
import qs.services
import qs.core
import qs.core.functions
import qs.widgets

QuickToggleModel {
    name: qsTr("Audio output")
    statusText: toggled ? qsTr("Unmuted") : qsTr("Muted")
    tooltipText: qsTr("Audio output | Right-click for volume mixer & device selector")
    toggled: !Audio.sink?.audio?.muted
    icon: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"
    mainAction: () => {
        Audio.toggleMute()
    }
    hasMenu: true
}
