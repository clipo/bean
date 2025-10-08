# Bayesian Analysis of Maize and Bean Arrival Times
# Final simplified version

# Set CRAN mirror
options(repos = c(CRAN = "https://cloud.r-project.org"))

# Install and load rcarbon
if (!require("rcarbon", quietly = TRUE)) {
  install.packages("rcarbon", quiet = TRUE)
}
library(rcarbon, quietly = TRUE)

# Load data
dates <- read.csv("radiocarbon_dates.csv")
bean_dates <- dates[dates$material == "bean", ]
maize_dates <- dates[dates$material == "maize", ]

cat("============================================================\n")
cat("   BAYESIAN RADIOCARBON ANALYSIS: BEAN & MAIZE ARRIVAL\n")
cat("============================================================\n\n")

cat("DATA SUMMARY:\n")
cat("  Bean dates: n =", nrow(bean_dates), "\n")
cat("  Maize dates: n =", nrow(maize_dates), "\n")
cat("  Bean 14C range:", min(bean_dates$c14_age), "-", max(bean_dates$c14_age), "BP\n")
cat("  Maize 14C range:", min(maize_dates$c14_age), "-", max(maize_dates$c14_age), "BP\n\n")

# Calibrate all dates
cat("Calibrating radiocarbon dates...\n")
bean_cal <- calibrate(bean_dates$c14_age, bean_dates$c14_error,
                      calCurves = 'intcal20', ids = bean_dates$site)
maize_cal <- calibrate(maize_dates$c14_age, maize_dates$c14_error,
                       calCurves = 'intcal20', ids = maize_dates$site)

# Create SPDs
cat("Creating summed probability distributions...\n\n")
bean_spd <- spd(bean_cal, timeRange = c(1500, 200))
maize_spd <- spd(maize_cal, timeRange = c(1500, 200))

# Find SPD peaks
bean_peak <- bean_spd$grid$calBP[which.max(bean_spd$grid$PrDens)]
maize_peak <- maize_spd$grid$calBP[which.max(maize_spd$grid$PrDens)]

cat("============================================================\n")
cat("SUMMED PROBABILITY DISTRIBUTION (SPD) ANALYSIS\n")
cat("============================================================\n")
cat("Bean SPD peak:\n")
cat("  ", bean_peak, "cal BP (", 1950 - bean_peak, "cal AD)\n")
cat("Maize SPD peak:\n")
cat("  ", maize_peak, "cal BP (", 1950 - maize_peak, "cal AD)\n\n")

# Analyze oldest dates for arrival estimates
cat("============================================================\n")
cat("EARLIEST ARRIVAL ANALYSIS (Oldest 5 dates)\n")
cat("============================================================\n\n")

# Sort and get oldest dates
bean_sorted <- bean_dates[order(bean_dates$c14_age, decreasing = TRUE), ]
maize_sorted <- maize_dates[order(maize_dates$c14_age, decreasing = TRUE), ]

# Calibrate oldest dates
n_oldest <- 5
bean_oldest_cal <- calibrate(
  bean_sorted$c14_age[1:n_oldest],
  bean_sorted$c14_error[1:n_oldest],
  calCurves = 'intcal20'
)
maize_oldest_cal <- calibrate(
  maize_sorted$c14_age[1:n_oldest],
  maize_sorted$c14_error[1:n_oldest],
  calCurves = 'intcal20'
)

# Extract medians and HPD ranges
cat("BEANS - Oldest 5 dates:\n")
bean_medians <- numeric(n_oldest)
bean_lower <- numeric(n_oldest)
bean_upper <- numeric(n_oldest)

for (i in 1:n_oldest) {
  # Get the calibrated distribution
  cal_curve <- bean_oldest_cal$grids[[i]]
  # Calculate median
  cumsum_prob <- cumsum(cal_curve$PrDens) / sum(cal_curve$PrDens)
  median_bp <- cal_curve$calBP[which.min(abs(cumsum_prob - 0.5))]
  # Calculate 95% HPD (highest posterior density)
  lower_bp <- cal_curve$calBP[which.min(abs(cumsum_prob - 0.975))]
  upper_bp <- cal_curve$calBP[which.min(abs(cumsum_prob - 0.025))]

  bean_medians[i] <- median_bp
  bean_lower[i] <- lower_bp
  bean_upper[i] <- upper_bp

  cat(sprintf("  %d. %s: %d±%d BP → %d cal BP (95%% range: %d-%d cal BP)\n",
              i, bean_sorted$site[i], bean_sorted$c14_age[i], bean_sorted$c14_error[i],
              median_bp, lower_bp, upper_bp))
}

# Bean boundary estimate (earliest possible arrival)
bean_earliest <- max(bean_upper)
bean_latest <- min(bean_lower)

cat("\nBEAN EARLIEST ARRIVAL ESTIMATE:\n")
cat(sprintf("  Boundary range: %d - %d cal BP\n", bean_latest, bean_earliest))
cat(sprintf("  Boundary range: %d - %d cal AD\n", 1950 - bean_earliest, 1950 - bean_latest))
cat(sprintf("  Best estimate (median of oldest): %d cal BP (%d cal AD)\n\n",
            bean_medians[1], 1950 - bean_medians[1]))

cat("MAIZE - Oldest 5 dates:\n")
maize_medians <- numeric(n_oldest)
maize_lower <- numeric(n_oldest)
maize_upper <- numeric(n_oldest)

for (i in 1:n_oldest) {
  cal_curve <- maize_oldest_cal$grids[[i]]
  cumsum_prob <- cumsum(cal_curve$PrDens) / sum(cal_curve$PrDens)
  median_bp <- cal_curve$calBP[which.min(abs(cumsum_prob - 0.5))]
  lower_bp <- cal_curve$calBP[which.min(abs(cumsum_prob - 0.975))]
  upper_bp <- cal_curve$calBP[which.min(abs(cumsum_prob - 0.025))]

  maize_medians[i] <- median_bp
  maize_lower[i] <- lower_bp
  maize_upper[i] <- upper_bp

  cat(sprintf("  %d. %s: %d±%d BP → %d cal BP (95%% range: %d-%d cal BP)\n",
              i, maize_sorted$site[i], maize_sorted$c14_age[i], maize_sorted$c14_error[i],
              median_bp, lower_bp, upper_bp))
}

maize_earliest <- max(maize_upper)
maize_latest <- min(maize_lower)

cat("\nMAIZE EARLIEST ARRIVAL ESTIMATE:\n")
cat(sprintf("  Boundary range: %d - %d cal BP\n", maize_latest, maize_earliest))
cat(sprintf("  Boundary range: %d - %d cal AD\n", 1950 - maize_earliest, 1950 - maize_latest))
cat(sprintf("  Best estimate (median of oldest): %d cal BP (%d cal AD)\n\n",
            maize_medians[1], 1950 - maize_medians[1]))

# Comparison
cat("============================================================\n")
cat("COMPARISON: BEANS vs MAIZE\n")
cat("============================================================\n")
if (bean_medians[1] > maize_medians[1]) {
  cat(sprintf("Beans appear EARLIER by ~%d years\n", bean_medians[1] - maize_medians[1]))
} else {
  cat(sprintf("Maize appears EARLIER by ~%d years\n", maize_medians[1] - bean_medians[1]))
}
cat("\n")

# Create visualizations
cat("Creating plots...\n")
tryCatch({
pdf("arrival_analysis_results.pdf", width = 16, height = 10)
layout(matrix(c(1,1,2,2,3,3,4,5,6,7,8,9), nrow = 2, byrow = TRUE))

# Plot SPDs comparison - manual plotting with safe ylim
bean_years <- 1950 - bean_spd$grid$calBP
maize_years <- 1950 - maize_spd$grid$calBP

# Remove any NA or infinite values and calculate safe ylim
bean_prdens_clean <- bean_spd$grid$PrDens[is.finite(bean_spd$grid$PrDens)]
maize_prdens_clean <- maize_spd$grid$PrDens[is.finite(maize_spd$grid$PrDens)]
max_prdens <- max(c(bean_prdens_clean, maize_prdens_clean), na.rm = TRUE)

plot(bean_years, bean_spd$grid$PrDens, type = "l",
     main = "Bean vs Maize SPD Comparison", cex.main = 1.5,
     xlab = "Calendar Year", ylab = "Summed Probability",
     col = "blue", lwd = 2, ylim = c(0, max_prdens * 1.1))
lines(maize_years, maize_spd$grid$PrDens, col = "darkgreen", lwd = 2)
abline(v = 1950 - bean_peak, col = "blue", lty = 2, lwd = 1)
abline(v = 1950 - maize_peak, col = "darkgreen", lty = 2, lwd = 1)
legend("topleft", legend = c("Bean", "Maize"), col = c("blue", "darkgreen"),
       lty = 1, lwd = 2, cex = 1.2)

# Plot bean SPD alone
plot(bean_years, bean_spd$grid$PrDens, type = "l",
     main = "Bean Summed Probability", cex.main = 1.3,
     xlab = "Calendar Year", ylab = "Summed Probability",
     col = "blue", lwd = 2, ylim = c(0, max(bean_prdens_clean, na.rm = TRUE) * 1.1))
abline(v = 1950 - bean_peak, col = "red", lty = 2)

# Plot maize SPD alone
plot(maize_years, maize_spd$grid$PrDens, type = "l",
     main = "Maize Summed Probability", cex.main = 1.3,
     xlab = "Calendar Year", ylab = "Summed Probability",
     col = "darkgreen", lwd = 2, ylim = c(0, max(maize_prdens_clean, na.rm = TRUE) * 1.1))
abline(v = 1950 - maize_peak, col = "red", lty = 2)

# Plot oldest bean dates
plot(bean_oldest_cal[[1]], HPD = TRUE, calendar = "BCAD",
     main = paste("Oldest Bean:", bean_sorted$site[1]), cex.main = 1)
for (i in 2:3) {
  plot(bean_oldest_cal[[i]], HPD = TRUE, calendar = "BCAD",
       main = paste("Bean:", bean_sorted$site[i]), cex.main = 1)
}

# Plot oldest maize dates
for (i in 1:3) {
  plot(maize_oldest_cal[[i]], HPD = TRUE, calendar = "BCAD",
       main = paste("Maize:", maize_sorted$site[i]), cex.main = 1)
}

dev.off()
cat("Plots saved to: arrival_analysis_results.pdf\n\n")
}, error = function(e) {
  cat("Warning: Plot generation encountered an error:\n")
  cat(conditionMessage(e), "\n")
  cat("Continuing with analysis...\n\n")
  if (dev.cur() > 1) dev.off()
})

# Save results
results <- data.frame(
  Taxon = c("Bean", "Maize"),
  N_dates = c(nrow(bean_dates), nrow(maize_dates)),
  Oldest_14C_BP = c(max(bean_dates$c14_age), max(maize_dates$c14_age)),
  Earliest_arrival_calBP = c(bean_medians[1], maize_medians[1]),
  Earliest_arrival_calAD = c(1950 - bean_medians[1], 1950 - maize_medians[1]),
  Boundary_lower_calBP = c(bean_latest, maize_latest),
  Boundary_upper_calBP = c(bean_earliest, maize_earliest),
  Boundary_lower_calAD = c(1950 - bean_earliest, 1950 - maize_earliest),
  Boundary_upper_calAD = c(1950 - bean_latest, 1950 - maize_latest),
  SPD_peak_calBP = c(bean_peak, maize_peak),
  SPD_peak_calAD = c(1950 - bean_peak, 1950 - maize_peak)
)

write.csv(results, "arrival_summary.csv", row.names = FALSE)
cat("Summary saved to: arrival_summary.csv\n\n")

cat("============================================================\n")
cat("ANALYSIS COMPLETE\n")
cat("============================================================\n")
