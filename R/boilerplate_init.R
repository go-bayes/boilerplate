#' Initialise Boilerplate Text Databases
#'
#' This function initialises or updates the boilerplate text databases with default values.
#' It's useful for setting up the system initially or adding new default entries.
#'
#' @param categories Character vector. Categories to initialise.
#'   Note: The "measures" category should be initialised using \code{boilerplate_init_measures()}.
#' @param merge_strategy Character. How to merge with existing databases: "keep_existing", "merge_recursive", or "overwrite_all".
#' @param text_path Character. Path to the directory where text database files are stored.
#'   If NULL (default), uses the "boilerplate/data/" subdirectory of the current working directory
#'   via the here::here() function.
#' @param overwrite Logical. Whether to overwrite existing entries (deprecated, use merge_strategy instead).
#' @param quiet Logical. If TRUE, suppresses all CLI alerts. Default is FALSE.
#' @param dry_run Logical. If TRUE, simulates the operation without writing files. Default is FALSE.
#' @param create_dirs Logical. If TRUE, creates directories that don't exist. Default is FALSE.
#' @param confirm Logical. If TRUE, asks for confirmation before making changes. Default is TRUE.
#'
#' @return No return value, called for side effects.
#'
#' @examples
#' \dontrun{
#' # Run in dry-run mode first to see what would happen
#' boilerplate_init_text(dry_run = TRUE)
#'
#' # Initialise all categories with confirmation prompts
#' boilerplate_init_text(create_dirs = TRUE)
#'
#' # Initialise only methods, skipping confirmation
#' boilerplate_init_text("methods", create_dirs = TRUE, confirm = FALSE)
#'
#' # Initialise specific categories including the new ones
#' boilerplate_init_text(
#'   categories = c("methods", "template", "appendix"),
#'   create_dirs = TRUE
#' )
#'
#' # Initialise in a specific existing directory
#' boilerplate_init_text(text_path = "path/to/existing/data")
#' }
#'
#' @importFrom utils modifyList
#' @importFrom here here
#' @importFrom cli cli_alert_info cli_alert_success cli_alert_warning cli_alert_danger cli_alert_danger
#' @export
boilerplate_init_text <- function(
    categories = c("methods", "results", "discussion", "appendix", "template"),
    merge_strategy = c("keep_existing", "merge_recursive", "overwrite_all"),
    text_path = NULL,
    overwrite = FALSE,
    quiet = FALSE,
    dry_run = FALSE,
    create_dirs = FALSE,
    confirm = TRUE
) {
  # handle input validation
  merge_strategy <- match.arg(merge_strategy)

  if (!quiet) cli_alert_info("initialising {length(categories)} text databases with strategy: {merge_strategy}")
  if (dry_run && !quiet) cli_alert_info("dry run mode: no files will be written")

  # check if 'measures' is in categories and warn that it should be initialised separately
  if ("measures" %in% categories) {
    if (!quiet) cli_alert_warning("'measures' category should be initialised using boilerplate_init_measures()")
    categories <- setdiff(categories, "measures")
    if (!quiet) cli_alert_info("'measures' category removed from initialisation list")
  }

  # handle deprecated overwrite parameter
  if (overwrite && merge_strategy == "keep_existing") {
    merge_strategy <- "overwrite_all"
    if (!quiet) cli_alert_warning("the 'overwrite' parameter is deprecated. please use merge_strategy='overwrite_all' instead.")
  }

  # set default path if not provided
  if (is.null(text_path)) {
    if (!requireNamespace("here", quietly = TRUE)) {
      if (!quiet) cli_alert_danger("package 'here' is required for default path resolution")
      stop("Package 'here' is required for default path resolution. Please install it or specify 'text_path' manually.")
    }
    text_path <- here::here("boilerplate", "data")
    if (!quiet) cli_alert_info("using default path: {text_path}")
  }

  # check if directory exists
  dir_exists <- dir.exists(text_path)

  # handle directory creation
  if (!dir_exists) {
    if (!create_dirs) {
      if (!quiet) cli_alert_danger("directory does not exist: {text_path}")
      stop("Directory does not exist. Set create_dirs=TRUE to create it or specify an existing directory.")
    }

    # ask for confirmation if needed
    proceed <- TRUE
    if (confirm && !dry_run) {
      proceed <- ask_yes_no(paste0("Directory does not exist: ", text_path, ". Create it?"))
    }

    if (proceed && !dry_run) {
      dir.create(text_path, recursive = TRUE)
      if (!quiet) cli_alert_success("created directory: {text_path}")
    } else if (!proceed) {
      if (!quiet) cli_alert_danger("directory creation cancelled by user")
      stop("Directory creation cancelled by user.")
    } else if (dry_run) {
      if (!quiet) cli_alert_info("would create directory: {text_path}")
    }
  }

  # process each category
  for (category in categories) {
    if (!quiet) cli_alert_info("processing category: {category}")

    # get default database for category
    if (!quiet) cli_alert_info("loading default {category} database")
    default_db <- get_default_db(category)

    # get file path
    file_path <- file.path(text_path, paste0(category, "_db.rds"))
    if (!quiet) cli_alert_info("full file path: {file_path}")

    # check if file exists and warn
    file_exists <- file.exists(file_path)
    if (file_exists) {
      action <- if (merge_strategy == "overwrite_all") {
        "overwriting"
      } else {
        "merging with"
      }
      if (!quiet) cli_alert_info("{action} existing {category} database file: {file_path}")
    }

    # handle existing files according to merge strategy
    if (file_exists && merge_strategy != "overwrite_all") {
      if (dry_run) {
        if (!quiet) cli_alert_info("would load and merge existing {category} database from {file_path}")
        next
      }

      # ask for confirmation if needed
      proceed <- TRUE
      if (confirm) {
        proceed <- ask_yes_no(paste0("Modify existing file: ", file_path, "?"))
      }

      if (!proceed) {
        if (!quiet) cli_alert_info("skipping {category} database update")
        next
      }

      # load existing database
      if (!quiet) cli_alert_info("loading existing {category} database from {file_path}")
      existing_db <- tryCatch({
        readRDS(file_path)
      }, error = function(e) {
        if (!quiet) cli_alert_danger("error loading existing {category} database: {e$message}")
        return(list())
      })

      # apply selected merge strategy
      if (merge_strategy == "keep_existing") {
        # only add new keys, never modify existing ones
        merged_db <- utils::modifyList(default_db, existing_db, keep.null = TRUE)
        if (!quiet) cli_alert_success("merged {category} database (keeping existing entries)")
      } else if (merge_strategy == "merge_recursive") {
        # deep recursive merge, combining nested structures
        merged_db <- merge_recursive_lists(default_db, existing_db)
        if (!quiet) cli_alert_success("recursively merged {category} database")
      }

      # save merged database
      if (!quiet) cli_alert_info("saving merged {category} database")
      saveRDS(merged_db, file = file_path)
      if (!quiet) cli_alert_success("updated {category} database at: {file_path}")
    } else {
      if (dry_run) {
        action <- if (file_exists) "would overwrite" else "would create new"
        if (!quiet) cli_alert_info("{action} {category} database at: {file_path}")
        next
      }

      # ask for confirmation if needed and file exists
      proceed <- TRUE
      if (confirm && file_exists && merge_strategy == "overwrite_all") {
        proceed <- ask_yes_no(paste0("Overwrite existing file: ", file_path, "?"))
      }

      if (!proceed) {
        if (!quiet) cli_alert_info("skipping {category} database creation/overwrite")
        next
      }

      # save default database
      if (!quiet) cli_alert_info("saving default {category} database")
      saveRDS(default_db, file = file_path)
      action <- if (file_exists) "overwrote" else "created new"
      if (!quiet) cli_alert_success("{action} {category} database at: {file_path}")
    }
  }

  if (!quiet) {
    if (dry_run) {
      cli_alert_success("dry run completed for all {length(categories)} categories")
    } else {
      cli_alert_success("initialisation complete for all {length(categories)} categories")
    }
  }
}

#' Initialise Boilerplate Measures Database
#'
#' This function initialises or updates the boilerplate measures database with default values.
#' It's useful for setting up the system initially or adding new default entries.
#'
#' @param merge_strategy Character. How to merge with existing database: "keep_existing", "merge_recursive", or "overwrite_all".
#' @param measures_path Character. Path to the directory where measures database files are stored.
#'   If NULL (default), uses the "boilerplate/data/" subdirectory of the current working directory
#'   via the here::here() function.
#' @param file_name Character. Name of the file to save or load (without path).
#'   If NULL (default), uses "measures_db.rds".
#' @param overwrite Logical. Whether to overwrite existing entries (deprecated, use merge_strategy instead).
#' @param quiet Logical. If TRUE, suppresses all CLI alerts. Default is FALSE.
#' @param dry_run Logical. If TRUE, simulates the operation without writing files. Default is FALSE.
#' @param create_dirs Logical. If TRUE, creates directories that don't exist. Default is FALSE.
#' @param confirm Logical. If TRUE, asks for confirmation before making changes. Default is TRUE.
#'
#' @return No return value, called for side effects.
#'
#' @examples
#' \dontrun{
#' # Run in dry-run mode first to see what would happen
#' boilerplate_init_measures(dry_run = TRUE)
#'
#' # Initialise with confirmation prompts, creating directory if needed
#' boilerplate_init_measures(create_dirs = TRUE)
#'
#' # Use recursive merging, skipping confirmation
#' boilerplate_init_measures(
#'   merge_strategy = "merge_recursive",
#'   create_dirs = TRUE,
#'   confirm = FALSE
#' )
#'
#' # Initialise in a specific existing directory with a custom file name
#' boilerplate_init_measures(
#'   measures_path = "path/to/existing/data",
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
    quiet = FALSE,
    dry_run = FALSE,
    create_dirs = FALSE,
    confirm = TRUE
) {
  # handle input validation
  merge_strategy <- match.arg(merge_strategy)

  if (!quiet) cli::cli_alert_info("initialising measures database with strategy: {merge_strategy}")
  if (dry_run && !quiet) cli::cli_alert_info("dry run mode: no files will be written")

  # handle deprecated overwrite parameter
  if (overwrite && merge_strategy == "keep_existing") {
    merge_strategy <- "overwrite_all"
    if (!quiet) cli::cli_alert_warning("the 'overwrite' parameter is deprecated. please use merge_strategy='overwrite_all' instead.")
  }

  # set default path if not provided
  if (is.null(measures_path)) {
    if (!requireNamespace("here", quietly = TRUE)) {
      if (!quiet) cli::cli_alert_danger("package 'here' is required for default path resolution")
      stop("Package 'here' is required for default path resolution. Please install it or specify 'measures_path' manually.")
    }
    measures_path <- here::here("boilerplate", "data")
    if (!quiet) cli::cli_alert_info("using default path: {measures_path}")
  }

  # check if directory exists
  dir_exists <- dir.exists(measures_path)

  # handle directory creation
  if (!dir_exists) {
    if (!create_dirs) {
      if (!quiet) cli::cli_alert_danger("directory does not exist: {measures_path}")
      stop("Directory does not exist. Set create_dirs=TRUE to create it or specify an existing directory.")
    }

    # ask for confirmation if needed
    proceed <- TRUE
    if (confirm && !dry_run) {
      proceed <- ask_yes_no(paste0("Directory does not exist: ", measures_path, ". Create it?"))
    }

    if (proceed && !dry_run) {
      dir.create(measures_path, recursive = TRUE)
      if (!quiet) cli::cli_alert_success("created directory: {measures_path}")
    } else if (!proceed) {
      if (!quiet) cli::cli_alert_danger("directory creation cancelled by user")
      stop("Directory creation cancelled by user.")
    } else if (dry_run) {
      if (!quiet) cli::cli_alert_info("would create directory: {measures_path}")
    }
  }

  # default file name
  if (is.null(file_name)) {
    file_name <- "measures_db.rds"
    if (!quiet) cli::cli_alert_info("using default file name: {file_name}")
  }

  # get file path
  file_path <- file.path(measures_path, file_name)
  if (!quiet) cli::cli_alert_info("full file path: {file_path}")

  # get default measures database
  if (!quiet) cli::cli_alert_info("loading default measures database")
  default_db <- get_default_measures_db()

  # check if file exists and apply merge strategy
  file_exists <- file.exists(file_path)
  if (file_exists) {
    action <- if (merge_strategy == "overwrite_all") {
      "overwriting"
    } else {
      "merging with"
    }
    if (!quiet) cli::cli_alert_info("{action} existing measures database file: {file_path}")
  }

  if (file_exists && merge_strategy != "overwrite_all") {
    if (dry_run) {
      if (!quiet) cli::cli_alert_info("would load and merge existing database from {file_path}")
      if (!quiet) cli::cli_alert_success("dry run completed")
      return(invisible())
    }

    # ask for confirmation if needed
    proceed <- TRUE
    if (confirm) {
      proceed <- ask_yes_no(paste0("Modify existing file: ", file_path, "?"))
    }

    if (!proceed) {
      if (!quiet) cli::cli_alert_info("measures database update cancelled by user")
      return(invisible())
    }

    # load existing database
    if (!quiet) cli::cli_alert_info("loading existing database from {file_path}")
    existing_db <- tryCatch({
      readRDS(file_path)
    }, error = function(e) {
      if (!quiet) cli::cli_alert_danger("error loading existing database: {e$message}")
      return(list())
    })

    # apply selected merge strategy
    if (merge_strategy == "keep_existing") {
      # only add new keys, never modify existing ones
      merged_db <- utils::modifyList(default_db, existing_db, keep.null = TRUE)
      if (!quiet) cli::cli_alert_success("merged measures database (keeping existing entries)")
    } else if (merge_strategy == "merge_recursive") {
      # deep recursive merge, combining nested structures
      merged_db <- merge_recursive_lists(default_db, existing_db)
      if (!quiet) cli::cli_alert_success("recursively merged measures database")
    }

    # save merged database
    if (!quiet) cli::cli_alert_info("saving merged database")
    saveRDS(merged_db, file = file_path)
    if (!quiet) cli::cli_alert_success("updated measures database at: {file_path}")
  } else {
    if (dry_run) {
      action <- if (file_exists) "would overwrite" else "would create new"
      if (!quiet) cli::cli_alert_info("{action} measures database at: {file_path}")
      if (!quiet) cli::cli_alert_success("dry run completed")
      return(invisible())
    }

    # ask for confirmation if needed and file exists
    proceed <- TRUE
    if (confirm && file_exists && merge_strategy == "overwrite_all") {
      proceed <- ask_yes_no(paste0("Overwrite existing file: ", file_path, "?"))
    }

    if (!proceed) {
      if (!quiet) cli::cli_alert_info("measures database creation/overwrite cancelled by user")
      return(invisible())
    }

    # save default database
    if (!quiet) cli::cli_alert_info("saving default database")
    saveRDS(default_db, file = file_path)
    action <- if (file_exists) "overwrote" else "created new"
    if (!quiet) cli::cli_alert_success("{action} measures database at: {file_path}")
  }

  if (!quiet) cli::cli_alert_success("measures initialisation complete")
}
