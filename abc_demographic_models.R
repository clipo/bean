# APPROXIMATE BAYESIAN COMPUTATION FOR SPD DEMOGRAPHIC MODELING
# Following DiNapoli et al. 2021 Nature Communications methodology
# Adapted for Northeastern Woodlands bean/maize/squash arrival analysis

library(tidyverse)
library(rcarbon)

# ==============================================================================
# ABC IMPLEMENTATION FOR LOGISTIC GROWTH MODELS
# ==============================================================================

#' Logistic growth demographic model
#' @param params List with N_t0 (initial pop), r (growth rate)
#' @param time_range Vector of calendar years BP
#' @return Vector of population sizes over time
logistic_growth_model <- function(params, time_range) {

  n_steps <- length(time_range)
  N <- numeric(n_steps)
  N[1] <- params$N_t0  # Initial population as proportion of K

  for (t in 2:n_steps) {
    # Logistic growth equation with K = 1
    N[t] <- N[t-1] * exp(params$r * (1 - N[t-1]))

    # Prevent numerical overflow
    if (N[t] > 1) N[t] <- 1
  }

  return(N)
}


#' Simulate radiocarbon dates from demographic model
#' @param N_t Vector of population sizes over time
#' @param time_range Vector of calendar years BP
#' @param n_dates Number of radiocarbon dates to simulate
#' @param observed_errors Vector of observed 14C errors to resample
#' @param cal_curve Calibration curve (default "intcal20")
#' @return Data frame with simulated C14 ages and errors
simulate_c14_from_model <- function(N_t, time_range, n_dates, observed_errors,
                                     cal_curve = "intcal20") {

  # Convert N_t to sampling probabilities
  p_t <- N_t / sum(N_t)

  # Sample calendar dates from demographic model
  sampled_cal_dates <- sample(time_range, size = n_dates, replace = TRUE, prob = p_t)

  # Assign random errors by resampling observed errors
  sampled_errors <- sample(observed_errors, size = n_dates, replace = TRUE)

  # Use rcarbon's uncalibrate function for back-calibration
  # This properly accounts for calibration curve structure
  c14_dates <- uncalibrate(x = sampled_cal_dates,
                          CRAerrors = sampled_errors,
                          calCurves = cal_curve,
                          roundyear = TRUE)

  # Create synthetic dataset
  # uncalibrate returns: calBP, ccCRA (center of calibration curve), ccError,
  #                      rCRA (randomized), rError
  # Use rCRA and rError for realistic radiocarbon measurements
  synthetic_data <- data.frame(
    CRA = c14_dates$rCRA,
    Error = c14_dates$rError
  )

  return(synthetic_data)
}


#' Simulate SPD from demographic model
#' @param N_t Vector of population sizes over time
#' @param time_range Vector of calendar years BP
#' @param n_dates Number of radiocarbon dates to simulate
#' @param observed_errors Vector of observed 14C errors
#' @param cal_curve Calibration curve
#' @param normalize Normalize calibrated dates (default FALSE)
#' @return SPD object
simulate_spd_from_model <- function(N_t, time_range, n_dates, observed_errors,
                                     cal_curve = "intcal20", normalize = FALSE) {

  # Simulate radiocarbon dates
  synthetic_data <- simulate_c14_from_model(N_t, time_range, n_dates,
                                            observed_errors, cal_curve)

  # Calibrate dates
  cal_dates <- calibrate(
    x = synthetic_data$CRA,
    errors = synthetic_data$Error,
    calCurves = cal_curve,
    normalised = normalize
  )

  # Create SPD
  # timeRange must be c(older, younger) = c(max, min)
  spd <- spd(cal_dates, timeRange = c(max(time_range), min(time_range)))

  return(spd)
}


#' Calculate Euclidean distance between two SPDs
#' @param spd1 First SPD object
#' @param spd2 Second SPD object
#' @return Euclidean distance
spd_distance <- function(spd1, spd2) {
  # Ensure same time range
  time_range <- intersect(spd1$grid$calBP, spd2$grid$calBP)

  dens1 <- spd1$grid$PrDens[spd1$grid$calBP %in% time_range]
  dens2 <- spd2$grid$PrDens[spd2$grid$calBP %in% time_range]

  # Euclidean distance
  dist <- sqrt(sum((dens1 - dens2)^2))

  return(dist)
}


#' ABC rejection algorithm for SPD demographic modeling
#' @param observed_spd Observed SPD
#' @param n_dates Number of dates in observed dataset
#' @param observed_errors Vector of observed 14C errors
#' @param time_range Vector of calendar years BP
#' @param prior_N_t0 Prior for initial population (c(min, max))
#' @param prior_r Prior for growth rate (c(min, max))
#' @param n_simulations Number of ABC simulations
#' @param n_accept Number of best-fitting models to accept
#' @param cal_curve Calibration curve
#' @param normalize Normalize dates
#' @return List with accepted parameters and distances
abc_spd_demographic <- function(observed_spd, n_dates, observed_errors,
                                 time_range,
                                 prior_N_t0 = c(0.001, 0.5),
                                 prior_r = c(0.001, 0.05),
                                 n_simulations = 10000,
                                 n_accept = 1000,
                                 cal_curve = "intcal20",
                                 normalize = FALSE) {

  cat("Running ABC demographic model fitting...\n")
  cat(sprintf("Simulations: %d, Accept: %d\n", n_simulations, n_accept))

  # Storage for parameters and distances
  params_list <- vector("list", n_simulations)
  distances <- numeric(n_simulations)

  # Progress tracking
  start_time <- Sys.time()

  # ABC rejection sampling
  for (i in 1:n_simulations) {

    if (i %% 1000 == 0) {
      elapsed <- difftime(Sys.time(), start_time, units = "secs")
      rate <- i / as.numeric(elapsed)
      remaining <- (n_simulations - i) / rate
      cat(sprintf("Simulation %d/%d (%.1f/sec, ~%.0f sec remaining)\n",
                  i, n_simulations, rate, remaining))
    }

    # Sample parameters from priors
    params <- list(
      N_t0 = runif(1, prior_N_t0[1], prior_N_t0[2]),
      r = runif(1, prior_r[1], prior_r[2])
    )

    # Generate population trajectory
    N_t <- logistic_growth_model(params, time_range)

    # Simulate SPD from model
    tryCatch({
      simulated_spd <- simulate_spd_from_model(
        N_t = N_t,
        time_range = time_range,
        n_dates = n_dates,
        observed_errors = observed_errors,
        cal_curve = cal_curve,
        normalize = normalize
      )

      # Calculate distance to observed SPD
      dist <- spd_distance(observed_spd, simulated_spd)

      params_list[[i]] <- params
      distances[i] <- dist

    }, error = function(e) {
      # If simulation fails, assign large distance and print error details
      if (i <= 5) {  # Print first 5 errors
        cat(sprintf("\nError in simulation %d: %s\n", i, e$message))
        if (i == 1) cat("Full error:\n", toString(e), "\n")
      }
      params_list[[i]] <- params
      distances[i] <- Inf
    })
  }

  # Select n_accept best-fitting models
  accept_idx <- order(distances)[1:n_accept]

  accepted_params <- params_list[accept_idx]
  accepted_distances <- distances[accept_idx]

  # Remove NULL entries
  non_null_idx <- !sapply(accepted_params, is.null)
  accepted_params <- accepted_params[non_null_idx]
  accepted_distances <- accepted_distances[non_null_idx]

  cat(sprintf("\nAccepted %d models with distances: %.6f - %.6f\n",
              length(accepted_params), min(accepted_distances), max(accepted_distances)))

  return(list(
    params = accepted_params,
    distances = accepted_distances,
    all_params = params_list,
    all_distances = distances
  ))
}


#' Extract posterior distributions from ABC results
#' @param abc_results Results from abc_spd_demographic
#' @return Data frame with parameter posteriors
extract_posteriors <- function(abc_results) {

  if (length(abc_results$params) == 0) {
    stop("No accepted parameters in ABC results")
  }

  # Extract parameters into vectors
  N_t0_vec <- sapply(abc_results$params, function(p) {
    if (is.null(p) || is.null(p$N_t0)) return(NA)
    return(p$N_t0)
  })

  r_vec <- sapply(abc_results$params, function(p) {
    if (is.null(p) || is.null(p$r)) return(NA)
    return(p$r)
  })

  # Remove NAs
  valid_idx <- !is.na(N_t0_vec) & !is.na(r_vec)
  N_t0_vec <- N_t0_vec[valid_idx]
  r_vec <- r_vec[valid_idx]
  distances_vec <- abc_results$distances[valid_idx]

  cat(sprintf("Extracted %d valid parameter sets\n", length(N_t0_vec)))

  # Create dataframe
  params_df <- data.frame(
    N_t0 = N_t0_vec,
    r = r_vec,
    distance = distances_vec
  )

  return(params_df)
}


#' Calculate 90% Highest Posterior Density interval
#' @param x Vector of parameter values
#' @return c(lower, upper) bounds
hpd_90 <- function(x) {
  x_sorted <- sort(x)
  n <- length(x)
  n_interval <- floor(0.9 * n)

  # Find narrowest interval containing 90% of data
  interval_widths <- x_sorted[(n - n_interval + 1):n] - x_sorted[1:n_interval]
  min_width_idx <- which.min(interval_widths)

  lower <- x_sorted[min_width_idx]
  upper <- x_sorted[min_width_idx + n_interval - 1]

  return(c(lower, upper))
}


#' Summarize ABC posterior distributions
#' @param posteriors Data frame from extract_posteriors
#' @return Data frame with summary statistics
summarize_posteriors <- function(posteriors) {

  summary_df <- data.frame(
    parameter = c("N_t0", "r"),
    median = c(
      median(posteriors$N_t0),
      median(posteriors$r)
    ),
    hpd_lower = c(
      hpd_90(posteriors$N_t0)[1],
      hpd_90(posteriors$r)[1]
    ),
    hpd_upper = c(
      hpd_90(posteriors$N_t0)[2],
      hpd_90(posteriors$r)[2]
    )
  )

  return(summary_df)
}


#' Estimate arrival date from demographic trajectory
#' @param N_t Population trajectory
#' @param time_range Vector of calendar years BP
#' @param threshold Population threshold for "arrival" (default 0.05)
#' @return Calendar year BP of arrival
estimate_arrival_date <- function(N_t, time_range, threshold = 0.05) {

  # Find first time population exceeds threshold
  arrival_idx <- min(which(N_t >= threshold))

  if (is.infinite(arrival_idx)) {
    return(NA)
  }

  arrival_date <- time_range[arrival_idx]
  return(arrival_date)
}


#' Get arrival date posterior from ABC results
#' @param abc_results ABC results
#' @param time_range Vector of calendar years BP
#' @param threshold Population threshold
#' @return Vector of arrival dates from posterior
get_arrival_posterior <- function(abc_results, time_range, threshold = 0.05) {

  arrival_samples <- sapply(abc_results$params, function(params) {
    N_t <- logistic_growth_model(params, time_range)
    arrival_date <- estimate_arrival_date(N_t, time_range, threshold)
    return(arrival_date)
  })

  return(arrival_samples)
}
