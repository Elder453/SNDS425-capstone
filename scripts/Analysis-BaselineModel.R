# ===========================
# Script: Analysis-ModelBaseline.R
# Purpose: Fit and evaluate a baseline multinomial logistic regression model.
# ===========================

# Standardize continuous predictors
standardized_predictors <- scale(data.frame(
  PC1 = pca_bands$x[, 1],                    # First PC
  PC2 = pca_bands$x[, 2],                    # Second PC
  NDVI = monthly_clean$ndvi,                 # NDVI
  Elevation = monthly_clean$elevation_meters # Elevation
))

# Construct the final dataset in a single step
model_data <- data.frame(
  standardized_predictors,                          # Std continuous predictors
  Season = factor(monthly_clean$season),            # Temporal feature: Season
  Veg = factor(monthly_clean$veg),                  # Vegetation indicator
  EastWest = factor(monthly_clean$east_west),       # Spatial: East/West
  NorthSouth = factor(monthly_clean$north_south),   # Spatial: North/South
  Outcome = monthly_clean$dominant_landcover        # Target: Land Cover Class
)

if (REPRODUCE) {
  # Fit multinomial logistic regression
  logistic_model <- multinom(Outcome ~ ., data = model_data)
  if (SAVE) {
    saveRDS(logistic_model, "../sims/log_model.RDS")
  }
} else {
  logistic_model <- readRDS("../sims/log_model.RDS")
}

if (REPRODUCE) {
  set.seed(425)
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
  
  (results_table <- class_metrics |> 
      rbind(macro_avg))
}

if (REPRODUCE) {
  # Extract coefficients
  coefficients <- summary(logistic_model)$coefficients
  
  coef_long <- as.data.frame(coefficients) |>
    rownames_to_column("Predictor") |>
    pivot_longer(-Predictor, names_to = "Class", values_to = "Coefficient")
  
  # Create heatmap
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
  
  if (SAVE) {
    ggsave("../sims/multinom_model_coeffs_heatmap.png", 
           plot = p, width = 8, height = 6, dpi = 300)
  }
} else {
  knitr::include_graphics("../sims/multinom_model_coeffs_heatmap.png")
}