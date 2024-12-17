# Analysis.R
# Purpose: Build models, evaluate performance, and interpret results

# Load prepared data
monthly_clean <- readRDS("Data.rds")

# ---- PCA & Scree Plot ----
# Feature selection: Use PCA to reduce multicollinearity
pca_bands <- prcomp(
  monthly_clean[, c("sr_b1", "sr_b2", "sr_b3", "sr_b4", "sr_b5", "sr_b7")],
  center = TRUE,
  scale. = TRUE)

# Variance Explained
pca_var <- pca_bands$sdev^2                  # Eigenvalues of each PC
pca_var_explained <- pca_var / sum(pca_var)  # Proportion of variance

# DataFrame for Plotting
pca_df <- data.frame(
  PC = paste0("PC", 1:length(pca_var)),
  Variance = pca_var_explained
)

# Scree Plot
ggplot(pca_df, aes(x = PC, y = Variance)) +
  geom_col(fill = "steelblue") +
  geom_point(size = 3) +
  geom_line(aes(group = 1), color = "darkred", linetype = "dashed") +
  labs(
    title = "Scree Plot: Variance Explained by Principal Components",
    x = "Principal Component", y = "Proportion of Variance Explained"
  ) +
  theme_pub() +
  scale_y_continuous(breaks = seq(0.05, 1, by = 0.1))

# ---- Baseline Multinomial Logistic Regression Model ----
# Standardize continuous predictors
standardized_predictors <- scale(data.frame(
  PC1 = pca_bands$x[, 1],                    # First PC
  PC2 = pca_bands$x[, 2],                    # Second PC
  NDVI = monthly_clean$ndvi,                 # NDVI
  Elevation = monthly_clean$elevation_meters # Elevation
))

# Construct the final dataset in a single step
model_data <- data.frame(
  standardized_predictors,                          # Standardized continuous predictors
  Season = factor(monthly_clean$season),            # Temporal feature: Season
  Veg = factor(monthly_clean$veg),                  # Vegetation indicator
  EastWest = factor(monthly_clean$east_west),       # Spatial: East/West
  NorthSouth = factor(monthly_clean$north_south),   # Spatial: North/South
  Outcome = monthly_clean$dominant_landcover        # Target: Land Cover Class
)

if (REPRODUCE) {
  # Fit multinomial logistic regression
  logistic_model <- multinom(Outcome ~ ., data = model_data)
  saveRDS(logistic_model, "sims/log_model.RDS")
} else {
  logistic_model <- readRDS("sims/log_model.RDS")
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
      scale_fill_gradient2(low = "darkred", mid = "white", high = "darkgreen", midpoint = 0) +
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
  
  ggsave("sims/multinom_model_coeffs_heatmap.png", plot = p, width = 8, height = 6, dpi = 300)
} else {
  knitr::include_graphics("sims/multinom_model_coeffs_heatmap.png")
}

# ---- Sinusoidal Multinomial Logistic Regression Model ----
ndvi_monthly <- monthly_clean |>
  group_by(month) |>
  summarize(mean_ndvi = mean(ndvi, na.rm = TRUE)) |>
  arrange(month)

ggplot(ndvi_monthly, aes(x = month, y = mean_ndvi)) +
  geom_line(group = 1, color = "darkgreen") +
  geom_point(size = 2, color = "darkred") +
  theme_minimal() +
  labs(title = "Monthly Mean NDVI", x = "Month", y = "Mean NDVI") +
  theme_pub()

if (REPRODUCE) {
  # Subtract mean NDVI to remove DC component
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

# Encode month as a numeric variable (1 = January, ..., 12 = December)
month_numeric <- as.numeric(monthly_clean$month)

# Frequency for annual cycle
freq_month <- 1 / 12

# sine and cosine features
monthly_clean$sin_month <- sin(2 * pi * freq_month * month_numeric)
monthly_clean$cos_month <- cos(2 * pi * freq_month * month_numeric)

# Standardize continuous predictors
standardized_predictors <- scale(data.frame(
  PC1 = pca_bands$x[, 1],                     # First PC
  PC2 = pca_bands$x[, 2],                     # Second PC
  NDVI = monthly_clean$ndvi,                  # NDVI
  Elevation = monthly_clean$elevation_meters, # Elevation
  Sin_Month = monthly_clean$sin_month,        # Sine of month
  Cos_Month = monthly_clean$cos_month         # Cosine of month
))

model_data_tmprl <- data.frame(
  standardized_predictors,                          # Standardized continuous predictors
  Veg = factor(monthly_clean$veg),                  # Vegetation indicator
  EastWest = factor(monthly_clean$east_west),       # Spatial: East/West
  NorthSouth = factor(monthly_clean$north_south),   # Spatial: North/South
  Outcome = monthly_clean$dominant_landcover        # Target: Land Cover Class
)

if (REPRODUCE) {
  # Fit multinomial logistic regression
  logistic_model <- multinom(Outcome ~ ., data = model_data_tmprl)
  saveRDS(logistic_model, "sims/log_model_tmprl_month.RDS")
} else {
  logistic_model <- readRDS("sims/log_model_tmprl_month.RDS")
}

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
      scale_fill_gradient2(low = "darkred", mid = "white", high = "darkgreen", midpoint = 0) +
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
  
  ggsave("sims/tmprl_multinom_model_coeffs_heatmap.png", plot = p, width = 8, height = 6, dpi = 300)
} else {
  knitr::include_graphics("sims/tmprl_multinom_model_coeffs_heatmap.png")
}

# ---- Random Forest Model ----
if (REPRODUCE) {
  # Define the hyperparameter grid
  num_trees_list <- c(50, 100)          # Number of trees
  mtry_list <- c(2, 4, 6)               # Number of predictors sampled at each split
  max_depth_list <- c(10, 15, 20)       # Maximum depth of trees
  
  # Create a data frame to store results
  results <- expand.grid(num_trees = num_trees_list,
                         mtry = mtry_list,
                         max_depth = max_depth_list,
                         OOB_error = NA)
  
  # Loop through hyperparameters and fit models
  for (i in 11:nrow(results)) {
    set.seed(425)  # Ensure reproducibility
    rf_tuned <- ranger(Outcome ~ ., 
                       data = model_data, 
                       num.trees = results$num_trees[i], 
                       mtry = results$mtry[i],
                       max.depth = results$max_depth[i],
                       importance = "impurity",
                       verbose = TRUE)
    
    # Store the OOB error
    results$OOB_error[i] <- rf_tuned$prediction.error
  }
  saveRDS(results, "sims/rf_results.RDS")
  
  set.seed(425)
  best_params <- results[which.min(results$OOB_error), ]
  rf_model <- ranger(Outcome ~ ., 
                     data = model_data, 
                     num.trees = best_params$num_trees, 
                     importance = "impurity", 
                     mtry = best_params$mtry,
                     max.depth = best_params$max_depth)
  saveRDS(rf_model, "sims/rf_model.RDS")
} else {
  results <- readRDS("sims/rf_results.RDS")
  rf_model <- readRDS("sims/rf_model.RDS")
}

if (REPRODUCE) {
  # Predictions
  set.seed(425)
  rf_predictions <- predict(rf_model, data = model_data)$predictions
  true_labels <- model_data$Outcome
  
  # Confusion matrix
  rf_conf_matrix <- confusionMatrix(
    data = factor(rf_predictions, levels = levels(true_labels)),
    reference = factor(true_labels, levels = levels(true_labels))
  )
  
  # Class-wise metrics
  rf_metrics <- as.data.frame(rf_conf_matrix$byClass) |> 
    dplyr::select(Precision, Recall, F1, "Balanced Accuracy")
  
  # Macro-averaged metrics
  macro_avg_rf <- colMeans(rf_metrics)
  
  (results_table <- rf_metrics |> 
      rbind(macro_avg_rf))
}

importance <- rf_model$variable.importance

importance_df <- data.frame(
  Variable = names(importance),
  Importance = importance
)

importance_df <- importance_df[order(-importance_df$Importance), ]

ggplot(importance_df,
       aes(x = reorder(Variable, Importance),
           y = Importance)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  labs(
    title = "Variable Importance",
    x = "Predictor",
    y = "Importance"
  ) +
  theme_pub()
