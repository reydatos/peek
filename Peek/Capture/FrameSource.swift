import AVFoundation

/// Sends live video frames to one renderer.
///
/// The outer display uses this path. A second `AVCaptureVideoPreviewLayer` showed no picture
/// in the camera capture accessory on a physical iPhone Duo (2026-11-11).
///
/// iOS 27 sends frames through a receiver: the renderer goes to a render synchronizer, and the synchronizer
/// gives the receiver that accepts the frames.
final nonisolated class FrameSource: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    let queue = DispatchQueue(label: "com.a8media.peek.frames")
    private let lock = NSLock()
    private var target: Target?
    /// Runs one time, when a frame shows a dark place.
    private var onLowLight: (@Sendable () -> Void)?
    private var frameCount = 0

    /// One renderer with its synchronizer and its receiver. Each renderer gets its own synchronizer,
    /// so a renderer that goes away takes its synchronizer with it.
    private struct Target {
        let renderer: AVSampleBufferVideoRenderer
        let synchronizer: AVSampleBufferRenderSynchronizer
        let receiver: AVSampleBufferVideoRenderer.Receiver
    }

    func attach(_ renderer: AVSampleBufferVideoRenderer) {
        let synchronizer = AVSampleBufferRenderSynchronizer()
        let receiver = synchronizer.sampleBufferReceiver(adding: renderer)
        // The frames have host-clock timestamps. The timeline runs on the same clock.
        synchronizer.setRate(1, time: CMClockGetTime(CMClockGetHostTimeClock()))
        lock.withLock { target = Target(renderer: renderer, synchronizer: synchronizer, receiver: receiver) }
    }

    func detach(_ renderer: AVSampleBufferVideoRenderer) {
        lock.withLock {
            if target?.renderer === renderer {
                target = nil
            }
        }
    }

    /// Sets the action for a dark place. It runs one time, then the source stops the check.
    func setLowLightHandler(_ handler: @escaping @Sendable () -> Void) {
        lock.withLock { onLowLight = handler }
    }

    /// Reads the brightness of the scene from the metadata of a frame, at each 15th frame, as the Glam app does.
    private func checkLowLight(_ sampleBuffer: CMSampleBuffer) {
        frameCount += 1
        guard frameCount % 15 == 0, lock.withLock({ onLowLight != nil }) else { return }
        guard
            let metadata = CMCopyDictionaryOfAttachments(
                allocator: nil,
                target: sampleBuffer,
                attachmentMode: kCMAttachmentMode_ShouldPropagate
            ) as? [String: Any],
            let exif = metadata["{Exif}"] as? [String: Any],
            let brightness = exif["BrightnessValue"] as? Double,
            GlamLight.isLowLight(brightnessValue: brightness)
        else { return }
        let handler = lock.withLock {
            defer { onLowLight = nil }
            return onLowLight
        }
        handler?()
    }

    func captureOutput(_: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from _: AVCaptureConnection) {
        checkLowLight(sampleBuffer)
        guard let receiver = lock.withLock({ target?.receiver }) else { return }
        markForImmediateDisplay(sampleBuffer)
        // The ready buffer takes the frame. This method does not use the frame after that line.
        nonisolated(unsafe) let frame = sampleBuffer
        // A live frame does not wait: a frame that the receiver cannot take is dropped.
        switch receiver.enqueueImmediately(CMReadySampleBuffer(unsafeBuffer: frame)) {
        case .cancelledDueToFlushRequiredToResume, .cancelledDueToError:
            // The receiver takes frames again after a flush.
            receiver.flush()
        default:
            break
        }
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
