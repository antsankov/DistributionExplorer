import Foundation

struct Experiment: Equatable, Sendable {
    var distribution: Distribution
    var first: Double
    var second: Double
    var sampleCount = 600

    init(_ distribution: Distribution) {
        self.distribution = distribution
        (first, second) = distribution.definition.defaults
    }

    var domain: ClosedRange<Double> { distribution.definition.domain }
    var binCount: Int { distribution.definition.binCount }
    var binWidth: Double { (domain.upperBound - domain.lowerBound) / Double(binCount) }
    var mean: Double { distribution.definition.mean(first: first, second: second) }
    var variance: Double { distribution.definition.variance(first: first, second: second) }

    func probability(at x: Double) -> Double {
        distribution.definition.probability(at: x, first: first, second: second)
    }

    func sample(using random: inout SeededRandom) -> Double {
        distribution.definition.sample(first: first, second: second, using: &random)
    }

    func bin(for value: Double) -> Int? {
        guard domain.contains(value) else { return nil }
        return min(binCount - 1, Int((value - domain.lowerBound) / binWidth))
    }
}

