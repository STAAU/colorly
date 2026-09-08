import SwiftUI

struct BrushSizePicker: View {
    @Binding var selection: BrushSize
    let isVisible: Bool

    var body: some View {
        Group {
            if isVisible {
                HStack(spacing: 8) {
                    Text("Size")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(BrushSize.allCases) { size in
                        Button {
                            selection = size
                        } label: {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color.primary)
                                    .frame(width: markerDiameter(for: size), height: markerDiameter(for: size))
                                Text(size.title)
                                    .font(.caption.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity, minHeight: 42)
                            .background(selection == size ? Color.accentColor.opacity(0.16) : Color.black.opacity(0.045), in: RoundedRectangle(cornerRadius: 12))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selection == size ? Color.accentColor : .clear, lineWidth: 2)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(size.title) size")
                        .accessibilityAddTraits(selection == size ? .isSelected : [])
                    }
                }
                .frame(minHeight: 48)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                    Text("Tap a space to fill it")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 48)
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func markerDiameter(for size: BrushSize) -> CGFloat {
        switch size {
        case .small: 5
        case .medium: 9
        case .large: 14
        }
    }
}
