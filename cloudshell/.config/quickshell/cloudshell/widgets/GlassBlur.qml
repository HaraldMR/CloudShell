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
 *
 * The compositor's blur region is whole pixels with no antialiasing, so its rounded corners are
 * stair-stepped. It's pulled `inset` pixels inside each surface so those steps stay hidden under
 * the surface's own smooth (antialiased) edge.
 */
QtObject {
    id: root
    property list<Item> items: []
    property real inset: 2

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
            radius: Math.max(0, (modelData?.radius ?? 0) - root.inset)

            property var watched: []

            function update() {
                const item = region.modelData;
                if (!item || !item.visible || !item.parent) {
                    region.width = 0;
                    region.height = 0;
                    return;
                }
                const pos = item.mapToItem(null, 0, 0);
                region.x = Math.ceil(pos.x + root.inset);
                region.y = Math.ceil(pos.y + root.inset);
                region.width = Math.max(0, Math.floor(item.width - root.inset * 2));
                region.height = Math.max(0, Math.floor(item.height - root.inset * 2));
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
