import CoreGraphics
@testable import Peek
import Testing
import UIKit

struct PictureEdgeTests {
    let size = CGSize(width: 300, height: 400)

    @Test func eachEdgeIsOneLineOfPixels() {
        #expect(PictureEdge.left.rect(in: size) == CGRect(x: 0, y: 0, width: 1, height: 400))
        #expect(PictureEdge.right.rect(in: size) == CGRect(x: 299, y: 0, width: 1, height: 400))
        #expect(PictureEdge.top.rect(in: size) == CGRect(x: 0, y: 0, width: 300, height: 1))
        #expect(PictureEdge.bottom.rect(in: size) == CGRect(x: 0, y: 399, width: 300, height: 1))
    }

    @Test func theStripOfAPictureHasTheSizeOfItsEdge() {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        let left = PictureEdge.left.strip(of: image)
        #expect(left?.cgImage?.width == 1)
        #expect(left?.cgImage?.height == 400)
        let top = PictureEdge.top.strip(of: image)
        #expect(top?.cgImage?.width == 300)
        #expect(top?.cgImage?.height == 1)
    }

    @Test func aStudioBackgroundIsPlainAndAStreetIsNot() throws {
        // The limit is a design value. This test holds it between the two kinds of pose pictures.
        let kids = try #require(PoseLibrary.packs.first { $0.id == "kidsPoses" }?.cues.first)
        let classic = try #require(PoseLibrary.packs.first { $0.id == PoseLibrary.classicID }?.cues.first)
        let street = try #require(PoseLibrary.packs.first { $0.id == "streetStyle" }?.cues.first)
        let cartoon = try #require(UIImage(named: kids.assetName))
        let toys = try #require(UIImage(named: classic.assetName))
        let photo = try #require(UIImage(named: street.assetName))
        #expect(PictureEdge.left.isPlain(in: cartoon))
        #expect(PictureEdge.left.isPlain(in: toys))
        #expect(!PictureEdge.left.isPlain(in: photo))
    }

    @Test func aWidePictureIsWiderThanTall() throws {
        // The wide copy of a photo pose picture covers the outer display. The person is at its right.
        let cue = try #require(PoseLibrary.packs.first { $0.id == "streetStyle" }?.cues.first)
        let wide = try #require(UIImage(named: cue.wideAssetName))
        #expect(wide.size.width > wide.size.height)
    }

    @Test func eachClassicPosePictureFillsTheOuterDisplay() throws {
        // Owner rule (2026-11-15): each pose idea picture covers the outer display. A classic picture does this
        // with plain edges at the left and at the right, so its background continues to the edges of the display.
        let classic = try #require(PoseLibrary.packs.first { $0.id == PoseLibrary.classicID })
        #expect(classic.cues.count == 4)
        for cue in classic.cues {
            let picture = try #require(UIImage(named: cue.assetName), "\(cue.id) has no picture")
            #expect(PictureEdge.left.isPlain(in: picture), "\(cue.id): the left edge is not plain")
            #expect(PictureEdge.right.isPlain(in: picture), "\(cue.id): the right edge is not plain")
        }
    }
}
