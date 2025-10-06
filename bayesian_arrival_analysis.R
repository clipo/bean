# Bayesian Analysis of Maize and Bean Arrival Times
# Using radiocarbon dates from Hart et al. 2002

# Set CRAN mirror
options(repos = c(CRAN = "https://cloud.r-project.org"))

# Install required packages if needed
if (!require("Bchron")) install.packages("Bchron")
if (!require("rcarbon")) install.packages("rcarbon")
if (!require("tidyverse")) install.packages("tidyverse")

library(Bchron)
library(rcarbon)
library(tidyverse)

# Load the radiocarbon data
dates <- read.csv("radiocarbon_dates.csv")

# Separate by taxon
bean_dates <- dates %>% filter(material == "bean")
maize_dates <- dates %>% filter(material == "maize")

cat("Total bean dates:", nrow(bean_dates), "\n")
cat("Total maize dates:", nrow(maize_dates), "\n\n")

# Summary statistics
cat("Bean 14C ages: range =", min(bean_dates$c14_age), "-", max(bean_dates$c14_age), "BP\n")
cat("Maize 14C ages: range =", min(maize_dates$c14_age), "-", max(maize_dates$c14_age), "BP\n\n")

# ============================================================================
# APPROACH 1: Boundary Analysis using Bchron
# ============================================================================
cat("=== BOUNDARY ANALYSIS (Estimating earliest arrival) ===\n\n")

# For beans - use BchronDensity to get probability density
# Sort by age (oldest first)
bean_sorted <- bean_dates %>% arrange(desc(c14_age))
maize_sorted <- maize_dates %>% arrange(desc(c14_age))

# Estimate the boundary (earliest arrival) using the oldest dates
# We'll use a subset of the oldest dates to estimate the boundary
n_oldest <- 10  # Use 10 oldest dates for boundary estimation

# Beans boundary
cat("BEANS - Analyzing", n_oldest, "oldest dates for boundary estimation:\n")
bean_oldest <- bean_sorted[1:min(n_oldest, nrow(bean_sorted)), ]
print(bean_oldest[, c("site", "c14_age", "c14_error")])

bean_boundary <- BchronDensity(
  ages = bean_oldest$c14_age,
  ageSds = bean_oldest$c14_error,
  calCurves = rep('intcal20', nrow(bean_oldest))
)

# Maize boundary
cat("\nMAIZE - Analyzing", n_oldest, "oldest dates for boundary estimation:\n")
maize_oldest <- maize_sorted[1:min(n_oldest, nrow(maize_sorted)), ]
print(maize_oldest[, c("site", "c14_age", "c14_error")])

maize_boundary <- BchronDensity(
  ages = maize_oldest$c14_age,
  ageSds = maize_oldest$c14_error,
  calCurves = rep('intcal20', nrow(maize_oldest))
)

# ============================================================================
# APPROACH 2: Summed Probability Distribution (SPD) using rcarbon
# ============================================================================
cat("\n=== SUMMED PROBABILITY DISTRIBUTION ANALYSIS ===\n\n")

# Calibrate all dates
bean_cal <- calibrate(
  x = bean_dates$c14_age,
  errors = bean_dates$c14_error,
  calCurves = 'intcal20',
  ids = bean_dates$site
)

maize_cal <- calibrate(
  x = maize_dates$c14_age,
  errors = maize_dates$c14_error,
  calCurves = 'intcal20',
  ids = maize_dates$site
)

# Create SPDs
bean_spd <- spd(bean_cal, timeRange = c(1500, 500))
maize_spd <- spd(maize_cal, timeRange = c(1500, 500))

# ============================================================================
# CALCULATE EARLIEST ARRIVAL ESTIMATES
# ============================================================================
cat("\n=== EARLIEST ARRIVAL ESTIMATES ===\n\n")

# For beans - find the 95% interval from the boundary analysis
bean_hpd <- hdr(bean_boundary)
cat("BEANS earliest arrival (95% HPD):\n")
cat("  ", paste(bean_hpd, collapse = " to "), "cal BP\n")
cat("  ", paste(1950 - bean_hpd[1], "to", 1950 - bean_hpd[2]), "cal AD/BC\n\n")

# For maize
maize_hpd <- hdr(maize_boundary)
cat("MAIZE earliest arrival (95% HPD):\n")
cat("  ", paste(maize_hpd, collapse = " to "), "cal BP\n")
cat("  ", paste(1950 - maize_hpd[1], "to", 1950 - maize_hpd[2]), "cal AD/BC\n\n")

# Alternative: use the oldest single date's calibrated range
bean_oldest_single <- calibrate(
  x = max(bean_dates$c14_age),
  errors = bean_dates$c14_error[which.max(bean_dates$c14_age)],
  calCurves = 'intcal20'
)

maize_oldest_single <- calibrate(
  x = max(maize_dates$c14_age),
  errors = maize_dates$c14_error[which.max(maize_dates$c14_age)],
  calCurves = 'intcal20'
)

# ============================================================================
# VISUALIZATION
# ============================================================================
cat("\nGenerating plots...\n")

# Create a combined plot
pdf("arrival_analysis_results.pdf", width = 12, height = 10)

# Layout for multiple plots
par(mfrow = c(3, 2))

# Plot 1: Bean boundary density
plot(bean_boundary, main = "Bean Earliest Arrival (Boundary Estimate)",
     xlab = "Cal BP", ylab = "Probability Density")

# Plot 2: Maize boundary density
plot(maize_boundary, main = "Maize Earliest Arrival (Boundary Estimate)",
     xlab = "Cal BP", ylab = "Probability Density")

# Plot 3: Bean SPD
plot(bean_spd, calendar = "BP", main = "Bean Summed Probability Distribution",
     xlab = "Cal BP", ylab = "Summed Probability")

# Plot 4: Maize SPD
plot(maize_spd, calendar = "BP", main = "Maize Summed Probability Distribution",
     xlab = "Cal BP", ylab = "Summed Probability")

# Plot 5: Comparison of both SPDs
plot(bean_spd, type = 'n', calendar = "BP",
     main = "Comparison: Bean vs Maize Arrival",
     xlab = "Cal BP", ylab = "Summed Probability")
plot(bean_spd, col = "blue", add = TRUE, calendar = "BP")
plot(maize_spd, col = "red", add = TRUE, calendar = "BP")
legend("topright", legend = c("Bean", "Maize"), col = c("blue", "red"), lty = 1, lwd = 2)

# Plot 6: Calibrated ranges for oldest dates
plot(bean_oldest_single, main = "Oldest Bean Date (calibrated)",
     xlab = "Cal BP", ylab = "Probability")

dev.off()

cat("\nPlots saved to: arrival_analysis_results.pdf\n")

# ============================================================================
# SUMMARY STATISTICS
# ============================================================================
cat("\n=== SUMMARY STATISTICS ===\n\n")

# Get median dates from SPD
bean_spd_df <- data.frame(calBP = bean_spd$grid$calBP, PrDens = bean_spd$grid$PrDens)
maize_spd_df <- data.frame(calBP = maize_spd$grid$calBP, PrDens = maize_spd$grid$PrDens)

bean_median <- bean_spd_df$calBP[which.max(bean_spd_df$PrDens)]
maize_median <- maize_spd_df$calBP[which.max(maize_spd_df$PrDens)]

cat("Bean SPD peak (most likely period):", bean_median, "cal BP (", 1950 - bean_median, "AD/BC )\n")
cat("Maize SPD peak (most likely period):", maize_median, "cal BP (", 1950 - maize_median, "AD/BC )\n\n")

# Save results to file
results_summary <- data.frame(
  Taxon = c("Bean", "Maize"),
  N_dates = c(nrow(bean_dates), nrow(maize_dates)),
  Oldest_14C_BP = c(max(bean_dates$c14_age), max(maize_dates$c14_age)),
  Youngest_14C_BP = c(min(bean_dates$c14_age), min(maize_dates$c14_age)),
  Boundary_95HPD_from = c(bean_hpd[2], maize_hpd[2]),
  Boundary_95HPD_to = c(bean_hpd[1], maize_hpd[1]),
  SPD_peak_calBP = c(bean_median, maize_median)
)

write.csv(results_summary, "arrival_analysis_summary.csv", row.names = FALSE)
cat("Summary table saved to: arrival_analysis_summary.csv\n")

cat("\n=== ANALYSIS COMPLETE ===\n")
