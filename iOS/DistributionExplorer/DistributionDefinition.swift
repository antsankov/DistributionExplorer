import Foundation

/// Each distribution owns its teaching content, controls, and mathematical model.
protocol DistributionDefinition: Sendable {
    var title: String { get }
    var symbol: String { get }
    var summary: String { get }
    var explanation: String { get }
    var formula: String { get }
    var examples: [DistributionExample] { get }
    var isDiscrete: Bool { get }
    var defaults: (Double, Double) { get }
    var domain: ClosedRange<Double> { get }
    var binCount: Int { get }
    var ticks: [Double] { get }
    var chartNote: String { get }
    var parameters: [DistributionParameter] { get }
    func mean(first: Double, second: Double) -> Double
    func variance(first: Double, second: Double) -> Double
    func probability(at x: Double, first: Double, second: Double) -> Double
    func sample(first: Double, second: Double, using random: inout SeededRandom) -> Double
}

struct DistributionParameter: Identifiable, Sendable {
    let title: String
    let isSecond: Bool
    let range: ClosedRange<Double>
    let step: Double
    var id: String { title }
}

