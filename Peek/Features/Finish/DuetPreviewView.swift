import SwiftUI

/// The finished duet video, before it goes anywhere: it plays again and again, with Share, Save, and Close.
///
/// It is a state of the booth, not a sheet or a push: the system shows the outer display only while the booth is
/// onscreen (owner request, 2026-11-21).
struct DuetPreviewView: View {
    let model: BoothSessionModel
    let url: URL
    @State private var isWide = false

    var body: some View {
        let layout = isWide
            ? AnyLayout(HStackLayout(spacing: PeekTheme.tightSpace * 3))
            : AnyLayout(VStackLayout(spacing: PeekTheme.tightSpace * 3))
        layout {
            // The complete video, with its sound.
            PoseClipView(url: url, showsAll: true, isMuted: false)
                .aspectRatio(DuetVideo.size.width / DuetVideo.size.height, contentMode: .fit)
                .background(PeekTheme.cameraChrome)
                .clipShape(.rect(cornerRadius: PeekTheme.cardCorner))
                .accessibilityElement()
                .accessibilityLabel(Text(.duetPreviewTitle))
            controls
                .frame(maxWidth: isWide ? PeekTheme.railWidth : .infinity)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PeekTheme.page)
        .foregroundStyle(PeekTheme.ink)
        .onGeometryChange(for: Bool.self) { $0.size.width > $0.size.height } action: { isWide = $0 }
    }

    private var controls: some View {
        // The words scroll, so a large text size cuts none of them.
        ScrollView {
            VStack(alignment: .leading, spacing: PeekTheme.tightSpace * 2) {
                Text(.duetPreviewTitle)
                    .font(.title2)
                    .bold()
                // The video shows real people, so the customer reads this before sharing.
                Label(.duetShareNote, systemImage: "person.2")
                    .font(.footnote)
                    .foregroundStyle(PeekTheme.inkSecondary)
                SaveStatusLabel(status: model.saveStatus)
                ShareLink(item: url, preview: SharePreview(Text(.duetPreviewTitle))) {
                    Label(.shareDuet, systemImage: "square.and.arrow.up")
                }
                .buttonStyle(PeekPrimaryButtonStyle())
                Button { Task { await model.saveDuetPreview() } } label: {
                    Label(.saveDuet, systemImage: "square.and.arrow.down")
                }
                .buttonStyle(PeekSecondaryButtonStyle())
                .disabled(model.saveStatus == .saving || model.saveStatus == .saved)
                Button { model.closeDuetPreview() } label: {
                    Text(.close)
                }
                .buttonStyle(PeekSecondaryButtonStyle())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollBounceBehavior(.basedOnSize)
    }
}
