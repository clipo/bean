# RICH VISUALIZATIONS FOR BAYESIAN RADIOCARBON ANALYSIS
# Bean and Maize Arrival in Eastern Woodlands

options(repos = c(CRAN = "https://cloud.r-project.org"))

# Load required packages
if (!require("Bchron", quietly = TRUE)) install.packages("Bchron", quiet = TRUE)
if (!require("rcarbon", quietly = TRUE)) install.packages("rcarbon", quiet = TRUE)
if (!require("ggplot2", quietly = TRUE)) install.packages("ggplot2", quiet = TRUE)
if (!require("viridis", quietly = TRUE)) install.packages("viridis", quiet = TRUE)
if (!require("gridExtra", quietly = TRUE)) install.packages("gridExtra", quiet = TRUE)

library(Bchron)
library(rcarbon)
library(ggplot2)
library(viridis)
library(gridExtra)

# Custom theme for publication-quality plots
theme_publication <- function(base_size = 12) {
  theme_bw(base_size = base_size) +
    theme(
      panel.grid.major = element_line(color = "grey90", size = 0.3),
      panel.grid.minor = element_blank(),
      plot.title = element_text(size = base_size + 2, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = base_size, hjust = 0.5),
      axis.title = element_text(size = base_size, face = "bold"),
      axis.text = element_text(size = base_size - 1),
      legend.title = element_text(size = base_size, face = "bold"),
      legend.text = element_text(size = base_size - 1),
      legend.position = "bottom",
      strip.background = element_rect(fill = "grey95", color = "grey80"),
      strip.text = element_text(face = "bold")
    )
}

cat("Loading and preparing data...\n")

# Load data
dates <- read.csv("radiocarbon_dates.csv")
bean_dates <- dates[dates$material == "bean", ]
maize_dates <- dates[dates$material == "maize", ]

# Calibrate all dates
cat("Calibrating dates...\n")
bean_cal <- calibrate(bean_dates$c14_age, bean_dates$c14_error,
                      calCurves = 'intcal20', ids = bean_dates$site)
maize_cal <- calibrate(maize_dates$c14_age, maize_dates$c14_error,
                       calCurves = 'intcal20', ids = maize_dates$site)

# Create SPDs
bean_spd <- spd(bean_cal, timeRange = c(1500, 200))
maize_spd <- spd(maize_cal, timeRange = c(1500, 200))

# Prepare boundary models (8 oldest dates)
bean_sorted <- bean_dates[order(bean_dates$c14_age, decreasing = TRUE), ]
maize_sorted <- maize_dates[order(maize_dates$c14_age, decreasing = TRUE), ]

n_boundary <- 8
bean_boundary_subset <- bean_sorted[1:n_boundary, ]
maize_boundary_subset <- maize_sorted[1:n_boundary, ]

cat("Estimating boundary densities...\n")
bean_boundary_model <- BchronDensity(
  ages = bean_boundary_subset$c14_age,
  ageSds = bean_boundary_subset$c14_error,
  calCurves = rep('intcal20', n_boundary)
)

maize_boundary_model <- BchronDensity(
  ages = maize_boundary_subset$c14_age,
  ageSds = maize_boundary_subset$c14_error,
  calCurves = rep('intcal20', n_boundary)
)

# ============================================================================
# VISUALIZATION 1: Multi-panel Overview
# ============================================================================
cat("Creating multi-panel overview...\n")

pdf("Figure1_Overview.pdf", width = 16, height = 12)

layout(matrix(c(1,1,2,2,
                3,3,4,4,
                5,5,6,6), nrow = 3, byrow = TRUE))

par(mar = c(4, 4, 3, 1))

# Panel A: Bean calibrated dates (oldest 12)
oldest_bean_indices <- order(bean_dates$c14_age, decreasing = TRUE)[1:12]
colors_bean <- viridis(12)
plot(1, type = "n", xlim = c(1000, 1500), ylim = c(0, 13),
     xlab = "Calendar Year (AD)", ylab = "",
     main = "A. Calibrated Bean Dates (12 oldest)",
     yaxt = "n", cex.main = 1.4, cex.lab = 1.2)

for (i in 1:12) {
  idx <- oldest_bean_indices[i]
  if (!is.null(bean_cal$grids[[idx]])) {
    cal_curve <- bean_cal$grids[[idx]]
    if (!is.null(cal_curve$calBP) && !is.null(cal_curve$PrDens)) {
      cal_years <- 1950 - cal_curve$calBP
      density <- cal_curve$PrDens / max(cal_curve$PrDens) * 0.8

      polygon(c(cal_years, rev(cal_years)),
              c(i - density, rep(i, length(density))),
              col = colors_bean[i], border = NA)

      # Add site label
      text(1050, i, bean_dates$site[idx], adj = 0, cex = 0.7)
    }
  }
}
abline(v = c(1150, 1200, 1250, 1300, 1350, 1400), col = "grey80", lty = 2)

# Panel B: Maize calibrated dates (all 14)
colors_maize <- viridis(14, option = "magma")
plot(1, type = "n", xlim = c(1000, 1500), ylim = c(0, 15),
     xlab = "Calendar Year (AD)", ylab = "",
     main = "B. Calibrated Maize Dates (all dates)",
     yaxt = "n", cex.main = 1.4, cex.lab = 1.2)

maize_sorted_all <- order(maize_dates$c14_age, decreasing = TRUE)
for (i in 1:14) {
  idx <- maize_sorted_all[i]
  if (!is.null(maize_cal$grids[[idx]])) {
    cal_curve <- maize_cal$grids[[idx]]
    if (!is.null(cal_curve$calBP) && !is.null(cal_curve$PrDens)) {
      cal_years <- 1950 - cal_curve$calBP
      density <- cal_curve$PrDens / max(cal_curve$PrDens) * 0.8

      polygon(c(cal_years, rev(cal_years)),
              c(i - density, rep(i, length(density))),
              col = colors_maize[i], border = NA)

      text(1050, i, maize_dates$site[idx], adj = 0, cex = 0.7)
    }
  }
}
abline(v = c(1150, 1200, 1250, 1300, 1350, 1400), col = "grey80", lty = 2)

# Panel C: Bean SPD
bean_years <- 1950 - bean_spd$grid$calBP
plot(bean_years, bean_spd$grid$PrDens, type = "l", lwd = 3, col = "#1f77b4",
     main = "C. Bean Summed Probability Distribution",
     xlab = "Calendar Year (AD)", ylab = "Summed Probability",
     cex.main = 1.4, cex.lab = 1.2)
polygon(c(bean_years, rev(bean_years)),
        c(bean_spd$grid$PrDens, rep(0, length(bean_years))),
        col = rgb(31/255, 119/255, 180/255, 0.3), border = NA)
abline(v = 1950 - bean_spd$grid$calBP[which.max(bean_spd$grid$PrDens)],
       col = "red", lty = 2, lwd = 2)

# Panel D: Maize SPD
maize_years <- 1950 - maize_spd$grid$calBP
plot(maize_years, maize_spd$grid$PrDens, type = "l", lwd = 3, col = "#ff7f0e",
     main = "D. Maize Summed Probability Distribution",
     xlab = "Calendar Year (AD)", ylab = "Summed Probability",
     cex.main = 1.4, cex.lab = 1.2)
polygon(c(maize_years, rev(maize_years)),
        c(maize_spd$grid$PrDens, rep(0, length(maize_years))),
        col = rgb(255/255, 127/255, 14/255, 0.3), border = NA)
abline(v = 1950 - maize_spd$grid$calBP[which.max(maize_spd$grid$PrDens)],
       col = "red", lty = 2, lwd = 2)

# Panel E: Bean Boundary Density
bean_boundary_years <- 1950 - bean_boundary_model$denCalAges
plot(bean_boundary_years, bean_boundary_model$Density, type = "l", lwd = 3,
     col = "#1f77b4",
     main = "E. Bean Boundary (Earliest Arrival)",
     xlab = "Calendar Year (AD)", ylab = "Probability Density",
     cex.main = 1.4, cex.lab = 1.2)
polygon(c(bean_boundary_years, rev(bean_boundary_years)),
        c(bean_boundary_model$Density, rep(0, length(bean_boundary_years))),
        col = rgb(31/255, 119/255, 180/255, 0.5), border = NA)
# Add HDR
bean_hdr <- hdr(bean_boundary_model, prob = 0.95)
if (is.list(bean_hdr)) {
  all_vals <- unlist(bean_hdr)
  abline(v = 1950 - max(all_vals), col = "red", lty = 2, lwd = 2)
  abline(v = 1950 - min(all_vals), col = "red", lty = 2, lwd = 2)
}

# Panel F: Maize Boundary Density
maize_boundary_years <- 1950 - maize_boundary_model$denCalAges
plot(maize_boundary_years, maize_boundary_model$Density, type = "l", lwd = 3,
     col = "#ff7f0e",
     main = "F. Maize Boundary (Earliest Arrival)",
     xlab = "Calendar Year (AD)", ylab = "Probability Density",
     cex.main = 1.4, cex.lab = 1.2)
polygon(c(maize_boundary_years, rev(maize_boundary_years)),
        c(maize_boundary_model$Density, rep(0, length(maize_boundary_years))),
        col = rgb(255/255, 127/255, 14/255, 0.5), border = NA)
maize_hdr <- hdr(maize_boundary_model, prob = 0.95)
if (is.list(maize_hdr)) {
  all_vals <- unlist(maize_hdr)
  abline(v = 1950 - max(all_vals), col = "red", lty = 2, lwd = 2)
  abline(v = 1950 - min(all_vals), col = "red", lty = 2, lwd = 2)
}

dev.off()

# ============================================================================
# VISUALIZATION 2: Direct Comparison Plot
# ============================================================================
cat("Creating direct comparison plot...\n")

pdf("Figure2_Comparison.pdf", width = 14, height = 10)

par(mfrow = c(2, 2), mar = c(4, 4, 3, 2))

# Plot 1: Overlaid SPDs
plot(bean_years, bean_spd$grid$PrDens, type = "n",
     main = "A. SPD Comparison: Bean vs Maize",
     xlab = "Calendar Year (AD)", ylab = "Summed Probability",
     ylim = c(0, max(c(bean_spd$grid$PrDens, maize_spd$grid$PrDens)) * 1.1),
     cex.main = 1.3, cex.lab = 1.1)

# Bean
polygon(c(bean_years, rev(bean_years)),
        c(bean_spd$grid$PrDens, rep(0, length(bean_years))),
        col = rgb(31/255, 119/255, 180/255, 0.4), border = NA)
lines(bean_years, bean_spd$grid$PrDens, col = "#1f77b4", lwd = 3)

# Maize
polygon(c(maize_years, rev(maize_years)),
        c(maize_spd$grid$PrDens, rep(0, length(maize_years))),
        col = rgb(255/255, 127/255, 14/255, 0.4), border = NA)
lines(maize_years, maize_spd$grid$PrDens, col = "#ff7f0e", lwd = 3)

legend("topright", legend = c("Bean (n=36)", "Maize (n=14)"),
       col = c("#1f77b4", "#ff7f0e"), lwd = 3, bty = "n", cex = 1.1)
abline(v = c(1150, 1200, 1250, 1300, 1350, 1400), col = "grey70", lty = 3)

# Plot 2: Overlaid Boundary Densities
plot(bean_boundary_years, bean_boundary_model$Density, type = "n",
     main = "B. Boundary Comparison: Earliest Arrival",
     xlab = "Calendar Year (AD)", ylab = "Probability Density",
     ylim = c(0, max(c(bean_boundary_model$Density, maize_boundary_model$Density)) * 1.1),
     cex.main = 1.3, cex.lab = 1.1)

# Bean boundary
polygon(c(bean_boundary_years, rev(bean_boundary_years)),
        c(bean_boundary_model$Density, rep(0, length(bean_boundary_years))),
        col = rgb(31/255, 119/255, 180/255, 0.5), border = NA)
lines(bean_boundary_years, bean_boundary_model$Density, col = "#1f77b4", lwd = 3)

# Maize boundary
polygon(c(maize_boundary_years, rev(maize_boundary_years)),
        c(maize_boundary_model$Density, rep(0, length(maize_boundary_years))),
        col = rgb(255/255, 127/255, 14/255, 0.5), border = NA)
lines(maize_boundary_years, maize_boundary_model$Density, col = "#ff7f0e", lwd = 3)

legend("topright", legend = c("Bean", "Maize"),
       col = c("#1f77b4", "#ff7f0e"), lwd = 3, bty = "n", cex = 1.1)

# Plot 3: Radiocarbon age distributions
plot(density(bean_dates$c14_age), main = "C. 14C Age Distributions",
     xlab = "14C Age (BP)", ylab = "Density", lwd = 3, col = "#1f77b4",
     cex.main = 1.3, cex.lab = 1.1,
     xlim = c(250, 850))
lines(density(maize_dates$c14_age), lwd = 3, col = "#ff7f0e")
legend("topright", legend = c("Bean", "Maize"),
       col = c("#1f77b4", "#ff7f0e"), lwd = 3, bty = "n", cex = 1.1)

# Plot 4: Box plots with individual points
boxplot_data <- data.frame(
  CalBP = c(sapply(bean_cal$grids, function(x) {
    cumsum_prob <- cumsum(x$PrDens) / sum(x$PrDens)
    x$calBP[which.min(abs(cumsum_prob - 0.5))]
  }),
  sapply(maize_cal$grids, function(x) {
    cumsum_prob <- cumsum(x$PrDens) / sum(x$PrDens)
    x$calBP[which.min(abs(cumsum_prob - 0.5))]
  })),
  Crop = c(rep("Bean", nrow(bean_dates)), rep("Maize", nrow(maize_dates)))
)

boxplot(CalBP ~ Crop, data = boxplot_data, col = c("#1f77b4", "#ff7f0e"),
        main = "D. Calibrated Date Distributions",
        ylab = "Calibrated Age (cal BP)", cex.main = 1.3, cex.lab = 1.1,
        ylim = c(200, 950))

# Add individual points with jitter
set.seed(42)
bean_jitter <- jitter(rep(1, sum(boxplot_data$Crop == "Bean")), amount = 0.1)
maize_jitter <- jitter(rep(2, sum(boxplot_data$Crop == "Maize")), amount = 0.1)

points(bean_jitter, boxplot_data$CalBP[boxplot_data$Crop == "Bean"],
       pch = 21, bg = rgb(31/255, 119/255, 180/255, 0.5), cex = 1.2)
points(maize_jitter, boxplot_data$CalBP[boxplot_data$Crop == "Maize"],
       pch = 21, bg = rgb(255/255, 127/255, 14/255, 0.5), cex = 1.2)

dev.off()

# ============================================================================
# VISUALIZATION 3: HDR Intervals
# ============================================================================
cat("Creating HDR interval visualization...\n")

pdf("Figure3_HDR_Intervals.pdf", width = 12, height = 8)

par(mfrow = c(2, 1), mar = c(4, 4, 3, 2))

# Extract HDR intervals
bean_hdr <- hdr(bean_boundary_model, prob = 0.95)
maize_hdr <- hdr(maize_boundary_model, prob = 0.95)

# Bean HDR plot
plot(bean_boundary_years, bean_boundary_model$Density, type = "l", lwd = 3,
     col = "#1f77b4",
     main = "Bean 95% Highest Density Regions (HDR)",
     xlab = "Calendar Year (AD)", ylab = "Probability Density",
     cex.main = 1.4, cex.lab = 1.2)

# Fill overall region
polygon(c(bean_boundary_years, rev(bean_boundary_years)),
        c(bean_boundary_model$Density, rep(0, length(bean_boundary_years))),
        col = rgb(31/255, 119/255, 180/255, 0.2), border = NA)

# Highlight HDR intervals
if (is.list(bean_hdr)) {
  for (i in 1:length(bean_hdr)) {
    interval <- bean_hdr[[i]]
    if (length(interval) == 2) {
      in_interval <- bean_boundary_model$denCalAges >= min(interval) &
                     bean_boundary_model$denCalAges <= max(interval)
      if (sum(in_interval) > 0) {
        years_sub <- 1950 - bean_boundary_model$denCalAges[in_interval]
        dens_sub <- bean_boundary_model$Density[in_interval]
        polygon(c(years_sub, rev(years_sub)),
                c(dens_sub, rep(0, length(dens_sub))),
                col = rgb(31/255, 119/255, 180/255, 0.6), border = NA)

        # Add interval label
        mid_year <- 1950 - mean(interval)
        max_dens_in_interval <- max(dens_sub)
        text(mid_year, max_dens_in_interval * 1.05,
             paste(1950 - max(interval), "-", 1950 - min(interval), "AD"),
             cex = 0.8, srt = 0)
      }
    }
  }
}

# Maize HDR plot
plot(maize_boundary_years, maize_boundary_model$Density, type = "l", lwd = 3,
     col = "#ff7f0e",
     main = "Maize 95% Highest Density Regions (HDR)",
     xlab = "Calendar Year (AD)", ylab = "Probability Density",
     cex.main = 1.4, cex.lab = 1.2)

polygon(c(maize_boundary_years, rev(maize_boundary_years)),
        c(maize_boundary_model$Density, rep(0, length(maize_boundary_years))),
        col = rgb(255/255, 127/255, 14/255, 0.2), border = NA)

if (is.list(maize_hdr)) {
  for (i in 1:length(maize_hdr)) {
    interval <- maize_hdr[[i]]
    if (length(interval) == 2) {
      in_interval <- maize_boundary_model$denCalAges >= min(interval) &
                     maize_boundary_model$denCalAges <= max(interval)
      if (sum(in_interval) > 0) {
        years_sub <- 1950 - maize_boundary_model$denCalAges[in_interval]
        dens_sub <- maize_boundary_model$Density[in_interval]
        polygon(c(years_sub, rev(years_sub)),
                c(dens_sub, rep(0, length(dens_sub))),
                col = rgb(255/255, 127/255, 14/255, 0.6), border = NA)

        mid_year <- 1950 - mean(interval)
        max_dens_in_interval <- max(dens_sub)
        text(mid_year, max_dens_in_interval * 1.05,
             paste(1950 - max(interval), "-", 1950 - min(interval), "AD"),
             cex = 0.8, srt = 0)
      }
    }
  }
}

dev.off()

# ============================================================================
# VISUALIZATION 4: Timeline Summary
# ============================================================================
cat("Creating timeline summary...\n")

pdf("Figure4_Timeline.pdf", width = 16, height = 6)

par(mar = c(5, 2, 4, 2))

plot(1, type = "n", xlim = c(1000, 1500), ylim = c(0, 10),
     xlab = "Calendar Year (AD)", ylab = "",
     main = "Timeline of Bean and Maize Arrival in the Eastern Woodlands",
     yaxt = "n", cex.main = 1.6, cex.lab = 1.3)

# Bean timeline
bean_years_plot <- 1950 - bean_spd$grid$calBP
bean_dens_scaled <- bean_spd$grid$PrDens / max(bean_spd$grid$PrDens) * 2
polygon(c(bean_years_plot, rev(bean_years_plot)),
        c(7 + bean_dens_scaled, rep(7, length(bean_dens_scaled))),
        col = rgb(31/255, 119/255, 180/255, 0.6), border = "#1f77b4", lwd = 2)
text(1020, 8, "BEAN", pos = 4, cex = 1.3, font = 2, col = "#1f77b4")

# Maize timeline
maize_years_plot <- 1950 - maize_spd$grid$calBP
maize_dens_scaled <- maize_spd$grid$PrDens / max(maize_spd$grid$PrDens) * 2
polygon(c(maize_years_plot, rev(maize_years_plot)),
        c(3 + maize_dens_scaled, rep(3, length(maize_dens_scaled))),
        col = rgb(255/255, 127/255, 14/255, 0.6), border = "#ff7f0e", lwd = 2)
text(1020, 4, "MAIZE", pos = 4, cex = 1.3, font = 2, col = "#ff7f0e")

# Add key dates
abline(v = c(1100, 1150, 1200, 1250, 1300, 1350, 1400, 1450), col = "grey80", lty = 2)

# Add HDR ranges as bars
if (is.list(bean_hdr)) {
  all_bean_vals <- unlist(bean_hdr)
  rect(1950 - max(all_bean_vals), 6.5, 1950 - min(all_bean_vals), 7,
       col = rgb(31/255, 119/255, 180/255, 0.8), border = "black", lwd = 2)
}

if (is.list(maize_hdr)) {
  all_maize_vals <- unlist(maize_hdr)
  rect(1950 - max(all_maize_vals), 2.5, 1950 - min(all_maize_vals), 3,
       col = rgb(255/255, 127/255, 14/255, 0.8), border = "black", lwd = 2)
}

# Add legend
legend("topright",
       legend = c("Summed Probability Distribution", "95% HDR (earliest arrival)"),
       fill = c(rgb(0.5, 0.5, 0.5, 0.3), rgb(0.5, 0.5, 0.5, 0.7)),
       border = c("grey50", "black"),
       bty = "n", cex = 1.1)

dev.off()

cat("\n================================================================\n")
cat("VISUALIZATIONS COMPLETE!\n")
cat("================================================================\n\n")
cat("Generated files:\n")
cat("  1. Figure1_Overview.pdf - Multi-panel overview (calibrated dates, SPDs, boundaries)\n")
cat("  2. Figure2_Comparison.pdf - Direct comparisons (SPDs, boundaries, distributions)\n")
cat("  3. Figure3_HDR_Intervals.pdf - Detailed HDR interval visualization\n")
cat("  4. Figure4_Timeline.pdf - Timeline summary graphic\n")
cat("\n")
