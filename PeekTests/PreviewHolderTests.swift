import AVFoundation
@testable import Peek
import Testing
import UIKit

@MainActor struct PreviewHolderTests {
    @Test func theHolderGivesOnePreviewViewForASession() {
        let holder = PreviewHolder()
        let session = AVCaptureSession()
        let first = holder.view(for: session)
        let second = holder.view(for: session)
        #expect(first === second)
        #expect(first.previewLayer.session === session)
    }

    @Test func aNewContainerTakesThePreviewFromTheOldOne() {
        let holder = PreviewHolder()
        let session = AVCaptureSession()
        let preview = holder.view(for: session)
        let tall = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 400))
        let wide = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 300))
        tall.addSubview(preview)
        // The wide layout takes the same view. The session gets no new preview layer.
        let again = holder.view(for: session)
        again.frame = wide.bounds
        wide.addSubview(again)
        #expect(tall.subviews.isEmpty)
        #expect(wide.subviews.first === preview)
        #expect(preview.previewLayer.session === session)
    }
}
