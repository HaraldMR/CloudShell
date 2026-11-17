import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell
import qs
import qs.services
import qs.core
import qs.widgets
import qs.core.functions

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "wallpaper"
        title: qsTr("Wallpaper")

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            MaterialSymbol {
                text: Wallpaper.daemonRunning ? "check_circle" : "info"
                iconSize: Appearance.font.pixelSize.larger
                color: Wallpaper.daemonRunning ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
            }
            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                color: Appearance.colors.colOnLayer1
                text: Wallpaper.daemonRunning ? qsTr("skwd-wall is drawing the wallpaper.") : Wallpaper.available ? qsTr("skwd-wall is installed but its daemon isn't running, so cloudshell draws the image below. Start it with: systemctl --user enable --now skwd-walld") : qsTr("skwd-wall isn't installed, so cloudshell draws the image below.")
            }
        }

        RowLayout {
            Layout.fillWidth: true
            visible: Wallpaper.available
            RippleButtonWithIcon {
                materialIcon: "wallpaper"
                mainText: qsTr("Open wallpaper selector")
                onClicked: {
                    GlobalStates.settingsOpen = false;
                    Wallpaper.openSelector();
                }
            }
            RippleButtonWithIcon {
                enabled: Wallpaper.daemonRunning
                materialIcon: "shuffle"
                mainText: qsTr("Random wallpaper")
                onClicked: Wallpaper.random()
            }
        }

        ContentSubsection {
            title: qsTr("Set from an image file")
            RowLayout {
                Layout.fillWidth: true
                MaterialTextField {
                    id: wallpaperField
                    Layout.fillWidth: true
                    placeholderText: "~/Pictures/Wallpapers/example.jpg"
                    text: Config.options.theme.fallbackWallpaper
                    onAccepted: Wallpaper.setWallpaper(text)
                }
                RippleButtonWithIcon {
                    materialIcon: "folder_open"
                    mainText: qsTr("Browse")
                    onClicked: fileDialog.open()
                }
                RippleButtonWithIcon {
                    enabled: wallpaperField.text.trim().length > 0
                    materialIcon: "check"
                    mainText: qsTr("Apply")
                    onClicked: Wallpaper.setWallpaper(wallpaperField.text)
                }
            }
        }

        FileDialog {
            id: fileDialog
            title: qsTr("Choose wallpaper")
            currentFolder: `file://${Directories.pictures.replace("file://", "")}/Wallpapers`
            nameFilters: [qsTr("Images (*.jpg *.jpeg *.png *.webp *.bmp)")]
            onAccepted: {
                const path = FileUtils.trimFileProtocol(decodeURIComponent(selectedFile.toString()));
                wallpaperField.text = path;
                Wallpaper.setWallpaper(path);
            }
        }
    }

    ContentSection {
        icon: "blur_on"
        title: qsTr("Liquid glass")

        ConfigSwitch {
            buttonIcon: "blur_on"
            text: qsTr("See-through, blurred panels with a light edge")
            checked: Config.options.appearance.glass.enable
            onCheckedChanged: Config.options.appearance.glass.enable = checked
        }
        ConfigSlider {
            visible: Config.options.appearance.glass.enable
            buttonIcon: "opacity"
            text: qsTr("Transparency")
            // Left = more tinted, right = clearer
            value: 1 - Config.options.appearance.glass.opacity
            from: 0.05
            to: 0.95
            onValueChanged: Config.options.appearance.glass.opacity = Math.round((1 - value) * 100) / 100
        }
    }

    ContentSection {
        icon: "palette"
        title: qsTr("Colours")

        ContentSubsection {
            title: qsTr("Mode")
            ConfigSelectionArray {
                currentValue: Config.options.theme.mode
                onSelected: newValue => Theme.setMode(newValue)
                options: [
                    { "displayName": qsTr("Dark"), "icon": "dark_mode", "value": "dark" },
                    { "displayName": qsTr("Light"), "icon": "light_mode", "value": "light" }
                ]
            }
        }
        ContentSubsection {
            title: qsTr("Palette style")
            tooltip: qsTr("Material You scheme used to turn the wallpaper into colours")
            ConfigSelectionArray {
                currentValue: Config.options.theme.scheme
                onSelected: newValue => {
                    Config.options.theme.scheme = newValue;
                    Theme.regenerate();
                }
                options: [
                    { "displayName": qsTr("Content"), "icon": "image", "value": "scheme-content" },
                    { "displayName": qsTr("Tonal spot"), "icon": "palette", "value": "scheme-tonal-spot" },
                    { "displayName": qsTr("Expressive"), "icon": "celebration", "value": "scheme-expressive" },
                    { "displayName": qsTr("Vibrant"), "icon": "colors", "value": "scheme-vibrant" },
                    { "displayName": qsTr("Fidelity"), "icon": "center_focus_strong", "value": "scheme-fidelity" },
                    { "displayName": qsTr("Neutral"), "icon": "contrast", "value": "scheme-neutral" },
                    { "displayName": qsTr("Monochrome"), "icon": "filter_b_and_w", "value": "scheme-monochrome" },
                    { "displayName": qsTr("Rainbow"), "icon": "looks", "value": "scheme-rainbow" },
                    { "displayName": qsTr("Fruit salad"), "icon": "nutrition", "value": "scheme-fruit-salad" }
                ]
            }
        }
        RowLayout {
            Layout.fillWidth: true
            RippleButtonWithIcon {
                enabled: Theme.canGenerate
                materialIcon: "refresh"
                mainText: qsTr("Regenerate colours now")
                onClicked: Theme.regenerate()
            }
            StyledText {
                visible: !Theme.canGenerate
                color: Appearance.colors.colSubtext
                text: qsTr("matugen isn't installed")
            }
        }
    }
}
