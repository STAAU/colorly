import SwiftUI

struct GeneratedResultView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    let record: GeneratedPageRecord
    @State private var editor: ColoringProject?
    var body: some View { NavigationStack { VStack(spacing:18){if let image=model.image(for:record,thumbnail:false){Image(uiImage:image).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius:24))}; Text(record.prompt).font(.title2.bold()).multilineTextAlignment(.center); Button{editor=model.makeProject(for:record.page)}label:{Label(model.project(for:record.page.id)==nil ? "Start Coloring":"Continue Coloring",systemImage:"paintbrush.fill").frame(maxWidth:.infinity).padding().background(Color.artInk,in:Capsule()).foregroundStyle(.white)}.buttonStyle(PressScaleStyle()); Spacer()}.padding().background(Color.artPaper).toolbar{ToolbarItem(placement:.topBarTrailing){Button("Done"){dismiss()}}} }.fullScreenCover(item:$editor){project in EditorLoaderView(page:record.page,project:project)} }
}
