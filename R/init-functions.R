#' Get Empty Database Structure for a Category
#'
#' Creates an empty database structure with only top-level entries
#' based on the default database for a category.
#'
#' @param category Character. Category to get empty database structure for.
#'
#' @return List. Empty structure for the category.
#'
#' @noRd
get_empty_db_structure <- function(category) {
  # get the default database first
  default_db <- get_default_db(category)

  # create empty structure based on default
  empty_db <- list()

  # for each top-level entry in the default database
  for (name in names(default_db)) {
    entry <- default_db[[name]]

    # if entry is a list (nested structure), create an empty list
    # otherwise create NULL placeholder
    if (is.list(entry)) {
      empty_db[[name]] <- list()
    } else {
      empty_db[[name]] <- NULL
    }
  }

  return(empty_db)
}

#' Get Empty Measures Database Structure
#'
#' @return List. Empty measures database structure.
#'
#' @noRd
get_empty_measures_db_structure <- function() {
  # for measures, we'll create an example empty structure
  # this could alternatively be based on default measures
  list(
    # example placeholder for an anxiety measure
    anxiety = list(
      name = NULL,
      description = NULL,
      reference = NULL,
      waves = NULL,
      keywords = NULL,
      items = NULL
    )
  )
}

#' Initialise boilerplate Database
#'
#' This function initialises a boilerplate database. By default, it creates a single
#' unified JSON database containing all categories. Legacy support for separate RDS
#' files is maintained through the unified parameter.
#'
#' @param categories Character vector. Categories to include in the database.
#'   Default is all categories: "measures", "methods", "results", "discussion", "appendix", "template".
#' @param merge_strategy Character. How to merge with existing databases: "keep_existing", "merge_recursive", or "overwrite_all".
#' @param data_path Character. Base path for data directory.
#'   If NULL (default), uses tools::R_user_dir("boilerplate", "data").
#' @param quiet Logical. If TRUE, suppresses all CLI alerts. Default is FALSE.
#' @param dry_run Logical. If TRUE, simulates the operation without writing files. Default is FALSE.
#' @param create_dirs Logical. If TRUE, creates directories that don't exist. Default is FALSE.
#' @param confirm Logical. If TRUE, asks for confirmation before making changes. Default is TRUE.
#' @param create_empty Logical. If TRUE, creates empty database structures with just the template headings.
#'   Default is TRUE. Set to FALSE to use default content.
#' @param format Character. Format to save: "json" (default), "rds", or "both".
#' @param project Character. Project name for organizing databases. Default is "default".
#'   Projects are stored in separate subdirectories to allow multiple independent
#'   boilerplate collections.
#'
#' @return Invisibly returns TRUE if successful.
#'
#' @examples
#' # Create a temporary directory for examples
#' temp_dir <- tempdir()
#' data_path <- file.path(temp_dir, "boilerplate_example", "data")
#'
#' # Initialise unified JSON database (new default)
#' boilerplate_init(
#'   data_path = data_path,
#'   create_dirs = TRUE,
#'   create_empty = TRUE,
#'   confirm = FALSE,
#'   quiet = TRUE
#' )
#'
#' # Check that unified JSON file was created
#' list.files(data_path)
#'
#' # Initialise with default content in both formats
#' boilerplate_init(
#'   data_path = data_path,
#'   create_empty = FALSE,
#'   format = "both",
#'   confirm = FALSE,
#'   quiet = TRUE
#' )
#'
#' # Clean up
#' unlink(file.path(temp_dir, "boilerplate_example"), recursive = TRUE)
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
    confirm = TRUE,
    create_empty = TRUE,
    format = "json",
    project = "default"
) {
  merge_strategy <- match.arg(merge_strategy)
  format <- match.arg(format, c("json", "rds", "both"))
  
  # Validate project name
  if (!is.character(project) || length(project) != 1 || project == "") {
    stop("Project must be a non-empty character string")
  }
  
  # Set default path if not provided
  if (is.null(data_path)) {
    # use cran-compliant user directory
    data_path <- file.path(tools::R_user_dir("boilerplate", "data"), "projects", project)
    if (!quiet) cli_alert_info("using project '{project}' at path: {data_path}")
  } else {
    # Check if this looks like a legacy path or test path
    # Don't add project structure if:
    # 1. Path already contains "projects"
    # 2. Path ends with "data" (likely legacy)
    # 3. Path contains temp directory markers (test environment)
    # Use platform-agnostic checks
    if (!grepl("projects", data_path, fixed = TRUE) && 
        !grepl(file.path("", "data"), paste0(data_path, ""), fixed = TRUE) && 
        !grepl("tmp|Temp|TEMP", data_path, ignore.case = TRUE)) {
      # Add project structure for new paths
      data_path <- file.path(data_path, "projects", project, "data")
    }
  }
  
  # Check if directory exists and handle creation
  if (!dir.exists(data_path)) {
    if (!create_dirs) {
      if (!quiet) cli_alert_danger("directory does not exist: {data_path}")
      stop("Directory does not exist: ", data_path, ". Set create_dirs=TRUE to create it.")
    }
    
    # Ask for confirmation if needed
    proceed <- TRUE
    if (confirm && !dry_run) {
      proceed <- ask_yes_no(paste0("directory does not exist: ", data_path, ". create it?"))
    }
    
    if (proceed && !dry_run) {
      tryCatch({
        dir.create(data_path, recursive = TRUE)
        if (!quiet) cli_alert_success("created directory: {data_path}")
      }, warning = function(w) {
        stop(paste("Failed to create directory:", conditionMessage(w)))
      }, error = function(e) {
        stop(paste("Failed to create directory:", conditionMessage(e)))
      })
    } else if (!proceed) {
      if (!quiet) cli_alert_danger("directory creation cancelled by user")
      stop("Directory creation cancelled by user.")
    } else if (dry_run) {
      if (!quiet) cli_alert_info("would create directory: {data_path}")
    }
  }
  
  # Create single unified database
  if (!quiet) cli_alert_info("initialising unified database with {length(categories)} categories")
  if (create_empty && !quiet) cli_alert_info("creating empty database structures")
  
  # Build unified database
  unified_db <- list()
  
  for (category in categories) {
    if (!quiet && !dry_run) cli_alert_info("processing {category} category")
    
    # Get appropriate database based on create_empty flag
    if (create_empty) {
      if (category == "measures") {
        unified_db[[category]] <- get_empty_measures_db_structure()
      } else {
        unified_db[[category]] <- get_empty_db_structure(category)
      }
    } else {
      if (category == "measures") {
        unified_db[[category]] <- get_default_measures_db()
      } else {
        unified_db[[category]] <- get_default_db(category)
      }
    }
  }
  
  if (dry_run) {
    if (!quiet) cli_alert_info("would save unified database as {format} format")
    if (!quiet) cli_alert_success("dry run completed")
    return(invisible(TRUE))
  }
  
  # Check for existing unified database and handle merge strategy
  existing_files <- c(
    file.path(data_path, "boilerplate_unified.json"),
    file.path(data_path, "boilerplate_unified.rds")
  )
  existing_file <- existing_files[file.exists(existing_files)][1]
  
  if (!is.na(existing_file) && merge_strategy != "overwrite_all") {
    # Ask for confirmation BEFORE loading
    proceed <- TRUE
    if (confirm) {
      action_desc <- if (merge_strategy == "keep_existing") {
        "update existing unified database (keeping existing entries)"
      } else {
        "recursively merge with existing unified database"
      }
      proceed <- ask_yes_no(paste0(action_desc, ": ", existing_file, "?"))
    }
    
    if (!proceed) {
      if (!quiet) cli_alert_info("unified database update cancelled by user")
      return(invisible(FALSE))
    }
    
    # Load existing database
    if (!quiet) cli_alert_info("loading existing unified database")
    existing_db <- read_boilerplate_db(existing_file)
    
    # Apply merge strategy
    if (merge_strategy == "keep_existing") {
      # Only add new keys, never modify existing ones
      for (cat in names(unified_db)) {
        if (cat %in% names(existing_db)) {
          unified_db[[cat]] <- utils::modifyList(unified_db[[cat]], existing_db[[cat]], keep.null = TRUE)
        }
      }
      if (!quiet) cli_alert_success("merged unified database (keeping existing entries)")
    } else if (merge_strategy == "merge_recursive") {
      # Deep recursive merge
      for (cat in names(unified_db)) {
        if (cat %in% names(existing_db)) {
          unified_db[[cat]] <- merge_recursive_lists(unified_db[[cat]], existing_db[[cat]])
        }
      }
      if (!quiet) cli_alert_success("recursively merged unified database")
    }
  } else if (!is.na(existing_file) && merge_strategy == "overwrite_all") {
    # Ask for confirmation before overwriting
    proceed <- TRUE
    if (confirm) {
      proceed <- ask_yes_no(paste0("overwrite existing unified database: ", existing_file, "?"))
    }
    
    if (!proceed) {
      if (!quiet) cli_alert_info("unified database creation cancelled by user")
      return(invisible(FALSE))
    }
  }
  
  # Save unified database
  if (!quiet) cli_alert_info("saving unified database")
  
  boilerplate_save(
    db = unified_db,
    data_path = data_path,
    format = format,
    confirm = FALSE,  # Already confirmed above
    quiet = quiet,
    timestamp = FALSE  # Don't timestamp init files
  )
  
  if (!quiet) cli_alert_success("unified database initialisation complete")
  
  return(invisible(TRUE))
}


# Internal helper functions only - not exported

# The deprecated init functions have been removed entirely
# Use boilerplate_init() for all initialization needs

