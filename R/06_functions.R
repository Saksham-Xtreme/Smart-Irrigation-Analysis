
library(tidyverse)

# ==========================================
# MODULE 06: USER-DEFINED FUNCTIONS
# ==========================================

cat("\n========================================\n")
cat("     USER-DEFINED FUNCTIONS MODULE\n")
cat("========================================\n")

# 1. Load cleaned dataset
data <- read_csv(
  "data/processed/cleaned_irrigation_data.csv",
  show_col_types = FALSE
)

# 2. User-defined function: Calculate percentage
calculate_percentage <- function(count, total) {
  return(round((count / total) * 100, 2))
}

# 3. User-defined function: Classify soil moisture
classify_moisture <- function(moisture) {
  
  if (is.na(moisture)) {
    return("Unknown")
  } else if (moisture < 20) {
    return("Low")
  } else if (moisture < 40) {
    return("Moderate")
  } else {
    return("High")
  }
}

# 4. Apply function to a vector
sample_moisture <- c(15, 25, 35, 45, 55)

moisture_categories <- sapply(
  sample_moisture,
  classify_moisture
)

cat("\nSoil Moisture Classification:\n")

print(data.frame(
  Moisture = sample_moisture,
  Category = moisture_categories
))

# 5. Conditional statements: Irrigation recommendation
recommend_irrigation <- function(category) {
  
  if (category == "High") {
    return("High irrigation requirement")
  } else if (category == "Medium") {
    return("Moderate irrigation requirement")
  } else if (category == "Low") {
    return("Low irrigation requirement")
  } else {
    return("Invalid category")
  }
}

cat("\nIrrigation Recommendations:\n")

categories <- c("Low", "Medium", "High")

for (category in categories) {
  cat(category, ":", recommend_irrigation(category), "\n")
}

# 6. Vector operations
soil_moisture <- data$Soil_Moisture

cat("\nVector Operations:\n")
cat("Mean:", mean(soil_moisture, na.rm = TRUE), "\n")
cat("Maximum:", max(soil_moisture, na.rm = TRUE), "\n")
cat("Minimum:", min(soil_moisture, na.rm = TRUE), "\n")

# 7. Data frame operations
irrigation_summary <- data %>%
  count(Irrigation_Need, name = "Total_Records") %>%
  mutate(
    Percentage = calculate_percentage(
      Total_Records,
      sum(Total_Records)
    )
  )

cat("\nIrrigation Summary Data Frame:\n")
print(irrigation_summary)

# 8. List operations
project_summary <- list(
  project_name = "Smart Irrigation Analysis",
  total_records = nrow(data),
  irrigation_categories = unique(data$Irrigation_Need),
  average_soil_moisture = mean(
    data$Soil_Moisture,
    na.rm = TRUE
  ),
  irrigation_distribution = irrigation_summary
)

cat("\nProject Summary List:\n")
print(project_summary)

# 9. Save summary output
write_csv(
  irrigation_summary,
  "output/final_irrigation_summary.csv"
)

cat("\n========================================\n")
cat("  MODULE 06 COMPLETED SUCCESSFULLY\n")
cat("========================================\n")
