#' Initialize All Boilerplate Databases
#'
#' This function initializes or updates all boilerplate databases with default values.
#' It's a convenience wrapper around boilerplate_init_category() for all categories.
#'
#' @param categories Character vector. Categories to initialize.
#'   Default is all categories: "measures", "methods", "results", "discussion", "appendix", "template".
#' @param merge_strategy Character. How to merge with existing databases: "keep_existing", "merge_recursive", or "overwrite_all".
#' @param data_path Character. Base path for data directory.
#'   If NULL (default), uses here::here("boilerplate", "data").
#' @param quiet Logical. If TRUE, suppresses all CLI alerts. Default is FALSE.
#' @param dry_run Logical. If TRUE, simulates the operation without writing files. Default is FALSE.
#' @param create_dirs Logical. If TRUE, creates directories that don't exist. Default is FALSE.
#' @param confirm Logical. If TRUE, asks for confirmation before making changes. Default is TRUE.
#'
#' @return Invisibly returns a logical vector indicating which categories were successfully initialized.
#'
#' @examples
#' \dontrun{
#' # run in dry-run mode first to see what would happen
#' boilerplate_init(dry_run = TRUE)
#'
#' # initialize all databases with confirmation prompts
#' boilerplate_init(create_dirs = TRUE)
#'
#' # initialize specific categories only
#' boilerplate_init(
#'   categories = c("methods", "measures"),
#'   create_dirs = TRUE,
#'   confirm = FALSE
#' )
#' }
#'
#' @importFrom cli cli_alert_info cli_alert_success
#' @export
boilerplate_init <- function(
    categories = c("measures", "methods", "results", "discussion", "appendix", "template"),
    merge_strategy = c("keep_existing", "merge_recursive", "overwrite_all"),
    data_path = NULL,
    quiet = FALSE,
    dry_run = FALSE,
    create_dirs = FALSE,
    confirm = TRUE
) {
  merge_strategy <- match.arg(merge_strategy)

  if (!quiet) cli_alert_info("initializing {length(categories)} databases with strategy: {merge_strategy}")

  # track initialization status for each category
  initialization_status <- logical(length(categories))
  names(initialization_status) <- categories

  for (i in seq_along(categories)) {
    category <- categories[i]
    if (!quiet) cli_alert_info("initializing {category} database")

    # call boilerplate_init_category and capture result
    initialization_status[i] <- boilerplate_init_category(
      category = category,
      merge_strategy = merge_strategy,
      data_path = data_path,
      quiet = quiet,
      dry_run = dry_run,
      create_dirs = create_dirs,
      confirm = confirm
    )
  }

  # count successful initializations
  successful <- sum(initialization_status)
  canceled <- length(categories) - successful

  if (!quiet) {
    if (dry_run) {
      cli_alert_success("dry run completed for all {length(categories)} categories")
    } else if (canceled == 0) {
      cli_alert_success("initialization complete for all {length(categories)} categories")
    } else if (successful == 0) {
      cli_alert_info("initialization canceled for all {length(categories)} categories")
    } else {
      successful_cats <- names(initialization_status)[initialization_status]
      canceled_cats <- names(initialization_status)[!initialization_status]

      cli_alert_info("initialization complete for {successful}/{length(categories)} categories")
      if (!quiet && successful > 0) {
        cli_alert_info("completed: {paste(successful_cats, collapse = ', ')}")
      }
      if (!quiet && canceled > 0) {
        cli_alert_info("canceled: {paste(canceled_cats, collapse = ', ')}")
      }
    }
  }

  # return invisible status
  invisible(initialization_status)
}


#' Initialize a Specific Boilerplate Database Category
#'
#' This function initializes or updates a specific boilerplate database category with default values.
#'
#' @param category Character. Category to initialize.
#'   Options include "measures", "methods", "results", "discussion", "appendix", "template".
#' @param merge_strategy Character. How to merge with existing database: "keep_existing", "merge_recursive", or "overwrite_all".
#' @param data_path Character. Base path for data directory.
#'   If NULL (default), uses here::here("boilerplate", "data").
#' @param quiet Logical. If TRUE, suppresses all CLI alerts. Default is FALSE.
#' @param dry_run Logical. If TRUE, simulates the operation without writing files. Default is FALSE.
#' @param create_dirs Logical. If TRUE, creates directories that don't exist. Default is FALSE.
#' @param confirm Logical. If TRUE, asks for confirmation before making changes. Default is TRUE.
#'
#' @return Logical. TRUE if initialization was successful, FALSE if canceled.
#'
#' @examples
#' \dontrun{
#' # initialize the methods database
#' boilerplate_init_category("methods", create_dirs = TRUE)
#'
#' # initialize measures database with recursive merging
#' boilerplate_init_category(
#'   category = "measures",
#'   merge_strategy = "merge_recursive",
#'   create_dirs = TRUE
#' )
#' }
#'
#' @importFrom utils modifyList
#' @importFrom cli cli_alert_info cli_alert_success cli_alert_warning cli_alert_danger
#' @export
boilerplate_init_category <- function(
    category,
    merge_strategy = c("keep_existing", "merge_recursive", "overwrite_all"),
    data_path = NULL,
    quiet = FALSE,
    dry_run = FALSE,
    create_dirs = FALSE,
    confirm = TRUE
) {
  # validate category
  all_categories <- c("measures", "methods", "results", "discussion", "appendix", "template")
  if (!category %in% all_categories) {
    if (!quiet) cli_alert_danger("invalid category: {category}")
    stop("Invalid category: ", category, ". Must be one of: ", paste(all_categories, collapse = ", "))
  }

  merge_strategy <- match.arg(merge_strategy)

  if (!quiet) cli_alert_info("initializing {category} database with strategy: {merge_strategy}")
  if (dry_run && !quiet) cli_alert_info("dry run mode: no files will be written")

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
    if (confirm && !dry_run) {
      proceed <- ask_yes_no(paste0("directory does not exist: ", data_path, ". create it?"))
    }

    if (proceed && !dry_run) {
      dir.create(data_path, recursive = TRUE)
      if (!quiet) cli_alert_success("created directory: {data_path}")
    } else if (!proceed) {
      if (!quiet) cli_alert_danger("directory creation cancelled by user")
      stop("Directory creation cancelled by user.")
    } else if (dry_run) {
      if (!quiet) cli_alert_info("would create directory: {data_path}")
    }
  }

  # get file path
  file_path <- file.path(data_path, paste0(category, "_db.rds"))

  # get default database for the category
  if (!quiet) cli_alert_info("loading default {category} database")
  if (category == "measures") {
    default_db <- get_default_measures_db()
  } else {
    default_db <- get_default_db(category)
  }

  # check if file exists and determine operation type
  file_exists <- file.exists(file_path)

  # handle existing file according to merge strategy
  if (file_exists && merge_strategy != "overwrite_all") {
    if (dry_run) {
      if (!quiet) cli_alert_info("would load and merge existing {category} database from {file_path}")
      if (!quiet) cli_alert_success("dry run completed for {category}")
      return(TRUE) # consider dry runs as successful
    }

    # ask for confirmation BEFORE showing merging message
    proceed <- TRUE
    if (confirm) {
      if (merge_strategy == "keep_existing") {
        action_desc <- "update existing file (keeping existing entries)"
      } else if (merge_strategy == "merge_recursive") {
        action_desc <- "recursively merge with existing file"
      } else {
        action_desc <- "modify existing file"
      }
      proceed <- ask_yes_no(paste0(action_desc, ": ", file_path, "?"))
    }

    if (!proceed) {
      if (!quiet) cli_alert_info("{category} database update cancelled by user")
      return(FALSE) # return FALSE to indicate cancellation
    }

    # Now that user has confirmed, show the action message
    if (!quiet) cli_alert_info("loading existing {category} database from {file_path}")

    # load existing database
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
    # handle overwrite all or new file creation
    if (dry_run) {
      action <- if (file_exists) "would overwrite" else "would create new"
      if (!quiet) cli_alert_info("{action} {category} database at: {file_path}")
      if (!quiet) cli_alert_success("dry run completed for {category}")
      return(TRUE) # consider dry runs as successful
    }

    # ask for confirmation if needed and file exists
    proceed <- TRUE
    if (confirm && file_exists && merge_strategy == "overwrite_all") {
      proceed <- ask_yes_no(paste0("overwrite existing file: ", file_path, "?"))
    }

    if (!proceed) {
      if (!quiet) cli_alert_info("{category} database creation/overwrite cancelled by user")
      return(FALSE) # return FALSE to indicate cancellation
    }

    # Now that user has confirmed, show the action message
    action <- if (file_exists) "overwriting" else "creating new"
    if (!quiet) cli_alert_info("{action} {category} database at: {file_path}")

    # save default database
    saveRDS(default_db, file = file_path)
    action <- if (file_exists) "overwrote" else "created new"
    if (!quiet) cli_alert_success("{action} {category} database at: {file_path}")
  }

  if (!quiet) cli_alert_success("{category} initialization complete")
  return(TRUE) # return TRUE to indicate successful initialization
}

#' Initialize Boilerplate Text Databases (Deprecated)
#'
#' This function is deprecated. Please use boilerplate_init() instead.
#'
#' @param categories Character vector. Categories to initialize.
#' @param merge_strategy Character. How to merge with existing databases.
#' @param text_path Character. Path to the directory where text database files are stored.
#' @param overwrite Logical. Whether to overwrite existing entries (deprecated).
#' @param quiet Logical. If TRUE, suppresses all CLI alerts.
#' @param dry_run Logical. If TRUE, simulates the operation without writing files.
#' @param create_dirs Logical. If TRUE, creates directories that don't exist.
#' @param confirm Logical. If TRUE, asks for confirmation before making changes.
#'
#' @return Invisibly returns a logical vector indicating which categories were successfully initialized.
#'
#' @importFrom cli cli_alert_warning cli_alert_info
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
  # issue deprecation warning
  warning(
    "boilerplate_init_text() is deprecated. ",
    "Please use boilerplate_init() instead.",
    call. = FALSE
  )

  # forward to new function
  merge_strategy <- match.arg(merge_strategy)

  # handle deprecated overwrite parameter
  if (overwrite && merge_strategy == "keep_existing") {
    merge_strategy <- "overwrite_all"
    if (!quiet) cli_alert_warning("the 'overwrite' parameter is deprecated. please use merge_strategy='overwrite_all' instead.")
  }

  # check if 'measures' is in categories and warn
  if ("measures" %in% categories) {
    if (!quiet) cli_alert_warning("'measures' category should be initialized using boilerplate_init_measures() or the new boilerplate_init()")
    categories <- setdiff(categories, "measures")
    if (!quiet) cli_alert_info("'measures' category removed from initialization list")
  }

  # call new function and return its result
  result <- boilerplate_init(
    categories = categories,
    merge_strategy = merge_strategy,
    data_path = text_path,
    quiet = quiet,
    dry_run = dry_run,
    create_dirs = create_dirs,
    confirm = confirm
  )

  return(invisible(result))
}

#' Initialize Boilerplate Measures Database (Deprecated)
#'
#' This function is deprecated. Please use boilerplate_init("measures") instead.
#'
#' @param merge_strategy Character. How to merge with existing database.
#' @param measures_path Character. Path to the directory where measures database files are stored.
#' @param file_name Character. Name of the file to save or load (without path).
#' @param overwrite Logical. Whether to overwrite existing entries (deprecated).
#' @param quiet Logical. If TRUE, suppresses all CLI alerts.
#' @param dry_run Logical. If TRUE, simulates the operation without writing files.
#' @param create_dirs Logical. If TRUE, creates directories that don't exist.
#' @param confirm Logical. If TRUE, asks for confirmation before making changes.
#'
#' @return Invisibly returns a logical value indicating if the measures database was successfully initialized.
#'
#' @importFrom cli cli_alert_warning
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
  # issue deprecation warning
  warning(
    "boilerplate_init_measures() is deprecated. ",
    "Please use boilerplate_init(\"measures\") instead.",
    call. = FALSE
  )

  # forward to new function
  merge_strategy <- match.arg(merge_strategy)

  # handle deprecated overwrite parameter
  if (overwrite && merge_strategy == "keep_existing") {
    merge_strategy <- "overwrite_all"
    if (!quiet) cli_alert_warning("the 'overwrite' parameter is deprecated. please use merge_strategy='overwrite_all' instead.")
  }

  # if custom file_name is specified, warn
  if (!is.null(file_name)) {
    if (!quiet) cli_alert_warning("custom file_name is not supported in the new unified system")
  }

  # call new function and get result
  result <- boilerplate_init(
    categories = "measures",
    merge_strategy = merge_strategy,
    data_path = measures_path,
    quiet = quiet,
    dry_run = dry_run,
    create_dirs = create_dirs,
    confirm = confirm
  )

  # return just the measures result (first element of the vector)
  return(invisible(result["measures"]))
}

