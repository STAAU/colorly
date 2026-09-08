import CoreGraphics
import SwiftUI

struct RGBAColor: Hashable, Sendable {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8

    init(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8 = 255) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    var swiftUIColor: Color {
        Color(
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }

    var cgColor: CGColor {
        CGColor(
            srgbRed: CGFloat(red) / 255,
            green: CGFloat(green) / 255,
            blue: CGFloat(blue) / 255,
            alpha: CGFloat(alpha) / 255
        )
    }
}

struct PaletteColor: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let rgba: RGBAColor

    static let all: [PaletteColor] = [
        .init(id: "red", name: "Red", rgba: .init(red: 239, green: 68, blue: 68)),
        .init(id: "orange", name: "Orange", rgba: .init(red: 249, green: 115, blue: 22)),
        .init(id: "yellow", name: "Yellow", rgba: .init(red: 250, green: 204, blue: 21)),
        .init(id: "green", name: "Green", rgba: .init(red: 34, green: 197, blue: 94)),
        .init(id: "cyan", name: "Cyan", rgba: .init(red: 34, green: 211, blue: 238)),
        .init(id: "blue", name: "Blue", rgba: .init(red: 59, green: 130, blue: 246)),
        .init(id: "purple", name: "Purple", rgba: .init(red: 139, green: 92, blue: 246)),
        .init(id: "pink", name: "Pink", rgba: .init(red: 236, green: 72, blue: 153)),
        .init(id: "brown", name: "Brown", rgba: .init(red: 146, green: 91, blue: 56)),
        .init(id: "black", name: "Black", rgba: .init(red: 28, green: 32, blue: 38)),
        .init(id: "lightGray", name: "Light Gray", rgba: .init(red: 203, green: 213, blue: 225))
    ]
}
