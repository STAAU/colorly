import SwiftUI

struct ColoringToolbar: View {
    let pageTitle: String
    let canUndo: Bool, canRedo: Bool, isSaving: Bool
    let undo: () -> Void, redo: () -> Void, reset: () -> Void, save: () -> Void, done: () -> Void

    var body: some View {
        HStack(spacing: 5) {
            Text(pageTitle)
                .font(.headline.bold())
                .foregroundStyle(Color.artInk)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            ToolbarButton(title: "Undo", symbol: "arrow.uturn.backward", enabled: canUndo, action: undo)
            ToolbarButton(title: "Redo", symbol: "arrow.uturn.forward", enabled: canRedo, action: redo)
            Menu {
                Button("Start Over", systemImage: "arrow.counterclockwise", role: .destructive, action: reset)
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 42, height: 42)
                    .background(.primary.opacity(0.06), in: Circle())
            }
            .accessibilityLabel("More actions")
            ToolbarButton(title: "Save", symbol: isSaving ? "hourglass" : "square.and.arrow.down", enabled: !isSaving, prominent: true, action: save)
            Button("Done", action: done)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .frame(minHeight: 42)
                .background(Color.artLavender, in: Capsule())
                .buttonStyle(PressScaleStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial)
    }
}

private struct ToolbarButton: View {
    let title: String, symbol: String, enabled: Bool
    var prominent = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 17, weight: .semibold)).frame(width: 42, height: 42)
                .foregroundStyle(prominent ? .white : Color.artInk.opacity(enabled ? 1 : 0.35))
                .background(prominent ? Color.artInk : Color.primary.opacity(0.06), in: Circle())
        }.buttonStyle(PressScaleStyle()).disabled(!enabled).accessibilityLabel(title)
    }
}
