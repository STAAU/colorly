import CoreGraphics
import Foundation
import ImageIO
import UIKit

struct PreparedPhoto { let image: UIImage; let preview: UIImage; let path: String; let source: PhotoSourceKind }

enum PhotoImagePreparationService {
    static func prepare(data: Data, source: PhotoSourceKind) throws -> PreparedPhoto {
        guard let provider = CGDataProvider(data: data as CFData), let cgSource = CGImageSourceCreateWithDataProvider(provider, nil), CGImageSourceGetCount(cgSource) > 0 else { throw PhotoGenerationFailure.corrupt }
        guard let properties = CGImageSourceCopyPropertiesAtIndex(cgSource, 0, nil) as? [CFString: Any], let width = properties[kCGImagePropertyPixelWidth] as? Int, let height = properties[kCGImagePropertyPixelHeight] as? Int else { throw PhotoGenerationFailure.unsupported }
        guard min(width, height) >= 400 else { throw PhotoGenerationFailure.tooSmall }
        let options = [kCGImageSourceCreateThumbnailFromImageAlways: true, kCGImageSourceCreateThumbnailWithTransform: true, kCGImageSourceThumbnailMaxPixelSize: 2048] as CFDictionary
        guard let normalized = CGImageSourceCreateThumbnailAtIndex(cgSource, 0, options) else { throw PhotoGenerationFailure.corrupt }
        let image = UIImage(cgImage: normalized)
        guard image.averageLuminance > 0.06 else { throw PhotoGenerationFailure.tooDark }
        guard image.luminanceRange > 0.025 else { throw PhotoGenerationFailure.blank }
        let preview = image.downsampled(maxDimension: 500)
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("PhotoColoring", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let name = "source-\(UUID().uuidString).jpg", url = root.appendingPathComponent(name)
        guard let jpeg = image.jpegData(compressionQuality: 0.9) else { throw PhotoGenerationFailure.unsupported }
        try jpeg.write(to: url, options: .atomic)
        return PreparedPhoto(image:image, preview:preview, path:url.path, source:source)
    }
    static func storeComposition(_ image: UIImage, source: PhotoSourceKind) throws -> PreparedPhoto {
        guard let data=image.jpegData(compressionQuality:0.9) else { throw PhotoGenerationFailure.unsupported }
        return try prepare(data:data,source:source)
    }
}

@MainActor protocol PhotoGenerationService { func generate(_ request: PhotoGenerationRequest, id: UUID) async throws -> PhotoGenerationRecord }

@MainActor final class PhotoAssetRepository {
    let root=FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("PhotoCreations",isDirectory:true)
    func image(path:String?)->UIImage? { guard let path else{return nil}; return UIImage(contentsOfFile:root.appendingPathComponent(path).path) }
    func store(master:UIImage,thumbnail:UIImage,id:UUID)throws->(String,String){try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true); let m="\(id)-master.png",t="\(id)-thumbnail.png"; guard let md=master.pngData(),let td=thumbnail.pngData()else{throw PhotoGenerationFailure.storage};try md.write(to:root.appendingPathComponent(m),options:.atomic);try td.write(to:root.appendingPathComponent(t),options:.atomic);return(m,t)}
    func delete(_ record:PhotoGenerationRecord){[record.masterPath,record.thumbnailPath].compactMap{$0}.forEach{try? FileManager.default.removeItem(at:root.appendingPathComponent($0))}}
}
actor PhotoHistoryRepository {
    private let root=FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("PhotoCreations",isDirectory:true)
    func load()->[PhotoGenerationRecord]{(try? Data(contentsOf:root.appendingPathComponent("history.json"))).flatMap{try? JSONDecoder().decode([PhotoGenerationRecord].self,from:$0)} ?? []}
    func save(_ values:[PhotoGenerationRecord])throws{try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true);try JSONEncoder().encode(values).write(to:root.appendingPathComponent("history.json"),options:.atomic)}
    func pending()->UUID?{(try? Data(contentsOf:root.appendingPathComponent("pending.json"))).flatMap{try? JSONDecoder().decode(UUID.self,from:$0)}}
    func setPending(_ id:UUID?)throws{try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true);let u=root.appendingPathComponent("pending.json");if let id{try JSONEncoder().encode(id).write(to:u,options:.atomic)}else{try? FileManager.default.removeItem(at:u)}}
}
@MainActor final class LocalFixturePhotoGenerationService:PhotoGenerationService {
    let assets:PhotoAssetRepository; init(assets:PhotoAssetRepository){self.assets=assets}
    func generate(_ request:PhotoGenerationRequest,id:UUID)async throws->PhotoGenerationRecord{
        guard let data=try? Data(contentsOf:URL(fileURLWithPath:request.preparedSourcePath)),!data.isEmpty else{throw PhotoGenerationFailure.corrupt}
        try await Task.sleep(for:.milliseconds(600)); let seed=data.prefix(4096).reduce(UInt64(1469598103934665603)){($0 ^ UInt64($1)) &* 1099511628211}
        let master=PhotoFixtureRenderer.render(seed:seed,options:request.options,size:1024),thumb=PhotoFixtureRenderer.render(seed:seed,options:request.options,size:320)
        guard PhotoFixtureRenderer.valid(master) else{throw PhotoGenerationFailure.invalidOutput};let paths=try assets.store(master:master,thumbnail:thumb,id:id),now=Date()
        return PhotoGenerationRecord(id:id,source:request.source,options:request.options,status:.completed,createdAt:now,updatedAt:now,preparedSourcePath:request.preparedSourcePath,masterPath:paths.0,thumbnailPath:paths.1,failure:nil,isHiddenFromGallery:false)
    }
}
enum PhotoFixtureRenderer {
    static func render(seed:UInt64,options:PhotoGenerationOptions,size:CGFloat)->UIImage{let f=UIGraphicsImageRendererFormat();f.scale=1;f.opaque=true;return UIGraphicsImageRenderer(size:CGSize(width:size,height:size),format:f).image{r in UIColor.white.setFill();r.fill(CGRect(x:0,y:0,width:size,height:size));let c=r.cgContext;c.setStrokeColor(UIColor.black.cgColor);c.setLineWidth(size*(options.style == .simple ? 0.016:0.011));c.setLineCap(.round);c.setLineJoin(.round);let margin=size*0.07;c.strokeEllipse(in:CGRect(x:margin,y:margin,width:size - 2 * margin,height:size - 2 * margin));let count=options.style == .simple ? 7:options.style == .classic ? 12:18;for i in 0..<count{let v=seed &+ UInt64(i * 3571),w=size * (0.1+CGFloat(v % 18) / 100),h=size * (0.1+CGFloat((v/19)%18) / 100),x=margin + CGFloat((v/43) % 1000) / 1000 * (size - 2 * margin - w),y=margin + CGFloat((v/79) % 1000) / 1000 * (size - 2 * margin - h);c.strokeEllipse(in:CGRect(x:x,y:y,width:w,height:h))};if options.background == .keep{for i in 1...4{let y=size * CGFloat(i)/5;c.move(to:CGPoint(x:margin,y:y));c.addCurve(to:CGPoint(x:size - margin,y:y),control1:CGPoint(x:size * 0.35,y:y - size * 0.04),control2:CGPoint(x:size * 0.65,y:y + size * 0.04));c.strokePath()}}}}
    static func valid(_ image:UIImage)->Bool{guard let cg=image.cgImage,cg.width==1024,cg.height==1024,let d=cg.dataProvider?.data,let p=CFDataGetBytePtr(d)else{return false};var dark=0;let total=cg.width * cg.height;for i in stride(from:0,to:total,by:16){if p[i * 4]<80{dark += 1}};let ratio=Double(dark)/Double(total/16);return ratio > 0.005 && ratio < 0.35}
}
private extension UIImage {
    func downsampled(maxDimension:CGFloat)->UIImage{let scale=min(1,maxDimension/max(size.width,size.height));let target=CGSize(width:size.width*scale,height:size.height*scale);return UIGraphicsImageRenderer(size:target).image{_ in draw(in:CGRect(origin:.zero,size:target))}}
    var averageLuminance:Double{samples().0};var luminanceRange:Double{samples().1}
    func samples()->(Double,Double){guard let cg=downsampled(maxDimension:64).cgImage,let data=cg.dataProvider?.data,let p=CFDataGetBytePtr(data)else{return(0,0)};var sum=0.0,minV=1.0,maxV=0.0,n=0;for y in 0..<cg.height{for x in 0..<cg.width{let i=(y*cg.bytesPerRow)+(x*4);let v=(0.2126*Double(p[i])+0.7152*Double(p[i+1])+0.0722*Double(p[i+2]))/255;sum += v;minV=min(minV,v);maxV=max(maxV,v);n += 1}};return(sum/Double(max(n,1)),maxV-minV)}
}
