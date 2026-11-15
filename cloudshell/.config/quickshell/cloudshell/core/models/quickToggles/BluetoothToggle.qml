import QtQuick
import Quickshell.Bluetooth
import qs.services
import qs.core
import qs.core.functions
import qs.widgets

QuickToggleModel {
    name: qsTr("Bluetooth")
    statusText: BluetoothStatus.firstActiveDevice?.name ?? qsTr("Not connected")
    tooltipText: qsTr("%1 | Right-click to configure").arg(
        (BluetoothStatus.firstActiveDevice?.name ?? qsTr("Bluetooth"))
        + (BluetoothStatus.activeDeviceCount > 1 ? ` +${BluetoothStatus.activeDeviceCount - 1}` : "")
    )
    icon: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"

    available: BluetoothStatus.available
    toggled: BluetoothStatus.enabled
    mainAction: () => {
        Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter?.enabled
    }
    hasMenu: true
}
