import CoreGraphics
import UIKit

@MainActor
final class ColoringDocument {
    let page: ColoringPageAsset

    var onInvalidate: ((CGRect) -> Void)?
    var onHistoryChange: (() -> Void)?

    private let paintSurface: PaintSurface
    private let history = HistoryManager(actionLimit: 25)
    private var segmentation: RegionSegmentation?
    private var activeStroke: ActiveStroke?

    init(page: ColoringPageAsset, restoredPaint: Data? = nil) {
        self.page = page
        self.paintSurface = PaintSurface(width: page.width, height: page.height)
        if let restoredPaint, let image = UIImage(data: restoredPaint)?.cgImage {
            _ = paintSurface.importImage(image)
        }
    }

    func paintPNGData() -> Data? {
        guard let image = paintSurface.image() else { return nil }
        return UIImage(cgImage: image).pngData()
    }

    var canUndo: Bool { history.canUndo }
    var canRedo: Bool { history.canRedo }
    var hasRegions: Bool { segmentation != nil }
    var canvasBounds: CGRect { CGRect(origin: .zero, size: page.pixelSize) }

    func install(segmentation: RegionSegmentation) {
        guard segmentation.width == page.width, segmentation.height == page.height else { return }
        self.segmentation = segmentation
    }

    @discardableResult
    func fill(at point: CGPoint, color: RGBAColor) -> Bool {
        guard
            activeStroke == nil,
            let segmentation,
            point.x >= 0,
            point.y >= 0,
            point.x < CGFloat(page.width),
            point.y < CGFloat(page.height),
            let index = segmentation.regionIndex(x: Int(point.x), y: Int(point.y))
        else { return false }

        let region = segmentation.regions[index]
        let transaction = PaintTransaction(surface: paintSurface)
        paintSurface.flushDrawing()
        for span in region.spans {
            transaction.capture(CGRect(x: span.startX, y: span.y, width: span.endX - span.startX + 1, height: 1))
        }
        for span in region.spans {
            paintSurface.fill(span: span, color: color)
        }
        finish(transaction: transaction)
        let dirty = CGRect(
            x: region.minX,
            y: region.minY,
            width: region.maxX - region.minX + 1,
            height: region.maxY - region.minY + 1
        )
        onInvalidate?(dirty)
        return true
    }

    func beginStroke(at point: CGPoint, color: RGBAColor, diameter: CGFloat, erasing: Bool) {
        guard activeStroke == nil, canvasBounds.insetBy(dx: -diameter, dy: -diameter).contains(point) else { return }
        let transaction = PaintTransaction(surface: paintSurface)
        let dirty = BrushEngine.bounds(from: point, to: point, diameter: diameter)
        transaction.capture(dirty)
        let renderedDirty = BrushEngine.apply(
            to: paintSurface,
            from: point,
            to: point,
            diameter: diameter,
            color: color,
            erasing: erasing
        )
        activeStroke = ActiveStroke(
            lastPoint: point,
            color: color,
            diameter: diameter,
            erasing: erasing,
            transaction: transaction
        )
        onInvalidate?(renderedDirty.intersection(canvasBounds))
    }

    func continueStroke(to point: CGPoint) {
        guard var stroke = activeStroke else { return }
        let dirty = BrushEngine.bounds(from: stroke.lastPoint, to: point, diameter: stroke.diameter)
        stroke.transaction.capture(dirty)
        let renderedDirty = BrushEngine.apply(
            to: paintSurface,
            from: stroke.lastPoint,
            to: point,
            diameter: stroke.diameter,
            color: stroke.color,
            erasing: stroke.erasing
        )
        stroke.lastPoint = point
        activeStroke = stroke
        onInvalidate?(renderedDirty.intersection(canvasBounds))
    }

    func finishStroke() {
        guard let stroke = activeStroke else { return }
        activeStroke = nil
        finish(transaction: stroke.transaction)
    }

    /// Reverts an in-progress gesture. This prevents the first finger of a two-finger pan
    /// from leaving an accidental dot or partial stroke behind.
    func cancelStroke() {
        guard let stroke = activeStroke else { return }
        activeStroke = nil
        stroke.transaction.restoreBefore()
        onInvalidate?(stroke.transaction.dirtyBounds.intersection(canvasBounds))
    }

    func undo() {
        cancelStroke()
        guard let action = history.takeUndo() else { return }
        apply(action: action, useAfter: false)
        onHistoryChange?()
    }

    func redo() {
        cancelStroke()
        guard let action = history.takeRedo() else { return }
        apply(action: action, useAfter: true)
        onHistoryChange?()
    }

    func reset() {
        activeStroke = nil
        paintSurface.clear()
        history.clear()
        onInvalidate?(canvasBounds)
        onHistoryChange?()
    }

    func draw(in context: CGContext) {
        context.saveGState()
        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(canvasBounds)
        context.interpolationQuality = .none
        if let paint = paintSurface.image() {
            UIImage(cgImage: paint).draw(in: canvasBounds)
        }
        UIImage(cgImage: page.lineArt).draw(in: canvasBounds)
        context.restoreGState()
    }

    func flattenedPNGData() -> Data? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        format.preferredRange = .standard
        let renderer = UIGraphicsImageRenderer(size: page.pixelSize, format: format)
        let image = renderer.image { rendererContext in
            let context = rendererContext.cgContext
            context.setFillColor(CGColor(gray: 1, alpha: 1))
            context.fill(canvasBounds)
            context.interpolationQuality = .none
            if let paint = paintSurface.image() {
                UIImage(cgImage: paint).draw(in: canvasBounds)
            }
            UIImage(cgImage: page.lineArt).draw(in: canvasBounds)
        }
        return image.pngData()
    }

    private func finish(transaction: PaintTransaction) {
        paintSurface.flushDrawing()
        if let action = transaction.makeAction() {
            history.record(action)
            onHistoryChange?()
        }
    }

    private func apply(action: DrawingAction, useAfter: Bool) {
        paintSurface.flushDrawing()
        var dirty = CGRect.null
        for patch in action.patches {
            let payload = useAfter ? patch.after : patch.before
            guard let pixels = payload.decoded() else { continue }
            paintSurface.write(rect: patch.rect, pixels: pixels)
            dirty = dirty.union(patch.rect)
        }
        if !dirty.isNull {
            onInvalidate?(dirty.intersection(canvasBounds))
        }
    }
}

private struct ActiveStroke {
    var lastPoint: CGPoint
    let color: RGBAColor
    let diameter: CGFloat
    let erasing: Bool
    let transaction: PaintTransaction
}

@MainActor
private final class PaintTransaction {
    static let tileSize = 64

    private let surface: PaintSurface
    private var beforeTiles: [Int: Data] = [:]
    private(set) var dirtyBounds = CGRect.null

    init(surface: PaintSurface) {
        self.surface = surface
        surface.flushDrawing()
    }

    func capture(_ rect: CGRect) {
        let clipped = rect.standardized.intersection(CGRect(x: 0, y: 0, width: surface.width, height: surface.height))
        guard !clipped.isNull, clipped.width > 0, clipped.height > 0 else { return }
        dirtyBounds = dirtyBounds.union(clipped)

        let minTileX = max(0, Int(floor(clipped.minX)) / Self.tileSize)
        let minTileY = max(0, Int(floor(clipped.minY)) / Self.tileSize)
        let maxTileX = min((surface.width - 1) / Self.tileSize, Int(ceil(clipped.maxX) - 1) / Self.tileSize)
        let maxTileY = min((surface.height - 1) / Self.tileSize, Int(ceil(clipped.maxY) - 1) / Self.tileSize)
        let tilesPerRow = (surface.width + Self.tileSize - 1) / Self.tileSize

        for tileY in minTileY...maxTileY {
            for tileX in minTileX...maxTileX {
                let key = tileY * tilesPerRow + tileX
                guard beforeTiles[key] == nil else { continue }
                let tileRect = rectForTile(x: tileX, y: tileY)
                beforeTiles[key] = surface.read(rect: tileRect)
            }
        }
    }

    func makeAction() -> DrawingAction? {
        guard !beforeTiles.isEmpty else { return nil }
        let tilesPerRow = (surface.width + Self.tileSize - 1) / Self.tileSize
        let patches = beforeTiles.keys.sorted().compactMap { key -> TilePatch? in
            guard let before = beforeTiles[key] else { return nil }
            let tileX = key % tilesPerRow
            let tileY = key / tilesPerRow
            let tileRect = rectForTile(x: tileX, y: tileY)
            let after = surface.read(rect: tileRect)
            guard before != after else { return nil }
            return TilePatch(
                rect: tileRect,
                before: PixelPayload(raw: before),
                after: PixelPayload(raw: after)
            )
        }
        return patches.isEmpty ? nil : DrawingAction(patches: patches)
    }

    func restoreBefore() {
        surface.flushDrawing()
        let tilesPerRow = (surface.width + Self.tileSize - 1) / Self.tileSize
        for (key, pixels) in beforeTiles {
            let tileRect = rectForTile(x: key % tilesPerRow, y: key / tilesPerRow)
            surface.write(rect: tileRect, pixels: pixels)
        }
    }

    private func rectForTile(x: Int, y: Int) -> CGRect {
        let originX = x * Self.tileSize
        let originY = y * Self.tileSize
        return CGRect(
            x: originX,
            y: originY,
            width: min(Self.tileSize, surface.width - originX),
            height: min(Self.tileSize, surface.height - originY)
        )
    }
}

private extension BrushEngine {
    static func bounds(from start: CGPoint, to end: CGPoint, diameter: CGFloat) -> CGRect {
        let radius = diameter / 2 + 2
        return CGRect(
            x: min(start.x, end.x) - radius,
            y: min(start.y, end.y) - radius,
            width: abs(end.x - start.x) + radius * 2,
            height: abs(end.y - start.y) + radius * 2
        )
    }
}
