# ===========================
# Script: LoadLibraries.R
# Purpose: Load necessary libraries, installing them if not already installed.
# ===========================

# ---------------------------
# Define Required Packages
# ---------------------------
# List of required packages for the project.
required_packages <- c(
  "caret",
  "ggplot2",
  "ggcorrplot",
  "httr",         # For HTTP requests
  "janitor",      # Clean column names
  "MASS",         # PCA
  "nnet",         # Multinomial regression
  "pubtheme",     # Custom themes for ggplot
  "randomForest", # Random forest
  "ranger",       # Random forest
  "sf",           # Spatial data
  "tidyverse"     # Data manipulation
)

# ---------------------------
# Install Missing Packages
# ---------------------------
# Function to check for missing packages and install them.
install_if_missing <- function(packages) {
  # Identify packages that are not installed
  missing_packages <- packages[
    !(packages %in% installed.packages()[, "Package"])
    ]
  
  if (length(missing_packages)) {
    message("Installing missing packages: ", 
            paste(missing_packages, collapse = ", ")
            )
    install.packages(missing_packages, dependencies = TRUE)
  } else {
    message("All required packages are already installed.")
  }
}

# Install missing packages
install_if_missing(required_packages)


# ---------------------------
# Load Libraries
# ---------------------------
# Suppress messages and load all required libraries.
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
