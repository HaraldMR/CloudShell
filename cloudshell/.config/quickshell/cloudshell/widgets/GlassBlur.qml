import QtQuick
import Quickshell

/**
 * Builds a blur region (for a window's BackgroundEffect.blurRegion) from a list of surfaces.
 * Each item's `radius` rounds its part of the region. Items that aren't visible are skipped.
 *
 *   BackgroundEffect.blurRegion: Appearance.glass ? glassBlur.region : null
 *   GlassBlur { id: glassBlur; items: [card1, card2] }
 *
 * - Position: Region's own `item` places the region by the item's position inside its parent, which
 *   is wrong for nested items, so the position in the window is computed here and kept up to date.
 * - Shape: the compositor's blur has no antialiasing, and Region's built-in rounded corners are a
 *   coarse curve that bulges past the real circle. So each surface is built from 1px strips through
 *   its rounded corners, every strip cut to lie strictly inside the circle (and `inset` px inside
 *   the edge), where the surface's own smooth edge covers it.
 */
QtObject {
    id: root
    property list<Item> items: []
    property int inset: 1

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
            id: area
            required property Item modelData

            // Area in window pixels, already inset
            property int gx: 0
            property int gy: 0
            property int gw: 0
            property int gh: 0
            readonly property real r: Math.max(0, Math.min((modelData?.radius ?? 0) - root.inset, Math.min(gw, gh) / 2))
            readonly property int rows: Math.ceil(r)

            // The region itself is empty; the strips make up the shape
            width: 0
            height: 0
            regions: {
                const result = [];
                for (let i = 0; i < strips.count; i++) {
                    const strip = strips.objectAt(i);
                    if (strip)
                        result.push(strip);
                }
                return result;
            }

            property Instantiator strips: Instantiator {
                model: area.gw > 0 && area.gh > 0 ? area.rows * 2 + 1 : 0
                delegate: Region {
                    required property int index
                    readonly property bool middle: index === area.rows
                    readonly property bool top: index < area.rows
                    // Rows counted from the outer (top or bottom) edge
                    readonly property int edgeRow: top ? index : area.rows * 2 - index
                    // Width cut from each side: where the circle is at this row's outer edge
                    readonly property int cut: middle ? 0 : Math.ceil(area.r - Math.sqrt(Math.max(0, area.r * area.r - (area.r - edgeRow) * (area.r - edgeRow))))
                    x: area.gx + cut
                    width: Math.max(0, area.gw - cut * 2)
                    y: middle ? area.gy + area.rows : top ? area.gy + index : area.gy + area.gh - 1 - edgeRow
                    height: middle ? Math.max(0, area.gh - area.rows * 2) : 1
                }
            }

            property var watched: []

            function update() {
                const item = area.modelData;
                if (!item || !item.visible || !item.parent) {
                    area.gw = 0;
                    area.gh = 0;
                    return;
                }
                const pos = item.mapToItem(null, 0, 0);
                const left = Math.ceil(pos.x + root.inset);
                const topEdge = Math.ceil(pos.y + root.inset);
                const right = Math.floor(pos.x + item.width - root.inset);
                const bottom = Math.floor(pos.y + item.height - root.inset);
                area.gx = left;
                area.gy = topEdge;
                area.gw = Math.max(0, right - left);
                area.gh = Math.max(0, bottom - topEdge);
            }

            function watch() {
                for (const w of area.watched) {
                    w.xChanged.disconnect(area.update);
                    w.yChanged.disconnect(area.update);
                    w.parentChanged.disconnect(area.watch);
                }
                const list = [];
                for (let it = area.modelData; it; it = it.parent) {
                    it.xChanged.connect(area.update);
                    it.yChanged.connect(area.update);
                    it.parentChanged.connect(area.watch);
                    list.push(it);
                }
                area.watched = list;
                area.update();
            }

            property Connections sizeWatcher: Connections {
                target: area.modelData
                function onWidthChanged() {
                    area.update();
                }
                function onHeightChanged() {
                    area.update();
                }
                function onVisibleChanged() {
                    area.update();
                }
            }

            Component.onCompleted: watch()
            Component.onDestruction: {
                for (const w of area.watched) {
                    w.xChanged.disconnect(area.update);
                    w.yChanged.disconnect(area.update);
                    w.parentChanged.disconnect(area.watch);
                }
            }
        }
    }
}
