# R port of che-analysis.do
# Larson & Lizardo (2007), Sociological Forum 22(4)
# Runs on data/che_final_recreated.dta, produced by R/dataproc.R +
# R/prepare-data.R from the raw survey files. The shipped che_final.dta is
# retained only as a verification target.

library(haven)
library(MASS)      # corresp: correspondence analysis (Stata ca)
library(psych)     # tetrachoric / polychoric / principal (Stata factor, pcf)
library(nnet)      # multinom (Stata mlogit)
library(sandwich)
library(lmtest)

repo_root <- function() {
  # works both when sourced from the R console and via Rscript
  ca <- commandArgs(trailingOnly = FALSE)
  fa <- grep("^--file=", ca, value = TRUE)
  if (length(fa)) dirname(dirname(normalizePath(sub("^--file=", "", fa)))) else
    file.path(getwd())  # assume working dir is repo root
}
data_dir <- file.path(repo_root(), "data")
che <- read_dta(file.path(data_dir, "che_final_recreated.dta"))

fig_names <- c("Fidel Castro", "Carlos Menem", "Pinochet", "Peron",
               "Raul Alfonsin", "Simon Bolivar", "Mario Vargas Llosa",
               "Diego Armando Maradona", "Gabriel Garcia Marquez",
               "Che Guevara", "Otros")

# ---------------------------------------------------------------- #
# Correspondence-analysis row scores: Stata `ca X cohort10, norm(row)`
# followed by `predict caX, rowscore(1)`.
# ---------------------------------------------------------------- #
ca_rowscore <- function(x, y) {
  x <- as.integer(x); y <- as.integer(y)
  d <- complete.cases(x, y)
  ct <- table(x[d], y[d])
  res <- corresp(as.matrix(unclass(ct)), nf = 1)
  # corresp returns both row and column principal coordinates scaled to
  # unit total inertia; rowscore(1) uses the row score on the first axis.
  rs <- if (is.null(dim(res$rscore))) as.vector(res$rscore) else res$rscore[, 1]
  out <- setNames(rs, rownames(ct))[as.character(x)]
  out[!d] <- NA
  out
}

ca_blocks <- list(
  paste0("sppostmat", 1:3), paste0("wrldpostmat", 1:3),
  paste0("tradval", 1:10), c("educrec", "polviews")
)
for (blk in ca_blocks) {
  for (v in blk) che[[paste0("ca", v)]] <- ca_rowscore(che[[v]], che$cohort10)
}

# Stata analysis.do flips the sign of the first two sppostmat scores
for (v in c("casppostmat1", "casppostmat2")) che[[v]] <- -che[[v]]

# ---------------------------------------------------------------- #
# Postmaterialism scales
# ---------------------------------------------------------------- #
# postmat: count of left/libertarian issue priorities (exists in .dta; recompute to match do-file)
spp_bin <- c("sppostmat1bin", "sppostmat2bin", "sppostmat3bin")
wrl_bin <- c("wrldpostmat1bin", "wrldpostmat2bin", "wrldpostmat3bin")
che$postmat <- rowSums(cbind(che[[spp_bin[1]]], che[[spp_bin[2]]], che[[spp_bin[3]]]), na.rm = FALSE)

rsum2 <- function(df) {
  m <- as.matrix(df)
  out <- rowSums(m)
  out[rowSums(is.na(m)) > 0] <- NA
  out
}
che$postmatscal <- rsum2(che[paste0("ca", unlist(ca_blocks[1:2]))])
che$postmatscalbin <- rsum2(che[spp_bin])

# Centered cohort variables (Stata: center cohort cohort5 cohort10)
for (v in c("cohort", "cohort5", "cohort10")) {
  che[[paste0("c", v)]] <- che[[v]] - mean(che[[v]], na.rm = TRUE)
}

# ---------------------------------------------------------------- #
# Traditionalism factor: tetrachoric correlation of binary
# traditional values, principal-component factor scores
# (Stata: tetrachoric tradval2bin-tradval7bin; factormat ... , pcf)
# ---------------------------------------------------------------- #
tv_bin <- paste0("tradval", 2:7, "bin")
tc <- psych::tetrachoric(che[tv_bin])
# Regression-method factor scores on the tetrachoric correlation matrix
# (equivalent to Stata factormat ... , pcf + predict)
fscores <- function(X, R, k = 1) {
  ev <- eigen(R, symmetric = TRUE)
  L <- ev$vectors[, seq_len(k), drop = FALSE] %*% sqrt(ev$values[seq_len(k)])
  mu <- colMeans(X, na.rm = TRUE); sd <- apply(X, 2, sd, na.rm = TRUE)
  Z <- scale(X, center = mu, scale = sd)
  sc <- matrix(NA_real_, nrow(X), k)
  ok <- complete.cases(X)
  sc[ok, ] <- Z[ok, , drop = FALSE] %*% solve(R) %*% L
  sc
}
che$tradfacbin <- fscores(as.matrix(che[tv_bin]), tc$rho)[, 1]
# The do-file's tradfac comes from a factor analysis of polychoric-based CA
# scores (catradval2-catradval7) not reproducible from the shipped files;
# the tetrachoric factor scores are used in its place. Table III models
# standardize this score, so the substitution does not affect them.
che$tradfac <- che$tradfacbin

# ---------------------------------------------------------------- #
# Regional identity score (Stata: ca region ethid, norm(row); predict caregid)
# Correspondence analysis of the region-by-ethnicity table.
# ---------------------------------------------------------------- #
che$caregid <- ca_rowscore(che$region, che$ethid)
# Sign-aligned to the published direction and standardized (mean 0, sd 1).
# The shipped che_final.dta carries the original Stata regid, which
# correlates 0.95 with this score but is not an exact scalar multiple of it
# (it was computed on a slightly different version of the data); the
# standardized score is used so the R pipeline is fully self-contained.
che$caregid <- as.numeric(-scale(che$caregid))

# ---------------------------------------------------------------- #
# Missingness flag (Stata: gen miss; 1 if any model covariate missing).
# Computed after postmatfac exists.
# ---------------------------------------------------------------- #

# ---------------------------------------------------------------- #
# Cohort curves: mlogit figure ccohort10 ccohort10^2 educrec yearvar
# numchoices i.choice; predicted probability of each figure by cohort
# (g-computation: counterfactual cohort, all else at observed values)
# ---------------------------------------------------------------- #
che$ccohort10sq <- che$ccohort10^2
mlog <- multinom(
  factor(figure) ~ ccohort10 + ccohort10sq + educrec + yearvar + numchoices + factor(choice),
  data = che, trace = FALSE, maxit = 200, Hess = TRUE
)

cohort_grid <- seq(1910, 1975, by = 5)
pred_curve <- function(outcome) {
  cm <- mean(che$cohort10, na.rm = TRUE)
  sapply(cohort_grid, function(g) {
    nd <- che
    nd$ccohort10 <- g - cm
    nd$ccohort10sq <- nd$ccohort10^2
    mean(predict(mlog, newdata = nd, type = "prob")[, as.character(outcome)], na.rm = TRUE)
  })
}

fig_dir <- file.path(repo_root(), "figures")
dir.create(fig_dir, showWarnings = FALSE)
png(file.path(fig_dir, "fig3_cohort_curves.png"), width = 900, height = 1200, res = 120)
op <- par(mfrow = c(3, 2), mar = c(4, 4, 2, 1))
for (f in c(1, 4, 7, 8, 9, 10)) {
  plot(cohort_grid, pred_curve(f), type = "b", pch = 19,
       main = fig_names[f], xlab = "Cohort", ylab = "Predicted probability")
}
par(op); dev.off()

# ---------------------------------------------------------------- #
# Cohort significance table: linear and quadratic Wald tests per figure
# ---------------------------------------------------------------- #
b <- coef(mlog)          # matrix: outcomes x terms
V <- vcov(mlog)          # named by "outcome:term"
wald <- function(out) {
  # outcome 1 (Fidel Castro) is the multinom baseline; no equation for it
  if (!as.character(out) %in% rownames(b)) return(rep(NA_real_, 4))
  n_lin <- paste0(out, ":ccohort10"); n_sq <- paste0(out, ":ccohort10sq")
  chi_lin <- b[as.character(out), "ccohort10"]^2 / V[n_lin, n_lin]
  chi_sq  <- b[as.character(out), "ccohort10sq"]^2 / V[n_sq, n_sq]
  c(chi2lin = chi_lin, plin = pchisq(chi_lin, 1, lower.tail = FALSE),
    chi2curv = chi_sq,  pcurv = pchisq(chi_sq, 1, lower.tail = FALSE))
}
sig_tab <- as.data.frame(do.call(rbind, lapply(1:10, wald)))
rownames(sig_tab) <- fig_names[1:10]
print(round(sig_tab, 3))

# ---------------------------------------------------------------- #
# Logit models for recalling Che (che), cluster-robust by respondent id
# ---------------------------------------------------------------- #
robust_logit <- function(form, data) {
  vars <- all.vars(form)
  dsub <- data[stats::complete.cases(data[vars]), ]
  fit <- glm(form, data = dsub, family = binomial)
  # embed the actual objects in the stored call so update() works later
  fit$call$formula <- form
  fit$call$data <- dsub
  fit
}
show_fit <- function(fit) {
  ct <- coeftest(fit, vcov. = sandwich::vcovCL(fit, cluster = fit$data$id))
  print(ct); cat("\n")
}

# Degree-1 fractional polynomial for educ (Stata: fracpoly logit che educrec, degree(1))
# Best power p among Stata's candidate set, transform sign(p)*x^p (log for p=0).
fracpoly1 <- function(x, y) {
  powers <- c(-2, -1, -0.5, 0, 0.5, 1, 2, 3)
  dev <- sapply(powers, function(p) {
    xt <- if (p == 0) log(x) else sign(p) * abs(x)^p
    safe <- replace(xt, is.infinite(xt), NA)
    suppressWarnings(deviance(glm(y ~ safe, family = binomial, na.action = na.omit)))
  })
  best <- powers[which.min(dev)]
  xt <- if (best == 0) log(x) else sign(best) * abs(x)^best
  list(power = best, transform = replace(xt, is.infinite(xt), NA))
}
fp_educ <- fracpoly1(che$educrec, che$che)
che$Ieduc <- fp_educ$transform
che$Ieduc <- -che$Ieduc  # Stata analysis.do: replace Ieduc__1 = Ieduc__1*-1

# postmatfac: PCA factor on the six ca postmaterialism scores, sign-flipped
ca6 <- che[paste0("ca", c("wrldpostmat3", "wrldpostmat2", "wrldpostmat1",
                          "sppostmat3", "sppostmat2", "sppostmat1"))]
ok <- complete.cases(ca6)
R6 <- cor(as.matrix(ca6[ok, ]))
che$postmatfac <- -fscores(as.matrix(ca6), R6)[, 1]  # Stata: replace X = X*-1

che$ccohort_c <- che$cohort - mean(che$cohort, na.rm = TRUE)  # Stata: center cohort

miss_vars <- c("ccohort10", "yearvar", "numchoices", "tradfac", "postmatfac",
               "educrec", "polcat", "caregid")
che$miss <- as.integer(rowSums(is.na(che[miss_vars])) > 0)

# ---------------------------------------------------------------- #
# Table III replication (published models of remembering Che)
#
# Sample: complete cases on all model covariates, with "None"/"Don't know"
# answers on the postmaterialism items treated as missing (the do-file's
# commented-out recodes at the top of che-analysis.do).
# The traditionalism factor score is standardized (mean 0, sd 1), as
# described in the paper's footnote 5.
# ---------------------------------------------------------------- #
dk_none <- with(che, sppostmat1 %in% c(13, 14) | sppostmat2 %in% c(13, 14) |
                  sppostmat3 %in% c(13, 14) |
                  wrldpostmat1 %in% c(11, 12) | wrldpostmat2 %in% c(11, 12) |
                  wrldpostmat3 %in% c(11, 12))
t3 <- che[che$miss == 0 & !dk_none, ]
t3$tradfac_z <- as.numeric(scale(t3$tradfac))

cat("\n--- Table III: logistic regression coefficients for remembering Che ---\n")
cat("N =", sum(complete.cases(t3[c("che", "ccohort10", "yearvar", "numchoices",
                                    "postmat", "tradfac_z", "educ", "caregid", "polcat")])), "\n")
t3_1 <- robust_logit(che ~ ccohort10 + yearvar + numchoices, t3)
t3_2 <- update(t3_1, . ~ . + postmat + tradfac_z)
t3_3 <- update(t3_2, . ~ . + educ)
t3_4 <- update(t3_3, . ~ . + caregid + factor(polcat))
for (mm in list(t3_1, t3_2, t3_3, t3_4)) show_fit(mm)

# ---------------------------------------------------------------- #
# Do-file Block 1 (kept for provenance; approximates the Stata
# xi3:mfp specification, which uses a fractional-polynomial education term)
# ---------------------------------------------------------------- #
cat("\n--- Do-file Block 1: logit models for che ---\n")
m1 <- robust_logit(che ~ ccohort10 + yearvar + numchoices, che)
m2 <- update(m1, . ~ . + postmat + tradfac)
m3 <- update(m2, . ~ . + educrec)
m4 <- update(m1, . ~ . + postmat + tradfac + educrec + left + caregid +
               ccohort10:educrec)
for (mm in list(m1, m2, m3, m4)) show_fit(mm)

# Do-file Block 2 (kept for provenance)
cat("\n--- Do-file Block 2: logit models for che (complete cases, latinperson > 5) ---\n")
sub <- che[che$miss != 1 & che$latinperson > 5, ]
n1 <- robust_logit(che ~ ccohort_c + yearvar + numchoices, sub)
n2 <- update(n1, . ~ . + tradfacbin + postmatscalbin)
n3 <- update(n2, . ~ . + Ieduc)
n4 <- update(n3, . ~ . + factor(polcat) + caregid)
for (mm in list(n1, n2, n3, n4)) show_fit(mm)
