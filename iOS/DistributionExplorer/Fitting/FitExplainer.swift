import SwiftUI

enum FitExplainerTarget: Hashable {
    case kind, format, input, examples, ranking, histogram, qq, guide
}

struct FitExplainerAnchors: PreferenceKey {
    static var defaultValue: [FitExplainerTarget: Anchor<CGRect>] { [:] }

    static func reduce(value: inout [FitExplainerTarget: Anchor<CGRect>],
                       nextValue: () -> [FitExplainerTarget: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

extension View {
    func fitExplainerTarget(_ target: FitExplainerTarget) -> some View {
        anchorPreference(key: FitExplainerAnchors.self, value: .bounds) { [target: $0] }
            .id(target)
    }
}

struct FitExplainerStep {
    let target: FitExplainerTarget
    let title: String
    let message: String

    static func steps(hasResults: Bool) -> [Self] {
        var steps: [Self] = [
            .init(target: .kind, title: "What did you measure?",
                  message: "Choose Measurements for values such as task times or heights, even if rounded. Choose Counts for nonnegative whole-number outcomes, such as arrivals per hour. This determines which distributions we compare."),
            .init(target: .format, title: "Choose how to enter it",
                  message: "Raw samples means one number for each observation. Value / frequency lets you enter a value and how many times it occurred, one pair per line."),
            .init(target: .input, title: "Paste your observations",
                  message: "For raw samples, try 2.1, 3.4, 2.8, 5.2. Separate numbers with commas, spaces, or new lines. For frequencies, 2.5, 4 means four observations of 2.5. Fits update automatically; at least four varied observations are needed."),
            .init(target: .examples, title: "Try an example",
                  message: "No data handy? This menu generates sample measurements or counts so you can explore the ranking and plots. Each selection replaces the current input with a fresh example.")
        ]
        if hasResults {
            steps += [
                .init(target: .ranking, title: "Compare the candidates",
                      message: "The leading model has the lowest AICc score, balancing fit with complexity. Percentages show relative support among the tested candidates, not the probability that a model is true. Close contenders deserve a look too."),
                .init(target: .histogram, title: "Does the curve follow your data?",
                      message: "Gray bars show your observations. Colored curves show up to three fitted models. Look for curves that follow the overall shape, including the tails. A winning rank alone does not guarantee a good fit."),
                .init(target: .qq, title: "Check more closely",
                      message: "Choose a model for the Q–Q plot. Points near the diagonal agree with that model; curves or large departures reveal a mismatch. Steps are normal for count data.")
            ]
        }
        steps.append(.init(target: .guide, title: "Keep the result in perspective",
                           message: "We compare a limited set of models, assuming independent observations from a stable process. Small samples can give uncertain rankings. Read this guide for details, and tap the lightbulb Explainer button above to replay the tour, including the results when you have a fit."))
        return steps
    }
}

struct FitExplainerOverlay: View {
    let step: FitExplainerStep
    let index: Int
    let count: Int
    let highlight: CGRect?
    let onBack: () -> Void
    let onNext: () -> Void
    let onClose: () -> Void
    @AccessibilityFocusState private var titleFocused: Bool

    var body: some View {
        GeometryReader { geometry in
            let rect = highlight?.insetBy(dx: -5, dy: -5)
            ZStack {
                Path { path in
                    path.addRect(CGRect(origin: .zero, size: geometry.size))
                    if let rect {
                        path.addRoundedRect(in: rect, cornerSize: CGSize(width: 16, height: 16))
                    }
                }
                .fill(.black.opacity(0.6), style: FillStyle(eoFill: true))
                .accessibilityHidden(true)

                if let rect {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(.blue, lineWidth: 3)
                        .frame(width: rect.width, height: rect.height)
                        .position(x: rect.midX, y: rect.midY)
                        .accessibilityHidden(true)
                }

                VStack {
                    if (rect?.midY ?? 0) < geometry.size.height / 2 { Spacer(minLength: 16) }
                    card
                        .frame(maxWidth: 480, maxHeight: geometry.size.height * 0.48)
                    if (rect?.midY ?? 0) >= geometry.size.height / 2 { Spacer(minLength: 16) }
                }
                .padding(16)
                .frame(maxWidth: .infinity)
            }
            .contentShape(Rectangle())
            .onTapGesture { }
        }
        .accessibilityAddTraits(.isModal)
        .onAppear { titleFocused = true }
        .onChange(of: index) { _, _ in titleFocused = true }
        .accessibilityAction(.escape, onClose)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Quick tour · \(index + 1) of \(count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("fit.tour.progress")
                Spacer()
                Button("Skip", action: onClose)
                    .accessibilityIdentifier("fit.tour.skip")
            }
            ViewThatFits(in: .vertical) {
                explanation.fixedSize(horizontal: false, vertical: true)
                ScrollView { explanation }
            }
            HStack {
                if index > 0 {
                    Button("Back", action: onBack)
                        .accessibilityIdentifier("fit.tour.back")
                }
                Spacer()
                Button(index == count - 1 ? "Got it" : "Next", action: onNext)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("fit.tour.next")
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(radius: 16, y: 4)
    }

    private var explanation: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(step.title)
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($titleFocused)
                .accessibilityIdentifier("fit.tour.title")
            Text(step.message)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
