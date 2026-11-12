# Data-wrangling port of the tail of che-dataproc-latest.do (lines 93-131):
# the pooled wide file (three Latin American figure choices) -> the long
# analysis file (figure coding, and dummy indicators for Che and comparison
# figures).
#
# Reads data/che_prem_recreated.dta produced by R/dataproc.R, making the
# pipeline fully self-contained from the raw survey files. The shipped
# che_prem.dta and che_final.dta are retained only as verification targets.

library(haven)

repo_root <- function() {
  ca <- commandArgs(trailingOnly = FALSE)
  fa <- grep("^--file=", ca, value = TRUE)
  if (length(fa)) dirname(dirname(normalizePath(sub("^--file=", "", fa)))) else getwd()
}
data_dir <- file.path(repo_root(), "data")

prem <- read_dta(file.path(data_dir, "che_prem_recreated.dta"))

# Binary indicators (Stata analysis.do lines 6-7 and 26):
# left/libertarian postmaterialism priorities; rich/poor world priorities;
# traditional values "agree" codes
for (j in 1:3) {
  prem[[paste0("sppostmat", j, "bin")]] <- as.integer(
    prem[[paste0("sppostmat", j)]] %in% c(1, 3, 4, 8))
  prem[[paste0("wrldpostmat", j, "bin")]] <- as.integer(
    prem[[paste0("wrldpostmat", j)]] %in% c(1, 2, 4, 9))
}
for (j in 1:10) {
  prem[[paste0("tradval", j, "bin")]] <- as.integer(prem[[paste0("tradval", j)]] <= 2)
}

lp <- grep("^latinperson[0-9]+$", names(prem), value = TRUE)
prem$idnum <- seq_len(nrow(prem))
long <- do.call(rbind, lapply(seq_along(lp), function(j) {
  data.frame(idnum = prem$idnum, choice = j,
             latinperson = as.integer(prem[[lp[j]]]))
}))
long <- long[!is.na(long$latinperson), ]
long <- long[order(long$idnum), ]

# Running count of nonmissing choices per respondent, computed BEFORE the
# 98/99 (don't know/refused) codes are dropped, matching the shipped
# che_final.dta (Stata: qby idnum: gen numchoices = sum(counter)).
# Known discrepancy: for 2 respondents (idnum 3464, 3499) the shipped
# che_final.dta has numchoices = 2 where the shipped che_prem.dta shows only
# one nonmissing choice; the original run evidently saw a 98/99 code that is
# missing in the shipped che_prem. The recreation gives 1 for those cells.
long$numchoices <- stats::ave(rep(1L, nrow(long)), long$idnum, FUN = cumsum)

# Now drop don't know/refused responses
long <- long[!long$latinperson %in% c(98, 99), ]

# Figure coding: keep figures chosen by at least 3% of the pooled responses,
# pool the rest as "Otros" (97), then apply the original recode
shares <- prop.table(table(long$latinperson))
long$figure <- ifelse(shares[as.character(long$latinperson)] >= 0.03,
                      long$latinperson, 97)
rec_map <- c(`7` = 6L, `8` = 7L, `10` = 8L, `15` = 9L, `18` = 10L, `97` = 11L)
fig <- as.integer(long$figure)
long$figure <- ifelse(fig %in% names(rec_map), rec_map[as.character(fig)], fig)
attr(long$figure, "labels") <- c(`Fidel Castro` = 1, `Carlos Menem` = 2,
  Pinochet = 3, Peron = 4, `Raul Alfonsin` = 5, `Simon Bolivar` = 6,
  `Mario Vargas Llosa` = 7, `Diego Armando Maradona` = 8,
  `Gabriel Garcia Marquez` = 9, `Che Guevara` = 10, Otros = 11)

# Dummy indicators for Che and the comparison figures (original latinperson codes)
mk <- function(v, code) as.integer(long$latinperson == code)
long$che     <- mk("che", 18)
long$castro  <- mk("castro", 1)
long$bolivar <- mk("bolivar", 7)
long$allende <- mk("allende", 26)
long$peron   <- mk("peron", 4)
long$pinochet<- mk("pinochet", 3)
long$marquez <- mk("marquez", 15)
long$llosa   <- mk("llosa", 8)
long$maradona<- mk("maradona", 10)
long$evita   <- mk("evita", 6)

# Attach the wrangled rows back to the respondent-level prem variables
wrangled <- merge(prem[!names(prem) %in% lp], long, by = "idnum", sort = FALSE)

write_dta(wrangled, file.path(data_dir, "che_final_recreated.dta"))
