import SwiftUI

struct DistributionIntroductionView: View {
    let onContinue: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var demo = DistributionIntroductionDemo()
    @State private var time = 0.0
    @State private var replayID = UUID()

    private var finished: Bool { time >= SampleMovie.duration }

    private struct AnimationSession: Equatable {
        let replayID: UUID
        let scenePhase: ScenePhase
        let reduceMotion: Bool
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("What is a distribution?")
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                Text("Imagine timing the same task 450 times. Each ball represents one task’s completion time.")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(finished ? "A pattern in task times" : "Collecting task times…")
                            .font(.headline)
                        Spacer()
                        Text("\(demo.movie.landed(at: time)) / \(demo.movie.experiment.sampleCount)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    DistributionCanvas(movie: demo.movie, time: time, showCurve: true,
                                       resetBallsRequest: replayID, motionEnabled: false,
                                       ballPhase: .constant(.home), fittedCurve: demo.fit)
                        .frame(height: 280)
                        .accessibilityLabel("Task completion times in minutes falling into a histogram")
                        .accessibilityValue(finished ? "Finished. Best fit: \(demo.fit.family.rawValue)." : "\(demo.movie.landed(at: time)) task times collected")
                    Text("Completion time (minutes) · Simulated example")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 24))

                Button {
                    time = 0
                    replayID = UUID()
                } label: {
                    Label("Watch again", systemImage: "arrow.clockwise")
                }
                .accessibilityIdentifier("onboarding.distribution.replay")

                if finished {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Best fit: \(demo.fit.family.rawValue) Distribution")
                            .font(.title2.bold())
                            .accessibilityIdentifier("onboarding.distribution.result")
                        Text("Many tasks finish quickly; a few take much longer. The curve follows that pattern. A distribution’s function describes how probability is spread across possible outcomes.")
                        Text("Best match among Normal, Exponential, Lognormal, and Gamma. For measurements, probability over a range is the area under the curve.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Shorter tasks land to the left. Longer tasks land to the right.")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 28)
            .padding(.bottom, 16)
        }
        .safeAreaInset(edge: .bottom) {
            Button(action: onContinue) {
                Text("Continue").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("onboarding.distribution.continue")
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(.systemGroupedBackground))
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .task(id: AnimationSession(replayID: replayID, scenePhase: scenePhase, reduceMotion: reduceMotion)) {
            if reduceMotion {
                time = SampleMovie.duration
                return
            }
            guard scenePhase == .active else { return }
            let initialTime = time
            let start = Date()
            while !Task.isCancelled && time < SampleMovie.duration {
                time = min(SampleMovie.duration, initialTime + Date().timeIntervalSince(start) * 3)
                do { try await Task.sleep(for: .seconds(1.0 / 60)) }
                catch { return }
            }
        }
    }
}

/// Rank the very same observations shown by the falling-ball movie.
struct DistributionIntroductionDemo {
    let movie: SampleMovie
    let fit: DistributionFit

    init() {
        var experiment = Experiment(.lognormal)
        experiment.first = 1
        experiment.sampleCount = 450
        let movie = SampleMovie(experiment: experiment, seed: 42)
        let report = FitReport.calculate(text: movie.values.map { String($0) }.joined(separator: ","),
                                         format: .samples, kind: .measurements)
        // This fixed, varied sample has finite measurement fits.
        self.movie = movie
        self.fit = report.fits[0]
    }
}
