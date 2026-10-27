import Foundation

/// SplitMix64 keeps replays reproducible without affecting the system RNG.
struct SeededRandom: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
    mutating func normal() -> Double {
        sqrt(-2 * log(unit())) * cos(2 * .pi * unit())
    }

    /// Marsaglia–Tsang rejection sampler for shape >= 1 (all explorer controls).
    mutating func gamma(shape: Double) -> Double {
        precondition(shape >= 1)
        let d = shape - 1 / 3.0
        let c = 1 / sqrt(9 * d)
        while true {
            let z = normal()
            let root = 1 + c * z
            if root <= 0 { continue }
            let v = root * root * root
            let u = unit()
            if u < 1 - 0.0331 * pow(z, 4) || log(u) < z * z / 2 + d * (1 - v + log(v)) {
                return d * v
            }
        }
    }

    mutating func unit() -> Double {
        // Strictly between zero and one, avoiding log(0) in the samplers.
        (Double(next() >> 12) + 0.5) / 4_503_599_627_370_496
    }
}

