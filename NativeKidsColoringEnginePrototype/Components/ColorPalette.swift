import SwiftUI

struct ColorPalette: View {
    @Binding var selection: PaletteColor
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(PaletteColor.all) { color in
                    Button { selection = color } label: {
                        Circle().fill(color.rgba.swiftUIColor).frame(width: 40, height: 40)
                            .overlay(Circle().stroke(.white.opacity(0.9), lineWidth: 3).padding(3))
                            .overlay(Circle().stroke(selection == color ? Color.artInk : Color.primary.opacity(0.12), lineWidth: selection == color ? 3 : 1))
                            .padding(3).scaleEffect(selection == color ? 1.08 : 1)
                    }.buttonStyle(PressScaleStyle()).accessibilityLabel(color.name).accessibilityAddTraits(selection == color ? .isSelected : [])
                }
            }.padding(.horizontal, 4).padding(.vertical, 3)
        }
    }
}
