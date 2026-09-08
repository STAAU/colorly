import Foundation

protocol ContentRepository {
    var pages: [ColoringPage] { get }
    var categories: [ColoringCategory] { get }
    func page(id: String) -> ColoringPage?
}

struct LocalContentRepository: ContentRepository {
    let pages = SampleContent.pages
    let categories = SampleContent.categories
    func page(id: String) -> ColoringPage? { pages.first { $0.id == id } }
}
