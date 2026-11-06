import Foundation

struct HypergeometricDistribution: DistributionDefinition {
    static let population = 50.0
    let title = "Hypergeometric"
    let symbol = "tray.full"
    let summary = "Successes in draws without replacement."
    let explanation = "Draw n items uniformly without replacement from a population of 50 containing K successes. Count the successes drawn. Unlike Binomial trials, the draws are dependent: each draw changes what remains. Drawing the whole population always gives exactly K successes."
    let formula = "P(X = k) = C(K,k) C(50 − K,n − k) / C(50,n)"
    let isDiscrete = true
    let defaults: (Double, Double) = (20, 10)
    let domain: ClosedRange<Double> = -0.5...50.5
    let binCount = 51
    let ticks: [Double] = [0, 10, 20, 30, 40, 50]
    let chartNote = "Population size is fixed at 50. Each experiment sample starts with the full population again."
    let parameters: [DistributionParameter] = [
        .init(title: "Successes in population K", isSecond: false, range: 0...50, step: 1),
        .init(title: "Draws n", isSecond: true, range: 1...50, step: 1)
    ]
    let examples: [DistributionExample] = [
        .init(title: "Colored balls in a bag", symbol: "circle.grid.3x3.fill", detail: "Draw n balls uniformly from 50 balls containing K red balls, without putting them back. Count the red balls."),
        .init(title: "Inspecting a finite batch", symbol: "checkmark.seal", detail: "Randomly inspect n distinct items from a batch of 50 with K defective items. Count defects; every item must be equally likely to be selected."),
        .init(title: "Selecting a committee", symbol: "person.3.fill", detail: "Choose n people uniformly from a group of 50 containing K members of a subgroup. Count selected subgroup members. Nonrandom selection changes the model.")
    ]

    func mean(first: Double, second: Double) -> Double { second * first / Self.population }
    func variance(first: Double, second: Double) -> Double {
        let p = first / Self.population
        return second * p * (1 - p) * (Self.population - second) / (Self.population - 1)
    }
    private func logChoose(_ n: Double, _ k: Double) -> Double {
        lgamma(n + 1) - lgamma(k + 1) - lgamma(n - k + 1)
    }
    func probability(at x: Double, first: Double, second: Double) -> Double {
        guard x == x.rounded(), x >= max(0, second - Self.population + first),
              x <= min(first, second) else { return 0 }
        return exp(logChoose(first, x) + logChoose(Self.population - first, second - x)
                   - logChoose(Self.population, second))
    }
    func sample(first: Double, second: Double, using random: inout SeededRandom) -> Double {
        var remainingSuccesses = first
        var count = 0.0
        for draw in 0..<Int(second) {
            if random.unit() < remainingSuccesses / (Self.population - Double(draw)) {
                count += 1
                remainingSuccesses -= 1
            }
        }
        return count
    }
}
