import QtQuick
import QtQuick.Layouts
import qs.services
import qs.core
import qs.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "view_agenda"
        title: qsTr("Sections")

        ConfigSwitch {
            buttonIcon: "volume_up"
            text: qsTr("Volume slider")
            checked: Config.options.dropdown.sections.volume
            onCheckedChanged: Config.options.dropdown.sections.volume = checked
        }
        ConfigSwitch {
            buttonIcon: "mic"
            text: qsTr("Microphone slider")
            checked: Config.options.dropdown.sections.mic
            onCheckedChanged: Config.options.dropdown.sections.mic = checked
        }
        ConfigSwitch {
            buttonIcon: "light_mode"
            text: qsTr("Brightness slider (hidden when the monitor doesn't support it)")
            checked: Config.options.dropdown.sections.brightness
            onCheckedChanged: Config.options.dropdown.sections.brightness = checked
        }
        ConfigSwitch {
            buttonIcon: "monitoring"
            text: qsTr("CPU / RAM / disk usage")
            checked: Config.options.dropdown.sections.stats
            onCheckedChanged: Config.options.dropdown.sections.stats = checked
        }
        ConfigSwitch {
            buttonIcon: "notifications"
            text: qsTr("Notifications")
            checked: Config.options.dropdown.sections.notifications
            onCheckedChanged: Config.options.dropdown.sections.notifications = checked
        }
    }

    ContentSection {
        icon: "toggle_on"
        title: qsTr("Quick toggles")

        NoticeBox {
            Layout.fillWidth: true
            text: qsTr("Edit the toggles with the pencil button in the dropdown: click to add or remove, right-click to resize, scroll to move.")
        }
        ConfigSpinBox {
            icon: "view_column"
            text: qsTr("Columns")
            value: Config.options.dropdown.columns
            from: 2
            to: 6
            stepSize: 1
            onValueChanged: Config.options.dropdown.columns = value
        }
    }
}
