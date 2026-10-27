"""Regenerate the original distribution figures with NumPy, SciPy and Matplotlib.

Install: python -m pip install numpy scipy matplotlib
Run from any directory: python scripts/generate_distribution_plots.py
The script only writes its 20 PNG figures in docs/assets/generated/.
"""

import os
from pathlib import Path
import tempfile
import textwrap

# Keep Matplotlib's font cache out of the user's configuration directory.
os.environ.setdefault("MPLCONFIGDIR", str(Path(tempfile.gettempdir()) / "distribution-explorer-mpl"))
os.environ.setdefault("XDG_CACHE_HOME", str(Path(tempfile.gettempdir()) / "distribution-explorer-cache"))

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
from scipy import stats


OUTPUT = Path(__file__).resolve().parents[1] / "docs" / "assets" / "generated"
COLORS = ("#1764ab", "#d15b16", "#268154")


def specifications():
    """Use the parameter conventions stated in the corresponding guides."""
    return [
        ("bernoulli", "Bernoulli", np.arange(-1, 3), True,
         [(f"p = {p:g}", stats.bernoulli(p)) for p in (0.2, 0.5, 0.8)], ""),
        ("geometric", "Geometric", np.arange(0, 26), True,
         [(f"p = {p:g}", stats.geom(p)) for p in (0.15, 0.35, 0.65)],
         "Counts trials including the first success; the right tail continues beyond the plot."),
        ("negative-binomial", "Negative binomial", np.arange(-1, 33), True,
         [(f"r = {r}, p = {r / (r + 6):.3g}", stats.nbinom(r, r / (r + 6)))
          for r in (1, 3, 12)],
         "All curves have mean 6 failures; the right tail continues beyond the plot."),
        ("hypergeometric", "Hypergeometric", np.arange(-1, 12), True,
         [(f"N = 50, K = {k}, n = 10", stats.hypergeom(M=50, n=k, N=10))
          for k in (10, 25, 40)], "Sampling without replacement; N denotes population size."),
        ("pareto", "Pareto Type I", np.linspace(0, 8, 1601), False,
         [(rf"$x_m = 1,\ \alpha = {a:g}$", stats.pareto(a, scale=1))
          for a in (0.8, 1.5, 3)], "The right tail continues beyond the plot."),
        ("logistic", "Logistic", np.linspace(-10, 10, 1601), False,
         [(rf"$\mu = 0,\ s = {s:g}$", stats.logistic(loc=0, scale=s))
          for s in (0.5, 1, 2)], "Both tails continue beyond the plot."),
        ("triangular", "Triangular", np.linspace(-1, 11, 1601), False,
         [(f"a = 0, m = {m}, b = 10", stats.triang(m / 10, loc=0, scale=10))
          for m in (2, 5, 8)], ""),
        ("rayleigh", "Rayleigh", np.linspace(0, 8, 1601), False,
         [(rf"$\sigma = {s:g}$", stats.rayleigh(scale=s)) for s in (0.5, 1, 2)],
         "The right tail continues beyond the plot."),
        ("generalized-extreme-value", "Generalized extreme value", np.linspace(-4, 8, 2401), False,
         [(rf"$\mu = 0,\ \sigma = 1,\ \xi = {xi:g}$", stats.genextreme(c=-xi))
          for xi in (-0.3, 0, 0.3)],
         "Uses xi = -SciPy c; xi = 0 is the maximum Gumbel case. Unbounded tails extend beyond the plot."),
        ("von-mises", "Von Mises", np.linspace(-np.pi, np.pi, 1601), False,
         [(rf"$\mu = 0,\ \kappa = {k:g}$", stats.vonmises(k, loc=0)) for k in (0, 1, 4)],
         "Angles in radians; -pi and pi are the same direction. The CDF uses a cut at -pi."),
    ]


def draw(slug, title, x, discrete, curves, note, cumulative):
    kind = "cdf" if cumulative else "pmf" if discrete else "pdf"
    description = "Cumulative distribution" if cumulative else "Probability mass" if discrete else "Probability density"
    fig, ax = plt.subplots(figsize=(9, 5.5), layout="constrained")
    fig.set_facecolor("white")
    for i, ((label, rv), color) in enumerate(zip(curves, COLORS)):
        y = rv.cdf(x) if cumulative else rv.pmf(x) if discrete else rv.pdf(x)
        if not np.all(np.isfinite(y)) or np.any(y < -1e-12):
            raise ValueError(f"Invalid {kind} values for {slug}: {label}")
        if cumulative:
            if np.any(y > 1 + 1e-12) or np.any(np.diff(y) < -1e-12):
                raise ValueError(f"Invalid CDF for {slug}: {label}")
            if discrete:
                ax.step(x, y, where="post", color=color, linewidth=2,
                        linestyle=("-", "--", ":")[i], label=label)
            else:
                ax.plot(x, y, color=color, linewidth=2, label=label)
        elif discrete:
            # Stems stay at integer outcomes; their heights represent mass.
            ax.vlines(x, 0, y, color=color, alpha=0.5, linewidth=1.4)
            ax.plot(x, y, linestyle="none", marker=("o", "s", "^")[i],
                    markersize=5, color=color, label=label)
        else:
            ax.plot(x, y, color=color, linewidth=2, label=label)
    ax.set_title(f"{title} — {description}", loc="left", pad=15, fontweight="bold")
    ax.set_xlabel("Outcome k" if discrete else "Angle θ (radians)" if slug == "von-mises" else "Value x")
    ax.set_ylabel("F(x) = P(X ≤ x)" if cumulative else "P(X = k)" if discrete else "Density f(x)")
    ax.set_xlim(x[0], x[-1])
    ax.set_ylim((-0.025, 1.025) if cumulative else (0, None))
    ax.grid(alpha=0.18)
    ax.set_axisbelow(True)
    ax.spines[["top", "right"]].set_visible(False)
    ax.legend(loc="best", framealpha=0.95, fontsize=10)
    if slug == "bernoulli":
        ax.set_xticks([-1, 0, 1, 2])
    if slug == "von-mises":
        ax.set_xticks([-np.pi, -np.pi / 2, 0, np.pi / 2, np.pi],
                      [r"$-\pi$", r"$-\pi/2$", "0", r"$\pi/2$", r"$\pi$"])
    if note:
        fig.supxlabel(textwrap.fill(note, width=103), fontsize=9, color="#555555")
    target = OUTPUT / f"{slug}-{kind}.png"
    fig.savefig(target, dpi=160, metadata={"Software": "DistributionExplorer: SciPy + Matplotlib"})
    plt.close(fig)
    return target


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 11})
    count = 0
    for spec in specifications():
        for cumulative in (False, True):
            print(draw(*spec, cumulative=cumulative).relative_to(OUTPUT.parent.parent))
            count += 1
    print(f"Generated {count} figures.")


if __name__ == "__main__":
    main()
