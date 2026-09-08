import Foundation

enum ProjectStatus: String, Codable { case inProgress, finished }

struct ColoringProject: Codable, Identifiable, Hashable {
    let id: String
    let pageID: String
    let createdAt: Date
    var updatedAt: Date
    var status: ProjectStatus
    var paintPath: String
    var thumbnailPath: String
    let pixelWidth: Int
    let pixelHeight: Int
}
