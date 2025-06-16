plot_al_coords <- function(file, crs_column) {
  # change the crs entry within the crs column of the dataset to epsg codes right away
  crs_to_epsg <- list(
    "NAD83" = 4269,
    "NAD27" = 4267
  )

  # convert list to vector without changing naming
  lookup <- setNames(unlist(crs_to_epsg), names(crs_to_epsg))

  # change crs_column entries from "NAD27" and "NAD83" to 4267 and 4267 respectively
  # rename crs_column to crs_epsg
  file$crs_epsg <- lookup[file[[crs_column]]]

  # remove rows where crs_epsg is NA (prevents errors where matching didn't occur due to a blank, for example)
  file <- file[!is.na(file$crs_epsg), ]

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

      # lat, long, and crs used to create sf spatial object
      # use as.integer because names(split_by_crs) returns character strings, st_as_sf() requires integers
      st_as_sf(
        grouped_by_crs,
        coords = c("location_longitude", "location_latitude"),
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
    geom_sf(data = station_coordinates, color = "orange", size = 3) +
    coord_sf(crs = 4269) +
    theme_minimal() +
    labs(title = "WQP Stations in AL")
}
