import Foundation

struct GeometricDistribution: DistributionDefinition {
    let title = "Geometric"
    let symbol = "repeat"
    let summary = "Trials until the first success."
    let explanation = "Repeat independent trials with the same success probability p. Count every trial, including the first success. The wait is memoryless: past failures do not change the chance of success on the next trial."
    let formula = "P(X = k) = p(1 − p)ᵏ⁻¹, for k = 1, 2, …"
    let isDiscrete = true
    let defaults: (Double, Double) = (0.5, 0)
    let domain: ClosedRange<Double> = -0.5...40.5
    let binCount = 41
    let ticks: [Double] = [0, 10, 20, 30, 40]
    let chartNote = "Counts trials starting at 1. Fit your data uses the alternative convention: failures starting at 0. Long waits can fall beyond the chart."
    let parameters: [DistributionParameter] = [
        .init(title: "Success probability p", isSecond: false, range: 0.1...1, step: 0.05)
    ]
    let examples: [DistributionExample] = [
        .init(title: "Tosses until heads", symbol: "circle.lefthalf.filled", detail: "Count independent tosses of the same coin, including the toss that first lands heads."),
        .init(title: "Rolls until a six", symbol: "die.face.6", detail: "Roll the same fair die until a six appears. Each independent roll has success probability 1/6."),
        .init(title: "Attempts until a connection", symbol: "antenna.radiowaves.left.and.right", detail: "Count attempts until a connection succeeds, assuming independent attempts with a constant success probability. Changing network conditions can break this assumption.")
    ]

    func mean(first: Double, second: Double) -> Double { 1 / first }
    func variance(first: Double, second: Double) -> Double { (1 - first) / (first * first) }
    func probability(at x: Double, first: Double, second: Double) -> Double {
        guard x >= 1, x == x.rounded() else { return 0 }
        if first == 1 { return x == 1 ? 1 : 0 }
        return first * exp((x - 1) * log1p(-first))
    }
    func sample(first: Double, second: Double, using random: inout SeededRandom) -> Double {
        if first == 1 { return 1 }
        return floor(log(random.unit()) / log1p(-first)) + 1
    }
}
