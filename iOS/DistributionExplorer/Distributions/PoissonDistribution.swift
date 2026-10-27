import Foundation

struct PoissonDistribution: DistributionDefinition {
    let title = "Poisson"
    let isDiscrete = true
    let defaults: (Double, Double) = (5, 0)
    let symbol: String = "number"
    let summary: String = "How many events happen in an interval."
    let explanation: String = "Each dot is a whole-number count. The rate is both the average count and the variance."
    let formula: String = "P(X = k) = exp(−λ) λᵏ / k!"
    let domain: ClosedRange<Double> = -0.5...24.5
    let binCount: Int = 25
    let ticks: [Double] = [0, 5, 10, 15, 20, 24]
    let chartNote = ""
    let parameters: [DistributionParameter] = [
        .init(title: "Average count λ", isSecond: false, range: 1...10, step: 0.5)
    ]
    let examples: [DistributionExample] = [
        .init(title: "Radiation detections per minute", symbol: "atom", detail: "Count independent detector clicks during a fixed interval with a steady average rate. The count is Poisson; the wait between clicks is exponential."),
        .init(title: "Requests arriving each minute", symbol: "tray.fill", detail: "Independent arrivals at a stable rate can give Poisson counts. Coordinated bursts or changing demand break that simple model."),
        .init(title: "Flaws along a length of material", symbol: "magnifyingglass", detail: "Count flaws in equal lengths of wire or fabric when flaws occur independently at a constant average rate. Clustering calls for a different model.")
    ]

    func mean(first: Double, second: Double) -> Double {
        first
    }

    func variance(first: Double, second: Double) -> Double {
        first
    }

    func probability(at x: Double, first: Double, second: Double) -> Double {
        guard x >= 0, x.rounded() == x else { return 0 }
        let k = Int(x)
        var mass = exp(-first)
        if k > 0 {
            for i in 1...k { mass *= first / Double(i) }
        }
        return mass
    }

    func sample(first: Double, second: Double, using random: inout SeededRandom) -> Double {
        let limit = exp(-first)
        var product = 1.0
        var count = 0
        repeat {
            count += 1
            product *= random.unit()
        } while product > limit
        return Double(count - 1)
    }

}
