# ===========================
# Script: Analysis-TemporalModel.R
# Purpose: Add temporal sinusoidal features and fit multinomial regression.
# ===========================


# ---------------------------
# Visualization: Monthly Mean NDVI
# ---------------------------
# Plot the monthly mean NDVI to visualize seasonal trends.

# Aggregate NDVI by month to compute mean NDVI for each month
ndvi_monthly <- monthly_clean |>
  group_by(month) |>
  summarize(mean_ndvi = mean(ndvi, na.rm = TRUE)) |>
  arrange(month)

# Create a line plot of monthly mean NDVI
ggplot(ndvi_monthly, aes(x = month, y = mean_ndvi)) +
  geom_line(group = 1, color = "darkgreen") +
  geom_point(size = 2, color = "darkred") +
  theme_minimal() +
  labs(title = "Monthly Mean NDVI", x = "Month", y = "Mean NDVI") +
  theme_pub()


# ---------------------------
# Sinusoidal Analysis Using FFT
# ---------------------------
# Analyze the frequency components of the NDVI time series to 
# identify dominant cycles.

if (REPRODUCE) {
  # Subtract mean NDVI to remove DC component (center data at 0)
  ndvi_detrended <- ndvi_monthly$mean_ndvi - mean(ndvi_monthly$mean_ndvi)
  
  # Perform FFT on detrended NDVI
  fft_result <- fft(ndvi_detrended)
  frequencies <- seq(0, 0.5, length.out = length(fft_result) / 2 + 1)
  magnitudes <- Mod(fft_result)[1:(length(fft_result) / 2 + 1)]
  
  # Identify dominant frequency
  dominant_freq <- frequencies[which.max(magnitudes)]
  
  # results
  list(
    frequencies = frequencies |> fractions(),
    magnitudes = magnitudes,
    dominant_frequency = dominant_freq |> fractions()
    # 1/12 is dominant frequency after DC
  )
}


# ---------------------------
# Sinusoidal Feature Engineering
# ---------------------------
# This section adds sinusoidal features to capture the cyclical 
# nature of temporal data (months).

# Encode month as a numeric variable (1 = January, ..., 12 = December)
month_numeric <- as.numeric(monthly_clean$month)

# Frequency for annual cycle
freq_month <- 1 / 12

# sine and cosine features
monthly_clean$sin_month <- sin(2 * pi * freq_month * month_numeric)
monthly_clean$cos_month <- cos(2 * pi * freq_month * month_numeric)


# ---------------------------
# Data Preparation
# ---------------------------
# Standardize continuous predictors and construct the final dataset for modeling.

# Standardize continuous predictors to ensure they are on the same scale
standardized_predictors <- scale(data.frame(
  PC1 = pca_bands$x[, 1],                     # First PC
  PC2 = pca_bands$x[, 2],                     # Second PC
  NDVI = monthly_clean$ndvi,                  # NDVI
  Elevation = monthly_clean$elevation_meters, # Elevation
  Sin_Month = monthly_clean$sin_month,        # Sine of month
  Cos_Month = monthly_clean$cos_month         # Cosine of month
))

model_data_tmprl <- data.frame(
  standardized_predictors,                          # Std continuous predictors
  Veg = factor(monthly_clean$veg),                  # Vegetation indicator
  EastWest = factor(monthly_clean$east_west),       # Spatial: East/West
  NorthSouth = factor(monthly_clean$north_south),   # Spatial: North/South
  Outcome = monthly_clean$dominant_landcover        # Target: Land Cover Class
)


# ---------------------------
# Multinomial Logistic Regression Model Training
# ---------------------------

if (REPRODUCE) {
  # Fit multinomial logistic regression
  logistic_model <- multinom(Outcome ~ ., data = model_data_tmprl)
  
  # Save the trained model to disk if the SAVE flag is set to TRUE.
  if (SAVE) {
    saveRDS(logistic_model, "../sims/log_model_tmprl_month.RDS")
  }
} else {
  # If not reproducing, load the existing trained model from disk.
  logistic_model <- readRDS("../sims/log_model_tmprl_month.RDS")
}


# ---------------------------
# Model Evaluation
# ---------------------------

if (REPRODUCE) {
  set.seed(425)
  predictions <- predict(logistic_model, model_data_tmprl)  # Predicted classes
  true_labels <- model_data_tmprl$Outcome                   # True labels
  
  # Confusion matrix
  conf_matrix <- confusionMatrix(
    data = factor(predictions, levels = levels(true_labels)), 
    reference = factor(true_labels, levels = levels(true_labels))
  )
  
  # Class-wise metrics
  class_metrics <- as.data.frame(conf_matrix$byClass) |> 
    dplyr::select(Precision, Recall, F1, "Balanced Accuracy")
  
  # Macro-averages for Recall, Precision, and F1-score
  macro_avg <- colMeans(class_metrics)
  
  # Combine class-wise metrics with macro-averaged metrics
  (results_table <- class_metrics |> 
      rbind(macro_avg))
}


# ---------------------------
# Coefficient Analysis
# ---------------------------

if (REPRODUCE) {
  # Extract coefficients
  coefficients <- summary(logistic_model)$coefficients
  
  coef_long <- as.data.frame(coefficients) |>
    rownames_to_column("Predictor") |>
    pivot_longer(-Predictor, names_to = "Class", values_to = "Coefficient")
  
  # Create a heatmap to visualize the coefficients for each predictor and class
  (p <- ggplot(coef_long, aes(x = Class, y = Predictor, fill = Coefficient)) +
      geom_tile() +
      scale_fill_gradient2(low = "darkred", 
                           mid = "white", 
                           high = "darkgreen", 
                           midpoint = 0) +
      theme_pub() +
      labs(
        title = "Heatmap of Coefficients by Predictor and Class",
        x = "Predictor", y = "Class", fill = "Coefficient"
      ) +
      theme(
        plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
        legend.text = element_text(size = 6),
        legend.title = element_text(size = 10),
        axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
        axis.text.y = element_text(size = 10)
      ))
  
  # Save the coefficient heatmap plot to disk if the SAVE flag is set to TRUE.
  if (SAVE) {
    ggsave("../sims/tmprl_multinom_model_coeffs_heatmap.png", 
           plot = p, width = 8, height = 6, dpi = 300)
  }
} else {
  # If not reproducing, include existing coefficient heatmap image in report.
  knitr::include_graphics("../sims/tmprl_multinom_model_coeffs_heatmap.png")
}
