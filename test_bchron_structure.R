# Quick test to understand BchronDensity output structure
library(Bchron)

# Generate simple test data
test_ages <- c(700, 720, 710, 705, 715)
test_errors <- c(40, 40, 40, 40, 40)

# Run BchronDensity
result <- {
  invisible(capture.output({
    out <- BchronDensity(ages = test_ages, ageSds = test_errors, calCurves = rep('intcal20', 5))
  }))
  out
}

# Examine structure
cat("Class:", class(result), "\n")
cat("Names:", names(result), "\n")
cat("Structure:\n")
str(result)
