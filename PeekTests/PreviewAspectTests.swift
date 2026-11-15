import CoreGraphics
@testable import Peek
import Testing

struct PreviewAspectTests {
    private let wide: CGFloat = 4.0 / 3.0
    private let tall: CGFloat = 3.0 / 4.0

    @Test func aLevelSensorKeepsItsShape() {
        let level: CGFloat = PreviewAspect.aspect(sensorWidth: 4032, sensorHeight: 3024, rotationAngle: 0)
        let inverted: CGFloat = PreviewAspect.aspect(sensorWidth: 4032, sensorHeight: 3024, rotationAngle: 180)
        #expect(level == wide)
        #expect(inverted == wide)
    }

    @Test func aQuarterTurnExchangesWidthAndHeight() {
        let right: CGFloat = PreviewAspect.aspect(sensorWidth: 4032, sensorHeight: 3024, rotationAngle: 90)
        let left: CGFloat = PreviewAspect.aspect(sensorWidth: 4032, sensorHeight: 3024, rotationAngle: 270)
        #expect(right == tall)
        #expect(left == tall)
    }

    @Test func anUnknownSensorUsesTheFallback() {
        let unknown: CGFloat = PreviewAspect.aspect(sensorWidth: 0, sensorHeight: 0, rotationAngle: 90)
        #expect(unknown == PreviewAspect.fallback)
    }
}
