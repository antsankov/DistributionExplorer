import Foundation
import CoreGraphics

@main
struct BallFlightChecks {
    static func main() {
        for rate in [30.0, 60.0, 120.0] {
            var trails = BallFlightTrails()
            for frame in 0...Int(rate * 3) {
                let now = Double(frame) / rate
                let positions = (0..<1_200).map { CGPoint(x: Double($0) + now * 30, y: now * 10) }
                trails.sample(positions: positions, flying: true, at: now)
                trails.expire(at: now)
                precondition(trails.batches.count <= 16, "Trail storage must stay bounded at every refresh rate")
                precondition(trails.snapshot.count <= 17, "Only one live tip may be added to the bounded history")
                if frame > 0 {
                    precondition(trails.snapshot.last?.ends == positions, "The tip must follow the ball at every refresh rate")
                }
                precondition(trails.batches.allSatisfy { now - $0.timestamp < 0.5 }, "Expired trails must be removed")
            }
            precondition(!trails.batches.isEmpty)
            let end = trails.batches.last!.ends
            trails.sample(positions: end, flying: false, at: 3.1)
            trails.expire(at: 3.25)
            precondition(!trails.batches.isEmpty, "A stopped or interrupted flight must fade rather than disappear instantly")
            trails.expire(at: 3.5)
            precondition(trails.batches.isEmpty, "Every segment must disappear within half a second")

            // A new flight must not connect across an interruption or an idle gap.
            let newStart = [CGPoint(x: 200, y: 100)]
            trails.sample(positions: newStart, flying: true, at: 4)
            precondition(trails.batches.isEmpty)
            trails.sample(positions: [.zero], flying: true, at: 4.02, finishing: true)
            precondition(trails.batches.count == 1 && trails.batches[0].starts == newStart)
            precondition(trails.batches[0].ends == [.zero], "The final home segment must be retained")
            trails.expire(at: 4.52)
            precondition(trails.batches.isEmpty)
            trails.sample(positions: newStart, flying: true, at: 5)
            trails.sample(positions: [.zero], flying: true, at: 6)
            precondition(trails.batches.isEmpty, "Sensor stalls must not create a streak across the missing interval")
            print("PASS bounded trails, half-second expiry, interruption, and final segment at \(Int(rate)) Hz")
        }

        // Check the shared 19-group calculation against the original trajectory
        // for every group, while retaining exact homes and zero momentum.
        let homes = (0..<450).map { CGPoint(x: 20 + Double($0 % 30) * 4, y: 20 + Double($0 / 30) * 4) }
        var world = BallPhysics(homes: homes, releases: Array(repeating: 0, count: homes.count),
                                width: 200, height: 160, radius: 1.5)
        world.update(gravityX: 0, gravityY: 1, deltaTime: 1.0 / 60, playbackTime: 10)
        world.update(gravityX: 0.6, gravityY: 0.8, deltaTime: 1.0 / 60, playbackTime: 10)
        let starts = world.balls.map(\.position)
        world.returnHome(manually: true)
        for frame in 1...65 {
            world.update(gravityX: 0.6, gravityY: 0.8, deltaTime: 1.0 / 60, playbackTime: 10)
            for i in homes.indices {
                let t = min(1, max(0, (Double(frame) / 60 * 3 - Double(i % 19) / 19 * 0.4) / 2.8))
                let eased = t * t * t * (10 + t * (-15 + 6 * t))
                let expected = CGPoint(x: starts[i].x + (homes[i].x - starts[i].x) * eased,
                                       y: starts[i].y + (homes[i].y - starts[i].y) * eased - sin(.pi * t) * 19.2)
                precondition(hypot(world.balls[i].position.x - expected.x, world.balls[i].position.y - expected.y) < 1e-8)
                precondition(world.balls[i].velocity == .zero)
            }
        }
        precondition(world.phase == .home && world.balls.map(\.position) == homes)
        print("PASS all 19 return trajectories, exact homes, and zero return momentum")
    }
}
