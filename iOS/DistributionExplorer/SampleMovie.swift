import Foundation

struct Particle: Sendable {
    let bin: Int?
    let rank: Int
    let release: Double
    let drift: Double
}

struct SampleMovie: Sendable {
    let id = UUID()
    let experiment: Experiment
    let particles: [Particle]
    let counts: [Int]
    let outsideCount: Int
    let maximum: Double

    static let releaseDuration = 7.0
    static let flightDuration = 0.85
    static let traceDuration = 1.4
    static let duration = releaseDuration + flightDuration + traceDuration

    init(experiment: Experiment, seed: UInt64) {
        self.experiment = experiment
        var random = SeededRandom(state: seed)
        var counts = Array(repeating: 0, count: experiment.binCount)
        var particles: [Particle] = []
        var outside = 0
        for index in 0..<experiment.sampleCount {
            let value = experiment.sample(using: &random)
            let bin = experiment.bin(for: value)
            let rank = bin.map { counts[$0] } ?? 0
            if let bin { counts[bin] += 1 } else { outside += 1 }
            let fraction = Double(index) / Double(experiment.sampleCount - 1)
            particles.append(Particle(
                bin: bin, rank: rank,
                release: pow(fraction, 0.55) * Self.releaseDuration,
                drift: (random.unit() - 0.5) * 80
            ))
        }
        self.particles = particles
        self.counts = counts
        outsideCount = outside
        let histogramPeak = Double(counts.max() ?? 1) / Double(experiment.sampleCount) / experiment.binWidth
        let theoryPeak = (0...1000).map { index in
            let x = experiment.domain.lowerBound + Double(index) / 1000 * (experiment.domain.upperBound - experiment.domain.lowerBound)
            return experiment.probability(at: experiment.distribution.isDiscrete ? x.rounded() : x)
        }.max() ?? 1
        maximum = max(histogramPeak, theoryPeak) * 1.2
    }

    func landed(at time: Double) -> Int {
        particles.prefix { $0.release + Self.flightDuration <= time }.count
    }
}
