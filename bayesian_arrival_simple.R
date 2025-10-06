# Bayesian Analysis of Maize and Bean Arrival Times
# Simplified version using rcarbon

# Set CRAN mirror
options(repos = c(CRAN = "https://cloud.r-project.org"))

# Install and load only rcarbon (simpler, fewer dependencies)
if (!require("rcarbon")) install.packages("rcarbon", quiet = TRUE)
library(rcarbon)

# Load the radiocarbon data
dates <- read.csv("radiocarbon_dates.csv")

# Separate by taxon
bean_dates <- dates[dates$material == "bean", ]
maize_dates <- dates[dates$material == "maize", ]

cat("=== DATA SUMMARY ===\n")
cat("Total bean dates:", nrow(bean_dates), "\n")
cat("Total maize dates:", nrow(maize_dates), "\n\n")

cat("Bean 14C ages: range =", min(bean_dates$c14_age), "-", max(bean_dates$c14_age), "BP\n")
cat("Maize 14C ages: range =", min(maize_dates$c14_age), "-", max(maize_dates$c14_age), "BP\n\n")

# Calibrate all dates
cat("Calibrating bean dates...\n")
bean_cal <- calibrate(
  x = bean_dates$c14_age,
  errors = bean_dates$c14_error,
  calCurves = 'intcal20',
  ids = bean_dates$site
)

cat("Calibrating maize dates...\n")
maize_cal <- calibrate(
  x = maize_dates$c14_age,
  errors = maize_dates$c14_error,
  calCurves = 'intcal20',
  ids = maize_dates$site
)

# Get summary statistics for individual dates
cat("\n=== INDIVIDUAL DATE RANGES (2-sigma, 95.4%) ===\n\n")

# Find oldest dates
bean_oldest_idx <- which.max(bean_dates$c14_age)
maize_oldest_idx <- which.max(maize_dates$c14_age)

cat("OLDEST BEAN DATE:\n")
cat("  Site:", bean_dates$site[bean_oldest_idx], "\n")
cat("  14C age:", bean_dates$c14_age[bean_oldest_idx], "±", bean_dates$c14_error[bean_oldest_idx], "BP\n")
bean_oldest_sum <- summary(bean_cal, prob = 0.95)
bean_oldest_range <- bean_oldest_sum[bean_oldest_idx, ]
cat("  Median cal BP:", bean_oldest_range$MedianBP, "\n")
cat("  1-sigma range:", bean_oldest_range$OneSigma_BP, "cal BP\n")
cat("  2-sigma range:", bean_oldest_range$TwoSigma_BP, "cal BP\n\n")

cat("OLDEST MAIZE DATE:\n")
cat("  Site:", maize_dates$site[maize_oldest_idx], "\n")
cat("  14C age:", maize_dates$c14_age[maize_oldest_idx], "±", maize_dates$c14_error[maize_oldest_idx], "BP\n")
maize_oldest_sum <- summary(maize_cal, prob = 0.95)
maize_oldest_range <- maize_oldest_sum[maize_oldest_idx, ]
cat("  Median cal BP:", maize_oldest_range$MedianBP, "\n")
cat("  1-sigma range:", maize_oldest_range$OneSigma_BP, "cal BP\n")
cat("  2-sigma range:", maize_oldest_range$TwoSigma_BP, "cal BP\n\n")

# Create Summed Probability Distributions
cat("=== SUMMED PROBABILITY DISTRIBUTION (SPD) ANALYSIS ===\n\n")

bean_spd <- spd(bean_cal, timeRange = c(1500, 200))
maize_spd <- spd(maize_cal, timeRange = c(1500, 200))

# Find peaks in SPD
bean_peak_idx <- which.max(bean_spd$grid$PrDens)
maize_peak_idx <- which.max(maize_spd$grid$PrDens)

bean_peak <- bean_spd$grid$calBP[bean_peak_idx]
maize_peak <- maize_spd$grid$calBP[maize_peak_idx]

cat("Bean SPD peak (most activity):", bean_peak, "cal BP (", 1950 - bean_peak, "cal AD)\n")
cat("Maize SPD peak (most activity):", maize_peak, "cal BP (", 1950 - maize_peak, "cal AD)\n\n")

# Estimate earliest arrival using 95th percentile of oldest dates
# Sort dates and take top 10 oldest
bean_sorted <- bean_dates[order(bean_dates$c14_age, decreasing = TRUE), ]
maize_sorted <- maize_dates[order(maize_dates$c14_age, decreasing = TRUE), ]

n_boundary <- min(5, nrow(bean_sorted))  # Use top 5 oldest dates

cat("=== BOUNDARY ANALYSIS (Using", n_boundary, "oldest dates) ===\n\n")

# Calibrate the oldest dates for boundary estimation
bean_boundary_cal <- calibrate(
  x = bean_sorted$c14_age[1:n_boundary],
  errors = bean_sorted$c14_error[1:n_boundary],
  calCurves = 'intcal20'
)

maize_boundary_cal <- calibrate(
  x = maize_sorted$c14_age[1:n_boundary],
  errors = maize_sorted$c14_error[1:n_boundary],
  calCurves = 'intcal20'
)

# Get the summary stats
bean_boundary_summary <- summary(bean_boundary_cal, prob = 0.95)
cat("BEANS - Top", n_boundary, "oldest dates for boundary:\n")
for (i in 1:n_boundary) {
  cat("  ", bean_sorted$site[i], ":", bean_sorted$c14_age[i], "±", bean_sorted$c14_error[i],
      "BP -> Median:", bean_boundary_summary$MedianBP[i], "cal BP\n")
}

# Find the earliest possible date from the ranges
# Parse the TwoSigma_BP strings to get max
bean_ranges <- strsplit(bean_boundary_summary$TwoSigma_BP, ";")
bean_all_bounds <- unlist(lapply(bean_ranges, function(x) {
  lapply(strsplit(x, ":"), function(y) as.numeric(y))
}))
bean_earliest <- max(bean_all_bounds, na.rm = TRUE)
bean_latest <- min(bean_all_bounds, na.rm = TRUE)

cat("\nBean earliest arrival estimate:\n")
cat("  Earliest possible (95% CI):", bean_earliest, "cal BP (", 1950 - bean_earliest, "cal AD)\n")
cat("  Latest possible (95% CI):", bean_latest, "cal BP (", 1950 - bean_latest, "cal AD)\n\n")

maize_boundary_summary <- summary(maize_boundary_cal, prob = 0.95)
cat("MAIZE - Top", n_boundary, "oldest dates for boundary:\n")
for (i in 1:n_boundary) {
  cat("  ", maize_sorted$site[i], ":", maize_sorted$c14_age[i], "±", maize_sorted$c14_error[i],
      "BP -> Median:", maize_boundary_summary$MedianBP[i], "cal BP\n")
}

maize_ranges <- strsplit(maize_boundary_summary$TwoSigma_BP, ";")
maize_all_bounds <- unlist(lapply(maize_ranges, function(x) {
  lapply(strsplit(x, ":"), function(y) as.numeric(y))
}))
maize_earliest <- max(maize_all_bounds, na.rm = TRUE)
maize_latest <- min(maize_all_bounds, na.rm = TRUE)

cat("\nMaize earliest arrival estimate:\n")
cat("  Earliest possible (95% CI):", maize_earliest, "cal BP (", 1950 - maize_earliest, "cal AD)\n")
cat("  Latest possible (95% CI):", maize_latest, "cal BP (", 1950 - maize_latest, "cal AD)\n\n")

# Create plots
cat("=== CREATING VISUALIZATIONS ===\n")

pdf("arrival_analysis_results.pdf", width = 14, height = 10)
par(mfrow = c(2, 3))

# Plot 1: All bean calibrated dates
plot(bean_cal, HPD = TRUE, credMass = 0.95, main = "All Bean Dates (Calibrated, 95% CI)",
     xlab = "Cal BP", calendar = "BP")

# Plot 2: All maize calibrated dates
plot(maize_cal, HPD = TRUE, credMass = 0.95, main = "All Maize Dates (Calibrated, 95% CI)",
     xlab = "Cal BP", calendar = "BP")

# Plot 3: Bean SPD
plot(bean_spd, calendar = "BP", main = "Bean Summed Probability Distribution",
     xlab = "Cal BP", ylab = "Summed Probability", col = "blue", lwd = 2)
abline(v = bean_peak, col = "red", lty = 2)

# Plot 4: Maize SPD
plot(maize_spd, calendar = "BP", main = "Maize Summed Probability Distribution",
     xlab = "Cal BP", ylab = "Summed Probability", col = "darkgreen", lwd = 2)
abline(v = maize_peak, col = "red", lty = 2)

# Plot 5: Comparison of SPDs
plot(bean_spd, type = 'n', calendar = "BP",
     main = "Bean vs Maize Arrival Comparison",
     xlab = "Cal BP", ylab = "Summed Probability")
plot(bean_spd, col = "blue", add = TRUE, calendar = "BP", lwd = 2)
plot(maize_spd, col = "darkgreen", add = TRUE, calendar = "BP", lwd = 2)
legend("topright", legend = c("Bean", "Maize"), col = c("blue", "darkgreen"),
       lty = 1, lwd = 2, cex = 0.8)

# Plot 6: Oldest dates for boundary
plot(bean_boundary_cal, HPD = TRUE, main = paste("Oldest", n_boundary, "Bean Dates (Boundary)"),
     xlab = "Cal BP", calendar = "BP", col = "blue")
abline(v = bean_earliest, col = "red", lty = 2)
abline(v = bean_latest, col = "red", lty = 2)

dev.off()

cat("\nPlots saved to: arrival_analysis_results.pdf\n\n")

# Save summary results
results <- data.frame(
  Taxon = c("Bean", "Maize"),
  N_dates = c(nrow(bean_dates), nrow(maize_dates)),
  Oldest_14C = c(max(bean_dates$c14_age), max(maize_dates$c14_age)),
  Youngest_14C = c(min(bean_dates$c14_age), min(maize_dates$c14_age)),
  Earliest_arrival_calBP = c(bean_earliest, maize_earliest),
  Earliest_arrival_calAD = c(1950 - bean_earliest, 1950 - maize_earliest),
  Latest_arrival_calBP = c(bean_latest, maize_latest),
  Latest_arrival_calAD = c(1950 - bean_latest, 1950 - maize_latest),
  SPD_peak_calBP = c(bean_peak, maize_peak),
  SPD_peak_calAD = c(1950 - bean_peak, 1950 - maize_peak)
)

write.csv(results, "arrival_summary.csv", row.names = FALSE)
cat("Summary saved to: arrival_summary.csv\n")

cat("\n=== ANALYSIS COMPLETE ===\n\n")

cat("INTERPRETATION:\n")
cat("The earliest arrival dates represent the 95% upper bound of the oldest dates,\n")
cat("indicating when these crops first appeared in the archaeological record.\n")
cat("The SPD peaks show when these crops were most commonly used/deposited.\n")
