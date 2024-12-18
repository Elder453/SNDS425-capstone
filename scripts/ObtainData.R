# ===========================
# Script: ObtainData.R
# Purpose: Download multiple RDS files from SharePoint links
#          and save them in the "../sims/" directory.
# ===========================

# Target directory for saving files
output_dir <- "../sims"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Define SharePoint links and corresponding output file names
file_links <- list(
  "Rawdata.RDS"               = "https://yaleedu-my.sharepoint.com/:u:/g/personal/elder_veliz_yale_edu/Ec6zY8QnpxJPg4sz41MNLnABYmoX7AN_iJ3Av3FcTlyIyQ?e=gfH3pQ",
  "rf_results.RDS"            = "https://yaleedu-my.sharepoint.com/:u:/g/personal/elder_veliz_yale_edu/ESa48T6Q47pKniOWAL-2obUBe80fDjUN06gPbdjkjiauFw?e=X8jgUI",
  "rf_model.RDS"              = "https://yaleedu-my.sharepoint.com/:u:/g/personal/elder_veliz_yale_edu/ERFoC0jhWoZKg2h5i9c3VOIBaC8iwOmGd4t3XnZmrLWqfA?e=gb93ec",
  "log_model.RDS"             = "https://yaleedu-my.sharepoint.com/:u:/g/personal/elder_veliz_yale_edu/EfMfBcM2gZNDkzQK6BBVZ48B7hFgrSQmXx2qIUhtubeh6Q?e=mCQmSS",
  "log_model_tmprl_month.RDS" = "https://yaleedu-my.sharepoint.com/:u:/g/personal/elder_veliz_yale_edu/EbRacReXIr9FpmaVkccjWH4BLjLNvF6mxSqfSnMbEhzgOg?e=lA93kr"
)

# Function to download files from SharePoint
download_file <- function(url, output_path) {
  cat("Downloading", basename(output_path), "...\n")
  
  # Append download flag to SharePoint URL
  download_url <- paste0(url, "&download=1")
  
  # Use httr::GET to download and save the file
  response <- GET(download_url, write_disk(output_path, overwrite = TRUE))
  
  # Check for success
  if (response$status_code == 200 && file.exists(output_path)) {
    cat("Successfully saved to:", output_path, "\n\n")
  } else {
    stop("Failed to download", basename(output_path), ". Check URL or network connection.")
  }
}

# Loop through files and download each
for (file_name in names(file_links)) {
  # Construct full output path
  output_path <- file.path(output_dir, file_name)
  
  # Download the file
  download_file(file_links[[file_name]], output_path)
}

cat("All files have been downloaded and saved in", output_dir, "\n")
