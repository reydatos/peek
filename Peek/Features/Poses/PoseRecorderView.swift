import SwiftUI

/// The record screen of one pose: the live camera, a countdown, a clip of five seconds, then the result.
///
/// It shows the one preview view of the booth. When it goes away it gives the preview back.
struct PoseRecorderView: View {
    let model: BoothSessionModel
    let poseNumber: Int
    /// The customer uses the recording: the JPEG bytes of the last frame, and the clip file.
    let onUse: (Data, URL) -> Void
    let onCancel: () -> Void
    @State private var recording: PoseRecording
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(model: BoothSessionModel, poseNumber: Int, onUse: @escaping (Data, URL) -> Void, onCancel: @escaping () -> Void) {
        self.model = model
        self.poseNumber = poseNumber
        self.onUse = onUse
        self.onCancel = onCancel
        _recording = State(initialValue: PoseRecording(capture: model.capture))
    }

    var body: some View {
        VStack {
            HStack {
                Text(.poseNumber(poseNumber))
                    .font(.headline)
                Spacer()
                Button {
                    recording.cancel()
                    onCancel()
                } label: {
                    PeekIconLabel(text: .close, systemImage: "xmark")
                }
            }
            picture
                .aspectRatio(3 / 4, contentMode: .fit)
                .clipShape(.rect(cornerRadius: PeekTheme.photoCorner))
                .overlay { status }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            controls
        }
        .padding()
        .foregroundStyle(PeekTheme.ink)
        .background(PeekTheme.page)
        .onDisappear {
            recording.cancel()
            model.preview.release()
        }
    }

    /// The live camera. After the recording: the clip, above its last frame. With Reduce Motion on, the last frame only.
    @ViewBuilder private var picture: some View {
        if recording.phase == .done, let still = recording.still {
            PoseClipPicture(still: still, clipURL: reduceMotion ? nil : recording.clipURL)
                .accessibilityElement()
                .accessibilityLabel(Text(.capturedPhoto))
        } else {
            CameraPreviewView(
                session: model.capture.session,
                holder: model.preview,
                deviceID: model.deviceID,
                isMirrored: model.isSelfie,
                generation: model.preview.generation,
                isBorrower: true
            )
            .accessibilityLabel(Text(.livePreview))
        }
    }

    /// The countdown numeral, or the progress of the clip, on a card over the picture.
    @ViewBuilder private var status: some View {
        switch recording.phase {
        case let .countdown(remaining):
            CountdownView(remaining: remaining, total: 3, isLarge: true)
                .padding()
                .background(PeekTheme.surface, in: .rect(cornerRadius: PeekTheme.cardCorner))
        case .recording:
            VStack {
                Spacer()
                if let start = recording.recordingStart {
                    ProgressView(timerInterval: start ... start.addingTimeInterval(ClipRecorder.duration), countsDown: false) {
                        Label(.recordingPose, systemImage: "record.circle.fill")
                            .font(.headline)
                    }
                    .tint(PeekTheme.red)
                    .padding()
                    .background(PeekTheme.surface, in: .rect(cornerRadius: PeekTheme.cardCorner))
                    .padding()
                }
            }
        case .ready, .done, .failed:
            EmptyView()
        }
    }

    @ViewBuilder private var controls: some View {
        switch recording.phase {
        case .ready:
            Text(.recordHint)
                .font(.subheadline)
                .foregroundStyle(PeekTheme.inkSecondary)
            HStack {
                // The front camera lets a person record their own pose, with the view as a mirror.
                FlipCameraButton(model: model)
                Button { recording.start() } label: {
                    Label(.recordPose, systemImage: "record.circle")
                }
                .buttonStyle(PeekPrimaryButtonStyle())
            }
        case .countdown, .recording:
            Button(role: .cancel) { recording.cancel() } label: {
                Label(.cancel, systemImage: "xmark")
            }
            .buttonStyle(PeekSecondaryButtonStyle())
        case .done:
            HStack {
                Button { recording.start() } label: {
                    Label(.recordAgain, systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(PeekSecondaryButtonStyle())
                Button {
                    if let result = recording.takeResult() {
                        onUse(result.still, result.clipURL)
                    }
                } label: {
                    Label(.usePose, systemImage: "checkmark")
                }
                .buttonStyle(PeekPrimaryButtonStyle())
            }
        case .failed:
            PeekBanner(text: .recordFailed, systemImage: "exclamationmark.triangle")
            Button { recording.start() } label: {
                Label(.recordAgain, systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(PeekPrimaryButtonStyle())
        }
    }
}
