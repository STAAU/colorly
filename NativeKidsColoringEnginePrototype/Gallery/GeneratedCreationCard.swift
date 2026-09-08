import SwiftUI

struct GeneratedCreationCard: View {
    @Environment(AppModel.self) private var model
    let record: GeneratedPageRecord
    var body: some View {
        VStack(alignment:.leading,spacing:10){Group{if let image=model.image(for:record,thumbnail:true){Image(uiImage:image).resizable().scaledToFit()}else{ZStack{Color.artSky.opacity(0.16);ProgressView()}}}.aspectRatio(1,contentMode:.fit).background(.white).clipShape(RoundedRectangle(cornerRadius:20)); Text(record.prompt).font(.headline).lineLimit(2); Text(record.complexity.rawValue).font(.caption).foregroundStyle(.secondary)}
    }
}
