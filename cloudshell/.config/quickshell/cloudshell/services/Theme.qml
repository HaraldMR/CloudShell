pragma Singleton
pragma ComponentBehavior: Bound

import qs.core
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * Loads the Material 3 palette that matugen writes to ~/.local/state/cloudshell/colors.json
 * and reloads it live. Without that file the built-in defaults in Appearance are used.
 */
Singleton {
    id: root
    property string filePath: Directories.generatedMaterialThemePath
    readonly property bool canGenerate: Deps.has("matugen")

    function load() {
        themeFileView.reload();
    }

    function applyColors(fileContent) {
        if (!fileContent || fileContent.length === 0)
            return;
        let json;
        try {
            json = JSON.parse(fileContent);
        } catch (e) {
            console.warn("[Theme] Invalid colors.json:", e);
            return;
        }
        for (const key in json) {
            if (!json.hasOwnProperty(key))
                continue;
            const camelCaseKey = key.replace(/_([a-z])/g, g => g[1].toUpperCase());
            const m3Key = `m3${camelCaseKey}`;
            if (Appearance.m3colors.hasOwnProperty(m3Key))
                Appearance.m3colors[m3Key] = json[key];
        }
        Appearance.m3colors.darkmode = (Appearance.m3colors.m3background.hslLightness < 0.5);
    }

    // Regenerate with matugen (used for light/dark switching and when skwd-wall isn't installed)
    // image: optional; by default the current skwd-wall wallpaper, else theme.fallbackWallpaper
    function regenerate(image) {
        if (!root.canGenerate)
            return;
        const args = [Directories.themeScriptPath, "--mode", Config.options.theme.mode, "--type", Config.options.theme.scheme];
        if (image)
            args.push("--image", image);
        Quickshell.execDetached(args);
    }

    function setMode(mode) {
        Config.options.theme.mode = mode;
        root.regenerate();
    }

    function toggleLightDark() {
        root.setMode(Appearance.m3colors.darkmode ? "light" : "dark");
    }

    Timer {
        id: delayedFileRead
        interval: Config.options?.hacks?.arbitraryRaceConditionDelay ?? 100
        repeat: false
        onTriggered: root.applyColors(themeFileView.text())
    }

    FileView {
        id: themeFileView
        path: Qt.resolvedUrl(root.filePath)
        watchChanges: true
        printErrors: false
        onFileChanged: {
            this.reload();
            delayedFileRead.start();
        }
        onLoadedChanged: root.applyColors(themeFileView.text())
    }

    GlobalShortcut {
        name: "toggleLightDark"
        description: "Toggles between dark theme and light theme"
        onPressed: root.toggleLightDark()
    }

    IpcHandler {
        target: "theme"

        function toggleLightDark(): void {
            root.toggleLightDark();
        }
        function reload(): void {
            root.load();
        }
        function regenerate(): void {
            root.regenerate();
        }
    }
}
