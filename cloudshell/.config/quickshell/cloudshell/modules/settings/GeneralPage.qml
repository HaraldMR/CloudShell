import QtQuick
import QtQuick.Layouts
import qs.services
import qs.core
import qs.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "toolbar"
        title: qsTr("Top bar")

        ConfigSwitch {
            buttonIcon: "rounded_corner"
            text: qsTr("Pill backgrounds")
            checked: Config.options.bar.pills.enable
            onCheckedChanged: Config.options.bar.pills.enable = checked
        }
        ColumnLayout {
            Layout.fillWidth: true
            visible: Config.options.bar.pills.enable
            spacing: 4

            Flow {
                Layout.fillWidth: true
                Layout.leftMargin: 40
                spacing: 6
                Repeater {
                    model: [
                        { "key": "clock", "label": qsTr("Clock"), "icon": "schedule" },
                        { "key": "media", "label": qsTr("Media"), "icon": "music_note" },
                        { "key": "workspaces", "label": qsTr("Workspaces"), "icon": "workspaces" },
                        { "key": "status", "label": qsTr("Tray & status"), "icon": "wifi" }
                    ]
                    delegate: RippleButton {
                        id: pillChip
                        required property var modelData
                        toggled: Config.options.bar.pills[modelData.key]
                        onClicked: Config.options.bar.pills[modelData.key] = !toggled
                        implicitHeight: 34
                        implicitWidth: pillChipRow.implicitWidth + 24
                        buttonRadius: Appearance.rounding.full
                        colBackground: Appearance.colors.colLayer2
                        colBackgroundHover: Appearance.colors.colLayer2Hover
                        colBackgroundToggled: Appearance.colors.colSecondaryContainer
                        colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                        contentItem: Item {
                            RowLayout {
                                id: pillChipRow
                                anchors.centerIn: parent
                                spacing: 6
                                MaterialSymbol {
                                    text: pillChip.toggled ? "check" : pillChip.modelData.icon
                                    iconSize: Appearance.font.pixelSize.large
                                    color: pillChip.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer2
                                }
                                StyledText {
                                    text: pillChip.modelData.label
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: pillChip.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer2
                                }
                            }
                        }
                    }
                }
            }
            ContentSubsection {
                title: qsTr("Colour")
                ConfigSelectionArray {
                    currentValue: Config.options.bar.pills.style
                    onSelected: newValue => Config.options.bar.pills.style = newValue
                    options: [
                        { "displayName": qsTr("Surface"), "icon": "rectangle", "value": "surface" },
                        { "displayName": qsTr("Tonal"), "icon": "tonality", "value": "tonal" },
                        { "displayName": qsTr("Accent"), "icon": "palette", "value": "primary" }
                    ]
                }
            }
            ConfigSlider {
                buttonIcon: "opacity"
                text: qsTr("Opacity")
                value: Config.options.bar.pills.opacity
                from: 0.1
                to: 1
                onValueChanged: Config.options.bar.pills.opacity = Math.round(value * 100) / 100
            }
            ConfigSwitch {
                buttonIcon: "border_style"
                text: qsTr("Outline (not used with liquid glass)")
                checked: Config.options.bar.pills.outline
                onCheckedChanged: Config.options.bar.pills.outline = checked
            }
        }
    }

    ContentSection {
        icon: "workspaces"
        title: qsTr("Workspaces")

        ConfigSpinBox {
            icon: "view_column"
            text: qsTr("Workspaces shown")
            value: Config.options.bar.workspaces.shown
            from: 1
            to: 30
            stepSize: 1
            onValueChanged: Config.options.bar.workspaces.shown = value
        }
        ConfigSwitch {
            buttonIcon: "award_star"
            text: qsTr("Show app icons")
            checked: Config.options.bar.workspaces.showAppIcons
            onCheckedChanged: Config.options.bar.workspaces.showAppIcons = checked
        }
        ConfigSwitch {
            buttonIcon: "counter_1"
            text: qsTr("Always show numbers")
            checked: Config.options.bar.workspaces.alwaysShowNumbers
            onCheckedChanged: Config.options.bar.workspaces.alwaysShowNumbers = checked
        }
    }

    ContentSection {
        icon: "overview_key"
        title: qsTr("Overview")

        ConfigSwitch {
            buttonIcon: "check"
            text: qsTr("Show workspace overview in the Super window")
            checked: Config.options.overview.enable
            onCheckedChanged: Config.options.overview.enable = checked
        }
        ConfigSwitch {
            buttonIcon: "center_focus_strong"
            text: qsTr("Center icons")
            checked: Config.options.overview.centerIcons
            onCheckedChanged: Config.options.overview.centerIcons = checked
        }
        ConfigSpinBox {
            icon: "loupe"
            text: qsTr("Scale (%)")
            value: Config.options.overview.scale * 100
            from: 1
            to: 100
            stepSize: 1
            onValueChanged: Config.options.overview.scale = value / 100
        }
        ConfigRow {
            uniform: true
            ConfigSpinBox {
                icon: "splitscreen_bottom"
                text: qsTr("Rows")
                value: Config.options.overview.rows
                from: 1
                to: 20
                stepSize: 1
                onValueChanged: Config.options.overview.rows = value
            }
            ConfigSpinBox {
                icon: "splitscreen_right"
                text: qsTr("Columns")
                value: Config.options.overview.columns
                from: 1
                to: 20
                stepSize: 1
                onValueChanged: Config.options.overview.columns = value
            }
        }
        ConfigRow {
            uniform: true
            ConfigSelectionArray {
                currentValue: Config.options.overview.orderRightLeft
                onSelected: newValue => Config.options.overview.orderRightLeft = newValue
                options: [
                    { "displayName": qsTr("Left to right"), "icon": "arrow_forward", "value": false },
                    { "displayName": qsTr("Right to left"), "icon": "arrow_back", "value": true }
                ]
            }
            ConfigSelectionArray {
                currentValue: Config.options.overview.orderBottomUp
                onSelected: newValue => Config.options.overview.orderBottomUp = newValue
                options: [
                    { "displayName": qsTr("Top-down"), "icon": "arrow_downward", "value": false },
                    { "displayName": qsTr("Bottom-up"), "icon": "arrow_upward", "value": true }
                ]
            }
        }
    }

    ContentSection {
        icon: "schedule"
        title: qsTr("Clock")

        ContentSubsection {
            title: qsTr("Time format")
            ConfigSelectionArray {
                currentValue: Config.options.time.format
                onSelected: newValue => Config.options.time.format = newValue
                options: [
                    { "displayName": qsTr("24h"), "icon": "schedule", "value": "hh:mm" },
                    { "displayName": qsTr("12h"), "icon": "nest_clock_farsight_analog", "value": "h:mm AP" }
                ]
            }
        }
        ConfigSwitch {
            buttonIcon: "calendar_today"
            text: qsTr("Show date next to the clock")
            checked: Config.options.bar.verbose
            onCheckedChanged: Config.options.bar.verbose = checked
        }
    }

    ContentSection {
        icon: "lock"
        title: qsTr("Lock screen")

        ConfigSwitch {
            buttonIcon: "login"
            text: qsTr("Lock right after logging in (hyprlock)")
            checked: Config.options.lock.launchOnStartup
            onCheckedChanged: Config.options.lock.launchOnStartup = checked
        }
    }
}
