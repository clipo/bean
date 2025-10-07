# BOUNDARY ESTIMATION SENSITIVITY ANALYSIS
# Testing robustness to number of dates used in boundary estimation

library(tidyverse)
library(Bchron)

# ==============================================================================
# LOAD DATA
# ==============================================================================

all_data <- read_csv("radiocarbon_dates.csv", show_col_types = FALSE)

bean_data <- all_data %>%
  filter(material == "bean") %>%
  arrange(desc(c14_age))  # Oldest first

maize_data <- all_data %>%
  filter(material == "maize") %>%
  arrange(desc(c14_age))  # Oldest first

cat("Total bean dates:", nrow(bean_data), "\n")
cat("Total maize dates:", nrow(maize_data), "\n\n")

# ==============================================================================
# SENSITIVITY FUNCTION
# ==============================================================================

#' Test boundary sensitivity to number of dates
#' @param dates_df Data frame with c14_age and c14_error
#' @param material_name Name for output
#' @param n_dates Number of oldest dates to use
boundary_with_n_dates <- function(dates_df, material_name, n_dates) {

  # Select n oldest dates
  subset_data <- dates_df[1:n_dates, ]

  # Run BchronDensity
  result <- BchronDensity(
    ages = subset_data$c14_age,
    ageSds = subset_data$c14_error,
    calCurves = rep("intcal20", n_dates)
  )

  # Extract boundary estimates
  cumsum_dens <- cumsum(result$densities) / sum(result$densities)

  earliest_95 <- result$ageGrid[min(which(cumsum_dens >= 0.025))]
  earliest_68 <- result$ageGrid[min(which(cumsum_dens >= 0.16))]
  median <- result$ageGrid[min(which(cumsum_dens >= 0.5))]
  latest_68 <- result$ageGrid[max(which(cumsum_dens <= 0.84))]
  latest_95 <- result$ageGrid[max(which(cumsum_dens <= 0.975))]

  # Return full posterior and summaries
  return(list(
    material = material_name,
    n_dates = n_dates,
    median = median,
    hdr68 = c(earliest_68, latest_68),
    hdr95 = c(earliest_95, latest_95),
    width_68 = earliest_68 - latest_68,
    width_95 = earliest_95 - latest_95,
    ageGrid = result$ageGrid,
    densities = result$densities
  ))
}

# ==============================================================================
# RUN SENSITIVITY TESTS
# ==============================================================================

cat(strrep("=", 70), "\n")
cat("BOUNDARY SENSITIVITY ANALYSIS\n")
cat("Testing n = 5, 6, 7, 8, 9, 10 dates\n")
cat(strrep("=", 70), "\n\n")

# Test range of n values
n_values <- 5:10

bean_sensitivity <- list()
maize_sensitivity <- list()

cat("BEAN SENSITIVITY:\n")
for (n in n_values) {
  result <- boundary_with_n_dates(bean_data, "Bean", n)
  bean_sensitivity[[as.character(n)]] <- result

  cat(sprintf("n=%d: Median=%d BP (%.0f CE), 95%% HDR=%d-%d BP (width=%d yrs)\n",
              n, result$median, 1950 - result$median,
              result$hdr95[1], result$hdr95[2], result$width_95))
}

cat("\nMAIZE SENSITIVITY:\n")
for (n in n_values) {
  result <- boundary_with_n_dates(maize_data, "Maize", n)
  maize_sensitivity[[as.character(n)]] <- result

  cat(sprintf("n=%d: Median=%d BP (%.0f CE), 95%% HDR=%d-%d BP (width=%d yrs)\n",
              n, result$median, 1950 - result$median,
              result$hdr95[1], result$hdr95[2], result$width_95))
}

# ==============================================================================
# PAIRWISE DIFFERENCES FOR EACH N
# ==============================================================================

cat("\n", strrep("=", 70), "\n")
cat("BEAN-MAIZE DIFFERENCE BY N\n")
cat(strrep("=", 70), "\n\n")

difference_results <- data.frame()

for (n in n_values) {
  bean_result <- bean_sensitivity[[as.character(n)]]
  maize_result <- maize_sensitivity[[as.character(n)]]

  # Calculate difference
  diff_median <- bean_result$median - maize_result$median

  # Calculate overlap
  bean_95 <- bean_result$hdr95
  maize_95 <- maize_result$hdr95

  overlap_start <- max(bean_95[1], maize_95[1])
  overlap_end <- min(bean_95[2], maize_95[2])
  overlap_years <- max(0, overlap_start - overlap_end)

  bean_range <- bean_95[1] - bean_95[2]
  maize_range <- maize_95[1] - maize_95[2]

  overlap_pct_bean <- (overlap_years / bean_range) * 100
  overlap_pct_maize <- (overlap_years / maize_range) * 100

  cat(sprintf("n=%d: Difference=%+d yrs, Overlap=%.1f%% (bean), %.1f%% (maize)\n",
              n, diff_median, overlap_pct_bean, overlap_pct_maize))

  difference_results <- rbind(difference_results, data.frame(
    n = n,
    diff_median = diff_median,
    overlap_pct_bean = overlap_pct_bean,
    overlap_pct_maize = overlap_pct_maize
  ))
}

# ==============================================================================
# SUMMARY STATISTICS
# ==============================================================================

cat("\n", strrep("=", 70), "\n")
cat("SENSITIVITY SUMMARY\n")
cat(strrep("=", 70), "\n\n")

# Extract medians for all n
bean_medians <- sapply(bean_sensitivity, function(x) x$median)
maize_medians <- sapply(maize_sensitivity, function(x) x$median)

# Extract width for all n
bean_widths_95 <- sapply(bean_sensitivity, function(x) x$width_95)
maize_widths_95 <- sapply(maize_sensitivity, function(x) x$width_95)

cat("BEAN:\n")
cat(sprintf("  Median range: %d - %d BP (range = %d yrs)\n",
            min(bean_medians), max(bean_medians),
            max(bean_medians) - min(bean_medians)))
cat(sprintf("  95%% HDR width range: %d - %d yrs\n",
            min(bean_widths_95), max(bean_widths_95)))
cat(sprintf("  Coefficient of variation (median): %.2f%%\n",
            sd(bean_medians) / mean(bean_medians) * 100))

cat("\nMAIZE:\n")
cat(sprintf("  Median range: %d - %d BP (range = %d yrs)\n",
            min(maize_medians), max(maize_medians),
            max(maize_medians) - min(maize_medians)))
cat(sprintf("  95%% HDR width range: %d - %d yrs\n",
            min(maize_widths_95), max(maize_widths_95)))
cat(sprintf("  Coefficient of variation (median): %.2f%%\n",
            sd(maize_medians) / mean(maize_medians) * 100))

cat("\nBEAN-MAIZE DIFFERENCE:\n")
cat(sprintf("  Difference range: %+d to %+d yrs\n",
            min(difference_results$diff_median),
            max(difference_results$diff_median)))
cat(sprintf("  Mean overlap: %.1f%% (bean), %.1f%% (maize)\n",
            mean(difference_results$overlap_pct_bean),
            mean(difference_results$overlap_pct_maize)))

# ==============================================================================
# BAYES FACTORS FOR MODEL COMPARISON
# ==============================================================================

cat("\n", strrep("=", 70), "\n")
cat("BAYES FACTORS: SIMULTANEOUS VS. SEQUENTIAL\n")
cat(strrep("=", 70), "\n\n")

for (n in n_values) {
  bean_result <- bean_sensitivity[[as.character(n)]]
  maize_result <- maize_sensitivity[[as.character(n)]]

  # Sample from posteriors
  n_samples <- 10000

  # Interpolate densities to get samples
  bean_samples <- sample(bean_result$ageGrid, size = n_samples,
                         replace = TRUE, prob = bean_result$densities)
  maize_samples <- sample(maize_result$ageGrid, size = n_samples,
                          replace = TRUE, prob = maize_result$densities)

  # Calculate difference
  diff <- bean_samples - maize_samples

  # Hypotheses
  p_simul_50 <- mean(abs(diff) <= 50)
  p_simul_100 <- mean(abs(diff) <= 100)
  p_bean_first <- mean(diff > 0)
  p_maize_first <- mean(diff < 0)

  # Bayes factors (vs. flat alternative)
  bf_simul_100 <- p_simul_100 / 0.5  # Simplistic, but informative

  cat(sprintf("n=%d:\n", n))
  cat(sprintf("  P(simultaneous ≤50 yrs) = %.3f\n", p_simul_50))
  cat(sprintf("  P(simultaneous ≤100 yrs) = %.3f\n", p_simul_100))
  cat(sprintf("  P(bean first) = %.3f\n", p_bean_first))
  cat(sprintf("  P(maize first) = %.3f\n", p_maize_first))
  cat(sprintf("  BF (simul/seq) ≈ %.2f\n\n", bf_simul_100))
}

# ==============================================================================
# SAVE RESULTS
# ==============================================================================

results <- list(
  bean_sensitivity = bean_sensitivity,
  maize_sensitivity = maize_sensitivity,
  difference_results = difference_results,
  summary = list(
    bean_medians = bean_medians,
    maize_medians = maize_medians,
    bean_widths = bean_widths_95,
    maize_widths = maize_widths_95
  )
)

saveRDS(results, "boundary_sensitivity_results.rds")
cat("\nResults saved to: boundary_sensitivity_results.rds\n")
