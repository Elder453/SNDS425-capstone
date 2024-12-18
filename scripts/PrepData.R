# ===========================
# Script: PrepData.R
# Purpose: Load and preprocess the raw data for analysis.
# ===========================

# Load raw data
rawdata <- readRDS("../sims/Rawdata.RDS")

# Clean and organize data
monthly_clean <- rawdata |>
  clean_names() |>
  mutate(
    dominant_landcover = str_to_lower(str_trim(dominant_landcover)),
    year = factor(image_year),
    season = factor(season, 
                    levels = c("Winter", "Spring", "Summer", "Fall"), 
                    ordered = TRUE),
    veg = factor(veg),
    east_west = factor(east_west),
    north_south = factor(north_south),
    dominant_landuse = factor(dominant_landuse),
    dominant_landcover = factor(dominant_landcover),
    month = factor(month)
  ) |>
  dplyr::select(-image_year, -elevation_bins)

# Save prepared data for analysis
saveRDS(monthly_clean, "../sims/Data.RDS")
