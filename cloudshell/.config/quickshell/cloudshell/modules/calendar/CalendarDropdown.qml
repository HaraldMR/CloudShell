import qs
import qs.core
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

DropdownWindow {
    id: root
    open: GlobalStates.calendarOpen
    alignRight: false
    panelWidth: 360
    namespace: "cloudshell:calendar"
    onDismissed: GlobalStates.calendarOpen = false
    contentHeight: calendarColumn.implicitHeight

    ColumnLayout {
        id: calendarColumn
        anchors {
            left: parent.left
            right: parent.right
        }
        spacing: 4

        StyledText {
            Layout.leftMargin: 8
            Layout.topMargin: 2
            font.pixelSize: Appearance.font.pixelSize.title
            font.family: Appearance.font.family.title
            color: Appearance.colors.colOnLayer0
            text: Qt.locale().toString(DateTime.clock.date, "dddd d MMMM")
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: calendar.implicitHeight
            radius: Appearance.rounding.large
            color: Appearance.colors.colLayer1

            CalendarWidget {
                id: calendar
                anchors.horizontalCenter: parent.horizontalCenter
                focus: GlobalStates.calendarOpen
            }
        }
    }
}
