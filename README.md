# S&DS 425: Landcover Classification Project

Welcome to our S&DS: 425 Capstone Project repository! This project encompasses data acquisition, preprocessing, exploratory analysis, and the implementation of various machine learning models for land cover classification. The repository includes both R and JavaScript scripts tailored for different aspects of the analysis.

## Table of Contents

- [Project Overview](#project-overview)
- [Repository Structure](#repository-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Execution](#execution)
- [Scripts Description](#scripts-description)
  - [R Scripts](#r-scripts)
  - [JavaScript Script](#javascript-script)
- [Configuration](#configuration)
- [Contact](#contact)

## Project Overview

This project aims to perform land cover classification using various machine learning models, including CART (Classification and Regression Trees), multinomial logistic regression, and Random Forests. The analysis involves:

1. **Data Acquisition**: Downloading raw data from SharePoint.
2. **Data Preprocessing**: Cleaning and preparing the data for analysis.
3. **Exploratory Data Analysis**: Understanding data distributions and relationships.
4. **Modeling**: Implementing and evaluating different classification models.
5. **Visualization**: Presenting results through maps and charts.
6. **Error Analysis**: Investigating misclassifications to improve model performance.

## Repository Structure

```
SNDS425-capstone/
│
├── scripts/
│   ├── LoadLibraries.R               # Installs and loads necessary R packages
│   ├── ObtainData.R                  # Downloads raw data from SharePoint into ../sims/
│   ├── PrepData.R                    # Cleans and prepares the dataset
│   ├── ExploreData.R                 # Performs exploratory data analysis
│   ├── Analysis-PCA.R                # Performs PCA and generates scree plot
│   ├── Analysis-BaselineModel.R      # Implements baseline multinomial logistic regression
│   ├── Analysis-TemporalModel.R      # Implements temporal multinomial regression
│   ├── Analysis-RandomForestModel.R  # Implements Random Forest model
│   ├── Analysis-CARTI.js             # CART classifier script for Google Earth Engine
│   ├── Main.R                        # Executes all R scripts in sequence
│   ├── exec-summary.qmd              # Quarto markdown for generating exec-summary.pdf
│   └── report.qmd                    # Quarto markdown for generating report.pdf
│
├── sims/
│   └── …                             # Directory for graphs saved as PNGs and all RDS files.
│
├── README.md                         # Project documentation
├── report.pdf                        # Generated project report
├── exec-summary.pdf                  # Generated executive summary
└── .gitignore                        # Specifies files and directories to be ignored by Git
```

## Getting Started

### Prerequisites

- **R Environment**: Ensure that R (version 4.0 or higher) is installed on your system.
- **Google Earth Engine Account**: Required to run the `Analysis-CARTI.js` script.
- **Access to SharePoint**: Permissions to download the raw data (`monthly_clean.RDS`) from SharePoint.

### Installation

1. **Clone the Repository**

   ```bash
   git clone https://github.com/Elder453/SNDS425-capstone.git
   cd SNDS425-capstone
   ```

2. **Install R and Required Packages**  
	The `LoadLibraries.R` script handles the installation and loading of all necessary R packages. Ensure you have an active internet connection to install any missing packages. Run the following commands from the `scripts` directory:  
	
    ```bash
   cd scripts
   Rscript LoadLibraries.R
   ```

### Execution

1. **Run the Main R Script**  
	The `Main.R` script orchestrates the execution of all R scripts in the correct order. To execute, run the following commands from the `scripts` directory::
	
	```bash
	Rscript Main.R
	```

	- **Important Notes**:  
		- You must be in the scripts directory before running `Main.R`.  
		- All scripts must be executed in the order presented in `Main.R`. The scripts are **NOT** self-contained.

2. **Run the JavaScript Script on Google Earth Engine**  
	The `Analysis-CARTI.js` script is standalone and designed to run on Google Earth Engine (GEE). The steps are explained in the file. The Google Earth Engine version can be found [here](https://code.earthengine.google.com/c3ff3c14701654ffd166e70e189f8ee6).

## Scripts Description

### R Scripts

- **`LoadLibraries.R`**
  - **Purpose**: Installs (if necessary) and loads all required R packages into the environment.
  - **Usage**: Automatically sourced by `Main.R`.

- **`ObtainData.R`**
  - **Purpose**: Downloads the raw data (`Rawdata.RDS`, `rf_results.RDS`, `rf_model.RDS`, `log_model.RDS`, `log_model_tmprl_month.RDS`) from SharePoint to the `sims` folder.
  - **Usage**: Automatically sourced by `Main.R`.

- **`PrepData.R`**
  - **Purpose**: Loads `Rawdata.RDS` into the environment, cleans it, and saves the cleaned version as `Data.rds` in the `sims` folder.
  - **Usage**: Automatically sourced by `Main.R`.

- **`ExploreData.R`**
  - **Purpose**: Loads `../sims/Data.rds` into the environment as `monthly_clean` and explores the data in the order presented in the report.
  - **Usage**: Automatically sourced by `Main.R`.

- **`Analysis-PCA.R`**
  - **Purpose**: Performs Principal Component Analysis (PCA) and generates a scree plot.
  - **Usage**: Automatically sourced by `Main.R`.

- **`Analysis-BaselineModel.R`**
  - **Purpose**: Implements a baseline multinomial logistic regression model.
  - **Usage**: Automatically sourced by `Main.R`.

- **`Analysis-TemporalModel.R`**
  - **Purpose**: Implements a temporal multinomial regression model.
  - **Usage**: Automatically sourced by `Main.R`.

- **`Analysis-RandomForestModel.R`**
  - **Purpose**: Implements a Random Forest classification model.
  - **Usage**: Automatically sourced by `Main.R`.

- **`Main.R`**
  - **Purpose**: Executes all R scripts in the required sequence.
  - **Usage**: Run this script to perform the entire analysis pipeline.

### JavaScript Script

- **`Analysis-CARTI.js`**
  - **Purpose**: Implements a CART (Classification and Regression Trees) classifier for land cover classification using Google Earth Engine (GEE).
  - **Usage**: This script is standalone and serves as proof of concept. It requires a GEE account to execute.
  - **Note**: Ensure that you manually download the required table from `x.com`, upload it to your GEE assets, and reference it correctly in the script as `var dataset`.

### Configuration

The `Main.R` script contains configurable constants that can be modified to control the behavior of the analysis.
- **REPRODUCE**
  - **Description**: Determines whether to re-run all simulations, trainings, and plot generations.
  - **Values**:
    - `TRUE`: Re-run all processes.
    - `FALSE`: Load and use existing results.
  - **Default**: `FALSE`
- **SAVE**
  - **Description**: Controls whether to overwrite any PNGs or output files created during the analysis.
  - **Values**:
    - `TRUE`: Overwrite existing files.
    - `FALSE`: Retain existing files.
  - **Default**: `FALSE`

To modify these constants, edit the `Main.R` script:

## Contact

For any inquiries or contributions, please contact [Elder Veliz](mailto:elder.veliz@yale.edu)!
