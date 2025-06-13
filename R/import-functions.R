#' Import boilerplate Database(s)
#'
#' This function imports one or more boilerplate databases from disk. It automatically
#' detects the file format (RDS or JSON) based on file extension. The function can
#' import from a directory (original behaviour) or from a specific file path (new).
#'
#' @param category Character or character vector. Category of database to import.
#'   Options include "measures", "methods", "results", "discussion", "appendix", "template".
#'   If NULL (default), imports all available categories as a unified database.
#'   Ignored if data_path points to a specific file.
#' @param data_path Character. Can be either:
#'   - A directory path containing database files (original behaviour)
#'   - A specific file path to import (e.g., "data/methods_db_20240115_143022.rds")
#'   If NULL (default), uses here::here("boilerplate", "data").
#' @param quiet Logical. If TRUE, suppresses all CLI alerts. Default is FALSE.
#' @param project Character. Project name for organizing databases. Default is "default".
#'   Projects are stored in separate subdirectories to allow multiple independent
#'   boilerplate collections.
#'
#' @return List. The imported database(s). If a single category was requested,
#'   returns that database. If multiple categories were requested, returns a
#'   unified database with each category as a named element.
#'
#' @examples
#' # Create a temporary directory and initialise databases
#' temp_dir <- tempdir()
#' data_path <- file.path(temp_dir, "boilerplate_import_example", "data")
#'
#' # Initialise some databases first
#' boilerplate_init(
#'   categories = c("methods", "measures"),
#'   data_path = data_path,
#'   create_dirs = TRUE,
#'   create_empty = FALSE,
#'   confirm = FALSE,
#'   quiet = TRUE
#' )
#'
#' # Import all databases as unified (new default)
#' unified_db <- boilerplate_import(data_path = data_path, quiet = TRUE)
#' names(unified_db)
#'
#' # Access specific category
#' methods_db <- unified_db$methods
#' names(methods_db)
#'
#' # Import from a specific file (e.g., timestamped or backup)
#' # First, save with timestamp to create a timestamped file
#' boilerplate_save(
#'   methods_db,
#'   category = "methods",
#'   data_path = data_path,
#'   timestamp = TRUE,
#'   confirm = FALSE,
#'   quiet = TRUE
#' )
#'
#' # List files to see what's available
#' list.files(data_path, pattern = "methods.*\\.rds")
#'
#' # Import the timestamped file directly
#' timestamped_file <- list.files(
#'   data_path, 
#'   pattern = "methods.*_\\d{8}_\\d{6}\\.rds", 
#'   full.names = TRUE
#' )[1]
#' if (length(timestamped_file) > 0 && file.exists(timestamped_file)) {
#'   methods_timestamped <- boilerplate_import(
#'     data_path = timestamped_file, 
#'     quiet = TRUE
#'   )
#' }
#'
#' # Clean up
#' unlink(file.path(temp_dir, "boilerplate_import_example"), recursive = TRUE)
#'
#' @importFrom cli cli_alert_info cli_alert_success cli_alert_warning
#' @importFrom here here
#' @export
boilerplate_import <- function(category = NULL, data_path = NULL, quiet = FALSE, project = "default") {
  # Validate project name
  if (!is.character(project) || length(project) != 1 || project == "") {
    stop("Project must be a non-empty character string")
  }
  
  # Check if data_path is a specific file first
  is_file_path <- !is.null(data_path) && file.exists(data_path) && !dir.exists(data_path)
  
  # Set default data path or append project if directory
  if (is.null(data_path)) {
    data_path <- here::here("boilerplate", "projects", project, "data")
  } else if (!is_file_path) {
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

  # Check if data_path is a file (new functionality)
  if (is_file_path) {
    # Direct file import
    if (!quiet) cli_alert_info("Importing from file: {basename(data_path)}")
    
    # Check file extension
    if (!grepl("\\.(rds|json)$", data_path, ignore.case = TRUE)) {
      stop("File must have .rds or .json extension: ", data_path)
    }
    
    # Read the file
    db <- read_boilerplate_db(data_path)
    
    # Try to determine what type of database this is
    if (is.list(db)) {
      db_names <- names(db)
      categories <- c("measures", "methods", "results", "discussion", "appendix", "template")
      
      # Check if it's a unified database
      if (any(categories %in% db_names)) {
        if (!quiet) cli_alert_success("Imported unified database from {basename(data_path)}")
      } else {
        # Single category database
        category_name <- gsub("_db.*$", "", basename(data_path))
        if (!quiet) cli_alert_success("Imported {category_name} database from {basename(data_path)}")
      }
    }
    
    return(db)
  }

  # Original behaviour: data_path is a directory
  if (!dir.exists(data_path)) {
    stop("Data path does not exist: ", data_path)
  }

  # If no category specified, import all available
  if (is.null(category)) {
    categories <- c("measures", "methods", "results", "discussion", "appendix", "template")
    unified_db <- list()

    # Try each category with both RDS and JSON extensions
    for (cat in categories) {
      # Check for RDS first (backward compatibility)
      rds_path <- file.path(data_path, paste0(cat, "_db.rds"))
      json_path <- file.path(data_path, paste0(cat, "_db.json"))

      if (file.exists(rds_path)) {
        if (!quiet) cli_alert_info("importing {cat} database (RDS)")
        unified_db[[cat]] <- read_boilerplate_db(rds_path)
      } else if (file.exists(json_path)) {
        if (!quiet) cli_alert_info("importing {cat} database (JSON)")
        unified_db[[cat]] <- read_boilerplate_db(json_path)
      }
    }

    # Also check for unified database (RDS or JSON)
    unified_rds <- file.path(data_path, "boilerplate_unified.rds")
    unified_json <- file.path(data_path, "boilerplate_unified.json")

    if (file.exists(unified_rds)) {
      if (!quiet) cli_alert_info("found unified database (RDS), importing...")
      unified_db <- read_boilerplate_db(unified_rds)
    } else if (file.exists(unified_json)) {
      if (!quiet) cli_alert_info("found unified database (JSON), importing...")
      unified_db <- read_boilerplate_db(unified_json)
    }

    if (!quiet) cli_alert_success("imported {length(unified_db)} database(s)")
    return(unified_db)
  }

  # Import specific category/categories from unified database
  # First check for unified database
  unified_rds <- file.path(data_path, "boilerplate_unified.rds")
  unified_json <- file.path(data_path, "boilerplate_unified.json")
  
  if (file.exists(unified_json)) {
    if (!quiet) cli_alert_info("loading unified database (JSON)")
    full_db <- read_boilerplate_db(unified_json)
  } else if (file.exists(unified_rds)) {
    if (!quiet) cli_alert_info("loading unified database (RDS)")
    full_db <- read_boilerplate_db(unified_rds)
  } else {
    # Fall back to individual files for backward compatibility
    if (length(category) == 1) {
      # Single category
      rds_path <- file.path(data_path, paste0(category, "_db.rds"))
      json_path <- file.path(data_path, paste0(category, "_db.json"))

      if (file.exists(rds_path)) {
        if (!quiet) cli_alert_info("importing {category} database (RDS)")
        db <- read_boilerplate_db(rds_path)
      } else if (file.exists(json_path)) {
        if (!quiet) cli_alert_info("importing {category} database (JSON)")
        db <- read_boilerplate_db(json_path)
      } else {
        stop("Database file not found: boilerplate_unified.json/rds or ", category, "_db.json/rds in ", data_path)
      }

      if (!quiet) cli_alert_success("imported {category} database")
      return(db)
    } else {
      # Multiple categories
      result <- list()

      for (cat in category) {
        rds_path <- file.path(data_path, paste0(cat, "_db.rds"))
        json_path <- file.path(data_path, paste0(cat, "_db.json"))

        if (file.exists(rds_path)) {
          if (!quiet) cli_alert_info("importing {cat} database (RDS)")
          result[[cat]] <- read_boilerplate_db(rds_path)
        } else if (file.exists(json_path)) {
          if (!quiet) cli_alert_info("importing {cat} database (JSON)")
          result[[cat]] <- read_boilerplate_db(json_path)
        } else {
          if (!quiet) cli_alert_warning("{cat} database not found")
        }
      }

      if (!quiet) cli_alert_success("imported {length(result)} database(s)")
      return(result)
    }
  }
  
  # Extract requested categories from unified database
  if (length(category) == 1) {
    if (category %in% names(full_db)) {
      if (!quiet) cli_alert_success("extracted {category} from unified database")
      return(full_db[[category]])
    } else {
      stop("Category '", category, "' not found in unified database")
    }
  } else {
    result <- list()
    for (cat in category) {
      if (cat %in% names(full_db)) {
        result[[cat]] <- full_db[[cat]]
      } else {
        if (!quiet) cli_alert_warning("{cat} not found in unified database")
      }
    }
    if (!quiet) cli_alert_success("extracted {length(result)} categories from unified database")
    return(result)
  }
}


#' Save boilerplate Database
#'
#' This function saves a boilerplate database to disk in RDS, JSON, or both formats.
#'
#' @param db List. The database to save. Can be a single category database or unified database.
#' @param category Character. The category name if saving a single category.
#'   If NULL and db contains multiple categories, saves as unified database.
#' @param data_path Character. Base path for data directory.
#'   If NULL (default), uses here::here("boilerplate", "data").
#' @param format Character. Format to save: "json" (default), "rds", or "both".
#' @param confirm Logical. If TRUE, asks for confirmation. Default is TRUE.
#' @param create_dirs Logical. If TRUE, creates directories if they don't exist. Default is FALSE.
#' @param quiet Logical. If TRUE, suppresses all CLI alerts. Default is FALSE.
#' @param pretty Logical. If TRUE (default), pretty-print JSON for readability.
#' @param timestamp Logical. If TRUE, add timestamp to filename. Default is FALSE.
#' @param entry_level_confirm Logical. Not used, kept for backward compatibility.
#' @param create_backup Logical. If TRUE, creates a backup before saving. Default is TRUE unless running examples or in a temporary directory.
#' @param select_elements Character vector. Not used, kept for backward compatibility.
#' @param output_file Character. Not used, kept for backward compatibility.
#' @param project Character. Project name for organizing databases. Default is "default".
#'   Projects are stored in separate subdirectories to allow multiple independent
#'   boilerplate collections.
#'
#' @return Invisible TRUE if successful, with saved file paths as an attribute.
#'
#' @examples
#' # Create a temporary directory
#' temp_dir <- tempdir()
#' data_path <- file.path(temp_dir, "boilerplate_save_example", "data")
#'
#' # Create a test database
#' test_db <- list(
#'   methods = list(
#'     sample = list(default = "Sample text")
#'   ),
#'   measures = list(
#'     test_measure = list(name = "Test", description = "A test measure")
#'   )
#' )
#'
#' # Save as unified database
#' boilerplate_save(
#'   db = test_db,
#'   data_path = data_path,
#'   create_dirs = TRUE,
#'   confirm = FALSE,
#'   quiet = TRUE
#' )
#'
#' # Check that file was created
#' file.exists(file.path(data_path, "boilerplate_unified.rds"))
#'
#' # Save a single category
#' boilerplate_save(
#'   db = test_db$methods,
#'   category = "methods",
#'   data_path = data_path,
#'   confirm = FALSE,
#'   quiet = TRUE
#' )
#'
#' # Clean up
#' unlink(file.path(temp_dir, "boilerplate_save_example"), recursive = TRUE)
#'
#' @importFrom cli cli_alert_info cli_alert_success cli_alert_danger
#' @importFrom here here
#' @export
boilerplate_save <- function(
    db,
    category = NULL,
    data_path = NULL,
    format = "json",
    confirm = TRUE,
    create_dirs = FALSE,
    quiet = FALSE,
    pretty = TRUE,
    timestamp = FALSE,
    entry_level_confirm = TRUE,
    create_backup = NULL,
    select_elements = NULL,
    output_file = NULL,
    project = "default"
) {
  # Validate project name
  if (!is.character(project) || length(project) != 1 || project == "") {
    stop("Project must be a non-empty character string")
  }
  
  # Set default data path
  if (is.null(data_path)) {
    data_path <- here::here("boilerplate", "projects", project, "data")
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

  # Set default for create_backup based on context
  if (is.null(create_backup)) {
    # Don't create backups in temp directories or during examples
    create_backup <- !grepl("tmp|Temp|TEMP", data_path, ignore.case = TRUE) && interactive()
  }

  # Check if data path exists
  if (!dir.exists(data_path)) {
    if (create_dirs) {
      dir.create(data_path, recursive = TRUE)
      if (!quiet) cli_alert_info("created directory: {data_path}")
    } else {
      stop("Directory does not exist: ", data_path, ". Set create_dirs=TRUE to create it.")
    }
  }

  # Validate format
  format <- match.arg(format, c("rds", "json", "both"))

  # Determine base filename
  if (is.null(category)) {
    # Check if db looks like a unified database
    db_names <- names(db)
    categories <- c("measures", "methods", "results", "discussion", "appendix", "template")
    is_unified <- any(categories %in% db_names) || length(db) == 0  # Empty db is also unified
    
    if (is_unified) {
      # Save as unified database
      base_name <- "boilerplate_unified"
      save_type <- "unified database"
    } else {
      stop("Cannot determine database type. Please specify 'category' parameter.")
    }
  } else {
    # Save as specific category
    base_name <- paste0(category, "_db")
    save_type <- paste0(category, " database")
  }

  # Add timestamp if requested
  if (timestamp) {
    time_stamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    base_name <- paste0(base_name, "_", time_stamp)
  }

  # Save in requested format(s)
  files_saved <- character()

  if (format %in% c("rds", "both")) {
    rds_path <- file.path(data_path, paste0(base_name, ".rds"))

    # Create backup if file exists
    if (file.exists(rds_path) && create_backup && !timestamp) {
      backup_path <- create_db_backup(rds_path, quiet)
    }

    # Ask for confirmation
    if (confirm && file.exists(rds_path) && !timestamp) {
      response <- readline(paste0("Overwrite ", save_type, " at ", rds_path, "? (y/n): "))
      if (tolower(response) != "y") {
        if (!quiet) cli_alert_info("save cancelled")
        return(invisible(FALSE))
      }
    }

    # Save RDS
    write_boilerplate_db(db, rds_path, format = "rds")
    if (!quiet) cli_alert_success("saved {save_type} to {rds_path}")
    files_saved <- c(files_saved, rds_path)
  }

  if (format %in% c("json", "both")) {
    json_path <- file.path(data_path, paste0(base_name, ".json"))

    # Ask for confirmation if file exists
    if (confirm && file.exists(json_path) && !timestamp) {
      response <- readline(paste0("Overwrite ", save_type, " at ", json_path, "? (y/n): "))
      if (tolower(response) != "y") {
        if (!quiet) cli_alert_info("save cancelled")
        return(invisible(FALSE))
      }
    }

    # Save JSON
    write_boilerplate_db(db, json_path, format = "json", pretty = pretty)
    if (!quiet) cli_alert_success("saved {save_type} to {json_path}")
    files_saved <- c(files_saved, json_path)
  }

  # Return TRUE for backward compatibility, but also include files_saved as attribute
  result <- TRUE
  attr(result, "files") <- files_saved
  return(invisible(result))
}


#' Access Measures from Unified Database
#'
#' This function extracts and returns the measures portion of a unified database,
#' optionally retrieving a specific measure by name.
#'
#' @param unified_db List. The unified boilerplate database
#' @param name Character. Optional specific measure to retrieve
#'
#' @return List. The requested measures database or specific measure
#'
#' @examples
#' # Create a temporary directory and initialise database
#' temp_dir <- tempdir()
#' data_path <- file.path(temp_dir, "boilerplate_measures_example", "data")
#'
#' # Initialise with default measures
#' boilerplate_init(
#'   categories = "measures",
#'   data_path = data_path,
#'   create_dirs = TRUE,
#'   create_empty = FALSE,
#'   confirm = FALSE,
#'   quiet = TRUE
#' )
#'
#' # Import all databases
#' unified_db <- boilerplate_import(data_path = data_path, quiet = TRUE)
#'
#' # Get all measures
#' measures_db <- boilerplate_measures(unified_db)
#' names(measures_db)
#'
#' # Get a specific measure
#' if ("anxiety" %in% names(measures_db)) {
#'   anxiety_measure <- boilerplate_measures(unified_db, "anxiety")
#'   anxiety_measure$description
#' }
#'
#' # Clean up
#' unlink(file.path(temp_dir, "boilerplate_measures_example"), recursive = TRUE)
#'
#' @export
boilerplate_measures <- function(unified_db, name = NULL) {
  # Check if the database contains a measures element
  if (!is.list(unified_db) || !"measures" %in% names(unified_db)) {
    stop("unified_db must contain a 'measures' element")
  }

  measures_db <- unified_db$measures

  if (is.null(name)) {
    return(measures_db)
  } else {
    if (!name %in% names(measures_db)) {
      stop("Measure '", name, "' not found in database")
    }
    return(measures_db[[name]])
  }
}


#' Access Results from Unified Database
#'
#' This function extracts and returns the results portion of a unified database,
#' optionally retrieving a specific result section by name using dot notation.
#'
#' @param unified_db List. The unified boilerplate database
#' @param name Character. Optional specific result section to retrieve (supports dot notation)
#'
#' @return List or character. The requested results database or specific section
#'
#' @examples
#' # Create a temporary directory and initialise database
#' temp_dir <- tempdir()
#' data_path <- file.path(temp_dir, "boilerplate_results_example", "data")
#'
#' # Initialise with default results
#' boilerplate_init(
#'   categories = "results",
#'   data_path = data_path,
#'   create_dirs = TRUE,
#'   create_empty = FALSE,
#'   confirm = FALSE,
#'   quiet = TRUE
#' )
#'
#' # Import all databases
#' unified_db <- boilerplate_import(data_path = data_path, quiet = TRUE)
#'
#' # Get all results sections
#' results_db <- boilerplate_results(unified_db)
#' names(results_db)
#'
#' # Clean up
#' unlink(file.path(temp_dir, "boilerplate_results_example"), recursive = TRUE)
#'
#' @export
boilerplate_results <- function(unified_db, name = NULL) {
  # Check if the database contains a results element
  if (!is.list(unified_db) || !"results" %in% names(unified_db)) {
    stop("unified_db must contain a 'results' element")
  }

  results_db <- unified_db$results

  if (is.null(name)) {
    return(results_db)
  } else {
    # Support dot notation for nested access
    path_parts <- strsplit(name, "\\.")[[1]]
    current <- results_db

    for (part in path_parts) {
      if (!is.list(current) || !part %in% names(current)) {
        stop("Result section '", name, "' not found in database")
      }
      current <- current[[part]]
    }

    return(current)
  }
}
