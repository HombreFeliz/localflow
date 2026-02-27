import Accelerate
import Foundation

struct WaveformAnalyzer {
    static func rms(of samples: [Float]) -> Float {
        guard !samples.isEmpty else { return 0 }
        var result: Float = 0
        vDSP_measqv(samples, 1, &result, vDSP_Length(samples.count))
        return sqrt(result)
    }

    static func rollingAmplitudes(from buffer: [Float], buckets: Int) -> [Float] {
        guard !buffer.isEmpty, buckets > 0 else {
            return Array(repeating: 0.05, count: buckets)
        }
        let chunkSize = max(1, buffer.count / buckets)
        var amplitudes: [Float] = []
        for i in 0..<buckets {
            let start = i * chunkSize
            let end = min(start + chunkSize, buffer.count)
            if start >= buffer.count {
                amplitudes.append(0.05)
            } else {
                let chunk = Array(buffer[start..<end])
                let r = rms(of: chunk)
                amplitudes.append(max(0.05, min(1.0, r * 8.0)))
            }
        }
        return amplitudes
    }
}
