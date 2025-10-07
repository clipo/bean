# CHRONOLOGICAL MODELING: ORDERED PHASE MODELS
# Testing alternative hypotheses about bean/maize arrival sequence

library(tidyverse)
library(Bchron)
library(rcarbon)

# ==============================================================================
# LOAD DATA
# ==============================================================================

all_data <- read_csv("radiocarbon_dates.csv", show_col_types = FALSE)

bean_data <- all_data %>% filter(material == "bean")
maize_data <- all_data %>% filter(material == "maize")

cat("Bean dates:", nrow(bean_data), "\n")
cat("Maize dates:", nrow(maize_data), "\n\n")

# ==============================================================================
# MODEL COMPARISON FRAMEWORK
# ==============================================================================

cat(strrep("=", 70), "\n")
cat("CHRONOLOGICAL MODELING: ALTERNATIVE ARRIVAL HYPOTHESES\n")
cat(strrep("=", 70), "\n\n")

cat("We will compare three hypotheses:\n\n")

cat("H1: BEANS ARRIVED FIRST (Sequential Model)\n")
cat("    Beans established → Gap → Maize introduced\n\n")

cat("H2: MAIZE ARRIVED FIRST (Sequential Model)\n")
cat("    Maize established → Gap → Beans introduced\n\n")

cat("H3: SIMULTANEOUS ARRIVAL (Overlapping Model)\n")
cat("    Beans and Maize arrived at approximately the same time\n\n")

# ==============================================================================
# HELPER FUNCTIONS
# ==============================================================================

#' Calculate overlap between two intervals
calculate_interval_overlap <- function(interval_a, interval_b) {

  # Intervals are [earlier, later] in BP (so larger to smaller)
  a_start <- interval_a[1]
  a_end <- interval_a[2]
  b_start <- interval_b[1]
  b_end <- interval_b[2]

  # Find overlap
  overlap_start <- max(a_start, b_start)
  overlap_end <- min(a_end, b_end)

  if (overlap_start > overlap_end) {
    # No overlap
    overlap_years <- 0
  } else {
    overlap_years <- overlap_start - overlap_end
  }

  # Calculate percentages
  a_range <- a_start - a_end
  b_range <- b_start - b_end

  pct_a <- if (a_range > 0) (overlap_years / a_range * 100) else 0
  pct_b <- if (b_range > 0) (overlap_years / b_range * 100) else 0

  return(list(
    overlap_years = overlap_years,
    pct_a = pct_a,
    pct_b = pct_b
  ))
}

# ==============================================================================
# MODEL 1: UNORDERED (BASELINE)
# ==============================================================================

cat(strrep("=", 70), "\n")
cat("BASELINE: UNORDERED MODEL\n")
cat("Estimate boundaries independently without constraints\n")
cat(strrep("=", 70), "\n\n")

#' Estimate phase boundary for a crop
estimate_boundary <- function(dates_df, material_name) {

  cat(sprintf("Analyzing %s (%d dates)...\n", material_name, nrow(dates_df)))

  result <- BchronDensity(
    ages = dates_df$c14_age,
    ageSds = dates_df$c14_error,
    calCurves = rep("intcal20", nrow(dates_df))
  )

  # Extract boundary estimates
  cumsum_dens <- cumsum(result$densities) / sum(result$densities)
  earliest_95 <- result$ageGrid[min(which(cumsum_dens >= 0.025))]
  earliest_68 <- result$ageGrid[min(which(cumsum_dens >= 0.16))]
  median <- result$ageGrid[min(which(cumsum_dens >= 0.5))]
  latest_68 <- result$ageGrid[max(which(cumsum_dens <= 0.84))]
  latest_95 <- result$ageGrid[max(which(cumsum_dens <= 0.975))]

  cat(sprintf("  Median arrival: %d BP (%.0f CE)\n", median, 1950 - median))
  cat(sprintf("  68%% HDR: %d - %d BP\n", earliest_68, latest_68))
  cat(sprintf("  95%% HDR: %d - %d BP\n\n", earliest_95, latest_95))

  return(list(
    material = material_name,
    densities = result$densities,
    calAges = result$calAges,
    median = median,
    hdr68 = c(earliest_68, latest_68),
    hdr95 = c(earliest_95, latest_95)
  ))
}

bean_baseline <- estimate_boundary(bean_data, "Bean")
maize_baseline <- estimate_boundary(maize_data, "Maize")

# Calculate overlap
overlap_68 <- calculate_interval_overlap(
  bean_baseline$hdr68,
  maize_baseline$hdr68
)

overlap_95 <- calculate_interval_overlap(
  bean_baseline$hdr95,
  maize_baseline$hdr95
)

cat("BASELINE OVERLAP:\n")
cat(sprintf("  68%% HDR overlap: %.1f%% of bean range, %.1f%% of maize range\n",
            overlap_68$pct_a, overlap_68$pct_b))
cat(sprintf("  95%% HDR overlap: %.1f%% of bean range, %.1f%% of maize range\n\n",
            overlap_95$pct_a, overlap_95$pct_b))

# ==============================================================================
# MODEL 2: ORDERED SEQUENTIAL MODELS
# ==============================================================================

cat(strrep("=", 70), "\n")
cat("ORDERED SEQUENTIAL MODELS\n")
cat("Testing hypotheses with enforced ordering\n")
cat(strrep("=", 70), "\n\n")

#' Create simulated sequence data with enforced ordering
#' This tests if data are compatible with a sequential model
test_sequential_model <- function(first_crop_data, second_crop_data,
                                   first_name, second_name,
                                   min_gap = 0) {

  cat(sprintf("\nTesting: %s before %s (minimum gap: %d years)\n",
              first_name, second_name, min_gap))

  # Combine data
  all_ages <- c(first_crop_data$c14_age, second_crop_data$c14_age)
  all_errors <- c(first_crop_data$c14_error, second_crop_data$c14_error)
  phases <- c(rep(1, nrow(first_crop_data)), rep(2, nrow(second_crop_data)))

  # Calibrate all dates
  cal_dates <- calibrate(
    x = all_ages,
    errors = all_errors,
    calCurves = "intcal20",
    normalised = FALSE
  )

  # Get median calibrated ages for each date
  median_ages <- sapply(cal_dates$grids, function(g) {
    cumsum_prob <- cumsum(g$PrDens)
    g$calBP[which.min(abs(cumsum_prob - 0.5))]
  })

  # Split by phase
  phase1_medians <- median_ages[phases == 1]
  phase2_medians <- median_ages[phases == 2]

  # Check compatibility with sequential model
  # For sequential: all phase 1 dates should be older than all phase 2 dates
  # (in BP, older = larger number)

  phase1_youngest <- min(phase1_medians)  # Smallest BP = youngest
  phase2_oldest <- max(phase2_medians)    # Largest BP = oldest

  gap <- phase1_youngest - phase2_oldest

  compatible <- gap >= min_gap

  cat(sprintf("  %s youngest median: %d BP (%.0f CE)\n",
              first_name, phase1_youngest, 1950 - phase1_youngest))
  cat(sprintf("  %s oldest median: %d BP (%.0f CE)\n",
              second_name, phase2_oldest, 1950 - phase2_oldest))
  cat(sprintf("  Gap between phases: %d years\n", gap))

  if (compatible) {
    cat(sprintf("  ✓ Data are compatible with %s → %s sequence\n", first_name, second_name))
  } else {
    cat(sprintf("  ✗ Data are NOT compatible with %s → %s sequence\n", first_name, second_name))
    cat(sprintf("    (Gap is %d years, required minimum is %d years)\n", gap, min_gap))
  }

  # Calculate overlap in calibrated ranges
  phase1_range <- range(phase1_medians)
  phase2_range <- range(phase2_medians)

  overlap <- calculate_interval_overlap(phase1_range, phase2_range)

  cat(sprintf("  Phase overlap: %.1f%% of %s range overlaps with %s\n",
              overlap$pct_a, first_name, second_name))

  # Statistical test: How many phase 1 dates are younger than phase 2 dates?
  violations <- sum(outer(phase1_medians, phase2_medians, "<"))
  total_comparisons <- length(phase1_medians) * length(phase2_medians)
  violation_pct <- violations / total_comparisons * 100

  cat(sprintf("  Ordering violations: %d out of %d comparisons (%.1f%%)\n",
              violations, total_comparisons, violation_pct))

  return(list(
    first = first_name,
    second = second_name,
    gap = gap,
    compatible = compatible,
    overlap_pct = overlap$pct_a,
    violations = violations,
    violation_pct = violation_pct,
    phase1_range = phase1_range,
    phase2_range = phase2_range
  ))
}

# Test H1: Beans before Maize
h1_result <- test_sequential_model(
  bean_data, maize_data,
  "Bean", "Maize",
  min_gap = 0
)

# Test H2: Maize before Beans
h2_result <- test_sequential_model(
  maize_data, bean_data,
  "Maize", "Bean",
  min_gap = 0
)

# ==============================================================================
# MODEL 3: BAYESIAN MODEL COMPARISON
# ==============================================================================

cat("\n", strrep("=", 70), "\n")
cat("BAYESIAN MODEL COMPARISON\n")
cat("Using overlap and violation statistics\n")
cat(strrep("=", 70), "\n\n")

#' Calculate model likelihood based on violations
#' Lower violations = better fit for sequential model
calculate_model_support <- function(sequential_result, baseline_overlap) {

  # For sequential model: penalize based on violation percentage
  # A perfect sequential model would have 0% violations

  # Model likelihood proportional to (1 - violation_rate)
  sequential_likelihood <- (100 - sequential_result$violation_pct) / 100

  # For simultaneous model: support is proportional to overlap
  # High overlap = strong support for simultaneous arrival
  simultaneous_likelihood <- baseline_overlap$pct_a / 100

  return(list(
    sequential = sequential_likelihood,
    simultaneous = simultaneous_likelihood,
    bayes_factor = sequential_likelihood / simultaneous_likelihood
  ))
}

# Compare H1 vs H3
h1_support <- calculate_model_support(h1_result, overlap_95)
cat("H1 (Beans before Maize) vs H3 (Simultaneous):\n")
cat(sprintf("  Sequential model support: %.3f\n", h1_support$sequential))
cat(sprintf("  Simultaneous model support: %.3f\n", h1_support$simultaneous))
cat(sprintf("  Bayes Factor (H1/H3): %.2f\n", h1_support$bayes_factor))

if (h1_support$bayes_factor > 3) {
  cat("  → Moderate support for sequential (beans first)\n")
} else if (h1_support$bayes_factor > 1) {
  cat("  → Weak support for sequential (beans first)\n")
} else {
  cat("  → Support for simultaneous arrival\n")
}

# Compare H2 vs H3
h2_support <- calculate_model_support(h2_result, overlap_95)
cat("\nH2 (Maize before Beans) vs H3 (Simultaneous):\n")
cat(sprintf("  Sequential model support: %.3f\n", h2_support$sequential))
cat(sprintf("  Simultaneous model support: %.3f\n", h2_support$simultaneous))
cat(sprintf("  Bayes Factor (H2/H3): %.2f\n", h2_support$bayes_factor))

if (h2_support$bayes_factor > 3) {
  cat("  → Moderate support for sequential (maize first)\n")
} else if (h2_support$bayes_factor > 1) {
  cat("  → Weak support for sequential (maize first)\n")
} else {
  cat("  → Support for simultaneous arrival\n")
}

# Compare H1 vs H2
cat("\nH1 (Beans first) vs H2 (Maize first):\n")
bf_h1_h2 <- h1_support$sequential / h2_support$sequential
cat(sprintf("  Bayes Factor (H1/H2): %.2f\n", bf_h1_h2))

if (abs(log(bf_h1_h2)) < log(3)) {
  cat("  → No clear preference between sequential models\n")
} else if (bf_h1_h2 > 1) {
  cat("  → Preference for beans arriving first\n")
} else {
  cat("  → Preference for maize arriving first\n")
}

# ==============================================================================
# MODEL 4: MINIMUM GAP SENSITIVITY
# ==============================================================================

cat("\n", strrep("=", 70), "\n")
cat("MINIMUM GAP SENSITIVITY ANALYSIS\n")
cat("Testing compatibility with different minimum gaps\n")
cat(strrep("=", 70), "\n\n")

#' Test range of minimum gaps
test_gap_sensitivity <- function(first_crop_data, second_crop_data,
                                  first_name, second_name,
                                  gaps = c(0, 25, 50, 100, 150, 200)) {

  results <- data.frame(
    gap = gaps,
    compatible = logical(length(gaps)),
    violation_pct = numeric(length(gaps))
  )

  for (i in seq_along(gaps)) {
    result <- test_sequential_model(
      first_crop_data, second_crop_data,
      first_name, second_name,
      min_gap = gaps[i]
    )
    results$compatible[i] <- result$compatible
    results$violation_pct[i] <- result$violation_pct
  }

  return(results)
}

cat("Testing Beans → Maize sequence with varying minimum gaps:\n\n")
bean_first_gaps <- test_gap_sensitivity(bean_data, maize_data, "Bean", "Maize")
print(bean_first_gaps)

cat("\n\nTesting Maize → Beans sequence with varying minimum gaps:\n\n")
maize_first_gaps <- test_gap_sensitivity(maize_data, bean_data, "Maize", "Bean")
print(maize_first_gaps)

# ==============================================================================
# SUMMARY AND INTERPRETATION
# ==============================================================================

cat("\n", strrep("=", 70), "\n")
cat("CHRONOLOGICAL MODELING SUMMARY\n")
cat(strrep("=", 70), "\n\n")

cat("KEY FINDINGS:\n\n")

cat("1. BASELINE (UNORDERED) MODEL:\n")
cat(sprintf("   Bean arrival: %d BP (%.0f CE), 95%% HDR: %d-%d BP\n",
            bean_baseline$median, 1950 - bean_baseline$median,
            bean_baseline$hdr95[1], bean_baseline$hdr95[2]))
cat(sprintf("   Maize arrival: %d BP (%.0f CE), 95%% HDR: %d-%d BP\n",
            maize_baseline$median, 1950 - maize_baseline$median,
            maize_baseline$hdr95[1], maize_baseline$hdr95[2]))
cat(sprintf("   95%% HDR overlap: %.1f%% of bean range\n", overlap_95$pct_a))

cat("\n2. SEQUENTIAL MODEL TESTS:\n")
cat(sprintf("   H1 (Beans first): %.1f%% ordering violations\n", h1_result$violation_pct))
cat(sprintf("   H2 (Maize first): %.1f%% ordering violations\n", h2_result$violation_pct))

cat("\n3. MODEL COMPARISON:\n")
cat(sprintf("   BF (Beans first / Simultaneous): %.2f\n", h1_support$bayes_factor))
cat(sprintf("   BF (Maize first / Simultaneous): %.2f\n", h2_support$bayes_factor))
cat(sprintf("   BF (Beans first / Maize first): %.2f\n", bf_h1_h2))

cat("\n4. INTERPRETATION:\n")

# Determine best-supported model
if (overlap_95$pct_a > 80) {
  cat("   ✓ STRONG support for SIMULTANEOUS arrival (H3)\n")
  cat("     Beans and maize arrived at approximately the same time\n")
  cat("     95% HDRs overlap by >80%, indicating indistinguishable arrival times\n")

} else if (h1_support$bayes_factor > 3 || h2_support$bayes_factor > 3) {
  if (h1_support$bayes_factor > h2_support$bayes_factor) {
    cat("   → MODERATE support for BEANS ARRIVING FIRST (H1)\n")
    cat(sprintf("     But with %.1f%% violations of strict ordering\n", h1_result$violation_pct))
  } else {
    cat("   → MODERATE support for MAIZE ARRIVING FIRST (H2)\n")
    cat(sprintf("     But with %.1f%% violations of strict ordering\n", h2_result$violation_pct))
  }

} else {
  cat("   ~ INCONCLUSIVE: Cannot clearly distinguish between models\n")
  cat("     Data are compatible with multiple hypotheses\n")
  cat("     Larger sample sizes may be needed to resolve arrival sequence\n")
}

cat("\n5. MINIMUM DETECTABLE GAP:\n")

# Find maximum gap still compatible with data
max_compatible_gap_h1 <- max(bean_first_gaps$gap[bean_first_gaps$compatible])
max_compatible_gap_h2 <- max(maize_first_gaps$gap[maize_first_gaps$compatible])

if (max_compatible_gap_h1 >= 0) {
  cat(sprintf("   Beans → Maize: Compatible with gaps up to %d years\n",
              max_compatible_gap_h1))
} else {
  cat("   Beans → Maize: Not compatible with any gap\n")
}

if (max_compatible_gap_h2 >= 0) {
  cat(sprintf("   Maize → Beans: Compatible with gaps up to %d years\n",
              max_compatible_gap_h2))
} else {
  cat("   Maize → Beans: Not compatible with any gap\n")
}

# ==============================================================================
# SAVE RESULTS
# ==============================================================================

chronological_results <- list(
  baseline = list(bean = bean_baseline, maize = maize_baseline),
  overlap = list(hdr68 = overlap_68, hdr95 = overlap_95),
  h1_beans_first = h1_result,
  h2_maize_first = h2_result,
  model_support = list(h1 = h1_support, h2 = h2_support),
  gap_sensitivity = list(
    beans_first = bean_first_gaps,
    maize_first = maize_first_gaps
  )
)

saveRDS(chronological_results, "chronological_models_results.rds")
cat("\n\nResults saved to: chronological_models_results.rds\n")
