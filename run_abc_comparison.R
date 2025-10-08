# METHODOLOGICAL COMPARISON: ABC vs Bchron for Bean/Maize Arrival
# Comparing arrival date estimates across different analytical methods
# Following DiNapoli et al. 2021 to assess methodological sensitivity

library(tidyverse)
library(rcarbon)
library(Bchron)

source("abc_demographic_models.R")

# ==============================================================================
# LOAD DATA
# ==============================================================================

cat("Loading radiocarbon data...\n")
all_data <- read_csv("radiocarbon_dates.csv", show_col_types = FALSE)

cat(sprintf("Total dates: %d\n", nrow(all_data)))
cat(sprintf("  Beans: %d\n", sum(all_data$material == "bean")))
cat(sprintf("  Maize: %d\n", sum(all_data$material == "maize")))
cat(sprintf("  Squash: %d\n", sum(all_data$material == "squash")))

# ==============================================================================
# METHOD 1: BCHRON BOUNDARY ESTIMATION (Current approach)
# ==============================================================================

run_bchron_boundary <- function(material_data, material_name) {
  cat(sprintf("\n=== Bchron Analysis: %s ===\n", material_name))

  ages <- material_data$c14_age
  errors <- material_data$c14_error

  # BchronDensity for boundary estimation
  result <- BchronDensity(
    ages = ages,
    ageSds = errors,
    calCurves = rep("intcal20", length(ages))
  )

  # Extract earliest date (95% lower bound)
  cumsum_dens <- cumsum(result$densities) / sum(result$densities)
  earliest_95 <- result$calAges[min(which(cumsum_dens >= 0.025))]
  median_est <- result$calAges[min(which(cumsum_dens >= 0.5))]
  latest_95 <- result$calAges[max(which(cumsum_dens <= 0.975))]

  return(list(
    method = "Bchron",
    material = material_name,
    n_dates = length(ages),
    earliest_95 = earliest_95,
    median = median_est,
    latest_95 = latest_95,
    result = result
  ))
}


# ==============================================================================
# METHOD 2: ABC LOGISTIC GROWTH (DiNapoli et al. approach)
# ==============================================================================

run_abc_logistic <- function(material_data, material_name,
                             n_simulations = 20000, n_accept = 1000) {
  cat(sprintf("\n=== ABC Logistic Growth: %s ===\n", material_name))

  # Calibrate dates (non-normalized following DiNapoli et al.)
  cal_dates <- calibrate(
    x = material_data$c14_age,
    errors = material_data$c14_error,
    calCurves = "intcal20",
    normalised = FALSE  # Critical: NO normalization
  )

  # Create observed SPD
  observed_spd <- spd(cal_dates, timeRange = c(1200, 200))

  # Time range for model
  time_range <- seq(1200, 200, by = -1)

  # Run ABC
  abc_result <- abc_spd_demographic(
    observed_spd = observed_spd,
    n_dates = nrow(material_data),
    observed_errors = material_data$c14_error,
    time_range = time_range,
    prior_N_t0 = c(0.001, 0.3),  # Initial population (small for "arrival")
    prior_r = c(0.001, 0.05),    # Growth rate
    n_simulations = n_simulations,
    n_accept = n_accept,
    cal_curve = "intcal20",
    normalize = FALSE
  )

  # Extract posteriors
  posteriors <- extract_posteriors(abc_result)
  summary_stats <- summarize_posteriors(posteriors)

  # Get arrival date posterior (threshold = 5% of carrying capacity)
  arrival_samples <- get_arrival_posterior(abc_result, time_range, threshold = 0.05)

  # Remove NAs
  arrival_samples <- arrival_samples[!is.na(arrival_samples)]

  # Summary statistics
  arrival_median <- median(arrival_samples)
  arrival_hpd <- hpd_90(arrival_samples)

  # Generate fitted trajectory from median parameters
  median_params <- list(
    N_t0 = median(posteriors$N_t0),
    r = median(posteriors$r)
  )

  fitted_N_t <- logistic_growth_model(median_params, time_range)

  return(list(
    method = "ABC_Logistic",
    material = material_name,
    n_dates = nrow(material_data),
    earliest_95 = arrival_hpd[2],  # Earlier in BP = higher value
    median = arrival_median,
    latest_95 = arrival_hpd[1],    # Later in BP = lower value
    posteriors = posteriors,
    summary_stats = summary_stats,
    arrival_samples = arrival_samples,
    fitted_trajectory = data.frame(calBP = time_range, N = fitted_N_t),
    abc_result = abc_result
  ))
}


# ==============================================================================
# RUN COMPARISON FOR BEANS, MAIZE, SQUASH
# ==============================================================================

cat("\n\n########################################\n")
cat("# METHODOLOGICAL COMPARISON\n")
cat("########################################\n\n")

# Storage for results
comparison_results <- list()

# Analyze each crop
for (crop in c("bean", "maize", "squash")) {

  cat(sprintf("\n\n=====================================\n"))
  cat(sprintf("# %s\n", toupper(crop)))
  cat(sprintf("=====================================\n"))

  crop_data <- all_data %>% filter(material == crop)

  cat(sprintf("N dates: %d\n", nrow(crop_data)))

  if (nrow(crop_data) < 10) {
    cat(sprintf("Skipping %s - insufficient data (< 10 dates)\n", crop))
    next
  }

  # Method 1: Bchron
  bchron_result <- run_bchron_boundary(crop_data, crop)

  # Method 2: ABC Logistic
  # Use more simulations for final analysis (20000+)
  abc_result <- run_abc_logistic(
    crop_data,
    crop,
    n_simulations = 20000,  # Increase for final analysis
    n_accept = 1000
  )

  comparison_results[[crop]] <- list(
    bchron = bchron_result,
    abc_logistic = abc_result,
    n_dates = nrow(crop_data)
  )
}

# ==============================================================================
# SUMMARIZE COMPARISON
# ==============================================================================

cat("\n\n========================================\n")
cat("METHODOLOGICAL COMPARISON SUMMARY\n")
cat("========================================\n\n")

comparison_table <- do.call(rbind, lapply(names(comparison_results), function(crop) {
  res <- comparison_results[[crop]]

  # Convert BP to CE for easier interpretation
  bp_to_ce <- function(bp) 1950 - bp

  data.frame(
    Crop = toupper(crop),
    N_Dates = res$n_dates,
    Bchron_Median_CE = bp_to_ce(res$bchron$median),
    Bchron_95_Lower_CE = bp_to_ce(res$bchron$latest_95),
    Bchron_95_Upper_CE = bp_to_ce(res$bchron$earliest_95),
    ABC_Median_CE = bp_to_ce(res$abc_logistic$median),
    ABC_95_Lower_CE = bp_to_ce(res$abc_logistic$latest_95),
    ABC_95_Upper_CE = bp_to_ce(res$abc_logistic$earliest_95),
    Difference_Median = abs(res$bchron$median - res$abc_logistic$median)
  )
}))

print(comparison_table)

# Save results
write_csv(comparison_table, "method_comparison_results.csv")
saveRDS(comparison_results, "method_comparison_full_results.rds")

cat("\n\nResults saved to:\n")
cat("  - method_comparison_results.csv\n")
cat("  - method_comparison_full_results.rds\n")

# ==============================================================================
# BEAN VS MAIZE COMPARISON ACROSS METHODS
# ==============================================================================

if ("bean" %in% names(comparison_results) && "maize" %in% names(comparison_results)) {

  cat("\n\n========================================\n")
  cat("BEAN vs MAIZE COMPARISON\n")
  cat("========================================\n\n")

  # Bchron comparison
  bean_bchron <- comparison_results$bean$bchron$median
  maize_bchron <- comparison_results$maize$bchron$median
  diff_bchron <- bean_bchron - maize_bchron

  cat("BCHRON Method:\n")
  cat(sprintf("  Bean arrival:  %d BP (%.0f CE)\n", bean_bchron, 1950 - bean_bchron))
  cat(sprintf("  Maize arrival: %d BP (%.0f CE)\n", maize_bchron, 1950 - maize_bchron))
  cat(sprintf("  Difference:    %d years ", abs(diff_bchron)))
  if (diff_bchron > 0) {
    cat("(maize arrived first)\n")
  } else if (diff_bchron < 0) {
    cat("(bean arrived first)\n")
  } else {
    cat("(simultaneous)\n")
  }

  # ABC comparison
  bean_abc <- comparison_results$bean$abc_logistic$median
  maize_abc <- comparison_results$maize$abc_logistic$median
  diff_abc <- bean_abc - maize_abc

  cat("\nABC Logistic Method:\n")
  cat(sprintf("  Bean arrival:  %d BP (%.0f CE)\n", bean_abc, 1950 - bean_abc))
  cat(sprintf("  Maize arrival: %d BP (%.0f CE)\n", maize_abc, 1950 - maize_abc))
  cat(sprintf("  Difference:    %d years ", abs(diff_abc)))
  if (diff_abc > 0) {
    cat("(maize arrived first)\n")
  } else if (diff_abc < 0) {
    cat("(bean arrived first)\n")
  } else {
    cat("(simultaneous)\n")
  }

  # Method agreement
  cat("\nMethod Agreement:\n")
  cat(sprintf("  Difference between methods (Bean):  %d years\n",
              abs(bean_bchron - bean_abc)))
  cat(sprintf("  Difference between methods (Maize): %d years\n",
              abs(maize_bchron - maize_abc)))

  if (sign(diff_bchron) == sign(diff_abc)) {
    cat("  ✓ Methods agree on arrival order\n")
  } else {
    cat("  ✗ Methods disagree on arrival order\n")
  }
}

# ==============================================================================
# GENERATE COMPARISON PLOTS
# ==============================================================================

pdf("method_comparison_plots.pdf", width = 14, height = 10)

for (crop in names(comparison_results)) {

  res <- comparison_results[[crop]]

  par(mfrow = c(2, 3), mar = c(4, 4, 3, 1))

  # Plot 1: Bchron density
  plot(res$bchron$result$calAges, res$bchron$result$densities,
       type = "l", col = "blue", lwd = 2,
       main = paste(toupper(crop), "- Bchron Boundary"),
       xlab = "Cal BP", ylab = "Probability Density",
       xlim = c(1200, 200))
  abline(v = res$bchron$median, col = "blue", lty = 2, lwd = 2)
  abline(v = c(res$bchron$earliest_95, res$bchron$latest_95),
         col = "blue", lty = 3)
  legend("topright", legend = c("Median", "95% HDR"),
         lty = c(2, 3), col = "blue", lwd = c(2, 1))

  # Plot 2: ABC fitted demographic trajectory
  plot(res$abc_logistic$fitted_trajectory$calBP,
       res$abc_logistic$fitted_trajectory$N,
       type = "l", col = "red", lwd = 2,
       main = paste(toupper(crop), "- ABC Logistic Growth"),
       xlab = "Cal BP", ylab = "Population (proportion of K)",
       xlim = c(1200, 200))
  abline(v = res$abc_logistic$median, col = "red", lty = 2, lwd = 2)
  abline(v = c(res$abc_logistic$earliest_95, res$abc_logistic$latest_95),
         col = "red", lty = 3)
  abline(h = 0.05, col = "gray", lty = 3)  # Arrival threshold
  legend("topleft", legend = c("Median arrival", "90% HPD", "5% threshold"),
         lty = c(2, 3, 3), col = c("red", "red", "gray"), lwd = c(2, 1, 1))

  # Plot 3: ABC arrival date posterior
  hist(res$abc_logistic$arrival_samples, breaks = 50, col = "salmon",
       main = paste(toupper(crop), "- ABC Arrival Posterior"),
       xlab = "Arrival Date (Cal BP)", ylab = "Frequency")
  abline(v = res$abc_logistic$median, col = "red", lwd = 2, lty = 2)
  abline(v = c(res$abc_logistic$earliest_95, res$abc_logistic$latest_95),
         col = "red", lty = 3)

  # Plot 4: ABC posterior - initial population
  hist(res$abc_logistic$posteriors$N_t0, breaks = 50, col = "lightblue",
       main = "ABC Posterior: Initial Population",
       xlab = "N_t0 (proportion of K)")

  # Plot 5: ABC posterior - growth rate
  hist(res$abc_logistic$posteriors$r, breaks = 50, col = "lightgreen",
       main = "ABC Posterior: Growth Rate",
       xlab = "r (per year)")

  # Plot 6: Method comparison
  estimates <- c(res$bchron$median, res$abc_logistic$median)
  lower_bounds <- c(res$bchron$earliest_95, res$abc_logistic$earliest_95)
  upper_bounds <- c(res$bchron$latest_95, res$abc_logistic$latest_95)
  methods <- c("Bchron", "ABC Logistic")

  plot(1:2, estimates, ylim = range(c(lower_bounds, upper_bounds)),
       xlim = c(0.5, 2.5), xlab = "", ylab = "Arrival Date (Cal BP)",
       xaxt = "n", pch = 19, cex = 2,
       main = paste(toupper(crop), "- Method Comparison"))
  axis(1, at = 1:2, labels = methods)
  segments(1:2, lower_bounds, 1:2, upper_bounds, lwd = 3)
  segments(1:2, lower_bounds, 1:2, lower_bounds, lwd = 2, lty = 1)
  segments(1:2, upper_bounds, 1:2, upper_bounds, lwd = 2, lty = 1)
  abline(h = mean(estimates), lty = 3, col = "gray")

  # Add difference text
  diff_years <- abs(estimates[1] - estimates[2])
  text(1.5, max(upper_bounds), sprintf("Difference: %d years", diff_years),
       pos = 3, cex = 0.9, font = 2)
}

# Overall comparison plot: Bean vs Maize
if ("bean" %in% names(comparison_results) && "maize" %in% names(comparison_results)) {

  par(mfrow = c(1, 1), mar = c(5, 5, 4, 2))

  # Prepare data
  crops <- c("BEAN", "MAIZE")
  bchron_est <- c(comparison_results$bean$bchron$median,
                  comparison_results$maize$bchron$median)
  abc_est <- c(comparison_results$bean$abc_logistic$median,
               comparison_results$maize$abc_logistic$median)

  bchron_lower <- c(comparison_results$bean$bchron$earliest_95,
                    comparison_results$maize$bchron$earliest_95)
  bchron_upper <- c(comparison_results$bean$bchron$latest_95,
                    comparison_results$maize$bchron$latest_95)

  abc_lower <- c(comparison_results$bean$abc_logistic$earliest_95,
                 comparison_results$maize$abc_logistic$earliest_95)
  abc_upper <- c(comparison_results$bean$abc_logistic$latest_95,
                 comparison_results$maize$abc_logistic$latest_95)

  # Plot
  x_pos <- c(1, 2, 4, 5)
  all_est <- c(bchron_est, abc_est)
  all_lower <- c(bchron_lower, abc_lower)
  all_upper <- c(bchron_upper, abc_upper)
  colors <- c("blue", "blue", "red", "red")

  plot(x_pos, all_est, ylim = range(c(all_lower, all_upper)),
       xlim = c(0, 6), xlab = "", ylab = "Arrival Date (Cal BP)",
       xaxt = "n", pch = 19, cex = 2, col = colors,
       main = "Bean vs Maize Arrival: Method Comparison")

  # Add error bars
  segments(x_pos, all_lower, x_pos, all_upper, lwd = 3, col = colors)

  # Add x-axis labels
  axis(1, at = c(1.5, 4.5), labels = c("Bchron", "ABC Logistic"), cex.axis = 1.2)

  # Add legend
  legend("topright", legend = crops, col = c("blue", "red"),
         pch = 19, cex = 1.2, title = "Crop")

  # Add grid
  abline(v = 3, lty = 2, col = "gray")
  grid()
}

dev.off()

cat("\n\nComparison plots saved to: method_comparison_plots.pdf\n")

cat("\n\n========================================\n")
cat("Analysis complete!\n")
cat("========================================\n")
