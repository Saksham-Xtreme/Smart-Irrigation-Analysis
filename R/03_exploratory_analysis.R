
# ==========================================================
# MODULE 03: EXPLORATORY DATA ANALYSIS (EDA)
# PROJECT: SMART IRRIGATION ANALYSIS
# ==========================================================

library(tidyverse)

cat("\n========================================\n")
cat("   EXPLORATORY DATA ANALYSIS\n")
cat("========================================\n")

# 1. Import cleaned dataset

irrigation_data <- read_csv(
  "data/processed/cleaned_irrigation_data.csv",
  show_col_types = FALSE
)

cat("\nDataset loaded successfully!\n")

# 2. Separate numerical variables

numeric_data <- irrigation_data %>%
  select(where(is.numeric)) %>%
  select(-id)

numeric_columns <- names(numeric_data)

# 3. Descriptive Statistics

descriptive_stats <- numeric_data %>%
  summarise(
    across(
      everything(),
      list(
        Mean = ~mean(.x),
        Median = ~median(.x),
        SD = ~sd(.x),
        Minimum = ~min(.x),
        Maximum = ~max(.x)
      )
    )
  )

cat("\n--- DESCRIPTIVE STATISTICS ---\n")
print(descriptive_stats)

write_csv(
  descriptive_stats,
  "output/descriptive_statistics.csv"
)

# 4. Irrigation Demand Distribution

demand_distribution <- irrigation_data %>%
  count(Irrigation_Need) %>%
  mutate(
    Percentage = round(n / sum(n) * 100, 2)
  )

cat("\n--- IRRIGATION DEMAND DISTRIBUTION ---\n")
print(demand_distribution)

write_csv(
  demand_distribution,
  "output/irrigation_distribution.csv"
)

# 5. Crop-wise Irrigation Analysis

crop_analysis <- irrigation_data %>%
  group_by(Crop_Type, Irrigation_Need) %>%
  summarise(
    Total_Records = n(),
    .groups = "drop"
  ) %>%
  group_by(Crop_Type) %>%
  mutate(
    Percentage = round(
      Total_Records / sum(Total_Records) * 100, 2
    )
  )

cat("\n--- CROP-WISE IRRIGATION ANALYSIS ---\n")
print(crop_analysis)

write_csv(
  crop_analysis,
  "output/crop_analysis.csv"
)

# 6. Seasonal Irrigation Analysis

season_analysis <- irrigation_data %>%
  group_by(Season, Irrigation_Need) %>%
  summarise(
    Total_Records = n(),
    .groups = "drop"
  )

cat("\n--- SEASONAL ANALYSIS ---\n")
print(season_analysis)

write_csv(
  season_analysis,
  "output/season_analysis.csv"
)

# 7. Regional Irrigation Analysis

region_analysis <- irrigation_data %>%
  group_by(Region, Irrigation_Need) %>%
  summarise(
    Total_Records = n(),
    .groups = "drop"
  )

cat("\n--- REGIONAL ANALYSIS ---\n")
print(region_analysis)

write_csv(
  region_analysis,
  "output/region_analysis.csv"
)

# 8. Soil Moisture Analysis

moisture_analysis <- irrigation_data %>%
  group_by(Irrigation_Need) %>%
  summarise(
    Average_Moisture = mean(Soil_Moisture),
    Median_Moisture = median(Soil_Moisture),
    SD_Moisture = sd(Soil_Moisture),
    .groups = "drop"
  )

cat("\n--- SOIL MOISTURE ANALYSIS ---\n")
print(moisture_analysis)

write_csv(
  moisture_analysis,
  "output/moisture_analysis.csv"
)

# 9. Correlation Analysis

correlation_matrix <- cor(
  numeric_data,
  use = "complete.obs"
)

cat("\n--- CORRELATION MATRIX ---\n")
print(round(correlation_matrix, 3))

write.csv(
  correlation_matrix,
  "output/correlation_matrix.csv"
)

# 10. Identify strongest correlations

correlation_values <- as.data.frame(
  as.table(correlation_matrix)
)

correlation_values <- correlation_values %>%
  filter(Var1 != Var2) %>%
  mutate(Absolute_Correlation = abs(Freq)) %>%
  arrange(desc(Absolute_Correlation))

# Remove duplicate variable pairs

correlation_values <- correlation_values %>%
  rowwise() %>%
  mutate(
    Pair = paste(
      sort(c(as.character(Var1), as.character(Var2))),
      collapse = "_"
    )
  ) %>%
  ungroup() %>%
  distinct(Pair, .keep_all = TRUE) %>%
  arrange(desc(Absolute_Correlation))

cat("\n--- TOP 10 CORRELATIONS ---\n")
print(head(correlation_values, 10))

# 11. Final Summary

cat("\n========================================\n")
cat("       EDA COMPLETED SUCCESSFULLY\n")
cat("========================================\n")

cat("Records analyzed:", nrow(irrigation_data), "\n")
cat("Numerical variables:", length(numeric_columns), "\n")
cat("EDA output files generated successfully!\n")

