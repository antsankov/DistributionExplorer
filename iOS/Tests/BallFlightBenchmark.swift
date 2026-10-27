import Foundation
import CoreGraphics

/// Optimized host timings for return physics and trail sampling, excluding
/// SwiftUI/GPU rendering. No hardware-dependent performance assertion.
@main
struct BallFlightBenchmark {
    static func main() {
        for count in [450, 1_200] {
            let homes = (0..<count).map { CGPoint(x: 20 + Double($0 % 30) * 4, y: 20 + Double($0 / 30) * 4) }
            var seed = BallPhysics(homes: homes, releases: Array(repeating: 0, count: count),
                                   width: 300, height: 210, radius: 1.5)
            seed.update(gravityX: 0, gravityY: 1, deltaTime: 1.0 / 60, playbackTime: 10)
            seed.update(gravityX: 0.6, gravityY: 0.8, deltaTime: 1.0 / 60, playbackTime: 10)
            var physicsTime = 0.0
            var trailTime = 0.0
            var checksum = 0.0
            var maximumBatches = 0
            for _ in 0..<100 {
                var world = seed
                world.returnHome(manually: true)
                var trails = BallFlightTrails()
                for frame in 0..<96 {
                    let start = ProcessInfo.processInfo.systemUptime
                    let changed = world.update(gravityX: 0.6, gravityY: 0.8, deltaTime: 1.0 / 60, playbackTime: 10)
                    let simulated = ProcessInfo.processInfo.systemUptime
                    if changed {
                        trails.sample(positions: world.balls.map(\.position), flying: true,
                                      at: Double(frame) / 60, finishing: world.phase == .home)
                    }
                    trails.expire(at: Double(frame) / 60)
                    let snapshot = trails.snapshot
                    physicsTime += simulated - start
                    trailTime += ProcessInfo.processInfo.systemUptime - simulated
                    maximumBatches = max(maximumBatches, trails.batches.count)
                    checksum += world.balls[frame % count].position.x + Double(snapshot.count)
                }
                precondition(!trails.hasVisibleTrails)
            }
            print(String(format: "%4d balls: return physics %.4f ms/update, snapshot + trail sampling %.4f ms/update, max batches %d, checksum %.4f",
                         count, physicsTime / 9_600 * 1_000, trailTime / 9_600 * 1_000, maximumBatches, checksum))
        }
    }
}
