# ATTEMPT TO INSTALL INTCAL24 SUPPORT
# Try development versions of packages

options(repos = c(CRAN = "https://cloud.r-project.org"))

cat("================================================================\n")
cat("  INSTALLING INTCAL24 SUPPORT\n")
cat("================================================================\n\n")

# Install devtools if needed
if (!require("devtools", quietly = TRUE)) {
  cat("Installing devtools...\n")
  install.packages("devtools", quiet = TRUE)
}

library(devtools)

cat("\nAttempting to install development version of rcarbon from GitHub...\n")
tryCatch({
  devtools::install_github('ahb108/rcarbon', quiet = FALSE, upgrade = "never")
  cat("✓ rcarbon development version installed\n\n")
}, error = function(e) {
  cat("✗ Failed to install rcarbon from GitHub:\n")
  cat("  ", e$message, "\n\n")
})

# Test if IntCal24 is now available
library(rcarbon)

cat("Testing IntCal24 availability...\n")
intcal24_works <- FALSE

tryCatch({
  test <- calibrate(x = 700, errors = 40, calCurves = 'intcal24', verbose = FALSE)
  intcal24_works <- TRUE
  cat("✓ IntCal24 is NOW AVAILABLE!\n\n")
}, error = function(e) {
  cat("✗ IntCal24 still not available\n")
  cat("  Error:", e$message, "\n\n")
})

if (intcal24_works) {
  cat("SUCCESS! Proceeding with IntCal24 recalibration.\n")
} else {
  cat("IntCal24 not yet in development version either.\n")
  cat("\nLikely reasons:\n")
  cat("1. IntCal24 curve data not yet added to rcarbon package\n")
  cat("2. Package maintainers still updating for IntCal24\n\n")
  cat("RECOMMENDATION: Proceed with IntCal20\n")
  cat("- IntCal20 is still the standard for most publications\n")
  cat("- Differences for 600-800 BP dates are typically <5-10 years\n")
  cat("- Can update later when IntCal24 support is officially released\n")
}

cat("\n================================================================\n")
