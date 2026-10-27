import CoreMotion
import UIKit

/// Accessed only by the visible chart's main-actor task.
@MainActor
final class ChartMotion {
    static let shared = ChartMotion()
    private let manager = CMMotionManager()
    private var session: UUID?

    private init() {}

    func start() -> UUID? {
        guard manager.isDeviceMotionAvailable else { return nil }
        let session = UUID()
        self.session = session
        manager.deviceMotionUpdateInterval = 1.0 / 60
        manager.startDeviceMotionUpdates()
        return session
    }

    func stop(session: UUID) {
        guard self.session == session else { return }
        manager.stopDeviceMotionUpdates()
        self.session = nil
    }

    var sample: (x: Double, y: Double, timestamp: Double, orientation: UIInterfaceOrientation)? {
        guard let motion = manager.deviceMotion else { return nil }
        let orientation = (UIApplication.shared.connectedScenes.first {
            $0.activationState == .foregroundActive
        } as? UIWindowScene)?.interfaceOrientation ?? .portrait
        let gravity = motion.gravity
        let vector: (Double, Double)
        switch orientation {
        case .landscapeLeft: vector = (-gravity.y, -gravity.x)
        case .landscapeRight: vector = (gravity.y, gravity.x)
        case .portraitUpsideDown: vector = (-gravity.x, gravity.y)
        default: vector = (gravity.x, -gravity.y)
        }
        return (vector.0, vector.1, motion.timestamp, orientation)
    }
}
