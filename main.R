
# ==========================================
# SMART IRRIGATION DEMAND & WATER USAGE ANALYSIS
# Main Execution File
# ==========================================

cat("\n")
cat("============================================\n")
cat("   SMART IRRIGATION ANALYSIS USING R\n")
cat("============================================\n")

start_time <- Sys.time()

modules <- c(
  "R/01_data_import.R",
  "R/02_data_cleaning.R",
  "R/03_exploratory_analysis.R",
  "R/04_statistical_analysis.R",
  "R/05_visualizations.R",
  "R/06_functions.R"
)

for (module in modules) {
  
  cat("\n\n--------------------------------------------\n")
  cat("Executing:", module, "\n")
  cat("--------------------------------------------\n")
  
  if (file.exists(module)) {
    source(module)
    cat("\nCompleted:", module, "\n")
  } else {
    stop(paste("Module not found:", module))
  }
}

end_time <- Sys.time()

cat("\n\n============================================\n")
cat("       PROJECT EXECUTION COMPLETED\n")
cat("============================================\n")

cat(
  "Total execution time:",
  round(
    as.numeric(difftime(end_time, start_time, units = "secs")),
    2
  ),
  "seconds\n"
)

cat("Modules executed:", length(modules), "\n")
cat("Visualizations generated: 6\n")
cat("============================================\n")
