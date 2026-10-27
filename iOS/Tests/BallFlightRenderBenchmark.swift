import SwiftUI
import Foundation

/// Host-only offscreen drawing benchmark using the app's actual trail renderer.
/// Includes SwiftUI setup, path construction and image creation at 2× scale.
/// It does not wait for GPU completion or represent iPhone GPU/frame time.
@main
struct BallFlightRenderBenchmark {
    @MainActor
    static func main() {
        for count in [450, 1_200] {
            let homes = (0..<count).map {
                CGPoint(x: 30 + Double($0 % 30) * 10, y: 200 - Double($0 / 30) * 4)
            }
            var world = BallPhysics(homes: homes, releases: Array(repeating: 0, count: count),
                                    width: 360, height: 230, radius: 1.5)
            world.update(gravityX: 0, gravityY: 1, deltaTime: 1.0 / 60, playbackTime: 10)
            for _ in 0..<90 {
                world.update(gravityX: 0.6, gravityY: 0.8, deltaTime: 1.0 / 60, playbackTime: 10)
            }
            world.returnHome(manually: true)
            var trails = BallFlightTrails()
            var positions = world.balls.map(\.position)
            trails.sample(positions: positions, flying: true, at: 0)
            for frame in 1...28 {
                world.update(gravityX: 0.6, gravityY: 0.8, deltaTime: 1.0 / 60, playbackTime: 10)
                positions = world.balls.map(\.position)
                trails.sample(positions: positions, flying: true, at: Double(frame) / 60)
                trails.expire(at: Double(frame) / 60)
            }
            for enabled in [false, true] {
                var timings: [Double] = []
                let batches = enabled ? trails.snapshot : []
                let snapshot = positions
                for frame in 0..<35 {
                    let start = ProcessInfo.processInfo.systemUptime
                    let time = 28.0 / 60 + Double(frame) * 1e-6
                    let view = Canvas { context, _ in
                        BallFlightTrailRenderer.draw(context: &context, batches: batches, at: time,
                                                     offset: CGPoint(x: 20, y: 20), color: .blue)
                        var dots = Path()
                        for point in snapshot {
                            dots.addEllipse(in: CGRect(x: point.x + 18.5, y: point.y + 18.5, width: 3, height: 3))
                        }
                        context.fill(dots, with: .color(.blue.opacity(0.7)))
                    }
                    .frame(width: 400, height: 270)
                    .background(.white)
                    let renderer = ImageRenderer(content: view)
                    renderer.scale = 2
                    precondition(renderer.cgImage?.width == 800)
                    let elapsed = (ProcessInfo.processInfo.systemUptime - start) * 1_000
                    if frame >= 5 { timings.append(elapsed) }
                }
                timings.sort()
                print(String(format: "%4d balls, trails %@: host image creation mean %.3f ms, p95 %.3f ms",
                             count, enabled ? "on" : "off", timings.reduce(0, +) / Double(timings.count),
                             timings[Int(Double(timings.count) * 0.95)]))
            }
        }
    }
}
