
# ==========================================================
# MODULE 04: STATISTICAL ANALYSIS
# PROJECT: SMART IRRIGATION ANALYSIS
# ==========================================================

library(tidyverse)

cat("\n========================================\n")
cat("       STATISTICAL ANALYSIS\n")
cat("========================================\n")

# 1. Load cleaned dataset

irrigation_data <- read_csv(
  "data/processed/cleaned_irrigation_data.csv",
  show_col_types = FALSE
)

# 2. Function: Cramer's V

calculate_cramers_v <- function(table_data) {
  
  test <- chisq.test(table_data, correct = FALSE)
  
  n <- sum(table_data)
  
  minimum_dimension <- min(
    nrow(table_data) - 1,
    ncol(table_data) - 1
  )
  
  sqrt(
    as.numeric(test$statistic) /
      (n * minimum_dimension)
  )
}

# 3. Function: Chi-square analysis

categorical_test <- function(data, variable) {
  
  contingency_table <- table(
    data[[variable]],
    data$Irrigation_Need
  )
  
  test <- chisq.test(contingency_table)
  
  effect_size <- calculate_cramers_v(
    contingency_table
  )
  
  result <- data.frame(
    Variable = variable,
    Chi_Square = as.numeric(test$statistic),
    Degrees_Freedom = as.numeric(test$parameter),
    P_Value = test$p.value,
    Cramers_V = effect_size
  )
  
  cat("\n====================================\n")
  cat("Variable:", variable, "\n")
  cat("====================================\n")
  
  print(contingency_table)
  print(result)
  
  return(result)
}

# 4. Crop vs Irrigation Need

crop_test <- categorical_test(
  irrigation_data,
  "Crop_Type"
)

# 5. Season vs Irrigation Need

season_test <- categorical_test(
  irrigation_data,
  "Season"
)

# 6. Region vs Irrigation Need

region_test <- categorical_test(
  irrigation_data,
  "Region"
)

# 7. Combine categorical test results

categorical_results <- bind_rows(
  crop_test,
  season_test,
  region_test
)

write_csv(
  categorical_results,
  "output/categorical_statistical_tests.csv"
)

# 8. Kruskal-Wallis Test
# Compare soil moisture across irrigation categories

kruskal_result <- kruskal.test(
  Soil_Moisture ~ Irrigation_Need,
  data = irrigation_data
)

cat("\n====================================\n")
cat("       KRUSKAL-WALLIS TEST\n")
cat("====================================\n")

print(kruskal_result)

# 9. Calculate epsilon-squared effect size

h_value <- as.numeric(kruskal_result$statistic)

number_groups <- nlevels(
  irrigation_data$Irrigation_Need
)

total_records <- nrow(irrigation_data)

epsilon_squared <- max(
  0,
  (h_value - number_groups + 1) /
    (total_records - number_groups)
)

cat("\nEpsilon-squared:", epsilon_squared, "\n")

# 10. Save Kruskal-Wallis results

kruskal_summary <- data.frame(
  Test = "Kruskal-Wallis",
  Variable = "Soil_Moisture",
  Group = "Irrigation_Need",
  H_Statistic = h_value,
  Degrees_Freedom = as.numeric(
    kruskal_result$parameter
  ),
  P_Value = kruskal_result$p.value,
  Epsilon_Squared = epsilon_squared
)

write_csv(
  kruskal_summary,
  "output/kruskal_wallis_results.csv"
)

# 11. Statistical interpretation

if (kruskal_result$p.value < 0.05) {
  
  cat(
    "\nSoil moisture distributions differ",
    "significantly across demand categories.\n"
  )
  
} else {
  
  cat(
    "\nNo statistically significant difference",
    "was detected.\n"
  )
}

# 12. Final results

cat("\n========================================\n")
cat("   STATISTICAL ANALYSIS COMPLETED\n")
cat("========================================\n")

cat("Statistical test reports saved!\n")
