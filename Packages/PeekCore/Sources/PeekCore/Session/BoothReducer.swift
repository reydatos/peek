/// The one authority for slot, countdown, capture token, review, and acceptance state.
///
/// The reducer is pure. It has no timers and no I/O. The app layer runs the returned effects
/// and sends the results back as events.
public struct BoothReducer: Sendable {
    private let makeToken: @Sendable () -> CaptureToken

    public init(makeToken: @escaping @Sendable () -> CaptureToken = { CaptureToken() }) {
        self.makeToken = makeToken
    }

    public func reduce(_ state: inout BoothState, _ event: BoothEvent) -> [BoothEffect] {
        switch (state.phase, event) {
        case (.setup, .finishSetup):
            // Only a restored draft has an accepted take in setup. It shows the finished picture,
            // or it waits for an explicit resume.
            guard state.slots.contains(where: { $0.acceptedTake != nil }) else {
                state.phase = .ready
                return []
            }
            state.advance()
            if state.phase == .ready {
                state.phase = .paused(resumeTo: .ready, reason: .recovered)
            }
            return []

        case let (.ready, .swapCue(cueID)):
            state.slots[state.currentSlotID.index].cueID = cueID
            return []

        case (.ready, .start):
            state.lastFailure = nil
            return begin(&state)

        case let (.countdown(remaining), .tick):
            guard remaining > 1 else { return requestCapture(&state) }
            state.phase = .countdown(remaining: remaining - 1)
            return []

        case (.countdown, .cancel):
            state.phase = .ready
            return [.stopCountdown]

        case let (.ready, .pause(reason)):
            state.phase = .paused(resumeTo: .ready, reason: reason)
            return []

        case let (.countdown, .pause(reason)):
            state.phase = .paused(resumeTo: .countdown, reason: reason)
            return [.stopCountdown]

        case (.countdown, .outerDisplayLost):
            state.phase = .paused(resumeTo: .countdown, reason: .outerDisplayLost)
            return [.stopCountdown]

        case let (.capturePending, .pause(reason)):
            // The pending token is dropped. A late callback is stale and its take is discarded.
            state.phase = .paused(resumeTo: .ready, reason: reason)
            return []

        case (.paused(resumeTo: .ready, reason: _), .resume):
            state.phase = .ready
            return []

        case (.paused(resumeTo: .countdown, reason: _), .resume):
            return begin(&state)

        case let (.capturePending(pending), .captureSucceeded(token, take)) where token == pending:
            state.phase = .review(take)
            return []

        case let (_, .captureSucceeded(_, take)):
            return state.references(take) ? [] : [.discardTake(take)]

        case let (.capturePending(pending), .captureFailed(token, failure)) where token == pending:
            state.lastFailure = failure
            state.phase = .ready
            return []

        case let (.review(take), .accept):
            let dropped = state.accept(take)
            state.advance()
            return dropped.map { [.discardTake($0)] } ?? []

        case let (.review(take), .redo):
            state.phase = .ready
            return [.discardTake(take)]

        case let (.review(take), .cancel):
            state.advance()
            return [.discardTake(take)]

        case (.ready, .cancel) where state.currentSlot.acceptedTake != nil:
            state.advance()
            return []

        case let (.ready, .retake(id)), let (.complete, .retake(id)):
            guard state.slots.indices.contains(id.index) else { return [] }
            state.currentSlotID = id
            state.phase = .ready
            return []

        case let (.ready, .undo(id)), let (.complete, .undo(id)):
            state.undo(id)
            return []

        default:
            return []
        }
    }

    private func begin(_ state: inout BoothState) -> [BoothEffect] {
        guard state.countdown != .manual else { return requestCapture(&state) }
        state.phase = .countdown(remaining: state.countdown.seconds)
        return [.startCountdown(seconds: state.countdown.seconds)]
    }

    private func requestCapture(_ state: inout BoothState) -> [BoothEffect] {
        let token = makeToken()
        state.phase = .capturePending(token)
        return [.capture(token, state.currentSlotID)]
    }
}
