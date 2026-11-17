import PeekCore
import SwiftUI

/// The pack editor: the customer gives the pack a name and records a short clip for each of its four poses.
/// It is a sheet on the photographer's side. The camera of the booth stays on, and the recorder uses it.
///
/// The record screen is a state of this sheet, not a second presentation. A full-screen cover hides the booth
/// view, and the booth stops its camera when it goes away.
struct PackEditorView: View {
    let model: BoothSessionModel
    /// Stores the pack. It gives false when storage refused the pack.
    let onSave: (PackDraft) async -> Bool
    let onCancel: () -> Void
    @State private var draft = PackDraft()
    /// The index of the pose that the customer records now.
    @State private var recordingIndex: Int?
    /// The index of the pose that the customer plays again now.
    @State private var previewIndex: Int?
    @State private var isSaving = false
    @State private var didFail = false
    @ScaledMetric(relativeTo: .body) private var thumbnailWidth = 60

    var body: some View {
        Group {
            if let index = recordingIndex {
                PoseRecorderView(model: model, poseNumber: index + 1) { still, clipURL in
                    draft.setRecording(still: still, clipURL: clipURL, at: index)
                    recordingIndex = nil
                } onCancel: {
                    recordingIndex = nil
                }
            } else if let index = previewIndex, let still = draft.poses[index].still, let clipURL = draft.poses[index].clipURL {
                // The replay is a state of this sheet too, for the same reason as the record screen.
                PosePreviewView(poseNumber: index + 1, still: still, clipURL: clipURL) {
                    previewIndex = nil
                } onRecordAgain: {
                    previewIndex = nil
                    recordingIndex = index
                }
            } else {
                editor
            }
        }
        // A swipe down must not lose four recordings. The customer leaves with Cancel or Save pack.
        .interactiveDismissDisabled()
    }

    private var editor: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    TextField(text: $draft.name) { Text(.packNamePrompt) }
                        .font(.title3)
                        .textInputAutocapitalization(.words)
                        .padding()
                        .background(PeekTheme.surface, in: .rect(cornerRadius: PeekTheme.cardCorner))
                    Text(.recordHint)
                        .font(.subheadline)
                        .foregroundStyle(PeekTheme.inkSecondary)
                    ForEach(draft.poses.indices, id: \.self) { index in
                        row(index)
                    }
                    if didFail {
                        PeekBanner(text: .packNotSaved, systemImage: "exclamationmark.triangle")
                    }
                    Button {
                        Task { await save() }
                    } label: {
                        Label(.savePack, systemImage: "checkmark")
                    }
                    .buttonStyle(PeekPrimaryButtonStyle())
                    .disabled(!draft.isComplete || isSaving)
                    // A gray button with no reason is a dead end. This line says what the pack still needs.
                    if !draft.isComplete {
                        Label(draft.poses.allSatisfy(\.isRecorded) ? .saveNeedsName : .saveNeedsPoses, systemImage: "info.circle")
                            .font(.subheadline)
                            .foregroundStyle(PeekTheme.inkSecondary)
                    }
                }
                .padding()
            }
            .background(PeekTheme.page)
            .foregroundStyle(PeekTheme.ink)
            .navigationTitle(Text(.newPack))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        draft.discard()
                        onCancel()
                    } label: { Text(.cancel) }
                }
            }
        }
    }

    private func row(_ index: Int) -> some View {
        let pose = draft.poses[index]
        return HStack {
            PeekTheme.fill
                .aspectRatio(3 / 4, contentMode: .fit)
                .overlay {
                    if let still = pose.still, let picture = UIImage(data: still) {
                        Image(uiImage: picture)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "figure.stand")
                            .foregroundStyle(PeekTheme.inkSecondary)
                    }
                }
                .clipShape(.rect(cornerRadius: PeekTheme.slotCorner))
                .overlay {
                    // A tap on a recorded pose plays its clip again.
                    if pose.isRecorded {
                        Button { previewIndex = index } label: {
                            Image(systemName: "play.circle.fill")
                                .font(.title)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(PeekTheme.ink, PeekTheme.surface)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(.playClip(index + 1)))
                    }
                }
                .frame(width: thumbnailWidth)
            VStack(alignment: .leading) {
                Text(.poseNumber(index + 1))
                    .font(.caption)
                    .bold()
                    .foregroundStyle(PeekTheme.inkSecondary)
                TextField(text: $draft.poses[index].name) { Text(.poseNamePrompt) }
                    .font(.headline)
            }
            Button { recordingIndex = index } label: {
                Label(pose.isRecorded ? .recordAgain : .recordPose, systemImage: pose.isRecorded ? "arrow.counterclockwise" : "record.circle")
            }
            .buttonStyle(PeekRailButtonStyle())
        }
        .padding(PeekTheme.tightSpace * 2)
        .background(PeekTheme.surface, in: .rect(cornerRadius: PeekTheme.cardCorner))
    }

    private func save() async {
        isSaving = true
        didFail = false
        let didSave = await onSave(draft)
        isSaving = false
        didFail = !didSave
    }
}
