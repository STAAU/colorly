import CoreGraphics
import UIKit

@MainActor
final class LocalArtworkProvider {
    static let canvasSize = CGSize(width: 1024, height: 1024)
    private let cache = NSCache<NSString, UIImage>()

    func asset(for page: ColoringPage) -> ColoringPageAsset {
        ColoringPageAsset(page: page, pixelSize: Self.canvasSize, lineArt: fullImage(for: page))
    }

    func thumbnail(for page: ColoringPage, size: CGFloat = 320) -> UIImage {
        let key = "\(page.id)-\(Int(size))" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
        let result = UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format).image { context in
            UIColor.white.setFill(); context.fill(CGRect(x: 0, y: 0, width: size, height: size))
            UIImage(cgImage: fullImage(for: page)).draw(in: CGRect(x: 0, y: 0, width: size, height: size))
        }
        cache.countLimit = 32; cache.totalCostLimit = 12_000_000
        cache.setObject(result, forKey: key, cost: Int(size * size * 4))
        return result
    }

    private func fullImage(for page: ColoringPage) -> CGImage {
        if page.id == "cat" { return SampleCatPageRenderer.render() }
        let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = false
        let image = UIGraphicsImageRenderer(size: Self.canvasSize, format: format).image { renderer in
            let c = renderer.cgContext
            c.setStrokeColor(UIColor.black.cgColor); c.setLineWidth(18)
            c.setLineCap(.round); c.setLineJoin(.round)
            ArtworkRecipes.draw(page.id, in: c)
        }
        return image.cgImage!
    }
}

private enum ArtworkRecipes {
    static func draw(_ id: String, in c: CGContext) {
        switch id {
        case "dog": dog(c)
        case "panda": panda(c)
        case "fox": fox(c)
        case "trex": trex(c)
        case "triceratops": triceratops(c)
        case "car": car(c)
        case "fire-truck": fireTruck(c)
        case "rocket": rocket(c)
        case "astronaut": astronaut(c)
        case "planet": planet(c)
        case "fish": fish(c)
        case "turtle": turtle(c)
        case "dragon": dragon(c)
        case "unicorn": unicorn(c)
        case "cupcake": cupcake(c)
        default: rounded(c, 170, 170, 684, 684, 120)
        }
    }

    private static func dog(_ c: CGContext) {
        ellipse(c, 285, 245, 454, 430); ellipse(c, 170, 190, 230, 350); ellipse(c, 624, 190, 230, 350)
        ellipse(c, 385, 500, 254, 180); ellipse(c, 390, 330, 70, 90); ellipse(c, 564, 330, 70, 90)
        ellipse(c, 210, 690, 604, 205); ellipse(c, 260, 820, 190, 90); ellipse(c, 574, 820, 190, 90)
    }
    private static func panda(_ c: CGContext) {
        ellipse(c, 270, 180, 484, 490); ellipse(c, 210, 130, 190, 190); ellipse(c, 624, 130, 190, 190)
        ellipse(c, 345, 330, 115, 145); ellipse(c, 564, 330, 115, 145); ellipse(c, 425, 470, 174, 130)
        ellipse(c, 245, 650, 534, 250); ellipse(c, 210, 735, 190, 145); ellipse(c, 624, 735, 190, 145)
    }
    private static func fox(_ c: CGContext) {
        polygon(c, [(512,125),(760,315),(705,675),(512,800),(319,675),(264,315)])
        polygon(c, [(275,330),(215,115),(440,285)]); polygon(c, [(749,330),(809,115),(584,285)])
        polygon(c, [(512,790),(395,610),(629,610)]); ellipse(c, 370, 385, 80, 100); ellipse(c, 574, 385, 80, 100)
        ellipse(c, 270, 750, 484, 145)
    }
    private static func trex(_ c: CGContext) {
        curved(c, [(185,580),(235,245),(610,205),(825,355),(610,480),(560,735),(310,795),(185,580)])
        ellipse(c, 610, 292, 55, 65); polygon(c, [(625,480),(810,535),(610,570)])
        ellipse(c, 260, 720, 210, 135); ellipse(c, 480, 720, 210, 135); polygon(c, [(235,570),(95,500),(215,665)])
    }
    private static func triceratops(_ c: CGContext) {
        ellipse(c, 260, 260, 510, 470); polygon(c, [(310,350),(130,175),(405,285)]); polygon(c, [(714,350),(894,175),(619,285)])
        polygon(c, [(512,300),(455,90),(575,300)]); ellipse(c, 370, 420, 70, 80); ellipse(c, 584, 420, 70, 80)
        rounded(c, 365, 545, 294, 140, 65); ellipse(c, 220, 700, 584, 185)
    }
    private static func car(_ c: CGContext) {
        curved(c, [(145,650),(180,440),(335,405),(430,270),(665,270),(770,410),(865,455),(875,650),(145,650)])
        polygon(c, [(455,300),(360,410),(535,410),(535,300)]); polygon(c, [(565,300),(565,410),(735,410),(645,300)])
        ellipse(c, 230, 570, 190, 190); ellipse(c, 610, 570, 190, 190); rounded(c, 155, 645, 720, 95, 35)
    }
    private static func fireTruck(_ c: CGContext) {
        rounded(c, 120, 385, 780, 350, 45); rounded(c, 620, 425, 220, 145, 20)
        polygon(c, [(205,375),(255,190),(650,190),(700,260),(275,260)]); rounded(c, 210, 450, 300, 100, 18)
        ellipse(c, 210, 650, 185, 185); ellipse(c, 625, 650, 185, 185); ellipse(c, 450, 600, 105, 105)
    }
    private static func rocket(_ c: CGContext) {
        curved(c, [(512,105),(680,320),(650,680),(512,805),(374,680),(344,320),(512,105)])
        ellipse(c, 422, 320, 180, 180); polygon(c, [(375,570),(205,780),(390,720)]); polygon(c, [(649,570),(819,780),(634,720)])
        polygon(c, [(450,790),(512,930),(574,790)])
    }
    private static func astronaut(_ c: CGContext) {
        ellipse(c, 300, 100, 424, 390); ellipse(c, 355, 170, 314, 230); rounded(c, 315, 470, 394, 315, 90)
        rounded(c, 150, 500, 190, 125, 55); rounded(c, 684, 500, 190, 125, 55)
        rounded(c, 340, 740, 145, 175, 55); rounded(c, 539, 740, 145, 175, 55); rounded(c, 420, 550, 184, 120, 25)
    }
    private static func planet(_ c: CGContext) {
        ellipse(c, 260, 220, 504, 504); ellipse(c, 365, 335, 110, 90); ellipse(c, 550, 485, 125, 105)
        curved(c, [(105,570),(245,455),(790,370),(920,440),(785,580),(245,670),(105,570)])
        ellipse(c, 110, 150, 75, 75); ellipse(c, 815, 180, 95, 95); ellipse(c, 780, 760, 65, 65)
    }
    private static func fish(_ c: CGContext) {
        curved(c, [(145,515),(330,275),(710,320),(825,515),(710,710),(330,755),(145,515)])
        polygon(c, [(740,430),(930,275),(900,515),(930,755),(740,600)]); ellipse(c, 315, 420, 80, 90)
        curved(c, [(430,330),(530,170),(640,350),(430,330)]); curved(c, [(430,700),(530,855),(640,680),(430,700)])
    }
    private static func turtle(_ c: CGContext) {
        ellipse(c, 260, 275, 510, 460); ellipse(c, 725, 405, 190, 180); ellipse(c, 110, 400, 180, 155)
        ellipse(c, 230, 675, 185, 140); ellipse(c, 605, 675, 185, 140); ellipse(c, 230, 210, 185, 140); ellipse(c, 605, 210, 185, 140)
        polygon(c, [(390,315),(512,505),(635,315)]); polygon(c, [(390,695),(512,505),(635,695)]); ellipse(c, 820, 455, 35, 40)
    }
    private static func dragon(_ c: CGContext) {
        curved(c, [(265,715),(250,340),(410,205),(610,265),(735,455),(680,760),(265,715)])
        polygon(c, [(345,350),(160,210),(250,510)]); polygon(c, [(625,360),(825,205),(730,545)])
        polygon(c, [(445,220),(480,90),(535,230)]); ellipse(c, 430, 330, 60, 70); ellipse(c, 570, 330, 60, 70)
        curved(c, [(650,690),(870,650),(820,835),(650,690)]); ellipse(c, 285, 700, 210, 145)
    }
    private static func unicorn(_ c: CGContext) {
        curved(c, [(280,725),(260,350),(420,220),(670,285),(745,560),(650,775),(280,725)])
        polygon(c, [(480,235),(535,65),(585,255)]); polygon(c, [(350,300),(265,155),(455,255)]); polygon(c, [(655,305),(760,180),(705,390)])
        ellipse(c, 435, 365, 65, 75); ellipse(c, 595, 365, 65, 75); ellipse(c, 415, 565, 225, 120)
        curved(c, [(280,400),(115,510),(285,600),(280,400)])
    }
    private static func cupcake(_ c: CGContext) {
        curved(c, [(260,430),(290,820),(735,820),(765,430),(260,430)]); polygon(c, [(330,470),(370,780),(430,470)]); polygon(c, [(500,470),(512,780),(570,470)]); polygon(c, [(640,470),(610,780),(695,470)])
        curved(c, [(245,440),(275,300),(390,285),(420,175),(535,225),(610,170),(690,285),(775,320),(780,440),(245,440)])
        ellipse(c, 455, 90, 115, 115)
    }

    private static func ellipse(_ c: CGContext, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) { c.strokeEllipse(in: CGRect(x: x, y: y, width: w, height: h)) }
    private static func rounded(_ c: CGContext, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) { c.addPath(CGPath(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerWidth: r, cornerHeight: r, transform: nil)); c.strokePath() }
    private static func polygon(_ c: CGContext, _ points: [(CGFloat, CGFloat)]) { guard let first = points.first else { return }; let p = CGMutablePath(); p.move(to: CGPoint(x: first.0, y: first.1)); points.dropFirst().forEach { p.addLine(to: CGPoint(x: $0.0, y: $0.1)) }; p.closeSubpath(); c.addPath(p); c.strokePath() }
    private static func curved(_ c: CGContext, _ points: [(CGFloat, CGFloat)]) { guard let first = points.first else { return }; let p = CGMutablePath(); p.move(to: CGPoint(x: first.0, y: first.1)); points.dropFirst().forEach { p.addLine(to: CGPoint(x: $0.0, y: $0.1)) }; p.closeSubpath(); c.addPath(p); c.strokePath() }
}
