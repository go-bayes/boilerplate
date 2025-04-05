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

#' Extract Selected Elements from a Database
#'
#' This function extracts selected elements from a database based on specified paths.
#'
#' @param db List. The database to extract from.
#' @param select_paths Character vector. Paths to select in dot notation (e.g., "methods.statistical.longitudinal").
#'   Use "*" for wildcard selection at any level (e.g., "methods.*" selects all methods).
#'
#' @return List. A new database containing only the selected elements.
#'
#' @noRd
extract_selected_elements <- function(db, select_paths) {
  if (length(select_paths) == 0) {
    return(db)  # return full database if no paths specified
  }

  # Initialize result database
  result_db <- list()

  # Process each selection path
  for (path in select_paths) {
    # Handle wildcards
    if (grepl("\\*", path)) {
      # Contains wildcards
      result_db <- extract_wildcard_path(db, path, result_db)
    } else {
      # Exact path
      result_db <- extract_exact_path(db, path, result_db)
    }
  }

  return(result_db)
}

#' Extract Elements Matching a Wildcard Path
#'
#' @param db List. The source database.
#' @param wildcard_path Character. Path with wildcards.
#' @param result_db List. The result database to update.
#'
#' @return List. The updated result database.
#'
#' @noRd
extract_wildcard_path <- function(db, wildcard_path, result_db) {
  # Split path into parts
  path_parts <- strsplit(wildcard_path, "\\.")[[1]]

  # Find matching paths
  all_paths <- find_matching_paths(db, path_parts)

  # Extract each matching path
  for (path in all_paths) {
    result_db <- extract_exact_path(db, path, result_db)
  }

  return(result_db)
}

#' Find Paths Matching a Pattern with Wildcards
#'
#' @param db List. The database to search.
#' @param pattern_parts Character vector. Path pattern parts, with possible wildcards.
#' @param current_path Character. Current path being built (for recursion).
#'
#' @return Character vector. Paths that match the pattern.
#'
#' @noRd
find_matching_paths <- function(db, pattern_parts, current_path = "") {
  if (!is.list(db) || length(pattern_parts) == 0) {
    return(character(0))
  }

  matching_paths <- character(0)

  # Get current part and remaining parts
  current_part <- pattern_parts[1]
  remaining_parts <- pattern_parts[-1]

  # Handle wildcard at current level
  if (current_part == "*") {
    # Select all items at this level
    for (name in names(db)) {
      # Build path
      path_prefix <- if (current_path == "") name else paste(current_path, name, sep = ".")

      if (length(remaining_parts) == 0) {
        # This is the end of the pattern, add current path
        matching_paths <- c(matching_paths, path_prefix)
      } else if (is.list(db[[name]])) {
        # Continue search in nested structure
        nested_paths <- find_matching_paths(db[[name]], remaining_parts, path_prefix)
        matching_paths <- c(matching_paths, nested_paths)
      }
    }
  } else {
    # Exact match at current level
    if (current_part %in% names(db)) {
      # Build path
      path_prefix <- if (current_path == "") current_part else paste(current_path, current_part, sep = ".")

      if (length(remaining_parts) == 0) {
        # This is the end of the pattern, add current path
        matching_paths <- c(matching_paths, path_prefix)
      } else if (is.list(db[[current_part]])) {
        # Continue search in nested structure
        nested_paths <- find_matching_paths(db[[current_part]], remaining_parts, path_prefix)
        matching_paths <- c(matching_paths, nested_paths)
      }
    }
  }

  return(matching_paths)
}

#' Extract an Element at a Specific Path
#'
#' @param db List. The source database.
#' @param path Character. Dot-separated path to the element.
#' @param result_db List. The result database to update.
#'
#' @return List. The updated result database.
#'
#' @noRd
extract_exact_path <- function(db, path, result_db) {
  # Split the path into parts
  path_parts <- strsplit(path, "\\.")[[1]]

  # Get the value at the specified path
  value <- get_nested_value(db, path_parts)

  # Update result database with the extracted value
  result_db <- set_nested_value(result_db, path_parts, value)

  return(result_db)
}

#' Get a Nested Value from a Database
#'
#' @param db List. The database to query.
#' @param path_parts Character vector. Path components.
#'
#' @return Any. The value at the specified path.
#'
#' @noRd
get_nested_value <- function(db, path_parts) {
  current_item <- db

  for (part in path_parts) {
    if (!is.list(current_item) || !(part %in% names(current_item))) {
      stop("Path component '", part, "' not found")
    }
    current_item <- current_item[[part]]
  }

  return(current_item)
}

#' Set a Nested Value in a Database
#'
#' @param db List. The database to modify.
#' @param path_parts Character vector. Path components.
#' @param value Any. The value to set.
#'
#' @return List. The modified database.
#'
#' @noRd
set_nested_value <- function(db, path_parts, value) {
  if (length(path_parts) == 1) {
    # Set value at top level
    db[[path_parts[1]]] <- value
    return(db)
  }

  # Process nested path
  current_part <- path_parts[1]
  remaining_parts <- path_parts[-1]

  # Create nested structure if needed
  if (!(current_part %in% names(db))) {
    db[[current_part]] <- list()
  } else if (!is.list(db[[current_part]])) {
    # Handle case where existing item is not a list
    stop("Cannot set nested path: '", current_part, "' exists but is not a list")
  }

  # Recursively set nested value
  db[[current_part]] <- set_nested_value(db[[current_part]], remaining_parts, value)

  return(db)
}

#' Save Boilerplate Database
#'
#' This function saves a boilerplate database to disk with entry-level change detection.
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
#' @param entry_level_confirm Logical. If TRUE, shows changes at the entry level and asks for confirmation. Default is TRUE.
#' @param create_backup Logical. If TRUE, creates a backup of existing database before saving. Default is TRUE.
#' @param select_elements Character vector. Paths to select in dot notation (e.g., "statistical.longitudinal.lmtp").
#'   Use "*" for wildcard selection (e.g., "statistical.*" selects all statistical methods).
#'   If NULL (default), saves the entire database.
#' @param output_file Character. Name of the output file if saving selected elements to a separate file.
#'   If NULL (default), overwrites the original file.
#'
#' @return Invisibly returns a named list with logical values indicating which categories
#'   were successfully saved, or the file path if a single category was saved.
#'
#' @examples
#' # save a specific database
#' methods_db <- boilerplate_import("methods")
#' methods_db$new_section <- "New content"
#' boilerplate_save(methods_db, "methods")
#'
#' # save selected elements from a database
#' unified_db <- boilerplate_import()
#' boilerplate_save(unified_db,
#'                 select_elements = c("methods.statistical.*", "results.main_effect"),
#'                 output_file = "selected_elements.rds")
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
    quiet = FALSE,
    entry_level_confirm = TRUE,
    create_backup = TRUE,
    select_elements = NULL,
    output_file = NULL
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

    # if select_elements is specified, extract selected elements for each category
    if (!is.null(select_elements)) {
      if (!quiet) cli_alert_info("extracting selected elements for unified database")

      # Process selection paths that might include category prefixes
      selected_db <- list()

      for (cat in intersect(db_names, all_categories)) {
        # Get category-specific paths (those starting with "category.")
        cat_prefix <- paste0(cat, ".")
        cat_paths <- select_elements[startsWith(select_elements, cat_prefix)]

        # Strip category prefix for processing
        stripped_paths <- sub(paste0("^", cat, "\\."), "", cat_paths)

        if (length(stripped_paths) > 0) {
          if (!quiet) cli_alert_info("extracting {length(stripped_paths)} paths from {cat}")
          selected_db[[cat]] <- extract_selected_elements(db[[cat]], stripped_paths)
        }
      }

      # For paths without category prefix, apply to all categories
      unprefixed_paths <- select_elements[!grepl("^[^.]+\\.", select_elements)]

      if (length(unprefixed_paths) > 0) {
        if (!quiet) cli_alert_info("applying {length(unprefixed_paths)} general paths to all categories")
        for (cat in intersect(db_names, all_categories)) {
          if (!(cat %in% names(selected_db))) {
            selected_db[[cat]] <- list()
          }
          selected_db[[cat]] <- extract_selected_elements(db[[cat]], unprefixed_paths)
        }
      }

      # Replace db with selected elements
      db <- selected_db

      # If output_file is specified, save to that file
      if (!is.null(output_file)) {
        output_path <- file.path(data_path, output_file)

        # Confirm if file exists
        proceed <- TRUE
        if (confirm && file.exists(output_path)) {
          proceed <- ask_yes_no(paste0("save to output file? this will overwrite: ", output_path))
        }

        if (proceed) {
          if (!quiet) cli_alert_info("saving selected elements to {output_path}")
          saveRDS(db, file = output_path)
          if (!quiet) cli_alert_success("saved selected elements to {output_path}")
          return(invisible(output_path))
        } else {
          if (!quiet) cli_alert_info("save cancelled by user")
          return(invisible(NULL))
        }
      }
    }

    # check for invalid categories
    invalid_categories <- setdiff(db_names, all_categories)
    if (length(invalid_categories) > 0) {
      if (!quiet) cli_alert_warning("ignoring invalid categories: {paste(invalid_categories, collapse = ', ')}")
      db_names <- intersect(db_names, all_categories)
    }

    # prepare for multi-database save
    if (!quiet) cli_alert_info("preparing to save {length(db_names)} databases")

    # track save status for each category
    save_status <- logical(length(db_names))
    names(save_status) <- db_names

    # save each valid category
    for (i in seq_along(db_names)) {
      cat_name <- db_names[i]
      if (!quiet) cli_alert_info("processing {cat_name} database ({i}/{length(db_names)})")

      # Call save for each individual category
      result <- boilerplate_save(
        db = db[[cat_name]],
        category = cat_name,
        data_path = data_path,
        confirm = confirm,
        create_dirs = FALSE,  # directory already exists or was created
        quiet = quiet,
        entry_level_confirm = entry_level_confirm,
        create_backup = create_backup,
        select_elements = NULL  # selection already processed
      )

      # Store result
      save_status[i] <- !is.null(result)
    }

    # count successful saves
    successful <- sum(save_status)
    canceled <- length(db_names) - successful

    # show summary of operations
    if (!quiet) {
      if (canceled == 0) {
        cli_alert_success("successfully saved all {length(db_names)} databases")
      } else if (successful == 0) {
        cli_alert_info("all {length(db_names)} database saves were cancelled")
      } else {
        successful_cats <- names(save_status)[save_status]
        canceled_cats <- names(save_status)[!save_status]

        cli_alert_info("saved {successful}/{length(db_names)} databases")
        if (successful > 0) {
          cli_alert_info("saved: {paste(successful_cats, collapse = ', ')}")
        }
        if (canceled > 0) {
          cli_alert_info("cancelled: {paste(canceled_cats, collapse = ', ')}")
        }
      }
    }

    return(invisible(save_status))
  }

  # handle saving a single database
  if (!category %in% all_categories) {
    if (!quiet) cli_alert_danger("invalid category: {category}")
    stop("Invalid category: ", category, ". Must be one of: ", paste(all_categories, collapse = ", "))
  }

  # Handle selected elements for a single category
  if (!is.null(select_elements)) {
    if (!quiet) cli_alert_info("extracting selected elements for {category}")
    db <- extract_selected_elements(db, select_elements)

    # If output_file is specified, save to that file instead of the category file
    if (!is.null(output_file)) {
      output_path <- file.path(data_path, output_file)

      # Confirm if file exists
      proceed <- TRUE
      if (confirm && file.exists(output_path)) {
        proceed <- ask_yes_no(paste0("save to output file? this will overwrite: ", output_path))
      }

      if (proceed) {
        if (!quiet) cli_alert_info("saving selected elements to {output_path}")
        saveRDS(db, file = output_path)
        if (!quiet) cli_alert_success("saved selected elements to {output_path}")
        return(invisible(output_path))
      } else {
        if (!quiet) cli_alert_info("save cancelled by user")
        return(invisible(NULL))
      }
    }
  }

  # construct file path
  file_path <- file.path(data_path, paste0(category, "_db.rds"))

  # Check for changes if file exists and entry-level confirmation is requested
  if (file.exists(file_path) && (confirm || entry_level_confirm)) {
    # Load existing database for comparison
    existing_db <- tryCatch({
      readRDS(file_path)
    }, error = function(e) {
      if (!quiet) cli_alert_warning("error loading existing database for comparison: {e$message}")
      return(list())
    })

    # Find changes between existing and new database
    changes <- find_changes(existing_db, db)

    # Prepare change summary
    has_changes <- length(changes$added) > 0 || length(changes$removed) > 0 || length(changes$modified) > 0

    if (has_changes) {
      if (!quiet) {
        if (length(changes$added) > 0) {
          cli_alert_info("{length(changes$added)} new entries will be added:")
          for (entry in changes$added) {
            cli_alert_info("  + {entry}")
          }
        }

        if (length(changes$modified) > 0) {
          cli_alert_info("{length(changes$modified)} existing entries will be modified:")
          for (entry in changes$modified) {
            cli_alert_info("  ~ {entry}")
          }
        }

        if (length(changes$removed) > 0) {
          cli_alert_warning("{length(changes$removed)} entries will be removed:")
          for (entry in changes$removed) {
            cli_alert_warning("  - {entry}")
          }
        }
      }

      # Ask for confirmation with changes
      if (entry_level_confirm) {
        proceed <- ask_yes_no(paste0("Save ", category, " database with these changes?"))
        if (!proceed) {
          if (!quiet) cli_alert_info("{category} database save cancelled by user")
          return(invisible(NULL))
        }
      }
    } else {
      if (!quiet) cli_alert_info("no changes detected in {category} database")
    }

    # File-level confirmation
    if (confirm && !entry_level_confirm) {
      proceed <- ask_yes_no(paste0("Save ", category, " database? This will overwrite: ", file_path))
      if (!proceed) {
        if (!quiet) cli_alert_info("{category} database save cancelled by user")
        return(invisible(NULL))
      }
    }

    # Create backup if requested
    if (create_backup && has_changes) {
      backup_path <- create_db_backup(file_path)
    }
  } else if (file.exists(file_path) && confirm) {
    # Simple file-level confirmation without entry detection
    proceed <- ask_yes_no(paste0("Save ", category, " database? This will overwrite: ", file_path))
    if (!proceed) {
      if (!quiet) cli_alert_info("{category} database save cancelled by user")
      return(invisible(NULL))
    }
  }

  # save the database
  if (!quiet) cli_alert_info("saving {category} database to {file_path}")
  saveRDS(db, file = file_path)
  if (!quiet) cli_alert_success("saved {category} database")

  return(invisible(file_path))
}

#' Export Database Elements to a File
#'
#' This function exports a database (fully or partially) to a new file
#' without modifying the original database. It's useful for versioning,
#' sharing, or creating targeted subsets of your boilerplate content.
#'
#' @param db List. The database to export from. Can be a single category database
#'   or a unified database with multiple categories.
#' @param output_file Character. Name of the output file.
#' @param select_elements Character vector. Optional paths to select in dot notation.
#'   Use "*" for wildcard selection (e.g., "statistical.*" selects all statistical methods).
#'   If NULL or empty (default), exports the entire database.
#' @param data_path Character. Base path for data directory.
#'   If NULL (default), uses here::here("boilerplate", "data").
#' @param confirm Logical. If TRUE, asks for confirmation before overwriting. Default is TRUE.
#' @param create_dirs Logical. If TRUE, creates directories that don't exist. Default is FALSE.
#' @param quiet Logical. If TRUE, suppresses all CLI alerts. Default is FALSE.
#'
#' @return Invisibly returns the path to the saved file if successful, or NULL if cancelled.
#'
#' @examples
#' \dontrun{
#' # Export the entire database (versioning)
#' unified_db <- boilerplate_import()
#' boilerplate_export(
#'   unified_db,
#'   output_file = "boilerplate_backup_20250405.rds"
#' )
#'
#' # Export selected elements from a unified database (sharing specific parts)
#' unified_db <- boilerplate_import()
#' boilerplate_export(
#'   unified_db,
#'   output_file = "causal_methods_subset.rds",
#'   select_elements = c("methods.statistical.*", "results.main_effect")
#' )
#'
#' # Export selected elements from a single category (creating a subset)
#' methods_db <- boilerplate_import("methods")
#' boilerplate_export(
#'   methods_db,
#'   output_file = "causal_methods.rds",
#'   select_elements = c("statistical.longitudinal.*", "causal_assumptions")
#' )
#' }
#'
#' @importFrom cli cli_alert_info cli_alert_success cli_alert_warning cli_alert_danger
#' @export
boilerplate_export <- function(
    db,
    output_file,
    select_elements = NULL,
    data_path = NULL,
    confirm = TRUE,
    create_dirs = FALSE,
    quiet = FALSE
) {
  if (!is.list(db)) {
    if (!quiet) cli_alert_danger("db must be a list")
    stop("db must be a list")
  }

  # If select_elements is NULL or empty, export the entire database
  if (is.null(select_elements) || length(select_elements) == 0) {
    if (!quiet) cli_alert_info("no specific elements selected, exporting entire database")
    selected_db <- db  # Use the entire database
  }

  if (is.null(output_file) || output_file == "") {
    if (!quiet) cli_alert_danger("output_file cannot be empty")
    stop("output_file cannot be empty")
  }

  # Set default path if not provided
  if (is.null(data_path)) {
    if (!requireNamespace("here", quietly = TRUE)) {
      if (!quiet) cli_alert_danger("package 'here' is required for default path resolution")
      stop("Package 'here' is required for default path resolution. Please install it or specify 'data_path' manually.")
    }
    data_path <- here::here("boilerplate", "data")
    if (!quiet) cli_alert_info("using default path: {data_path}")
  }

  # Check if directory exists and handle creation
  if (!dir.exists(data_path)) {
    if (!create_dirs) {
      if (!quiet) cli_alert_danger("directory does not exist: {data_path}")
      stop("Directory does not exist: ", data_path, ". Set create_dirs=TRUE to create it.")
    }

    # Ask for confirmation if needed
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

  # Determine if db is a unified database or a single category
  category_names <- c("measures", "methods", "results", "discussion", "appendix", "template")
  is_unified <- all(names(db) %in% category_names) && length(names(db)) > 1

  # Process selection only if select_elements is provided
  if (!is.null(select_elements) && length(select_elements) > 0) {
    if (is_unified) {
      if (!quiet) cli_alert_info("extracting selected elements from unified database")

      # Extract from unified database (similar to boilerplate_save)
      selected_db <- list()

      for (cat in intersect(names(db), category_names)) {
        # Get category-specific paths (those starting with "category.")
        cat_prefix <- paste0(cat, ".")
        cat_paths <- select_elements[startsWith(select_elements, cat_prefix)]

        # Strip category prefix for processing
        stripped_paths <- sub(paste0("^", cat, "\\."), "", cat_paths)

        if (length(stripped_paths) > 0) {
          if (!quiet) cli_alert_info("extracting {length(stripped_paths)} paths from {cat}")
          selected_db[[cat]] <- extract_selected_elements(db[[cat]], stripped_paths)
        }
      }

      # For paths without category prefix, apply to all categories
      unprefixed_paths <- select_elements[!grepl("^[^.]+\\.", select_elements)]

      if (length(unprefixed_paths) > 0) {
        if (!quiet) cli_alert_info("applying {length(unprefixed_paths)} general paths to all categories")
        for (cat in intersect(names(db), category_names)) {
          if (!(cat %in% names(selected_db))) {
            selected_db[[cat]] <- extract_selected_elements(db[[cat]], unprefixed_paths)
          } else {
            # Merge with existing selections
            cat_selections <- extract_selected_elements(db[[cat]], unprefixed_paths)
            selected_db[[cat]] <- merge_recursive_lists(selected_db[[cat]], cat_selections)
          }
        }
      }

      # Check if any selections were found
      if (length(selected_db) == 0) {
        if (!quiet) cli_alert_warning("no elements matched the specified paths")
        return(invisible(NULL))
      }
    } else {
      # Single category database
      if (!quiet) cli_alert_info("extracting selected elements from database")

      # Extract selected elements
      selected_db <- extract_selected_elements(db, select_elements)

      # Check if any selections were found
      if (length(selected_db) == 0) {
        if (!quiet) cli_alert_warning("no elements matched the specified paths")
        return(invisible(NULL))
      }
    }
  }

  # Save selected elements
  output_path <- file.path(data_path, output_file)

  # Confirm if file exists
  proceed <- TRUE
  if (confirm && file.exists(output_path)) {
    proceed <- ask_yes_no(paste0("save to output file? this will overwrite: ", output_path))
  }

  if (proceed) {
    if (!quiet) cli_alert_info("saving selected elements to {output_path}")
    saveRDS(selected_db, file = output_path)
    if (!quiet) cli_alert_success("saved selected elements to {output_path}")
    return(invisible(output_path))
  } else {
    if (!quiet) cli_alert_info("save cancelled by user")
    return(invisible(NULL))
  }
}
