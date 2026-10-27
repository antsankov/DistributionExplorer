import SwiftUI

enum BallFlightTrailRenderer {
    /// Six age bands, each drawn as one shared halo and one fine luminous core.
    /// No per-ball views, blur filters, or offscreen glow surfaces.
    static func draw(context: inout GraphicsContext, batches: [BallFlightTrails.Batch],
                     at time: Double, offset: CGPoint, color: Color) {
        guard !batches.isEmpty else { return }
        let bandCount = 6
        var paths = Array(repeating: Path(), count: bandCount)
        for batch in batches {
            let age = max(0, time - batch.timestamp) / BallFlightTrails.lifetime
            guard age < 1 else { continue }
            let band = min(bandCount - 1, Int(age * Double(bandCount)))
            for index in batch.starts.indices where index < batch.ends.count {
                let start = batch.starts[index]
                let end = batch.ends[index]
                let dx = end.x - start.x
                let dy = end.y - start.y
                // Still balls, including out-of-range samples, emit no trail.
                guard dx * dx + dy * dy > 0.04 else { continue }
                paths[band].move(to: CGPoint(x: offset.x + start.x, y: offset.y + start.y))
                paths[band].addLine(to: CGPoint(x: offset.x + end.x, y: offset.y + end.y))
            }
        }
        for band in paths.indices where !paths[band].isEmpty {
            let remaining = 1 - (Double(band) + 0.5) / Double(bandCount)
            let fade = remaining * remaining
            context.stroke(paths[band], with: .color(color.opacity(0.10 * fade)),
                           style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
            context.stroke(paths[band], with: .color(color.opacity(0.48 * fade)),
                           style: StrokeStyle(lineWidth: 0.9, lineCap: .round, lineJoin: .round))
        }
    }
}
