import SwiftUI

struct PhotoActionLabel: View {
    let title: String
    let symbol: String
    let color: Color
    var body: some View {
        HStack {
            Image(systemName: symbol).font(.title)
            Text(title).font(.title3.bold())
            Spacer()
            Image(systemName: "chevron.right")
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(color, in: RoundedRectangle(cornerRadius: 24))
    }
}
