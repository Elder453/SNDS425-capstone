# Main.R
# Purpose: Master script to run all components of the workflow

# Load libraries
source("LoadLibraries.R")

# Obtain raw data
source("ObtainData.R")

# Prepare and clean data
source("PrepData.R")

# Explore and visualize data
source("ExploreData.R")

# Perform modeling and analysis
source("Analysis.R")
