import SwiftUI

/// One pack in the pose browser: its four poses and a start button.
struct PosePackSection: View {
    let pack: PosePack

    var body: some View {
        Section {
            HStack(alignment: .top) {
                ForEach(pack.cues) { cue in
                    VStack {
                        PoseArt(cue: cue)
                        Text(cue.name)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            NavigationLink(value: HomeRoute.booth(packID: pack.id)) {
                Label(.startWithPack, systemImage: "camera")
            }
        } header: {
            HStack {
                Text(pack.name)
                Spacer()
                Text(pack.isFree ? .free : .preview)
            }
        }
    }
}
