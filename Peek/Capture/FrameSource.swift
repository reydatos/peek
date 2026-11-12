import AVFoundation

/// Sends live video frames to one renderer.
///
/// The outer display uses this path. A second `AVCaptureVideoPreviewLayer` showed no picture
/// in the camera capture accessory on a physical iPhone Duo (2026-11-11).
final nonisolated class FrameSource: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    let queue = DispatchQueue(label: "com.a8media.peek.frames")
    private let lock = NSLock()
    private var renderer: AVSampleBufferVideoRenderer?

    func attach(_ renderer: AVSampleBufferVideoRenderer) {
        lock.withLock { self.renderer = renderer }
    }

    func detach(_ renderer: AVSampleBufferVideoRenderer) {
        lock.withLock {
            if self.renderer === renderer {
                self.renderer = nil
            }
        }
    }

    func captureOutput(_: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from _: AVCaptureConnection) {
        guard let renderer = lock.withLock({ self.renderer }) else { return }
        if renderer.status == .failed {
            renderer.flush()
        }
        guard renderer.isReadyForMoreMediaData else { return }
        markForImmediateDisplay(sampleBuffer)
        renderer.enqueue(sampleBuffer)
    }

    /// Live frames have capture-clock timestamps. The renderer must show each frame at once.
    private func markForImmediateDisplay(_ sampleBuffer: CMSampleBuffer) {
        guard
            let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true),
            CFArrayGetCount(attachments) > 0
        else { return }
        let attachment = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0), to: CFMutableDictionary.self)
        CFDictionarySetValue(
            attachment,
            Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
            Unmanaged.passUnretained(kCFBooleanTrue).toOpaque()
        )
    }
}
