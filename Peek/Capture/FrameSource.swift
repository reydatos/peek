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
    private var frameCount = 0
    /// The recorder of a pose clip. It takes each frame while it records.
    private var recorder: ClipRecorder?
    /// Takes a frame for the pose match.
    private var onPoseFrame: (@Sendable (CMSampleBuffer) -> Void)?

    /// The pose match examines one frame in this number of frames. This is a design value.
    static let poseFrameInterval = 6

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

    /// Sets the action that takes a frame for the pose match. Nil stops it.
    func setPoseFrameHandler(_ handler: (@Sendable (CMSampleBuffer) -> Void)?) {
        lock.withLock { onPoseFrame = handler }
    }

    /// Records a clip of `ClipRecorder.duration` seconds from the next frames, and gives the last frame as JPEG bytes.
    /// - Parameter rotationAngle: the clockwise angle, in degrees, that makes a frame upright.
    /// A cancel of the task stops the recording.
    /// - Parameter isMirrored: true for the front camera, so the clip is a mirror picture as the live view is.
    func record(to url: URL, rotationAngle: CGFloat, isMirrored: Bool = false) async throws -> Data {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let recorder = ClipRecorder(url: url, rotationAngle: rotationAngle, isMirrored: isMirrored) { [weak self] result in
                    self?.lock.withLock { self?.recorder = nil }
                    continuation.resume(with: result)
                }
                // One recording at a time. The check and the change are one step, so two calls can not both pass.
                let isFirst = lock.withLock {
                    guard self.recorder == nil else { return false }
                    self.recorder = recorder
                    return true
                }
                guard isFirst else {
                    continuation.resume(throwing: ClipRecorder.Failure.stopped)
                    return
                }
                // A cancel that came before the recorder was in place found nothing to stop.
                if Task.isCancelled {
                    recorder.stop()
                }
            }
        } onCancel: {
            lock.withLock { recorder }?.stop()
        }
    }

    func captureOutput(_: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from _: AVCaptureConnection) {
        frameCount += 1
        lock.withLock { recorder }?.append(sampleBuffer)
        if frameCount % Self.poseFrameInterval == 0 {
            lock.withLock { onPoseFrame }?(sampleBuffer)
        }
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
