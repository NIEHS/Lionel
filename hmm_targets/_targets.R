# created by use_target()

# Load packages required to define the pipeline:
library(targets, tidyverse)

# Set target options:
tar_option_set(
  packages = c("tibble", "janitor", "fst", "data.table", "dplyr", "sf")
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
  )
)
