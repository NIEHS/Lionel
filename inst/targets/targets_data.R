targets_data <- list(
  # targets

  ### create core objects ---------------------------------------------------------------------------------------------------------

  tar_target(
    name = TADAProfile_file,
    command = "inst/tabs/TADAProfile.csv",
    format = "file"
  ),
  tar_target(
    name = TADAProfile,
    command = {
      read_csv(
        TADAProfile_file
      )
    }
  ),
  tar_target(
    name = nutrient_locations,
    command = get_nutrient_locations(TADAProfile)
  ),
  tar_target(
    name = southeast,
    command = get_states(c(
      "Alabama",
      "Georgia",
      "North Carolina",
      "South Carolina",
      "Tennessee",
      "Mississippi",
      "Florida"
    ))
  ),
  tar_target(
    # this target creates a 1km spaced dot grid for the southeast
    southeast_grid,
    {
      # project southeast to NAD83 / Conus Albers
      southeast_proj <- st_transform(southeast, 5070)

      grid <- st_make_grid(
        southeast_proj,
        cellsize = 1000,
        what = "centers",
        square = TRUE
      )

      point_grid <- st_sf(geometry = grid) %>%
        st_intersection(southeast_proj)

      st_transform(point_grid, st_crs(southeast))

      point_grid_image <- ggplot(point_grid) +
        geom_sf(southeast, col = "white", border = "black")

      ggsave(
        "inst/figs/dot_grid.png",
        plot = point_grid_image,
        width = 11,
        height = 8
      )
      "inst/figs/dot_grid.png"
    },
    format = "file"
  ),

  ### eda ---------------------------------------------------------------------------------------------------------

  tar_target(
    name = locations_map,
    command = map_locations(nutrient_locations, southeast),
    format = "file"
  ),
  tar_target(
    name = nutrients_maps,
    command = map_nutrients(nutrient_locations, southeast),
    format = "file"
  ),
  tar_target(
    # this target creates a stacked barchart for yearly nutrient sampling frequency by state
    name = state_nutrients_barchart,
    command = barchart_nutrients_by_state(TADAProfile),
    format = "file"
  ),
  tar_target(
    name = nutrients_barchart,
    command = barchart_nutrients(TADAProfile)
  ),

  ### nlcd ---------------------------------------------------------------------------------------------------------

  # tar_target(
  #   nlcd_years,
  #   list(1985, 1995, 2005, 2015),
  #   iteration = "list"
  # ),
  # tar_target(
  #   get_nlcd,
  #   command = {
  #     download_dir <- "inst/data/nlcd"

  #     if (!dir.exists(download_dir)) {
  #       dir.create(download_dir, recursive = TRUE)
  #     }

  #     amadeus::download_nlcd(
  #       product = "Land Cover",
  #       year = nlcd_years,
  #       directory_to_save = download_dir,
  #       acknowledgement = TRUE,
  #       download = TRUE,
  #       hash = TRUE
  #     )
  #     TRUE
  #   },
  #   pattern = map(nlcd_years),
  # ),
  # tar_target(
  #   process_nlcd,
  #   command = {
  #     download_nlcd
  #     amadeus::process_nlcd(
  #       path = file.path(
  #         "inst",
  #         "data",
  #         "rasters",
  #         "nlcd"
  #       ),
  #       year = nlcd_years,
  #       extent = terra::ext(-91.00001, -74.99999, 23.99999, 36.99999)
  #     )
  #   },
  #   pattern = map(nlcd_years)
  # ),
  # tar_target(
  #   calculate_nlcd,
  #   command = {
  #     process_nlcd
  #     amadeus::calculate_nlcd(
  #       from = process_nlcd,
  #       locs = southeast,
  #       locs_id = "STATEFP",
  #       mode = "exact",
  #       radius = 1000,
  #       max_cells = 5e+07
  #     )
  #   },
  #   pattern = map(process_nlcd)
  # )

  ### ssurgo ---------------------------------------------------------------------------------------------------------

  tar_target(
    ssurgo_files,
    c(
      "DrainageClass.zip",
      "HydGrp.zip",
      "Layer.zip",
      "Text.zip",
      "WtDep.zip"
    ),
    iteration = "list"
  ),
  tar_target(
    get_ssurgo,
    {
      item_id <- "631405c8d34e36012efa31ff"
      download_dir <- "inst/data/ssurgo/zips"
      dest_file <- file.path(download_dir, ssurgo_files)

      if (!dir.exists(download_dir)) {
        dir.create(download_dir, recursive = TRUE)
      }

      sbtools::item_file_download(
        sb_id = item_id,
        names = ssurgo_files,
        destinations = dest_file,
        overwrite_file = TRUE
      )
      dest_file
    },
    pattern = map(ssurgo_files),
    format = "file"
  ),
  tar_target(
    unzip_ssurgo,
    {
      zip_basename <- basename(get_ssurgo)
      zip_name_no_ext <- sub("\\.[^.]*$", "", zip_basename)
      extract_dir <- file.path("inst/data/ssurgo", zip_name_no_ext)

      if (!dir.exists(extract_dir)) {
        dir.create(extract_dir, recursive = TRUE)
      }

      unzip(get_ssurgo, exdir = extract_dir)
      extract_dir
    },
    pattern = map(get_ssurgo),
    format = "file"
  ),

  ### mohp ----------------------------------------------------------------------------------------------------------

  # tar_target(
  #   mohp_files,
  #   c(
  #     "Order9_DSD_LP_90m.gdb.7z",
  #     "Order8_DSD_LP_90m.gdb.7z",
  #     "Order7_DSD_LP_90m.gdb.7z",
  #     "Order6_DSD_LP_90m.gdb.7z",
  #     "Order5_DSD_LP_90m.gdb.7z",
  #     "Order4_DSD_LP_90m.gdb.7z",
  #     "Order3_DSD_LP_90m.gdb.7z",
  #     "Order2_DSD_LP_90m.gdb.7z",
  #     "Order1_DSD_LP_90m.gdb.7z"
  #   ),
  #   iteration = "list"
  # ),
  # tar_target(
  #   get_mohp,
  #   {
  #     item_id <- "5b4e34dfe4b06a6dd180272e"
  #     download_dir <- "inst/data/mohp/zips"
  #     dest_file <- file.path(download_dir, mohp_files)

  #     if (!dir.exists(download_dir)) {
  #       dir.create(download_dir, recursive = TRUE)
  #     }

  #     tryCatch(
  #       {
  #         sbtools::item_file_download(
  #           sb_id = item_id,
  #           names = mohp_files,
  #           destinations = dest_file,
  #           overwrite_file = TRUE
  #         )
  #       },
  #       error = function(e) {
  #         stop("Failed to download ", mohp_files, ": ", e$message)
  #       }
  #     )

  #     if (!file.exists(dest_file) || file.info(dest_file)$size < 1000) {
  #       stop("Downloaded file appears corrupted or too small: ", dest_file)
  #     }
  #     dest_file
  #   },
  #   pattern = map(mohp_files),
  #   format = "file"
  # ),
  # tar_target(
  #   unzip_mohp,
  #   {
  #     zip_basename <- basename(get_mohp)
  #     zip_name_no_ext <- sub("\\.[^.]*$", "", zip_basename)
  #     extract_dir <- file.path("inst/data/mohp", zip_name_no_ext)

  #     if (!dir.exists(extract_dir)) {
  #       dir.create(extract_dir, recursive = TRUE)
  #     }

  #     tryCatch(
  #       {
  #         archive::archive(get_mohp) # Will throw if corrupt
  #         archive::archive_extract(get_mohp, dir = extract_dir)
  #       },
  #       error = function(e) {
  #         stop("Failed to extract ", get_mohp, ": ", e$message)
  #       }
  #     )
  #     extract_dir
  #   },
  #   pattern = map(get_mohp),
  #   format = "file"
  # ),

  ### soil_comp ----------------------------------------------------------------------------------------------------------

  tar_target(
    soil_comp_files,
    c(
      "Appendix_2b_Top5_18Sept2013.txt",
      "Appendix_4b_Chorizon_18Sept2013.txt"
    ),
    iteration = "list"
  ),
  tar_target(
    get_soil_comp,
    {
      base_url <- "https://pubs.usgs.gov/ds/801/downloads/"
      download_dir <- "inst/data/soil_comp"

      if (!dir.exists(download_dir)) {
        dir.create(download_dir, recursive = TRUE)
      }

      file_url <- paste0(base_url, soil_comp_files)
      dest_file <- file.path(download_dir, soil_comp_files)

      download.file(file_url, dest_file, mode = "wb")
      dest_file
    },
    pattern = map(soil_comp_files),
    format = "file"
  )
)
