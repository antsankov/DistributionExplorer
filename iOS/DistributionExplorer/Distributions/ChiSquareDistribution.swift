import Foundation

struct ChiSquareDistribution: DistributionDefinition {
    let title = "Chi-Square"
    let isDiscrete = false
    let defaults: (Double, Double) = (4, 0)
    let symbol = "sum"
    let summary = "Variance estimation and statistical tests."
    let explanation = "The sum of ν independent squared standard Normal variables follows a Chi-Square distribution. It is positive and right-skewed, becoming more symmetric as degrees of freedom increase. It is also Gamma with shape ν/2 and scale 2."
    let formula = "f(x) = x⁽ν/²⁾⁻¹ exp(−x/2) / (2⁽ν/²⁾ Γ(ν/2)), for x > 0"
    let domain: ClosedRange<Double> = 0...40
    let binCount = 40
    let ticks: [Double] = [0, 10, 20, 30, 40]
    let chartNote = "Degrees of freedom start at 2 so the density stays finite at zero."
    let parameters: [DistributionParameter] = [
        .init(title: "Degrees of freedom ν", isSecond: false, range: 2...20, step: 1)
    ]
    let examples: [DistributionExample] = [
        .init(title: "Estimating variance", symbol: "plusminus", detail: "For n independent normal observations, (n − 1)s²/σ² follows Chi-Square with n − 1 degrees of freedom. This gives confidence intervals for population variance."),
        .init(title: "Testing category counts", symbol: "chart.bar", detail: "Pearson’s goodness-of-fit statistic is approximately Chi-Square when independent category counts have sufficiently large expected counts. Degrees of freedom account for fitted parameters."),
        .init(title: "Testing independence", symbol: "tablecells", detail: "For independent observations in a contingency table with sufficiently large expected counts, Pearson’s independence statistic is approximately Chi-Square with (rows − 1)(columns − 1) degrees of freedom.")
    ]

    func mean(first: Double, second: Double) -> Double { first }
    func variance(first: Double, second: Double) -> Double { 2 * first }

    func probability(at x: Double, first: Double, second: Double) -> Double {
        GammaDistribution().probability(at: x, first: first / 2, second: 2)
    }

    func sample(first: Double, second: Double, using random: inout SeededRandom) -> Double {
        random.gamma(shape: first / 2) * 2
    }
}
