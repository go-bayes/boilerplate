#' Initialise Boilerplate Measures Database
#'
#' This function initialises or updates the boilerplate measures database with default values.
#' It's useful for setting up the system initially or adding new default entries.
#'
#' @param merge_strategy Character. How to merge with existing database: "keep_existing", "merge_recursive", or "overwrite_all".
#' @param measures_path Character. Path to the directory where measures database files are stored.
#'   If NULL (default), uses the "boilerplate/data/" subdirectory of the current working directory
#'   via the here::here() function. The directory will be created if it doesn't exist.
#' @param file_name Character. Name of the file to save or load (without path).
#'   If NULL (default), uses "measures_db.rds".
#' @param overwrite Logical. Whether to overwrite existing entries (deprecated, use merge_strategy instead).
#' @param quiet Logical. If TRUE, suppresses all CLI alerts. Default is FALSE.
#'
#' @return No return value, called for side effects.
#'
#' @examples
#' \dontrun{
#' # Initialise measures database with default merge strategy
#' boilerplate_init_measures()
#'
#' # Use recursive merging
#' boilerplate_init_measures(merge_strategy = "merge_recursive")
#'
#' # Completely overwrite existing database
#' boilerplate_init_measures(merge_strategy = "overwrite_all")
#'
#' # Initialise in a specific directory with a custom file name
#' boilerplate_init_measures(
#'   measures_path = "path/to/project/data",
#'   file_name = "my_measures.rds"
#' )
#' }
#'
#' @importFrom utils modifyList
#' @importFrom here here
#' @importFrom cli cli_alert_info cli_alert_success cli_alert_warning cli_alert_danger
#' @export
boilerplate_init_measures <- function(
    merge_strategy = c("keep_existing", "merge_recursive", "overwrite_all"),
    measures_path = NULL,
    file_name = NULL,
    overwrite = FALSE,
    quiet = FALSE
) {
  # handle input validation
  merge_strategy <- match.arg(merge_strategy)

  if (!quiet) cli_alert_info("initialising measures database with strategy: {merge_strategy}")

  # handle deprecated overwrite parameter
  if (overwrite && merge_strategy == "keep_existing") {
    merge_strategy <- "overwrite_all"
    if (!quiet) cli_alert_warning("the 'overwrite' parameter is deprecated. please use merge_strategy='overwrite_all' instead.")
  }

  # set default path if not provided
  if (is.null(measures_path)) {
    if (!requireNamespace("here", quietly = TRUE)) {
      if (!quiet) cli_alert_danger("package 'here' is required for default path resolution")
      stop("Package 'here' is required for default path resolution. Please install it or specify 'measures_path' manually.")
    }
    measures_path <- here::here("boilerplate", "data")
    if (!quiet) cli_alert_info("using default path: {measures_path}")
  }

  # create directory if it doesn't exist
  if (!dir.exists(measures_path)) {
    dir.create(measures_path, recursive = TRUE)
    if (!quiet) cli_alert_success("created directory: {measures_path}")
  }

  # default file name
  if (is.null(file_name)) {
    file_name <- "measures_db.rds"
    if (!quiet) cli_alert_info("using default file name: {file_name}")
  }

  # get file path
  file_path <- file.path(measures_path, file_name)
  if (!quiet) cli_alert_info("full file path: {file_path}")

  # get default measures database
  if (!quiet) cli_alert_info("loading default measures database")
  default_db <- get_default_measures_db()

  # check if file exists and apply merge strategy
  file_exists <- file.exists(file_path)
  if (file_exists) {
    action <- if (merge_strategy == "overwrite_all") {
      "overwriting"
    } else {
      "merging with"
    }
    if (!quiet) cli_alert_info("{action} existing measures database file: {file_path}")
  }

  if (file_exists && merge_strategy != "overwrite_all") {
    # load existing database
    if (!quiet) cli_alert_info("loading existing database from {file_path}")
    existing_db <- tryCatch({
      readRDS(file_path)
    }, error = function(e) {
      if (!quiet) cli_alert_danger("error loading existing database: {e$message}")
      return(list())
    })

    # apply selected merge strategy
    if (merge_strategy == "keep_existing") {
      # only add new keys, never modify existing ones
      merged_db <- utils::modifyList(default_db, existing_db, keep.null = TRUE)
      if (!quiet) cli_alert_success("merged measures database (keeping existing entries)")
    } else if (merge_strategy == "merge_recursive") {
      # deep recursive merge, combining nested structures
      merged_db <- merge_recursive_lists(default_db, existing_db)
      if (!quiet) cli_alert_success("recursively merged measures database")
    }

    # save merged database
    if (!quiet) cli_alert_info("saving merged database")
    saveRDS(merged_db, file = file_path)
    if (!quiet) cli_alert_success("updated measures database at: {file_path}")
  } else {
    # save default database
    if (!quiet) cli_alert_info("saving default database")
    saveRDS(default_db, file = file_path)
    action <- if (file_exists) "overwrote" else "created new"
    if (!quiet) cli_alert_success("{action} measures database at: {file_path}")
  }

  if (!quiet) cli_alert_success("measures initialisation complete")
}
# boilerplate_init_measures <- function(
#     merge_strategy = c("keep_existing", "merge_recursive", "overwrite_all"),
#     measures_path = NULL,
#     file_name = NULL,
#     overwrite = FALSE
# ) {
#   # Handle input validation
#   merge_strategy <- match.arg(merge_strategy)
#
#   # Handle deprecated overwrite parameter
#   if (overwrite && merge_strategy == "keep_existing") {
#     merge_strategy <- "overwrite_all"
#     warning("The 'overwrite' parameter is deprecated. Please use merge_strategy='overwrite_all' instead.")
#   }
#
#   # Set default path if not provided
#   if (is.null(measures_path)) {
#     if (!requireNamespace("here", quietly = TRUE)) {
#       stop("Package 'here' is required for default path resolution. Please install it or specify 'measures_path' manually.")
#     }
#     measures_path <- here::here("boilerplate", "data")
#   }
#
#   # Create directory if it doesn't exist
#   if (!dir.exists(measures_path)) {
#     dir.create(measures_path, recursive = TRUE)
#     message(paste("Created directory:", measures_path))
#   }
#
#   # Default file name
#   if (is.null(file_name)) {
#     file_name <- "measures_db.rds"
#   }
#
#   # Get file path
#   file_path <- file.path(measures_path, file_name)
#
#   # Get default measures database
#   default_db <- get_default_measures_db()
#
#   # Check if file exists and apply merge strategy
#   file_exists <- file.exists(file_path)
#   if (file_exists) {
#     action <- if (merge_strategy == "overwrite_all") {
#       "Overwriting"
#     } else {
#       "Merging with"
#     }
#     message(paste(action, "existing measures database file:", file_path))
#   }
#
#   if (file_exists && merge_strategy != "overwrite_all") {
#     # Load existing database
#     existing_db <- tryCatch({
#       readRDS(file_path)
#     }, error = function(e) {
#       warning(paste("Error loading existing database:", e$message))
#       return(list())
#     })
#
#     # Apply selected merge strategy
#     if (merge_strategy == "keep_existing") {
#       # Only add new keys, never modify existing ones
#       merged_db <- utils::modifyList(default_db, existing_db, keep.null = TRUE)
#       message("Merged measures database (keeping existing entries)")
#     } else if (merge_strategy == "merge_recursive") {
#       # Deep recursive merge, combining nested structures
#       merged_db <- merge_recursive_lists(default_db, existing_db)
#       message("Recursively merged measures database")
#     }
#
#     # Save merged database
#     saveRDS(merged_db, file = file_path)
#     message(paste("Updated measures database at:", file_path))
#   } else {
#     # Save default database
#     saveRDS(default_db, file = file_path)
#     action <- if (file_exists) "Overwrote" else "Created new"
#     message(paste(action, "measures database at:", file_path))
#   }
#
#   message("Measures initialization complete.")
# }

