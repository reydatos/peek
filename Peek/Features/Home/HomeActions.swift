import SwiftUI

/// The actions of the first screen: the red start button with the name of the selected pack, and the draft.
struct HomeActions: View {
    let pack: PosePack
    let hasDraft: Bool
    let onStart: () -> Void
    let onResume: () -> Void

    var body: some View {
        VStack {
            Button(action: onStart) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(.startBooth)
                        Text(pack.name)
                            .font(.subheadline)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(PeekPrimaryButtonStyle())
            if hasDraft {
                Button(action: onResume) {
                    Label(.resumeDraft, systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(PeekSecondaryButtonStyle())
            }
        }
    }
}
