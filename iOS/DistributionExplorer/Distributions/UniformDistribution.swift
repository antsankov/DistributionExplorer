import Foundation

struct UniformDistribution: DistributionDefinition {
    let title = "Uniform"
    let isDiscrete = false
    let defaults: (Double, Double) = (-2, 4)
    let symbol: String = "rectangle"
    let summary: String = "Every value in an interval is equally likely."
    let explanation: String = "Equal-width intervals have equal probability. The dots will make an approximately flat shape."
    let formula: String = "f(x) = 1 / (b − a), for a ≤ x ≤ b"
    let domain: ClosedRange<Double> = -4...8
    let binCount: Int = 36
    let ticks: [Double] = [-4, -1, 2, 5, 8]
    let chartNote = ""
    let parameters: [DistributionParameter] = [
        .init(title: "Minimum a", isSecond: false, range: -3...1, step: 0.25),
        .init(title: "Width b − a", isSecond: true, range: 1...6, step: 0.25)
    ]
    let examples: [DistributionExample] = [
        .init(title: "A fair spinner", symbol: "arrow.triangle.2.circlepath", detail: "An ideal spinner with no preferred direction has an equal chance of stopping in any equal-sized angle interval."),
        .init(title: "A perfectly regular bus", symbol: "bus.fill", detail: "If a bus arrives exactly every 10 minutes and you arrive at a random time, your wait is uniform between 0 and 10 minutes."),
        .init(title: "Random numbers in software", symbol: "dice.fill", detail: "A uniform random draw between 0 and 1 gives equal probability to equal-width intervals. Games and simulations use these draws as building blocks.")
    ]

    func mean(first: Double, second: Double) -> Double {
        first + second / 2
    }

    func variance(first: Double, second: Double) -> Double {
        second * second / 12
    }

    func probability(at x: Double, first: Double, second: Double) -> Double {
        return x >= first && x <= first + second ? 1 / second : 0
    }

    func sample(first: Double, second: Double, using random: inout SeededRandom) -> Double {
        return first + second * random.unit()
    }

}
