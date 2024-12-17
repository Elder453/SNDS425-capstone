# ===========================
# Script: PCA.R
# Purpose: Perform PCA on spectral bands and generate a Scree Plot.
# ===========================

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
