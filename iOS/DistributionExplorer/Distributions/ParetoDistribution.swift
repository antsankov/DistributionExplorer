import Foundation

struct ParetoDistribution: DistributionDefinition {
    let title = "Pareto"
    let symbol = "chart.line.uptrend.xyaxis"
    let summary = "Positive values with a power-law tail."
    let explanation = "Pareto Type I starts at a positive minimum xₘ and has a power-law upper tail. Smaller shape α makes extreme values more likely. A finite mean requires α > 1 and a finite variance requires α > 2; these controls stay above 2 so both displayed statistics exist."
    let formula = "f(x) = α xₘᵅ / xᵅ⁺¹, for x ≥ xₘ"
    let isDiscrete = false
    let defaults: (Double, Double) = (5, 1)
    let domain: ClosedRange<Double> = 0...12
    let binCount = 48
    let ticks: [Double] = [0, 3, 6, 9, 12]
    let chartNote = "Shape stays above 2 for a finite variance. Rare large values can fall beyond the chart."
    let parameters: [DistributionParameter] = [
        .init(title: "Shape α", isSecond: false, range: 2.5...8, step: 0.5),
        .init(title: "Minimum xₘ", isSecond: true, range: 0.5...3, step: 0.25)
    ]
    let examples: [DistributionExample] = [
        .init(title: "High incomes", symbol: "banknote", detail: "A Pareto tail can approximate incomes above a chosen threshold. It does not describe the entire income distribution, and the threshold and tail shape need checking."),
        .init(title: "Large insurance claims", symbol: "doc.text", detail: "Claim sizes above a high threshold may have a Pareto-like tail. Policy limits and changing claim conditions can alter that tail."),
        .init(title: "Large file sizes", symbol: "folder", detail: "A Pareto tail can approximate unusually large files in some collections. A common collection process and evidence for a power-law tail are needed.")
    ]

    func mean(first: Double, second: Double) -> Double { first * second / (first - 1) }
    func variance(first: Double, second: Double) -> Double {
        first * second * second / (pow(first - 1, 2) * (first - 2))
    }
    func probability(at x: Double, first: Double, second: Double) -> Double {
        guard x >= second else { return 0 }
        return first / x * pow(second / x, first)
    }
    func sample(first: Double, second: Double, using random: inout SeededRandom) -> Double {
        second * pow(random.unit(), -1 / first)
    }
}
