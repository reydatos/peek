@testable import PeekCore
import Testing

struct BoothReducerTests {
    let reducer = BoothReducer()

    /// A four-slot session in `ready` with manual capture.
    func readyState(countdown: CountdownLength = .manual) -> BoothState {
        var state = BoothState(cueIDs: ["a", "b", "c", "d"], countdown: countdown)
        _ = reducer.reduce(&state, .finishSetup)
        return state
    }

    func pendingToken(_ state: BoothState) throws -> CaptureToken {
        guard case let .capturePending(token) = state.phase else {
            throw PhaseError(phase: state.phase)
        }
        return token
    }

    /// Starts a manual capture and delivers a take. The state ends in `review`.
    @discardableResult
    func shoot(_ state: inout BoothState) throws -> Take {
        _ = reducer.reduce(&state, .start)
        let token = try pendingToken(state)
        let take = Take(slotID: state.currentSlotID, token: token, assetName: "asset")
        _ = reducer.reduce(&state, .captureSucceeded(token, take))
        return take
    }

    func completedState() throws -> BoothState {
        var state = readyState()
        for _ in state.slots {
            try shoot(&state)
            _ = reducer.reduce(&state, .accept)
        }
        return state
    }

    @Test func swapCueChangesOnlyTheCurrentSlotAndOnlyInReady() {
        var state = readyState()
        _ = reducer.reduce(&state, .swapCue("z"))
        #expect(state.slots.map(\.cueID) == ["z", "b", "c", "d"])

        _ = reducer.reduce(&state, .start)
        _ = reducer.reduce(&state, .swapCue("y"))
        #expect(state.slots.map(\.cueID) == ["z", "b", "c", "d"])
    }

    @Test func fourAcceptedShotsCompleteTheSession() throws {
        let state = try completedState()
        #expect(state.phase == .complete)
        #expect(state.slots.allSatisfy { $0.acceptedTake != nil })
    }

    @Test func countdownTicksDownThenRequestsOneCapture() throws {
        var state = readyState(countdown: .three)
        #expect(reducer.reduce(&state, .start) == [.startCountdown(seconds: 3)])
        #expect(reducer.reduce(&state, .tick).isEmpty)
        #expect(reducer.reduce(&state, .tick).isEmpty)
        #expect(state.phase == .countdown(remaining: 1))
        let effects = reducer.reduce(&state, .tick)
        let token = try pendingToken(state)
        #expect(effects == [.capture(token, SlotID(0))])
    }

    @Test func cancelStopsTheCountdownAndIgnoresLateTicks() {
        var state = readyState(countdown: .five)
        _ = reducer.reduce(&state, .start)
        #expect(reducer.reduce(&state, .cancel) == [.stopCountdown])
        #expect(reducer.reduce(&state, .tick).isEmpty)
        #expect(state.phase == .ready)
    }

    /// PRD QA gate 5: repeated shutter taps and late callbacks.
    @Test func repeatedStartKeepsOnePendingCapture() throws {
        var state = readyState()
        _ = reducer.reduce(&state, .start)
        let token = try pendingToken(state)
        #expect(reducer.reduce(&state, .start).isEmpty)
        #expect(reducer.reduce(&state, .start).isEmpty)
        #expect(try pendingToken(state) == token)
    }

    @Test func duplicateCallbackDoesNotAdvanceOrDiscardTheReviewedTake() throws {
        var state = readyState()
        let take = try shoot(&state)
        #expect(reducer.reduce(&state, .captureSucceeded(take.token, take)).isEmpty)
        #expect(state.phase == .review(take))
        #expect(state.currentSlotID == SlotID(0))
    }

    @Test func staleCallbackIsIgnoredAndItsTakeIsDiscarded() throws {
        var state = readyState()
        _ = reducer.reduce(&state, .start)
        let staleToken = try pendingToken(state)
        _ = reducer.reduce(&state, .pause(.interruption))
        let late = Take(slotID: SlotID(0), token: staleToken, assetName: "late")
        #expect(reducer.reduce(&state, .captureSucceeded(staleToken, late)) == [.discardTake(late)])
        #expect(state.phase == .paused(resumeTo: .ready, reason: .interruption))
        #expect(state.slots[0].acceptedTake == nil)
    }

    @Test func failedCaptureStaysOnTheSlotAndOffersRetry() throws {
        var state = readyState()
        _ = reducer.reduce(&state, .start)
        let token = try pendingToken(state)
        let failure = CaptureFailure(message: "failed")
        _ = reducer.reduce(&state, .captureFailed(token, failure))
        #expect(state.phase == .ready)
        #expect(state.currentSlotID == SlotID(0))
        #expect(state.lastFailure == failure)
        _ = reducer.reduce(&state, .start)
        #expect(state.lastFailure == nil)
        _ = try pendingToken(state)
    }

    @Test func outerDisplayLossPausesTheCountdownUntilAnExplicitResume() {
        var state = readyState(countdown: .three)
        _ = reducer.reduce(&state, .start)
        _ = reducer.reduce(&state, .tick)
        #expect(reducer.reduce(&state, .outerDisplayLost) == [.stopCountdown])
        #expect(state.phase == .paused(resumeTo: .countdown, reason: .outerDisplayLost))
        #expect(reducer.reduce(&state, .tick).isEmpty)
        #expect(reducer.reduce(&state, .resume) == [.startCountdown(seconds: 3)])
        #expect(state.phase == .countdown(remaining: 3))
    }

    @Test func outerDisplayLossOutsideCountdownChangesNothing() {
        var state = readyState()
        #expect(reducer.reduce(&state, .outerDisplayLost).isEmpty)
        #expect(state.phase == .ready)
    }

    /// PRD QA gate 4: retake slot two, cancel, then retake and accept. Verify other slots and undo.
    @Test func cancelledRetakeKeepsThePreviousShot() throws {
        var state = try completedState()
        let before = state.slots
        _ = reducer.reduce(&state, .retake(SlotID(1)))
        _ = reducer.reduce(&state, .cancel)
        #expect(state.phase == .complete)

        _ = reducer.reduce(&state, .retake(SlotID(1)))
        let candidate = try shoot(&state)
        #expect(reducer.reduce(&state, .cancel) == [.discardTake(candidate)])
        #expect(state.phase == .complete)
        #expect(state.slots == before)
    }

    @Test func acceptedRetakeChangesOnlyThatSlotAndUndoRestoresIt() throws {
        var state = try completedState()
        let before = state.slots
        _ = reducer.reduce(&state, .retake(SlotID(1)))
        let replacement = try shoot(&state)
        #expect(reducer.reduce(&state, .accept).isEmpty)
        #expect(state.phase == .complete)
        #expect(state.slots[1].acceptedTake == replacement)
        #expect(state.slots[1].previousTake == before[1].acceptedTake)
        for index in [0, 2, 3] {
            #expect(state.slots[index] == before[index])
        }

        _ = reducer.reduce(&state, .undo(SlotID(1)))
        #expect(state.slots[1].acceptedTake == before[1].acceptedTake)
        #expect(state.slots[1].previousTake == replacement)
    }

    @Test func redoDiscardsTheCandidateAndStaysOnTheSlot() throws {
        var state = readyState()
        let candidate = try shoot(&state)
        #expect(reducer.reduce(&state, .redo) == [.discardTake(candidate)])
        #expect(state.phase == .ready)
        #expect(state.currentSlotID == SlotID(0))
        #expect(state.slots[0].acceptedTake == nil)
    }
}

struct PhaseError: Error {
    let phase: BoothPhase
}
