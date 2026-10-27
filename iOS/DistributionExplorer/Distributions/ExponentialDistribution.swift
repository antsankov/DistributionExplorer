import Foundation

struct ExponentialDistribution: DistributionDefinition {
    let title = "Exponential"
    let isDiscrete = false
    let defaults: (Double, Double) = (1, 0)
    let symbol: String = "timer"
    let summary: String = "The wait until the next event."
    let explanation: String = "Short waits are more common than long ones. Increasing the rate makes the typical wait shorter."
    let formula: String = "f(x) = λ exp(−λx), for x ≥ 0"
    let domain: ClosedRange<Double> = 0...16
    let binCount: Int = 40
    let ticks: [Double] = [0, 4, 8, 12, 16]
    let chartNote = ""
    let parameters: [DistributionParameter] = [
        .init(title: "Rate λ", isSecond: false, range: 0.4...2, step: 0.1)
    ]
    let examples: [DistributionExample] = [
        .init(title: "Between detector clicks", symbol: "waveform.path.ecg", detail: "The wait between independent radiation detections can be exponential when the average detection rate stays constant."),
        .init(title: "Until the next request", symbol: "bubble.left.and.bubble.right.fill", detail: "The wait for a support request can be modeled this way when requests arrive independently at a steady rate. Busy hours may need a different model."),
        .init(title: "A component’s working life", symbol: "cpu", detail: "A component with a constant failure risk has an exponential lifetime. This assumption does not describe wear-out or aging.")
    ]

    func mean(first: Double, second: Double) -> Double {
        1 / first
    }

    func variance(first: Double, second: Double) -> Double {
        1 / (first * first)
    }

    func probability(at x: Double, first: Double, second: Double) -> Double {
        return x >= 0 ? first * exp(-first * x) : 0
    }

    func sample(first: Double, second: Double, using random: inout SeededRandom) -> Double {
        return -log(random.unit()) / first
    }

}
