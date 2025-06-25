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
        `DetectionQuantitationLimitMeasure/MeasureValue` = col_double()
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
              "DetectionQuantitationLimit" = `DetectionQuantitationLimitMeasure/MeasureValue`
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
          CoordReferenceSys
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
    # this target maps all WQP nutrient data by chemical color
    name = southeast_nutrients,
    command = nutrient_map(
      file = nutrient_data_join,
      crs_column = "CoordReferenceSys"
    ),
    format = "file"
  ),
  tar_target(
    # this target establishes the nutrient file containing state information
    name = nutrient_data_with_state,
    command = "inst/visualize/nutrient_data_with_state.csv",
    format = "file"
  ),
  tar_target(
    # this target creates a barchart for the distribution of sample nutrient type collected within a year by state
    name = nutrient_barchart_by_state,
    command = chem_bar_chart(nutrient_data_with_state),
    format = "file"
  ),
  tar_target(
    # this target creates maps for the top nutrients sampled in the southeast
    name = se_top_nutrients_maps,
    command = top_nutrients_maps(nutrient_data_with_state),
    format = "file"
  ),
  tar_target(
    # this target creates a table counting the various units in which each nutrient is measured
    name = nutrient_unit_data,
    command = get_unit_distribution(
      file = nutrient_data_with_state,
      nutrient_column = "ChemName",
      unit_column = "ChemUnit",
      detect_column = "DetectionCondition"
    )
  ),
  tar_target(
    # this target establishes the nutrient units file
    name = unit_distribution,
    command = "inst/visualize/unit_distribution.csv",
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
