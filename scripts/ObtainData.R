# ===========================
# Script: ObtainData.R
# Purpose: Download raw RDS data from SharePoint link 
#          and save it locally as "Rawdata.rds".
# ===========================

# SharePoint link to the RDS file
sharepoint_link <- "https://yaleedu-my.sharepoint.com/:u:/g/personal/elder_veliz_yale_edu/Ec6zY8QnpxJPg4sz41MNLnABYmoX7AN_iJ3Av3FcTlyIyQ?e=gfH3pQ"
download_link <- paste0(sharepoint_link, "&download=1")

# Local file path to save the raw RDS file
output_file <- "Rawdata.rds"

# Download RDS file
download_rawdata <- function(url, output_path) {
  cat("Starting download of raw RDS data...\n")
  
  # Use httr::GET to download and save the file
  response <- GET(url, write_disk(output_path, overwrite = TRUE))
  
  # Check for success
  if (response$status_code == 200 && file.exists(output_path)) {
    cat("File successfully downloaded and saved as", output_path, "\n")
  } else {
    stop("Failed to download the file. Check the URL or network connection.")
  }
}
download_rawdata(download_link, output_file)

cat("ObtainData.R completed. Raw data is saved as 'Rawdata.rds'.\n")