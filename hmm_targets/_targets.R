# created by use_target()

# Load packages required to define the pipeline:
library(targets, tidyverse)

# Set target options:
tar_option_set(
  packages = c(
    "tibble",
    "janitor",
    "fst",
    "data.table",
    "dplyr",
    "sf",
    "ggplot2",
    "rnaturalearth",
    "rnaturalearthdata",
    "rnaturalearthhires"
  )
)

# Run the R scripts in the R/ folder with your custom functions:
tar_source()

# Replace the target list below with your own:
list(
  tar_target(
    name = nutrients,
    command = "inst/nutrients.csv",
    format = "file"
  ),
  tar_target(
    name = clean_nutrients,
    command = get_clean_nutrients(nutrients),
    format = "fst_dt" # then type "view(tar_read(clean_nutrients))" to open a table to the right
  ),
  tar_target(
    name = station_coords,
    command = plot_al_coords(
      file = clean_nutrients,
      crs_column = "location_horz_coord_reference_system_datum"
    )
  )
)
