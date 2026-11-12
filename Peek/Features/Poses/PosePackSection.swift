import SwiftUI

/// One pack in the pose browser: its four poses and a start button.
struct PosePackSection: View {
    let pack: PosePack
    let onSelect: (PosePack) -> Void

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
            .listRowBackground(PeekTheme.ink)
            Button { onSelect(pack) } label: {
                Label(.startWithPack, systemImage: "camera")
            }
            .buttonStyle(PeekPrimaryButtonStyle())
            .listRowBackground(PeekTheme.ink)
        } header: {
            HStack {
                Text(pack.name)
                    .font(.title2)
                    .fontDesign(.serif)
                    .textCase(nil)
                    .foregroundStyle(PeekTheme.cream)
                Spacer()
                Text(pack.isFree ? .free : .preview)
                    .modifier(PeekSectionLabel())
            }
        }
    }
}
