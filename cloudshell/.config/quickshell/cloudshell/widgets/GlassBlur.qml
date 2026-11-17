import QtQuick
import Quickshell

/**
 * Builds a blur region (for a window's BackgroundEffect.blurRegion) from a list of surfaces.
 * Each item's `radius` rounds its part of the region. Items that aren't visible are skipped.
 *
 *   BackgroundEffect.blurRegion: Appearance.glass ? glassBlur.region : null
 *   GlassBlur { id: glassBlur; items: [card1, card2] }
 *
 * Region's own `item` property places the region by the item's position inside its parent, which
 * is wrong for nested items, so the position in the window is computed here and kept up to date
 * when the item or any of its parents move or resize.
 */
QtObject {
    id: root
    property list<Item> items: []

    readonly property Region region: Region {
        regions: {
            const result = [];
            for (let i = 0; i < instantiator.count; i++) {
                const region = instantiator.objectAt(i);
                if (region)
                    result.push(region);
            }
            return result;
        }
    }

    property Instantiator instantiator: Instantiator {
        id: instantiator
        model: root.items
        delegate: Region {
            id: region
            required property Item modelData
            radius: modelData?.radius ?? 0

            property var watched: []

            function update() {
                const item = region.modelData;
                if (!item || !item.visible || !item.parent) {
                    region.width = 0;
                    region.height = 0;
                    return;
                }
                const pos = item.mapToItem(null, 0, 0);
                region.x = Math.round(pos.x);
                region.y = Math.round(pos.y);
                region.width = Math.round(item.width);
                region.height = Math.round(item.height);
            }

            function watch() {
                for (const w of region.watched) {
                    w.xChanged.disconnect(region.update);
                    w.yChanged.disconnect(region.update);
                    w.parentChanged.disconnect(region.watch);
                }
                const list = [];
                for (let it = region.modelData; it; it = it.parent) {
                    it.xChanged.connect(region.update);
                    it.yChanged.connect(region.update);
                    it.parentChanged.connect(region.watch);
                    list.push(it);
                }
                region.watched = list;
                region.update();
            }

            property Connections sizeWatcher: Connections {
                target: region.modelData
                function onWidthChanged() {
                    region.update();
                }
                function onHeightChanged() {
                    region.update();
                }
                function onVisibleChanged() {
                    region.update();
                }
            }

            Component.onCompleted: watch()
            Component.onDestruction: {
                for (const w of region.watched) {
                    w.xChanged.disconnect(region.update);
                    w.yChanged.disconnect(region.update);
                    w.parentChanged.disconnect(region.watch);
                }
            }
        }
    }
}
