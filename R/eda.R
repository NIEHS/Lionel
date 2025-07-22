

###---------------------------------------------------------------------------------------------------------

map_locations <- function(sf_nutrients, sf_states) {
  se_bbox <- st_bbox(sf_states)

  # create the map
  locations_map <- ggplot() +
    geom_sf(data = sf_states, fill = "white", color = "black") +
    geom_sf(
      data = sf_nutrients,
      aes(color = nutrient),
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
      title = "Clean Nutrient Data across Southeastern United States"
    )

  ggsave(
    "inst/figs/locations_map.png",
    plot = locations_map,
    width = 11,
    height = 8,
    bg = "white"
  )

  "inst/figs/locations_map.png"
}

###---------------------------------------------------------------------------------------------------------

barchart_nutrients_by_state <- function(data) {
  state_nutrients_barchart <- ggplot(
    data,
    aes(x = sample_year, fill = nutrient)
  ) +
    geom_bar(position = "stack") +
    facet_wrap(~state_code, scales = "free_x") +
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
    "inst/figs/state_nutrients_barchart.png",
    plot = state_nutrients_barchart,
    width = 11,
    height = 8,
    bg = "white"
  )

  "inst/figs/state_nutrients_barchart.png"
}

###---------------------------------------------------------------------------------------------------------

map_nutrients <- function(nutrient_locations, southeast) {
  se_bbox <- st_bbox(southeast)

  # create the map
  nutrients_maps <- ggplot() +
    geom_sf(data = southeast, fill = "white", color = "black") +
    geom_sf(
      data = nutrient_locations,
      aes(color = nutrient),
      size = 0.3,
      alpha = 0.2
    ) +
    facet_wrap(~nutrient) +
    coord_sf(
      crs = 4269,
      xlim = c(se_bbox["xmin"], se_bbox["xmax"]),
      ylim = c(se_bbox["ymin"], se_bbox["ymax"])
    ) +
    theme_minimal() +
    theme(legend.position = "none") +
    labs(title = "Nutrients Sampled in Southeastern US")

  ggsave(
    "inst/figs/nutrients_maps.png",
    plot = nutrients_maps,
    width = 11,
    height = 8,
    bg = "white"
  )

  "inst/figs/nutrients_maps.png"
}

###---------------------------------------------------------------------------------------------------------

barchart_nutrients <- function(data) {
  nutrients_barchart <- ggplot(
    data,
    aes(x = sample_year, fill = nutrient)
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
    "inst/figs/nutrients_barchart.png",
    plot = nutrients_barchart,
    width = 11,
    height = 8,
    bg = "white"
  )

  "inst/figs/nutrients_barchart.png"
}

###---------------------------------------------------------------------------------------------------------
