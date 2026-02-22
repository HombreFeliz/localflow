import AVFoundation
import Foundation

final class AudioRecorder {
    private let engine = AVAudioEngine()
    private var sampleBuffer: [Float] = []
    private let targetSampleRate: Double = 16_000
    private var converter: AVAudioConverter?
    private let bufferLock = NSLock()

    var onAmplitudeUpdate: (([Float]) -> Void)?

    private let targetFormat: AVAudioFormat = {
        AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16_000,
            channels: 1,
            interleaved: false
        )!
    }()

    func startRecording() throws {
        bufferLock.lock()
        sampleBuffer = []
        bufferLock.unlock()

        let inputNode = engine.inputNode
        let hardwareFormat = inputNode.outputFormat(forBus: 0)

        guard let conv = AVAudioConverter(from: hardwareFormat, to: targetFormat) else {
            throw RecorderError.converterFailed
        }
        converter = conv

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: hardwareFormat) {
            [weak self] buffer, _ in
            self?.processTap(buffer: buffer, hardwareFormat: hardwareFormat)
        }

        engine.prepare()
        try engine.start()
    }

    func stopRecording() -> [Float] {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        bufferLock.lock()
        let result = sampleBuffer
        bufferLock.unlock()
        return result
    }

    private func processTap(buffer: AVAudioPCMBuffer, hardwareFormat: AVAudioFormat) {
        guard let converter = converter else { return }

        let ratio = targetFormat.sampleRate / hardwareFormat.sampleRate
        let outputFrameCapacity = AVAudioFrameCount(
            ceil(Double(buffer.frameLength) * ratio)
        )

        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: outputFrameCapacity
        ) else { return }

        var hadInput = false
        var error: NSError?

        converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            if hadInput {
                outStatus.pointee = .noDataNow
                return nil
            }
            hadInput = true
            outStatus.pointee = .haveData
            return buffer
        }

        guard error == nil,
              let channelData = outputBuffer.floatChannelData else { return }

        let frameCount = Int(outputBuffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameCount))

        bufferLock.lock()
        sampleBuffer.append(contentsOf: samples)
        let recent = Array(sampleBuffer.suffix(16_000 * 2))
        bufferLock.unlock()

        let amplitudes = WaveformAnalyzer.rollingAmplitudes(from: recent, buckets: 40)

        DispatchQueue.main.async { [weak self] in
            self?.onAmplitudeUpdate?(amplitudes)
        }
    }
}

enum RecorderError: Error, LocalizedError {
    case converterFailed

    var errorDescription: String? {
        switch self {
        case .converterFailed:
            return "No se pudo crear el convertidor de audio."
        }
    }
}
