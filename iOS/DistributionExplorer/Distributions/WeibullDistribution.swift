import Foundation

struct WeibullDistribution: DistributionDefinition {
    let title = "Weibull"
    let symbol = "gearshape"
    let summary = "Lifetimes with constant or increasing failure rates."
    let explanation = "Weibull models positive lifetimes. Shape k = 1 gives an Exponential distribution; k > 1 describes a failure rate that increases with age. Scale λ stretches time. The wider family also allows k < 1 and decreasing failure rates; this explorer starts at 1 to keep the density finite at zero."
    let formula = "f(x) = (k/λ)(x/λ)ᵏ⁻¹ exp(−(x/λ)ᵏ), for x ≥ 0"
    let isDiscrete = false
    let defaults: (Double, Double) = (2, 2)
    let domain: ClosedRange<Double> = 0...15
    let binCount = 50
    let ticks: [Double] = [0, 3, 6, 9, 12, 15]
    let chartNote = "Shape starts at 1 to keep the density finite at zero. λ is scale, not rate."
    let parameters: [DistributionParameter] = [
        .init(title: "Shape k", isSecond: false, range: 1...5, step: 0.25),
        .init(title: "Scale λ", isSecond: true, range: 0.5...4, step: 0.25)
    ]
    let examples: [DistributionExample] = [
        .init(title: "Component wear", symbol: "gearshape", detail: "Weibull with shape above 1 can model component lifetimes when failure risk increases with age. Check whether the observed failure pattern supports this assumption."),
        .init(title: "Material strength", symbol: "hammer", detail: "Weibull can approximate breaking strengths when failure is governed by the weakest of many defects. Material and test conditions must be comparable."),
        .init(title: "Wind speeds", symbol: "wind", detail: "Weibull often approximates positive wind speeds at a site over a stable period. Calm periods, seasons, and changing weather may need separate treatment.")
    ]

    func mean(first: Double, second: Double) -> Double { second * tgamma(1 + 1 / first) }
    func variance(first: Double, second: Double) -> Double {
        second * second * (tgamma(1 + 2 / first) - pow(tgamma(1 + 1 / first), 2))
    }
    func probability(at x: Double, first: Double, second: Double) -> Double {
        guard x >= 0 else { return 0 }
        if x == 0 { return first == 1 ? 1 / second : 0 }
        let scaled = x / second
        return first / second * pow(scaled, first - 1) * exp(-pow(scaled, first))
    }
    func sample(first: Double, second: Double, using random: inout SeededRandom) -> Double {
        second * pow(-log(random.unit()), 1 / first)
    }
}
