# Distribution Explorer

A native iPhone explorer with ten essentials in order: Normal (Gaussian), Binomial, Poisson, Uniform, Exponential, Student’s t, Beta, Gamma, Lognormal, and Chi-Square. Bernoulli is available under **More to explore**, for eleven interactive distributions in total. Built with SwiftUI's standard navigation, lists, buttons, sliders, pickers, toggles, and progress indicators. The animated plot uses Canvas.

See a [completed experiment in the iPhone simulator](iOS/Preview/normal-completed.png).

First launch explains how visual experiments help build probability intuition, then asks one question about education level. Choosing an answer opens the explorer. The answer and completion are saved on the device; the question mark in the distribution list reopens onboarding.

## Run on an iPhone simulator

Open [iOS/DistributionExplorer.xcodeproj](iOS/DistributionExplorer.xcodeproj) in Xcode, select the **DistributionExplorer** scheme and an iPhone simulator, then Run. The deployment target is iOS 17. No packages or network services are required. Running on a physical iPhone requires choosing your own signing team in Xcode.

Tap a distribution to start the movie. Dots fall into histogram bins, then the theoretical density or probability mass function is traced. Experiments default to 450 balls, with 300, 600, and 1,200 also available. Playback defaults to 2×, with 1× and 4× also available. Use Play/Pause, Replay, the speed selector, parameter sliders, and sample count to experiment. Changing parameters restarts the movie with the same underlying random sequence so comparisons are easier; Play resumes a paused movie; Replay starts over with a fresh sample.

On a physical iPhone, the balls stay locked while samples fall and the theoretical curve forms. The control beside Replay shows a lock during this phase; tap it to keep the balls locked after the curve finishes, then tap it again to unlock. Otherwise they unlock automatically after the full animation. Whenever the balls are in their histogram positions, the control shows **Lock balls**; tap to engage the lock, then tap again to unlock. Once unlocked, tilt the phone to send the balls rolling under gravity. They have individual momentum, slippery contacts, and collisions with one another and the chart edges. While rolling or returning, the control shows the **Reset balls** arrow. Only after every ball has come to rest do they lift out and float back to their exact histogram positions over about one second—even if you keep the phone tilted. Tap **Reset balls** to bring them home without restarting playback or changing the sample. A manual reset completes even if you keep tilting. A fresh tilt otherwise interrupts an automatic flight home and starts them rolling again. Replay locks the balls for the new animation. Sample values and the theoretical curve stay fixed during tilt. Motion follows portrait and landscape orientation, stops when the chart is dismissed or the app becomes inactive, and is disabled by Reduce Motion. Simulators without motion sensors show the usual animation. The graph has no explanatory footer; teaching content remains in **What you’re seeing**.

Returning balls leave fine glowing trails in the distribution’s color. Each segment fades away within half a second, including after the balls reach home or a fresh tilt interrupts the return. Trails use bounded history and shared Canvas strokes; they stop redrawing once the last segment expires and are disabled by Reduce Motion.

Below playback, native disclosure groups let you expand or collapse **Parameters**, **Examples in nature & society**, and **What you’re seeing** independently. Parameters starts expanded; the other two start collapsed. Each distribution has three examples, with the assumptions that make the model appropriate. Collapsing a section preserves its parameter values and playback state.

The examples draw on NIST's explanations of [normal measurement errors](https://www.itl.nist.gov/div898/handbook/pmd/section4/pmd445.htm), [uniform random draws](https://www.itl.nist.gov/div898/handbook/eda/section3/eda3662.htm), [exponential waiting times and constant failure rates](https://www.itl.nist.gov/div898/handbook/apr/section1/apr161.htm), and [Poisson defects](https://www.itl.nist.gov/div898/handbook/prc/section2/prc25.htm), along with the [OpenStax uniform bus-wait example](https://openstax.org/books/statistics/pages/5-2-the-uniform-distribution) and [University of Wisconsin's discussion of height models](https://pages.stat.wisc.edu/~kdlevin/teaching/Fall2022/STAT340/lecs/L00_motivation.html).

The plots use a fixed horizontal range so parameter changes visibly move or spread the pile. Rare samples outside the visible range still count toward the total. The completed histogram uses the total sample count and bin width to match the theoretical density scale. Bernoulli, Binomial, and Poisson use bins of width one and stem traces at integers. Student’s t uses degrees of freedom from 3 to 30 so the displayed mean and variance exist. Beta uses shape parameters from 1 to 10 to keep endpoint densities finite. Gamma uses shape α from 1 to 10 and scale θ from 0.25 to 2. Chi-Square uses 2 to 20 degrees of freedom. These lower bounds keep densities finite at zero. Lognormal controls describe the mean and standard deviation of the logarithm. Small differences between the pile and the theory are expected from finite sampling and binning. Reduce Motion displays the finished plot without falling dots. Playback pauses when the app becomes inactive or the experiment is dismissed.

## Validation

The project includes UI tests for all eleven experiments, playback, replay, parameter changes, curve visibility, animation completion (including while the graph is scrolled offscreen), and expanding and collapsing the three disclosure groups. Run them with Product → Test in Xcode.

The math checks run independently of the simulator:

```sh
xcrun swiftc -module-cache-path /tmp/distribution-swift-cache \
  iOS/DistributionExplorer/Distribution.swift \
  iOS/DistributionExplorer/DistributionDefinition.swift \
  iOS/DistributionExplorer/Distributions/*.swift \
  iOS/DistributionExplorer/Experiment.swift \
  iOS/DistributionExplorer/SeededRandom.swift \
  iOS/DistributionExplorer/SampleMovie.swift \
  iOS/Tests/DistributionChecks.swift \
  -o /tmp/distribution-checks
/tmp/distribution-checks
```

These check sampling moments against theory, probability normalization, histogram accounting, deterministic replay, and movie completion.

The ball physics can also be checked without device sensors:

```sh
xcrun swiftc -module-cache-path /tmp/distribution-swift-cache \
  iOS/DistributionExplorer/BallPhysics.swift iOS/Tests/BallPhysicsChecks.swift \
  -o /tmp/ball-physics-checks
/tmp/ball-physics-checks
```

These checks cover free rolling, walls, collisions in dense piles, sliding a packed pile when tilt reverses, waiting until every ball rests before returning, manual reset while moving, exact home positions while held tilted, and release timing at 30, 60, and 120 Hz. On a physical iPhone, check tilt during and after playback, rotate to landscape, interrupt an automatic flight home with another tilt, press Reset balls while rolling, and try Reduce Motion and backgrounding the app.

Idle sensor samples do not publish chart frames, and fully sleeping piles skip collision solving while waiting to return home. Physics checks also cover idle display suppression, waking sleepers, and publishing the final return frame. See the [ball motion performance audit](docs/ball-motion-performance.md) for findings, benchmark results, and device profiling limits.

## Distribution reference

The [docs directory](docs/README.md) contains 29 distribution articles with local images, including the original NIST gallery and ten additional guides. The app implements the eleven distributions above. Each distribution has its own file under `iOS/DistributionExplorer/Distributions/`, containing its teaching content, parameter controls, density or probability mass, moments, and sampling logic. `Distribution.swift` registers them; the experiment state, random generator, animation, and screen layout are shared.

## Fit your data

Simulator previews: [rankings and histogram](iOS/Preview/fit-counts.png), [Q–Q comparison](iOS/Preview/fit-qq.png).

Open **Fit your data** at the top of the distribution list. Type or paste raw samples separated by commas, spaces, semicolons, or new lines. Alternatively choose **Value / frequency** and enter one value and a positive integer frequency per line. Use decimal points. Input supports up to 10,000 observations; supported nonzero magnitudes are 1e−12 through 1e12. Processing stays on the device and updates after a short typing pause.

**Try an example** generates 60 fresh observations each time you choose Measurements or Counts, varying both the source distribution and its parameters.

Choose **Measurements** for continuous observations (including rounded measurements) or **Counts** for nonnegative integer outcomes. Measurements compare Normal, Exponential, Lognormal, and Gamma; counts compare Poisson, Geometric (failures before success), and Bernoulli when all values are binary. Binomial is omitted because the number of trials is not supplied. Models incompatible with the observations are skipped with an explanation. At least four varied observations are needed.

Parameters use maximum likelihood, including numerical profile optimization for Gamma. Fits rank by [AICc](https://www.mathworks.com/help/econ/information-criteria.html), using `−2 log L + 2k + 2k(k+1)/(n−k−1)`. Relative support weights normalize `exp(−ΔAICc/2)` across the tested candidates; they are not probabilities that a model is true. The [R likelihood/AIC documentation](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/AIC.html) explains why comparisons require the same observations and compatible likelihoods. Small samples and close contenders are flagged. Independent observations from a stable process are assumed.

A normalized histogram overlays up to three leading fits. Count spans over 80 use grouped bins and omit overlays. A selectable Q–Q plot compares up to 100 sample quantiles with a fitted model; large Gamma shape and Poisson rate parameters use a Wilson–Hilferty approximation for quantiles. Model tails can extend beyond the displayed histogram range. These plots help expose poor fits even when one candidate leads the ranking.

Simulator UI tests cover raw input with live ranking, invalid input replacing previous results, frequency input for counts, Q–Q model switching, and navigation back into existing experiments.

Run the fitting math checks separately:

```sh
xcrun swiftc -module-cache-path /tmp/distribution-swift-cache \
  iOS/DistributionExplorer/Fitting/DistributionFitter.swift \
  iOS/DistributionExplorer/SeededRandom.swift \
  iOS/Tests/FittingChecks.swift -o /tmp/fitting-checks
/tmp/fitting-checks
```
