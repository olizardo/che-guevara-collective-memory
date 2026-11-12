# Data-processing port of che-dataproc-latest.do (lines 1-92):
# raw monthly Spain survey files (data/raw/) -> che_prem.dta
#
# Reproduces: pooling of the January 1991, 1992, and 1993 cross-sections;
# cohort variables; recodes of education, political views, ethnicity; and
# the traditional-values item keep-list. The reshape to the long analysis
# file (che_final.dta) is in prepare-data.R.

library(haven)

repo_root <- function() {
  ca <- commandArgs(trailingOnly = FALSE)
  fa <- grep("^--file=", ca, value = TRUE)
  if (length(fa)) dirname(dirname(normalizePath(sub("^--file=", "", fa)))) else getwd()
}
data_dir <- file.path(repo_root(), "data")
raw_dir  <- file.path(data_dir, "raw")

keep_demo <- c("gender", "age", "marital", "relhead", "hhsize", "occ",
               "headocc", "paocc", "educ", "paeduc", "relig", "howrelig",
               "polviews", "class", "ethid", "placeborn", "reg15", "region",
               "commun", "citysize", "finc")

load_year <- function(file, year, n_lat) {
  d <- read_dta(file.path(raw_dir, file))
  d$year <- year
  d$id <- seq_len(nrow(d))
  # 1991/92 spell the region variable "commmun" (three m's); 1993 uses
  # "commun". The original pipeline never unified them; keep both.
  keep <- c(paste0("sppostmat", 1:3), paste0("wrldpostmat", 1:3),
            "geoid", "passport", paste0("tradval", 1:10), "year", "id",
            paste0("latinperson", seq_len(n_lat)),
            keep_demo[keep_demo != "commun"],
            intersect(c("commmun", "commun"), names(d)))
  d <- d[keep]
  # pad columns absent from this wave so the three files can be pooled
  need <- setdiff(c(paste0("latinperson", 1:3), "commmun", "commun"), names(d))
  for (v in need) d[[v]] <- NA_real_
  d
}

d91 <- load_year("spainjan91.dta", 1991, 3)
d92 <- load_year("spainjan92.dta", 1992, 2)
d93 <- load_year("spainjan93_ren.dta", 1993, 2)

pooled <- rbind(d91, d92, d93)

# Cohort and cohort bins (Stata: egen cut, at(1880(10)1980); >= 1980 missing)
pooled$cohort <- pooled$year - pooled$age
cuts <- seq(1880, 1980, by = 10)
cohort10 <- cut(pooled$cohort, breaks = c(cuts, Inf), labels = FALSE,
                right = FALSE)
pooled$cohort10 <- ifelse(!is.na(cohort10), cuts[cohort10], NA_real_)
pooled$cohort5  <- cut(pooled$cohort, breaks = c(seq(1880, 1980, by = 5), Inf),
                       labels = FALSE, right = FALSE)
pooled$cohort5  <- ifelse(!is.na(pooled$cohort5),
                          seq(1880, 1975, by = 5)[pooled$cohort5], NA_real_)
# Stata: recode cohort10 1890/1900 = 1910
pooled$cohort10[pooled$cohort10 %in% c(1890, 1900)] <- 1910

# Education recode (Stata: recode educ 9 = 2, g(educrec))
pooled$educrec <- ifelse(!is.na(pooled$educ) & pooled$educ == 9, 2, pooled$educ)
# Political views recodes (Stata: recode polviews .=10; 9/10=4 g; 1/2=1 3/4=2 5/7=3 9/10=4 g)
pv <- pooled$polviews
pooled$polviews <- ifelse(is.na(pv), 10, pv)  # Stata: recode polviews .=10 (in place)
pv <- pooled$polviews
pooled$polviewsrec <- ifelse(pv >= 9, 4, pv)
pooled$polcat <- ifelse(pv <= 2, 1, ifelse(pv <= 4, 2, ifelse(pv <= 7, 3, 4)))
# Traditionalism transformation
pooled$teduc <- -1 / (pooled$educrec + 1)^2
# Basque/Navarre residence. Stata semantics: missing commun satisfies >14
# but not <17, so vasco = 0 whenever commun is missing (i.e., for 1991/92).
pooled$vasco <- as.integer(!is.na(pooled$commun) &
                             pooled$commun > 14 & pooled$commun < 17)
# Ethnic identity recodes
e <- pooled$ethid
pooled$ethidcat <- ifelse(e <= 2, 1, ifelse(e == 3, 2, ifelse(e >= 4 & e <= 7, 3, e)))
pooled$ethidord <- ifelse(e %in% 6:7, 3, e)
pooled$left <- pooled$polviews < 3
pooled$educ[is.na(pooled$educ)] <- 9
pooled$yearvar <- pooled$year - 1991
# Four-category birth cohort (Stata: recode cohort 1880/1935=1 1936/1954=2 1955/1964=3 1965/1975=4)
c0 <- pooled$cohort
pooled$cohortcat4 <- ifelse(c0 >= 1880 & c0 <= 1935, 1,
                     ifelse(c0 >= 1936 & c0 <= 1954, 2,
                     ifelse(c0 >= 1955 & c0 <= 1964, 3,
                     ifelse(c0 >= 1965 & c0 <= 1975, 4, c0))))

attr(pooled$polcat, "labels") <- c(left = 1, moderate = 2, right = 3, `no opinion` = 4)
attr(pooled$cohortcat4, "labels") <- c(`1890/1935` = 1, `1936/1955` = 2,
                                       `1955/1964` = 3, `1965/1975` = 4)
attr(pooled$commun, "labels") <- c(Andalucia = 1, Aragon = 2, Asturias = 3,
  Baleares = 4, Cataluna = 5, Canarias = 6, Cantabria = 7, Leon = 8,
  La_Mancha = 9, Extremadura = 10, Galicia = 11, Rioja = 12, Madrid = 13,
  Murcia = 14, Navarra = 15, Pais_Vasco = 16, Valenciana = 17)

# Order columns as in the shipped che_prem.dta where possible
ref <- read_dta(file.path(data_dir, "che_prem.dta"), n_max = 1)
pooled <- pooled[c(intersect(names(ref), names(pooled)),
                   setdiff(names(pooled), names(ref)))]
haven::write_dta(pooled, file.path(data_dir, "che_prem_recreated.dta"))
