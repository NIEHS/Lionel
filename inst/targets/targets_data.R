targets_data <- list(
  tar_target(
    name = nutrient_stations,
    command = {
      # Define the directory containing your CSV files
      station_files <- list.files(
        path = "inst/input/raw_data/",
        pattern = "station.csv$",
        recursive = TRUE,
        full.names = TRUE
      )

      # Read and bind all CSV files into one data frame
      combined_df <- station_files |>
        map_dfr(
          ~ read_csv(
            .x,
            col_select = c(
              "Org" = "OrganizationIdentifier",
              "SiteID" = "MonitoringLocationIdentifier",
              "SiteType" = "MonitoringLocationTypeName",
              "SiteName" = "MonitoringLocationName",
              "MonitorName" = "MonitoringLocationName",
              "Latitude" = "LatitudeMeasure",
              "Longitude" = "LongitudeMeasure",
              "VerticalValue" = "VerticalMeasure/MeasureValue",
              "WellDepth" = "WellDepthMeasure/MeasureValue",
              "WellHole" = "WellHoleDepthMeasure/MeasureValue",
              "ConstructionDate" = "ConstructionDateText",
              "CoordReferenceSys" = "HorizontalCoordinateReferenceSystemDatumName"
            )
          )
        )
    },
    description = "WQP | Process Data | Stations"
  ),
  tar_target(
    name = nutrient_physchem,
    command = {
      # Define the directory containing your CSV files
      physchem_files <- list.files(
        path = "inst/input/raw_data/",
        pattern = "resultphyschem.csv$",
        recursive = TRUE,
        full.names = TRUE
      )

      col_types_spec <- cols_only(
        OrganizationIdentifier = col_character(),
        MonitoringLocationIdentifier = col_character(),
        MonitoringLocationTypeName = col_character(),
        ActivityStartDate = col_character(),
        MonitoringLocationName = col_character(),
        ResultDetectionConditionText = col_character(),
        ResultMeasureValue = col_double(),
        `ResultMeasure/MeasureUnitCode` = col_character(),
        CharacteristicName = col_character(),
        ResultSampleFractionText = col_character(),
        MeasureQualifierCode = col_character(),
        ResultStatusIdentifier = col_character(),
        ResultCommentText = col_character(),
        `DetectionQuantitationLimitMeasure/MeasureValue` = col_double(),
        `ResultAnalyticalMethod/MethodName` = col_character(),
        `ResultAnalyticalMethod/MethodIdentifier` = col_character()
      )

      combined_df <- physchem_files |>
        map_dfr(
          ~ read_csv(
            .x,
            col_types = col_types_spec,
            col_select = c(
              "Org" = "OrganizationIdentifier",
              "SiteID" = "MonitoringLocationIdentifier",
              "SiteName" = "MonitoringLocationName",
              "SampleDate" = "ActivityStartDate",
              "MonitorName" = "MonitoringLocationName",
              "ChemName" = "CharacteristicName",
              "ChemValue" = "ResultMeasureValue",
              "ChemUnit" = `ResultMeasure/MeasureUnitCode`,
              "SampleFraction" = "ResultSampleFractionText",
              "DetectionCondition" = "ResultDetectionConditionText",
              "MeasureQualifier" = "MeasureQualifierCode",
              "ResultStatus" = "ResultStatusIdentifier",
              "ResultComment" = "ResultCommentText",
              "DetectionQuantitationLimit" = `DetectionQuantitationLimitMeasure/MeasureValue`,
              "AnalyticalMethodName" = `ResultAnalyticalMethod/MethodName`,
              "AnalyticalMethodID" = `ResultAnalyticalMethod/MethodIdentifier`
            )
          )
        )
    },
    description = "WQP | Process Data | Chem"
  ),
  tar_target(
    # This target creates the state-level nutrient data from NWIS
    name = nutrient_data_join,
    command = {
      nutrient_physchem |>
        left_join(
          nutrient_stations,
          by = c("SiteID" = "SiteID")
        ) |>
        mutate(
          SampleDate = lubridate::ymd(SampleDate),
          Latitude = as.numeric(Latitude),
          Longitude = as.numeric(Longitude)
        ) |>
        select(
          SiteID,
          Org.x,
          SiteName.x,
          MonitorName.x,
          SampleDate,
          ChemName,
          ChemValue,
          ChemUnit,
          SampleFraction,
          DetectionCondition,
          MeasureQualifier,
          ResultStatus,
          ResultComment,
          DetectionQuantitationLimit,
          WellDepth,
          Latitude,
          Longitude,
          CoordReferenceSys,
          AnalyticalMethodName,
          AnalyticalMethodID
        ) |>
        rename(
          SiteName = SiteName.x,
          MonitorName = MonitorName.x,
          Org = Org.x
        )
    },
    description = "WQP | Join"
  ),

  tar_target(
    # this target modifies nutrient_data_join to add crs and state columns
    name = se_stations_data,
    command = get_se_stations_data(nutrient_data_join, CoordReferenceSys)
  ),
  tar_target(
    # this target writes se_stations_data to a csv
    name = se_stations_file,
    command = {
      write.csv(
        se_stations_data,
        file = "inst/tabs/se_stations_file.csv",
        row.names = FALSE
      )

      "inst/tabs/se_stations_file.csv"
    },
    format = "file"
  ),
  tar_target(
    name = all_nutrient_barchart,
    command = barchart_all_nutrients(se_stations_data),
    format = "file"
  ),
  tar_target(
    # this target filters se_stations_data to nutrient entries: nitrate, nitrite, orthophosphate, and ammonia and ammonium
    name = filtered_station_nutrients,
    command = filter_se_stations(se_stations_data)
  ),
  tar_target(
    # this target maps nitrate, nitrite, orthophosphate, and ammonia and ammonium across the southeastern US
    name = se_stations_map,
    command = map_se_stations(filtered_station_nutrients),
    format = "file"
  ),
  tar_target(
    # this target creates a stacked barchart for yearly nutrient sampling frequency by state
    name = sampling_by_state_barchart,
    command = barchart_sampling_by_state(filtered_station_nutrients),
    format = "file"
  ),
  tar_target(
    # this target creates a figure displaying four maps of the southeast highlighting sampling efforts for nitrate, nitrite, orthophosphate, and ammonia and ammonium
    name = nutrient_sampling_maps,
    command = map_nutrient_sampling(filtered_station_nutrients),
    format = "file"
  ),
  tar_target(
    # this target creates a table counting the various units in which each nutrient is measured
    name = unit_data,
    command = get_unit_data(se_stations_data)
  ),
  tar_target(
    # this target establishes the nutrient units file
    name = unit_data_file,
    command = {
      write.csv(
        unit_data,
        file = "inst/tabs/unit_distribution.csv",
        row.names = FALSE
      )

      "inst/tabs/unit_distribution.csv"
    },
    format = "file"
  ),
  tar_target(
    # this target creates a barchart for the number of samples analyzed using a certain analytical method by nutrient
    name = analytical_method_barchart,
    command = barchart_analytical_methods(filtered_station_nutrients),
    format = "file"
  ),
  tar_target(
    # this target creates a barchart for the number of samples reported using a certain unit by nutrient
    name = nutrient_unit_barchart,
    command = barchart_nutrient_units(filtered_station_nutrients),
    format = "file"
  )
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
