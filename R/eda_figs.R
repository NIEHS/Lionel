# eda
# functions: map_se_stations(), barchart_sampling_by_state(), map_nutrient_sampling(), barchart_all_nutrients()

###---------------------------------------------------------------------------------------------------------

map_se_stations <- function(data) {
  data_sf <- data %>%
    st_as_sf(
      coords = c("Longitude", "Latitude"),
      crs = 4269,
      remove = FALSE
    )

  se <- rnaturalearth::ne_states(
    country = "United States of America",
    returnclass = "sf"
  ) %>%
    filter(
      name %in%
        c(
          "Alabama",
          "Florida",
          "Georgia",
          "North Carolina",
          "South Carolina",
          "Mississippi",
          "Tennessee"
        )
    ) %>%
    st_transform(crs = 4269)

  se_bbox <- st_bbox(se)

  # create the map
  se_stations_map <- ggplot() +
    geom_sf(data = se, fill = "white", color = "black") +
    geom_sf(
      data = data_sf,
      aes(color = ChemName),
      size = 0.5,
      alpha = 0.8
    ) +
    coord_sf(
      crs = 4269,
      xlim = c(se_bbox["xmin"], se_bbox["xmax"]),
      ylim = c(se_bbox["ymin"], se_bbox["ymax"])
    ) +
    theme_minimal() +
    theme(legend.key.size = unit(0.5, "cm")) +
    labs(
      title = "Nitrate, Nitrite, Orthophosphate, and Ammonia and Ammonium Sampled from WQP Stations across Southeastern United States"
    )

  ggsave(
    "inst/figs/se_stations_map.png",
    plot = se_stations_map,
    width = 11,
    height = 8
  )

  "inst/figs/se_stations_map.png"
}

###---------------------------------------------------------------------------------------------------------

barchart_sampling_by_state <- function(data) {
  data_sampling_years <- data %>%
    mutate(year = year(SampleDate))

  se_nutrients_barchart <- ggplot(
    data_sampling_years,
    aes(x = factor(year), fill = ChemName)
  ) +
    geom_bar(position = "stack") +
    facet_wrap(~state, scale = "free_x") +
    labs(
      title = "Yearly Nutrient Sampling Frequency by State",
      x = "Sample Year",
      y = "Number of Samples",
      fill = "Nutrient"
    ) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 75, hjust = 1),
      legend.key.size = unit(0.5, "cm")
    )

  ggsave(
    "inst/figs/sampling_by_state_barchart.png",
    plot = se_nutrients_barchart,
    width = 11,
    height = 8
  )

  "inst/figs/sampling_by_state_barchart.png"
}

###---------------------------------------------------------------------------------------------------------

map_nutrient_sampling <- function(data) {
  data_sf <- data %>%
    st_as_sf(
      coords = c("Longitude", "Latitude"),
      crs = 4269,
      remove = FALSE
    )

  se <- rnaturalearth::ne_states(
    country = "United States of America",
    returnclass = "sf"
  ) %>%
    filter(
      name %in%
        c(
          "Alabama",
          "Florida",
          "Georgia",
          "North Carolina",
          "South Carolina",
          "Mississippi",
          "Tennessee"
        )
    ) %>%
    st_transform(crs = 4269)

  se_bbox <- st_bbox(se)

  # create the map
  nutrient_sampling_maps <- ggplot() +
    geom_sf(data = se, fill = "white", color = "black") +
    geom_sf(
      data = data_sf,
      aes(color = ChemName),
      size = 0.3,
      alpha = 0.2
    ) +
    facet_wrap(~ChemName) +
    coord_sf(
      crs = 4269,
      xlim = c(se_bbox["xmin"], se_bbox["xmax"]),
      ylim = c(se_bbox["ymin"], se_bbox["ymax"])
    ) +
    theme_minimal() +
    theme(legend.position = "none") +
    labs(title = "Nutrients Sampled in Southeastern US")

  ggsave(
    "inst/figs/nutrient_sampling_maps.png",
    plot = nutrient_sampling_maps,
    width = 11,
    height = 8
  )

  "inst/figs/nutrient_sampling_maps.png"
}

###---------------------------------------------------------------------------------------------------------

barchart_all_nutrients <- function(data) {
  data_sampling_years <- data %>%
    mutate(year = year(SampleDate))

  all_nutrient_barchart <- ggplot(
    data_sampling_years,
    aes(x = factor(year), fill = ChemName)
  ) +
    geom_bar(position = "stack") +
    labs(
      title = "Yearly Nutrient Sampling Frequency",
      x = "Sample Year",
      y = "Sampling Frequency",
      fill = "Nutrient"
    ) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 75, hjust = 1),
      legend.key.size = unit(0.5, "cm")
    ) +
    guides(fill = guide_legend(ncol = 1))

  ggsave(
    "inst/figs/all_nutrient_barchart.png",
    plot = all_nutrient_barchart,
    width = 11,
    height = 8
  )

  "inst/figs/all_nutrient_barchart.png"
}

###---------------------------------------------------------------------------------------------------------
