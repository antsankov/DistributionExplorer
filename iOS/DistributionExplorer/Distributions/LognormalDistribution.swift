import Foundation

struct LognormalDistribution: DistributionDefinition {
    let title = "Lognormal"
    let isDiscrete = false
    let defaults: (Double, Double) = (0, 0.5)
    let symbol: String = "chart.line.uptrend.xyaxis"
    let summary: String = "Positive values shaped by multiplying effects."
    let explanation: String = "The logarithm of each value is normal. Multiplying independent positive effects can produce this right-skewed shape. The log-scale mean and standard deviation are different from the mean and standard deviation of the values shown."
    let formula: String = "f(x) = exp(−(ln x − μ)² / (2σ²)) / (xσ√(2π)), x > 0"
    let domain: ClosedRange<Double> = 0...16
    let binCount: Int = 40
    let ticks: [Double] = [0, 4, 8, 12, 16]
    let chartNote = ""
    let parameters: [DistributionParameter] = [
        .init(title: "Log-scale mean μ", isSecond: false, range: -1...1, step: 0.1),
        .init(title: "Log-scale standard deviation σ", isSecond: true, range: 0.25...1, step: 0.05)
    ]
    let examples: [DistributionExample] = [
        .init(title: "Multiplicative growth", symbol: "chart.line.uptrend.xyaxis", detail: "A quantity can be approximately lognormal when its logarithm sums many small independent effects."),
        .init(title: "Particle sizes", symbol: "circle.grid.2x2", detail: "Positive particle diameters can have a right-skewed spread consistent with multiplicative formation processes."),
        .init(title: "Task durations", symbol: "timer", detail: "Some positive completion times have a long right tail and approximately normal logarithms. Check those assumptions before fitting.")
    ]

    func mean(first: Double, second: Double) -> Double {
        exp(first + second * second / 2)
    }

    func variance(first: Double, second: Double) -> Double {
        (exp(second * second) - 1) * exp(2 * first + second * second)
    }

    func probability(at x: Double, first: Double, second: Double) -> Double {
        guard x > 0 else { return 0 }
        let z = (log(x) - first) / second
        return exp(-z * z / 2) / (x * second * sqrt(2 * .pi))
    }

    func sample(first: Double, second: Double, using random: inout SeededRandom) -> Double {
        return exp(first + second * random.normal())
    }

}
