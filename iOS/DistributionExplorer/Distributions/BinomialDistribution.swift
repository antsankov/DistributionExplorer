import Foundation

struct BinomialDistribution: DistributionDefinition {
    let title = "Binomial"
    let isDiscrete = true
    let defaults: (Double, Double) = (10, 0.5)
    let symbol: String = "chart.bar"
    let summary: String = "The number of successes in independent trials."
    let explanation: String = "Count successes in n independent trials, each with the same success probability p. With n = 1, this is Bernoulli."
    let formula: String = "P(X = k) = C(n,k) pᵏ (1 − p)ⁿ⁻ᵏ"
    let domain: ClosedRange<Double> = -0.5...30.5
    let binCount: Int = 31
    let ticks: [Double] = [0, 5, 10, 15, 20, 25, 30]
    let chartNote = ""
    let parameters: [DistributionParameter] = [
        .init(title: "Trials n", isSecond: false, range: 1...30, step: 1),
        .init(title: "Success probability p", isSecond: true, range: 0...1, step: 0.05)
    ]
    let examples: [DistributionExample] = [
        .init(title: "Heads in ten tosses", symbol: "circle.lefthalf.filled", detail: "Count heads across ten independent tosses of the same coin."),
        .init(title: "Passing items in a batch", symbol: "checkmark.circle", detail: "Count passes among n independently produced items with the same pass probability. Sampling a finite batch without replacement instead calls for Hypergeometric."),
        .init(title: "Sign-ups in a trial", symbol: "person.2.fill", detail: "Count sign-ups among a fixed number of independent visitors with the same conversion probability.")
    ]

    func mean(first: Double, second: Double) -> Double {
        first * second
    }

    func variance(first: Double, second: Double) -> Double {
        first * second * (1 - second)
    }

    func probability(at x: Double, first: Double, second: Double) -> Double {
        guard x >= 0, x <= first, x.rounded() == x else { return 0 }
        if second == 0 { return x == 0 ? 1 : 0 }
        if second == 1 { return x == first ? 1 : 0 }
        return exp(lgamma(first + 1) - lgamma(x + 1) - lgamma(first - x + 1)
                   + x * log(second) + (first - x) * log1p(-second))
    }

    func sample(first: Double, second: Double, using random: inout SeededRandom) -> Double {
        return Double((0..<Int(first)).reduce(0) { count, _ in count + (random.unit() < second ? 1 : 0) })
    }

}
