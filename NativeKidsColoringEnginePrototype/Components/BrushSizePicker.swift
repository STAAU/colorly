import SwiftUI

struct BrushSizePicker: View {
    @Binding var selection: BrushSize
    let isVisible: Bool
    var body: some View {
        Group {
            if isVisible {
                HStack(spacing: 8) {
                    Text("Stroke").font(.caption.bold()).foregroundStyle(.secondary)
                    ForEach(BrushSize.allCases) { size in
                        Button { selection = size } label: {
                            ZStack {
                                Circle().fill(selection == size ? Color.artInk : Color.primary.opacity(0.07)).frame(width: 42, height: 42)
                                Circle().fill(selection == size ? .white : Color.artInk).frame(width: marker(size), height: marker(size))
                            }
                        }.buttonStyle(PressScaleStyle()).accessibilityLabel("\(size.title) size").accessibilityAddTraits(selection == size ? .isSelected : [])
                    }
                }.frame(maxWidth: .infinity)
            } else {
                Label("Tap an area to fill", systemImage: "hand.tap.fill").font(.subheadline.weight(.medium)).foregroundStyle(.secondary).frame(maxWidth: .infinity, minHeight: 42)
            }
        }
    }
    private func marker(_ size: BrushSize) -> CGFloat { size == .small ? 5 : (size == .medium ? 10 : 16) }
}
