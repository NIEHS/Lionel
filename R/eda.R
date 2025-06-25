# eda
# functions: nutrient map(), chem_bar_chart(), top_nutrients_maps

###---------------------------------------------------------------------------------------------------------

nutrient_map <- function(file, crs_column) {
  # change the crs entry within the crs column of the dataset to epsg codes right away
  crs_to_epsg <- list(
    "NAD83" = 4269,
    "NAD27" = 4267,
    "WAKE" = 4733,
    "WGS84" = 4326
  )

  # ensure crs_column is a character vector
  file[[crs_column]] <- as.character(file[[crs_column]])

  # sum(is.na(file$Latitude))
  # [1] 0
  # > sum(is.na(file$Longitude))
  # [1] 0
  # going to assign the NAD83 epsg to all blank and UNKWN columns within the crs_column
  file[[crs_column]][
    file[[crs_column]] == "" | file[[crs_column]] == "UNKWN"
  ] <- "NAD83"
  # sum(is.na(file$CoordReferenceSys))
  # [1] 0

  # convert list to vector without changing naming
  lookup <- setNames(unlist(crs_to_epsg), names(crs_to_epsg))

  # change crs_column entries from "NAD27"to 4267, for example
  # rename crs_column to crs_epsg
  file$crs_epsg <- lookup[file[[crs_column]]]

  # create smaller data frames by crs_espg so objects can be tranformed in sf separately
  split_by_crs <- split(file, file$crs_epsg)

  # individually create sf objects by crs
  # lapply() ensures that each unique data frame within split_by_crs is passed through the function
  sf_list <- lapply(
    names(split_by_crs),
    function(crs_epsg) {
      #check for invalid or unmapped crs_column entries
      if (is.na(crs_epsg) || crs_epsg == "") {
        warning("Skipping group with missing or unknown CRS")
        return(NULL)
      }

      # within split_by_crs, grab all rows for first crs_epsg entry passed through the loop
      grouped_by_crs <- split_by_crs[[crs_epsg]]

      # lat, long, and crs used to create sf spatial object for the first crs_epsg entry passed
      # use as.integer because names(split_by_crs) returns character strings, st_as_sf() requires integers
      st_as_sf(
        grouped_by_crs,
        coords = c("Longitude", "Latitude"),
        crs = as.integer(crs_epsg),
        remove = FALSE
      )
    }
  )

  # remove NULL entries to prevent error when combining data frames again
  # if input is not NULL, Negate(is.null) will return TRUE and remove if FALSE
  sf_list <- Filter(Negate(is.null), sf_list)

  # for each unique epsg, transfrom to epsg code 4269
  sf_list_with_epsg <- lapply(sf_list, function(x) {
    st_transform(x, crs = 4269)
  })

  # combines the sf objects
  station_coordinates <- do.call(rbind, sf_list_with_epsg) %>%
    st_transform(crs = 4269)

  write.csv(
    st_drop_geometry(station_coordinates),
    file = "inst/visualize/sf_list.csv",
    row.names = FALSE
  )

  "inst/visualize/sf_list.csv"

  # obtain AL polygon
  us_states <- rnaturalearth::ne_states(
    country = "United States of America",
    returnclass = "sf"
  )
  se <- us_states %>%
    dplyr::filter(
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

  # assign each point to a state using spatial join tool
  joined_station_se <- st_join(station_coordinates, se["name"]) %>%
    rename(state = name) %>%
    st_drop_geometry()

  write.csv(
    joined_station_se,
    file = "inst/visualize/nutrient_data_with_state.csv",
    row.names = FALSE
  )

  "inst/visualize/nutrient_data_with_state.csv" # this file has 142,467 rows whereas "file" (nutrient_data_join.csv) has 142,966

  station_coordinates$ChemName <- forcats::fct_lump(
    station_coordinates$ChemName,
    n = 7
  )

  se_bbox <- st_bbox(se)

  # create the map
  se_nutrients_map <- ggplot() +
    geom_sf(data = se, fill = "white", color = "black") +
    geom_sf(
      data = station_coordinates,
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
    labs(title = "WQP Results by Chemical Name")

  ggsave(
    "inst/figs/se_nutrients_map.png",
    plot = se_nutrients_map,
    width = 11,
    height = 8
  )

  "inst/figs/se_nutrients_map.png"
}

###---------------------------------------------------------------------------------------------------------

chem_bar_chart <- function(file) {
  file_sample_year <- read_csv(file) %>%
    mutate(year = year(SampleDate))

  file_sample_year$ChemName <- forcats::fct_lump(
    file_sample_year$ChemName,
    n = 7
  )

  chem_bar_chart_plot <- ggplot(
    file_sample_year,
    aes(x = factor(year), fill = ChemName)
  ) +
    geom_bar(position = "stack") +
    facet_wrap(~state, scale = "free_x") +
    labs(
      title = "Distribution of Sample Chemical Type Collected within a Year by State",
      x = "Sample Year",
      y = "Number of Samples",
      fill = "Chemical"
    ) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 75, hjust = 1),
      legend.key.size = unit(0.5, "cm")
    )

  ggsave(
    "inst/figs/chem_bar_chart.png",
    plot = chem_bar_chart_plot,
    width = 11,
    height = 8
  )

  "inst/figs/chem_bar_chart.png"
}

###---------------------------------------------------------------------------------------------------------

top_nutrients_maps <- function(file) {
  data <- read_csv(file)

  split_by_crs <- split(data, data$crs_epsg)

  # individually create sf objects by crs
  # lapply() ensures that each unique data frame within split_by_crs is passed through the function
  sf_list <- lapply(
    names(split_by_crs),
    function(crs_epsg) {
      #check for invalid or unmapped crs_column entries
      if (is.na(crs_epsg) || crs_epsg == "") {
        warning("Skipping group with missing or unknown CRS")
        return(NULL)
      }

      # within split_by_crs, grab all rows for first crs_epsg entry passed through the loop
      grouped_by_crs <- split_by_crs[[crs_epsg]]

      # lat, long, and crs used to create sf spatial object for the first crs_epsg entry passed
      # use as.integer because names(split_by_crs) returns character strings, st_as_sf() requires integers
      st_as_sf(
        grouped_by_crs,
        coords = c("Longitude", "Latitude"),
        crs = as.integer(crs_epsg)
      )
    }
  )

  # remove NULL entries to prevent error when combining data frames again
  # if input is not NULL, Negate(is.null) will return TRUE and remove if FALSE
  sf_list <- Filter(Negate(is.null), sf_list)

  # for each unique epsg, transfrom to epsg code 4269
  sf_list_with_epsg <- lapply(sf_list, function(x) {
    st_transform(x, crs = 4269)
  })

  # combines the sf objects
  station_coordinates <- do.call(rbind, sf_list_with_epsg) %>%
    st_transform(crs = 4269)

  us_states <- rnaturalearth::ne_states(
    country = "United States of America",
    returnclass = "sf"
  )
  se <- us_states %>%
    dplyr::filter(
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

  station_coordinates$ChemName <- forcats::fct_lump(
    station_coordinates$ChemName,
    n = 7
  )

  se_bbox <- st_bbox(se)

  # create the map
  se_top_nutrients_maps <- ggplot() +
    geom_sf(data = se, fill = "white", color = "black") +
    geom_sf(
      data = station_coordinates,
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
    "inst/figs/se_top_nutrients_maps.png",
    plot = se_top_nutrients_maps,
    width = 11,
    height = 8
  )

  "inst/figs/se_top_nutrients_maps.png"
}
