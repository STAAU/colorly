import Foundation
import UIKit

@MainActor protocol AIGenerationService { func generate(_ request: GenerationRequest, id: UUID) async throws -> GeneratedPageRecord }

@MainActor final class GeneratedAssetCache {
    private let root: URL
    init() { root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("GeneratedPages", isDirectory: true) }
    func masterURL(_ id: UUID) -> URL { root.appendingPathComponent("\(id.uuidString)-master.png") }
    func thumbnailURL(_ id: UUID) -> URL { root.appendingPathComponent("\(id.uuidString)-thumbnail.png") }
    func store(master: UIImage, thumbnail: UIImage, id: UUID) throws -> (String, String) {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        guard let masterData=master.pngData(), let thumbData=thumbnail.pngData() else { throw GenerationFailure.storage }
        let masterName="\(id.uuidString)-master.png", thumbName="\(id.uuidString)-thumbnail.png"
        try masterData.write(to: root.appendingPathComponent(masterName), options:.atomic)
        try thumbData.write(to: root.appendingPathComponent(thumbName), options:.atomic)
        return (masterName, thumbName)
    }
    func image(path: String?) -> UIImage? { guard let path else { return nil }; return UIImage(contentsOfFile: root.appendingPathComponent(path).path) }
    func delete(_ record: GeneratedPageRecord) { [record.masterPath, record.thumbnailPath].compactMap{$0}.forEach { try? FileManager.default.removeItem(at: root.appendingPathComponent($0)) } }
}

actor GeneratedHistoryRepository {
    private let index: URL
    private let pending: URL
    init() { let root=FileManager.default.urls(for:.applicationSupportDirectory,in:.userDomainMask)[0].appendingPathComponent("GeneratedPages",isDirectory:true); index=root.appendingPathComponent("history.json"); pending=root.appendingPathComponent("pending.json") }
    func load() -> [GeneratedPageRecord] { (try? Data(contentsOf:index)).flatMap { try? JSONDecoder().decode([GeneratedPageRecord].self,from:$0) } ?? [] }
    func save(_ records:[GeneratedPageRecord]) throws { try FileManager.default.createDirectory(at:index.deletingLastPathComponent(),withIntermediateDirectories:true); try JSONEncoder().encode(records).write(to:index,options:.atomic) }
    func loadPending() -> UUID? { (try? Data(contentsOf:pending)).flatMap { try? JSONDecoder().decode(UUID.self,from:$0) } }
    func savePending(_ id:UUID?) throws { try FileManager.default.createDirectory(at:pending.deletingLastPathComponent(),withIntermediateDirectories:true); if let id { try JSONEncoder().encode(id).write(to:pending,options:.atomic) } else { try? FileManager.default.removeItem(at:pending) } }
}

@MainActor final class LocalFixtureGenerationService: AIGenerationService {
    let cache: GeneratedAssetCache
    init(cache:GeneratedAssetCache){self.cache=cache}
    func generate(_ request:GenerationRequest,id:UUID) async throws -> GeneratedPageRecord {
        try await Task.sleep(for:.milliseconds(700)); let master=FixtureLineArtRenderer.render(prompt:request.prompt,complexity:request.complexity,size:1024); let thumb=FixtureLineArtRenderer.render(prompt:request.prompt,complexity:request.complexity,size:320); let paths=try cache.store(master:master,thumbnail:thumb,id:id); let now=Date(); return GeneratedPageRecord(id:id,prompt:request.prompt,complexity:request.complexity,status:.completed,createdAt:now,updatedAt:now,masterPath:paths.0,thumbnailPath:paths.1,failure:nil)
    }
}

enum FixtureLineArtRenderer {
    static func render(prompt:String,complexity:GenerationComplexity,size:CGFloat)->UIImage {
        let format=UIGraphicsImageRendererFormat(); format.scale=1; format.opaque=true
        return UIGraphicsImageRenderer(size:CGSize(width:size,height:size),format:format).image { r in
            UIColor.white.setFill(); r.fill(CGRect(x:0,y:0,width:size,height:size)); let c=r.cgContext; c.setStrokeColor(UIColor.black.cgColor); c.setLineWidth(size*0.014); c.setLineCap(.round); c.setLineJoin(.round)
            let seed=prompt.utf8.reduce(UInt64(5381)){($0 &* 33) &+ UInt64($1)}; let count=complexity == .simple ? 5 : complexity == .medium ? 9 : 14
            let margin=size*0.09; c.strokeEllipse(in:CGRect(x:margin,y:margin,width:size-margin*2,height:size-margin*2))
            for i in 0..<count { let v=seed &+ UInt64(i*7919); let w=size*(0.12+CGFloat(v%17)/100); let h=size*(0.12+CGFloat((v/17)%17)/100); let x=margin+CGFloat((v/37)%1000)/1000*(size-margin*2-w); let y=margin+CGFloat((v/71)%1000)/1000*(size-margin*2-h); if v%2==0 { c.strokeEllipse(in:CGRect(x:x,y:y,width:w,height:h)) } else { let p=UIBezierPath(roundedRect:CGRect(x:x,y:y,width:w,height:h),cornerRadius:min(w,h)*0.22); c.addPath(p.cgPath); c.strokePath() } }
        }
    }
}
