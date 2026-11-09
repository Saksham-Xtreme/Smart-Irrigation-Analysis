
# ==================================================
# MODULE 01: DATA IMPORT AND INITIAL VALIDATION
# ==================================================

library(readr)

# Dataset location
file_path <- "data/raw/train.csv"

# Verify the file exists
if (!file.exists(file_path)) {
  stop("Dataset not found. Check data/raw/")
}

# Import CSV
irrigation_data <- read_csv(
  file_path,
  show_col_types = FALSE
)

# Dataset dimensions
cat("Total Rows:", nrow(irrigation_data), "\n")
cat("Total Columns:", ncol(irrigation_data), "\n")

# Inspect dataset
print(head(irrigation_data))
print(names(irrigation_data))
print(str(irrigation_data))

# Count missing values
missing_values <- colSums(is.na(irrigation_data))

cat("\nMissing Values:\n")
print(missing_values)

# Detect duplicate rows
cat("\nDuplicate Rows:",
    sum(duplicated(irrigation_data)), "\n")

# Target distribution
if ("Irrigation_Need" %in% names(irrigation_data)) {
  print(table(irrigation_data$Irrigation_Need))
}
