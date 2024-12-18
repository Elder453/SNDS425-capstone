# ===========================
# Script: Main.R
# Purpose: Execute all scripts in sequence.
# ===========================

# Load libraries
source("LoadLibraries.R")

# Set constants
REPRODUCE <- FALSE  # Re-run code or load saved results
SAVE <- FALSE       # Overwrite saved training results
set.seed(425)       # For reproducibility

# Obtain raw data
source("ObtainData.R")

# Prepare and clean data
source("PrepData.R")

# Explore and visualize data
source("ExploreData.R")

# Perform modeling and analysis
source("Analysis-PCA.R")               # Perform PCA and scree plot
source("Analysis-BaselineModel.R")     # Baseline multinomial logistic regr
source("Analysis-TemporalModel.R")     # Temporal multinomial regression
source("Analysis-RandomForestModel.R") # Random forest model
