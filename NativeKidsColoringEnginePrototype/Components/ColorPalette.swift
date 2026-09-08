import SwiftUI

struct ColorPalette: View {
    @Binding var selection: PaletteColor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Colors")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(PaletteColor.all) { paletteColor in
                        Button {
                            selection = paletteColor
                        } label: {
                            Circle()
                                .fill(paletteColor.rgba.swiftUIColor)
                                .frame(width: 42, height: 42)
                                .overlay {
                                    Circle()
                                        .stroke(.white, lineWidth: 3)
                                        .padding(3)
                                }
                                .overlay {
                                    Circle()
                                        .stroke(selection == paletteColor ? Color.accentColor : Color.black.opacity(0.14), lineWidth: selection == paletteColor ? 4 : 1)
                                }
                                .frame(width: 48, height: 48)
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(paletteColor.name)
                        .accessibilityAddTraits(selection == paletteColor ? .isSelected : [])
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
        }
    }
}
