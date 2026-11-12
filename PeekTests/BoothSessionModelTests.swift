@testable import Peek
import PeekCore
import Testing

struct BoothSessionModelTests {
    /// Waits for the countdown, then for the capture that the last tick starts.
    func settle(_ model: BoothSessionModel) async {
        await model.countdownTask?.value
        await model.captureTask?.value
    }

    @Test func countdownCapturesOnePhotoAndShowsItForReview() async {
        let capture = FakeCapture()
        let model = BoothSessionModel(capture: capture, cueIDs: ["sample"], sleep: { _ in })
        await model.startCamera()
        #expect(model.cameraStatus == .running)
        #expect(model.state.phase == .ready)

        model.send(.start)
        model.send(.start)
        await settle(model)

        guard case let .review(take) = model.state.phase else {
            Issue.record("Expected review, got \(model.state.phase)")
            return
        }
        #expect(take.rotationAngle == 90)
        #expect(model.stillImage != nil)
        #expect(await capture.captureCount == 1)

        model.send(.accept)
        #expect(model.state.phase == .complete)
        #expect(model.stillImage != nil)
    }

    @Test func deniedCameraKeepsTheSessionInSetup() async {
        let model = BoothSessionModel(capture: FakeCapture(startError: .permissionDenied), sleep: { _ in })
        await model.startCamera()
        #expect(model.cameraStatus == .denied)
        #expect(model.state.phase == .setup)
    }

    @Test func failedCaptureDoesNotAdvanceAndOffersRetry() async {
        let model = BoothSessionModel(capture: FakeCapture(captureError: .captureFailed), sleep: { _ in })
        await model.startCamera()
        model.send(.start)
        await settle(model)
        #expect(model.state.phase == .ready)
        #expect(model.state.lastFailure != nil)
        #expect(model.stillImage == nil)
    }

    @Test func outerDisplayLossPausesTheCountdownWithNoCapture() async {
        let capture = FakeCapture()
        let model = BoothSessionModel(capture: capture, sleep: { _ in try await Task.sleep(for: .seconds(3600)) })
        await model.startCamera()
        model.setOuterDisplayAvailable(true)
        model.send(.start)
        model.setOuterDisplayAvailable(false)
        #expect(model.state.phase == .paused(resumeTo: .countdown, reason: .outerDisplayLost))
        #expect(model.countdownTask == nil)
        #expect(await capture.captureCount == 0)
    }

    @Test func acceptMovesToTheNextSlotAndKeepsTheShot() async {
        let model = BoothSessionModel(capture: FakeCapture(), sleep: { _ in })
        await model.startCamera()
        #expect(model.state.slots.count == 4)

        model.send(.start)
        await settle(model)
        model.send(.accept)

        #expect(model.state.phase == .ready)
        #expect(model.state.currentSlotID.index == 1)
        #expect(model.image(for: model.state.slots[0]) != nil)
        #expect(model.image(for: model.state.slots[1]) == nil)
    }
}
