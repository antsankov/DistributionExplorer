import Foundation

struct LaplaceDistribution: DistributionDefinition {
    let title = "Laplace"
    let symbol = "triangle"
    let summary = "A sharp central peak with exponential tails."
    let explanation = "Laplace, also called Double Exponential, is symmetric around location μ. Its peak is sharper and its tails heavier than a Normal distribution with the same variance. Scale b controls the spread; the standard deviation is √2 times b."
    let formula = "f(x) = exp(−|x − μ|/b) / (2b)"
    let isDiscrete = false
    let defaults: (Double, Double) = (0, 1)
    let domain: ClosedRange<Double> = -15...15
    let binCount = 60
    let ticks: [Double] = [-15, -10, -5, 0, 5, 10, 15]
    let chartNote = "b is scale, not standard deviation. Rare values can fall beyond the chart."
    let parameters: [DistributionParameter] = [
        .init(title: "Location μ", isSecond: false, range: -4...4, step: 0.25),
        .init(title: "Scale b", isSecond: true, range: 0.5...2, step: 0.25)
    ]
    let examples: [DistributionExample] = [
        .init(title: "Difference of waiting times", symbol: "hourglass", detail: "The difference between two independent Exponential waiting times with the same rate is Laplace, with location 0 and scale equal to the reciprocal of that rate."),
        .init(title: "Errors with occasional large deviations", symbol: "ruler", detail: "Laplace can approximate symmetric measurement errors with a sharp peak and more large deviations than Normal errors. Check symmetry and the tail shape in actual data."),
        .init(title: "Privacy noise", symbol: "hand.raised", detail: "The Laplace mechanism adds Laplace noise to a numeric query result. Its scale is chosen from the query sensitivity and privacy budget; adding arbitrary noise alone is not a privacy guarantee.")
    ]

    func mean(first: Double, second: Double) -> Double { first }
    func variance(first: Double, second: Double) -> Double { 2 * second * second }
    func probability(at x: Double, first: Double, second: Double) -> Double {
        exp(-abs(x - first) / second) / (2 * second)
    }
    func sample(first: Double, second: Double, using random: inout SeededRandom) -> Double {
        let u = random.unit() - 0.5
        return first - second * (u < 0 ? -1 : 1) * log1p(-2 * abs(u))
    }
}
