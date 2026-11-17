import SwiftUI

/// The step before the customer sends a pack: what the file has in it, then the Share button.
/// The pack has video of real people, so the customer reads this each time.
struct PackShareView: View {
    let pack: PosePack
    @Environment(UserPacks.self) private var userPacks
    @Environment(\.dismiss) private var dismiss
    @State private var file: URL?
    @State private var isFailed = false

    var body: some View {
        VStack(alignment: .leading, spacing: PeekTheme.tightSpace * 2) {
            // The text scrolls, so a large text size cuts no word of it.
            ScrollView {
                VStack(alignment: .leading, spacing: PeekTheme.tightSpace * 2) {
                    pack.name.text
                        .font(.title2)
                        .fontWeight(.bold)
                    Label(.sharePackNote, systemImage: "person.2")
                        .font(.body)
                        .foregroundStyle(PeekTheme.inkSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            if isFailed {
                PeekBanner(text: .sharePackFailed, systemImage: "exclamationmark.triangle")
            } else if let file {
                ShareLink(item: file) {
                    Label(.sharePack, systemImage: "square.and.arrow.up")
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
            file = await userPacks.exportFile(packID: pack.id)
            isFailed = file == nil
        }
        .onDisappear {
            // The copy in the temporary folder goes away with the sheet.
            if let file {
                try? FileManager.default.removeItem(at: file.deletingLastPathComponent())
            }
        }
    }
}
