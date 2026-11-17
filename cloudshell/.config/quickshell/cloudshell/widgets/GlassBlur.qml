import QtQuick
import Quickshell

/**
 * Builds a blur region (for a window's BackgroundEffect.blurRegion) from a list of surfaces.
 * Each item's `radius` rounds its part of the region. Items that aren't visible are skipped.
 *
 *   BackgroundEffect.blurRegion: Appearance.glass ? glassBlur.region : null
 *   GlassBlur { id: glassBlur; items: [card1, card2] }
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
            required property Item modelData
            item: modelData && modelData.visible ? modelData : null
            radius: modelData?.radius ?? 0
        }
    }
}
