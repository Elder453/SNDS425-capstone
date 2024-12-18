# ===========================
# Script: Analysis-ModelRandomForest.R
# Purpose: Train a Random Forest model, tune hyperparameters, and evaluate performance.
# ===========================

# ---------------------------
# Random Forest Model Training and Hyperparameter Tuning
# ---------------------------
if (REPRODUCE) {
  
  # Define the hyperparameter grid for tuning
  num_trees_list <- c(50, 100)          # Number of trees
  mtry_list <- c(2, 4, 6)               # Number of predictors sampled at each split
  max_depth_list <- c(10, 15, 20)       # Maximum depth of trees
  
  # Create a data frame to store results
  results <- expand.grid(num_trees = num_trees_list,
                         mtry = mtry_list,
                         max_depth = max_depth_list,
                         OOB_error = NA)
  
  # Loop through hyperparameters and fit models
  for (i in 1:nrow(results)) {
    set.seed(425)  # Ensure reproducibility
    
    # Train the Random Forest model with the current set of hyperparameters
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
  if (SAVE) {
    # Save the hyperparameter tuning results if SAVE flag is TRUE
    saveRDS(results, "../sims/rf_results.RDS")
  }
  
  # Identify the best hyperparameter combination based on the lowest OOB error
  set.seed(425)
  best_params <- results[which.min(results$OOB_error), ]
  
  # Train the final Random Forest model using the best hyperparameters
  rf_model <- ranger(Outcome ~ ., 
                     data = model_data, 
                     num.trees = best_params$num_trees, 
                     importance = "impurity", 
                     mtry = best_params$mtry,
                     max.depth = best_params$max_depth)
  
  # Save the final Random Forest model if SAVE flag is TRUE
  if (SAVE) {
    saveRDS(rf_model, "../sims/rf_model.RDS")
  }
} else {
  # If not reproducing, load the existing tuning results and trained model
  results <- readRDS("../sims/rf_results.RDS")
  rf_model <- readRDS("../sims/rf_model.RDS")
}


# ---------------------------
# Model Evaluation
# ---------------------------

if (REPRODUCE) {
  
  # Generate predictions on the training data using the trained RF
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
  
  # Combine class-wise metrics with macro-averaged metrics into a results table
  (results_table <- rf_metrics |> 
      rbind(macro_avg_rf))
}


# ---------------------------
# Variable Importance Analysis
# ---------------------------

# Extract variable importance from the trained Random Forest model
importance <- rf_model$variable.importance

importance_df <- data.frame(
  Variable = names(importance),
  Importance = importance
)

# Order the data frame by descending importance
importance_df <- importance_df[order(-importance_df$Importance), ]

# Plot Variable Importance using a horizontal bar chart
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
