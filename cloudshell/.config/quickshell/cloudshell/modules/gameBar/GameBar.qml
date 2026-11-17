pragma ComponentBehavior: Bound
import qs
import qs.core
import qs.services
import qs.widgets
import qs.core.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Game bar (Super+G): MangoHud FPS limit + screenshots/recording in one small,
 * see-through panel in the top-left corner. Doesn't darken or block the game.
 */
Scope {
    id: root
    readonly property bool hasMangohud: Deps.has("mangohud")
    readonly property bool hasRecorder: Deps.has("gpu-screen-recorder")
    readonly property bool hasScreenshot: Deps.has("grim") && Deps.has("wl-copy")
    readonly property string mangohudConfig: Deps.expand(Config.options.gameBar.mangohudConfig)
    property int currentFpsLimit: 0
    property string recorderStatus: "idle" // idle | recording | replay | both
    readonly property bool recording: recorderStatus === "recording" || recorderStatus === "both"
    readonly property bool replayRunning: recorderStatus === "replay" || recorderStatus === "both"

    function close() {
        GlobalStates.gameBarOpen = false;
    }

    function setFpsLimit(fps) {
        const path = StringUtils.shellSingleQuoteEscape(root.mangohudConfig);
        const cmd = `mkdir -p "$(dirname '${path}')"; touch '${path}'; ` + `if grep -q '^fps_limit=' '${path}'; then sed -i 's/^fps_limit=.*/fps_limit=${fps}/' '${path}'; ` + `else echo 'fps_limit=${fps}' >> '${path}'; fi`;
        Quickshell.execDetached(["bash", "-c", cmd]);
        root.currentFpsLimit = fps;
    }

    function record(args) {
        Quickshell.execDetached([Directories.recordScriptPath, ...args]);
        statusDelay.restart();
    }

    Process {
        id: readFpsProc
        command: ["bash", "-c", `grep -m1 '^fps_limit=' '${StringUtils.shellSingleQuoteEscape(root.mangohudConfig)}' 2>/dev/null | cut -d= -f2 | cut -d, -f1`]
        stdout: StdioCollector {
            onStreamFinished: root.currentFpsLimit = parseInt(this.text) || 0
        }
    }

    Process {
        id: statusProc
        command: [Directories.recordScriptPath, "--status"]
        stdout: StdioCollector {
            onStreamFinished: root.recorderStatus = this.text.trim() || "idle"
        }
    }
    Timer {
        id: statusDelay
        interval: 800
        onTriggered: statusProc.running = true
    }

    Connections {
        target: GlobalStates
        function onGameBarOpenChanged() {
            if (!GlobalStates.gameBarOpen)
                return;
            if (root.hasMangohud)
                readFpsProc.running = true;
            statusProc.running = true;
        }
    }

    PanelWindow {
        id: window
        visible: GlobalStates.gameBarOpen || panel.opacity > 0
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.namespace: "cloudshell:gameBar"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: GlobalStates.gameBarOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        anchors {
            top: true
            left: true
        }
        margins {
            top: 16
            left: 16
        }
        implicitWidth: panel.implicitWidth
        implicitHeight: panel.implicitHeight
        BackgroundEffect.blurRegion: Appearance.glass ? glassRegion : null
        Region {
            id: glassRegion
            item: panel
            radius: panel.radius
        }

        Rectangle {
            id: panel
            implicitWidth: 360
            implicitHeight: content.implicitHeight + 28
            radius: Appearance.rounding.verylarge
            color: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainer, 1 - Config.options.gameBar.backgroundOpacity)
            border.width: Appearance.glass ? 0 : 1
            border.color: ColorUtils.transparentize(Appearance.m3colors.m3outlineVariant, 0.5)

            GlassRim {
                radius: panel.radius
            }

            opacity: GlobalStates.gameBarOpen ? 1 : 0
            scale: GlobalStates.gameBarOpen ? 1 : 0.95
            transformOrigin: Item.TopLeft
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            Behavior on scale {
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
            }

            focus: GlobalStates.gameBarOpen
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.close();
                    event.accepted = true;
                }
            }

            ColumnLayout {
                id: content
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 14
                }
                spacing: 12

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    MaterialSymbol {
                        text: "sports_esports"
                        iconSize: Appearance.font.pixelSize.huge
                        color: Appearance.colors.colPrimary
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: qsTr("Game bar")
                        font.pixelSize: Appearance.font.pixelSize.large
                        font.family: Appearance.font.family.title
                        color: Appearance.colors.colOnLayer0
                    }
                    RecorderIndicator {
                        visible: root.recording
                        label: qsTr("REC")
                    }
                    RecorderIndicator {
                        visible: root.replayRunning
                        label: qsTr("Replay")
                    }
                    SmallIconButton {
                        iconName: "close"
                        onClicked: root.close()
                    }
                }

                // FPS limit
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.hasMangohud
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        StyledText {
                            Layout.fillWidth: true
                            text: qsTr("FPS limit")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnLayer0
                        }
                        StyledText {
                            text: root.currentFpsLimit > 0 ? qsTr("%1 fps").arg(root.currentFpsLimit) : qsTr("Unlimited")
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        Repeater {
                            model: [0, ...Config.options.gameBar.fpsPresets]
                            Chip {
                                required property int modelData
                                text: modelData === 0 ? qsTr("Off") : `${modelData}`
                                toggled: root.currentFpsLimit === modelData
                                onClicked: root.setFpsLimit(modelData)
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        ToolbarTextField {
                            id: fpsField
                            Layout.fillWidth: true
                            implicitHeight: 36
                            placeholderText: qsTr("Custom FPS")
                            inputMethodHints: Qt.ImhDigitsOnly
                            validator: IntValidator {
                                bottom: 0
                                top: 1000
                            }
                            onAccepted: applyCustom.clicked()
                        }
                        SmallIconButton {
                            id: applyCustom
                            iconName: "check"
                            enabled: fpsField.text.length > 0
                            onClicked: {
                                root.setFpsLimit(parseInt(fpsField.text) || 0);
                                fpsField.text = "";
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    visible: root.hasMangohud && (root.hasRecorder || root.hasScreenshot)
                    color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.4)
                }

                // Capture
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.hasRecorder || root.hasScreenshot
                    spacing: 8

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8

                        BigButton {
                            visible: root.hasScreenshot
                            materialSymbol: "screenshot_region"
                            name: qsTr("Screenshot region")
                            onClicked: {
                                root.close();
                                Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "screenshot"]);
                            }
                        }
                        BigButton {
                            visible: root.hasScreenshot
                            materialSymbol: "photo_camera"
                            name: qsTr("Screenshot")
                            onClicked: {
                                root.close();
                                Quickshell.execDetached(["bash", "-c", `sleep 0.3; grim -o "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')" - | wl-copy`]);
                            }
                        }
                        BigButton {
                            visible: root.hasRecorder
                            materialSymbol: "screen_record"
                            name: qsTr("Record region")
                            onClicked: {
                                root.close();
                                Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "recordWithSound"]);
                            }
                        }
                        BigButton {
                            visible: root.hasRecorder
                            materialSymbol: root.recording ? "stop_circle" : "capture"
                            name: root.recording ? qsTr("Stop recording") : qsTr("Record screen")
                            toggled: root.recording
                            onClicked: {
                                if (root.recording) {
                                    root.record(["--stop"]);
                                } else {
                                    root.close();
                                    root.record(["--fullscreen", "--sound"]);
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: root.hasRecorder
                        spacing: 6
                        Chip {
                            Layout.fillWidth: true
                            iconName: "replay"
                            text: root.replayRunning ? qsTr("Replay on") : qsTr("Replay buffer")
                            toggled: root.replayRunning
                            onClicked: root.record([root.replayRunning ? "--replay-stop" : "--replay-start", "--sound"])
                        }
                        Chip {
                            Layout.fillWidth: true
                            iconName: "save"
                            enabled: root.replayRunning
                            text: qsTr("Save last %1s").arg(Config.options.gameBar.replaySeconds)
                            onClicked: root.record(["--replay-save"])
                        }
                    }

                    Chip {
                        Layout.fillWidth: true
                        iconName: "folder_open"
                        text: qsTr("Open recordings")
                        onClicked: {
                            root.close();
                            Qt.openUrlExternally(`file://${Config.options.screenRecord.savePath}`);
                        }
                    }
                }
            }
        }
    }

    component Chip: RippleButton {
        id: chip
        property string iconName: ""
        implicitHeight: 34
        implicitWidth: chipRow.implicitWidth + 24
        buttonRadius: Appearance.rounding.full
        colBackground: ColorUtils.transparentize(Appearance.colors.colLayer2, 0.3)
        colBackgroundHover: Appearance.colors.colLayer2Hover
        colRipple: Appearance.colors.colLayer2Active
        opacity: enabled ? 1 : 0.5
        contentItem: Item {
            RowLayout {
                id: chipRow
                anchors.centerIn: parent
                spacing: 6
                MaterialSymbol {
                    visible: chip.iconName.length > 0
                    text: chip.iconName
                    iconSize: Appearance.font.pixelSize.large
                    color: chip.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
                }
                StyledText {
                    text: chip.text
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: chip.toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
                }
            }
        }
    }

    component SmallIconButton: RippleButton {
        id: smallButton
        property string iconName
        implicitWidth: 34
        implicitHeight: 34
        buttonRadius: Appearance.rounding.full
        colBackground: ColorUtils.transparentize(Appearance.colors.colLayer2, 0.3)
        colBackgroundHover: Appearance.colors.colLayer2Hover
        colRipple: Appearance.colors.colLayer2Active
        opacity: enabled ? 1 : 0.5
        contentItem: MaterialSymbol {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            text: smallButton.iconName
            iconSize: Appearance.font.pixelSize.larger
            color: Appearance.colors.colOnLayer2
        }
    }

    component BigButton: RippleButton {
        id: bigButton
        required property string materialSymbol
        required property string name
        implicitHeight: 62
        implicitWidth: 62
        buttonRadius: toggled ? Appearance.rounding.large : height / 2
        colBackground: ColorUtils.transparentize(Appearance.colors.colLayer2, 0.3)
        colBackgroundHover: Appearance.colors.colLayer2Hover
        colRipple: Appearance.colors.colLayer2Active
        colBackgroundToggled: Appearance.colors.colError
        colBackgroundToggledHover: Appearance.colors.colErrorHover
        contentItem: MaterialSymbol {
            anchors.centerIn: parent
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: bigButton.materialSymbol
            iconSize: 26
            color: bigButton.toggled ? Appearance.colors.colOnError : Appearance.colors.colOnLayer2
        }
        StyledToolTip {
            text: bigButton.name
        }
    }

    component RecorderIndicator: Rectangle {
        id: indicator
        property string label
        implicitWidth: indicatorRow.implicitWidth + 14
        implicitHeight: 24
        radius: height / 2
        color: Appearance.colors.colErrorContainer
        RowLayout {
            id: indicatorRow
            anchors.centerIn: parent
            spacing: 4
            Rectangle {
                implicitWidth: 8
                implicitHeight: 8
                radius: 4
                color: Appearance.colors.colError
            }
            StyledText {
                text: indicator.label
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colOnErrorContainer
            }
        }
    }
}
