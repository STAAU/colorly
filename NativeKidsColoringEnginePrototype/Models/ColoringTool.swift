import Foundation

enum ColoringTool: String, CaseIterable, Identifiable, Sendable {
    case fill
    case brush
    case eraser

    var id: Self { self }

    var title: String {
        switch self {
        case .fill: "Fill"
        case .brush: "Brush"
        case .eraser: "Erase"
        }
    }

    var symbolName: String {
        switch self {
        case .fill: "paintbucket.fill"
        case .brush: "paintbrush.pointed.fill"
        case .eraser: "eraser.fill"
        }
    }
}
