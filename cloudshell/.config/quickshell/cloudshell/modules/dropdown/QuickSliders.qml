import qs
import qs.services
import qs.core
import qs.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Rectangle {
    id: root

    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    readonly property bool showBrightness: Config.options.dropdown.sections.brightness && (brightnessMonitor?.ready ?? false)
    readonly property bool showVolume: Config.options.dropdown.sections.volume
    readonly property bool showMic: Config.options.dropdown.sections.mic
    readonly property bool hasContent: showBrightness || showVolume || showMic
    signal openAudioOutputDialog
    signal openAudioInputDialog

    implicitWidth: contentItem.implicitWidth + root.horizontalPadding * 2
    implicitHeight: contentItem.implicitHeight + root.verticalPadding * 2
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1
    property real verticalPadding: 4
    property real horizontalPadding: 12

    Column {
        id: contentItem
        anchors {
            fill: parent
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
            topMargin: root.verticalPadding
            bottomMargin: root.verticalPadding
        }

        Loader {
            anchors {
                left: parent.left
                right: parent.right
            }
            visible: active
            active: root.showVolume
            sourceComponent: SliderRow {
                materialSymbol: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"
                value: Audio.sink?.audio?.volume ?? 0
                onMoved: value => Audio.sink.audio.volume = value
                onMenuRequested: root.openAudioOutputDialog()
            }
        }

        Loader {
            anchors {
                left: parent.left
                right: parent.right
            }
            visible: active
            active: root.showMic
            sourceComponent: SliderRow {
                materialSymbol: Audio.source?.audio?.muted ? "mic_off" : "mic"
                value: Audio.source?.audio?.volume ?? 0
                onMoved: value => Audio.source.audio.volume = value
                onMenuRequested: root.openAudioInputDialog()
            }
        }

        Loader {
            anchors {
                left: parent.left
                right: parent.right
            }
            visible: active
            active: root.showBrightness
            sourceComponent: SliderRow {
                materialSymbol: "light_mode"
                showMenuButton: false
                value: root.brightnessMonitor?.brightness ?? 0
                onMoved: value => root.brightnessMonitor.setBrightness(value)
            }
        }
    }

    component SliderRow: RowLayout {
        id: sliderRow
        required property string materialSymbol
        property real value
        property bool showMenuButton: true
        signal moved(real value)
        signal menuRequested
        spacing: 4

        QuickSlider {
            Layout.fillWidth: true
            materialSymbol: sliderRow.materialSymbol
            value: sliderRow.value
            onMoved: sliderRow.moved(value)
        }
        RippleButton {
            visible: sliderRow.showMenuButton
            implicitWidth: 32
            implicitHeight: 32
            buttonRadius: Appearance.rounding.full
            onClicked: sliderRow.menuRequested()
            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                text: "chevron_right"
                iconSize: 20
                color: Appearance.colors.colOnLayer1
            }
        }
    }

    component QuickSlider: StyledSlider {
        id: quickSlider
        required property string materialSymbol
        configuration: StyledSlider.Configuration.M
        stopIndicatorValues: []

        MaterialSymbol {
            id: icon
            property bool nearFull: quickSlider.value >= 0.9
            anchors {
                verticalCenter: quickSlider.verticalCenter
                right: nearFull ? quickSlider.handle.right : quickSlider.right
                rightMargin: nearFull ? 14 : 8
            }
            iconSize: 20
            color: nearFull ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
            text: quickSlider.materialSymbol

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
            Behavior on anchors.rightMargin {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }
    }
}
