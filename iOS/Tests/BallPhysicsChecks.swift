import Foundation
import CoreGraphics

@main
struct BallPhysicsChecks {
    static func main() {
        for rate in [30.0, 60.0, 120.0] {
            let dt = 1 / rate
            let homes = [CGPoint(x: 50, y: 35), CGPoint(x: 60, y: 35)]
            var world = BallPhysics(homes: homes, releases: [0, 0], width: 200, height: 160, radius: 2)
            world.update(gravityX: 0, gravityY: 1, deltaTime: dt, playbackTime: 10)
            assert(world.phase == .home && world.balls.map(\.position) == homes)
            for _ in 0..<Int(rate * 0.5) {
                world.update(gravityX: 0.6, gravityY: 0.8, deltaTime: dt, playbackTime: 10)
            }
            assert(world.phase == .rolling, "Rolling must precede returning")
            assert(world.balls[0].position.x > homes[0].x + 15, "Balls must roll freely beyond a small spring displacement")
            assert(world.balls[0].position.y > homes[0].y + 15, "Screen gravity must pull balls down")
            var sawReturn = false
            var returnedSmoothly = false
            for _ in 0..<Int(rate * 20) {
                let previous = world.balls[0].position
                world.update(gravityX: 0.6, gravityY: 0.8, deltaTime: dt, playbackTime: 10)
                if world.phase == .returning {
                    sawReturn = true
                    if hypot(previous.x - homes[0].x, previous.y - homes[0].y) > 20 {
                        assert(hypot(world.balls[0].position.x - previous.x, world.balls[0].position.y - previous.y) < 15,
                               "Flight home must be gradual")
                        returnedSmoothly = true
                    }
                }
                if sawReturn && world.phase == .home { break }
            }
            assert(sawReturn && returnedSmoothly, "Settled balls must fly home")
            assert(world.phase == .home && world.balls.map(\.position) == homes, "Every ball must return exactly home while held tilted")

            world.update(gravityX: -0.6, gravityY: 0.8, deltaTime: dt, playbackTime: 10)
            assert(world.phase == .rolling, "A fresh tilt must restart rolling")
            for _ in 0..<Int(rate * 12) {
                world.update(gravityX: -0.6, gravityY: 0.8, deltaTime: dt, playbackTime: 10)
                if world.phase == .returning { break }
            }
            assert(world.phase == .returning)
            world.update(gravityX: 0.6, gravityY: 0.8, deltaTime: dt, playbackTime: 10)
            assert(world.phase == .rolling, "A fresh tilt must interrupt the flight home")

            let samplesBeforeReset = world.balls.map(\.home)
            world.returnHome(manually: true)
            assert(world.phase == .returning, "Reset must work while balls are still moving")
            for frame in 0..<Int(rate * 3.5) {
                let direction = frame.isMultiple(of: 2) ? -0.6 : 0.6
                world.update(gravityX: direction, gravityY: 0.8, deltaTime: dt, playbackTime: 10)
                if world.phase == .home { break }
                assert(world.phase == .returning, "An explicit reset must complete despite further tilt")
            }
            assert(world.phase == .home && world.balls.map(\.position) == homes)
            assert(world.balls.map(\.home) == samplesBeforeReset, "Reset must preserve the sample")

            var touching = BallPhysics(homes: [CGPoint(x: 50, y: 50), CGPoint(x: 53, y: 50)],
                                       releases: [0, 0], width: 200, height: 160, radius: 2)
            touching.update(gravityX: 0, gravityY: 1, deltaTime: dt, playbackTime: 10)
            touching.update(gravityX: 0.5, gravityY: 0.86, deltaTime: dt, playbackTime: 10)
            let a = touching.balls[0].position
            let b = touching.balls[1].position
            assert(hypot(a.x - b.x, a.y - b.y) >= 3.99, "Collisions must separate overlapping balls")

            // Dense piles exercise local collisions and the settling detector.
            let count = rate == 60 ? 1_200 : 300
            let pile = (0..<count).map { CGPoint(x: 25 + Double($0 % 30) * 3, y: 20 + Double($0 / 30) * 3) }
            var crowded = BallPhysics(homes: pile, releases: Array(repeating: 0, count: pile.count), width: 200, height: 160, radius: 1.5)
            crowded.update(gravityX: 0, gravityY: 1, deltaTime: dt, playbackTime: 10)
            var crowdedReturn = false
            for _ in 0..<Int(rate * 90) {
                crowded.update(gravityX: 0.5, gravityY: 0.86, deltaTime: dt, playbackTime: 10)
                if crowded.phase == .rolling {
                    for ball in crowded.balls {
                        assert(ball.position.x >= 1.5 && ball.position.x <= 198.5)
                        assert(ball.position.y >= 1.5 && ball.position.y <= 158.5)
                    }
                }
                crowdedReturn = crowdedReturn || crowded.phase == .returning
                if crowded.phase == .returning {
                    assert(crowded.balls.allSatisfy { !$0.active || $0.sleeping },
                           "Automatic return must wait for every ball, not average pile speed")
                }
                if crowdedReturn && crowded.phase == .home { break }
            }
            assert(crowdedReturn && crowded.phase == .home, "A crowded pile must settle and return")
            assert(crowded.balls.map(\.position) == pile)

            // A packed pile must slide across the chart when tilt reverses,
            // rather than losing all momentum through repeated contacts.
            var sliding = BallPhysics(homes: pile, releases: Array(repeating: 0, count: pile.count),
                                      width: 200, height: 160, radius: 1.5)
            sliding.update(gravityX: 0, gravityY: 1, deltaTime: dt, playbackTime: 10)
            for _ in 0..<Int(rate * 2) {
                sliding.update(gravityX: 0.5, gravityY: 0.86, deltaTime: dt, playbackTime: 10)
            }
            let startX = sliding.balls.reduce(0.0) { $0 + $1.position.x } / Double(count)
            for _ in 0..<Int(rate * 2) {
                sliding.update(gravityX: -0.5, gravityY: 0.86, deltaTime: dt, playbackTime: 10)
            }
            let endX = sliding.balls.reduce(0.0) { $0 + $1.position.x } / Double(count)
            assert(startX - endX > 60, "Dense piles must remain slippery when tilt reverses")

            // Unreleased samples stay out of the physics world.
            var delayed = BallPhysics(homes: homes, releases: [0, 100], width: 200, height: 160, radius: 2)
            delayed.update(gravityX: 0, gravityY: 1, deltaTime: dt, playbackTime: 10)
            delayed.update(gravityX: 0.6, gravityY: 0.8, deltaTime: dt, playbackTime: 10)
            assert(!delayed.balls[1].active && delayed.balls[1].position == homes[1])
            let before = delayed.balls.map(\.position)
            delayed.update(gravityX: .nan, gravityY: 0, deltaTime: dt, playbackTime: 10)
            assert(delayed.balls.map(\.position) == before)
            print("PASS rolling, walls, settling, reset, slippery dense piles, and release timing at \(Int(rate)) Hz")
        }
    }
}
