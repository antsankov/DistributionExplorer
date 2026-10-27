# Distribution reference

29 distribution guides: Markdown editions of all 19 distributions in the [NIST/SEMATECH e-Handbook of Statistical Methods distribution gallery](https://www.itl.nist.gov/div898/handbook/eda/section3/eda366.htm), plus 10 original guides checked against the SciPy reference. Sources were consulted on 2026-10-25.

## Recommended scope

For a general educational explorer, start with Bernoulli, Binomial, Geometric, Negative Binomial, Hypergeometric, Poisson, Normal, Uniform, Exponential, Gamma, Beta, Lognormal, Student's t, Weibull, and Pareto. Together these cover binary outcomes, counts, waiting times, bounded values, symmetric shapes, and heavy tails.

Then add Logistic and Laplace for shape comparisons; Triangular for bounded simulation; Rayleigh for Gaussian magnitudes; Von Mises for angles; Gumbel and Generalized Extreme Value for maxima; and F and Chi-Square for inference. Cauchy is especially useful for demonstrating a distribution without a finite mean or variance. These are editorial priorities for this explorer, not a ranking of statistical validity.

The four lowest priorities for the initial explorer are:

| Distribution | Suggested placement | Reason |
| --- | --- | --- |
| [Power Normal](power-normal-distribution.md) | Advanced; defer initially | A specialized shape family with less introductory value than Normal, Logistic, or Student's t. |
| [Power Lognormal](power-lognormal-distribution.md) | Advanced; defer initially | A specialized extension; teach Lognormal, Weibull, and Pareto first. |
| [Tukey–Lambda](tukey-lambda-distribution.md) | Advanced fitting tools | Useful for comparing candidate shapes through probability plot correlation; less direct as a first modeling example. |
| [Birnbaum–Saunders (Fatigue Life)](birnbaum-saunders-fatigue-life-distribution.md) | Reliability specialty | Valuable for fatigue applications; lower priority without that domain. |

All four remain available below. The NIST articles themselves retain their original content.

## Continuous distributions

- [Normal Distribution](normal-distribution.md)
- [Uniform Distribution](uniform-distribution.md)
- [Cauchy Distribution](cauchy-distribution.md)
- [t Distribution](t-distribution.md)
- [F Distribution](f-distribution.md)
- [Chi-Square Distribution](chi-square-distribution.md)
- [Exponential Distribution](exponential-distribution.md)
- [Weibull Distribution](weibull-distribution.md)
- [Lognormal Distribution](lognormal-distribution.md)
- [Birnbaum-Saunders (Fatigue Life) Distribution](birnbaum-saunders-fatigue-life-distribution.md)
- [Gamma Distribution](gamma-distribution.md)
- [Double Exponential Distribution](double-exponential-distribution.md)
- [Power Normal Distribution](power-normal-distribution.md)
- [Power Lognormal Distribution](power-lognormal-distribution.md)
- [Tukey-Lambda Distribution](tukey-lambda-distribution.md)
- [Extreme Value Type I Distribution](extreme-value-type-i-distribution.md)
- [Beta Distribution](beta-distribution.md)
- [Pareto Distribution](pareto-distribution.md) — original guide
- [Logistic Distribution](logistic-distribution.md) — original guide
- [Triangular Distribution](triangular-distribution.md) — original guide
- [Rayleigh Distribution](rayleigh-distribution.md) — original guide
- [Generalized Extreme Value Distribution](generalized-extreme-value-distribution.md) — original guide
- [Von Mises Distribution](von-mises-distribution.md) — original guide

## Discrete distributions

- [Binomial Distribution](binomial-distribution.md)
- [Poisson Distribution](poisson-distribution.md)
- [Bernoulli Distribution](bernoulli-distribution.md) — original guide
- [Geometric Distribution](geometric-distribution.md) — original guide
- [Negative Binomial Distribution](negative-binomial-distribution.md) — original guide
- [Hypergeometric Distribution](hypergeometric-distribution.md) — original guide

## Source and conversion notes

For the 19 NIST transcriptions: Reprinted courtesy of the National Institute of Standards and Technology, U.S. Department of Commerce. Not copyrightable in the United States.

See [NIST's copyright and disclaimer policy](https://www.nist.gov/copyrights-disclaimers) and [NIST's reprint guidance](https://www.nist.gov/nist-research-library/library-faqs). References to external publications remain attributed to their original authors; those publications are not reproduced here.

Each NIST transcription links to its original page. The crawl includes the 19 distribution articles directly listed in the gallery; supporting handbook chapters and bibliographic references remain external links.

The conversion preserves source text, formulas, tables, and plots while removing navigation, scripts, and page layout. Links between these distributions point to local Markdown files. Plots and any equations supplied as images are stored in `assets/nist/`, so the articles can be read offline. LaTeX uses `$...$` and `$$...$$` delimiters and requires a Markdown viewer with math support. Named source anchors are retained for cross-references.

The NIST articles are transcriptions, not mathematical revisions: source terminology, parameter conventions, software availability statements, and possible source errors are retained. In particular, the handbook often gives functions in their standard form and limits parameter estimation to methods of moments and maximum likelihood. Consult the source and its linked references when interpreting formulas or fitting distributions.

The 10 entries marked "original guide" are newly written summaries, not NIST transcriptions or copies of SciPy documentation. Each links to its SciPy reference and provides its support, parameter convention, probability functions, summary statistics, and software mapping. Each includes original probability and cumulative distribution plots for three parameter settings, stored locally in `assets/generated/`. Discrete probabilities use stems and their CDFs use steps. Infinite tails are cropped to the displayed range; captions identify this. The Von Mises plots use radians and a CDF cut at minus pi. The NIST public-domain attribution above applies to the NIST material, not to external SciPy documentation.

To regenerate the 20 original plots, install `numpy`, `scipy`, and `matplotlib`, then run `python scripts/generate_distribution_plots.py` from the repository root. The [generation script](../scripts/generate_distribution_plots.py) records the parameters and uses SciPy's probability functions, including its opposite-sign GEV shape convention.

For the new guides, quantile formulas use $0<q<1$. A discrete quantile means the smallest supported integer $k$ with $F(k)\ge q$. Variance means ordinary variance except where the Von Mises guide explicitly uses circular variance. The Logistic guide labels excess kurtosis; NIST's kurtosis values generally use ordinary kurtosis, which is three larger.
