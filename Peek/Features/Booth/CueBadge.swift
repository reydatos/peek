import SwiftUI

struct CueBadge: View {
    let text: LocalizedStringResource
    let systemImage: String
    let isSubjectFacing: Bool

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(isSubjectFacing ? .largeTitle : .headline)
            .bold()
            .padding()
            .background(.regularMaterial, in: .capsule)
            .frame(maxHeight: .infinity, alignment: .top)
            .padding()
    }
}
