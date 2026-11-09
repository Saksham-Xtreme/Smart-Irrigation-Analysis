
# 4. Handle missing values conditionally

# User-defined function to calculate mode
get_mode <- function(x) {
  values <- na.omit(x)
  
  if (length(values) == 0) {
    return(NA)
  }
  
  names(which.max(table(values)))
}

# Remove rows with missing identifier or target
irrigation_data <- irrigation_data %>%
  filter(!is.na(id), !is.na(Irrigation_Need))

# Identify predictor columns
predictor_columns <- setdiff(
  names(irrigation_data),
  c("id", "Irrigation_Need")
)

# Handle missing values using a loop
for (column in predictor_columns) {
  
  if (anyNA(irrigation_data[[column]])) {
    
    if (is.numeric(irrigation_data[[column]])) {
      
      # Replace missing numerical values with median
      median_value <- median(
        irrigation_data[[column]],
        na.rm = TRUE
      )
      
      irrigation_data[[column]][
        is.na(irrigation_data[[column]])
      ] <- median_value
      
    } else {
      
      # Replace missing categorical values with mode
      mode_value <- get_mode(irrigation_data[[column]])
      
      irrigation_data[[column]][
        is.na(irrigation_data[[column]])
      ] <- mode_value
    }
  }
}

# Remove duplicate records if present
if (any(duplicated(irrigation_data))) {
  
  irrigation_data <- distinct(irrigation_data)
  
}

cat("\nMissing values after treatment:",
    sum(is.na(irrigation_data)), "\n")
