
# ==========================================================
# MODULE 05: DATA VISUALIZATION
# PROJECT: SMART IRRIGATION ANALYSIS
# LIBRARY: GGPLOT2
# ==========================================================

library(tidyverse)
library(corrplot)

cat("\n========================================\n")
cat("       DATA VISUALIZATION MODULE\n")
cat("========================================\n")

# 1. Load cleaned dataset

irrigation_data <- read_csv(
  "data/processed/cleaned_irrigation_data.csv",
  show_col_types = FALSE
)

# Set category order

irrigation_data <- irrigation_data %>%
  mutate(
    Irrigation_Need = factor(
      Irrigation_Need,
      levels = c("Low", "Medium", "High")
    )
  )

# Create plots directory if required

dir.create("plots", showWarnings = FALSE)

# 2. User-defined function to save plots

save_plot <- function(plot, filename) {
  
  ggsave(
    filename = paste0("plots/", filename),
    plot = plot,
    width = 10,
    height = 6,
    dpi = 300
  )
  
  cat("Saved:", filename, "\n")
}

# ----------------------------------------------------------
# CHART 1: IRRIGATION DEMAND DISTRIBUTION
# ----------------------------------------------------------

demand_data <- irrigation_data %>%
  count(Irrigation_Need) %>%
  mutate(
    Percentage = n / sum(n) * 100
  )

plot1 <- ggplot(
  demand_data,
  aes(
    x = Irrigation_Need,
    y = Percentage,
    fill = Irrigation_Need
  )
) +
  geom_col(width = 0.65) +
  geom_text(
    aes(label = paste0(round(Percentage, 2), "%")),
    vjust = -0.5
  ) +
  labs(
    title = "Irrigation Demand Distribution",
    subtitle = "Distribution across 630,000 observations",
    x = "Irrigation Demand",
    y = "Percentage of Records"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

save_plot(
  plot1,
  "01_irrigation_distribution.png"
)


# ----------------------------------------------------------
# CHART 2: SOIL MOISTURE BY IRRIGATION DEMAND
# ----------------------------------------------------------

plot2 <- ggplot(
  irrigation_data,
  aes(
    x = Irrigation_Need,
    y = Soil_Moisture,
    fill = Irrigation_Need
  )
) +
  geom_boxplot(
    outlier.shape = NA,
    alpha = 0.8
  ) +
  labs(
    title = "Soil Moisture vs Irrigation Demand",
    subtitle = "Comparison of soil moisture distributions",
    x = "Irrigation Demand",
    y = "Soil Moisture"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

save_plot(
  plot2,
  "02_soil_moisture_boxplot.png"
)


# ----------------------------------------------------------
# CHART 3: CROP-WISE IRRIGATION DEMAND
# ----------------------------------------------------------

plot3 <- ggplot(
  irrigation_data,
  aes(
    x = Crop_Type,
    fill = Irrigation_Need
  )
) +
  geom_bar(
    position = "fill"
  ) +
  scale_y_continuous(
    labels = scales::percent
  ) +
  labs(
    title = "Crop-wise Irrigation Demand",
    subtitle = "Percentage distribution within each crop",
    x = "Crop Type",
    y = "Percentage",
    fill = "Irrigation Need"
  ) +
  theme_minimal()

save_plot(
  plot3,
  "03_crop_wise_demand.png"
)


# ----------------------------------------------------------
# CHART 4: SEASONAL IRRIGATION DEMAND
# ----------------------------------------------------------

plot4 <- ggplot(
  irrigation_data,
  aes(
    x = Season,
    fill = Irrigation_Need
  )
) +
  geom_bar(
    position = "fill"
  ) +
  scale_y_continuous(
    labels = scales::percent
  ) +
  labs(
    title = "Seasonal Irrigation Demand",
    subtitle = "Demand distribution across seasons",
    x = "Season",
    y = "Percentage",
    fill = "Irrigation Need"
  ) +
  theme_minimal()

save_plot(
  plot4,
  "04_seasonal_demand.png"
)


# ----------------------------------------------------------
# CHART 5: SOIL MOISTURE VS RAINFALL
# ----------------------------------------------------------

# Sample 10,000 records for clearer visualization

set.seed(42)

scatter_data <- irrigation_data %>%
  slice_sample(n = 10000)

plot5 <- ggplot(
  scatter_data,
  aes(
    x = Rainfall_mm,
    y = Soil_Moisture,
    color = Irrigation_Need
  )
) +
  geom_point(
    alpha = 0.45,
    size = 1.2
  ) +
  labs(
    title = "Rainfall vs Soil Moisture",
    subtitle = "Random sample of 10,000 observations",
    x = "Rainfall (mm)",
    y = "Soil Moisture",
    color = "Irrigation Need"
  ) +
  theme_minimal()

save_plot(
  plot5,
  "05_rainfall_vs_moisture.png"
)


# ----------------------------------------------------------
# CHART 6: CORRELATION HEATMAP
# ----------------------------------------------------------

numeric_data <- irrigation_data %>%
  select(where(is.numeric)) %>%
  select(-id)

correlation_matrix <- cor(
  numeric_data,
  use = "complete.obs"
)

png(
  "plots/06_correlation_heatmap.png",
  width = 1500,
  height = 1200,
  res = 150
)

corrplot(
  correlation_matrix,
  method = "color",
  type = "upper",
  addCoef.col = "black",
  number.cex = 0.65,
  tl.col = "black",
  tl.srt = 45,
  title = "Correlation Heatmap",
  mar = c(0, 0, 2, 0)
)

dev.off()

cat("Saved: 06_correlation_heatmap.png\n")


# ----------------------------------------------------------
# FINAL SUMMARY
# ----------------------------------------------------------

cat("\n========================================\n")
cat("   VISUALIZATION COMPLETED SUCCESSFULLY\n")
cat("========================================\n")

cat("Total visualizations generated: 6\n")
cat("Output directory: plots/\n")
