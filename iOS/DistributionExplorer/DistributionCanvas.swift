import SwiftUI

struct DistributionCanvas: View {
    let movie: SampleMovie
    let time: Double
    let showCurve: Bool
    let resetBallsRequest: UUID
    let motionEnabled: Bool
    @Binding var ballPhase: BallPhysics.Phase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var motionFrame: MotionFrame?
    @State private var playbackTime = 0.0
    @State private var pendingReset = false

    private struct MotionFrame {
        let positions: [CGPoint]
        let trails: [BallFlightTrails.Batch]
        let timestamp: Double
    }

    private struct MotionSession: Equatable {
        let enabled: Bool
        let size: CGSize
        let movieID: UUID
    }

    var body: some View {
        GeometryReader { geometry in
            // Capture a value in body so sensor updates redraw even when the
            // parent playback timeline is paused or finished.
            let snapshot = reduceMotion || !motionEnabled ? nil : motionFrame
            let plot = plotRect(size: geometry.size)
            let trace = min(1, max(0, (time - SampleMovie.releaseDuration - SampleMovie.flightDuration) / SampleMovie.traceDuration))
            ZStack {
                DistributionGuides(movie: movie, plot: plot, curveProgress: nil).equatable()
                Canvas { context, size in
                    draw(context: &context, size: size, frame: snapshot)
                }
                if showCurve, trace > 0 {
                    DistributionGuides(movie: movie, plot: plot, curveProgress: trace).equatable()
                }
            }
            .task(id: MotionSession(enabled: motionEnabled && scenePhase == .active && !reduceMotion,
                                    size: geometry.size, movieID: movie.id)) {
                await trackTilt(size: geometry.size)
            }
        }
        .onChange(of: time, initial: true) { _, value in playbackTime = value }
        .onChange(of: resetBallsRequest) { _, _ in pendingReset = true }
    }

    @MainActor
    private func trackTilt(size: CGSize) async {
        motionFrame = nil
        ballPhase = .home
        pendingReset = false
        guard !Task.isCancelled, motionEnabled, scenePhase == .active, !reduceMotion,
              let session = ChartMotion.shared.start() else { return }
        defer {
            ChartMotion.shared.stop(session: session)
        }
        let plot = plotRect(size: size)
        let binWidth = Double(plot.width) / Double(movie.experiment.binCount)
        let columns = max(1, Int(binWidth / 3.5))
        let radius = min(2.1, binWidth / Double(columns) * 0.4)
        var world = BallPhysics(
            homes: movie.particles.map { particle in
                guard particle.bin != nil else { return .zero }
                return home(for: particle, plot: plot, columns: columns, binWidth: binWidth)
            },
            releases: movie.particles.map { $0.bin == nil ? .infinity : $0.release + SampleMovie.flightDuration },
            width: plot.width, height: plot.height, radius: radius
        )
        var previousTimestamp: Double?
        var previousOrientation: Int?
        var positions = world.balls.map(\.position)
        var trails = BallFlightTrails()
        while !Task.isCancelled {
            let now = ProcessInfo.processInfo.systemUptime
            let hadTrails = trails.hasVisibleTrails
            var needsDisplay = false
            if let sample = ChartMotion.shared.sample, sample.timestamp != previousTimestamp {
                if pendingReset {
                    world.returnHome(manually: true)
                    pendingReset = false
                }
                if let previousOrientation, previousOrientation != sample.orientation.rawValue {
                    world.recalibrate()
                }
                previousOrientation = sample.orientation.rawValue
                let dt = previousTimestamp.map { sample.timestamp - $0 } ?? 1.0 / 60
                let wasReturning = world.phase == .returning
                if world.update(gravityX: sample.x, gravityY: sample.y, deltaTime: dt, playbackTime: playbackTime) {
                    positions = world.balls.map(\.position)
                    needsDisplay = true
                }
                let finished = wasReturning && world.phase == .home
                trails.sample(positions: positions, flying: world.phase == .returning || finished,
                              at: now, finishing: finished)
                // Only phase transitions reach the parent controls; ball frames
                // continue to invalidate just the canvas.
                if ballPhase != world.phase { ballPhase = world.phase }
                previousTimestamp = sample.timestamp
            }
            // Expire against wall time, including when the sensor has no new
            // sample. Publish the clearing frame, then stop idle redraws.
            trails.expire(at: now)
            if needsDisplay || hadTrails || trails.hasVisibleTrails {
                motionFrame = MotionFrame(positions: positions, trails: trails.snapshot, timestamp: now)
            }
            do { try await Task.sleep(for: .seconds(1.0 / 60)) }
            catch { return }
        }
    }

    private func plotRect(size: CGSize) -> CGRect {
        CGRect(x: 38, y: 22, width: max(1, size.width - 48), height: max(1, size.height - 50))
    }

    private func home(for particle: Particle, plot: CGRect, columns: Int, binWidth: Double) -> CGPoint {
        let config = movie.experiment
        let column = particle.rank % columns
        let row = particle.rank / columns
        let fraction = Double(particle.bin ?? 0) + (Double(column) + 0.5) / Double(columns)
        let count = (Double(row) + 0.5) * Double(columns)
        let density = count / Double(config.sampleCount) / config.binWidth
        let height = Double(plot.height)
        let y = height - density / movie.maximum * height
        return CGPoint(x: fraction * binWidth, y: y)
    }

    private func draw(context: inout GraphicsContext, size: CGSize, frame: MotionFrame?) {
        let plot = plotRect(size: size)
        let config = movie.experiment
        let binWidth = Double(plot.width) / Double(config.binCount)
        let columns = max(1, Int(binWidth / 3.5))
        let radius = min(2.1, binWidth / Double(columns) * 0.4)
        var settled = Path()
        var falling = Path()
        for (index, particle) in movie.particles.enumerated() {
            guard time >= particle.release, particle.bin != nil else { continue }
            let progress = min(1, (time - particle.release) / SampleMovie.flightDuration)
            let position: CGPoint
            if progress >= 1, let positions = frame?.positions, index < positions.count {
                position = CGPoint(x: plot.minX + positions[index].x, y: plot.minY + positions[index].y)
            } else {
                let home = home(for: particle, plot: plot, columns: columns, binWidth: binWidth)
                let remaining = 1 - progress
                position = CGPoint(
                    x: plot.minX + home.x + particle.drift * remaining * remaining,
                    y: plot.minY - 12 + (home.y + 12) * progress * progress
                )
            }
            let rect = CGRect(
                x: position.x - radius,
                y: position.y - radius,
                width: radius * 2, height: radius * 2
            )
            if progress >= 1 { settled.addEllipse(in: rect) }
            else { falling.addEllipse(in: rect) }
        }
        var clipped = context
        clipped.clip(to: Path(CGRect(x: plot.minX, y: 0, width: plot.width, height: plot.maxY)))
        if let frame {
            BallFlightTrailRenderer.draw(context: &clipped, batches: frame.trails, at: frame.timestamp,
                                         offset: plot.origin, color: config.distribution.color)
        }
        clipped.fill(settled, with: .color(config.distribution.color.opacity(0.7)))
        clipped.fill(falling, with: .color(config.distribution.color))
    }
}

/// Ball frames do not change these inputs. Keep text layout and the completed
/// theory's probability evaluations out of motion-driven Canvas redraws.
private struct DistributionGuides: View, Equatable {
    let movie: SampleMovie
    let plot: CGRect
    let curveProgress: Double?

    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.movie.id == rhs.movie.id && lhs.plot == rhs.plot && lhs.curveProgress == rhs.curveProgress
    }

    var body: some View {
        Canvas { context, _ in
            if let curveProgress {
                context.clip(to: Path(CGRect(x: plot.minX, y: 0, width: plot.width, height: plot.maxY)))
                drawTheory(context: &context, plot: plot, progress: curveProgress)
            } else {
                drawAxes(context: &context, plot: plot)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func point(x: Double, y: Double, plot: CGRect) -> CGPoint {
        let domain = movie.experiment.domain
        return CGPoint(
            x: plot.minX + (x - domain.lowerBound) / (domain.upperBound - domain.lowerBound) * plot.width,
            y: plot.maxY - y / movie.maximum * plot.height
        )
    }

    private func drawAxes(context: inout GraphicsContext, plot: CGRect) {
        for index in 0...3 {
            let probability = movie.maximum * Double(index) / 3
            let y = plot.maxY - Double(index) / 3 * plot.height
            var grid = Path()
            grid.move(to: CGPoint(x: plot.minX, y: y))
            grid.addLine(to: CGPoint(x: plot.maxX, y: y))
            context.stroke(grid, with: .color(.secondary.opacity(0.17)), lineWidth: 0.5)
            context.draw(Text(probability.formatted(.number.precision(.fractionLength(2)))).font(.system(size: 9)).foregroundStyle(.secondary),
                         at: CGPoint(x: plot.minX - 5, y: y), anchor: .trailing)
        }
        let config = movie.experiment
        let ticks = config.distribution.definition.ticks
        for tick in ticks {
            let p = point(x: tick, y: 0, plot: plot)
            context.draw(Text(tick.formatted(.number.precision(.fractionLength(0...2)))).font(.system(size: 10)).foregroundStyle(.secondary),
                         at: CGPoint(x: p.x, y: plot.maxY + 12))
        }
    }

    private func drawTheory(context: inout GraphicsContext, plot: CGRect, progress: Double) {
        let config = movie.experiment
        var path = Path()
        if config.distribution.isDiscrete {
            let last = config.binCount - 1
            let final = min(last, Int(progress * Double(config.binCount)))
            for k in 0...final {
                let x = Double(k)
                let p = point(x: x, y: config.probability(at: x), plot: plot)
                path.move(to: point(x: x, y: 0, plot: plot))
                path.addLine(to: p)
                context.fill(Path(ellipseIn: CGRect(x: p.x - 2.5, y: p.y - 2.5, width: 5, height: 5)), with: .color(.primary))
            }
        } else if config.distribution == .uniform {
            // Preserve the actual endpoints rather than connecting across a jump.
            let a = config.first
            let b = a + config.second
            path.move(to: point(x: a, y: 0, plot: plot))
            path.addLine(to: point(x: a, y: 1 / config.second, plot: plot))
            path.addLine(to: point(x: a + (b - a) * progress, y: 1 / config.second, plot: plot))
            if progress >= 1 { path.addLine(to: point(x: b, y: 0, plot: plot)) }
        } else {
            let steps = 400
            for index in 0...Int(Double(steps) * progress) {
                let x = config.domain.lowerBound + Double(index) / Double(steps) * (config.domain.upperBound - config.domain.lowerBound)
                let p = point(x: x, y: config.probability(at: x), plot: plot)
                if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
            }
        }
        context.stroke(path, with: .color(.primary), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
    }
}
