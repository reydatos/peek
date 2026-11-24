import Foundation
@testable import PeekCore
import Testing

struct LayoutTests {
    /// Drafts store the raw value. A change to a raw value would lose the layout of every stored draft.
    @Test func rawValuesStayTheSame() {
        #expect(Layout.verticalStrip.rawValue == "verticalStrip")
        #expect(Layout.grid2x2.rawValue == "grid2x2")
        #expect(Layout.duetRow.rawValue == "duetRow")
        #expect(Layout.duetSingle.rawValue == "duetSingle")
    }

    @Test func onlyTheDuetLayoutsShowThePoses() {
        #expect(Layout.allCases.filter(\.showsPoses) == [.duetRow, .duetSingle])
    }

    @Test func aDraftWithADuetLayoutComesBack() throws {
        let record = SessionRecord(
            templateID: "classic",
            templateVersion: 1,
            countdown: .five,
            layout: .duetSingle,
            slots: [Slot(id: SlotID(0), cueID: "smile", acceptedTake: nil)]
        )
        let data = try JSONEncoder().encode(record)

        #expect(try JSONDecoder().decode(SessionRecord.self, from: data).layout == .duetSingle)
    }
}
