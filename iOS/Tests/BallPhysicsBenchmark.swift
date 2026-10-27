import Foundation
import CoreGraphics

/// Run with swiftc -O alongside BallPhysics.swift. Timings are host wall time
/// per update, not device frame rates; no machine-dependent pass threshold.
@main
struct BallPhysicsBenchmark {
    static func main() {
        for count in [450, 600, 1_200] {
            let homes = (0..<count).map {
                CGPoint(x: 25 + Double($0 % 30) * 3, y: 20 + Double($0 / 30) * 3)
            }
            var world = BallPhysics(homes: homes, releases: Array(repeating: 0, count: count),
                                    width: 300, height: 210, radius: 1.5)
            world.update(gravityX: 0, gravityY: 1, deltaTime: 1.0 / 60, playbackTime: 10)
            let idleStart = ProcessInfo.processInfo.systemUptime
            for _ in 0..<10_000 {
                world.update(gravityX: 0, gravityY: 1, deltaTime: 1.0 / 60, playbackTime: 10)
            }
            let idle = (ProcessInfo.processInfo.systemUptime - idleStart) / 10_000 * 1_000
            var timings: [Double] = []
            for frame in 0..<600 {
                let start = ProcessInfo.processInfo.systemUptime
                world.update(gravityX: frame / 120 % 2 == 0 ? 0.5 : -0.5,
                             gravityY: 0.86, deltaTime: 1.0 / 60, playbackTime: 10)
                timings.append((ProcessInfo.processInfo.systemUptime - start) * 1_000)
            }
            precondition(world.balls.allSatisfy { $0.position.x.isFinite && $0.position.y.isFinite })
            timings.sort()
            let mean = timings.reduce(0, +) / Double(timings.count)
            print(String(format: "%4d balls: idle %.4f ms, moving mean %.3f ms, p95 %.3f ms, checksum %.2f",
                         count, idle, mean, timings[Int(Double(timings.count) * 0.95)],
                         world.balls.reduce(0.0) { $0 + $1.position.x + $1.position.y }))
        }
    }
}
