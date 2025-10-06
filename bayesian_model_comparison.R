# COMPREHENSIVE BAYESIAN ANALYSIS OF BEAN & MAIZE ARRIVAL
# Model comparison, outlier analysis, and hypothesis testing

options(repos = c(CRAN = "https://cloud.r-project.org"))

# Install packages
if (!require("Bchron", quietly = TRUE)) install.packages("Bchron", quiet = TRUE)
if (!require("rcarbon", quietly = TRUE)) install.packages("rcarbon", quiet = TRUE)
if (!require("coda", quietly = TRUE)) install.packages("coda", quiet = TRUE)

library(Bchron)
library(rcarbon)
library(coda)

cat("\n================================================================\n")
cat("  COMPREHENSIVE BAYESIAN RADIOCARBON MODEL COMPARISON\n")
cat("  Bean and Maize Arrival in Eastern Woodlands\n")
cat("================================================================\n\n")

# Load data
dates <- read.csv("radiocarbon_dates.csv")
bean_dates <- dates[dates$material == "bean", ]
maize_dates <- dates[dates$material == "maize", ]

cat("DATA SUMMARY:\n")
cat("  Beans: n =", nrow(bean_dates), "\n")
cat("  Maize: n =", nrow(maize_dates), "\n\n")

# ============================================================================
# STEP 1: OUTLIER ANALYSIS
# ============================================================================
cat("================================================================\n")
cat("STEP 1: OUTLIER DETECTION\n")
cat("================================================================\n\n")

# Calibrate all dates first
bean_cal <- calibrate(bean_dates$c14_age, bean_dates$c14_error,
                      calCurves = 'intcal20', ids = bean_dates$site)
maize_cal <- calibrate(maize_dates$c14_age, maize_dates$c14_error,
                       calCurves = 'intcal20', ids = maize_dates$site)

# Statistical outlier detection using IQR method on calibrated medians
bean_medians <- sapply(bean_cal$grids, function(x) {
  cumsum_prob <- cumsum(x$PrDens) / sum(x$PrDens)
  x$calBP[which.min(abs(cumsum_prob - 0.5))]
})

maize_medians <- sapply(maize_cal$grids, function(x) {
  cumsum_prob <- cumsum(x$PrDens) / sum(x$PrDens)
  x$calBP[which.min(abs(cumsum_prob - 0.5))]
})

# IQR outlier detection
detect_outliers <- function(values, labels) {
  Q1 <- quantile(values, 0.25)
  Q3 <- quantile(values, 0.75)
  IQR <- Q3 - Q1
  lower_fence <- Q1 - 3 * IQR  # Using 3*IQR for extreme outliers
  upper_fence <- Q3 + 3 * IQR

  outliers <- values < lower_fence | values > upper_fence

  cat("  IQR Analysis:\n")
  cat("    Q1 =", Q1, "cal BP\n")
  cat("    Q3 =", Q3, "cal BP\n")
  cat("    IQR =", IQR, "years\n")
  cat("    Lower fence (Q1 - 3*IQR) =", lower_fence, "cal BP\n")
  cat("    Upper fence (Q3 + 3*IQR) =", upper_fence, "cal BP\n")

  if (any(outliers)) {
    cat("  OUTLIERS DETECTED:\n")
    for (i in which(outliers)) {
      cat("    ", labels[i], ":", values[i], "cal BP\n")
    }
  } else {
    cat("  No extreme outliers detected.\n")
  }

  return(outliers)
}

cat("BEAN DATES:\n")
bean_outliers <- detect_outliers(bean_medians, bean_dates$site)

cat("\nMAIZE DATES:\n")
maize_outliers <- detect_outliers(maize_medians, maize_dates$site)

# Z-score analysis for context
bean_zscore <- scale(bean_medians)
maize_zscore <- scale(maize_medians)

cat("\n\nDates with |Z-score| > 2.5 (potentially unusual):\n")
cat("BEANS:\n")
extreme_beans <- abs(bean_zscore) > 2.5
if (any(extreme_beans)) {
  for (i in which(extreme_beans)) {
    cat("  ", bean_dates$site[i], ": Z =", round(bean_zscore[i], 2),
        "(", bean_medians[i], "cal BP)\n")
  }
} else {
  cat("  None\n")
}

cat("MAIZE:\n")
extreme_maize <- abs(maize_zscore) > 2.5
if (any(extreme_maize)) {
  for (i in which(extreme_maize)) {
    cat("  ", maize_dates$site[i], ": Z =", round(maize_zscore[i], 2),
        "(", maize_medians[i], "cal BP)\n")
  }
} else {
  cat("  None\n")
}

# Create filtered datasets (removing extreme outliers if any)
bean_dates_filtered <- bean_dates[!bean_outliers, ]
maize_dates_filtered <- maize_dates[!maize_outliers, ]

cat("\n\nFILTERED DATA:\n")
cat("  Beans: n =", nrow(bean_dates_filtered),
    "(removed", sum(bean_outliers), "outliers)\n")
cat("  Maize: n =", nrow(maize_dates_filtered),
    "(removed", sum(maize_outliers), "outliers)\n")

# ============================================================================
# STEP 2: BAYESIAN CHRONOLOGICAL MODELS USING BCHRON
# ============================================================================
cat("\n\n================================================================\n")
cat("STEP 2: BAYESIAN BOUNDARY ESTIMATION\n")
cat("================================================================\n\n")

# We'll use BchronDensity for boundary estimation
# This creates a probability density for the dates accounting for calibration

# For each crop, we'll focus on the oldest dates to estimate arrival
n_boundary <- 8  # Use more dates for boundary

# Sort by age (oldest first)
bean_sorted <- bean_dates_filtered[order(bean_dates_filtered$c14_age, decreasing = TRUE), ]
maize_sorted <- maize_dates_filtered[order(maize_dates_filtered$c14_age, decreasing = TRUE), ]

cat("Using", n_boundary, "oldest dates for boundary estimation\n\n")

# Bean boundary
cat("BEANS - Oldest dates:\n")
bean_boundary_subset <- bean_sorted[1:min(n_boundary, nrow(bean_sorted)), ]
for (i in 1:nrow(bean_boundary_subset)) {
  cat("  ", i, ". ", bean_boundary_subset$site[i], ": ",
      bean_boundary_subset$c14_age[i], " ± ",
      bean_boundary_subset$c14_error[i], " BP\n", sep = "")
}

cat("\nEstimating bean boundary density...\n")
bean_boundary_model <- BchronDensity(
  ages = bean_boundary_subset$c14_age,
  ageSds = bean_boundary_subset$c14_error,
  calCurves = rep('intcal20', nrow(bean_boundary_subset))
)

# Maize boundary
cat("\nMAIZE - Oldest dates:\n")
maize_boundary_subset <- maize_sorted[1:min(n_boundary, nrow(maize_sorted)), ]
for (i in 1:nrow(maize_boundary_subset)) {
  cat("  ", i, ". ", maize_boundary_subset$site[i], ": ",
      maize_boundary_subset$c14_age[i], " ± ",
      maize_boundary_subset$c14_error[i], " BP\n", sep = "")
}

cat("\nEstimating maize boundary density...\n")
maize_boundary_model <- BchronDensity(
  ages = maize_boundary_subset$c14_age,
  ageSds = maize_boundary_subset$c14_error,
  calCurves = rep('intcal20', nrow(maize_boundary_subset))
)

# Extract HDR (Highest Density Region) intervals
cat("\n\nBOUNDARY ESTIMATES (95% HDR):\n\n")

bean_hdr <- hdr(bean_boundary_model, prob = 0.95)
cat("BEANS:\n")

# Handle different return types from hdr
if (is.list(bean_hdr)) {
  # hdr returns a list of ranges
  cat("  95% HDR intervals:\n")
  for (i in 1:length(bean_hdr)) {
    range_vals <- bean_hdr[[i]]
    if (length(range_vals) == 2) {
      cat("    Range", i, ":", range_vals[2], "-", range_vals[1], "cal BP",
          "(", 1950 - range_vals[1], "-", 1950 - range_vals[2], "cal AD)\n")
    }
  }
  # Get overall bounds
  all_vals <- unlist(bean_hdr)
  bean_earliest <- max(all_vals)
  bean_latest <- min(all_vals)
  cat("  Overall range:", bean_latest, "-", bean_earliest, "cal BP",
      "(", 1950 - bean_earliest, "-", 1950 - bean_latest, "cal AD)\n")
} else if (is.matrix(bean_hdr)) {
  for (i in 1:nrow(bean_hdr)) {
    cat("    Range", i, ":", bean_hdr[i,2], "-", bean_hdr[i,1], "cal BP",
        "(", 1950 - bean_hdr[i,1], "-", 1950 - bean_hdr[i,2], "cal AD)\n")
  }
  bean_earliest <- max(bean_hdr)
  bean_latest <- min(bean_hdr)
} else {
  cat("    ", bean_hdr[2], "-", bean_hdr[1], "cal BP",
      "(", 1950 - bean_hdr[1], "-", 1950 - bean_hdr[2], "cal AD)\n")
  bean_earliest <- max(bean_hdr)
  bean_latest <- min(bean_hdr)
}

maize_hdr <- hdr(maize_boundary_model, prob = 0.95)
cat("\nMAIZE:\n")

# Handle different return types from hdr
if (is.list(maize_hdr)) {
  cat("  95% HDR intervals:\n")
  for (i in 1:length(maize_hdr)) {
    range_vals <- maize_hdr[[i]]
    if (length(range_vals) == 2) {
      cat("    Range", i, ":", range_vals[2], "-", range_vals[1], "cal BP",
          "(", 1950 - range_vals[1], "-", 1950 - range_vals[2], "cal AD)\n")
    }
  }
  all_vals <- unlist(maize_hdr)
  maize_earliest <- max(all_vals)
  maize_latest <- min(all_vals)
  cat("  Overall range:", maize_latest, "-", maize_earliest, "cal BP",
      "(", 1950 - maize_earliest, "-", 1950 - maize_latest, "cal AD)\n")
} else if (is.matrix(maize_hdr)) {
  for (i in 1:nrow(maize_hdr)) {
    cat("    Range", i, ":", maize_hdr[i,2], "-", maize_hdr[i,1], "cal BP",
        "(", 1950 - maize_hdr[i,1], "-", 1950 - maize_hdr[i,2], "cal AD)\n")
  }
  maize_earliest <- max(maize_hdr)
  maize_latest <- min(maize_hdr)
} else {
  cat("    ", maize_hdr[2], "-", maize_hdr[1], "cal BP",
      "(", 1950 - maize_hdr[1], "-", 1950 - maize_hdr[2], "cal AD)\n")
  maize_earliest <- max(maize_hdr)
  maize_latest <- min(maize_hdr)
}

# ============================================================================
# STEP 3: MODEL COMPARISON - DIFFERENT SCENARIOS
# ============================================================================
cat("\n\n================================================================\n")
cat("STEP 3: HYPOTHESIS TESTING VIA POSTERIOR COMPARISON\n")
cat("================================================================\n\n")

# We'll compare the posterior distributions to test hypotheses

# Extract posterior samples from the density estimates
# BchronDensity stores the density grid
bean_dens <- as.vector(bean_boundary_model$densities)
maize_dens <- as.vector(maize_boundary_model$densities)
# Use ageGrid for the age grid
bean_ages <- bean_boundary_model$ageGrid
maize_ages <- maize_boundary_model$ageGrid

# Normalize densities to sum to 1
bean_dens_norm <- bean_dens / sum(bean_dens)
maize_dens_norm <- maize_dens / sum(maize_dens)

# Calculate probability that beans arrived before maize
# P(bean_arrival > maize_arrival) - in BP, larger = older

# Sample from posteriors (weighted by density)
n_samples <- 10000
bean_samples <- sample(bean_ages, n_samples, replace = TRUE, prob = bean_dens_norm)
maize_samples <- sample(maize_ages, n_samples, replace = TRUE, prob = maize_dens_norm)

# Hypothesis tests
p_bean_earlier <- mean(bean_samples > maize_samples)
p_maize_earlier <- mean(maize_samples > bean_samples)
p_simultaneous_50yr <- mean(abs(bean_samples - maize_samples) <= 50)
p_simultaneous_100yr <- mean(abs(bean_samples - maize_samples) <= 100)

cat("HYPOTHESIS TESTING RESULTS:\n\n")
cat("H1: Beans arrived before maize\n")
cat("    Posterior probability: P(bean > maize) =", round(p_bean_earlier, 3), "\n")
cat("    Bayes Factor (H1 vs H2):", round(p_bean_earlier / p_maize_earlier, 2), "\n\n")

cat("H2: Maize arrived before beans\n")
cat("    Posterior probability: P(maize > bean) =", round(p_maize_earlier, 3), "\n")
cat("    Bayes Factor (H2 vs H1):", round(p_maize_earlier / p_bean_earlier, 2), "\n\n")

cat("H3: Simultaneous arrival (within 50 years)\n")
cat("    Posterior probability: P(|diff| ≤ 50 yrs) =", round(p_simultaneous_50yr, 3), "\n\n")

cat("H4: Simultaneous arrival (within 100 years)\n")
cat("    Posterior probability: P(|diff| ≤ 100 yrs) =", round(p_simultaneous_100yr, 3), "\n\n")

# Difference in arrival times
arrival_diff <- bean_samples - maize_samples
cat("DIFFERENCE IN ARRIVAL TIMES (Bean - Maize):\n")
cat("  Mean:", round(mean(arrival_diff), 1), "years\n")
cat("  Median:", round(median(arrival_diff), 1), "years\n")
cat("  95% Credible Interval:", round(quantile(arrival_diff, c(0.025, 0.975)), 1), "years\n")
cat("  (Positive = beans earlier, Negative = maize earlier)\n")

# Interpretation
cat("\n\nINTERPRETATION:\n")
if (p_bean_earlier > 0.95) {
  cat("  STRONG evidence that beans arrived before maize.\n")
} else if (p_maize_earlier > 0.95) {
  cat("  STRONG evidence that maize arrived before beans.\n")
} else if (p_simultaneous_100yr > 0.80) {
  cat("  Evidence suggests SIMULTANEOUS or near-simultaneous arrival.\n")
} else {
  cat("  Evidence is INCONCLUSIVE regarding order of arrival.\n")
}

# Bayes Factor interpretation
bf_bean_maize <- p_bean_earlier / p_maize_earlier
cat("\nBayes Factor interpretation (Kass & Raftery 1995):\n")
if (bf_bean_maize > 100 || bf_bean_maize < 0.01) {
  cat("  Decisive evidence\n")
} else if (bf_bean_maize > 10 || bf_bean_maize < 0.1) {
  cat("  Strong evidence\n")
} else if (bf_bean_maize > 3 || bf_bean_maize < 0.33) {
  cat("  Positive evidence\n")
} else {
  cat("  Not worth more than a bare mention (inconclusive)\n")
}

# ============================================================================
# STEP 4: SENSITIVITY ANALYSIS
# ============================================================================
cat("\n\n================================================================\n")
cat("STEP 4: SENSITIVITY ANALYSIS\n")
cat("================================================================\n\n")

cat("Testing sensitivity to number of dates included in boundary...\n\n")

# Test with different numbers of dates
n_values <- c(3, 5, 8, 10)
sensitivity_results <- data.frame(
  n_dates = integer(),
  bean_hdr_lower = numeric(),
  bean_hdr_upper = numeric(),
  maize_hdr_lower = numeric(),
  maize_hdr_upper = numeric(),
  p_bean_earlier = numeric()
)

for (n in n_values) {
  if (n <= nrow(bean_sorted) && n <= nrow(maize_sorted)) {
    cat("  Testing with n =", n, "dates...\n")

    # Bean
    bean_sub <- bean_sorted[1:n, ]
    bean_mod <- BchronDensity(
      ages = bean_sub$c14_age,
      ageSds = bean_sub$c14_error,
      calCurves = rep('intcal20', n)
    )

    # Maize
    maize_sub <- maize_sorted[1:n, ]
    maize_mod <- BchronDensity(
      ages = maize_sub$c14_age,
      ageSds = maize_sub$c14_error,
      calCurves = rep('intcal20', n)
    )

    # Get HDRs
    bean_h <- hdr(bean_mod, prob = 0.95)
    maize_h <- hdr(maize_mod, prob = 0.95)

    # Sample and compare
    bean_dens_s <- bean_mod$Density / sum(bean_mod$Density)
    maize_dens_s <- maize_mod$Density / sum(maize_mod$Density)
    bean_samp <- sample(bean_mod$denCalAges, 5000, replace = TRUE, prob = bean_dens_s)
    maize_samp <- sample(maize_mod$denCalAges, 5000, replace = TRUE, prob = maize_dens_s)
    p_bean <- mean(bean_samp > maize_samp)

    # Store results - handle different HDR return types
    if (is.list(bean_h)) {
      all_bean_vals <- unlist(bean_h)
      bean_range <- c(min(all_bean_vals), max(all_bean_vals))
    } else if (is.matrix(bean_h)) {
      bean_range <- c(bean_h[1,2], bean_h[1,1])
    } else {
      bean_range <- c(min(bean_h), max(bean_h))
    }

    if (is.list(maize_h)) {
      all_maize_vals <- unlist(maize_h)
      maize_range <- c(min(all_maize_vals), max(all_maize_vals))
    } else if (is.matrix(maize_h)) {
      maize_range <- c(maize_h[1,2], maize_h[1,1])
    } else {
      maize_range <- c(min(maize_h), max(maize_h))
    }

    sensitivity_results <- rbind(sensitivity_results, data.frame(
      n_dates = n,
      bean_hdr_lower = bean_range[1],
      bean_hdr_upper = bean_range[2],
      maize_hdr_lower = maize_range[1],
      maize_hdr_upper = maize_range[2],
      p_bean_earlier = p_bean
    ))
  }
}

cat("\n\nSENSITIVITY RESULTS:\n")
print(sensitivity_results, row.names = FALSE)

cat("\n\nStability check:\n")
cat("  Range in P(bean earlier):",
    round(range(sensitivity_results$p_bean_earlier), 3), "\n")
if (max(sensitivity_results$p_bean_earlier) - min(sensitivity_results$p_bean_earlier) < 0.1) {
  cat("  Result: STABLE across different n values\n")
} else {
  cat("  Result: SENSITIVE to number of dates included\n")
}

# ============================================================================
# SAVE RESULTS
# ============================================================================
cat("\n\n================================================================\n")
cat("SAVING RESULTS\n")
cat("================================================================\n\n")

# Save sensitivity analysis
write.csv(sensitivity_results, "model_sensitivity_analysis.csv", row.names = FALSE)
cat("Saved: model_sensitivity_analysis.csv\n")

# Save posterior samples for further analysis
posterior_samples <- data.frame(
  bean_arrival = bean_samples,
  maize_arrival = maize_samples,
  difference = arrival_diff
)
write.csv(posterior_samples, "posterior_arrival_samples.csv", row.names = FALSE)
cat("Saved: posterior_arrival_samples.csv\n")

# Summary statistics
summary_stats <- data.frame(
  Taxon = c("Bean", "Maize"),
  N_dates = c(nrow(bean_dates_filtered), nrow(maize_dates_filtered)),
  N_boundary = c(nrow(bean_boundary_subset), nrow(maize_boundary_subset)),
  Mean_arrival = c(mean(bean_samples), mean(maize_samples)),
  Median_arrival = c(median(bean_samples), median(maize_samples)),
  CI_95_lower = c(quantile(bean_samples, 0.975), quantile(maize_samples, 0.975)),
  CI_95_upper = c(quantile(bean_samples, 0.025), quantile(maize_samples, 0.025))
)
write.csv(summary_stats, "bayesian_model_summary.csv", row.names = FALSE)
cat("Saved: bayesian_model_summary.csv\n")

cat("\n================================================================\n")
cat("ANALYSIS COMPLETE\n")
cat("================================================================\n")
