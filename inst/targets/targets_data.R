targets_data <- list(
  # tar_target(
  #   name = nutrient_stations,
  #   command = {
  #     # Define the directory containing your CSV files
  #     station_files <- list.files(
  #       path = "inst/input/raw_data/",
  #       pattern = "station.csv$",
  #       recursive = TRUE,
  #       full.names = TRUE
  #     )

  #     # Read and bind all CSV files into one data frame
  #     combined_df <- station_files |>
  #       map_dfr(
  #         ~ read_csv(
  #           .x,
  #           col_select = c(
  #             "Org" = "OrganizationIdentifier",
  #             "SiteID" = "MonitoringLocationIdentifier",
  #             "SiteType" = "MonitoringLocationTypeName",
  #             "SiteName" = "MonitoringLocationName",
  #             "MonitorName" = "MonitoringLocationName",
  #             "Latitude" = "LatitudeMeasure",
  #             "Longitude" = "LongitudeMeasure",
  #             "VerticalValue" = "VerticalMeasure/MeasureValue",
  #             "WellDepth" = "WellDepthMeasure/MeasureValue",
  #             "WellHole" = "WellHoleDepthMeasure/MeasureValue",
  #             "ConstructionDate" = "ConstructionDateText",
  #             "CoordReferenceSys" = "HorizontalCoordinateReferenceSystemDatumName"
  #           )
  #         )
  #       )
  #   },
  #   description = "WQP | Process Data | Stations"
  # ),
  # tar_target(
  #   name = nutrient_physchem,
  #   command = {
  #     # Define the directory containing your CSV files
  #     physchem_files <- list.files(
  #       path = "inst/input/raw_data/",
  #       pattern = "resultphyschem.csv$",
  #       recursive = TRUE,
  #       full.names = TRUE
  #     )

  #     col_types_spec <- cols_only(
  #       OrganizationIdentifier = col_character(),
  #       MonitoringLocationIdentifier = col_character(),
  #       MonitoringLocationTypeName = col_character(),
  #       ActivityStartDate = col_character(),
  #       MonitoringLocationName = col_character(),
  #       ResultDetectionConditionText = col_character(),
  #       ResultMeasureValue = col_double(),
  #       `ResultMeasure/MeasureUnitCode` = col_character(),
  #       CharacteristicName = col_character(),
  #       ResultSampleFractionText = col_character(),
  #       MeasureQualifierCode = col_character(),
  #       ResultStatusIdentifier = col_character(),
  #       ResultCommentText = col_character(),
  #       `DetectionQuantitationLimitMeasure/MeasureValue` = col_double(),
  #       `ResultAnalyticalMethod/MethodName` = col_character(),
  #       `ResultAnalyticalMethod/MethodIdentifier` = col_character()
  #     )

  #     combined_df <- physchem_files |>
  #       map_dfr(
  #         ~ read_csv(
  #           .x,
  #           col_types = col_types_spec,
  #           col_select = c(
  #             "Org" = "OrganizationIdentifier",
  #             "SiteID" = "MonitoringLocationIdentifier",
  #             "SiteName" = "MonitoringLocationName",
  #             "SampleDate" = "ActivityStartDate",
  #             "MonitorName" = "MonitoringLocationName",
  #             "ChemName" = "CharacteristicName",
  #             "ChemValue" = "ResultMeasureValue",
  #             "ChemUnit" = `ResultMeasure/MeasureUnitCode`,
  #             "SampleFraction" = "ResultSampleFractionText",
  #             "DetectionCondition" = "ResultDetectionConditionText",
  #             "MeasureQualifier" = "MeasureQualifierCode",
  #             "ResultStatus" = "ResultStatusIdentifier",
  #             "ResultComment" = "ResultCommentText",
  #             "DetectionQuantitationLimit" = `DetectionQuantitationLimitMeasure/MeasureValue`,
  #             "AnalyticalMethodName" = `ResultAnalyticalMethod/MethodName`,
  #             "AnalyticalMethodID" = `ResultAnalyticalMethod/MethodIdentifier`
  #           )
  #         )
  #       )
  #   },
  #   description = "WQP | Process Data | Chem"
  # ),
  # tar_target(
  #   # This target creates the state-level nutrient data from NWIS
  #   name = nutrient_data_join,
  #   command = {
  #     nutrient_physchem |>
  #       left_join(
  #         nutrient_stations,
  #         by = c("SiteID" = "SiteID")
  #       ) |>
  #       mutate(
  #         SampleDate = lubridate::ymd(SampleDate),
  #         Latitude = as.numeric(Latitude),
  #         Longitude = as.numeric(Longitude)
  #       ) |>
  #       select(
  #         SiteID,
  #         Org.x,
  #         SiteName.x,
  #         MonitorName.x,
  #         SampleDate,
  #         ChemName,
  #         ChemValue,
  #         ChemUnit,
  #         SampleFraction,
  #         DetectionCondition,
  #         MeasureQualifier,
  #         ResultStatus,
  #         ResultComment,
  #         DetectionQuantitationLimit,
  #         WellDepth,
  #         Latitude,
  #         Longitude,
  #         CoordReferenceSys,
  #         AnalyticalMethodName,
  #         AnalyticalMethodID
  #       ) |>
  #       rename(
  #         SiteName = SiteName.x,
  #         MonitorName = MonitorName.x,
  #         Org = Org.x
  #       )
  #   },
  #   description = "WQP | Join"
  # ),

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

  tar_target(
    nlcd_years,
    c(1985, 1995, 2005, 2015)
  ),
  tar_target(
    download_nlcd,
    command = {
      amadeus::download_nlcd(
        product = "Land Cover",
        year = nlcd_year,
        directory_to_save = file.path(
          "inst",
          "data",
          "rasters",
          "nlcd",
          as.character(nlcd_year)
        ),
        acknowledgement = TRUE,
        download = TRUE,
        hash = TRUE
      )
    },
    pattern = map(nlcd_year = nlcd_years),
    iteration = "vector"
  ),
  tar_target(
    process_nlcd,
    command = {
      amadeus::process_nlcd(
        path = download_nlcd,
        year = nlcd_year,
        extent = terra::ext(-91.00001, -74.99999, 23.99999, 36.99999)
      )
    },
    pattern = map(download_nlcd, nlcd_year = nlcd_years),
    iteration = "vector"
  ),
  tar_target(
    calculate_nlcd,
    command = {
      amadeus::calculate_nlcd(
        from = process_nlcd,
        locs = southeast,
        locs_id = "STATEFP",
        mode = "exact",
        radius = 1000,
        max_cells = 5e+07
      )
    },
    pattern = map(process_nlcd),
    iteration = "vector"
  )

  ### USGS data releases ---------------------------------------------------------------------------------------------------------

  # tar_target(
  #   sb_items,
  #   list(
  #     list(item_id = "6734c572d34e6fbce7b5c09a", file = "BG2021_SepticDensities.csv"), # septic system density at the block group level (data release: https://doi.org/10.5066/P1WCYDPB)
  #     list(item_id = "631405c8d34e36012efa31ff", file = "MUKEY90m.zip"), # SSURGO variables by MUKEY (data release: https://doi.org/10.5066/P92JJ6UJ)
  #     list(item_id = "5e43efc3e4b0edb47be84c3d", file = "domestic_grids.zip"), # domestic well depth (data release: https://doi.org/10.5066/P94640EM)
  #     list(item_id = "631405ded34e36012efa3470", file = "Water_Divides.7z") # multi order hydrologic position (data release: https://doi.org/10.5066/P9HLU4YY)
  #   )
  # ),
  # tar_target(
  #   sciencebase_files,
  #   get_sb_item(item),
  #   pattern = map(item = sb_items),
  #   iteration = "list"
  # )
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
