import Foundation

enum SampleKind: String, CaseIterable, Sendable {
    case measurements = "Measurements", counts = "Counts"
}

enum SampleFormat: String, CaseIterable, Sendable {
    case samples = "Raw samples", frequencies = "Value / frequency"
}

struct SampleInput: Sendable {
    let values: [Double]
    let error: String?
    static let maximumCount = 10_000

    static func parse(_ text: String, format: SampleFormat, kind: SampleKind) -> SampleInput {
        func failure(_ message: String) -> SampleInput { SampleInput(values: [], error: message) }
        guard text.count <= 250_000 else { return failure("Input is too long. Use at most 10,000 samples.") }
        func number(_ token: String) -> Double? {
            guard let value = Double(token), value.isFinite, abs(value) <= 1e12,
                  value == 0 || abs(value) >= 1e-12 else { return nil }
            return value
        }
        var values: [Double] = []
        if format == .samples {
            let tokens = text.split { $0.isWhitespace || $0 == "," || $0 == ";" }
            guard tokens.count <= maximumCount else { return failure("Use at most 10,000 samples.") }
            for token in tokens {
                guard let value = number(String(token)) else {
                    return failure("“\(token.prefix(24))” is not a supported number. Use a decimal point; magnitudes must be between 1e−12 and 1e12, or zero.")
                }
                values.append(value)
            }
        } else {
            for (index, line) in text.components(separatedBy: .newlines).enumerated() {
                let tokens = line.split { $0.isWhitespace || $0 == "," || $0 == ";" }
                if tokens.isEmpty { continue }
                guard tokens.count == 2, let value = number(String(tokens[0])),
                      let frequency = Int(tokens[1]), frequency > 0 else {
                    return failure("Row \(index + 1): enter a value and a positive whole-number frequency, e.g. 2.5, 4.")
                }
                guard frequency <= maximumCount - values.count else { return failure("Use at most 10,000 samples in total.") }
                values.append(contentsOf: repeatElement(value, count: frequency))
            }
        }
        if kind == .counts && values.contains(where: { $0 < 0 || $0.rounded() != $0 }) {
            return failure("Counts must be nonnegative whole numbers. Choose Measurements for decimal or negative values.")
        }
        return SampleInput(values: values, error: nil)
    }
}

enum FitFamily: String, Sendable {
    case normal = "Normal", lognormal = "Lognormal", exponential = "Exponential", gamma = "Gamma"
    case poisson = "Poisson", geometric = "Geometric", bernoulli = "Bernoulli"
}

struct DistributionFit: Identifiable, Sendable {
    var id: FitFamily { family }
    let family: FitFamily
    let first: Double
    let second: Double
    let logLikelihood: Double
    let aicc: Double
    var delta = 0.0
    var weight = 0.0

    var parameters: String {
        func f(_ x: Double) -> String { x.formatted(.number.precision(.significantDigits(4))) }
        switch family {
        case .normal: return "μ = \(f(first)), σ = \(f(second))"
        case .lognormal: return "log μ = \(f(first)), log σ = \(f(second))"
        case .exponential: return "rate λ = \(f(first))"
        case .gamma: return "shape α = \(f(first)), scale θ = \(f(second))"
        case .poisson: return "rate λ = \(f(first))"
        case .geometric: return "success p = \(f(first)) (failures before success)"
        case .bernoulli: return "success p = \(f(first))"
        }
    }

    func logProbability(_ x: Double) -> Double {
        switch family {
        case .normal:
            return -log(second) - 0.5 * log(2 * .pi) - 0.5 * pow((x - first) / second, 2)
        case .lognormal:
            guard x > 0 else { return -.infinity }
            return -log(x) - log(second) - 0.5 * log(2 * .pi) - 0.5 * pow((log(x) - first) / second, 2)
        case .exponential:
            return x >= 0 ? log(first) - first * x : -.infinity
        case .gamma:
            guard x > 0 else { return -.infinity }
            return (first - 1) * log(x) - x / second - lgamma(first) - first * log(second)
        case .poisson:
            guard x >= 0, x == x.rounded() else { return -.infinity }
            return first == 0 ? (x == 0 ? 0 : -.infinity) : x * log(first) - first - lgamma(x + 1)
        case .geometric:
            guard x >= 0, x == x.rounded() else { return -.infinity }
            return first == 1 ? (x == 0 ? 0 : -.infinity) : log(first) + x * log1p(-first)
        case .bernoulli:
            if x == 1 { return log(first) }
            if x == 0 { return log1p(-first) }
            return -.infinity
        }
    }

    func probability(_ x: Double) -> Double {
        let value = exp(logProbability(x))
        return value.isFinite ? value : 0
    }

    func quantile(_ p: Double) -> Double {
        switch family {
        case .exponential: return -log1p(-p) / first
        case .geometric: return first == 1 ? 0 : max(0, ceil(log1p(-p) / log1p(-first)) - 1)
        case .bernoulli: return p <= 1 - first ? 0 : 1
        case .normal, .lognormal:
            var low = -9.0, high = 9.0
            for _ in 0..<60 {
                let mid = (low + high) / 2
                if 0.5 * erfc(-mid / sqrt(2)) < p { low = mid } else { high = mid }
            }
            let z = first + second * (low + high) / 2
            return family == .normal ? z : exp(z)
        case .gamma:
            var low = 0.0, high = max(1, first)
            while Self.gammaCDF(high, shape: first) < p && high < 1e15 { high *= 2 }
            for _ in 0..<80 {
                let mid = (low + high) / 2
                if Self.gammaCDF(mid, shape: first) < p { low = mid } else { high = mid }
            }
            return (low + high) / 2 * second
        case .poisson:
            // Integer binary search with the gamma/Poisson CDF identity.
            if first == 0 { return 0 }
            var low = 0.0, high = ceil(first + 12 * sqrt(first) + 20)
            for _ in 0..<60 {
                if high <= low { break }
                let mid = floor((low + high) / 2)
                let cdf = 1 - Self.gammaCDF(first, shape: mid + 1)
                if cdf < p { low = mid + 1 } else { high = mid }
            }
            return low
        }
    }

    // Regularized lower incomplete gamma: series below a+1, continued fraction above.
    private static func gammaCDF(_ x: Double, shape a: Double) -> Double {
        if x <= 0 { return 0 }
        // Normal approximation avoids long iterations for very large Poisson rates.
        if a > 10_000 {
            let z = (pow(x / a, 1 / 3.0) - (1 - 1 / (9 * a))) / sqrt(1 / (9 * a))
            return 0.5 * erfc(-z / sqrt(2))
        }
        let scale = exp(a * log(x) - x - lgamma(a))
        if x < a + 1 {
            var term = 1 / a, sum = term
            for n in 1...2000 {
                term *= x / (a + Double(n)); sum += term
                if abs(term) < abs(sum) * 1e-14 { break }
            }
            return min(1, max(0, sum * scale))
        }
        var b = x + 1 - a, c = 1e300, d = 1 / b, h = d
        for n in 1...2000 {
            let an = -Double(n) * (Double(n) - a)
            b += 2
            d = an * d + b; if abs(d) < 1e-300 { d = 1e-300 }
            c = b + an / c; if abs(c) < 1e-300 { c = 1e-300 }
            d = 1 / d
            let change = d * c; h *= change
            if abs(change - 1) < 1e-14 { break }
        }
        return min(1, max(0, 1 - scale * h))
    }
}

struct FitReport: Sendable {
    let values: [Double]
    let fits: [DistributionFit]
    let message: String?
    let excluded: [String]

    static func calculate(text: String, format: SampleFormat, kind: SampleKind) -> FitReport {
        let input = SampleInput.parse(text, format: format, kind: kind)
        guard input.error == nil else { return FitReport(values: [], fits: [], message: input.error, excluded: []) }
        let xs = input.values.sorted(), n = Double(xs.count)
        func empty(_ message: String) -> FitReport { FitReport(values: xs, fits: [], message: message, excluded: []) }
        guard xs.count >= 4 else { return empty("Enter at least 4 samples to start comparing fits. Rankings will be tentative.") }
        let mean = xs.reduce(0, +) / n
        let variance = xs.reduce(0) { $0 + pow($1 - mean, 2) } / n
        guard variance > 0 else { return empty("All samples are identical. Add varied observations to compare distribution shapes.") }
        var fits: [DistributionFit] = [], excluded: [String] = []
        func add(_ family: FitFamily, _ first: Double, _ second: Double = 0, k: Int) {
            guard first.isFinite, second.isFinite, n > Double(k + 1) else { return }
            let prototype = DistributionFit(family: family, first: first, second: second, logLikelihood: 0, aicc: 0)
            let ll = xs.reduce(0) { $0 + prototype.logProbability($1) }
            let score = -2 * ll + 2 * Double(k) + 2 * Double(k * (k + 1)) / (n - Double(k) - 1)
            guard score.isFinite else { excluded.append("\(family.rawValue): could not obtain a finite fit."); return }
            fits.append(DistributionFit(family: family, first: first, second: second, logLikelihood: ll, aicc: score))
        }
        if kind == .counts {
            add(.poisson, mean, k: 1)
            add(.geometric, 1 / (mean + 1), k: 1)
            if xs.last! <= 1 { add(.bernoulli, mean, k: 1) }
            else { excluded.append("Bernoulli needs only 0s and 1s.") }
        } else {
            add(.normal, mean, sqrt(variance), k: 2)
            if xs.first! >= 0 && mean > 0 { add(.exponential, 1 / mean, k: 1) }
            else { excluded.append("Exponential needs nonnegative values.") }
            if xs.first! > 0 {
                let logs = xs.map(log), logMean = logs.reduce(0, +) / n
                let logVariance = logs.reduce(0) { $0 + pow($1 - logMean, 2) } / n
                if logVariance > 0 { add(.lognormal, logMean, sqrt(logVariance), k: 2) }
                // Profile maximum likelihood: theta = mean / alpha; optimize log(alpha).
                let s = log(mean) - logMean
                if s > 1e-8 {
                    func objective(_ logShape: Double) -> Double {
                        let a = exp(logShape)
                        return a * log(a) - lgamma(a) - a - a * s
                    }
                    var low = -18.0, high = 18.0
                    for _ in 0..<100 {
                        let left = low + (high - low) / 3, right = high - (high - low) / 3
                        if objective(left) > objective(right) { high = right } else { low = left }
                    }
                    let a = exp((low + high) / 2)
                    add(.gamma, a, mean / a, k: 2)
                } else { excluded.append("Gamma: observations are too tightly clustered for a stable fit.") }
            } else { excluded.append("Lognormal and Gamma need strictly positive values.") }
        }
        fits.sort { $0.aicc == $1.aicc ? $0.family.rawValue < $1.family.rawValue : $0.aicc < $1.aicc }
        if let best = fits.first?.aicc {
            let total = fits.reduce(0) { $0 + exp(-0.5 * ($1.aicc - best)) }
            for i in fits.indices {
                fits[i].delta = fits[i].aicc - best
                fits[i].weight = exp(-0.5 * fits[i].delta) / total
            }
        }
        return FitReport(values: xs, fits: fits, message: fits.isEmpty ? "No stable fit is available for these samples." : nil, excluded: excluded)
    }
}
