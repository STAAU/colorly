import Foundation

actor ProjectStorageService {
    private let root: URL
    private let indexURL: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        root = base.appendingPathComponent("ColoringProjects", isDirectory: true)
        indexURL = root.appendingPathComponent("index.json")
    }

    func loadProjects() -> [ColoringProject] {
        guard let data = try? Data(contentsOf: indexURL), let values = try? JSONDecoder().decode([ColoringProject].self, from: data) else { return [] }
        return values
    }

    func paint(for project: ColoringProject) -> Data? { try? Data(contentsOf: root.appendingPathComponent(project.paintPath)) }
    func thumbnail(for project: ColoringProject) -> Data? { try? Data(contentsOf: root.appendingPathComponent(project.thumbnailPath)) }
    func lineArt(for project: ColoringProject) -> Data? { try? Data(contentsOf: root.appendingPathComponent("\(project.id)-lineart.png")) }
    func saveLineArt(_ data: Data, for project: ColoringProject) throws {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try data.write(to: root.appendingPathComponent("\(project.id)-lineart.png"), options: .atomic)
    }

    func save(project: ColoringProject, paint: Data, thumbnail: Data, allProjects: [ColoringProject]) throws {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try paint.write(to: root.appendingPathComponent(project.paintPath), options: .atomic)
        try thumbnail.write(to: root.appendingPathComponent(project.thumbnailPath), options: .atomic)
        let data = try JSONEncoder().encode(allProjects)
        try data.write(to: indexURL, options: .atomic)
    }

    func saveIndex(_ projects: [ColoringProject]) throws {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try JSONEncoder().encode(projects).write(to: indexURL, options: .atomic)
    }
}
