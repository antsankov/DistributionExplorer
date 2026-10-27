import Foundation

@main
struct FittingChecks {
    static func report(_ values: [Double], kind: SampleKind = .measurements) -> FitReport {
        FitReport.calculate(text: values.map(String.init(describing:)).joined(separator: ","), format: .samples, kind: kind)
    }

    static func close(_ actual: Double, _ expected: Double, tolerance: Double = 1e-7) {
        precondition(abs(actual - expected) < tolerance, "Expected \(expected), got \(actual)")
    }

    static func main() {
        let raw = SampleInput.parse("1, 2; 3\n4\t5e-1", format: .samples, kind: .measurements)
        precondition(raw.error == nil && raw.values == [1, 2, 3, 4, 0.5])
        let frequency = SampleInput.parse("1, 2\n2 3\n3; 1", format: .frequencies, kind: .counts)
        precondition(frequency.values == [1, 1, 2, 2, 2, 3])
        for text in ["1, nope, 2", "NaN", "inf", "1e99", "1e-99"] {
            precondition(SampleInput.parse(text, format: .samples, kind: .measurements).error != nil)
        }
        for text in ["1, 0", "1, -2", "1, 1.5", "1, 10001", "1, 2, 3", "1, 999999999999999999999"] {
            precondition(SampleInput.parse(text, format: .frequencies, kind: .measurements).error != nil)
        }
        for text in ["-1, 0, 1", "0, 0.5, 1"] {
            precondition(SampleInput.parse(text, format: .samples, kind: .counts).error != nil)
        }
        precondition(SampleInput.parse(String(repeating: "1 ", count: 10_001), format: .samples, kind: .counts).error != nil)
        for xs: [Double] in [[], [1], [1, 2, 3], [2, 2, 2, 2]] { precondition(report(xs).fits.isEmpty) }
        precondition(report([-2, -1, 0, 1, 2]).fits.map(\.family) == [.normal])
        let normal = report([-2, -1, 0, 1, 2]).fits[0]
        close(normal.first, 0)
        close(normal.second, sqrt(2)) // MLE uses n, not n-1.
        let expectedLL = -2.5 * (log(4 * .pi) + 1)
        close(normal.logLikelihood, expectedLL)
        close(normal.aicc, -2 * expectedLL + 4 + 12 / 2)
        let positive = report([0.2, 0.5, 0.8, 1.2, 2, 3, 5, 7])
        precondition(positive.fits.count == 4)
        close(positive.fits.reduce(0) { $0 + $1.weight }, 1)
        close(positive.fits[0].delta, 0)
        precondition(zip(positive.fits, positive.fits.dropFirst()).allSatisfy { $0.aicc <= $1.aicc })
        let equivalent = FitReport.calculate(text: "0.2 1\n0.5 1\n0.8 1\n1.2 1\n2 1\n3 1\n5 1\n7 1", format: .frequencies, kind: .measurements)
        precondition(positive.fits.map(\.aicc) == equivalent.fits.map(\.aicc))
        let zero = report([0, 0.5, 1, 2, 3])
        precondition(Set(zero.fits.map(\.family)) == Set([.normal, .exponential]))
        let binary = report([0, 1, 1, 0, 1, 0, 0, 1], kind: .counts)
        precondition(binary.fits.first?.family == .bernoulli)
        let counts = report([0, 1, 2, 3, 4, 5], kind: .counts)
        precondition(Set(counts.fits.map(\.family)) == Set([.poisson, .geometric]))
        close(counts.fits.first(where: { $0.family == .poisson })!.first, 2.5)

        // Deterministic simulated recovery and numerical Gamma maximum likelihood.
        var random = SeededRandom(state: 9876)
        let normals = (0..<3000).map { _ in random.normal() * 2 - 3 }
        precondition(report(normals).fits.first?.family == .normal)
        let logs = (0..<3000).map { _ in exp(random.normal() * 0.9 + 0.5) }
        precondition(report(logs).fits.first?.family == .lognormal)
        let gammas = (0..<3000).map { _ in random.gamma(shape: 3) * 2 }
        let gammaReport = report(gammas)
        precondition(gammaReport.fits.first?.family == .gamma)
        let gamma = gammaReport.fits.first(where: { $0.family == .gamma })!
        close(gamma.first, 3, tolerance: 0.2)
        close(gamma.second, 2, tolerance: 0.15)
        func ll(_ a: Double) -> Double {
            let mean = gammas.reduce(0, +) / Double(gammas.count)
            let model = DistributionFit(family: .gamma, first: a, second: mean / a, logLikelihood: 0, aicc: 0)
            return gammas.reduce(0) { $0 + model.logProbability($1) }
        }
        precondition(gamma.logLikelihood >= ll(gamma.first * 0.99))
        precondition(gamma.logLikelihood >= ll(gamma.first * 1.01))
        for fit in positive.fits + binary.fits + counts.fits {
            let qs = [0.01, 0.1, 0.5, 0.9, 0.99].map(fit.quantile)
            precondition(qs.allSatisfy(\.isFinite))
            precondition(zip(qs, qs.dropFirst()).allSatisfy { $0 <= $1 })
        }
        let exponential = positive.fits.first(where: { $0.family == .exponential })!
        close(exponential.quantile(0.5), log(2) / exponential.first)
        close(normal.quantile(0.5), 0)
        close(normal.quantile(0.975), sqrt(2) * 1.95996398454005)
        let gammaOne = DistributionFit(family: .gamma, first: 1, second: 2, logLikelihood: 0, aicc: 0)
        close(gammaOne.quantile(0.9), -2 * log(0.1))
        let poisson = DistributionFit(family: .poisson, first: 2, second: 0, logLikelihood: 0, aicc: 0)
        precondition([0.1, 0.5, 0.9].map(poisson.quantile) == [0, 2, 4])
        let tiny = report([1e-12, 2e-12, 3e-12, 4e-12, 5e-12])
        precondition(!tiny.fits.isEmpty && tiny.fits.allSatisfy { $0.aicc.isFinite })
        let huge = report([1e12, 1e12 - 1, 1e12 - 2, 1e12 - 3], kind: .counts)
        precondition(!huge.fits.isEmpty)
        precondition(huge.fits.allSatisfy { $0.quantile(0.5).isFinite })
        print("PASS fitting: input validation, frequency equivalence, MLE parameters, AICc, weights, support checks, simulated recovery, Gamma optimization, quantiles, and numerical limits")
    }
}
