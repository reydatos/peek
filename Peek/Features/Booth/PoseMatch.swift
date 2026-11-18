import Foundation
import Observation
import PeekCore
import UIKit

/// The limits of the pose match. These are provisional design values: the owner sets them on the phone.
enum PoseMatchTuning {
    /// At or above this score, the pose is a match.
    static let matchLimit = 0.8
    /// The automatic shutter starts after the match holds for this time, in seconds.
    static let holdSeconds = 1.0
    /// Below this score, the pose is different, and the review says so.
    static let weakLimit = 0.5
}

/// How near the people are to the pose.
enum MatchLevel: Equatable {
    /// No person is in view, or too little of a person.
    case none
    case different
    case near
    case matched

    init(score: Double?) {
        guard let score else {
            self = .none
            return
        }
        self = score >= PoseMatchTuning.matchLimit ? .matched : score >= PoseMatchTuning.weakLimit ? .near : .different
    }
}

/// The pose match of the booth: the live score while the booth is ready, the automatic shutter, and the score of
/// the shot in review. It compares body shape only. A pose picture with no person in it has no match.
@Observable
final class PoseMatch {
    /// The live match from 0 to 1. Nil when the booth is not ready, or no person is in view.
    private(set) var score: Double?
    /// The match of the shot in review.
    private(set) var reviewScore: Double?
    /// The body shape of the current pose picture. Nil when the picture has no person that the detector finds.
    private(set) var reference: PoseSignature?
    /// The photographer sets this. When the match holds, the booth starts the shot.
    var isAutoShutterOn = false {
        didSet { hold.reset() }
    }

    /// True while a sheet covers the booth. The camera examines no frame then, so a clip recording gets each frame,
    /// and the automatic shutter does not start a shot.
    var isBlocked = false {
        didSet {
            hold.reset()
            syncLive()
        }
    }

    /// Runs when the match has held for the full time.
    var onHold: () -> Void = {}
    /// The last operation. Each operation waits for the one before it, so the camera gets the changes in order.
    private(set) var task: Task<Void, Never>?

    private let capture: any CaptureProviding
    private let analyze: @Sendable (UIImage) async -> PoseSignature?
    private let now: () -> TimeInterval
    /// The signature of each pose picture that the app has examined. Nil for a picture with no person.
    private var references: [String: PoseSignature?] = [:]
    private var cueID: String?
    private var phase = BoothPhase.setup
    private var isCameraRunning = false
    private var isLive = false
    private var reviewedTake: Take.ID?
    private var hold = MatchHold(limit: PoseMatchTuning.matchLimit, duration: PoseMatchTuning.holdSeconds)

    init(
        capture: any CaptureProviding,
        analyze: @escaping @Sendable (UIImage) async -> PoseSignature?,
        now: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
    ) {
        self.capture = capture
        self.analyze = analyze
        self.now = now
    }

    var canMatch: Bool {
        reference != nil
    }

    /// The score that the meter shows: the live match before the shot, and the match of the shot in review.
    /// The outer nil is for a state with no meter. The inner nil is for no person in view.
    var meterScore: Double?? {
        switch phase {
        case .ready: .some(score)
        case .review: .some(reviewScore)
        default: nil
        }
    }

    /// The booth calls this after each change of its state.
    /// - Parameter reviewImage: the shot in review.
    func update(cue: PoseCue?, phase: BoothPhase, isCameraRunning: Bool, reviewImage: UIImage?) {
        self.phase = phase
        self.isCameraRunning = isCameraRunning
        if cue?.id != cueID {
            cueID = cue?.id
            score = nil
            hold.reset()
            reference = cue.flatMap { references[$0.id] ?? nil }
            if let cue, !references.keys.contains(cue.id), let picture = cue.picture {
                examine(picture, of: cue.id)
            }
        }
        syncLive()
        syncReview(image: reviewImage)
    }

    /// The match of a finished shot to its pose, from 0 to 1. Nil when the pose picture has no person that the
    /// detector finds, so the pose has no score. A shot with no person in it scores 0.
    func finalScore(of shot: UIImage, cue: PoseCue) async -> Double? {
        var reference: PoseSignature?
        if let known = references[cue.id] {
            reference = known
        } else if let picture = cue.picture {
            reference = await Self.reference(in: analyze(picture))
            references[cue.id] = .some(reference)
        }
        guard let reference else { return nil }
        let signature = await analyze(shot)
        return signature.flatMap { PoseMatcher.score(reference: reference, live: $0) } ?? 0
    }

    /// The body shape of a pose picture, or nil when it has no person.
    private static func reference(in signature: PoseSignature?) -> PoseSignature? {
        signature.flatMap { $0.bodies.contains { !$0.joints.isEmpty } ? $0 : nil }
    }

    /// Finds the body shape of a pose picture, one time for each pose.
    private func examine(_ picture: UIImage, of id: String) {
        enqueue { [analyze] in
            let found = await Self.reference(in: analyze(picture))
            self.references[id] = .some(found)
            if self.cueID == id {
                self.reference = found
                self.syncLive()
            }
        }
    }

    /// The camera sends body shapes only while the booth is ready and the pose has a reference.
    private func syncLive() {
        let wantsLive = isCameraRunning && phase == .ready && reference != nil && !isBlocked
        if wantsLive != isLive {
            isLive = wantsLive
            var handler: (@Sendable (PoseSignature) -> Void)?
            if wantsLive {
                handler = { [weak self] signature in
                    Task { @MainActor in self?.receive(signature) }
                }
            }
            enqueue { [capture, handler] in await capture.setPoseHandler(handler) }
        }
        if !wantsLive {
            score = nil
            hold.reset()
        }
    }

    private func syncReview(image: UIImage?) {
        guard case let .review(take) = phase else {
            reviewedTake = nil
            reviewScore = nil
            return
        }
        guard reviewedTake != take.id else { return }
        reviewedTake = take.id
        reviewScore = nil
        guard let reference, let image else { return }
        enqueue { [analyze] in
            let signature = await analyze(image)
            guard self.reviewedTake == take.id else { return }
            self.reviewScore = signature.flatMap { PoseMatcher.score(reference: reference, live: $0) }
        }
    }

    /// Takes the body shape of one live frame.
    func receive(_ live: PoseSignature) {
        guard isLive, let reference else { return }
        score = PoseMatcher.score(reference: reference, live: live)
        guard isAutoShutterOn, !isBlocked else { return }
        if hold.update(score: score, at: now()) {
            hold.reset()
            onHold()
        }
    }

    private func enqueue(_ operation: @escaping () async -> Void) {
        task = Task { [task] in
            await task?.value
            await operation()
        }
    }
}
