import qs
import qs.core
import qs.services
import qs.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.core.functions

/**
 * Cloudshell settings. Runs inside the shell (not a separate process) so it can show live
 * notification history. Open with the gear in the dropdown, `qs -c cloudshell ipc call settings open`,
 * or the old `qs -p .../settings.qml` command which forwards here.
 */
Scope {
    id: root

    readonly property list<var> pages: [
        { "id": "general", "name": qsTr("General"), "icon": "browse", "component": "GeneralPage.qml" },
        { "id": "dropdown", "name": qsTr("Quick settings"), "icon": "toggle_on", "component": "DropdownPage.qml" },
        { "id": "notifications", "name": qsTr("Notifications"), "icon": "notifications", "component": "NotificationsPage.qml" },
        { "id": "theme", "name": qsTr("Wallpaper & style"), "icon": "palette", "component": "ThemePage.qml" },
        { "id": "gameBar", "name": qsTr("Game bar"), "icon": "sports_esports", "component": "GameBarPage.qml" },
        { "id": "integrations", "name": qsTr("Integrations"), "icon": "extension", "component": "IntegrationsPage.qml" },
        { "id": "modules", "name": qsTr("Modules"), "icon": "widgets", "component": "ModulesPage.qml" }
    ]

    LazyLoader {
        active: GlobalStates.settingsOpen

        FloatingWindow {
            id: window
            property real contentPadding: 8
            property int currentPage: Math.max(0, root.pages.findIndex(p => p.id === GlobalStates.settingsPage))

            visible: true
            title: "Cloudshell Settings"
            minimumSize.width: 750
            minimumSize.height: 500
            implicitWidth: 1100
            implicitHeight: 760
            // The window itself is always transparent and the background is drawn below; a window that
            // opens solid has no alpha channel, so switching glass on later would render it grey/white.
            color: "transparent"
            BackgroundEffect.blurRegion: Appearance.glass ? fullRegion : null
            Region {
                id: fullRegion
                item: windowBackground
            }

            Rectangle {
                id: windowBackground
                anchors.fill: parent
                color: Appearance.glass ? "transparent" : Appearance.m3colors.m3background
            }
            onVisibleChanged: if (!visible)
                GlobalStates.settingsOpen = false

            Connections {
                target: GlobalStates
                function onSettingsPageChanged() {
                    const index = root.pages.findIndex(p => p.id === GlobalStates.settingsPage);
                    if (index >= 0)
                        window.currentPage = index;
                }
            }

            ColumnLayout {
                anchors {
                    fill: parent
                    margins: window.contentPadding
                }
                focus: true
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        GlobalStates.settingsOpen = false;
                        event.accepted = true;
                    } else if (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_PageDown) {
                        window.currentPage = Math.min(window.currentPage + 1, root.pages.length - 1);
                        event.accepted = true;
                    } else if (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_PageUp) {
                        window.currentPage = Math.max(window.currentPage - 1, 0);
                        event.accepted = true;
                    }
                }

                Item { // Titlebar
                    Layout.fillWidth: true
                    implicitHeight: Math.max(titleText.implicitHeight, closeButton.implicitHeight)
                    StyledText {
                        id: titleText
                        anchors.centerIn: parent
                        color: Appearance.colors.colOnLayer0
                        text: qsTr("Settings")
                        font {
                            family: Appearance.font.family.title
                            pixelSize: Appearance.font.pixelSize.title
                            variableAxes: Appearance.font.variableAxes.title
                        }
                    }
                    RippleButton {
                        id: closeButton
                        anchors {
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        buttonRadius: Appearance.rounding.full
                        implicitWidth: 35
                        implicitHeight: 35
                        onClicked: GlobalStates.settingsOpen = false
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            text: "close"
                            iconSize: 20
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: window.contentPadding

                    Item {
                        id: navRailWrapper
                        Layout.fillHeight: true
                        Layout.margins: 5
                        implicitWidth: navRail.expanded ? 190 : 56
                        Behavior on implicitWidth {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        NavigationRail {
                            id: navRail
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            spacing: 10
                            expanded: window.width > 900

                            NavigationRailExpandButton {}

                            NavigationRailTabArray {
                                currentIndex: window.currentPage
                                expanded: navRail.expanded
                                Repeater {
                                    model: root.pages
                                    NavigationRailButton {
                                        required property var index
                                        required property var modelData
                                        toggled: window.currentPage === index
                                        onPressed: window.currentPage = index
                                        expanded: navRail.expanded
                                        buttonIcon: modelData.icon
                                        buttonText: modelData.name
                                        showToggledHighlight: false
                                    }
                                }
                            }
                            Item {
                                Layout.fillHeight: true
                            }
                        }
                    }

                    Rectangle { // Content container
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: Appearance.glass ? ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainerLow, 0.5) : Appearance.m3colors.m3surfaceContainerLow
                        radius: Appearance.rounding.windowRounding - window.contentPadding

                        Loader {
                            id: pageLoader
                            anchors.fill: parent
                            active: Config.ready
                            source: root.pages[window.currentPage].component
                            opacity: 1
                            onSourceChanged: fadeIn.restart()
                            NumberAnimation {
                                id: fadeIn
                                target: pageLoader
                                property: "opacity"
                                from: 0
                                to: 1
                                duration: Appearance.animation.elementMoveFast.duration
                            }
                        }
                    }
                }
            }
        }
    }
}
