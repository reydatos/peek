@testable import Peek
import Testing
import UIKit

struct PeekFontTests {
    @Test func bundledFontsResolveByTheNamesTheAppUses() {
        PeekFont.register()

        #expect(UIFont(name: PeekFont.serifName, size: 17)?.familyName == "Instrument Serif")
        #expect(UIFont(name: PeekFont.sansName, size: 17)?.familyName == "Inter Tight")
    }
}
