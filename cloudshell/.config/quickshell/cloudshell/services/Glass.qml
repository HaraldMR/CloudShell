pragma Singleton
pragma ComponentBehavior: Bound

import qs.core
import QtQuick
import Quickshell
import Quickshell.Hyprland

/**
 * Applies the liquid glass blur strength (appearance.glass.blur) to Hyprland's blur settings.
 * Glass panels are fully clear, so this is what decides how frosted they look.
 * Re-applied after every Hyprland config reload; turning glass off reloads Hyprland's own values.
 */
Singleton {
    id: root
    readonly property bool enabled: Appearance.glass
    readonly property real strength: Math.max(0, Math.min(1, Config.options.appearance.glass.blur ?? 0.5))

    // Squared, so the clear end of the slider has fine steps: 0 -> size 1 / 1 pass (almost none),
    // 1 -> size 16 / 5 passes (heavy frost)
    readonly property int size: Math.max(1, Math.round(1 + root.strength * root.strength * 15))
    readonly property int passes: Math.max(1, Math.round(1 + root.strength * 4))

    function apply() {
        if (root.enabled) {
            Quickshell.execDetached(["hyprctl", "eval", `hl.config({ decoration = { blur = { size = ${root.size}, passes = ${root.passes} } } })`]);
            Persistent.states.glass.applied = true;
        } else if (Persistent.states.glass.applied) {
            // Our values may still be live in Hyprland (also after a shell restart): reload its own
            Persistent.states.glass.applied = false;
            Quickshell.execDetached(["hyprctl", "reload"]);
        }
    }

    // Debounce slider drags
    Timer {
        id: applyTimer
        interval: 120
        onTriggered: root.apply()
    }
    onStrengthChanged: if (ready)
        applyTimer.restart()
    onEnabledChanged: if (ready)
        applyTimer.restart()

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded" && root.enabled)
                applyTimer.restart();
        }
    }

    readonly property bool ready: Config.ready && Persistent.ready
    onReadyChanged: if (ready)
        applyTimer.restart()
    Component.onCompleted: if (ready)
        applyTimer.restart()
}
