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

    @Test func aRightAlignedPictureIsAtTheRightEdge() {
        // A 3:4 picture on a display that is wider than 3:4: the spare width is at the left.
        let display = CGSize(width: 600, height: 600)
        let frame = StripPlacement.frame(in: display, avoiding: [], aspect: 3 / 4, isRightAligned: true)

        #expect(abs(frame.height - 600) < 0.01)
        #expect(abs(frame.width - 450) < 0.01)
        #expect(abs(frame.maxX - 600) < 0.01)
    }

    @Test func aCoverAtTheLeftMovesTheRightAlignedPictureClearOfIt() {
        let display = CGSize(width: 600, height: 600)
        let cover = CGRect(x: 0, y: 0, width: 200, height: 600)
        let frame = StripPlacement.frame(in: display, avoiding: [cover], aspect: 3 / 4, isRightAligned: true)

        #expect(!frame.intersects(cover))
        #expect(abs(frame.maxX - 600) < 0.01)
        #expect(abs(frame.width - 400) < 0.01)
    }

    @Test func theFreeAreaIsTheLargestAreaThatNothingCovers() {
        let display = CGSize(width: 600, height: 600)
        #expect(StripPlacement.freeArea(in: display, avoiding: []) == CGRect(x: 0, y: 0, width: 600, height: 600))

        let cover = CGRect(x: 0, y: 0, width: 200, height: 600)
        #expect(StripPlacement.freeArea(in: display, avoiding: [cover]) == CGRect(x: 200, y: 0, width: 400, height: 600))
    }
}
