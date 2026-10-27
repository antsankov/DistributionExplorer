# Ball motion performance audit

Audited on 2026-10-27. Default sample count is now 450; the picker also offers 300, 600, and 1,200.

## Findings and changes

| Area | Previous work | Change |
| --- | --- | --- |
| Idle chart | Every sensor poll assigned the entire physics world to SwiftUI state, even at home or with a duplicate timestamp. | Ignore duplicate timestamps and publish positions only when the simulation requests a motion frame. Home samples only maintain tilt detection. |
| Sleeping pile | Every update still ran all substeps, rebuilt collision buckets, and checked contacts while waiting for automatic return. | Skip integration and contact solving when every active ball sleeps. Continue the rest timer and wake on fresh tilt. Skip pairs of sleeping balls in mixed piles. |
| Simulation storage | Each substep allocated previous positions; each of three collision passes allocated a dictionary of bucket arrays. Publishing the world also shared its ball array with the UI, forcing copy-on-write on subsequent mutations. | Reuse position storage and a dictionary of linked bucket heads, preserving collision order. Only a position array crosses into SwiftUI. |
| Contact calculations | Damping was calculated inside the ball loop; candidate pairs calculated a distance even when separated. | Calculate damping once per substep and reject separated pairs using squared distance. |
| Drawing | Each moving ball recalculated its histogram home and falling trajectory. Each frame also laid out axes and evaluated up to 401 theory points. | Read simulated positions directly. Separate axes and theory into equatable Canvas views whose inputs stay fixed during ball motion. Preserve the curve above the balls and clipping. |
| Release checks | Every update scanned all balls for newly landed samples. | Only scan when the next finite release time is reached; completed movies have no further release scans. |

The existing lifecycle stops sensors when motion is disabled, the scene is inactive, Reduce Motion is enabled, or the chart task is cancelled. Playback already pauses its timeline at completion. These safeguards remain in place. Unlocked charts still poll motion at 60 Hz to detect a fresh tilt; idle means no physics solving or motion-triggered chart publication, not zero sensor activity. Offscreen cancellation in a lazy List still depends on SwiftUI's view lifecycle.

## Host benchmark

The checked-in benchmark runs 10,000 home updates and 600 updates at 60 Hz with tilt reversing every two seconds. Results below are medians of three optimized runs on the development Mac, comparing the original and updated physics at the **same** ball count. Runs had other development activity, so they are indicative rather than isolated laboratory measurements.

| Balls | Previous mean/update | Updated mean/update | Reduction |
| ---: | ---: | ---: | ---: |
| 450 | 0.908 ms | 0.448 ms | 51% |
| 600 | 1.267 ms | 0.668 ms | 47% |
| 1,200 | 2.424 ms | 1.487 ms | 39% |

Final position checksums matched at every count. The updated idle path measured below 0.00005 ms per update at the benchmark's output precision. This excludes sensor access, SwiftUI, rendering, and GPU work; it is not a claim about iPhone frame rate or battery life. The default count reduction is separate from these same-count gains.

Reproduce the current benchmark:

```sh
xcrun swiftc -O -module-cache-path /tmp/distribution-swift-cache \
  iOS/DistributionExplorer/BallPhysics.swift iOS/Tests/BallPhysicsBenchmark.swift \
  -o /tmp/ball-physics-benchmark
/tmp/ball-physics-benchmark
```

## Validation and remaining device checks

Physics checks pass at 30, 60, and 120 Hz, including 1,200-ball dense piles, collisions, bounds, tilt reversals, automatic/manual return, exact home positions, and future releases. Added checks verify that idle and sleeping frames do not request display, a fresh tilt wakes sleepers, and the final return frame is published. Distribution math checks also pass across all eleven distributions and their parameter extremes.

The simulator build and four existing UI tests pass: finished controls/reset, lock persistence and unlocking, parameters/curve visibility/completion, and playback completion while the chart is scrolled offscreen.

Physical-device Instruments profiling is still needed to measure end-to-end frame time, allocations, energy, and sensor behavior. In particular, compare locked, unlocked at home, rolling, sleeping, and returning states at 450 and 1,200 balls; verify backgrounding, Reduce Motion, navigation away, rotation, and scrolling the chart offscreen. Simulator UI tests cannot exercise real Core Motion input.

## Return flight and glow trails

The return flight lasts about 1.1 seconds. It already avoids collision solving. The audit found repeated easing and sine calculations for every ball, although there are only 19 stagger groups. These calculations now run once per group per frame. Velocities are zeroed once at return start, rather than again for every ball on every flight frame. Checks compare every trajectory against the original formula and retain exact home positions.

Glowing trails appear during the return flight, behind the balls and inside the existing chart clip. Their history samples at 30 Hz, with one live tip that follows each display update. At most 16 history batches and one live tip are retained, sharing immutable position arrays with the motion snapshot. This is roughly 0.35 MB of point data at 1,200 balls, excluding metadata and renderer snapshots. A sensor gap of half a second or longer starts a fresh tip instead of inventing a streak across missing samples.

The renderer groups segments into six age bands. Each band uses one wide translucent halo stroke and one narrow core: at most 12 strokes for the whole chart. No ball has its own blur filter, view, or glow surface. Stationary segments are skipped. Each segment expires after 0.5 seconds of wall time, including when sensor readings stop or flight is interrupted. The final clearing frame is published; subsequent idle polls do not redraw. Replay, locking, scene changes, layout changes, and Reduce Motion discard the motion session and its trails.

Updated optimized host measurements (a representative run):

| Balls | Return physics before | Return physics after | Position snapshot + trail sampling |
| ---: | ---: | ---: | ---: |
| 450 | 0.0015 ms/update | 0.0006 ms/update | 0.0004 ms/update |
| 1,200 | 0.0040 ms/update | 0.0016 ms/update | 0.0012 ms/update |

These averages cover 100 return cycles of 96 updates each at 60 Hz: the flight followed by its trail fade. Checksums match before and after. Return arithmetic was already inexpensive; trail drawing is the larger added cost.

The host image-creation benchmark uses the actual trail renderer with 450 or 1,200 balls in mid-flight at 400 × 270 points and 2× scale. After five warmup images, it averages 30 images:

| Balls | Without trails | With trails | With trails, p95 |
| ---: | ---: | ---: | ---: |
| 450 | 0.045 ms | 0.346 ms | 0.365 ms |
| 1,200 | 0.072 ms | 0.831 ms | 0.903 ms |

This measures SwiftUI setup, path construction, and `ImageRenderer` image creation on the development Mac. It does **not** synchronize GPU completion or measure iPhone frame time. The new effect adds drawing work; bounded history, shared strokes, and stopping after fade keep that work limited. Device Instruments profiling remains necessary for end-to-end rendering and energy measurements.

Flight checks cover bounded history and a live tip at 30/60/120 Hz, exact half-second expiry, interrupted flights, stalled sensors, the final home segment, all 19 return trajectories, and zero return momentum. Existing dense-pile physics checks also pass. The simulator build and two UI checks for lock/unlock and parameter/curve/playback behavior pass. The actual renderer was visually inspected in light and dark host previews; simulator tests do not exercise device tilt.

Run the flight checks:

```sh
xcrun swiftc -module-cache-path /tmp/distribution-swift-cache \
  iOS/DistributionExplorer/BallPhysics.swift \
  iOS/DistributionExplorer/BallFlightTrails.swift \
  iOS/Tests/BallFlightChecks.swift -o /tmp/ball-flight-checks
/tmp/ball-flight-checks
```

For return CPU/sampling timings, compile those first two sources with `iOS/Tests/BallFlightBenchmark.swift` and `-O` instead. For host image-creation timings, also include `iOS/DistributionExplorer/BallFlightTrailRenderer.swift` and use `iOS/Tests/BallFlightRenderBenchmark.swift` as the main source.
