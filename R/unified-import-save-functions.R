#' Import Boilerplate Database(s)
#'
#' This function imports one or more boilerplate databases from disk.
#'
#' @param category Character or character vector. Category of database to import.
#'   Options include "measures", "methods", "results", "discussion", "appendix", "template".
#'   If NULL (default), imports all available categories.
#' @param data_path Character. Base path for data directory.
#'   If NULL (default), uses here::here("boilerplate", "data").
#' @param quiet Logical. If TRUE, suppresses all CLI alerts. Default is FALSE.
#'
#' @return List. The imported database(s). If a single category was requested,
#'   returns that database. If multiple categories were requested, returns a named
#'   list with each category's database.
#'
#' @examples
#' # import just the methods database
#' methods_db <- boilerplate_import("methods")
#'
#' # import multiple specific databases
#' dbs <- boilerplate_import(c("methods", "measures"))
#' methods_db <- dbs$methods
#' measures_db <- dbs$measures
#'
#' # import all databases
#' all_dbs <- boilerplate_import()
#'
#' @importFrom cli cli_alert_info cli_alert_warning cli_alert_danger
#' @importFrom here here
#' @export
boilerplate_import <- function(
    category = NULL,
    data_path = NULL,
    quiet = FALSE
) {
  # define all valid categories
  all_categories <- c("measures", "methods", "results", "discussion", "appendix", "template")

  # if no categories specified, import all
  if (is.null(category)) {
    category <- all_categories
    if (!quiet) cli_alert_info("importing all categories")
  }

  # validate requested categories
  invalid_categories <- setdiff(category, all_categories)
  if (length(invalid_categories) > 0) {
    if (!quiet) cli_alert_danger("invalid categories specified: {paste(invalid_categories, collapse = ', ')}")
    stop("Invalid categories: ", paste(invalid_categories, collapse = ", "))
  }

  # set default path if not provided
  if (is.null(data_path)) {
    if (!requireNamespace("here", quietly = TRUE)) {
      if (!quiet) cli_alert_danger("package 'here' is required for default path resolution")
      stop("Package 'here' is required for default path resolution. Please install it or specify 'data_path' manually.")
    }
    data_path <- here::here("boilerplate", "data")
    if (!quiet) cli_alert_info("using default path: {data_path}")
  }

  # check if directory exists
  if (!dir.exists(data_path)) {
    if (!quiet) cli_alert_warning("data directory does not exist: {data_path}")
  }

  # load each requested database
  result <- list()
  for (cat in category) {
    if (!quiet) cli_alert_info("importing {cat} database")

    file_path <- file.path(data_path, paste0(cat, "_db.rds"))

    if (file.exists(file_path)) {
      if (!quiet) cli_alert_info("loading {cat} database from {file_path}")
      result[[cat]] <- tryCatch({
        readRDS(file_path)
      }, error = function(e) {
        if (!quiet) cli_alert_warning("error loading {cat} database: {e$message}, using default")
        if (cat == "measures") {
          get_default_measures_db()
        } else {
          get_default_db(cat)
        }
      })
    } else {
      if (!quiet) cli_alert_warning("{cat} database file not found, using default")
      if (cat == "measures") {
        result[[cat]] <- get_default_measures_db()
      } else {
        result[[cat]] <- get_default_db(cat)
      }
    }
  }

  # if only one category was requested, return just that database
  if (length(category) == 1) {
    return(result[[category]])
  }

  return(result)
}

#' Save Boilerplate Database
#'
#' This function saves a boilerplate database to disk.
#'
#' @param db List. The database to save.
#' @param category Character. Category of the database.
#'   Options include "measures", "methods", "results", "discussion", "appendix", "template".
#'   If NULL and db is a named list matching category names, saves each category.
#' @param data_path Character. Base path for data directory.
#'   If NULL (default), uses here::here("boilerplate", "data").
#' @param confirm Logical. If TRUE, asks for confirmation before overwriting. Default is TRUE.
#' @param create_dirs Logical. If TRUE, creates directories that don't exist. Default is FALSE.
#' @param quiet Logical. If TRUE, suppresses all CLI alerts. Default is FALSE.
#'
#' @return Invisible. The path(s) where the database(s) was saved.
#'
#' @examples
#' # save a specific database
#' methods_db <- boilerplate_import("methods")
#' methods_db$new_section <- "New content"
#' boilerplate_save(methods_db, "methods")
#'
#' # save multiple databases at once
#' all_dbs <- boilerplate_import()
#' all_dbs$methods$new_section <- "New content"
#' boilerplate_save(all_dbs)
#'
#' @importFrom cli cli_alert_info cli_alert_success cli_alert_warning cli_alert_danger
#' @importFrom here here
#' @export
boilerplate_save <- function(
    db,
    category = NULL,
    data_path = NULL,
    confirm = TRUE,
    create_dirs = FALSE,
    quiet = FALSE
) {
  # define valid categories
  all_categories <- c("measures", "methods", "results", "discussion", "appendix", "template")

  # set default path if not provided
  if (is.null(data_path)) {
    if (!requireNamespace("here", quietly = TRUE)) {
      if (!quiet) cli_alert_danger("package 'here' is required for default path resolution")
      stop("Package 'here' is required for default path resolution. Please install it or specify 'data_path' manually.")
    }
    data_path <- here::here("boilerplate", "data")
    if (!quiet) cli_alert_info("using default path: {data_path}")
  }

  # check if directory exists and handle creation
  if (!dir.exists(data_path)) {
    if (!create_dirs) {
      if (!quiet) cli_alert_danger("directory does not exist: {data_path}")
      stop("Directory does not exist: ", data_path, ". Set create_dirs=TRUE to create it.")
    }

    # ask for confirmation if needed
    proceed <- TRUE
    if (confirm) {
      proceed <- ask_yes_no(paste0("directory does not exist: ", data_path, ". create it?"))
    }

    if (proceed) {
      dir.create(data_path, recursive = TRUE)
      if (!quiet) cli_alert_success("created directory: {data_path}")
    } else {
      if (!quiet) cli_alert_danger("directory creation cancelled by user")
      stop("Directory creation cancelled by user.")
    }
  }

  # handle saving multiple databases at once when category is NULL
  if (is.null(category)) {
    if (!is.list(db) || length(db) == 0) {
      if (!quiet) cli_alert_danger("when category is NULL, db must be a non-empty list")
      stop("When category is NULL, db must be a non-empty named list")
    }

    # check if db has valid category names
    db_names <- names(db)
    if (is.null(db_names) || any(db_names == "")) {
      if (!quiet) cli_alert_danger("when category is NULL, db must be a named list with valid category names")
      stop("When category is NULL, db must be a named list with valid category names")
    }

    # check for invalid categories
    invalid_categories <- setdiff(db_names, all_categories)
    if (length(invalid_categories) > 0) {
      if (!quiet) cli_alert_warning("ignoring invalid categories: {paste(invalid_categories, collapse = ', ')}")
      db_names <- intersect(db_names, all_categories)
    }

    # save each valid category
    saved_paths <- character()
    for (cat in db_names) {
      if (!quiet) cli_alert_info("saving {cat} database")
      path <- boilerplate_save(
        db = db[[cat]],
        category = cat,
        data_path = data_path,
        confirm = confirm,
        create_dirs = FALSE,  # directory already exists or was created
        quiet = quiet
      )
      saved_paths <- c(saved_paths, path)
    }

    return(invisible(saved_paths))
  }

  # validate category when specified
  if (!category %in% all_categories) {
    if (!quiet) cli_alert_danger("invalid category: {category}")
    stop("Invalid category: ", category, ". Must be one of: ", paste(all_categories, collapse = ", "))
  }

  # construct file path
  file_path <- file.path(data_path, paste0(category, "_db.rds"))

  # check if file exists and ask for confirmation if needed
  if (file.exists(file_path) && confirm) {
    proceed <- ask_yes_no(paste0("file exists: ", file_path, ". overwrite?"))
    if (!proceed) {
      if (!quiet) cli_alert_info("save cancelled by user")
      return(invisible(NULL))
    }
  }

  # save the database
  if (!quiet) cli_alert_info("saving {category} database to {file_path}")
  saveRDS(db, file = file_path)
  if (!quiet) cli_alert_success("saved {category} database")

  return(invisible(file_path))
}
