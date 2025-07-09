# functions for

###---------------------------------------------------------------------------------------------------------

get_sb_item <- function(item) {
  item_id <- item$item_id
  expected_filename <- item$file

  metadata_url <- paste0(
    "https://www.sciencebase.gov/catalog/item/",
    item_id,
    "?format=json"
  )
  metadata <- fromJSON(metadata_url)

  file_info <- metadata$files

  if (is.null(file_info) || !expected_filename %in% file_info$name) {
    stop(paste("File", expected_filename, "not found in item", item_id))
  }

  file_url <- file_info$url[file_info$name == expected_filename][1]

  dest_dir <- "inst/data/rasters/sciencebase"
  dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)

  dest_file <- file.path(dest_dir, expected_filename)

  if (!file.exists(dest_file)) {
    download.file(file_url, dest_file, mode = "wb", method = "curl")
  }

  return(dest_file)
}
