pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.core
import qs.widgets
import qs.core.functions
import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: root
    required property Component contentComponent
    
    Loader {
        active: PolkitService.active
        sourceComponent: Variants {
            model: Quickshell.screens
            delegate: PanelWindow {
                id: panelWindow
                required property var modelData
                screen: modelData
                
                anchors {
                    top: true
                    left: true
                    right: true
                    bottom: true
                }

                color: "transparent"
                WlrLayershell.namespace: "quickshell:polkit"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
                WlrLayershell.layer: WlrLayer.Overlay
                exclusionMode: ExclusionMode.Ignore
                BackgroundEffect.blurRegion: Appearance.glass ? fullRegion : null
                Region {
                    id: fullRegion
                    item: contentLoader
                }

                Loader {
                    id: contentLoader
                    anchors.fill: parent
                    sourceComponent: root.contentComponent
                }
            }
        }
    }
}
