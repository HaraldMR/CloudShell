pragma ComponentBehavior: Bound

import qs.widgets
import qs.services
import QtQuick
import Quickshell

StyledListView { // Scrollable window
    id: root
    property bool popup: false
    // "alerting" or "silent" (ignored for popups)
    property string section: "alerting"

    spacing: 3

    model: ScriptModel {
        values: root.popup ? Notifications.popupAppNameList : (root.section === "silent" ? Notifications.silentAppNameList : Notifications.appNameList)
    }
    delegate: NotificationGroup {
        required property int index
        required property var modelData
        popup: root.popup
        width: ListView.view.width // https://doc.qt.io/qt-6/qml-qtquick-listview.html
        notificationGroup: root.popup ? Notifications.popupGroupsByAppName[modelData] : (root.section === "silent" ? Notifications.silentGroupsByAppName[modelData] : Notifications.groupsByAppName[modelData])
    }
}
