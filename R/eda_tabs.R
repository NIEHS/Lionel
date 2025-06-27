# eda
# functions: nutrient map(), chem_bar_chart(), top_nutrients_maps

###---------------------------------------------------------------------------------------------------------

modify_nutrient_data_join <- function(data, crs_column) {
  # create a vector associating each crs with an epsg
  crs_to_epsg <- c(
    "NAD83" = 4269,
    "NAD27" = 4267,
    "WAKE" = 4733,
    "WGS84" = 4326
  )

  # clean crs column and convert each blank or unknown crs to NAD83
  data <- data %>%
    mutate(
      {{ crs_column }} := as.character({{ crs_column }}),
      {{ crs_column }} := if.else(
        {{ crs_column }} == "" | {{ crs_column }} == "UNKWN",
        "NAD83",
        {{ crs_column }}
      ),
      crs_epsg = crs_to_epsg[.data[[as.string(ensym(crs_column))]]]
    )

  # separate data by epsg code and convert each lat/long to sf
  sf_list <- data %>%
    split(.$crs_epsg) %>%
    imap(
      ~ {
        if (is.na(.y) || .y == "") {
          warning("Skipping group with missing or unknown crs")
          return(NULL)
        }

        st_as_sf(
          .x,
          coords = c("Longitude", "Latitude"),
          crs = as.integer(.y),
          remove = FALSE
        )
      }
    ) %>%
    compact() %>%
    map(~ st_transform(.x, crs = 4269))

  # combine the sf data to one object
  stations <- bind_rows(sf_list)

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

  # assign each point to a state using spatial join tool
  # this table has 142,467 rows whereas data (nutrient_data_join) has 142,966
  se_stations <- stations %>%
    st_join(se["name"]) %>%
    rename(state = name) %>%
    st_drop_geometry

  ###---------------------------------------------------------------------------------------------------------

  # write file containing the same data as the object nutrient_data_join, but only with rows that can be converted to sf and
  # spatially joined to a state (aka this data has an additional column "state")
  write.csv(
    se_stations,
    file = "inst/visualize/se_stations.csv",
    row.names = FALSE
  )

  "inst/visualize/se_stations.csv"
}

###---------------------------------------------------------------------------------------------------------

map_se_nutrients <- function(data, crs_column) {
  # create a vector associating each crs with an epsg
  crs_to_epsg <- c(
    "NAD83" = 4269,
    "NAD27" = 4267,
    "WAKE" = 4733,
    "WGS84" = 4326
  )

  # clean crs column and convert each blank or unknown crs to NAD83
  data <- data %>%
    mutate(
      {{ crs_column }} := as.character({{ crs_column }}),
      {{ crs_column }} := if.else(
        {{ crs_column }} == "" | {{ crs_column }} == "UNKWN",
        "NAD83",
        {{ crs_column }}
      ),
      crs_epsg = crs_to_epsg[.data[[as.string(ensym(crs_column))]]]
    )

  # separate data by epsg code and convert each lat/long to sf
  sf_list <- data %>%
    split(.$crs_epsg) %>%
    imap(
      ~ {
        if (is.na(.y) || .y == "") {
          warning("Skipping group with missing or unknown crs")
          return(NULL)
        }

        st_as_sf(
          .x,
          coords = c("Longitude", "Latitude"),
          crs = as.integer(.y),
          remove = FALSE
        )
      }
    ) %>%
    compact() %>%
    map(~ st_transform(.x, crs = 4269))

  # combine the sf data to one object
  stations <- bind_rows(sf_list) %>%
    mutate(ChemName = fct_lump(ChemName, n = 7))

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
  se_nutrients_map <- ggplot() +
    geom_sf(data = se, fill = "white", color = "black") +
    geom_sf(
      data = stations,
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
    labs(title = "All WQP Nutrients across Southeastern United States")

  ggsave(
    "inst/figs/se_nutrients_map.png",
    plot = se_nutrients_map,
    width = 11,
    height = 8
  )

  "inst/figs/se_nutrients_map.png"
}

###---------------------------------------------------------------------------------------------------------

barchart_nutrients <- function(data) {
  data <- data %>%
    mutate(year = year(SampleDate), ChemName = fct_lump(ChemName, n = 7))

  se_nutrients_barchart <- ggplot(
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
    "inst/figs/se_nutrients_barchart.png",
    plot = se_nutrients_barchart,
    width = 11,
    height = 8
  )

  "inst/figs/se_nutrients_barchart.png"
}

###---------------------------------------------------------------------------------------------------------

plot_top_7_se_nutrients <- function(data) {
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

###---------------------------------------------------------------------------------------------------------

all_chem_bar_chart <- function(file) {
  file_sample_year <- read_csv(file) %>%
    mutate(year = year(SampleDate))

  chem_bar_chart_plot <- ggplot(
    file_sample_year,
    aes(x = factor(year), fill = ChemName)
  ) +
    geom_bar(position = "stack") +
    labs(
      title = "Distribution of Sample Chemical Type Collected for each Year",
      x = "Sample Year",
      y = "Number of Samples",
      fill = "Chemical"
    ) +
    theme_minimal() +
    theme(
      axis.text.x = element_text(angle = 75, hjust = 1),
      legend.key.size = unit(0.5, "cm")
    ) +
    guides(fill = guide_legend(ncol = 1))

  ggsave(
    "inst/figs/all_chem_bar_chart.png",
    plot = chem_bar_chart_plot,
    width = 11,
    height = 8
  )

  "inst/figs/all_chem_bar_chart.png"
}
