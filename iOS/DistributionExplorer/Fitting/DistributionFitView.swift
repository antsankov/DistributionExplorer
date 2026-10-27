import SwiftUI

private struct FitRequest: Equatable, Sendable {
    let text: String
    let kind: SampleKind
    let format: SampleFormat
    let selected: FitFamily?
}

struct DistributionFitView: View {
    @State private var text = ""
    @State private var kind = SampleKind.measurements
    @State private var format = SampleFormat.samples
    @State private var selected: FitFamily?
    @State private var report: FitReport?
    @State private var chart: FitChartData?
    @State private var calculating = false
    @State private var fittedRequest: FitRequest?
    @FocusState private var editing: Bool

    private var request: FitRequest { FitRequest(text: text, kind: kind, format: format, selected: selected) }

    var body: some View {
        List {
            Section {
                Text("Which distribution fits?").font(.title2.bold())
                Text("Enter observations and compare the shapes that could have produced them. Rankings update as you type.")
                    .foregroundStyle(.secondary)
            }
            Section {
                Picker("Data type", selection: $kind) {
                    ForEach(SampleKind.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .accessibilityIdentifier("fit.kind")
                Picker("Input format", selection: $format) {
                    ForEach(SampleFormat.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .accessibilityIdentifier("fit.format")
                TextEditor(text: $text)
                    .font(.body.monospaced())
                    .frame(minHeight: 110)
                    .focused($editing)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Sample values")
                    .accessibilityIdentifier("fit.input")
                HStack {
                    Menu("Try an example", systemImage: "sparkles") {
                        Button("Measurements") { loadExample(.measurements) }
                        Button("Counts") { loadExample(.counts) }
                    }
                    Spacer()
                    Button("Clear", role: .destructive) { text = ""; selected = nil }
                        .disabled(text.isEmpty)
                        .accessibilityIdentifier("fit.clear")
                }
            } header: { Text("Your data") } footer: {
                Text(format == .samples
                     ? "Separate samples with commas, spaces, or new lines. Use a decimal point. Counts are whole-number observations; measurements may also be rounded integers. Up to 10,000 samples, processed on your device."
                     : "One value and its frequency per line, e.g. 2.5, 4 means four observations of 2.5. Frequencies must be positive whole numbers. Use a decimal point.")
            }
            if calculating {
                Section { ProgressView("Updating fits…").accessibilityIdentifier("fit.loading") }
            } else if let report {
                results(report)
            }
            Section("How to read the ranking") {
                Text("Lower AICc is better. The score balances likelihood against the number of fitted parameters, with an extra penalty for small samples. Δ is the difference from the leading score; models within 2 deserve a closer look.")
                Text("Support weights are relative to the candidates tested. They are not probabilities that a distribution is true. Even the leading candidate can fit poorly: inspect the histogram and Q–Q plot.")
                Text(kind == .measurements
                     ? "Candidates: Normal, Exponential, Lognormal, and Gamma. Parameters use maximum likelihood; Gamma uses numerical optimization. Positive-only models are skipped when observations fall outside their support."
                     : "Candidates: Poisson, Geometric (failures before the first success), and Bernoulli for binary data. Binomial needs a known number of trials and is not included.")
                Text("Assumes independent observations from one stable process. Mixed populations, rounding, censoring, and trends can change the result. AICc is a ranking heuristic, especially for small samples.")
                    .foregroundStyle(.secondary)
                Link("About likelihood and AIC", destination: URL(string: "https://stat.ethz.ch/R-manual/R-devel/library/stats/html/AIC.html")!)
                Link("AICc formula", destination: URL(string: "https://www.mathworks.com/help/econ/information-criteria.html")!)
            }
            .font(.footnote)
        }
        .navigationTitle("Fit your data")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { editing = false }
            }
        }
        .task(id: request) {
            let input = request
            let sameData = fittedRequest.map {
                $0.text == input.text && $0.kind == input.kind && $0.format == input.format
            } ?? false
            let previousReport = sameData ? report : nil
            calculating = !sameData
            if !sameData {
                do { try await Task.sleep(for: .milliseconds(250)) } catch { return }
            }
            let work = Task.detached(priority: .userInitiated) {
                let result = previousReport ?? FitReport.calculate(text: input.text, format: input.format, kind: input.kind)
                return (result, FitChartData(report: result, kind: input.kind, selected: input.selected))
            }
            let (result, plot) = await withTaskCancellationHandler {
                await work.value
            } onCancel: { work.cancel() }
            guard !Task.isCancelled else { return }
            report = result
            fittedRequest = input
            chart = plot
            calculating = false
        }
    }

    @ViewBuilder
    private func results(_ report: FitReport) -> some View {
        Section {
            LabeledContent("Observations", value: report.values.count.formatted())
                .accessibilityIdentifier("fit.count")
            if let message = report.message {
                Text(message).foregroundStyle(.secondary).accessibilityIdentifier("fit.message")
            }
        }
        if !report.fits.isEmpty {
            Section {
                if report.values.count < 30 {
                    Label("Small sample: rankings may change substantially as you add observations.", systemImage: "info.circle")
                        .foregroundStyle(.secondary)
                }
                if report.fits.count == 1 {
                    Text("Only one candidate could be fitted. Its weight provides no evidence against other distribution families.")
                        .foregroundStyle(.secondary)
                } else if report.fits[1].delta < 2 {
                    Text("Close contenders: the first two models are within 2 AICc points.")
                        .foregroundStyle(.secondary)
                }
                ForEach(Array(report.fits.enumerated()), id: \.element.id) { index, fit in
                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Text("\(index + 1). \(fit.family.rawValue)").font(.headline)
                            Spacer()
                            Text(fit.weight.formatted(.percent.precision(.fractionLength(1))))
                                .font(.subheadline.monospacedDigit())
                                .accessibilityLabel("Relative support \(fit.weight.formatted(.percent))")
                        }
                        Text(fit.parameters).font(.subheadline)
                        HStack {
                            Text("AICc \(fit.aicc.formatted(.number.precision(.fractionLength(2))))")
                            Spacer()
                            Text("Δ \(fit.delta.formatted(.number.precision(.fractionLength(2))))")
                        }.font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                        ProgressView(value: fit.weight).accessibilityLabel("Relative support")
                    }
                    .padding(.vertical, 5)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("fit.result.\(fit.family.rawValue)")
                }
            } header: { Text("Best fits among tested distributions") } footer: {
                Text("Percentages show relative support within this candidate set, not certainty.")
            }
            if let chart {
                Section {
                    FitHistogram(data: chart)
                    if chart.groupedCounts {
                        Text("The count range is wide, so the histogram uses grouped bins. Model overlays are omitted; use the Q–Q plot to compare the fit.")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text("Gray bars show your samples; colors show the top three fitted models. The horizontal range covers the observations, so model tails may extend beyond the plot.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                } header: { Text("Compare the shapes") }
                Section {
                    Picker("Compare model", selection: Binding(
                        get: { report.fits.first(where: { $0.family == selected })?.family ?? report.fits[0].family },
                        set: { selected = $0 }
                    )) {
                        ForEach(report.fits) { Text($0.family.rawValue).tag($0.family) }
                    }
                    .accessibilityIdentifier("fit.qq.model")
                    FitQQPlot(data: chart)
                    Text("Points near the diagonal agree with the model. Curves or large departures suggest a mismatch. Up to 100 sample quantiles are shown. Steps are expected for counts; very large shape or rate parameters use approximate model quantiles.")
                        .font(.caption).foregroundStyle(.secondary)
                } header: { Text("Q–Q plot") }
            }
        }
        if !report.excluded.isEmpty {
            Section("Candidates skipped") {
                ForEach(report.excluded, id: \.self) { Text($0).font(.footnote).foregroundStyle(.secondary) }
            }
        }
    }

    private func loadExample(_ newKind: SampleKind) {
        kind = newKind
        format = .samples
        selected = nil
        editing = false
        let candidates: [Distribution] = newKind == .measurements
            ? [.normal, .exponential, .lognormal, .gamma]
            : [.poisson, .bernoulli]
        var example = Experiment(candidates.randomElement()!)
        for control in example.distribution.definition.parameters {
            let value = Double.random(in: control.range)
            if control.isSecond { example.second = value }
            else { example.first = value }
        }
        // Keep binary examples away from near-certain outcomes so the shape is useful.
        if example.distribution == .bernoulli { example.first = Double.random(in: 0.2...0.8) }
        var random = SeededRandom(state: UInt64.random(in: .min ... .max))
        text = (0..<60).map { _ in
            let value = example.sample(using: &random)
            return newKind == .counts ? String(Int(value))
                : String(format: "%.6g", locale: Locale(identifier: "en_US_POSIX"), value)
        }.joined(separator: ", ")
    }
}
