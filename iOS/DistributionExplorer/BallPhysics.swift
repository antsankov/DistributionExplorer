import Foundation
import CoreGraphics

/// Free rolling, a short rest, then a separate flight home. No tether acts
/// during rolling: the balls can leave their histogram bins and collide.
struct BallPhysics {
    struct Ball {
        let home: CGPoint
        let release: Double
        var position: CGPoint
        var velocity = CGPoint.zero
        var active = false
        var sleeping = false
        var restTime = 0.0
        var restAnchor: CGPoint?
    }

    enum Phase { case home, rolling, returning }
    private(set) var balls: [Ball]
    private(set) var phase = Phase.home
    let width: Double
    let height: Double
    let radius: Double
    private var reference: CGPoint?
    private var previousGravity: CGPoint?
    private var quietTime = 0.0
    private var restingTime = 0.0
    private var returnTime = 0.0
    private var returnStarts: [CGPoint] = []
    private var manualReturn = false
    private var rollingGravity = CGPoint.zero

    init(homes: [CGPoint], releases: [Double], width: Double, height: Double, radius: Double) {
        balls = zip(homes, releases).map { Ball(home: $0, release: $1, position: $0) }
        self.width = max(radius * 2, width)
        self.height = max(radius * 2, height)
        self.radius = radius
    }

    mutating func recalibrate() {
        reference = nil
        previousGravity = nil
        quietTime = 0
    }

    mutating func returnHome(manually: Bool = false) {
        guard phase != .home else { return }
        phase = .returning
        returnTime = 0
        restingTime = 0
        returnStarts = balls.map(\.position)
        manualReturn = manually
        reference = previousGravity
        for i in balls.indices { balls[i].velocity = .zero }
    }

    mutating func update(gravityX: Double, gravityY: Double, deltaTime: Double, playbackTime: Double) {
        guard gravityX.isFinite, gravityY.isFinite, deltaTime.isFinite, deltaTime > 0 else { return }
        let gravity = CGPoint(x: gravityX, y: gravityY)
        let dt = min(deltaTime, 1.0 / 15)
        for i in balls.indices where !balls[i].active && playbackTime >= balls[i].release {
            balls[i].active = true
        }
        guard let reference, let previousGravity else {
            self.reference = gravity
            self.previousGravity = gravity
            return
        }
        let change = hypot(gravity.x - previousGravity.x, gravity.y - previousGravity.y)
        quietTime = change / dt > 0.35 ? 0 : quietTime + dt
        self.previousGravity = gravity

        // A fresh tilt starts/restarts rolling, including during the flight home.
        if hypot(gravity.x - reference.x, gravity.y - reference.y) > 0.055,
           phase != .rolling, !manualReturn, balls.contains(where: \.active) {
            phase = .rolling
            wakeBalls(gravity: gravity)
            restingTime = 0
            quietTime = 0
        }
        switch phase {
        case .home: break
        case .rolling:
            if hypot(gravity.x - rollingGravity.x, gravity.y - rollingGravity.y) > 0.025 {
                wakeBalls(gravity: gravity)
            }
            let steps = Int(ceil(dt * 120))
            for _ in 0..<steps { roll(gravity: gravity, dt: dt / Double(steps)) }
            // Sleep individual balls after sustained stillness. Sleeping contact
            // surfaces prevent numerical jitter from keeping a packed pile awake.
            for i in balls.indices where balls[i].active && !balls[i].sleeping {
                let anchor = balls[i].restAnchor ?? balls[i].position
                let drift = hypot(balls[i].position.x - anchor.x, balls[i].position.y - anchor.y)
                if balls[i].restAnchor == nil || drift > max(0.25, radius * 0.5) {
                    balls[i].restAnchor = balls[i].position
                    balls[i].restTime = 0
                } else {
                    balls[i].restTime += dt
                }
                if balls[i].restTime > 0.5 {
                    balls[i].sleeping = true
                    balls[i].velocity = .zero
                }
            }
            let allAtRest = balls.allSatisfy { !$0.active || $0.sleeping }
            restingTime = allAtRest && quietTime > 0.4 ? restingTime + dt : 0
            if restingTime > 0.65 {
                returnHome()
            }
        case .returning:
            returnTime += dt
            for i in balls.indices where balls[i].active {
                // A little stagger gives each ball its own floating trajectory.
                let delay = Double(i % 19) / 19 * 0.4
                let t = min(1, max(0, (returnTime - delay) / 2.8))
                let eased = t * t * t * (10 + t * (-15 + 6 * t))
                let start = returnStarts[i]
                balls[i].position = CGPoint(
                    x: start.x + (balls[i].home.x - start.x) * eased,
                    y: start.y + (balls[i].home.y - start.y) * eased - sin(.pi * t) * min(24, height * 0.12)
                )
                balls[i].velocity = .zero
            }
            if returnTime >= 3.2 {
                for i in balls.indices { balls[i].position = balls[i].home }
                phase = .home
                manualReturn = false
                self.reference = gravity
            }
        }
    }

    private mutating func wakeBalls(gravity: CGPoint) {
        rollingGravity = gravity
        for i in balls.indices {
            balls[i].sleeping = false
            balls[i].restTime = 0
            balls[i].restAnchor = nil
        }
    }

    private mutating func roll(gravity: CGPoint, dt: Double) {
        let previousPositions = balls.map(\.position)
        for i in balls.indices where balls[i].active && !balls[i].sleeping {
            balls[i].velocity.x = (balls[i].velocity.x + gravity.x * 520 * dt) * exp(-0.6 * dt)
            balls[i].velocity.y = (balls[i].velocity.y + gravity.y * 520 * dt) * exp(-0.6 * dt)
            // Keep travel below one ball diameter per physics substep so fast,
            // slippery balls still make contact rather than passing through.
            let speed = hypot(balls[i].velocity.x, balls[i].velocity.y)
            let limit = radius / dt
            if speed > limit {
                balls[i].velocity.x *= limit / speed
                balls[i].velocity.y *= limit / speed
            }
            balls[i].position.x += balls[i].velocity.x * dt
            balls[i].position.y += balls[i].velocity.y * dt
            confine(i)
        }
        // Spatial buckets keep contact work local, including at 1,200 samples.
        let diameter = radius * 2
        let stride = Int(ceil(width / diameter)) + 3
        for _ in 0..<3 {
            var buckets: [Int: [Int]] = [:]
            for i in balls.indices where balls[i].active {
                let col = Int(balls[i].position.x / diameter)
                let row = Int(balls[i].position.y / diameter)
                buckets[row * stride + col, default: []].append(i)
            }
            for i in balls.indices where balls[i].active {
                let col = Int(balls[i].position.x / diameter)
                let row = Int(balls[i].position.y / diameter)
                for dy in -1...1 {
                    for dx in -1...1 {
                        for j in buckets[(row + dy) * stride + col + dx] ?? [] where j > i {
                            collide(i, j, diameter: diameter)
                        }
                    }
                }
                confine(i)
            }
            for i in balls.indices where balls[i].active { confine(i) }
        }
        // Feed the constrained movement back into momentum. Otherwise dense
        // contact chains retain velocity into blocked surfaces, continually
        // injecting jitter even though the pile has nowhere left to travel.
        for i in balls.indices where balls[i].active && !balls[i].sleeping {
            let actualX = (balls[i].position.x - previousPositions[i].x) / dt
            let actualY = (balls[i].position.y - previousPositions[i].y) / dt
            balls[i].velocity.x = actualX * 0.8 + balls[i].velocity.x * 0.2
            balls[i].velocity.y = actualY * 0.8 + balls[i].velocity.y * 0.2
        }
    }

    private mutating func collide(_ i: Int, _ j: Int, diameter: Double) {
        let dx = balls[j].position.x - balls[i].position.x
        let dy = balls[j].position.y - balls[i].position.y
        let distance = hypot(dx, dy)
        guard distance < diameter else { return }
        let nx = distance > 0.0001 ? dx / distance : 1
        let ny = distance > 0.0001 ? dy / distance : 0
        let relative = (balls[j].velocity.x - balls[i].velocity.x) * nx
            + (balls[j].velocity.y - balls[i].velocity.y) * ny
        if relative < -40 {
            balls[i].sleeping = false
            balls[j].sleeping = false
            balls[i].restTime = 0
            balls[j].restTime = 0
            balls[i].restAnchor = nil
            balls[j].restAnchor = nil
        }
        let massI = balls[i].sleeping ? 0.0 : 1.0
        let massJ = balls[j].sleeping ? 0.0 : 1.0
        let total = massI + massJ
        guard total > 0 else { return }
        let correction = (diameter - distance) / total
        balls[i].position.x -= nx * correction * massI
        balls[i].position.y -= ny * correction * massI
        balls[j].position.x += nx * correction * massJ
        balls[j].position.y += ny * correction * massJ
        if relative < 0 {
            let impulse = -relative * 1.02 / total
            balls[i].velocity.x -= impulse * nx * massI
            balls[i].velocity.y -= impulse * ny * massI
            balls[j].velocity.x += impulse * nx * massJ
            balls[j].velocity.y += impulse * ny * massJ
            // A small Coulomb friction impulse opposes only sliding along the
            // contact. Multiplying both velocities at every contact used to
            // drain downhill momentum repeatedly and glue dense piles together.
            let tangentX = -ny
            let tangentY = nx
            let slip = (balls[j].velocity.x - balls[i].velocity.x) * tangentX
                + (balls[j].velocity.y - balls[i].velocity.y) * tangentY
            let friction = min(impulse * 0.015, max(-impulse * 0.015, -slip / total))
            balls[i].velocity.x -= friction * tangentX * massI
            balls[i].velocity.y -= friction * tangentY * massI
            balls[j].velocity.x += friction * tangentX * massJ
            balls[j].velocity.y += friction * tangentY * massJ
        }
    }

    private mutating func confine(_ i: Int) {
        if balls[i].position.x < radius || balls[i].position.x > width - radius {
            balls[i].position.x = min(width - radius, max(radius, balls[i].position.x))
            balls[i].velocity.x *= -0.05
            balls[i].velocity.y *= 0.99
        }
        if balls[i].position.y < radius || balls[i].position.y > height - radius {
            balls[i].position.y = min(height - radius, max(radius, balls[i].position.y))
            balls[i].velocity.y *= -0.05
            balls[i].velocity.x *= 0.99
        }
    }
}
