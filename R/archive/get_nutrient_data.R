get_nutrient_data <- function(
  state_list,
  nutrient_param,
  date_range,
  max_tries = 3,
  timeout_minutes_per_site = 5,
  sleep_on_error = 0,
  verbose = FALSE
) {
  start_date <- date_range[1]
  end_date <- date_range[2]

  wqp_args_all <- list(
    statecode = state_list,
    parameterCd = nutrient_param$parameterCd
  )

  timeout_minutes <- 0.33333

  pull_temp <- pull_data_safely(
    dataRetrieval::whatWQPdata,
    wqp_args_all,
    timeout_minutes = timeout_minutes,
    max_tries = max_tries,
    sleep_on_error = sleep_on_error,
    verbose = verbose
  )

  pull_temp <- pull_temp[pull_temp$MonitoringLocationTypeName == "Well", ]

  if (nrow(pull_temp) > 0) {
    data_wq <- dataRetrieval::readWQPqw(
      pull_temp$MonitoringLocationIdentifier,
      nutrient_param$parameterCd,
      startDate = start_date[1],
      endDate = end_date[1]
    )
  } else {
    data_wq <- NULL
  }
  return(data_wq)
}
