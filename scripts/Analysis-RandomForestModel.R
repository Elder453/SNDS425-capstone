# ===========================
# Script: Analysis-ModelRandomForest.R
# Purpose: Train a Random Forest model, tune hyperparameters, and evaluate performance.
# ===========================

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
