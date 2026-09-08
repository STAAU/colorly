import SwiftUI

struct CanvasStatusOverlay: View {
    let isPreparing: Bool

    var body: some View {
        if isPreparing {
            HStack(spacing: 10) {
                ProgressView()
                Text("Getting fills ready…")
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(.regularMaterial, in: Capsule())
            .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
            .accessibilityLabel("Getting fill regions ready")
        }
    }
}
