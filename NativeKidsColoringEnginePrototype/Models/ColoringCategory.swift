import Foundation

struct ColoringCategory: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let symbol: String
    let sortOrder: Int
}
