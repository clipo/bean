# Merge PAF dates with existing radiocarbon dates

# Read existing data
existing_dates <- read.csv("radiocarbon_dates.csv", stringsAsFactors = FALSE)
paf_dates <- read.csv("paf_dates.csv", stringsAsFactors = FALSE)

# The existing dates don't have a reference column, so add it
if (!"reference" %in% colnames(existing_dates)) {
  existing_dates$reference <- "Hart_and_others"
}

# Reorder columns to match
paf_dates <- paf_dates[, c("site", "material", "lab_no", "c14_age", "c14_error", "reference")]
existing_dates <- existing_dates[, c("site", "material", "lab_no", "c14_age", "c14_error", "reference")]

# Combine datasets
all_dates <- rbind(existing_dates, paf_dates)

# Write combined dataset
write.csv(all_dates, "radiocarbon_dates_combined.csv", row.names = FALSE)

# Print summary
cat("Original dates:", nrow(existing_dates), "\n")
cat("PAF dates:", nrow(paf_dates), "\n")
cat("Combined dates:", nrow(all_dates), "\n\n")

cat("Material breakdown:\n")
print(table(all_dates$material))

cat("\nCombined dataset saved to: radiocarbon_dates_combined.csv\n")
