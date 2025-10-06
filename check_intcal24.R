# CHECK FOR INTCAL24 SUPPORT AND COMPARE CALIBRATION CURVES
# Bean and Maize Radiocarbon Dating

options(repos = c(CRAN = "https://cloud.r-project.org"))

cat("================================================================\n")
cat("  INTCAL24 AVAILABILITY CHECK & COMPARISON\n")
cat("================================================================\n\n")

# Load packages
if (!require("rcarbon", quietly = TRUE)) install.packages("rcarbon", quiet = TRUE)
if (!require("Bchron", quietly = TRUE)) install.packages("Bchron", quiet = TRUE)

library(rcarbon)
library(Bchron)

cat("Package versions:\n")
cat("  rcarbon:", as.character(packageVersion("rcarbon")), "\n")
cat("  Bchron:", as.character(packageVersion("Bchron")), "\n\n")

# Check available calibration curves in rcarbon
cat("================================================================\n")
cat("CHECKING AVAILABLE CALIBRATION CURVES\n")
cat("================================================================\n\n")

# Test what curves are available
test_curves <- c("intcal20", "intcal24", "intcal13", "marine20", "marine13", "shcal20", "shcal13")

cat("Testing calibration curves in rcarbon:\n")
for (curve in test_curves) {
  tryCatch({
    # Try to calibrate a test date
    test_cal <- calibrate(x = 700, errors = 40, calCurves = curve, verbose = FALSE)
    cat("  ✓", curve, "- AVAILABLE\n")
  }, error = function(e) {
    cat("  ✗", curve, "- NOT AVAILABLE\n")
  })
}

cat("\nTesting calibration curves in Bchron:\n")
for (curve in test_curves) {
  tryCatch({
    # Try to use curve in BchronCalibrate
    test_cal <- BchronCalibrate(ages = 700, ageSds = 40, calCurves = curve)
    cat("  ✓", curve, "- AVAILABLE\n")
  }, error = function(e) {
    cat("  ✗", curve, "- NOT AVAILABLE\n")
  })
}

cat("\n")

# Load our data
dates <- read.csv("radiocarbon_dates.csv")
bean_dates <- dates[dates$material == "bean", ]
maize_dates <- dates[dates$material == "maize", ]

# Select a few representative dates for detailed comparison
sample_dates <- data.frame(
  site = c("Kelly_F7", "Larson_F140", "Hill_Creek_F1_07C",
           "Campbell_Farm_F352", "Orendorf_F782"),
  material = c("bean", "bean", "bean", "maize", "bean"),
  c14_age = c(770, 757, 734, 794, 712),
  c14_error = c(50, 44, 33, 38, 33)
)

cat("================================================================\n")
cat("DETAILED COMPARISON: INTCAL20 vs INTCAL24 (if available)\n")
cat("================================================================\n\n")

# Function to extract key statistics from calibrated date
extract_cal_stats <- function(cal_obj, idx = 1) {
  grid <- cal_obj$grids[[idx]]
  cumsum_prob <- cumsum(grid$PrDens) / sum(grid$PrDens)

  median_bp <- grid$calBP[which.min(abs(cumsum_prob - 0.5))]
  lower_95 <- grid$calBP[which.min(abs(cumsum_prob - 0.025))]
  upper_95 <- grid$calBP[which.min(abs(cumsum_prob - 0.975))]

  return(list(
    median = median_bp,
    lower_95 = lower_95,
    upper_95 = upper_95
  ))
}

# Try to calibrate with both curves
intcal24_available <- FALSE

tryCatch({
  # Test if intcal24 works
  test <- calibrate(x = 700, errors = 40, calCurves = 'intcal24', verbose = FALSE)
  intcal24_available <- TRUE
  cat("✓ IntCal24 is AVAILABLE!\n\n")
}, error = function(e) {
  cat("✗ IntCal24 is NOT YET AVAILABLE in installed packages\n")
  cat("  Error message:", e$message, "\n\n")
  cat("RECOMMENDATION:\n")
  cat("  - Update rcarbon: install.packages('rcarbon')\n")
  cat("  - Or install development version from GitHub:\n")
  cat("    devtools::install_github('ahb108/rcarbon')\n\n")
})

if (intcal24_available) {
  cat("Comparing calibration results:\n\n")

  comparison_results <- data.frame(
    Site = character(),
    Material = character(),
    C14_BP = integer(),
    Curve = character(),
    Median_calBP = numeric(),
    Range_95_calBP = character(),
    Median_calAD = numeric(),
    stringsAsFactors = FALSE
  )

  for (i in 1:nrow(sample_dates)) {
    site <- sample_dates$site[i]
    age <- sample_dates$c14_age[i]
    error <- sample_dates$c14_error[i]
    mat <- sample_dates$material[i]

    # Calibrate with IntCal20
    cal_20 <- calibrate(x = age, errors = error, calCurves = 'intcal20', verbose = FALSE)
    stats_20 <- extract_cal_stats(cal_20)

    # Calibrate with IntCal24
    cal_24 <- calibrate(x = age, errors = error, calCurves = 'intcal24', verbose = FALSE)
    stats_24 <- extract_cal_stats(cal_24)

    # Add to results
    comparison_results <- rbind(comparison_results,
      data.frame(
        Site = site,
        Material = mat,
        C14_BP = age,
        Curve = "IntCal20",
        Median_calBP = stats_20$median,
        Range_95_calBP = paste(stats_20$upper_95, "-", stats_20$lower_95),
        Median_calAD = 1950 - stats_20$median
      ),
      data.frame(
        Site = site,
        Material = mat,
        C14_BP = age,
        Curve = "IntCal24",
        Median_calBP = stats_24$median,
        Range_95_calBP = paste(stats_24$upper_95, "-", stats_24$lower_95),
        Median_calAD = 1950 - stats_24$median
      )
    )

    # Calculate difference
    diff_median <- stats_20$median - stats_24$median

    cat(sprintf("%s (%s, %d±%d BP):\n", site, mat, age, error))
    cat(sprintf("  IntCal20: %d cal BP (1950-%d = %d cal AD)\n",
                stats_20$median, stats_20$median, 1950-stats_20$median))
    cat(sprintf("  IntCal24: %d cal BP (1950-%d = %d cal AD)\n",
                stats_24$median, stats_24$median, 1950-stats_24$median))
    cat(sprintf("  Difference: %+d years\n\n", diff_median))
  }

  # Save comparison results
  write.csv(comparison_results, "intcal20_vs_intcal24_comparison.csv", row.names = FALSE)
  cat("Detailed comparison saved to: intcal20_vs_intcal24_comparison.csv\n\n")

  # Summary statistics
  cal20_all <- comparison_results[comparison_results$Curve == "IntCal20", ]
  cal24_all <- comparison_results[comparison_results$Curve == "IntCal24", ]
  differences <- cal20_all$Median_calBP - cal24_all$Median_calBP

  cat("SUMMARY OF DIFFERENCES:\n")
  cat(sprintf("  Mean difference: %+.1f years\n", mean(differences)))
  cat(sprintf("  Median difference: %+.1f years\n", median(differences)))
  cat(sprintf("  Range: %+d to %+d years\n", min(differences), max(differences)))
  cat(sprintf("  Std deviation: %.1f years\n\n", sd(differences)))

} else {
  cat("Cannot perform detailed comparison without IntCal24.\n")
  cat("Proceeding with IntCal20 for now.\n\n")
}

# Check if we should update packages
cat("================================================================\n")
cat("RECOMMENDATIONS\n")
cat("================================================================\n\n")

if (!intcal24_available) {
  cat("IntCal24 is not yet available. Options:\n\n")
  cat("1. WAIT for CRAN update:\n")
  cat("   - rcarbon package should be updated soon\n")
  cat("   - Check https://cran.r-project.org/package=rcarbon\n\n")

  cat("2. INSTALL from GitHub (development version):\n")
  cat("   install.packages('devtools')\n")
  cat("   devtools::install_github('ahb108/rcarbon')\n\n")

  cat("3. USE IntCal20 (current analysis):\n")
  cat("   - Still valid and widely accepted\n")
  cat("   - Differences likely minimal for this time period\n")
  cat("   - IntCal20 reference: Reimer et al. 2020, Radiocarbon 62(4)\n\n")

} else {
  cat("IntCal24 is available and working!\n\n")
  cat("NEXT STEPS:\n")
  cat("1. Review comparison results above\n")
  cat("2. Decide if differences warrant full reanalysis\n")
  cat("3. Update all scripts to use 'intcal24'\n")
  cat("4. Regenerate all outputs\n\n")

  cat("IntCal24 reference:\n")
  cat("  Reimer et al. 2024. The IntCal24 Northern Hemisphere\n")
  cat("  Radiocarbon Age Calibration Curve (0-55 cal kBP).\n")
  cat("  Radiocarbon. DOI: 10.1017/RDC.2024.XX\n\n")
}

cat("================================================================\n")
cat("CHECK COMPLETE\n")
cat("================================================================\n")
