# eda
# functions:

###---------------------------------------------------------------------------------------------------------

# the goal for this function is to create a table with counts for the unique units used to measure each nutrient
get_unit_distribution <- function(
  file,
  nutrient_column,
  unit_column,
  detect_column
) {
  nutrient_sym <- sym(nutrient_column)
  unit_sym <- sym(unit_column)
  detect_sym <- sym(detect_column)

  data <- read_csv(file, show_col_types = FALSE)

  top_7 <- data %>%
    filter(!is.na(!!nutrient_sym)) %>%
    count(!!nutrient_sym, sort = TRUE) %>%
    slice_head(n = 7) %>%
    pull(!!nutrient_sym)

  top_7_counts <- data %>%
    filter(!!nutrient_sym %in% top_7, !is.na(!!unit_sym)) %>%
    count(!!nutrient_sym, !!unit_sym) %>%
    pivot_wider(
      names_from = !!unit_sym,
      values_from = n,
      values_fill = 0
    )

  invalid_counts <- data %>%
    filter(!!nutrient_sym %in% top_7, !!detect_sym == "*Non-detect") %>%
    count(!!nutrient_sym) %>%
    rename(NonDetect = n)

  table_1 <- top_7_counts %>%
    left_join(invalid_counts, by = as_name(nutrient_sym)) %>%
    mutate(NonDetect = replace_na(NonDetect, 0)) %>%
    rowwise() %>%
    mutate(TOTAL = sum(c_across(where(is.numeric)))) %>%
    ungroup()

  table_2 <- table_1 %>%
    summarise(across(where(is.numeric), sum)) %>%
    mutate(ChemName = "TOTAL") %>%
    select(ChemName, everything())

  table <- bind_rows(table_1, table_2)

  write.csv(
    table,
    file = "inst/visualize/unit_distribution.csv",
    row.names = FALSE
  )

  "inst/visualize/unit_distribution.csv"
}

# the goal for this function is to create 14 boxplots (two for each of the top 7 nutrients)
# this function will create 7 png files in "inst/figs"
# one boxplot will display counts for ChemValue entry values and the other boxplot will display ChemUnit entries
