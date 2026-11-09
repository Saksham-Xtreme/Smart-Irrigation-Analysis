# 🌱 Smart Irrigation Demand & Water Usage Analysis using R

## 📌 Project Overview

**Smart Irrigation Demand & Water Usage Analysis** is a data analysis project developed using the R programming language. The project analyzes agricultural and environmental parameters to understand irrigation demand across different crops, seasons, and geographical regions.

It uses statistical analysis, data visualization, data cleaning, and user-defined functions to explore patterns in irrigation requirements.

The primary objective is to analyze the relationship between soil conditions, weather parameters, and irrigation demand, and generate meaningful insights that can support data-driven irrigation planning.

## 🎯 Objectives

- Import and analyze agricultural data using R.
- Identify and handle missing values and duplicate records.
- Perform exploratory data analysis (EDA).
- Analyze irrigation demand across different crops, seasons, and regions.
- Study relationships between numerical agricultural parameters.
- Apply statistical tests to identify significant differences and associations.
- Create meaningful visualizations using R.
- Implement user-defined functions, loops, conditionals, vectors, data frames, and lists.

## 📂 Dataset Information

The project uses a dataset obtained from the Kaggle Playground Series competition.

**Dataset:** Smart Irrigation Demand Dataset  
**Source:** [Kaggle Playground Series – Season 6, Episode 4](https://www.kaggle.com/competitions/playground-series-s6e4/data)

| Attribute | Details |
|---|---|
| Total Records | 630,000 |
| Total Columns | 21 |
| Missing Values | 0 |
| Duplicate Rows | 0 |
| Target Variable | Irrigation_Need |
| Target Categories | Low, Medium, High |

**Important:** This is synthetic competition data, not a verified collection of real-world farm measurements. Findings describe patterns in the supplied dataset and should not be treated as validated agricultural recommendations.

### Dataset Features

The dataset contains the following attributes:

- `Soil_Type`
- `Soil_pH`
- `Soil_Moisture`
- `Organic_Carbon`
- `Electrical_Conductivity`
- `Temperature_C`
- `Humidity`
- `Rainfall_mm`
- `Sunlight_Hours`
- `Wind_Speed_kmh`
- `Crop_Type`
- `Crop_Growth_Stage`
- `Season`
- `Irrigation_Type`
- `Water_Source`
- `Field_Area_hectare`
- `Mulching_Used`
- `Previous_Irrigation_mm`
- `Region`
- `Irrigation_Need`

The `id` column serves as a record identifier.

## 🛠️ Technologies and Libraries

**Programming Language:** R

**Development Environment:** RStudio

### R Libraries

| Library | Purpose |
|---|---|
| tidyverse | Data manipulation and visualization |
| readxl | Excel file import |
| janitor | Data cleaning |
| corrplot | Correlation heatmap |
| scales | Visualization formatting |
| rmarkdown | Report generation |
| knitr | Report formatting |

## ⚙️ Project Workflow

### 1. Data Import and Inspection

- Imported the CSV dataset using `read_csv()`.
- Examined dataset dimensions and column names.
- Inspected data types using `str()`.
- Checked missing values.
- Identified duplicate records.
- Analyzed the distribution of the target variable.

### 2. Data Cleaning and Preprocessing

- Converted categorical variables into appropriate factor types.
- Converted the ID column into an integer.
- Defined the target variable as an ordered factor.
- Checked for missing and invalid target values.
- Implemented median imputation for numerical variables.
- Implemented mode imputation for categorical variables.
- Checked and removed duplicate records when present.
- Exported the cleaned dataset.

**Result:** The dataset contained no missing values or duplicate records after validation.

### 3. Exploratory Data Analysis (EDA)

Performed descriptive and comparative analysis using R.

The analysis included:

- Mean, median, standard deviation, minimum, and maximum.
- Irrigation demand distribution.
- Crop-wise irrigation demand.
- Seasonal irrigation demand.
- Regional irrigation demand.
- Soil moisture analysis by irrigation category.
- Pearson correlation analysis.

### 4. Statistical Analysis

Applied statistical techniques to examine relationships in the dataset.

**Chi-Square Test of Independence**

Used to examine associations between irrigation demand and:

- Crop Type
- Season
- Region

**Cramér's V**

Used to measure the strength of categorical associations.

**Kruskal-Wallis Test**

Used to examine whether soil moisture distributions differ across Low, Medium, and High irrigation demand categories.

**Epsilon-Squared**

Calculated as an effect-size measure for the Kruskal-Wallis test.

### 5. Data Visualization

Generated six visualizations:

| No. | Visualization | Description |
|---|---|---|
| 1 | Irrigation Demand Distribution | Distribution of Low, Medium, and High categories |
| 2 | Soil Moisture Boxplot | Soil moisture variation across irrigation categories |
| 3 | Crop-wise Demand | Irrigation demand distribution across crops |
| 4 | Seasonal Demand | Irrigation demand distribution across seasons |
| 5 | Rainfall vs Soil Moisture | Relationship between rainfall and soil moisture |
| 6 | Correlation Heatmap | Correlations between numerical variables |

All visualizations are saved in the `plots/` directory.

### 6. User-Defined Functions

Implemented custom functions to demonstrate reusable programming logic.

Functions include:

- `calculate_percentage()` – Calculates percentage values.
- `classify_moisture()` – Classifies soil moisture into Low, Moderate, and High.
- `recommend_irrigation()` – Generates irrigation requirement recommendations.

Also implemented:

- Conditional statements (`if`, `else if`, `else`)
- Iteration using `for` loops
- Vector operations
- Data frame operations
- List creation and manipulation
- Summary report generation

## 📊 Key Findings

### Irrigation Demand Distribution

| Irrigation Category | Records | Percentage |
|---|---:|---:|
| Low | 369,917 | 58.7% |
| Medium | 239,074 | 38.0% |
| High | 21,009 | 3.33% |
| **Total** | **630,000** | **100%** |

### Soil Moisture Analysis

| Irrigation Category | Average Soil Moisture | Median Soil Moisture |
|---|---:|---:|
| High | 17.7 | 17.1 |
| Low | 43.3 | 44.0 |
| Medium | 29.7 | 23.9 |

The dataset shows lower average soil moisture in the High irrigation demand category.

### Statistical Findings

**Chi-Square Test Results**

| Variable | Chi-Square | Cramér's V |
|---|---:|---:|
| Crop Type | 1094.944 | 0.0295 |
| Season | 373.470 | 0.0172 |
| Region | 188.514 | 0.0122 |

All three tests produced statistically significant p-values, but their Cramér's V values indicate very weak associations.

**Kruskal-Wallis Test**

- H-statistic: 127599
- Degrees of freedom: 2
- P-value: less than 2.2e-16
- Epsilon-squared: 0.2025

The test indicates statistically significant differences in soil moisture distributions across irrigation demand categories.

**Correlation Analysis**

The strongest observed Pearson correlation was between:

- Rainfall and Soil Moisture: +0.0445

This represents a very weak positive linear correlation.

These results describe associations in the dataset; they do not establish causal relationships.

## 📁 Project Structure

```text
Smart-Irrigation-Analysis/
│
├── data/
│   ├── raw/
│   │   └── train.csv
│   │
│   └── processed/
│       └── cleaned_irrigation_data.csv
│
├── R/
│   ├── 01_data_import.R
│   ├── 02_data_cleaning.R
│   ├── 03_exploratory_analysis.R
│   ├── 04_statistical_analysis.R
│   ├── 05_visualizations.R
│   └── 06_functions.R
│
├── plots/
│   ├── 01_irrigation_distribution.png
│   ├── 02_soil_moisture_boxplot.png
│   ├── 03_crop_wise_demand.png
│   ├── 04_seasonal_demand.png
│   ├── 05_rainfall_vs_moisture.png
│   └── 06_correlation_heatmap.png
│
├── output/
│   ├── missing_value_report.csv
│   ├── descriptive_statistics.csv
│   ├── irrigation_distribution.csv
│   ├── crop_analysis.csv
│   ├── season_analysis.csv
│   ├── region_analysis.csv
│   ├── moisture_analysis.csv
│   ├── correlation_matrix.csv
│   ├── categorical_statistical_tests.csv
│   ├── kruskal_wallis_results.csv
│   └── final_irrigation_summary.csv
│
├── report/
│
├── main.R
├── README.md
└── Smart-Irrigation-Analysis.Rproj
```

## 🚀 How to Run the Project

### Prerequisites

- R installed on your system.
- RStudio Desktop.
- Required R packages.

### Step 1: Clone the Repository

```bash
git clone https://github.com/your-username/Smart-Irrigation-Analysis.git
```

### Step 2: Open the Project

Open `Smart-Irrigation-Analysis.Rproj` in RStudio.

### Step 3: Install Required Packages

```r
install.packages(c(
  "tidyverse",
  "readxl",
  "janitor",
  "corrplot",
  "scales",
  "rmarkdown",
  "knitr"
))
```

### Step 4: Execute the Project

Run the following command in the RStudio Console:

```r
source("main.R")
```

The main execution file automatically runs all six modules sequentially.

### Step 5: View Generated Outputs

- Processed dataset: `data/processed/`
- Statistical reports: `output/`
- Visualizations: `plots/`

## 📌 Project Execution Results

The complete project was successfully executed using `main.R`.

| Execution Metric | Result |
|---|---:|
| Modules Executed | 6 |
| Dataset Records | 630,000 |
| Dataset Columns | 21 |
| Visualizations Generated | 6 |
| Execution Time | 12.32 seconds |
| Execution Status | Successful |

## 🔮 Future Scope

- Integrate machine learning models for irrigation demand prediction.
- Explore more advanced statistical techniques.
- Incorporate real-world agricultural datasets.
- Develop an interactive dashboard for irrigation analysis.
- Integrate live weather and soil sensor data.
- Extend the analysis towards water consumption optimization.

## 👨‍💻 Author

**Saksham Tripathi**

B.Tech – Computer Science and Engineering

Project: Smart Irrigation Demand & Water Usage Analysis using R

## 📜 License

This project is developed for academic and educational purposes.