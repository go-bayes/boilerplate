#' Initialize Boilerplate Text Databases
#'
#' This function initializes or updates the boilerplate text databases with default values.
#' It's useful for setting up the system initially or adding new default entries.
#'
#' @param categories Character vector. Categories to initialize.
#' @param merge_strategy Character. How to merge with existing databases: "keep_existing", "merge_recursive", or "overwrite_all".
#' @param text_path Character. Path to the directory where text database files are stored.
#'   If NULL (default), uses the "boilerplate/data/" subdirectory of the current working directory
#'   via the here::here() function. The directory will be created if it doesn't exist.
#' @param overwrite Logical. Whether to overwrite existing entries (deprecated, use merge_strategy instead).
#'
#' @return No return value, called for side effects.
#'
#' @examples
#' \dontrun{
#' # Initialize all categories with default merge strategy
#' boilerplate_init_text()
#'
#' # Initialize only methods
#' boilerplate_init_text("methods")
#'
#' # Use recursive merging
#' boilerplate_init_text(merge_strategy = "merge_recursive")
#'
#' # Completely overwrite existing databases
#' boilerplate_init_text(merge_strategy = "overwrite_all")
#'
#' # Initialize in a specific directory
#' boilerplate_init_text(text_path = "path/to/project/data")
#' }
#'
#' @importFrom utils modifyList
#' @importFrom here here
#' @export
boilerplate_init_text <- function(
    categories = c("measures", "methods", "results", "discussion"),
    merge_strategy = c("keep_existing", "merge_recursive", "overwrite_all"),
    text_path = NULL,
    overwrite = FALSE
) {
  # Handle input validation
  merge_strategy <- match.arg(merge_strategy)

  # Handle deprecated overwrite parameter
  if (overwrite && merge_strategy == "keep_existing") {
    merge_strategy <- "overwrite_all"
    warning("The 'overwrite' parameter is deprecated. Please use merge_strategy='overwrite_all' instead.")
  }

  # Set default path if not provided
  if (is.null(text_path)) {
    if (!requireNamespace("here", quietly = TRUE)) {
      stop("Package 'here' is required for default path resolution. Please install it or specify 'text_path' manually.")
    }
    text_path <- here::here("boilerplate", "data")
  }

  # Create directory if it doesn't exist
  if (!dir.exists(text_path)) {
    dir.create(text_path, recursive = TRUE)
    message(paste("Created directory:", text_path))
  }

  # Process each category
  for (category in categories) {
    # Get default database for category
    default_db <- get_default_db(category)

    # Get file path
    file_path <- file.path(text_path, paste0(category, "_db.rds"))

    # Check if file exists and warn
    file_exists <- file.exists(file_path)
    if (file_exists) {
      action <- if (merge_strategy == "overwrite_all") {
        "Overwriting"
      } else {
        "Merging with"
      }
      message(paste(action, "existing", category, "database file:", file_path))
    }

    # Handle existing files according to merge strategy
    if (file_exists && merge_strategy != "overwrite_all") {
      # Load existing database
      existing_db <- tryCatch({
        readRDS(file_path)
      }, error = function(e) {
        warning(paste("Error loading existing database:", e$message))
        return(list())
      })

      # Apply selected merge strategy
      if (merge_strategy == "keep_existing") {
        # Only add new keys, never modify existing ones
        merged_db <- utils::modifyList(default_db, existing_db, keep.null = TRUE)
        message(paste("Merged", category, "database (keeping existing entries)"))
      } else if (merge_strategy == "merge_recursive") {
        # Deep recursive merge, combining nested structures
        merged_db <- merge_recursive_lists(default_db, existing_db)
        message(paste("Recursively merged", category, "database"))
      }

      # Save merged database
      saveRDS(merged_db, file = file_path)
      message(paste("Updated", category, "database at:", file_path))
    } else {
      # Save default database
      saveRDS(default_db, file = file_path)
      action <- if (file_exists) "Overwrote" else "Created new"
      message(paste(action, category, "database at:", file_path))
    }
  }

  message("Initialization complete.")
}

