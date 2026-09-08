import Foundation

struct RegionSpan: Sendable {
    let y: Int
    let startX: Int
    let endX: Int
}

struct FillRegion: Sendable {
    let spans: [RegionSpan]
    let minX: Int
    let minY: Int
    let maxX: Int
    let maxY: Int
}

struct RegionSegmentation: Sendable {
    let width: Int
    let height: Int
    /// -1 is a barrier. Every nonnegative value indexes `regions`.
    let labels: [Int32]
    let regions: [FillRegion]

    func regionIndex(x: Int, y: Int) -> Int? {
        guard x >= 0, y >= 0, x < width, y < height else { return nil }
        let label = labels[y * width + x]
        return label >= 0 ? Int(label) : nil
    }
}

enum FloodFillEngine {
    /// Labels each connected non-boundary component once. Work uses flat value buffers only;
    /// there is no recursion and no per-pixel reference allocation.
    static func segment(mask: BoundaryMask) -> RegionSegmentation {
        let width = mask.width
        let height = mask.height
        let pixelCount = width * height
        var labels = [Int32](repeating: -2, count: pixelCount)

        mask.bytes.withUnsafeBytes { raw in
            guard let barriers = raw.bindMemory(to: UInt8.self).baseAddress else { return }
            for index in 0..<pixelCount where barriers[index] != 0 {
                labels[index] = -1
            }
        }

        var queue = [Int32]()
        queue.reserveCapacity(pixelCount)
        var regionCount: Int32 = 0

        for seed in 0..<pixelCount where labels[seed] == -2 {
            queue.removeAll(keepingCapacity: true)
            labels[seed] = regionCount
            queue.append(Int32(seed))
            var cursor = 0

            while cursor < queue.count {
                let index = Int(queue[cursor])
                cursor += 1
                let x = index % width

                if x > 0 {
                    enqueue(index - 1, label: regionCount, labels: &labels, queue: &queue)
                }
                if x + 1 < width {
                    enqueue(index + 1, label: regionCount, labels: &labels, queue: &queue)
                }
                if index >= width {
                    enqueue(index - width, label: regionCount, labels: &labels, queue: &queue)
                }
                if index + width < pixelCount {
                    enqueue(index + width, label: regionCount, labels: &labels, queue: &queue)
                }
            }
            regionCount += 1
        }

        var spans = [[RegionSpan]](repeating: [], count: Int(regionCount))
        var bounds = [RegionBounds](repeating: RegionBounds(), count: Int(regionCount))

        for y in 0..<height {
            var x = 0
            while x < width {
                let label = labels[y * width + x]
                guard label >= 0 else {
                    x += 1
                    continue
                }
                let start = x
                x += 1
                while x < width, labels[y * width + x] == label {
                    x += 1
                }
                let end = x - 1
                let region = Int(label)
                spans[region].append(RegionSpan(y: y, startX: start, endX: end))
                bounds[region].include(minX: start, maxX: end, y: y)
            }
        }

        let regions = spans.indices.map { index in
            FillRegion(
                spans: spans[index],
                minX: bounds[index].minX,
                minY: bounds[index].minY,
                maxX: bounds[index].maxX,
                maxY: bounds[index].maxY
            )
        }
        return RegionSegmentation(width: width, height: height, labels: labels, regions: regions)
    }

    private static func enqueue(
        _ index: Int,
        label: Int32,
        labels: inout [Int32],
        queue: inout [Int32]
    ) {
        guard labels[index] == -2 else { return }
        labels[index] = label
        queue.append(Int32(index))
    }
}

private struct RegionBounds {
    var minX = Int.max
    var minY = Int.max
    var maxX = Int.min
    var maxY = Int.min

    mutating func include(minX: Int, maxX: Int, y: Int) {
        self.minX = Swift.min(self.minX, minX)
        self.minY = Swift.min(self.minY, y)
        self.maxX = Swift.max(self.maxX, maxX)
        self.maxY = Swift.max(self.maxY, y)
    }
}
