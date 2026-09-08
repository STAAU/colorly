import SwiftUI
import UIKit

@MainActor
struct ColoringScreen: View {
    @State private var viewModel: ColoringViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dismiss) private var dismiss

    init(viewModel: ColoringViewModel) { _viewModel = State(initialValue: viewModel) }

    var body: some View {
        @Bindable var viewModel = viewModel

        GeometryReader { geometry in
            let usesSideDeck = horizontalSizeClass == .regular || (geometry.size.width > geometry.size.height && geometry.size.width > 650)

            VStack(spacing: 0) {
                ColoringToolbar(
                    pageTitle: viewModel.page.title,
                    canUndo: viewModel.canUndo,
                    canRedo: viewModel.canRedo,
                    isSaving: viewModel.isSaving,
                    undo: viewModel.undo,
                    redo: viewModel.redo,
                    reset: { viewModel.isResetConfirmationPresented = true },
                    save: viewModel.save,
                    done: { viewModel.finish(); dismiss() }
                )

                if usesSideDeck {
                    HStack(spacing: 0) {
                        canvas
                        controlDeck
                            .frame(width: min(300, geometry.size.width * 0.34))
                            .padding(10)
                    }
                } else {
                    VStack(spacing: 0) {
                        canvas
                        controlDeck
                            .padding(.horizontal, 10)
                            .padding(.bottom, 8)
                    }
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
        .ignoresSafeArea(.keyboard)
        .toolbar(.hidden, for: .navigationBar)
        .onDisappear { viewModel.flushSave() }
        .alert("Start over?", isPresented: $viewModel.isResetConfirmationPresented) {
            Button("Cancel", role: .cancel) {}
            Button("Clear My Colors", role: .destructive) {
                viewModel.confirmReset()
            }
        } message: {
            Text("This clears all paint and the undo history. The black \(viewModel.page.title.lowercased()) lines stay in place.")
        }
        .alert(item: $viewModel.saveAlert) { alert in
            if case .denied = alert {
                return Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    primaryButton: .default(Text("Open Settings"), action: openSettings),
                    secondaryButton: .cancel()
                )
            }
            return Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .tint(Color(red: 0.08, green: 0.47, blue: 0.94))
    }

    private var canvas: some View {
        ZStack {
            ColoringCanvasRepresentable(
                document: viewModel.document,
                tool: viewModel.selectedTool,
                color: viewModel.selectedColor.rgba,
                brushSize: viewModel.brushSize,
                fillEnabled: !viewModel.isPreparingRegions,
                onEditFinished: viewModel.editFinished
            )
            CanvasStatusOverlay(isPreparing: viewModel.isPreparingRegions)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .accessibilityElement(children: .contain)
    }

    private var controlDeck: some View {
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                ForEach(ColoringTool.allCases) { tool in
                    Button { viewModel.selectedTool = tool } label: {
                        Label(tool.title, systemImage: tool.symbolName)
                            .font(.subheadline.bold()).labelStyle(.titleAndIcon)
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .foregroundStyle(viewModel.selectedTool == tool ? .white : Color.artInk)
                            .background(viewModel.selectedTool == tool ? Color.artInk : .clear, in: Capsule())
                    }
                    .buttonStyle(PressScaleStyle())
                    .accessibilityLabel(tool.title)
                    .accessibilityAddTraits(viewModel.selectedTool == tool ? .isSelected : [])
                }
            }
            .padding(5).background(.regularMaterial, in: Capsule())
            .overlay(Capsule().stroke(.primary.opacity(0.08)))

            BrushSizePicker(
                selection: $viewModel.brushSize,
                isVisible: viewModel.selectedTool == .brush || viewModel.selectedTool == .eraser
            )

            ColorPalette(selection: $viewModel.selectedColor)
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(.primary.opacity(0.08)))
        .shadow(color: .black.opacity(0.1), radius: 16, y: 8)
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
