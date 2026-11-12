# Generations, Identities, and the Collective Memory of Che Guevara

Replication materials for:

> Larson, Jeff A. and Omar Lizardo. 2007. "Generations, Identities, and the Collective Memory of Che Guevara." *Sociological Forum* 22(4). DOI: [10.1111/j.1573-7861.2007.00045.x](https://doi.org/10.1111/j.1573-7861.2007.00045.x)

The paper uses survey data from Spanish citizens to examine who recalls Che Guevara, testing the theory of generational imprinting against identity-based accounts of collective memory.

## Contents

- `data/raw/` — Raw monthly Spain survey files (`spainjan91.dta`, `spainjan92.dta`, `spainjan93.dta`, `spainjan93_ren.dta`).
- `data/` — Intermediate and analysis datasets (`.dta`): `che_prem.dta` (pooled wide file), `che_final.dta` (long analysis file), plus `che.dta` and the El País newspaper mention counts (`elpais.dta`, `table.dta`).
- `code/` — Original Stata do-files: `che-dataproc-latest.do` (data processing) and `che-analysis.do` (analysis). These reference hard-coded paths from the original research environment and need path edits to run as-is.
- `old-do-files/` — Earlier and auxiliary do-files from the original research process, retained for provenance.
- `R/` — R port of the full pipeline:
  - `R/dataproc.R` — raw files -> `che_prem` (pooling, cohort variables, recodes). Reproduces the shipped `che_prem.dta` variable-for-variable.
  - `R/prepare-data.R` — `che_prem` -> long analysis file (reshape, figure coding with the 3% popularity threshold, Che/comparison dummies). Reproduces the shipped `che_final.dta` variable-for-variable, except for 2 cells of `numchoices` (see script comments; the shipped `che_prem` and `che_final` disagree with each other there).
  - `R/analysis.R` — R translation of `che-analysis.do`: correspondence-analysis scores, postmaterialism and traditionalism scales, cohort curves for each figure, cohort Wald tests, and the logit models for recalling Che with cluster-robust standard errors.
- `tables-figures/` — Tables and figures as prepared for the manuscript (Excel/Word/PowerPoint).
- `manuscript/` — Manuscript PDF.

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
