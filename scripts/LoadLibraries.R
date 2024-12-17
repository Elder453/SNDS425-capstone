# LoadLibraries.R
# Purpose: Load necessary libraries

suppressMessages({
  library(caret)
  library(ggplot2)
  library(ggcorrplot)
  library(httr)         # For HTTP requests
  library(janitor)      # Clean column names
  library(MASS)         # PCA
  library(nnet)         # Multinomial regression
  library(pubtheme)     # Custom themes for ggplot
  library(randomForest) # Random forest
  library(ranger)       # Random forest
  library(sf)           # Spatial data
  library(tidyverse)    # Data manipulation
})

# Set constants
REPRODUCE <- FALSE
set.seed(425)
