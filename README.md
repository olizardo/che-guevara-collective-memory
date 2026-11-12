# Generations, Identities, and the Collective Memory of Che Guevara

Replication materials for:

> Larson, Jeff A. and Omar Lizardo. 2007. "Generations, Identities, and the Collective Memory of Che Guevara." *Sociological Forum* 22(4). DOI: [10.1111/j.1573-7861.2007.00045.x](https://doi.org/10.1111/j.1573-7861.2007.00045.x)

The paper uses survey data from Spanish citizens to examine who recalls Che Guevara, testing the theory of generational imprinting against identity-based accounts of collective memory.

## Contents

- `data/raw/` — Raw monthly Spain survey files (`spainjan91.dta`, `spainjan92.dta`, `spainjan93.dta`, `spainjan93_ren.dta`).
- `data/` — Shipped intermediate and analysis datasets (`.dta`): `che_prem.dta` (pooled wide file), `che_final.dta` (long analysis file), and the El País newspaper mention counts (`elpais.dta`, `table.dta`). These are retained as verification targets; the R pipeline does not require them. Files the R pipeline writes (`che_prem_recreated.dta`, `che_final_recreated.dta`) are treated as build artifacts and not tracked.
- `code/` — Original Stata do-files: `che-dataproc-latest.do` (data processing) and `che-analysis.do` (analysis). Retained for provenance only; the R pipeline does not require Stata. These reference hard-coded paths from the original research environment and need path edits to run as-is.
- `archive/` — Earlier and auxiliary material from the original research process (old do-files, an intermediate dataset) that the replication pipeline does not use.
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
- **Figure 3 (odds of mentioning Che by cohort)** reproduces strongly. The per-cohort observation counts in the published note (121, 386, 485, 545, 808, 1,158, 482) match the recreated data's cohort bins exactly, and the relative odds by cohort group (`figures/fig3_odds_by_cohort_group.png`: 0.66, 0.62, 0.41, 0.63, 1.15, 1.33, 1.43) land in the published figure's plotted range with its characteristic shape — below the overall odds for pre-1950 cohorts, rising almost linearly to about 1.4 for the youngest cohort. A smooth version of the same relationship (predicted probabilities for each of the six named figures, via g-computation from the multinomial logit) is in `figures/fig3_cohort_curves.png`.
- **Figure 1 (media visibility)** is only partially reproducible: the published figure plots four series (New York Times articles, Library of Congress entries, Biblioteca Nacional de España, El País) from 1955 to 2006, but the shipped files (`elpais.dta`, `elpais_che_mentions.xls.xlsx`) contain only two series (`m1`, `m2` as coded) for 1976–2004. `figures/fig1_news_mentions.png` plots what is available; both series show the post-1995 surge in Che's visibility that the paper describes.
- **Figure 2** (the iconic Korda photograph) involves no data.

Known, documented deviations (all in `R/` script comments): (1) the full analysis file contains 3,985 choice records (the basis for Table II and the Figure 3 cohort notes); the published Table III reports N = 3,772, and the exact filtering that produced it cannot be pinned down from the shipped files; the closest recoverable definition (complete cases with "None"/"Don't know" postmaterialism answers treated as missing) yields N = 3,684 in the fully raw-driven pipeline and near-identical estimates; (2) the published education coefficient is on a different metric (the raw education scale here), but the standardized effect matches; (3) the regional-identity score is recomputed from a region-by-ethnicity correspondence analysis and standardized; it correlates 0.95 with the original Stata `regid` but is not an exact scalar multiple (the original was computed on a slightly different version of the data); (4) the traditionalism factor score substitutes tetrachoric-based factor scores for the original's polychoric-based CA scores, which are not reconstructible from the shipped files — Table III standardizes this score, so the models are unaffected; (5) correspondence-analysis and factor-score conventions can differ in sign and small-sample detail between Stata and R.

## Replication

In R, from the repo root:

```r
source("R/dataproc.R")      # raw survey files -> pooled wide file
source("R/prepare-data.R")  # wide file -> long analysis file
source("R/analysis.R")      # scales, cohort curves, Wald tests, logit models
```

The pipeline is fully self-contained: it reads only `data/raw/` and writes its intermediate and final datasets into `data/` as build artifacts. The shipped `che_prem.dta` / `che_final.dta` are never read by the pipeline.

Requires: `haven`, `MASS`, `psych`, `nnet`, `sandwich`, `lmtest`, `dplyr`.

The Stata originals in `code/` are retained for provenance; the R scripts are the maintained, path-independent versions.

## Translation notes

The R port follows the original do-files step by step, with a few unavoidable equivalences: Stata's `ca ... , predict rowscore(1)` is reproduced with `MASS::corresp` (row scores of simple correspondence analysis); `tetrachoric`/`factormat ... , pcf` factor scores use regression-method scores on the tetrachoric correlation matrix; `xi3` centering and interactions are expressed directly in formula syntax; `fracpoly, degree(1)` for education is implemented as a search over Stata's candidate powers; and the `postgr3` cohort curves are computed by g-computation (counterfactual cohort values, all other covariates at their observed values). Coefficient estimates are numerically very close to the Stata originals, but scores produced by correspondence analysis and factor extraction can differ in sign convention or small-sample detail.
