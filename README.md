# Generations, Identities, and the Collective Memory of Che Guevara

Replication materials for:

> Larson, Jeff A. and Omar Lizardo. 2007. "Generations, Identities, and the Collective Memory of Che Guevara." *Sociological Forum* 22(4). DOI: [10.1111/j.1573-7861.2007.00045.x](https://doi.org/10.1111/j.1573-7861.2007.00045.x)

The paper uses survey data from Spanish citizens to examine who recalls Che Guevara, testing the theory of generational imprinting against identity-based accounts of collective memory.

## Contents

- `data/raw/` — Raw monthly Spain survey files (`spainjan91.dta`, `spainjan92.dta`, `spainjan93.dta`, `spainjan93_ren.dta`).
- `data/` — Shipped intermediate and analysis datasets (`.dta`): `che_prem.dta` (pooled wide file), `che_final.dta` (long analysis file), plus `che.dta` and the El País newspaper mention counts (`elpais.dta`, `table.dta`). The files the R pipeline writes (`che_prem_recreated.dta`, `che_final_recreated.dta`) are treated as build artifacts and not tracked.
- `code/` — Original Stata do-files: `che-dataproc-latest.do` (data processing) and `che-analysis.do` (analysis). These reference hard-coded paths from the original research environment and need path edits to run as-is.
- `old-do-files/` — Earlier and auxiliary do-files from the original research process, retained for provenance.
- `R/` — R port of the full pipeline:
  - `R/dataproc.R` — raw files -> `che_prem` (pooling, cohort variables, recodes). Reproduces the shipped `che_prem.dta` variable-for-variable.
  - `R/prepare-data.R` — `che_prem` -> long analysis file (reshape, figure coding with the 3% popularity threshold, Che/comparison dummies). Reproduces the shipped `che_final.dta` variable-for-variable, except for 2 cells of `numchoices` (see script comments; the shipped `che_prem` and `che_final` disagree with each other there).
  - `R/analysis.R` — R translation of `che-analysis.do`: correspondence-analysis scores, postmaterialism and traditionalism scales, cohort curves for each figure, cohort Wald tests, and the logit models for recalling Che with cluster-robust standard errors.
- `tables-figures/` — Tables and figures as prepared for the manuscript (Excel/Word/PowerPoint).
- `figures/` — Figures produced by the R pipeline (`fig3_cohort_curves.png`).

## Reproducibility check against the published article

The R pipeline is independent of Stata. Comparing its output against the published article:

- **Table II (descriptives: Latin American figures mentioned)** reproduces **exactly** — every count and percentage (e.g., Castro 594 = 14.91%, Che Guevara 195 = 4.89%) matches.
- **Table III (logit models of remembering Che)** reproduces closely. The final model (Model 4) is essentially identical: cohort 0.0116 (z = 2.08) vs published 0.0102 (t = 1.68); regional identity 0.4610 (z = 2.29) vs published 0.4656 (t = 2.36); political-identity dummies within 0.04 of published values; education z = 2.62 vs published t = 3.03. Models 1–3 match in sign, magnitude, and significance; cohort coefficients are within 10–15% of published values.
- **Figure 3 (cohort curves)** is reproduced as `figures/fig3_cohort_curves.png` via g-computation predicted probabilities from the multinomial logit; the shape matches the published figure (rising cohort gradients for Che and other figures).

Known, documented deviations (all in `R/` script comments): (1) the full analysis file contains 3,985 choice records (the basis for Table II and the Figure 3 cohort notes); the published Table III reports N = 3,772, and the exact filtering that produced it cannot be pinned down from the shipped files; the closest recoverable definition (complete cases with "None"/"Don't know" postmaterialism answers treated as missing) yields N = 3,900 and near-identical estimates; (2) the published education coefficient is on a different metric (the raw education scale here), but the standardized effect matches; (3) correspondence-analysis and factor-score conventions can differ in sign and small-sample detail between Stata and R.

## Replication

In R, from the repo root:

```r
source("R/dataproc.R")      # raw -> che_prem (writes data/che_prem_recreated.dta)
source("R/prepare-data.R")  # che_prem -> long analysis file (data/che_final_recreated.dta)
source("R/analysis.R")      # scales, cohort curves, Wald tests, logit models
```

Requires: `haven`, `MASS`, `psych`, `nnet`, `sandwich`, `lmtest`, `dplyr`.

The Stata originals in `code/` are retained for provenance; the R scripts are the maintained, path-independent versions.

## Translation notes

The R port follows the original do-files step by step, with a few unavoidable equivalences: Stata's `ca ... , predict rowscore(1)` is reproduced with `MASS::corresp` (row scores of simple correspondence analysis); `tetrachoric`/`factormat ... , pcf` factor scores use regression-method scores on the tetrachoric correlation matrix; `xi3` centering and interactions are expressed directly in formula syntax; `fracpoly, degree(1)` for education is implemented as a search over Stata's candidate powers; and the `postgr3` cohort curves are computed by g-computation (counterfactual cohort values, all other covariates at their observed values). Coefficient estimates are numerically very close to the Stata originals, but scores produced by correspondence analysis and factor extraction can differ in sign convention or small-sample detail.
