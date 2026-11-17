import Foundation
import Observation
import PeekCore

/// The recording of one pose clip: a countdown, then the clip, then the result.
@Observable
final class PoseRecording {
    enum Phase: Equatable {
        case ready
        /// The seconds that remain before the clip starts.
        case countdown(Int)
        case recording
        case done
        case failed
    }

    private(set) var phase = Phase.ready
    /// The JPEG bytes of the last frame of the clip.
    private(set) var still: Data?
    private(set) var clipURL: URL?
    /// The time at which the clip started. The progress bar of the recording uses it.
    private(set) var recordingStart: Date?
    private(set) var task: Task<Void, Never>?

    private let capture: any CaptureProviding
    private let sleep: @Sendable (Duration) async throws -> Void

    init(
        capture: any CaptureProviding,
        sleep: @escaping @Sendable (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) {
        self.capture = capture
        self.sleep = sleep
    }

    /// Starts the countdown and then the clip. The countdown has the length of the short booth countdown.
    func start() {
        guard phase == .ready || phase == .done || phase == .failed else { return }
        discardClip()
        task = Task {
            for remaining in (1 ... CountdownLength.three.seconds).reversed() {
                phase = .countdown(remaining)
                // After a cancel, this task changes nothing: `cancel()` set the state, and a new recording can run.
                do { try await sleep(.seconds(1)) } catch { return }
                guard !Task.isCancelled else { return }
            }
            let url = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).mov")
            recordingStart = .now
            phase = .recording
            do {
                let still = try await capture.recordClip(to: url)
                guard !Task.isCancelled else {
                    try? FileManager.default.removeItem(at: url)
                    return
                }
                self.still = still
                clipURL = url
                phase = .done
            } catch {
                try? FileManager.default.removeItem(at: url)
                if !Task.isCancelled {
                    phase = .failed
                }
            }
        }
    }

    /// Stops the countdown or the clip. The screen is ready for a new recording.
    func cancel() {
        task?.cancel()
        task = nil
        discardClip()
        phase = .ready
    }

    /// Gives the result to the caller, who then owns the clip file.
    func takeResult() -> (still: Data, clipURL: URL)? {
        guard phase == .done, let still, let clipURL else { return nil }
        self.still = nil
        self.clipURL = nil
        return (still, clipURL)
    }

    private func discardClip() {
        if let clipURL {
            try? FileManager.default.removeItem(at: clipURL)
        }
        clipURL = nil
        still = nil
    }
}
