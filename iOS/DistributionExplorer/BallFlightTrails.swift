import Foundation
import CoreGraphics

/// Short, bounded position history. Immutable position arrays are shared with
/// the motion snapshot; recording a trail does not copy a physics world.
struct BallFlightTrails {
    static let lifetime = 0.5
    static let sampleInterval = 1.0 / 30
    static let maximumBatches = 16

    struct Batch {
        let timestamp: Double
        let starts: [CGPoint]
        let ends: [CGPoint]
    }

    private(set) var batches: [Batch] = []
    private var head: Batch?
    private var anchor: [CGPoint]?
    private var anchorTime = 0.0

    init() { batches.reserveCapacity(Self.maximumBatches) }

    var hasVisibleTrails: Bool { !batches.isEmpty || head != nil }

    // The live tip follows the ball at display cadence, while the retained
    // history stays at 30 Hz. All position arrays are shared, not recopied.
    var snapshot: [Batch] {
        if let head { return batches + [head] }
        return batches
    }

    mutating func sample(positions: [CGPoint], flying: Bool, at time: Double, finishing: Bool = false) {
        guard flying else {
            if let head { append(head) }
            head = nil
            anchor = nil
            return
        }
        guard let anchor else {
            head = nil
            self.anchor = finishing ? nil : positions
            anchorTime = time
            return
        }
        // Do not invent a long streak across a stalled sensor or suspended app.
        guard time - anchorTime < Self.lifetime else {
            head = nil
            self.anchor = finishing ? nil : positions
            anchorTime = time
            return
        }
        let batch = Batch(timestamp: time, starts: anchor, ends: positions)
        guard finishing || time - anchorTime >= Self.sampleInterval - 1e-9 else {
            head = batch
            return
        }
        append(batch)
        head = nil
        self.anchor = finishing ? nil : positions
        anchorTime = time
    }

    mutating func expire(at time: Double) {
        let expired = batches.prefix { time - $0.timestamp >= Self.lifetime }.count
        if expired > 0 { batches.removeFirst(expired) }
        if let head, time - head.timestamp >= Self.lifetime { self.head = nil }
    }

    private mutating func append(_ batch: Batch) {
        // This also bounds retained memory if the input cadence changes.
        if batches.count == Self.maximumBatches { batches.removeFirst() }
        batches.append(batch)
    }
}
