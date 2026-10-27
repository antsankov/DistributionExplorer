import SwiftUI

extension Distribution {
    var color: Color {
        switch self {
        case .bernoulli: .pink
        case .binomial: .pink
        case .studentT: .indigo
        case .beta: .teal
        case .lognormal: .brown
        case .gamma: .cyan
        case .chiSquare: .red
        case .normal: .blue
        case .uniform: .green
        case .exponential: .orange
        case .poisson: .purple
        }
    }
}

struct DistributionList: View {
    @AppStorage("onboarding.version") private var onboardingVersion = 0
    @State private var showIntroduction = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        DistributionFitView()
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Fit your data").font(.headline)
                                Text("Enter samples and compare distribution fits")
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }.padding(.vertical, 6)
                        } icon: {
                            Image(systemName: "chart.xyaxis.line").foregroundStyle(.blue)
                        }
                    }
                    .accessibilityIdentifier("fit.open")
                }
                Section {
                    ForEach(Distribution.learningTopics) { distribution in
                        NavigationLink(value: distribution) {
                            HStack(spacing: 14) {
                                Image(systemName: distribution.symbol)
                                    .font(.title2)
                                    .foregroundStyle(distribution.color)
                                    .frame(width: 32)
                                    .accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(distribution.title).font(.headline)
                                    Text(distribution.summary)
                                        .font(.subheadline).foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 6)
                            }
                        }
                        .accessibilityIdentifier("distribution.\(distribution.rawValue)")
                    }
                } header: {
                    Text("Ten essentials")
                } footer: {
                    Text("Watch random samples fall into a shape. Then compare them with the theoretical distribution.")
                }
                Section("More to explore") {
                    NavigationLink(value: Distribution.bernoulli) {
                        Label("Bernoulli", systemImage: Distribution.bernoulli.symbol)
                    }
                    .accessibilityIdentifier("distribution.bernoulli")
                }
            }
            .navigationTitle("Distributions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showIntroduction = true
                    } label: {
                        Label("Introduction", systemImage: "questionmark.circle")
                    }
                    .accessibilityIdentifier("onboarding.replay")
                }
            }
            .navigationDestination(for: Distribution.self) { distribution in
                ExperimentView(distribution: distribution)
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { onboardingVersion < 1 || showIntroduction },
            set: { showIntroduction = $0 }
        )) {
            OnboardingView {
                onboardingVersion = 1
                showIntroduction = false
            }
            .interactiveDismissDisabled()
        }
    }
}

struct ExperimentView: View {
    let distribution: Distribution
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var experiment: Experiment
    @State private var movie: SampleMovie
    @State private var seed: UInt64 = 42
    @State private var elapsed = 0.0
    @State private var started: Date?
    @State private var speed = 2.0
    @State private var showCurve = true
    @State private var examplesExpanded = false
    @State private var parametersExpanded = true
    @State private var explanationExpanded = false
    @State private var resetBallsRequest = UUID()
    @State private var keepBallsLocked = false
    @State private var ballPhase = BallPhysics.Phase.home

    init(distribution: Distribution) {
        self.distribution = distribution
        let configuration = Experiment(distribution)
        _experiment = State(initialValue: configuration)
        _movie = State(initialValue: SampleMovie(experiment: configuration, seed: 42))
    }

    var body: some View {
        List {
            Section {
                TimelineView(.animation(minimumInterval: 1 / 60, paused: started == nil)) { timeline in
                    let time = currentTime(at: timeline.date)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(stage(at: time)).font(.headline)
                            Spacer()
                            Text("\(movie.landed(at: time)) / \(experiment.sampleCount)")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        DistributionCanvas(movie: movie, time: time, showCurve: showCurve,
                                           resetBallsRequest: resetBallsRequest,
                                           motionEnabled: time >= SampleMovie.duration && !keepBallsLocked,
                                           ballPhase: $ballPhase)
                            .frame(height: 260)
                            .accessibilityLabel("\(distribution.title) sampling animation")
                            .accessibilityValue("\(movie.landed(at: time)) of \(experiment.sampleCount) samples landed. Theoretical mean \(experiment.mean.formatted(.number.precision(.fractionLength(2)))).")
                        ProgressView(value: min(time / SampleMovie.duration, 1))
                            .accessibilityLabel("Animation progress")
                        HStack {
                            Label("Samples", systemImage: "circle.fill")
                                .foregroundStyle(distribution.color)
                            Spacer()
                            Label(distribution.isDiscrete ? "Probability" : "Density", systemImage: "waveform.path")
                                .foregroundStyle(.primary)
                        }
                        .font(.caption)
                    }
                    .padding(.vertical, 8)
                }
            }

            Section {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        Button(action: togglePlayback) {
                            Label(playbackTitle, systemImage: playbackSymbol)
                                .labelStyle(.titleAndIcon)
                                .frame(maxWidth: .infinity, minHeight: 28)
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("playback")
                        .accessibilityValue(playbackState)
                        Button {
                            replay(newSamples: true)
                        } label: {
                            Label("Replay", systemImage: "arrow.clockwise")
                                .labelStyle(.titleAndIcon)
                                .frame(maxWidth: .infinity, minHeight: 28)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("replay")
                        Button(action: ballControlAction) {
                            Label(ballControlTitle, systemImage: ballControlSymbol)
                                .labelStyle(.iconOnly)
                                .frame(minWidth: 28, minHeight: 28)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("balls.reset")
                        .accessibilityValue(ballControlValue)
                        .accessibilityHint(ballControlHint)
                    }
                    .font(.body.weight(.medium))
                    .buttonBorderShape(.capsule)
                    Picker("Speed", selection: $speed) {
                        Text("1×").tag(1.0)
                        Text("2×").tag(2.0)
                        Text("4×").tag(4.0)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: speed) { old, _ in
                        if let start = started {
                            elapsed = min(SampleMovie.duration, elapsed + Date().timeIntervalSince(start) * old)
                            started = Date()
                        }
                    }
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
            }

            Section {
                DisclosureGroup(isExpanded: $parametersExpanded) {
                    ForEach(distribution.definition.parameters) { control in
                        parameter(control.title,
                                  value: control.isSecond ? $experiment.second : $experiment.first,
                                  range: control.range, step: control.step)
                    }
                    if distribution == .uniform {
                        LabeledContent("Maximum b", value: (experiment.first + experiment.second).formatted(.number.precision(.fractionLength(2))))
                    }
                    Picker("Samples", selection: $experiment.sampleCount) {
                        Text("300").tag(300)
                        Text("450").tag(450)
                        Text("600").tag(600)
                        Text("1,200").tag(1200)
                    }
                    .accessibilityIdentifier("sampleCount")
                    Toggle("Show theoretical curve", isOn: $showCurve)
                        .accessibilityIdentifier("showCurve")
                } label: {
                    Text("Parameters").font(.headline).foregroundStyle(.primary)
                }
            }

            Section {
                DisclosureGroup(isExpanded: $examplesExpanded) {
                    ForEach(distribution.examples) { example in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: example.symbol)
                                .font(.title3)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(distribution.color)
                                .frame(width: 36, height: 36)
                                .background(distribution.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(example.title).font(.subheadline.weight(.semibold))
                                Text(example.detail).font(.subheadline).foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 4)
                    }
                } label: {
                    Text("Examples in nature & society")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
            }

            Section {
                DisclosureGroup(isExpanded: $explanationExpanded) {
                    Text(distribution.explanation)
                    LabeledContent("Mean", value: experiment.mean.formatted(.number.precision(.fractionLength(2))))
                    LabeledContent("Variance", value: experiment.variance.formatted(.number.precision(.fractionLength(2))))
                    Text(distribution.formula)
                        .font(.footnote.monospaced())
                        .textSelection(.enabled)
                } label: {
                    Text("What you’re seeing").font(.headline).foregroundStyle(.primary)
                }
            }
        }
        .listSectionSpacing(16)
        .contentMargins(.top, 18, for: .scrollContent)
        .navigationTitle(distribution.title)
        .navigationBarTitleDisplayMode(.inline)
        .tint(distribution.color)
        .onAppear { if started == nil && elapsed == 0 { replay(newSamples: false) } }
        .onDisappear { pause() }
        .onChange(of: experiment) { _, _ in replay(newSamples: false) }
        .onChange(of: scenePhase) { _, phase in if phase != .active { pause() } }
        .onChange(of: reduceMotion) { _, _ in replay(newSamples: false) }
        .task(id: playbackDeadline) {
            guard let deadline = playbackDeadline else { return }
            do {
                try await Task.sleep(for: .seconds(max(0, deadline.timeIntervalSinceNow)))
            } catch {
                return // Pausing, replaying, or changing speed cancels this deadline.
            }
            guard !Task.isCancelled, started != nil else { return }
            elapsed = SampleMovie.duration
            started = nil
        }
    }

    // Keep completion independent of the graph's lazy List row and frame updates.
    private var playbackDeadline: Date? {
        started.map { $0.addingTimeInterval(max(0, SampleMovie.duration - elapsed) / speed) }
    }

    private var canResetBalls: Bool {
        elapsed >= SampleMovie.duration && !keepBallsLocked && ballPhase != .home
    }

    private var ballControlTitle: String {
        if keepBallsLocked { return "Unlock balls" }
        if canResetBalls { return "Reset balls" }
        return elapsed < SampleMovie.duration ? "Keep balls locked" : "Lock balls"
    }

    private var ballControlSymbol: String {
        if keepBallsLocked { return "lock.fill" }
        return canResetBalls ? "arrow.uturn.backward" : "lock"
    }

    private var ballControlValue: String {
        if keepBallsLocked { return "Kept locked" }
        if elapsed < SampleMovie.duration { return "Locked until the curve finishes" }
        return canResetBalls ? "Away from home" : "Unlocked"
    }

    private var ballControlHint: String {
        if keepBallsLocked { return "Allow the balls to roll once the curve is complete" }
        if canResetBalls { return "Float the balls back to their original positions" }
        return elapsed < SampleMovie.duration
            ? "Keep the balls locked even after the curve finishes"
            : "Keep the balls locked in their original positions"
    }

    private func ballControlAction() {
        if canResetBalls {
            resetBallsRequest = UUID()
        } else {
            keepBallsLocked.toggle()
        }
    }

    private var playbackTitle: String {
        started != nil ? "Pause" : "Play"
    }

    private var playbackSymbol: String {
        started != nil ? "pause.fill" : "play.fill"
    }

    private var playbackState: String {
        if elapsed >= SampleMovie.duration { return "Finished" }
        return started == nil ? "Paused" : "Playing"
    }

    private func parameter(_ title: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double) -> some View {
        VStack(alignment: .leading) {
            LabeledContent(title, value: value.wrappedValue.formatted(.number.precision(.fractionLength(2))))
            Slider(value: value, in: range, step: step)
                .accessibilityLabel(title)
                .accessibilityValue(value.wrappedValue.formatted(.number.precision(.fractionLength(2))))
        }
    }

    private func currentTime(at date: Date) -> Double {
        min(SampleMovie.duration, elapsed + (started.map { max(0, date.timeIntervalSince($0)) * speed } ?? 0))
    }

    private func stage(at time: Double) -> String {
        if time < SampleMovie.releaseDuration + SampleMovie.flightDuration { return "Building the shape" }
        if time < SampleMovie.duration && showCurve { return "Tracing the theory" }
        return "Chance, taking shape"
    }

    private func pause() {
        elapsed = currentTime(at: Date())
        started = nil
    }

    private func togglePlayback() {
        if started != nil { pause() }
        else if elapsed >= SampleMovie.duration { replay(newSamples: true) }
        else { started = Date() }
    }

    private func replay(newSamples: Bool) {
        if newSamples { seed &+= 1 }
        movie = SampleMovie(experiment: experiment, seed: seed)
        ballPhase = .home
        elapsed = reduceMotion ? SampleMovie.duration : 0
        started = reduceMotion ? nil : Date()
    }
}
