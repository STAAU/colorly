import SwiftUI

struct ColoringToolbar: View {
    let canUndo: Bool
    let canRedo: Bool
    let isSaving: Bool
    let undo: () -> Void
    let redo: () -> Void
    let reset: () -> Void
    let save: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            ViewThatFits(in: .horizontal) {
                Text("Color the Cat")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Cat")
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ToolbarButton(title: "Undo", symbol: "arrow.uturn.backward", enabled: canUndo, action: undo)
            ToolbarButton(title: "Redo", symbol: "arrow.uturn.forward", enabled: canRedo, action: redo)
            ToolbarButton(title: "Reset", symbol: "arrow.counterclockwise", enabled: true, action: reset)
            ToolbarButton(title: "Save", symbol: isSaving ? "hourglass" : "square.and.arrow.down", enabled: !isSaving, action: save)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(uiColor: .secondarySystemBackground))
    }
}

private struct ToolbarButton: View {
    let title: String
    let symbol: String
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: symbol)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 9, weight: .semibold))
            }
            .frame(width: 45, height: 44)
            .foregroundStyle(enabled ? Color.accentColor : Color.secondary.opacity(0.45))
            .background(Color.black.opacity(enabled ? 0.035 : 0.018), in: RoundedRectangle(cornerRadius: 11))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(title)
    }
}
