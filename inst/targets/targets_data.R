targets_data <- list(
  # library(targets)
  # library(tidyverse)

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
    command = {
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
      get_nutrient_locations(TADAProfile)
    }
  ),
  tar_target(
    # the purpose of this target is to create a spatial object of the southeast
    name = southeast,
    command = {
      get_states <- function(state_names) {
        tigris::states(cb = TRUE, year = 2020, class = "sf") %>%
          filter(NAME %in% state_names) %>%
          st_transform(crs = 4269)
      }
      get_states(c(
        "Alabama",
        "Georgia",
        "North Carolina",
        "South Carolina",
        "Tennessee",
        "Mississippi",
        "Florida"
      ))
    }
  ),
  tar_target(
    # this target creates a 1km spaced dot grid for the southeast
    southeast_grid,
    {
      # project southeast to NAD83 / Conus Albers
      southeast_proj <- st_transform(southeast, 5070)

      grid <- st_make_grid(
        southeast_proj,
        cellsize = 1000, # 1km x 1km grid cells
        what = "centers",
        square = TRUE
      )

      point_grid <- st_sf(geometry = grid, crs = 5070)

      point_grid <- point_grid[
        st_join(point_grid, southeast_proj, left = FALSE),
      ]

      point_grid_image <- ggplot() +
        geom_sf(data = point_grid, color = "blue", size = 0.001, alpha = 0.3) +
        theme_minimal()

      ggsave(
        "inst/figs/dot_grid.png",
        plot = point_grid_image,
        width = 44,
        dpi = 600,
        height = 32,
        bg = "white"
      )
      "inst/figs/dot_grid.png"
    },
    format = "file"
  ),

  ### nlcd ---------------------------------------------------------------------------------------------------------

  tar_target(
    nlcd_years,
    c(1985, 1995, 2005, 2015),
    iteration = "list"
  ),
  tar_target(
    get_nlcd,
    command = {
      download_dir <- "inst/data/nlcd"

      if (!dir.exists(download_dir)) {
        dir.create(download_dir, recursive = TRUE)
      }

      amadeus::download_nlcd(
        product = "Land Cover",
        year = nlcd_years,
        directory_to_save = download_dir,
        acknowledgement = TRUE,
        download = TRUE,
        hash = TRUE
      )
      TRUE
    },
    pattern = map(nlcd_years),
  )
  #   tar_target(
  #     process_nlcd,
  #     command = {
  #       download_nlcd
  #       amadeus::process_nlcd(
  #         path = file.path(
  #           "inst",
  #           "data",
  #           "nlcd"
  #         ),
  #         year = nlcd_years,
  #         extent = terra::ext(-91.00001, -74.99999, 23.99999, 36.99999)
  #       )
  #       TRUE
  #     },
  #     pattern = map(nlcd_years)
  #   ),
  #   tar_target(
  #     calculate_nlcd,
  #     command = {
  #       process_nlcd
  #       amadeus::calculate_nlcd(
  #         from = process_nlcd,
  #         locs = southeast,
  #         locs_id = "STATEFP",
  #         mode = "exact",
  #         radius = 1000,
  #         max_cells = 5e+07
  #       )
  #       TRUE
  #     },
  #     pattern = map(process_nlcd)
  #   )
)

### eda ---------------------------------------------------------------------------------------------------------

# see `eda_figs.R` for functions associated with each of the eda targets

# tar_target(
#   name = locations_map,
#   command = map_locations(nutrient_locations, southeast),
#   format = "file"
# ),
# tar_target(
#   name = nutrients_maps,
#   command = map_nutrients(nutrient_locations, southeast),
#   format = "file"
# ),
# tar_target(
#   # this target creates a stacked barchart for yearly nutrient sampling frequency by state
#   name = state_nutrients_barchart,
#   command = barchart_nutrients_by_state(TADAProfile),
#   format = "file"
# ),
# tar_target(
#   name = nutrients_barchart,
#   command = barchart_nutrients(TADAProfile),
#   format = "file"
# ),

### ssurgo ---------------------------------------------------------------------------------------------------------

# tar_target(
#   ssurgo_files,
#   c(
#     "DrainageClass.zip",
#     "HydGrp.zip",
#     "Layer.zip",
#     "Text.zip",
#     "WtDep.zip",
#     "MUKEY90m.zip"
#   ),
#   iteration = "list"
# ),
# tar_target(
#   get_ssurgo,
#   {
#     item_id <- "631405c8d34e36012efa31ff"
#     download_dir <- "inst/data/ssurgo/zips"

#     if (!dir.exists(download_dir)) {
#       dir.create(download_dir, recursive = TRUE)
#     }

#     dest_path <- file.path(download_dir, ssurgo_files)

#     sbtools::item_file_download(
#       sb_id = item_id,
#       names = ssurgo_files,
#       destinations = dest_path,
#       overwrite_file = TRUE
#     )
#     dest_path
#   },
#   pattern = map(ssurgo_files),
#   format = "file"
# ),
# tar_target(
#   unzip_ssurgo,
#   {
#     zip_name <- tools::file_path_sans_ext(basename(get_ssurgo))
#     extract_dir <- file.path("inst/data/ssurgo/dbfs", zip_name)

#     if (!dir.exists(extract_dir)) {
#       dir.create(extract_dir, recursive = TRUE)
#     }

#     unzip(zipfile = get_ssurgo, exdir = extract_dir)

#     extract_dir
#   },
#   pattern = map(get_ssurgo),
#   format = "file"
# ),
# tar_target(
#   process_ssurgo,
#   {
#     dbf_path <- list.files(unzip_ssurgo, pattern = "\\.dbf$", full.names = TRUE)[1]
#     zip_basename <- tools::file_path_sans_ext(basename(get_ssurgo))
#     output_path <- file.path("inst/data/ssurgo", paste0("mukey_raster_", zip_basename, ".tif"))

#     ssurgo_table <- read.dbf(dbf_path, as.is = TRUE)
#     ssurgo_table$MUKEY <- as.numeric(ssurgo_table$MUKEY)

#     names(ssurgo_table) <- toupper(names(ssurgo_table))

#     ssurgo_levels <- ssurgo_table %>%
#       dplyr::filter(!is.na(MUKEY)) %>%
#       dplyr::relocate(MUKEY, .before = everything()) %>%
#       dplyr::distinct(MUKEY, .keep_all = TRUE)

#     m_raster <- rast("inst/data/ssurgo/dbfs/MUKEY90m/MapunitRaster_CONUS_90m1.tif") %>%
#       setNames("MUKEY")

#     levels(m_raster) <- ssurgo_levels
#     dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
#     writeRaster(m_raster, output_path, overwrite = TRUE)

#     output_path
#   },
#   pattern = map(unzip_ssurgo, get_ssurgo),
#   format = "file"
# ),

### soil_comp ----------------------------------------------------------------------------------------------------------

# tar_target(
#   soil_comp_files,
#   c(
#     "Appendix_2b_Top5_18Sept2013.txt",
#     "Appendix_4b_Chorizon_18Sept2013.txt"
#   ),
#   iteration = "list"
# ),
# tar_target(
#   get_soil_comp,
#   {
#     base_url <- "https://pubs.usgs.gov/ds/801/downloads/"
#     download_dir <- "inst/data/soil_comp"

#     if (!dir.exists(download_dir)) {
#       dir.create(download_dir, recursive = TRUE)
#     }

#     file_url <- paste0(base_url, soil_comp_files)
#     dest_file <- file.path(download_dir, soil_comp_files)

#     download.file(file_url, dest_file, mode = "wb")
#     dest_file
#   },
#   pattern = map(soil_comp_files),
#   format = "file"
# )

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
#     item_base_url <- "https://www.sciencebase.gov/catalog/file/get/5b4e34dfe4b06a6dd180272e?name="
#     download_dir <- "inst/data/mohp/zips"
#     dest_file <- file.path(download_dir, mohp_files)
#
#     if (!dir.exists(download_dir)) {
#       dir.create(download_dir, recursive = TRUE)
#     }
#
#     purrr::walk2(
#       mohp_files,
#       dest_file,
#       ~ curl::curl_download(
#         url = paste0(item_base_url, .x),
#         destfile = .y,
#         mode = "wb"
#       )
#     )
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
#
#     if (!dir.exists(extract_dir)) {
#       dir.create(extract_dir, recursive = TRUE)
#     }
#
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
