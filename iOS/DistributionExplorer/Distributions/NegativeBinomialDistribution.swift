import Foundation

struct NegativeBinomialDistribution: DistributionDefinition {
    let title = "Negative Binomial"
    let symbol = "checkmark.circle"
    let summary = "Failures before a target number of successes."
    let explanation = "Repeat independent trials with constant success probability p until r successes occur. Count only the failures. At r = 1, adding one to this count gives a Geometric wait. This family also models counts with variance greater than their mean."
    let formula = "P(X = k) = C(k + r − 1, k) pʳ(1 − p)ᵏ"
    let isDiscrete = true
    let defaults: (Double, Double) = (3, 0.5)
    let domain: ClosedRange<Double> = -0.5...80.5
    let binCount = 81
    let ticks: [Double] = [0, 20, 40, 60, 80]
    let chartNote = "Counts failures, not total trials. Large failure counts can fall beyond the chart."
    let parameters: [DistributionParameter] = [
        .init(title: "Target successes r", isSecond: false, range: 1...10, step: 1),
        .init(title: "Success probability p", isSecond: true, range: 0.2...1, step: 0.05)
    ]
    let examples: [DistributionExample] = [
        .init(title: "Tails before three heads", symbol: "circle.lefthalf.filled", detail: "Count tails before the third head in independent tosses of the same coin."),
        .init(title: "Misses before five hits", symbol: "target", detail: "Count misses before five hits, assuming independent attempts and a constant hit probability. Practice or fatigue can change that probability."),
        .init(title: "Counts with varying rates", symbol: "chart.bar", detail: "A Poisson count whose rate varies between observations according to a Gamma distribution has a Negative Binomial distribution. This can describe more variable counts than a single Poisson rate allows.")
    ]

    func mean(first: Double, second: Double) -> Double { first * (1 - second) / second }
    func variance(first: Double, second: Double) -> Double { first * (1 - second) / (second * second) }
    func probability(at x: Double, first: Double, second: Double) -> Double {
        guard x >= 0, x == x.rounded() else { return 0 }
        if second == 1 { return x == 0 ? 1 : 0 }
        return exp(lgamma(x + first) - lgamma(first) - lgamma(x + 1)
                   + first * log(second) + x * log1p(-second))
    }
    func sample(first: Double, second: Double, using random: inout SeededRandom) -> Double {
        if second == 1 { return 0 }
        return (0..<Int(first)).reduce(0.0) { count, _ in
            count + floor(log(random.unit()) / log1p(-second))
        }
    }
}
