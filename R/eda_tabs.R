# eda
# functions: get_se_stations_data(), filter_se_stations(), get_unit_data()

###---------------------------------------------------------------------------------------------------------

get_nutrient_locations <- function(data) {
  # create a vector associating each crs with an epsg
  crs_to_epsg <- c("NAD83" = 4269)

  # clean crs column and convert each blank or unknown crs to NAD83
  data %>%
    mutate(
      coordinate_ref_sys = as.character(coordinate_ref_sys),
      crs_epsg = crs_to_epsg[coordinate_ref_sys]
    ) %>%
    st_as_sf(
      coords = c("longitude", "latitude"),
      crs = 4269,
      remove = FALSE
    )
}

###---------------------------------------------------------------------------------------------------------

get_states <- function(state_names) {
  tigris::states(cb = TRUE, year = 2020, class = "sf") %>%
    filter(NAME %in% state_names) %>%
    st_transform(crs = 4269)
}

###---------------------------------------------------------------------------------------------------------

get_sb_file_urls <- function(sb_items) {
  sb_item <- sb_items$sb_item
  item_id <- sb_item$item_id
  expected_filename <- sb_item$file

  metadata_url <- paste0(
    "https://www.sciencebase.gov/catalog/item/",
    item_id,
    "?format=json"
  )
  metadata <- jsonlite::fromJSON(metadata_url)

  file_info <- metadata$files

  if (is.null(file_info) || !expected_filename %in% file_info$name) {
    stop(paste("File", expected_filename, "not found in item", item_id))
  }

  file_url <- file_info$url[file_info$name == expected_filename][1]

  file_url
}
