import QtQuick
import QtQuick.Layouts
import qs.services
import qs.core
import qs.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "sports_esports"
        title: qsTr("Game bar")

        ConfigSlider {
            text: qsTr("Background opacity")
            buttonIcon: "opacity"
            value: Config.options.gameBar.backgroundOpacity
            onValueChanged: Config.options.gameBar.backgroundOpacity = value
        }
        ContentSubsection {
            title: qsTr("MangoHud config file")
            MaterialTextField {
                Layout.fillWidth: true
                text: Config.options.gameBar.mangohudConfig
                onEditingFinished: Config.options.gameBar.mangohudConfig = text
            }
        }
        ContentSubsection {
            title: qsTr("FPS presets (comma separated)")
            MaterialTextField {
                Layout.fillWidth: true
                text: Config.options.gameBar.fpsPresets.join(", ")
                onEditingFinished: Config.options.gameBar.fpsPresets = text.split(",").map(v => parseInt(v.trim())).filter(v => v > 0)
            }
        }
    }

    ContentSection {
        icon: "videocam"
        title: qsTr("Recording")

        ContentSubsection {
            title: qsTr("Save recordings to")
            MaterialTextField {
                Layout.fillWidth: true
                text: Config.options.screenRecord.savePath
                onEditingFinished: Config.options.screenRecord.savePath = text
            }
        }
        ConfigSpinBox {
            icon: "replay"
            text: qsTr("Replay buffer length (seconds)")
            value: Config.options.gameBar.replaySeconds
            from: 10
            to: 600
            stepSize: 10
            onValueChanged: Config.options.gameBar.replaySeconds = value
        }
        ContentSubsection {
            title: qsTr("Save screenshots to (empty = clipboard only)")
            MaterialTextField {
                Layout.fillWidth: true
                text: Config.options.screenSnip.savePath
                onEditingFinished: Config.options.screenSnip.savePath = text
            }
        }
    }
}
