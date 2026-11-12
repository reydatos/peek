import Observation
import PeekCore
import UIKit

/// The one model that drives both displays. The outer accessory reads the same instance.
@Observable
final class BoothSessionModel {
    private(set) var state: BoothState
    private(set) var cameraStatus: CameraStatus = .idle
    private(set) var deviceID: String?
    private(set) var isOuterDisplayAvailable = false
    var isOuterDisplayEnabled = true
    /// PRD open decision: default mirroring. Off until hardware tests decide.
    var isOuterPreviewMirrored = false

    private(set) var countdownTask: Task<Void, Never>?
    private(set) var captureTask: Task<Void, Never>?

    let capture: any CaptureProviding
    private var images: [Take.ID: UIImage] = [:]
    private let reducer = BoothReducer()
    private let sleep: @Sendable (Duration) async throws -> Void

    init(
        capture: any CaptureProviding,
        cueIDs: [String] = PoseLibrary.cueIDs(forPack: PoseLibrary.classicID),
        sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) {
        self.capture = capture
        self.sleep = sleep
        state = BoothState(cueIDs: cueIDs)
    }

    /// Starts a new four-shot session with the poses of a pack. The shots of the old session are discarded.
    func loadPack(_ packID: String) {
        countdownTask?.cancel()
        captureTask?.cancel()
        images.removeAll()
        state = BoothState(cueIDs: PoseLibrary.cueIDs(forPack: packID), countdown: state.countdown)
        if cameraStatus == .running {
            send(.finishSetup)
        }
    }

    /// The pose of the current slot. Nil when the cue ID is not in the library.
    var currentCue: PoseCue? {
        PoseLibrary.cue(for: state.currentSlot.cueID)
    }

    /// The accepted shot of a slot, for the slot rail.
    func image(for slot: Slot) -> UIImage? {
        slot.acceptedTake.flatMap { images[$0.id] }
    }

    var countdown: CountdownLength {
        get { state.countdown }
        set { state.countdown = newValue }
    }

    /// True when the system shows the accessory on the outer display.
    var isOuterDisplayPresenting: Bool {
        isOuterDisplayAvailable && isOuterDisplayEnabled
    }

    /// The still to show in place of the live frame: the take in review, or the accepted take when complete.
    var stillImage: UIImage? {
        switch state.phase {
        case let .review(take): images[take.id]
        case .complete: state.currentSlot.acceptedTake.flatMap { images[$0.id] }
        default: nil
        }
    }

    func startCamera() async {
        guard cameraStatus == .idle else { return }
        cameraStatus = .starting
        do {
            deviceID = try await capture.start()
            cameraStatus = .running
            send(.finishSetup)
        } catch let error as CaptureError {
            cameraStatus = CameraStatus(error)
        } catch {
            cameraStatus = .failed
        }
    }

    func stopCamera() {
        send(.pause(.interruption))
        cameraStatus = .idle
        Task { [capture] in await capture.stop() }
    }

    func setOuterDisplayAvailable(_ isAvailable: Bool) {
        let wasPresenting = isOuterDisplayPresenting
        isOuterDisplayAvailable = isAvailable
        if wasPresenting, !isOuterDisplayPresenting {
            send(.outerDisplayLost)
        }
    }

    func send(_ event: BoothEvent) {
        for effect in reducer.reduce(&state, event) {
            run(effect)
        }
    }

    private func run(_ effect: BoothEffect) {
        switch effect {
        case let .startCountdown(seconds):
            countdownTask?.cancel()
            countdownTask = Task { [sleep] in
                for _ in 0 ..< seconds {
                    do { try await sleep(.seconds(1)) } catch { return }
                    guard !Task.isCancelled else { return }
                    send(.tick)
                }
            }

        case .stopCountdown:
            countdownTask?.cancel()
            countdownTask = nil

        case let .capture(token, slotID):
            captureTask = Task {
                do {
                    let photo = try await capture.capturePhoto()
                    guard let image = UIImage(data: photo.data) else { throw CaptureError.captureFailed }
                    let take = Take(
                        slotID: slotID,
                        token: token,
                        assetName: token.rawValue.uuidString,
                        rotationAngle: photo.rotationAngle
                    )
                    images[take.id] = image
                    send(.captureSucceeded(token, take))
                } catch {
                    send(.captureFailed(token, CaptureFailure(message: String(describing: error))))
                }
            }

        case let .discardTake(take):
            images[take.id] = nil
        }
    }
}
