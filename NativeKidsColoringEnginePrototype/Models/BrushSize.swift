import Foundation

enum BrushSize: String, CaseIterable, Identifiable, Sendable {
    case small
    case medium
    case large

    var id: Self { self }

    var title: String { rawValue.capitalized }

    /// Diameter in the page's canonical 1024-point coordinate space.
    var diameter: CGFloat {
        switch self {
        case .small: 18
        case .medium: 38
        case .large: 68
        }
    }
}
