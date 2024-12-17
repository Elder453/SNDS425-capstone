# ExploreData.R
# Purpose: Explore and visualize the data

# Load prepared data
monthly_clean <- readRDS("Data.rds")

# ---- Outcome Variable Exploration ----
if (REPRODUCE) {
  # Calculate counts and proportions
  landcover_summary <- monthly_clean |>
    count(dominant_landcover) |>
    mutate(prop = n / sum(n),
           label = scales::percent(prop))
  
  # Plot the ordered bar chart
  (p <- ggplot(landcover_summary, 
               aes(x = reorder(dominant_landcover, n), 
                   y = n, 
                   fill = dominant_landcover)
  ) +
      geom_bar(stat = "identity", width = 0.7) +
      geom_text(aes(label = label), vjust = -0.5, size = 3.5) +
      theme_pub() +
      labs(title = "Distribution of Land Cover Classes",
           x = "Land Cover Class", y = "Count") +
      scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
      theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
            legend.position = "none"))
  if (SAVE) {
    ggsave("../sims/landcover_distribution.png",
           plot = p,
           width = 8,
           height = 4,
           dpi = 300)
  }
} else {
  knitr::include_graphics("../sims/landcover_distribution.png")
}

# ---- NDVI Analysis ----
if (REPRODUCE) {
  (p <- ggplot(monthly_clean, 
               aes(x = dominant_landcover, y = ndvi, fill = dominant_landcover)
               ) +
     geom_boxplot() +
     theme_pub() +
     labs(title = "Distribution of NDVI by Land Cover Class",
          x = "Land Cover Class", y = "NDVI") +
     theme(axis.text.x = element_text(size = 8)))
  
  if (SAVE) {
    ggsave("../sims/ndvi_boxplot.png",
           plot = p, width = 8, height = 4, dpi = 300)
  }
} else {
  knitr::include_graphics("../sims/ndvi_boxplot.png")
}

# ---- Spectral Bands Exploration ----
if (REPRODUCE) {
  long_data <- monthly_clean |>
    pivot_longer(cols = starts_with("sr_b"), 
                 names_to = "spectral_band", 
                 values_to = "value")
  
  (p <- ggplot(long_data, 
               aes(x = dominant_landcover, 
                   y = value, 
                   fill = dominant_landcover)) +
      geom_boxplot() +
      theme_pub() +
      labs(title = "Distribution of Spectral Bands by Land Cover Class",
           x = "Land Cover Class", y = "Spectral Band Value") +
      facet_wrap(~spectral_band, scales = "free_y") +
      theme(axis.text.x = element_text(size = 8, angle = 45, hjust = 1)))
  
  if (SAVE) {
    ggsave("../sims/spectral_bands_boxplot.png",
           plot = p, width = 8, height = 6, dpi = 300)
  }
} else {
  knitr::include_graphics("../sims/spectral_bands_boxplot.png")
}

# ---- Temporal Features Exploration: NDVI ----
if (REPRODUCE) {
  (p <- ggplot(monthly_clean, 
               aes(x = month, 
                   y = ndvi, 
                   color = dominant_landcover, 
                   group = dominant_landcover)
               ) +
     geom_line(stat = "summary", fun = "mean") +
     theme_pub() +
     labs(title = "Monthly Trends in NDVI",
          x = "Month", y = "Mean NDVI"))
  
  if (SAVE) {
    ggsave("../sims/ndvi_monthly.png",
           plot = p, width = 8, height = 3.5, dpi = 300)
  }
  
  (p <- ggplot(monthly_clean, 
               aes(x = season, 
                   y = ndvi, 
                   color = dominant_landcover, 
                   group = dominant_landcover)
  ) +
      geom_line(stat = "summary", fun = "mean") +
      theme_pub() +
      labs(title = "Seasonal Trends in NDVI",
           x = "Season", y = "Mean NDVI"))
  
  if (SAVE) {
    ggsave("../sims/ndvi_seasonal.png",
           plot = p, width = 8, height = 3.5, dpi = 300)
  }
} else {
  knitr::include_graphics("../sims/ndvi_monthly.png")
  knitr::include_graphics("../sims/ndvi_seasonal.png")
}

if (REPRODUCE) {
  (p <- ggplot(monthly_clean, 
               aes(x = year, 
                   y = ndvi, 
                   color = dominant_landcover, 
                   group = dominant_landcover)
  ) +
    geom_line(stat = "summary", fun = "mean") +
    theme_pub() +
    labs(title = "Yearly Trends in NDVI",
         x = "Year", y = "Mean NDVI") +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)))
  
  if (SAVE) {
    ggsave("../sims/ndvi_yearly.png",
           plot = p, width = 8, height = 4, dpi = 300)
  }
} else {
  knitr::include_graphics("../sims/ndvi_yearly.png")
}

# ---- Temporal Features Exploration: Spectral Bands ----
if (REPRODUCE) {
  (p <- ggplot(long_data, 
               aes(x = season, 
                   y = value, 
                   color = dominant_landcover, 
                   group = dominant_landcover)
  ) +
    geom_line(stat = "summary", fun = "mean", linewidth = 1) +
    theme_pub() +
    labs(title = "Seasonal Trends in Spectral Bands by Land Cover Class",
         x = "Season", y = "Mean Value") +
    facet_wrap(~spectral_band, scales = "free_y") +
    theme(
      axis.text.x = element_text(size = 10, angle = 45, hjust = 1),
      strip.text = element_text(size = 10, face = "bold")
    ) +
    # reduce y-axis ticks
    scale_y_continuous(breaks = scales::pretty_breaks(n = 3)))
  
  if (SAVE) {
    ggsave("../sims/spectral_bands_seasonal.png",
           plot = p, width = 8, height = 5, dpi = 300)
  }
} else {
  knitr::include_graphics("../sims/spectral_bands_seasonal.png")
}

if (REPRODUCE) {
  (p <- ggplot(long_data, 
               aes(x = year, 
                   y = value, 
                   color = dominant_landcover, 
                   group = dominant_landcover)
  ) +
    geom_line(stat = "summary", fun = "mean", linewidth = 1) +
    theme_pub() +
    labs(title = "Yearly Trends in Spectral Bands by Land Cover Class",
         x = "Year", y = "Mean Value") +
    facet_wrap(~ spectral_band, scales = "free_y") +
    theme(
      axis.text.x = element_text(size = 6, angle = 90),
      strip.text = element_text(size = 10, face = "bold")
    ) +
    scale_y_continuous(breaks = scales::pretty_breaks(n = 3)))
  
  if (SAVE) {
    ggsave("../sims/spectral_bands_yearly.png",
           plot = p, width = 8, height = 5, dpi = 300)
  }
} else {
  knitr::include_graphics("../sims/spectral_bands_yearly.png")
}

# ---- Spatial Distribution of NDVI ----
if (REPRODUCE) {
  (p <- ggplot(monthly_clean |> filter(year == 2010), 
               aes(x = lon, y = lat, color = ndvi)
  ) +
    geom_point(size = 0.5, alpha = 0.7) +
    theme_pub() +
    labs(title = "Spatial Distribution of NDVI",
         x = "Longitude", y = "Latitude", color = "NDVI") +
    theme(legend.position = "none"))
  
  if (SAVE) {
    ggsave("../sims/ndvi_spatial.png",
           plot = p, width = 8, height = 3.75, dpi = 300)
  }
} else {
  knitr::include_graphics("../sims/ndvi_spatial.png")
}

# ---- Spatial Distribution of Spectral Bands ----
if (REPRODUCE) {
  (p <- ggplot(long_data |> filter(year == 2010), 
               aes(x = lon, y = lat, color = value)
  ) +
    geom_point(size = 0.5, alpha = 0.9) +
    theme_pub() +
    labs(
      title = "Spatial Distribution of Spectral Bands",
      x = "Longitude", y = "Latitude", color = "Value"
    ) +
    facet_wrap(~spectral_band, scales = "free") +
    theme(
      axis.text.x = element_text(size = 8),
      axis.text.y = element_text(size = 8),
      strip.text = element_text(size = 10, face = "bold"),
      legend.position = "none")
  )
  
  if (SAVE) {
    ggsave("../sims/spectral_bands_spatial.png",
           plot = p, width = 8, height = 4.5, dpi = 300)
  }
} else {
  knitr::include_graphics("../sims/spectral_bands_spatial.png")
}

# ---- Correlation Matrix ----
if (REPRODUCE) {
  correlation_matrix <- cor(monthly_clean[, c(
    "sr_b1", 
    "sr_b2", 
    "sr_b3", 
    "sr_b4",
    "sr_b5",
    "sr_b7",
    "ndvi",
    "elevation_meters",
    "lat",
    "lon")], use = "complete.obs")
  
  # correlation matrix
  (p <- ggcorrplot(correlation_matrix, 
                   type = "upper",
                   lab = TRUE,
                   lab_size = 3,
                   colors = c("darkred", "white", "darkgreen"),
                   outline.color = "black",
                   legend.title = "Correlation",
                   title = "Correlation Matrix of Continuous Predictors") +
      theme_pub() +
      theme(
        plot.title = element_text(size = 16, face = "bold", hjust = 0.5),
        legend.text = element_text(size = 8),
        legend.title = element_text(size = 12, face = "bold"),
        axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
        axis.text.y = element_text(size = 10),
        axis.title.x=element_blank(), 
        axis.title.y=element_blank()
      ))
  
  if (SAVE) {
    ggsave("../sims/correlation_matrix.png", 
           plot = p, width = 8, height = 6, dpi = 300)
  }
} else {
  knitr::include_graphics("../sims/correlation_matrix.png")
}

# ---- Elevation Distribution Across Land Cover Classes ----
ggplot(monthly_clean, 
       aes(x = dominant_landcover, 
           y = elevation_meters, 
           fill = dominant_landcover)
       ) +
  geom_boxplot(outlier.size = 0.5) +
  theme_pub() +
  labs(
    title = "Elevation Distribution Across Land Cover Classes",
    x = "Land Cover Class", y = "Elevation (meters)"
  ) +
  theme(axis.text.x = element_text(size = 8, angle = 45, hjust = 1),
        legend.position = "none")
