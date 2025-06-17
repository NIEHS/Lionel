targets_nwis <- list(
  tar_target(
    name = download_wbd,
    command = nhdplusTools::download_wbd(
      outdir = "/input/wbd",
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
    state.abb[c(-2, -11)], # Remove Alaska and Hawaii
    description = "NWIS | State List"
  ),

  tar_target(
    date_range,
    c("2000-01-01", "2022-12-31"),
    description = "NWIS | Date Range"
  ),

  tar_target(
    name = pesticide_codes,
    command = {
      readr::read_tsv(
        file = "inst/extdata/usgs_organic_pesticides_wqp.txt",
        skip = 7,
        col_names = TRUE,
        comment = "5s"
      )
    },
    description = "NWIS | Read | Parameter Codes"
  ),

  tar_target(
    # This target gets the nwis_site_info for the parameters
    name = pesticide_nwis_info,
    command = {
      dataRetrieval::pcode_to_name(pesticide_codes$parm_cd) |>
        as_tibble()
    },
    description = "NWIS | Site Info"
  ),

  tar_target(
    name = pesticide_nwis_filtered,
    command = {
      pesticide_nwis_info |>
        filter(str_detect(
          description,
          fixed("water, filtered, recoverable, micrograms per liter")
        )) # nolint
    },
    description = "NWIS | Water Filtered Recoverable"
  ),

  tar_target(
    # Get the parm_cd field and rename to parameterCd
    name = parameterCd,
    command = pesticide_nwis_filtered$parm_cd |>
      as.data.table() |>
      setnames("parameterCd"),
    description = "NWIS | parameterCd"
  ),

  tar_target(
    name = pest_data_parm_cd,
    command = get_pesticide_data(
      state_list,
      parameterCd,
      date_range,
      timeout_minutes_per_site = 0.01,
      verbose = TRUE
    ), #nolint
    pattern = cross(state_list, parameterCd),
    error = "null",
    iteration = "list",
    description = "NWIS | Retrive Data"
  ),

  tar_target(
    # This target creates the state-level Pesticide data from NWIS
    name = pest_data_join,
    command = join_site_info(pest_data_parm_cd),
    pattern = map(pest_data_parm_cd),
    iteration = "list",
    description = "NWIS | Site Info Join"
  ),

  tar_target(
    # This target gets the censoring aspects of the data
    name = pest_censored_check,
    command = get_censored_data(pest_data_join),
    pattern = map(pest_data_join),
    iteration = "list",
    description = "NWIS | Censored Data"
  ),

  tar_target(
    # This target gets the daily averages
    name = pest_daily_check,
    command = get_daily_averages(pest_censored_check),
    pattern = map(pest_censored_check),
    iteration = "list",
    description = "NWIS | Daily Averages"
  ),

  tar_target(
    # This target gets the yearly averages
    name = pest_yearly_check,
    command = get_yearly_averages(pest_daily_check),
    pattern = map(pest_daily_check),
    iteration = "list",
    description = "NWIS | Yearly Averages"
  ),

  tar_target(
    # filter concentrations with vals <= 0
    name = pest_filtered_check,
    command = filter_bad_rows(pest_yearly_check),
    pattern = map(pest_yearly_check),
    iteration = "list",
    description = "NWIS | Filtered Yearly"
  ),

  tar_target(
    # combine check
    name = pest_combined_check,
    command = combine_state_data(pest_filtered_check),
    description = "NWIS | Combined State Data"
  ),

  tar_target(
    # Pesticide group summaries
    name = pest_summary_check,
    command = group_summaries(pest_combined_check, parm_cd),
    description = "NWIS | Group Summaries"
  ),

  tar_target(
    # Filter by sample size
    name = pest_sample_size_check,
    command = {
      pest_summary_check |>
        group_by(characteristicname) |>
        summarise(num = sum(num), bd = mean(bd)) |>
        filter(num > 2000, bd < 100)
    },
    description = "NWIS | Filter by Sample Size"
  )
)
