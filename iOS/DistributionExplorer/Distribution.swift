import Foundation

enum Distribution: String, CaseIterable, Identifiable, Sendable {
    case normal, binomial, poisson, uniform, exponential, studentT, beta, gamma, lognormal, chiSquare, bernoulli

    var id: String { rawValue }
    static let learningTopics: [Distribution] = [.normal, .binomial, .poisson, .uniform, .exponential, .studentT, .beta, .gamma, .lognormal, .chiSquare]

    var definition: any DistributionDefinition {
        switch self {
        case .bernoulli: BernoulliDistribution()
        case .binomial: BinomialDistribution()
        case .normal: NormalDistribution()
        case .poisson: PoissonDistribution()
        case .exponential: ExponentialDistribution()
        case .uniform: UniformDistribution()
        case .studentT: StudentTDistribution()
        case .beta: BetaDistribution()
        case .lognormal: LognormalDistribution()
        case .gamma: GammaDistribution()
        case .chiSquare: ChiSquareDistribution()
        }
    }
    var title: String { definition.title }
    var symbol: String { definition.symbol }
    var summary: String { definition.summary }
    var explanation: String { definition.explanation }
    var formula: String { definition.formula }
    var examples: [DistributionExample] { definition.examples }
    var isDiscrete: Bool { definition.isDiscrete }
}

struct DistributionExample: Identifiable, Sendable {
    let title: String
    let symbol: String
    let detail: String
    var id: String { title }
}

