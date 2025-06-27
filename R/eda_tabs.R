# eda
# functions: get_se_stations_data(), filter_se_stations(), get_unit_data()

###---------------------------------------------------------------------------------------------------------

get_se_stations_data <- function(data, crs_column) {
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
      {{ crs_column }} := ifelse(
        {{ crs_column }} == "" | {{ crs_column }} == "UNKWN",
        "NAD83",
        {{ crs_column }}
      ),
      crs_epsg = crs_to_epsg[.data[[as_name(ensym(crs_column))]]]
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
}

###---------------------------------------------------------------------------------------------------------

filter_se_stations <- function(data) {
  filtered_station_nutrients <- data %>%
    filter(
      ChemName %in%
        c("Nitrate", "Nitrite", "Orthophosphate", "Ammonia and ammonium")
    )
}

###---------------------------------------------------------------------------------------------------------

# the goal for this function is to create a table with counts for the unique units used to measure each nutrient
get_unit_data <- function(data) {
  data <- data %>%
    filter(!is.na(ChemName))

  nutrient_counts <- data %>%
    filter(!is.na(ChemUnit)) %>%
    count(ChemName, ChemUnit) %>%
    pivot_wider(
      names_from = ChemUnit,
      values_from = n,
      values_fill = 0
    )

  invalid_counts <- data %>%
    filter(DetectionCondition == "*Non-detect") %>%
    count(ChemName) %>%
    rename(NonDetect = n)

  table_1 <- nutrient_counts %>%
    left_join(invalid_counts, by = "ChemName") %>%
    mutate(NonDetect = replace_na(NonDetect, 0)) %>%
    rowwise() %>%
    mutate(TOTAL = sum(c_across(where(is.numeric)))) %>%
    ungroup()

  table_2 <- table_1 %>%
    summarise(across(where(is.numeric), sum)) %>%
    mutate(ChemName = "TOTAL") %>%
    select(ChemName, everything())

  table <- bind_rows(table_1, table_2)
}

###---------------------------------------------------------------------------------------------------------
