import SwiftUI

struct CreateView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var prompt=""; @State private var complexity:GenerationComplexity = .medium; @State private var editor:ColoringProject?
    private let suggestions=["A sleepy fox in a flower garden","A rocket visiting a ringed planet","A friendly dragon having a picnic","A tiny city inside a teacup","A submarine with smiling sea creatures"]
    private var completed:GeneratedPageRecord? { if case .completed(let id)=model.generationPhase{return model.generatedHistory.first{$0.id==id}}; return nil }
    private var displayedSuggestions: [String] {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let offset = day % suggestions.count
        return (0..<4).map { suggestions[($0 + offset) % suggestions.count] }
    }
    var body: some View {
        NavigationStack { ScrollView { VStack(alignment:.leading,spacing:24) { header; accountNotice; if let completed { result(completed) } else { ideaForm; status } }.padding(20).frame(maxWidth:700).frame(maxWidth:.infinity) }.scrollDismissesKeyboard(.interactively).background(Color.artPaper).toolbar { ToolbarItem(placement:.topBarLeading){Button("Close"){dismiss()}} } }
        .fullScreenCover(item:$editor){ project in if let page=model.page(id:project.pageID){EditorLoaderView(page:page,project:project)} }
    }
    private var header:some View { VStack(alignment:.leading,spacing:8){Text("MAKE IT YOURS").font(.caption.bold()).tracking(1.4).foregroundStyle(Color.aiEmber); Text("Create with AI").font(.largeTitle.bold()); Text("Turn an idea into a one-of-a-kind coloring page—made locally for this preview.").foregroundStyle(.secondary)} }
    private var accountNotice: some View {
        Label("Local studio preview · an account will be required for live AI", systemImage: "person.crop.circle.badge.checkmark")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.artInk)
            .padding(.horizontal, 14).padding(.vertical, 11)
            .background(Color.aiCream.opacity(0.65), in: Capsule())
            .accessibilityLabel("Local preview. An account will be required for live AI generation.")
    }
    private var ideaForm:some View { VStack(alignment:.leading,spacing:18){ VStack(alignment:.leading,spacing:8){Text("What should we draw?").font(.headline); TextEditor(text:$prompt).frame(minHeight:120).padding(10).background(.white,in:RoundedRectangle(cornerRadius:20)).overlay(RoundedRectangle(cornerRadius:20).stroke(Color.aiSky.opacity(0.8))).onChange(of:prompt){_,v in if v.count>300{prompt=String(v.prefix(300))}}.accessibilityLabel("Coloring page idea"); Text("\(prompt.count)/300").font(.caption).foregroundStyle(.secondary).frame(maxWidth:.infinity,alignment:.trailing)}; suggestionsView; Picker("Complexity",selection:$complexity){ForEach(GenerationComplexity.allCases){Text($0.rawValue).tag($0)}}.pickerStyle(.segmented); Button{model.generate(prompt:prompt,complexity:complexity)}label:{Label("Create my page",systemImage:"wand.and.stars").font(.headline).frame(maxWidth:.infinity).padding(.vertical,15).background(Color.aiEmber,in:Capsule()).foregroundStyle(.white)}.buttonStyle(PressScaleStyle()).disabled(prompt.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || model.generationPhase.isBusy).accessibilityHint("Generates one coloring page") } }
    private var suggestionsView:some View { ScrollView(.horizontal,showsIndicators:false){HStack{ForEach(displayedSuggestions,id:\.self){idea in Button(idea){prompt=idea}.buttonStyle(.bordered).tint(Color.artInk)}}} }
    @ViewBuilder private var status:some View { switch model.generationPhase { case .submitting: message("Checking your AI page allowance…","paperplane.fill"); case .generating: message("Sketching bold outlines…","pencil.and.scribble"); case .processing: message("Making every space color-ready…","sparkles"); case .failed(.limitReached): limitReached; case .failed(let error): VStack(alignment:.leading,spacing:12){Text(error.message).foregroundStyle(.secondary); Button("Try again"){model.resetGeneration()}.buttonStyle(.borderedProminent)}; default: EmptyView() } }
    private var limitReached: some View { VStack(alignment:.leading,spacing:14){Label("AI page allowance reached",systemImage:"clock.badge.exclamationmark").font(.title3.bold()).foregroundStyle(Color.artInk);Text(model.subscriptions.access.hasPremium ? "You’ve used this month’s AI coloring page allowance. Your creations will refresh with your next monthly reset." : "You’ve used your free AI coloring pages. Unlock Premium for a larger monthly creation allowance.").foregroundStyle(.secondary);if !model.subscriptions.access.hasPremium{Button("Unlock Premium"){dismiss();Task{try? await Task.sleep(for:.milliseconds(350));model.presentPaywall(context:"AI coloring pages")}}.buttonStyle(.borderedProminent).tint(Color.aiEmber)};Button("Explore Coloring Pages"){model.selectedTab=1;dismiss()}.buttonStyle(.bordered);Button("Not now"){dismiss()}.font(.subheadline).foregroundStyle(.secondary)}.padding(18).frame(maxWidth:.infinity,alignment:.leading).background(Color.aiCream.opacity(0.7),in:RoundedRectangle(cornerRadius:22)) }
    private func message(_ text:String,_ symbol:String)->some View { HStack(spacing:12){Image(systemName:symbol).symbolEffect(.pulse); Text(text).font(.headline)}.padding().frame(maxWidth:.infinity).background(Color.artMint.opacity(0.25),in:RoundedRectangle(cornerRadius:18)) }
    private func result(_ record:GeneratedPageRecord)->some View { VStack(spacing:18){if let image=model.image(for:record,thumbnail:false){Image(uiImage:image).resizable().scaledToFit().background(.white).clipShape(RoundedRectangle(cornerRadius:26)).shadow(radius:12,y:6)}; Text(record.prompt).font(.title2.bold()).multilineTextAlignment(.center); Button{editor=model.makeProject(for:record.page)}label:{Label("Start Coloring",systemImage:"paintbrush.fill").frame(maxWidth:.infinity).padding().background(Color.artInk,in:Capsule()).foregroundStyle(.white)}; HStack{Button("Generate Again"){prompt=record.prompt;model.resetGeneration()}; Spacer(); Button("Edit Idea"){prompt=record.prompt;model.resetGeneration()}}.buttonStyle(.bordered); Button("Save for Later"){dismiss()}.font(.headline).accessibilityHint("Keeps this creation in Gallery")}.buttonStyle(PressScaleStyle()) }
}
