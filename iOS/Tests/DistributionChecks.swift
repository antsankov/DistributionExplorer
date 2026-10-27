import Foundation

@main
struct DistributionChecks {
    static func main() {
        precondition(Distribution.learningTopics == [
            .normal, .binomial, .poisson, .uniform, .exponential,
            .studentT, .beta, .gamma, .lognormal, .chiSquare
        ])
        for distribution in Distribution.allCases {
            var experiment = Experiment(distribution)
            var generator = SeededRandom(state: 2026)
            let count = 100_000
            var sum = 0.0
            var squares = 0.0
            for _ in 0..<count {
                let x = experiment.sample(using: &generator)
                precondition(x.isFinite)
                if distribution.isDiscrete { precondition(x >= 0 && x == x.rounded()) }
                if distribution == .bernoulli { precondition(x == 0 || x == 1) }
                if distribution == .binomial { precondition(x <= experiment.first) }
                if distribution == .beta { precondition((0...1).contains(x)) }
                if [.lognormal, .gamma, .chiSquare].contains(distribution) { precondition(x > 0) }
                if distribution == .exponential { precondition(x >= 0) }
                if distribution == .uniform { precondition((-2...2).contains(x)) }
                sum += x
                squares += x * x
            }
            let observedMean = sum / Double(count)
            let observedVariance = squares / Double(count) - observedMean * observedMean
            precondition(abs(observedMean - experiment.mean) < 0.04, "Wrong mean: \(distribution)")
            precondition(abs(observedVariance - experiment.variance) < 0.08, "Wrong variance: \(distribution)")

            // Check normalization separately from sampling.
            if distribution.isDiscrete {
                let total = (0...80).reduce(0.0) { $0 + experiment.probability(at: Double($1)) }
                precondition(abs(total - 1) < 1e-10)
            } else {
                let step = 0.001
                let lower = distribution == .studentT ? -100.0 : distribution == .normal ? -12.0 : distribution == .uniform ? -4.0 : 0
                let upper = distribution == .studentT ? 100.0 : distribution == .beta ? 1.0 : distribution == .normal ? 12.0 : distribution == .uniform ? 8.0 : 40
                let steps = Int((upper - lower) / step)
                let total = (0..<steps).reduce(0.0) {
                    $0 + experiment.probability(at: lower + (Double($1) + 0.5) * step) * step
                }
                precondition(abs(total - 1) < 0.002)
            }
            experiment.sampleCount = 1200
            let movie = SampleMovie(experiment: experiment, seed: 42)
            let replay = SampleMovie(experiment: experiment, seed: 42)
            precondition(movie.counts == replay.counts)
            precondition(movie.counts.reduce(0, +) + movie.outsideCount == 1200)
            precondition(movie.landed(at: 0) == 0)
            precondition(movie.landed(at: SampleMovie.duration) == 1200)
            precondition(movie.maximum.isFinite && movie.maximum > 0)
            print("PASS \(distribution.title): sampling, normalization, histogram accounting, replay, completion")
        }
        checkParameterExtremes()
        checkKnownProbabilities()
    }

    static func checkParameterExtremes() {
        for distribution in Distribution.allCases {
            let controls = distribution.definition.parameters
            for first in [controls[0].range.lowerBound, controls[0].range.upperBound] {
                let seconds = controls.count > 1
                    ? [controls[1].range.lowerBound, controls[1].range.upperBound]
                    : [distribution.definition.defaults.1]
                for second in seconds {
                    var experiment = Experiment(distribution)
                    experiment.first = first
                    experiment.second = second
                    var random = SeededRandom(state: 7)
                    for _ in 0..<1000 {
                        let x = experiment.sample(using: &random)
                        precondition(x.isFinite)
                        if distribution.isDiscrete { precondition(x >= 0 && x == x.rounded()) }
                        if distribution == .beta { precondition((0...1).contains(x)) }
                    }
                    for index in 0...1000 {
                        let x = experiment.domain.lowerBound + Double(index) / 1000
                            * (experiment.domain.upperBound - experiment.domain.lowerBound)
                        let density = experiment.probability(at: distribution.isDiscrete ? x.rounded() : x)
                        precondition(density.isFinite && density >= 0)
                    }
                    let movie = SampleMovie(experiment: experiment, seed: 7)
                    precondition(movie.maximum.isFinite && movie.maximum > 0)
                    precondition(movie.counts.reduce(0, +) + movie.outsideCount == experiment.sampleCount)
                }
            }
        }
        print("PASS all parameter extremes: finite samples, densities, and chart scaling")
    }

    static func checkKnownProbabilities() {
        let bernoulli = Experiment(.bernoulli)
        var binomial = Experiment(.binomial)
        precondition(abs(binomial.probability(at: 5) - 0.24609375) < 1e-12)
        binomial.first = 1
        for x in [-1.0, 0, 0.5, 1, 2] {
            precondition(abs(binomial.probability(at: x) - bernoulli.probability(at: x)) < 1e-12)
        }
        for p in [0.0, 1.0] {
            binomial.first = 30
            binomial.second = p
            precondition(binomial.probability(at: p * 30) == 1)
        }
        var beta = Experiment(.beta)
        precondition(abs(beta.probability(at: 0.5) - 1.5) < 1e-12)
        beta.first = 1
        beta.second = 1
        for x in [0.0, 0.25, 0.5, 1] { precondition(beta.probability(at: x) == 1) }
        let t = Experiment(.studentT)
        precondition(abs(t.probability(at: 0) - 0.3796066898224944) < 1e-12)
        precondition(t.probability(at: -2) == t.probability(at: 2))
        let lognormal = Experiment(.lognormal)
        precondition(lognormal.probability(at: 0) == 0)
        precondition(abs(lognormal.probability(at: 1) - 2 / sqrt(2 * .pi)) < 1e-12)
        var gamma = Experiment(.gamma)
        precondition(abs(gamma.probability(at: 1) - exp(-1)) < 1e-12)
        gamma.first = 1
        gamma.second = 2
        let exponential = ExponentialDistribution()
        var chiSquare = Experiment(.chiSquare)
        chiSquare.first = 2
        for x in [-1.0, 0, 0.5, 1, 4, 20] {
            let expected = exponential.probability(at: x, first: 0.5, second: 0)
            precondition(abs(gamma.probability(at: x) - expected) < 1e-12)
            precondition(abs(chiSquare.probability(at: x) - expected) < 1e-12)
        }
        chiSquare.first = 4
        precondition(chiSquare.probability(at: 0) == 0)
        precondition(abs(chiSquare.probability(at: 2) - exp(-1) / 2) < 1e-12)
        print("PASS known probabilities, boundary cases, and distribution connections")
    }
}
