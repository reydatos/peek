import AVFoundation

nonisolated extension DuetVideo {
    /// One sound of the video at a time from its start.
    struct Cue: Equatable {
        enum Kind: Equatable {
            /// A countdown beep: one for each second before the shot.
            case beep
            /// The shutter click at the flash.
            case shutter
            /// The pop of the score at the end of its count.
            case pop
        }

        let kind: Kind
        /// Seconds from the start of the video.
        let time: Double
    }

    /// The sounds of a video with these poses, in the order of time.
    ///
    /// - Parameters:
    ///   - intro: true when the video starts with the intro card.
    ///   - clipFrames: the number of frames of the clip part of each pose.
    ///   - percents: the score of each pose; a pose with no score has no pop.
    static func cues(intro: Bool, clipFrames: [Int], percents: [Int?]) -> [Cue] {
        let fps = Double(framesPerSecond)
        var cues: [Cue] = []
        var cursor = intro ? frames(Timing.intro) : 0
        for (clip, percent) in zip(clipFrames, percents) {
            cursor += frames(Timing.title)
            let start = Double(cursor) / fps
            let end = Double(cursor + clip) / fps
            // The clip has the length of the countdown and ends at the shot, so the beeps count back from its end:
            // "3, 2, 1" at 3, 2 and 1 seconds before the shot. A clip that lost its start loses its first beeps.
            let seconds = Int((end - start).rounded())
            if seconds > 0 {
                for back in stride(from: seconds, through: 1, by: -1) where end - Double(back) >= start - 0.001 {
                    cues.append(Cue(kind: .beep, time: end - Double(back)))
                }
            }
            cursor += clip
            cues.append(Cue(kind: .shutter, time: Double(cursor) / fps))
            if percent != nil {
                cues.append(Cue(kind: .pop, time: Double(cursor) / fps + Timing.flash + Timing.countUp))
            }
            cursor += frames(Timing.flash + Timing.freeze)
        }
        return cues
    }

    /// The sound track of the video, made from the cues: original sounds that the app makes, so no file and no
    /// microphone is needed. The mix is quiet, so music that a customer adds later stays on top.
    enum Sound {
        static let sampleRate = 44100

        // Design values (owner approved the three sounds and a quiet mix, 2026-11-21).
        static let beepFrequency = 880.0
        static let beepLength = 0.12
        static let beepLevel: Float = 0.25
        static let clickLength = 0.03
        /// The second click of the shutter, after the first, as a camera has.
        static let secondClick = 0.05
        static let clickLevel: Float = 0.35
        static let popLength = 0.09
        static let popFrom = 400.0
        static let popTo = 900.0
        static let popLevel: Float = 0.3

        /// The samples of a track of this length: 16-bit, one channel.
        static func track(cues: [Cue], seconds: Double) -> [Int16] {
            var mix = [Float](repeating: 0, count: max(0, Int(seconds * Double(sampleRate))))
            for cue in cues {
                let start = Int(cue.time * Double(sampleRate))
                for (offset, value) in sound(cue.kind).enumerated() where start + offset >= 0 && start + offset < mix.count {
                    mix[start + offset] += value
                }
            }
            return mix.map { Int16(max(-1, min(1, $0)) * Float(Int16.max)) }
        }

        /// The samples of one sound, from -1 to 1.
        static func sound(_ kind: Cue.Kind) -> [Float] {
            let rate = Double(sampleRate)
            switch kind {
            case .beep:
                return (0 ..< Int(beepLength * rate)).map { index in
                    let time = Double(index) / rate
                    return beepLevel * envelope(time, length: beepLength) * Float(sin(2 * .pi * beepFrequency * time))
                }
            case .shutter:
                // Two short bursts of noise. The noise has a fixed seed, so the track is the same each time.
                var seed: UInt32 = 0x9E37_79B9
                let total = Int((secondClick + clickLength) * rate)
                return (0 ..< total).map { index in
                    seed = seed &* 1_664_525 &+ 1_013_904_223
                    let noise = Float(Int32(bitPattern: seed)) / Float(Int32.max)
                    let time = Double(index) / rate
                    let first = time < clickLength ? envelope(time, length: clickLength) : 0
                    let second = time >= secondClick ? envelope(time - secondClick, length: clickLength) * 0.7 : 0
                    return clickLevel * noise * (first + second)
                }
            case .pop:
                // A quick rise in pitch.
                var phase = 0.0
                return (0 ..< Int(popLength * rate)).map { index in
                    let time = Double(index) / rate
                    phase += 2 * .pi * (popFrom + (popTo - popFrom) * time / popLength) / rate
                    return popLevel * envelope(time, length: popLength) * Float(sin(phase))
                }
            }
        }

        /// A fast start and a smooth end, so a sound does not click at its edges.
        private static func envelope(_ time: Double, length: Double) -> Float {
            let attack = 0.005
            guard time >= 0, time < length else { return 0 }
            let rise = min(1, time / attack)
            return Float(rise * exp(-4 * time / length))
        }

        /// The format of the samples that go to the writer.
        static func format() -> CMAudioFormatDescription? {
            var description = AudioStreamBasicDescription(
                mSampleRate: Double(sampleRate),
                mFormatID: kAudioFormatLinearPCM,
                mFormatFlags: kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked,
                mBytesPerPacket: 2,
                mFramesPerPacket: 1,
                mBytesPerFrame: 2,
                mChannelsPerFrame: 1,
                mBitsPerChannel: 16,
                mReserved: 0
            )
            var format: CMAudioFormatDescription?
            CMAudioFormatDescriptionCreate(
                allocator: nil, asbd: &description, layoutSize: 0, layout: nil,
                magicCookieSize: 0, magicCookie: nil, extensions: nil, formatDescriptionOut: &format
            )
            return format
        }
    }

    /// Gives the sound track to the writer in short pieces. It runs on the queue of the video.
    final class SoundPieces: @unchecked Sendable {
        private let samples: [Int16]
        private let format: CMAudioFormatDescription
        private var index = 0
        /// A tenth of a second in each piece.
        private let pieceLength = Sound.sampleRate / 10

        init?(samples: [Int16]) {
            guard !samples.isEmpty, let format = Sound.format() else { return nil }
            self.samples = samples
            self.format = format
        }

        /// The next piece, or nil after the last one.
        func next() -> CMSampleBuffer? {
            guard index < samples.count else { return nil }
            let count = min(pieceLength, samples.count - index)
            let byteCount = count * MemoryLayout<Int16>.size
            var block: CMBlockBuffer?
            guard CMBlockBufferCreateWithMemoryBlock(
                allocator: nil, memoryBlock: nil, blockLength: byteCount, blockAllocator: nil, customBlockSource: nil,
                offsetToData: 0, dataLength: byteCount, flags: 0, blockBufferOut: &block
            ) == noErr, let block else { return nil }
            let status = samples[index ..< index + count].withUnsafeBytes { bytes in
                CMBlockBufferReplaceDataBytes(with: bytes.baseAddress!, blockBuffer: block, offsetIntoDestination: 0, dataLength: byteCount)
            }
            guard status == noErr else { return nil }
            var sample: CMSampleBuffer?
            CMAudioSampleBufferCreateReadyWithPacketDescriptions(
                allocator: nil, dataBuffer: block, formatDescription: format, sampleCount: count,
                presentationTimeStamp: CMTime(value: CMTimeValue(index), timescale: CMTimeScale(Sound.sampleRate)),
                packetDescriptions: nil, sampleBufferOut: &sample
            )
            index += count
            return sample
        }
    }
}
