# ===========================
# Script: Main.R
# Purpose: Execute all scripts in sequence.
# ===========================

# Load libraries
cat("Loading libraries via LoadLibraries.R...\n")
source("LoadLibraries.R")

# Set constants
REPRODUCE <- FALSE  # Re-run code or load saved results
SAVE <- FALSE       # Overwrite saved training results
set.seed(425)       # For reproducibility

# Obtain raw data
cat("Obtaining data via ObtainData.R...\n")
source("ObtainData.R")

# Prepare and clean data
cat("Preparing data via PrepData.R...\n")
source("PrepData.R")

# Explore and visualize data
cat("Exploring data via ExploreData.R...\n")
source("ExploreData.R")

# Perform modeling and analysis
cat("Performing analysis via Analysis-PCA.R...\n")
source("Analysis-PCA.R")               # Perform PCA and scree plot

cat("Performing analysis via Analysis-BaselineModel.R...\n")
source("Analysis-BaselineModel.R")     # Baseline multinomial logistic regr

cat("Performing analysis via Analysis-TemporalModel.R...\n")
source("Analysis-TemporalModel.R")     # Temporal multinomial regression

cat("Performing analysis via Analysis-RandomForestModel.R...\n")
source("Analysis-RandomForestModel.R") # Random forest model

cat("Main.R complete.\n")
