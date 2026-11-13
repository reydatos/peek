import CoreGraphics
@testable import Peek
import Testing

struct StripPlacementTests {
    let container = CGSize(width: 340, height: 704)
    let aspect: CGFloat = 1200.0 / 3744.0

    @Test func noOcclusionFitsTheFullContainer() {
        let frame = StripPlacement.frame(in: container, avoiding: [], aspect: aspect)
        #expect(abs(frame.height - 704) < 0.01)
        #expect(abs(frame.midX - 170) < 0.01)
    }

    @Test func aTopCornerHousingMovesTheStripClearOfIt() {
        let housing = CGRect(x: 208, y: 0, width: 132, height: 150)
        let frame = StripPlacement.frame(in: container, avoiding: [housing], aspect: aspect)

        #expect(!frame.intersects(housing))
        #expect(CGRect(origin: .zero, size: container).contains(frame))
        #expect(abs(frame.width / frame.height - aspect) < 0.001)
        // The column beside the housing gives a larger strip than the area below it.
        #expect(frame.maxX <= 208.01)
        #expect(abs(frame.width - 208) < 0.01)
    }

    @Test func anOcclusionOutsideTheContainerChangesNothing() {
        let outside = CGRect(x: 400, y: -200, width: 100, height: 100)
        let frame = StripPlacement.frame(in: container, avoiding: [outside], aspect: aspect)
        #expect(abs(frame.height - 704) < 0.01)
    }
}
