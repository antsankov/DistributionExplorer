import Foundation

struct NormalDistribution: DistributionDefinition {
    let title = "Normal"
    let isDiscrete = false
    let defaults: (Double, Double) = (0, 1)
    let symbol: String = "bell"
    let summary: String = "A bell curve around an average."
    let explanation: String = "Values near the mean are most likely. The standard deviation controls how widely they spread."
    let formula: String = "f(x) = exp(−(x − μ)² / (2σ²)) / (σ√(2π))"
    let domain: ClosedRange<Double> = -10...10
    let binCount: Int = 40
    let ticks: [Double] = [-10, -5, 0, 5, 10]
    let chartNote = ""
    let parameters: [DistributionParameter] = [
        .init(title: "Mean μ", isSecond: false, range: -3...3, step: 0.25),
        .init(title: "Standard deviation σ", isSecond: true, range: 0.5...2, step: 0.1)
    ]
    let examples: [DistributionExample] = [
        .init(title: "Measurement errors", symbol: "ruler", detail: "Small, independent sources of error can combine into an approximately bell-shaped spread around the true value."),
        .init(title: "Adult heights", symbol: "figure.stand", detail: "Heights within a similar age and sex group are often approximately normal. Mixing different populations can change the shape."),
        .init(title: "Averages across samples", symbol: "chart.bar.xaxis", detail: "Averages of many independent observations with finite variance tend toward a normal shape, even when individual observations are not normal.")
    ]

    func mean(first: Double, second: Double) -> Double {
        first
    }

    func variance(first: Double, second: Double) -> Double {
        second * second
    }

    func probability(at x: Double, first: Double, second: Double) -> Double {
        let z = (x - first) / second
        return exp(-z * z / 2) / (second * sqrt(2 * .pi))
    }

    func sample(first: Double, second: Double, using random: inout SeededRandom) -> Double {
        let z = sqrt(-2 * log(random.unit())) * cos(2 * .pi * random.unit())
        return first + second * z
    }

}
