import CoreGraphics
@testable import Peek
import Testing

struct GlamLightTests {
    @Test func theOuterDisplayIsTheLightWhenItShowsTheBooth() {
        #expect(GlamLight.surface(isOuterDisplayPresenting: true, isSelfie: false) == .outer)
    }

    @Test func theInnerDisplayIsTheLightForASelfie() {
        #expect(GlamLight.surface(isOuterDisplayPresenting: false, isSelfie: true) == .inner)
        #expect(GlamLight.surface(isOuterDisplayPresenting: true, isSelfie: true) == .inner)
    }

    @Test func oneScreenWithTheRearCameraHasNoLight() {
        #expect(GlamLight.surface(isOuterDisplayPresenting: false, isSelfie: false) == .none)
    }

    @Test func thePlaceIsDarkBelowTheLimit() {
        #expect(GlamLight.isLowLight(brightnessValue: -1.5))
        #expect(!GlamLight.isLowLight(brightnessValue: -1.0))
        #expect(!GlamLight.isLowLight(brightnessValue: 2))
    }

    @Test func theKeeperSavesTheBrightnessAndGivesItBack() {
        var keeper = BrightnessKeeper()
        #expect(keeper.update(isBright: true, current: 0.4) == 1)
        // A second update keeps the first saved value.
        #expect(keeper.update(isBright: true, current: 1) == nil)
        #expect(keeper.update(isBright: false, current: 1) == 0.4)
        #expect(keeper.saved == nil)
    }

    @Test func theKeeperChangesNothingWhenTheLightWasNeverOn() {
        var keeper = BrightnessKeeper()
        #expect(keeper.update(isBright: false, current: 0.4) == nil)
    }

    @Test func lowLightStartsTheLightOneTime() {
        let model = BoothSessionModel(capture: FakeCapture(), saver: FakeSaver())
        model.reportLowLight()
        #expect(model.isGlamLightOn)
        // The photographer stops the light. A dark place does not start it again in this booth.
        model.setGlamLight(false)
        model.reportLowLight()
        #expect(!model.isGlamLightOn)
    }

    @Test func theInnerLightShowsOnlyForASelfie() async {
        let model = BoothSessionModel(capture: FakeCapture(), saver: FakeSaver())
        await model.startCamera()
        model.setGlamLight(true)
        #expect(!model.showsInnerGlamLight)
        await model.flipCamera()
        #expect(model.showsInnerGlamLight)
    }
}
