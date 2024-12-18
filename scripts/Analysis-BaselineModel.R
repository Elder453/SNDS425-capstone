# ===========================
# Script: Analysis-ModelBaseline.R
# Purpose: Fit and evaluate a baseline multinomial logistic regression model.
# ===========================


# ---------------------------
# Data Preparation
# ---------------------------

# Standardize continuous predictors to ensure they are on the same scale.
standardized_predictors <- scale(data.frame(
  PC1 = pca_bands$x[, 1],                    # First PC
  PC2 = pca_bands$x[, 2],                    # Second PC
  NDVI = monthly_clean$ndvi,                 # NDVI
  Elevation = monthly_clean$elevation_meters # Elevation
))

# Construct the final dataset
model_data <- data.frame(
  standardized_predictors,                          # Std continuous predictors
  Season = factor(monthly_clean$season),            # Temporal feature: Season
  Veg = factor(monthly_clean$veg),                  # Vegetation indicator
  EastWest = factor(monthly_clean$east_west),       # Spatial: East/West
  NorthSouth = factor(monthly_clean$north_south),   # Spatial: North/South
  Outcome = monthly_clean$dominant_landcover        # Target: Land Cover Class
)


# ---------------------------
# Multinomial Logistic Regression Model Training
# ---------------------------

if (REPRODUCE) {
  
  # Fit the multinomial logistic regression model
  # Outcome is predicted by all other variables in `model_data`.
  logistic_model <- multinom(Outcome ~ ., data = model_data)
  
  # Save the trained model to disk if the SAVE flag is set to TRUE.
  if (SAVE) {
    saveRDS(logistic_model, "../sims/log_model.RDS")
  }
} else {
  # If not reproducing, load the existing trained model from disk.
  logistic_model <- readRDS("../sims/log_model.RDS")
}


# ---------------------------
# Model Evaluation
# ---------------------------

if (REPRODUCE) {
  set.seed(425)
  
  # Generate predictions on the training data using the trained model.
  predictions <- predict(logistic_model, model_data)  # Predicted classes
  true_labels <- model_data$Outcome                   # True labels
  
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
  
  # Extract coefficients from the trained multinom model.
  coefficients <- summary(logistic_model)$coefficients
  
  coef_long <- as.data.frame(coefficients) |>
    rownames_to_column("Predictor") |>
    pivot_longer(-Predictor, names_to = "Class", values_to = "Coefficient")
  
  # Create heatmap to visualize the coefficients for each predictor and class.
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
    ggsave("../sims/multinom_model_coeffs_heatmap.png", 
           plot = p, width = 8, height = 6, dpi = 300)
  }
} else {
  # If not reproducing, include the existing coefficient heatmap image in report
  knitr::include_graphics("../sims/multinom_model_coeffs_heatmap.png")
}