targets_data <- list(
  tar_target(
    name = download_wbd,
    command = nhdplusTools::download_wbd(
      outdir = "/inst/input/wbd",
      url = paste0(
        "https://prd-tnm.s3.amazonaws.com/StagedProducts/",
        "Hydrography/WBD/National/GDB/WBD_National_GDB.zip"
      ),
      progress = FALSE
    ),
    description = "NWIS | Download WBD"
  ),

  tar_target(
    state_list,
    state.abb[c(1, 9, 10, 24, 33, 40, 42)],
    description = "NWIS | State List"
  ),

  tar_target(
    date_range,
    c("2010-01-01", "2019-12-31"),
    description = "NWIS | Date Range"
  ),
  tar_target(
    yearly_date_chunks,
    {
      # Parse the date strings
      start_date <- as.Date(date_range[1])
      end_date <- as.Date(date_range[2])

      # Get all years in the range
      years <- seq(
        from = lubridate::year(start_date),
        to = lubridate::year(end_date)
      )

      # Create list of yearly date chunks
      purrr::map(years, function(y) {
        from <- as.Date(sprintf("%d-01-01", y))
        to <- as.Date(sprintf("%d-12-31", y))
        # Trim to within the date_range bounds
        from <- max(from, start_date)
        to <- min(to, end_date)
        c(from, to)
      })
    },
    description = "List of yearly date ranges"
  ),

  tar_target(
    name = nutrient_codes,
    command = {
      readr::read_tsv(
        file = "inst/input/usgs_param_codes_nutrients.txt",
        skip = 7,
        col_names = TRUE,
        comment = "5s"
      )
    },
    description = "NWIS | Read | Parameter Codes"
  ),

  tar_target(
    # This target gets the nwis_site_info for the parameters
    name = nutrient_nwis_info,
    command = {
      dataRetrieval::pcode_to_name(nutrient_codes$parm_cd) |>
        as_tibble()
    },
    description = "NWIS | Site Info"
  ),

  tar_target(
    # Get the parm_cd field and rename to parameterCd
    name = parameterCd,
    command = nutrient_nwis_info$parm_cd |>
      as.data.table() |>
      setnames("parameterCd"),
    description = "NWIS | parameterCd"
  ),

  tar_target(
    nutrient_data_parm_cd,
    get_nutrient_data(
      state_list,
      parameterCd,
      yearly_date_chunks,
      timeout_minutes_per_site = 0.01,
      verbose = TRUE
    ),
    pattern = cross(state_list, parameterCd, yearly_date_chunks),
    error = "null",
    iteration = "list",
    description = "NWIS | Retrieve Data"
  )

  # tar_target(
  #   # This target creates the state-level nutrient data from NWIS
  #   name = nutrient_data_join,
  #   command = join_site_info(nutrient_data_parm_cd),
  #   pattern = map(nutrient_data_parm_cd),
  #   iteration = "list",
  #   description = "NWIS | Site Info Join"
  # ),

  # tar_target(
  #   # This target gets the censoring aspects of the data
  #   name = nutrient_censored_check,
  #   command = get_censored_data(nutrient_data_join),
  #   pattern = map(nutrient_data_join),
  #   iteration = "list",
  #   description = "NWIS | Censored Data"
  # ),

  # tar_target(
  #   # This target gets the daily averages
  #   name = nutrient_daily_check,
  #   command = get_daily_averages(nutrient_censored_check),
  #   pattern = map(nutrient_censored_check),
  #   iteration = "list",
  #   description = "NWIS | Daily Averages"
  # ),

  # tar_target(
  #   # This target gets the yearly averages
  #   name = nutrient_yearly_check,
  #   command = get_yearly_averages(nutrient_daily_check),
  #   pattern = map(nutrient_daily_check),
  #   iteration = "list",
  #   description = "NWIS | Yearly Averages"
  # ),

  # tar_target(
  #   # filter concentrations with vals <= 0
  #   name = nutrient_filtered_check,
  #   command = filter_bad_rows(nutrient_yearly_check),
  #   pattern = map(nutrient_yearly_check),
  #   iteration = "list",
  #   description = "NWIS | Filtered Yearly"
  # ),

  # tar_target(
  #   # combine check
  #   name = nutrient_combined_check,
  #   command = combine_state_data(nutrient_filtered_check),
  #   description = "NWIS | Combined State Data"
  # ),

  # tar_target(
  #   # nutrient group summaries
  #   name = nutrient_summary_check,
  #   command = group_summaries(nutrient_combined_check, parm_cd),
  #   description = "NWIS | Group Summaries"
  # ),

  # tar_target(
  #   # Filter by sample size
  #   name = nutrient_sample_size_check,
  #   command = {
  #     nutrient_summary_check |>
  #       group_by(characteristicname) |>
  #       summarise(num = sum(num), bd = mean(bd)) |>
  #       filter(num > 2000, bd < 100)
  #   },
  #   description = "NWIS | Filter by Sample Size"
  # )
)
