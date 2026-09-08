import SwiftUI

extension Color {
    static let artInk = Color(light: UIColor(red: 0.10, green: 0.10, blue: 0.15, alpha: 1), dark: .white)
    static let artPaper = Color(light: UIColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1), dark: UIColor(red: 0.07, green: 0.07, blue: 0.09, alpha: 1))
    static let artLavender = Color(red: 0.55, green: 0.47, blue: 0.91)
    static let artCoral = Color(red: 0.96, green: 0.39, blue: 0.37)
    static let artSky = Color(red: 0.36, green: 0.68, blue: 0.91)
    static let artMint = Color(red: 0.39, green: 0.76, blue: 0.62)
    static let aiSky = Color(red: 0.41, green: 0.82, blue: 0.91)
    static let aiMint = Color(red: 0.65, green: 0.86, blue: 0.85)
    static let aiCream = Color(red: 0.88, green: 0.89, blue: 0.80)
    static let aiOrange = Color(red: 0.95, green: 0.53, blue: 0.19)
    static let aiEmber = Color(red: 0.98, green: 0.41, blue: 0.00)

    init(light: UIColor, dark: UIColor) {
        self.init(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
}

struct EditorialHeader: View {
    let eyebrow: String
    let title: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(eyebrow.uppercased()).font(.caption.weight(.bold)).tracking(1.5).foregroundStyle(Color.artCoral)
            Text(title).font(.largeTitle.bold()).foregroundStyle(Color.artInk)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ArtSectionTitle: View {
    let title: String
    let detail: String?
    init(_ title: String, detail: String? = nil) { self.title = title; self.detail = detail }
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.title2.bold()).foregroundStyle(Color.artInk)
            Spacer()
            if let detail { Text(detail).font(.subheadline).foregroundStyle(.secondary) }
        }
    }
}

struct PressScaleStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
    }
}
