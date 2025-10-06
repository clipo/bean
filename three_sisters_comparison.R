# THREE SISTERS COMPARISON: Beans, Maize, and Squash
# Bayesian analysis including squash dates

options(repos = c(CRAN = "https://cloud.r-project.org"))

if (!require("Bchron", quietly = TRUE)) install.packages("Bchron", quiet = TRUE)
if (!require("rcarbon", quietly = TRUE)) install.packages("rcarbon", quiet = TRUE)

library(Bchron)
library(rcarbon)

cat("\n================================================================\n")
cat("  THREE SISTERS BAYESIAN COMPARISON\n")
cat("  Beans, Maize, and Squash Arrival in Eastern Woodlands\n")
cat("================================================================\n\n")

# Load data
dates <- read.csv("radiocarbon_dates.csv")
bean_dates <- dates[dates$material == "bean", ]
maize_dates <- dates[dates$material == "maize", ]
squash_dates <- dates[dates$material == "squash", ]

cat("DATA SUMMARY:\n")
cat("  Beans: n =", nrow(bean_dates), "\n")
cat("  Maize: n =", nrow(maize_dates), "\n")
cat("  Squash: n =", nrow(squash_dates), "\n\n")

# ============================================================================
# CALIBRATE AND VISUALIZE
# ============================================================================

cat("Calibrating radiocarbon dates...\n\n")

bean_cal <- calibrate(bean_dates$c14_age, bean_dates$c14_error,
                      calCurves = 'intcal20', ids = bean_dates$site)
maize_cal <- calibrate(maize_dates$c14_age, maize_dates$c14_error,
                       calCurves = 'intcal20', ids = maize_dates$site)
squash_cal <- calibrate(squash_dates$c14_age, squash_dates$c14_error,
                        calCurves = 'intcal20', ids = squash_dates$site)

# Get calibrated ranges
cat("CALIBRATED DATE RANGES (95% probability):\n\n")

cat("SQUASH:\n")
for(i in 1:nrow(squash_dates)) {
  grid <- squash_cal$grids[[i]]
  # Calculate median and range
  cumsum_prob <- cumsum(grid$PrDens) / sum(grid$PrDens)
  median_bp <- grid$calBP[which.min(abs(cumsum_prob - 0.5))]
  # Get 95% range
  range_95 <- grid$calBP[cumsum_prob >= 0.025 & cumsum_prob <= 0.975]
  if(length(range_95) > 0) {
    cat("  ", squash_dates$site[i], ":",
        1950 - min(range_95), "-", 1950 - max(range_95), "cal AD",
        "(", squash_dates$c14_age[i], "±", squash_dates$c14_error[i], "BP)\n")
  }
}

# ============================================================================
# BOUNDARY ESTIMATION
# ============================================================================

cat("\n\n================================================================\n")
cat("BAYESIAN BOUNDARY ESTIMATION\n")
cat("================================================================\n\n")

# For beans and maize, use 8 oldest dates
# For squash, use all dates (only 3)

# Bean boundary
bean_sorted <- bean_dates[order(bean_dates$c14_age, decreasing = TRUE), ]
n_boundary <- 8
bean_boundary_subset <- bean_sorted[1:n_boundary, ]

cat("BEANS - Using", n_boundary, "oldest dates:\n")
for(i in 1:nrow(bean_boundary_subset)) {
  cat("  ", i, ". ", bean_boundary_subset$site[i], ": ",
      bean_boundary_subset$c14_age[i], " ± ",
      bean_boundary_subset$c14_error[i], " BP\n", sep = "")
}

bean_boundary <- BchronDensity(
  ages = bean_boundary_subset$c14_age,
  ageSds = bean_boundary_subset$c14_error,
  calCurves = rep('intcal20', nrow(bean_boundary_subset))
)

# Maize boundary
maize_sorted <- maize_dates[order(maize_dates$c14_age, decreasing = TRUE), ]
maize_boundary_subset <- maize_sorted[1:n_boundary, ]

cat("\nMAIZE - Using", n_boundary, "oldest dates:\n")
for(i in 1:nrow(maize_boundary_subset)) {
  cat("  ", i, ". ", maize_boundary_subset$site[i], ": ",
      maize_boundary_subset$c14_age[i], " ± ",
      maize_boundary_subset$c14_error[i], " BP\n", sep = "")
}

maize_boundary <- BchronDensity(
  ages = maize_boundary_subset$c14_age,
  ageSds = maize_boundary_subset$c14_error,
  calCurves = rep('intcal20', nrow(maize_boundary_subset))
)

# Squash boundary (use all dates)
cat("\nSQUASH - Using all", nrow(squash_dates), "dates:\n")
for(i in 1:nrow(squash_dates)) {
  cat("  ", i, ". ", squash_dates$site[i], ": ",
      squash_dates$c14_age[i], " ± ",
      squash_dates$c14_error[i], " BP\n", sep = "")
}

squash_boundary <- BchronDensity(
  ages = squash_dates$c14_age,
  ageSds = squash_dates$c14_error,
  calCurves = rep('intcal20', nrow(squash_dates))
)

# Extract HDRs
bean_hdr <- hdr(bean_boundary, prob = 0.95)
maize_hdr <- hdr(maize_boundary, prob = 0.95)
squash_hdr <- hdr(squash_boundary, prob = 0.95)

cat("\n\nBOUNDARY ESTIMATES (95% HDR):\n\n")

# Bean HDR
cat("BEANS:\n")
if(is.list(bean_hdr)) {
  for(i in 1:length(bean_hdr)) {
    cat("  Range", i, ":",
        bean_hdr[[i]][2], "-", bean_hdr[[i]][1], "cal BP",
        "(", 1950 - bean_hdr[[i]][1], "-", 1950 - bean_hdr[[i]][2], "cal AD)\n")
  }
  bean_earliest <- max(unlist(bean_hdr))
  bean_latest <- min(unlist(bean_hdr))
} else {
  cat("  ", bean_hdr[2], "-", bean_hdr[1], "cal BP",
      "(", 1950 - bean_hdr[1], "-", 1950 - bean_hdr[2], "cal AD)\n")
  bean_earliest <- max(bean_hdr)
  bean_latest <- min(bean_hdr)
}
cat("  Overall:", bean_earliest, "-", bean_latest, "cal BP",
    "(", 1950 - bean_latest, "-", 1950 - bean_earliest, "cal AD)\n")

# Maize HDR
cat("\nMAIZE:\n")
if(is.list(maize_hdr)) {
  for(i in 1:length(maize_hdr)) {
    cat("  Range", i, ":",
        maize_hdr[[i]][2], "-", maize_hdr[[i]][1], "cal BP",
        "(", 1950 - maize_hdr[[i]][1], "-", 1950 - maize_hdr[[i]][2], "cal AD)\n")
  }
  maize_earliest <- max(unlist(maize_hdr))
  maize_latest <- min(unlist(maize_hdr))
} else {
  cat("  ", maize_hdr[2], "-", maize_hdr[1], "cal BP",
      "(", 1950 - maize_hdr[1], "-", 1950 - maize_hdr[2], "cal AD)\n")
  maize_earliest <- max(maize_hdr)
  maize_latest <- min(maize_hdr)
}
cat("  Overall:", maize_earliest, "-", maize_latest, "cal BP",
    "(", 1950 - maize_latest, "-", 1950 - maize_earliest, "cal AD)\n")

# Squash HDR
cat("\nSQUASH:\n")
if(is.list(squash_hdr)) {
  for(i in 1:length(squash_hdr)) {
    cat("  Range", i, ":",
        squash_hdr[[i]][2], "-", squash_hdr[[i]][1], "cal BP",
        "(", 1950 - squash_hdr[[i]][1], "-", 1950 - squash_hdr[[i]][2], "cal AD)\n")
  }
  squash_earliest <- max(unlist(squash_hdr))
  squash_latest <- min(unlist(squash_hdr))
} else {
  cat("  ", squash_hdr[2], "-", squash_hdr[1], "cal BP",
      "(", 1950 - squash_hdr[1], "-", 1950 - squash_hdr[2], "cal AD)\n")
  squash_earliest <- max(squash_hdr)
  squash_latest <- min(squash_hdr)
}
cat("  Overall:", squash_earliest, "-", squash_latest, "cal BP",
    "(", 1950 - squash_latest, "-", 1950 - squash_earliest, "cal AD)\n")

# ============================================================================
# THREE-WAY HYPOTHESIS TESTING
# ============================================================================

cat("\n\n================================================================\n")
cat("THREE-WAY HYPOTHESIS TESTING\n")
cat("================================================================\n\n")

# Sample from posteriors
n_samples <- 10000

bean_dens <- as.vector(bean_boundary$densities)
maize_dens <- as.vector(maize_boundary$densities)
squash_dens <- as.vector(squash_boundary$densities)

bean_ages <- bean_boundary$ageGrid
maize_ages <- maize_boundary$ageGrid
squash_ages <- squash_boundary$ageGrid

bean_dens_norm <- bean_dens / sum(bean_dens)
maize_dens_norm <- maize_dens / sum(maize_dens)
squash_dens_norm <- squash_dens / sum(squash_dens)

bean_samples <- sample(bean_ages, n_samples, replace = TRUE, prob = bean_dens_norm)
maize_samples <- sample(maize_ages, n_samples, replace = TRUE, prob = maize_dens_norm)
squash_samples <- sample(squash_ages, n_samples, replace = TRUE, prob = squash_dens_norm)

# Test key hypotheses
cat("KEY HYPOTHESES:\n\n")

# H1: Squash before beans and maize
p_squash_first <- mean(squash_samples > bean_samples & squash_samples > maize_samples)
cat("H1: Squash arrived before both beans and maize\n")
cat("    P(squash > beans AND squash > maize) =", round(p_squash_first, 3), "\n\n")

# H2: Beans and maize simultaneous, but after squash
p_bm_simul_after_squash <- mean(
  abs(bean_samples - maize_samples) <= 100 &
  bean_samples < squash_samples &
  maize_samples < squash_samples
)
cat("H2: Beans and maize simultaneous (±100 yrs), after squash\n")
cat("    P(|bean-maize| ≤ 100 AND both < squash) =", round(p_bm_simul_after_squash, 3), "\n\n")

# Differences
cat("ARRIVAL TIME DIFFERENCES:\n\n")

cat("Squash - Bean:\n")
diff_sb <- squash_samples - bean_samples
cat("  Mean:", round(mean(diff_sb), 1), "years\n")
cat("  Median:", round(median(diff_sb), 1), "years\n")
cat("  95% CI: [", round(quantile(diff_sb, 0.025), 0), ",",
    round(quantile(diff_sb, 0.975), 0), "]\n\n")

cat("Squash - Maize:\n")
diff_sm <- squash_samples - maize_samples
cat("  Mean:", round(mean(diff_sm), 1), "years\n")
cat("  Median:", round(median(diff_sm), 1), "years\n")
cat("  95% CI: [", round(quantile(diff_sm, 0.025), 0), ",",
    round(quantile(diff_sm, 0.975), 0), "]\n\n")

cat("Bean - Maize:\n")
diff_bm <- bean_samples - maize_samples
cat("  Mean:", round(mean(diff_bm), 1), "years\n")
cat("  Median:", round(median(diff_bm), 1), "years\n")
cat("  95% CI: [", round(quantile(diff_bm, 0.025), 0), ",",
    round(quantile(diff_bm, 0.975), 0), "]\n\n")

# ============================================================================
# INTERPRETATION
# ============================================================================

cat("================================================================\n")
cat("INTERPRETATION\n")
cat("================================================================\n\n")

if(p_squash_first > 0.95) {
  cat("STRONG EVIDENCE: Squash arrived significantly before beans and maize\n")
} else if(p_squash_first > 0.75) {
  cat("MODERATE EVIDENCE: Squash likely arrived before beans and maize\n")
} else {
  cat("WEAK/INCONCLUSIVE: Timing of squash vs beans/maize uncertain\n")
}

cat("\nTime gap between squash and beans/maize:\n")
cat("  Approximately", round(mean(diff_sb), 0), "-", round(mean(diff_sm), 0),
    "years (", round(mean(c(diff_sb, diff_sm)), 0), "years average)\n")

cat("\n================================================================\n")
cat("ANALYSIS COMPLETE\n")
cat("================================================================\n")
