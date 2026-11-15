import CoreGraphics
@testable import Peek
import Testing

struct RailClearanceTests {
    let rail = CGSize(width: 150, height: 700)

    @Test func noOcclusionGivesNoSpace() {
        #expect(RailClearance.top(railSize: rail, occlusions: []) == 0)
    }

    @Test func aHousingInTheTopCornerMovesTheRailBelowIt() {
        let housing = CGRect(x: 100, y: -10, width: 40, height: 54)
        #expect(RailClearance.top(railSize: rail, occlusions: [housing]) == 44)
    }

    @Test func anOcclusionOutsideTheRailGivesNoSpace() {
        let fold = CGRect(x: -300, y: 0, width: 20, height: 700)
        #expect(RailClearance.top(railSize: rail, occlusions: [fold]) == 0)
    }

    @Test func anOcclusionLowerOnTheRailGivesNoSpace() {
        let low = CGRect(x: 100, y: 300, width: 40, height: 40)
        #expect(RailClearance.top(railSize: rail, occlusions: [low]) == 0)
    }
}
