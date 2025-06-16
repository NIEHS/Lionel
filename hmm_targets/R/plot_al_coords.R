plot_al_coords <- function(file, crs_column) {
  crs_to_epsg <- list(
    "NAD83" = 4269,
    "NAD27" = 4267
  )

  lookup <- setNames(unlist(crs_to_epsg), names(crs_to_epsg))
  file$crs_espg <- lookup[file[[crs_column]]]
  file <- file[!is.na(file$crs_espg), ]

  split_by_crs <- split(file, file$crs_espg)

  # individually creates sf objects by reference system
  sf_list <- lapply(
    names(split_by_crs),
    function(crs_code) {
      #check for invalid or unmapped crs_column entries
      if (is.na(crs_code) || crs_code == "") {
        warning("Skipping group with missing or unknown CRS")
        return(NULL)
      }

      grouped_by_crs <- split_by_crs[[crs_code]]

      st_as_sf(
        grouped_by_crs,
        coords = c("location_longitude", "location_latitude"),
        crs = as.integer(crs_code)
      )
    }
  )

  sf_list <- Filter(Negate(is.null), sf_list)

  sf_list_with_EPSG <- lapply(sf_list, function(x) {
    st_transform(x, crs = 4269)
  })

  # combines the sf objects
  station_coordinates <- do.call(rbind, sf_list_with_EPSG) %>%
    st_transform(crs = 4269)

  # obtain AL polygon
  us_states <- rnaturalearth::ne_states(
    country = "United States of America",
    returnclass = "sf"
  )
  al <- us_states %>%
    dplyr::filter(name == "Alabama") %>%
    st_transform(crs = 4269)

  # create the map
  ggplot() +
    geom_sf(data = al, fill = "white", color = "black") +
    geom_sf(data = station_coordinates, color = "yellow", size = 3) +
    coord_sf(crs = 4269) +
    theme_minimal() +
    labs(title = "WQP Stations in AL")
}
