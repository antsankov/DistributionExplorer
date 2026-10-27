import Foundation

struct BetaDistribution: DistributionDefinition {
    let title = "Beta"
    let isDiscrete = false
    let defaults: (Double, Double) = (2, 2)
    let symbol: String = "slider.horizontal.3"
    let summary: String = "Probabilities and proportions between 0 and 1."
    let explanation: String = "Values stay between 0 and 1. The two shape parameters control balance and concentration. A Beta distribution can represent uncertainty about a Bernoulli success probability; observed successes and failures update its shape."
    let formula: String = "f(x) = xᵅ⁻¹ (1−x)ᵝ⁻¹ / B(α,β), for 0 < x < 1"
    let domain: ClosedRange<Double> = 0...1
    let binCount: Int = 40
    let ticks: [Double] = [0, 0.25, 0.5, 0.75, 1]
    let chartNote = "Shape controls start at 1 so the density stays finite at the endpoints."
    let parameters: [DistributionParameter] = [
        .init(title: "Shape α", isSecond: false, range: 1...10, step: 0.5),
        .init(title: "Shape β", isSecond: true, range: 1...10, step: 0.5)
    ]
    let examples: [DistributionExample] = [
        .init(title: "Uncertain conversion probability", symbol: "person.2.fill", detail: "Use Beta to describe uncertainty about a fixed conversion probability under independent Bernoulli observations."),
        .init(title: "Learning from coin tosses", symbol: "circle.lefthalf.filled", detail: "With a Beta prior, each observed head adds one to α and each tail adds one to β."),
        .init(title: "A bounded fraction", symbol: "chart.pie", detail: "A continuous fraction strictly between zero and one may fit a Beta model. Exact zeros or ones require additional modeling.")
    ]

    func mean(first: Double, second: Double) -> Double {
        first / (first + second)
    }

    func variance(first: Double, second: Double) -> Double {
        first * second / (pow(first + second, 2) * (first + second + 1))
    }

    func probability(at x: Double, first: Double, second: Double) -> Double {
        guard x >= 0, x <= 1 else { return 0 }
        // Slider shapes are at least 1, so endpoint densities remain finite.
        if x == 0 { return first == 1 ? second : 0 }
        if x == 1 { return second == 1 ? first : 0 }
        return exp((first - 1) * log(x) + (second - 1) * log1p(-x)
                   + lgamma(first + second) - lgamma(first) - lgamma(second))
    }

    func sample(first: Double, second: Double, using random: inout SeededRandom) -> Double {
        let a = random.gamma(shape: first)
        let b = random.gamma(shape: second)
        return a / (a + b)
    }

}
