import Foundation

struct StudentTDistribution: DistributionDefinition {
    let title = "Student’s t"
    let isDiscrete = false
    let defaults: (Double, Double) = (5, 0)
    let symbol: String = "bell.fill"
    let summary: String = "A symmetric curve with heavier tails."
    let explanation: String = "Like Normal, this curve is symmetric around zero, but its heavier tails allow more extreme values. More degrees of freedom make it closer to Normal. For normal observations, it describes the standardized sample mean when variance is estimated from the sample."
    let formula: String = "f(x) = Γ((ν+1)/2) / (√(νπ) Γ(ν/2)) × (1+x²/ν)⁻⁽ν⁺¹⁾/²"
    let domain: ClosedRange<Double> = -10...10
    let binCount: Int = 40
    let ticks: [Double] = [-10, -5, 0, 5, 10]
    let chartNote = "Degrees of freedom start at 3 so the mean and variance are defined."
    let parameters: [DistributionParameter] = [
        .init(title: "Degrees of freedom ν", isSecond: false, range: 3...30, step: 1)
    ]
    let examples: [DistributionExample] = [
        .init(title: "Estimating an average", symbol: "chart.bar.xaxis", detail: "For independent normal measurements with unknown variance, the standardized sample mean follows t with n − 1 degrees of freedom."),
        .init(title: "Paired measurements", symbol: "arrow.left.arrow.right", detail: "A t interval for an average before-and-after difference assumes independent, approximately normal differences."),
        .init(title: "Heavier-tail comparison", symbol: "waveform.path", detail: "Compare the dots with Normal: small degrees of freedom put more probability far from the center. The explorer uses ν ≥ 3 so mean and variance exist.")
    ]

    func mean(first: Double, second: Double) -> Double {
        0
    }

    func variance(first: Double, second: Double) -> Double {
        first / (first - 2)
    }

    func probability(at x: Double, first: Double, second: Double) -> Double {
        return exp(lgamma((first + 1) / 2) - lgamma(first / 2)
                   - log(first * .pi) / 2 - (first + 1) / 2 * log1p(x * x / first))
    }

    func sample(first: Double, second: Double, using random: inout SeededRandom) -> Double {
        return random.normal() / sqrt(random.gamma(shape: first / 2) * 2 / first)
    }

}
