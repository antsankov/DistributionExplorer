import Foundation

struct GammaDistribution: DistributionDefinition {
    let title = "Gamma"
    let isDiscrete = false
    let defaults: (Double, Double) = (2, 1)
    let symbol = "hourglass"
    let summary = "Waiting times and positive, skewed measurements."
    let explanation = "Gamma models positive values with a right-skewed shape. For an integer shape α, it describes the time until α events in a constant-rate Poisson process. Scale θ stretches the waiting time. Shape 1 gives an Exponential distribution with rate 1/θ."
    let formula = "f(x) = xᵅ⁻¹ exp(−x/θ) / (Γ(α) θᵅ), for x > 0"
    let domain: ClosedRange<Double> = 0...40
    let binCount = 40
    let ticks: [Double] = [0, 10, 20, 30, 40]
    let chartNote = "Shape starts at 1 so the density stays finite at zero. θ is scale, not rate."
    let parameters: [DistributionParameter] = [
        .init(title: "Shape α", isSecond: false, range: 1...10, step: 0.5),
        .init(title: "Scale θ", isSecond: true, range: 0.25...2, step: 0.25)
    ]
    let examples: [DistributionExample] = [
        .init(title: "Time until several arrivals", symbol: "person.2.fill", detail: "In a constant-rate Poisson arrival process, the time until the kth arrival is Gamma with shape k and scale equal to the reciprocal of the arrival rate."),
        .init(title: "Several stages of service", symbol: "hourglass", detail: "The total duration of independent exponential stages with the same rate follows a Gamma distribution with integer shape."),
        .init(title: "Positive measurement variation", symbol: "chart.bar", detail: "Gamma can model positive, right-skewed amounts such as rainfall on wet days. Check the fit; dry days need a separate probability at zero.")
    ]

    func mean(first: Double, second: Double) -> Double { first * second }
    func variance(first: Double, second: Double) -> Double { first * second * second }

    func probability(at x: Double, first: Double, second: Double) -> Double {
        guard x >= 0 else { return 0 }
        if x == 0 { return first == 1 ? 1 / second : 0 }
        return exp((first - 1) * log(x) - x / second - lgamma(first) - first * log(second))
    }

    func sample(first: Double, second: Double, using random: inout SeededRandom) -> Double {
        random.gamma(shape: first) * second
    }
}
