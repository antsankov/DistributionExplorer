import SwiftUI
import Charts

struct FitPlotPoint: Identifiable, Sendable {
    let id: Int
    let x: Double
    let y: Double
}

struct FitHistogramBin: Identifiable, Sendable {
    let id: Int
    let lower: Double
    let upper: Double
    let height: Double
}

struct FitCurve: Identifiable, Sendable {
    var id: FitFamily { family }
    let family: FitFamily
    let points: [FitPlotPoint]
}

struct FitChartData: Sendable {
    let bins: [FitHistogramBin]
    let curves: [FitCurve]
    let qq: [FitPlotPoint]
    let discrete: Bool
    let groupedCounts: Bool
    let range: ClosedRange<Double>
    let qqRange: ClosedRange<Double>

    init(report: FitReport, kind: SampleKind, selected: FitFamily?) {
        let xs = report.values
        let discrete = kind == .counts
        self.discrete = discrete
        guard let minX = xs.first, let maxX = xs.last, maxX > minX else {
            bins = []; curves = []; qq = []; self.groupedCounts = false; range = 0...1; qqRange = 0...1
            return
        }
        let span = maxX - minX
        let groupedCounts = discrete && span > 80
        self.groupedCounts = groupedCounts
        let lower = discrete ? max(-0.5, minX - 0.5) : minX - span * 0.08
        let upper = discrete ? maxX + 0.5 : maxX + span * 0.08
        range = lower...upper
        let count = discrete && !groupedCounts ? Int(span) + 1 : min(30, max(5, Int(sqrt(Double(xs.count)))))
        let width = (upper - lower) / Double(count)
        var frequencies = Array(repeating: 0, count: count)
        for x in xs {
            let index = min(count - 1, max(0, Int((x - lower) / width)))
            frequencies[index] += 1
        }
        bins = frequencies.indices.map {
            FitHistogramBin(id: $0, lower: lower + Double($0) * width,
                            upper: lower + Double($0 + 1) * width,
                            height: Double(frequencies[$0]) / Double(xs.count) / width)
        }
        curves = groupedCounts ? [] : report.fits.prefix(3).map { fit in
            let steps = discrete ? count - 1 : 240
            let points = (0...steps).compactMap { i -> FitPlotPoint? in
                let x = discrete ? minX + Double(i) : lower + Double(i) / Double(steps) * (upper - lower)
                let y = fit.probability(x)
                return y.isFinite ? FitPlotPoint(id: i, x: x, y: y) : nil
            }
            return FitCurve(family: fit.family, points: points)
        }
        let fit = report.fits.first(where: { $0.family == selected }) ?? report.fits.first
        if let fit {
            var points: [FitPlotPoint] = []
            let quantileCount = min(100, xs.count)
            for i in 0..<quantileCount {
                if Task.isCancelled { break }
                let fraction = (Double(i) + 0.5) / Double(quantileCount)
                let index = min(xs.count - 1, Int(fraction * Double(xs.count)))
                let p = (Double(index) + 0.5) / Double(xs.count)
                let theoretical = fit.quantile(p)
                if theoretical.isFinite {
                    points.append(FitPlotPoint(id: i, x: theoretical, y: xs[index]))
                }
            }
            qq = points
            let low = min(minX, points.map(\.x).min() ?? minX)
            let high = max(maxX, points.map(\.x).max() ?? maxX)
            let pad = max((high - low) * 0.06, 1e-14)
            qqRange = (low - pad)...(high + pad)
        } else { qq = []; qqRange = range }
    }
}

struct FitHistogram: View {
    let data: FitChartData

    var body: some View {
        Chart {
            ForEach(data.bins) { bin in
                RectangleMark(xStart: .value("Lower", bin.lower), xEnd: .value("Upper", bin.upper),
                              yStart: .value("Baseline", 0), yEnd: .value("Samples", bin.height))
                    .foregroundStyle(.gray.opacity(0.3))
            }
            ForEach(data.curves) { curve in
                ForEach(curve.points) { point in
                    if data.discrete {
                        PointMark(x: .value("Value", point.x), y: .value("Probability", point.y))
                            .foregroundStyle(by: .value("Distribution", curve.family.rawValue))
                            .symbol(by: .value("Distribution", curve.family.rawValue))
                    } else {
                        LineMark(x: .value("Value", point.x), y: .value("Density", point.y),
                                 series: .value("Distribution", curve.family.rawValue))
                            .foregroundStyle(by: .value("Distribution", curve.family.rawValue))
                            .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                }
            }
        }
        .chartXScale(domain: data.range)
        .chartYAxisLabel(data.discrete ? (data.groupedCounts ? "Frequency / bin width" : "Probability") : "Density")
        .chartXAxisLabel("Observed value")
        .chartLegend(position: .bottom, alignment: .leading)
        .frame(height: 240)
        .accessibilityLabel("Sample histogram compared with the top three fitted distributions")
    }
}

struct FitQQPlot: View {
    let data: FitChartData

    var body: some View {
        Chart {
            ForEach([data.qqRange.lowerBound, data.qqRange.upperBound], id: \.self) { x in
                LineMark(x: .value("Theoretical", x), y: .value("Observed", x))
                    .foregroundStyle(.secondary)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            ForEach(data.qq) { point in
                PointMark(x: .value("Theoretical", point.x), y: .value("Observed", point.y))
                    .foregroundStyle(.blue)
                    .symbolSize(18)
            }
        }
        .chartXScale(domain: data.qqRange)
        .chartYScale(domain: data.qqRange)
        .chartXAxisLabel("Fitted quantiles")
        .chartYAxisLabel("Sample quantiles")
        .frame(height: 220)
        .accessibilityLabel("Q–Q plot. Points close to the diagonal agree with the selected distribution.")
    }
}
