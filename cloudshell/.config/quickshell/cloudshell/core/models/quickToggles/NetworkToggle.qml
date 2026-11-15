import QtQuick
import qs.services
import qs.core
import qs.core.functions
import qs.widgets

QuickToggleModel {
    name: qsTr("Internet")
    statusText: Network.networkName
    tooltipText: qsTr("%1 | Right-click to configure").arg(Network.networkName)
    icon: Network.materialSymbol

    toggled: Network.wifiStatus !== "disabled"
    mainAction: () => Network.toggleWifi()
    hasMenu: true
}
