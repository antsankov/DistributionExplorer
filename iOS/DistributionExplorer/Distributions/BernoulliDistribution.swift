import Foundation

struct BernoulliDistribution: DistributionDefinition {
    let title = "Bernoulli"
    let isDiscrete = true
    let defaults: (Double, Double) = (0.5, 0)
    let symbol: String = "circle.lefthalf.filled"
    let summary: String = "One yes/no outcome, then successes across trials."
    let explanation: String = "A single trial is either 0 (failure) or 1 (success). The probability p controls how often success occurs. Binomial adds up independent Bernoulli trials with the same p."
    let formula: String = "P(X = 1) = p; P(X = 0) = 1 − p"
    let domain: ClosedRange<Double> = -0.5...1.5
    let binCount: Int = 2
    let ticks: [Double] = [0, 1]
    let chartNote = ""
    let parameters: [DistributionParameter] = [
        .init(title: "Success probability p", isSecond: false, range: 0...1, step: 0.05)
    ]
    let examples: [DistributionExample] = [
        .init(title: "One coin toss", symbol: "circle.lefthalf.filled", detail: "Record heads as 1 and tails as 0. A fair coin has success probability 0.5."),
        .init(title: "One quality check", symbol: "checkmark.circle", detail: "A randomly selected item either passes or fails a specified inspection."),
        .init(title: "One visitor converts", symbol: "person.fill", detail: "Record whether one visitor signs up. Comparing visitors requires a stable definition of success.")
    ]

    func mean(first: Double, second: Double) -> Double {
        first
    }

    func variance(first: Double, second: Double) -> Double {
        first * (1 - first)
    }

    func probability(at x: Double, first: Double, second: Double) -> Double {
        return x == 0 ? 1 - first : x == 1 ? first : 0
    }

    func sample(first: Double, second: Double, using random: inout SeededRandom) -> Double {
        return random.unit() < first ? 1 : 0
    }

}
