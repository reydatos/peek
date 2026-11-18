import SwiftUI

/// The button that sends the finished picture together with the pose pack, so a friend can try the same poses.
/// It shows only for a pack of the customer: a built-in pack is on each phone already.
struct ChallengeShareButton<Style: ButtonStyle>: View {
    let model: BoothSessionModel
    let style: Style
    @Environment(UserPacks.self) private var userPacks: UserPacks?
    @State private var isSharing = false

    var body: some View {
        if userPacks != nil, let pack = model.pack, pack.category == .mine, model.strip != nil {
            Button { isSharing = true } label: {
                Label(.shareChallenge, systemImage: "person.2.badge.plus")
            }
            .buttonStyle(style)
            .sheet(isPresented: $isSharing) {
                ChallengeShareView(model: model, pack: pack)
            }
        }
    }
}

/// The step before the customer sends a challenge: what the two files have in them, then the Share button.
/// The pack has video of real people, so the customer reads this each time.
struct ChallengeShareView: View {
    let model: BoothSessionModel
    let pack: PosePack
    @Environment(UserPacks.self) private var userPacks: UserPacks?
    @Environment(\.dismiss) private var dismiss
    @State private var files: [URL]?
    @State private var isFailed = false

    var body: some View {
        VStack(alignment: .leading, spacing: PeekTheme.tightSpace * 2) {
            // The text scrolls, so a large text size cuts no word of it.
            ScrollView {
                VStack(alignment: .leading, spacing: PeekTheme.tightSpace * 2) {
                    Text(.challengeTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                    pack.name.text
                        .font(.headline)
                    Label(.challengeNote, systemImage: "person.2")
                        .font(.body)
                        .foregroundStyle(PeekTheme.inkSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            if isFailed {
                PeekBanner(text: .sharePackFailed, systemImage: "exclamationmark.triangle")
            } else if let files {
                ShareLink(items: files, message: message) {
                    Label(.shareChallenge, systemImage: "square.and.arrow.up")
                }
                .buttonStyle(PeekPrimaryButtonStyle())
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity)
            }
            Button(role: .cancel) { dismiss() } label: { Text(.cancel) }
                .buttonStyle(PeekSecondaryButtonStyle())
        }
        .padding()
        .foregroundStyle(PeekTheme.ink)
        .background(PeekTheme.page)
        .presentationDetents([.medium, .large])
        .task {
            if let strip = model.strip?.jpegData(compressionQuality: 1) {
                files = await userPacks?.challengeFiles(strip: strip, packID: pack.id)
            }
            isFailed = files == nil
        }
        .onDisappear {
            // The copies in the temporary folder go away with the sheet.
            if let folder = files?.first?.deletingLastPathComponent() {
                try? FileManager.default.removeItem(at: folder)
            }
        }
    }

    /// The words that go with the files. They have the score only when the picture shows it.
    private var message: Text {
        if model.showsMatchStamp, let percent = model.matchPercent {
            Text(.challengeMessageScore(BoothSessionModel.percentText(percent)))
        } else {
            Text(.challengeMessage)
        }
    }
}
