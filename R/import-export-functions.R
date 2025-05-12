#' Extract selected elements from a nested database
#'
#' This helper walks a nested list and returns only
#' those branches whose dot-notation paths match the user patterns.
#' It understands \code{*} as a wildcard for one whole segment.
#'
#' @param db A \code{list}. The database to extract from.
#' @param select_paths A \code{character} vector of dot-notation paths (\code{*} allowed).
#' @param quiet A \code{logical}. If \code{FALSE}, shows CLI alerts.
#' @return A \code{list} containing only the matching branches.
#' @keywords internal
#' Extract selected elements from a nested database
#'
#' This helper walks a nested list and returns only
#' those branches whose dot-notation paths match the user patterns.
#' It understands \code{*} as a wildcard for one whole segment.
#'
#' @param db A \code{list}. The database to extract from.
#' @param select_paths A \code{character} vector of dot-notation paths (\code{*} allowed).
#' @param quiet A \code{logical}. If \code{FALSE}, shows CLI alerts.
#' @return A \code{list} containing only the matching branches.
#' @keywords internal
extract_selected_elements <- function(db, select_paths, quiet = FALSE) {
  if (!is.list(db)) {
    stop("db must be a list")
  }
  if (length(select_paths) == 0) {
    if (!quiet) cli::cli_alert_warning("no paths specified for selection")
    return(list())
  }

  # Helper to determine if an element is a leaf (measure) or a folder
  is_leaf <- function(elem) {
    if (!is.list(elem)) return(TRUE)
    # Check for measure-like fields that indicate this is a leaf measure
    measure_fields <- c("name", "description", "reference", "items", "waves", "keywords")
    return(any(names(elem) %in% measure_fields))
  }

  # Recursive extractor
  recurse <- function(node, parts, path_so_far = character()) {
    # If no more parts and we're at a node, return the entire node
    if (length(parts) == 0) {
      return(node)
    }

    head <- parts[1]
    tail <- parts[-1]

    if (head == "*") {
      # Wildcard: handle specially based on context
      if (length(tail) == 0) {
        # Pattern ends with *, so we want all direct children
        # For measures.*, this should return all measures
        if (is.list(node)) {
          # Return all direct children
          return(node)
        } else {
          return(list())
        }
      } else {
        # Pattern continues after *, need to search through all children
        if (!is.list(node)) return(list())
        hits <- list()
        for (name in names(node)) {
          hit <- recurse(node[[name]], tail, c(path_so_far, name))
          if (length(hit) > 0) {
            hits[[name]] <- hit
          }
        }
        return(hits)
      }
    } else {
      # Exact match
      if (!is.list(node) || !(head %in% names(node))) {
        return(list())
      }

      if (length(tail) == 0) {
        # End of pattern - return this element
        result <- list()
        result[[head]] <- node[[head]]
        return(result)
      } else {
        # Continue recursing
        hit <- recurse(node[[head]], tail, c(path_so_far, head))
        if (length(hit) > 0) {
          result <- list()
          result[[head]] <- hit
          return(result)
        } else {
          return(list())
        }
      }
    }
  }

  # Apply each pattern and merge results
  result <- list()
  for (path in select_paths) {
    parts <- strsplit(path, "\\.")[[1]]
    hit <- recurse(db, parts)
    if (length(hit) > 0) {
      # Merge the hit into result
      result <- merge_recursive_lists(result, hit)
    }
  }

  # Count total elements for user feedback
  count_elements <- function(lst) {
    if (!is.list(lst)) return(1)
    count <- 0
    for (item in lst) {
      if (is_leaf(item)) {
        count <- count + 1
      } else if (is.list(item)) {
        count <- count + count_elements(item)
      }
    }
    return(count)
  }

  if (!quiet) {
    n_paths <- length(select_paths)
    # Count actual elements, not nested lists
    n_hits <- count_elements(result)
    cli::cli_alert_info("{n_paths} pattern{?s} processed; {n_hits} element{?s} extracted")
  }

  return(result)
}


# helper function to find changes between old and new databases
#' @keywords internal
find_changes <- function(old_db, new_db, prefix = "") {
  if (!is.list(old_db) || !is.list(new_db)) {
    # For non-list entries, just return if they're different
    if (!identical(old_db, new_db)) {
      return(list(modified = prefix))
    } else {
      return(list(added = character(0), removed = character(0), modified = character(0)))
    }
  }

  # Start with empty change lists
  added <- character(0)
  removed <- character(0)
  modified <- character(0)

  # Find added and modified entries
  for (name in names(new_db)) {
    key <- if (prefix == "") name else paste0(prefix, ".", name)

    if (!name %in% names(old_db)) {
      # Entry exists in new but not in old
      added <- c(added, key)
    } else {
      # Entry exists in both, check if modified
      if (is.list(new_db[[name]]) && is.list(old_db[[name]])) {
        # Recursive comparison for nested lists
        sub_changes <- find_changes(old_db[[name]], new_db[[name]], key)
        added <- c(added, sub_changes$added)
        removed <- c(removed, sub_changes$removed)
        modified <- c(modified, sub_changes$modified)
      } else if (!identical(old_db[[name]], new_db[[name]])) {
        # Entry exists in both but is different
        modified <- c(modified, key)
      }
    }
  }

  # Find removed entries
  for (name in names(old_db)) {
    if (!name %in% names(new_db)) {
      key <- if (prefix == "") name else paste0(prefix, ".", name)
      removed <- c(removed, key)
    }
  }

  return(list(added = added, removed = removed, modified = modified))
}

# helper function to create a backup file
#' @keywords internal
create_db_backup <- function(file_path, quiet = FALSE) {
  if (!file.exists(file_path)) return(FALSE)

  # Create backup filename with timestamp
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  backup_path <- paste0(file_path, ".", timestamp, ".bak")

  # Copy file to backup
  file.copy(file_path, backup_path)
  if (!quiet) cli_alert_info("created backup at: {backup_path}")

  return(backup_path)
}

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
#’ @examples
#’ \dontrun{
#’ # import just the methods database
#’ methods_db <- boilerplate_import("methods")
#’
#’ # import multiple specific databases
#’ dbs <- boilerplate_import(c("methods", "measures"))
#’ methods_db  <- dbs$methods
#’ measures_db <- dbs$measures
#’
#’ # import all databases
#’ all_dbs <- boilerplate_import()
#’ }
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
#’ @examples
#’ \dontrun{
#’ # save a specific database
#’ methods_db <- boilerplate_import("methods")
#’ methods_db$new_section <- "New content"
#’ boilerplate_save(methods_db, "methods")
#’
#’ # save selected elements from a database
#’ unified_db <- boilerplate_import()
#’ boilerplate_save(
#’   unified_db,
#’   select_elements = c("methods.statistical.*", "results.main_effect"),
#’   output_file     = "selected_elements.rds"
#’ )
#’
#’ # save multiple databases at once
#’ all_dbs <- boilerplate_import()
#’ all_dbs$methods$new_section <- "New content"
#’ boilerplate_save(all_dbs)
#’ }
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
      backup_path <- create_db_backup(file_path, quiet)
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
#' This function exports a database (fully or partially) to new files
#' without modifying the original database. For unified databases,
#' it automatically saves each category to its own file.
#'
#' @param db List. The database to export from. Can be a single category database
#'   or a unified database with multiple categories.
#' @param output_file Character. Name of the output file prefix for single files,
#'   or ignored for unified databases (which automatically save by category).
#' @param select_elements Character vector. Optional paths to select in dot notation.
#'   Use "*" for wildcard selection (e.g., "measures.*" selects all measures).
#'   If NULL or empty (default), exports the entire database.
#' @param data_path Character. Base path for data directory.
#'   If NULL (default), uses here::here("boilerplate", "data").
#' @param confirm Logical. If TRUE, asks for confirmation before overwriting. Default is TRUE.
#' @param create_dirs Logical. If TRUE, creates directories that don't exist. Default is FALSE.
#' @param quiet Logical. If TRUE, suppresses all CLI alerts. Default is FALSE.
#' @param save_by_category Logical. If TRUE and db is unified, saves each category
#'   to separate files (e.g., measures_db.rds, methods_db.rds). If FALSE, saves
#'   to a single unified file. Default is TRUE.
#'
#' @return Invisibly returns the path(s) to the saved file(s) if successful, or NULL if cancelled.
#'
#' @examples
#' \dontrun{
#' # Export the entire unified database by category (creates separate files)
#' unified_db <- boilerplate_import()
#' boilerplate_export(
#'   unified_db,
#'   data_path = "path/to/export/"
#' )
#'
#' # Export selected elements by category
#' unified_db <- boilerplate_import()
#' boilerplate_export(
#'   unified_db,
#'   data_path = "path/to/export/",
#'   select_elements = c("measures.*", "methods.statistical.*")
#' )
#'
#' # Export to a single unified file instead
#' unified_db <- boilerplate_import()
#' boilerplate_export(
#'   unified_db,
#'   output_file = "unified_backup.rds",
#'   data_path = "path/to/export/",
#'   save_by_category = FALSE
#' )
#' }
#'
#' @importFrom cli cli_alert_info cli_alert_success cli_alert_warning cli_alert_danger
#' @export
boilerplate_export <- function(
    db,
    output_file = NULL,
    select_elements = NULL,
    data_path = NULL,
    confirm = TRUE,
    create_dirs = FALSE,
    quiet = FALSE,
    save_by_category = TRUE
) {
  if (!is.list(db)) {
    if (!quiet) cli_alert_danger("db must be a list")
    stop("db must be a list")
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

  # Determine if this is a unified database
  category_names <- c("measures", "methods", "results", "discussion", "appendix", "template")
  is_unified <- all(names(db) %in% category_names) && length(names(db)) > 1

  # Process selections if specified
  selected_db <- db
  if (!is.null(select_elements) && length(select_elements) > 0) {
    if (is_unified) {
      if (!quiet) cli_alert_info("extracting selected elements from unified database")

      selected_db <- list()

      for (cat in intersect(names(db), category_names)) {
        # Get category-specific paths
        cat_prefix <- paste0(cat, ".")
        cat_paths <- select_elements[startsWith(select_elements, cat_prefix)]

        # Strip category prefix
        stripped_paths <- sub(paste0("^", cat, "\\."), "", cat_paths)

        if (length(stripped_paths) > 0) {
          if (!quiet) cli_alert_info("extracting {length(stripped_paths)} paths from {cat}")
          selected_db[[cat]] <- extract_selected_elements(db[[cat]], stripped_paths, quiet)
        }
      }

      # Handle paths without category prefix
      unprefixed_paths <- select_elements[!grepl("^[^.]+\\.", select_elements)]

      if (length(unprefixed_paths) > 0) {
        if (!quiet) cli_alert_info("applying {length(unprefixed_paths)} general paths to all categories")
        for (cat in intersect(names(db), category_names)) {
          if (!(cat %in% names(selected_db))) {
            selected_db[[cat]] <- extract_selected_elements(db[[cat]], unprefixed_paths, quiet)
          } else {
            cat_selections <- extract_selected_elements(db[[cat]], unprefixed_paths, quiet)
            selected_db[[cat]] <- merge_recursive_lists(selected_db[[cat]], cat_selections)
          }
        }
      }

      # Remove empty categories
      selected_db <- selected_db[sapply(selected_db, function(x) length(x) > 0)]

      if (length(selected_db) == 0) {
        if (!quiet) cli_alert_warning("no elements matched the specified paths")
        return(invisible(NULL))
      }
    } else {
      # Single category database
      if (!quiet) cli_alert_info("extracting selected elements from database")
      selected_db <- extract_selected_elements(db, select_elements, quiet)

      if (length(selected_db) == 0) {
        if (!quiet) cli_alert_warning("no elements matched the specified paths")
        return(invisible(NULL))
      }
    }
  }

  # Save the data
  if (is_unified && save_by_category) {
    # Save each category to its own file
    if (!quiet) cli_alert_info("saving unified database by category")

    saved_files <- character()

    for (cat in names(selected_db)) {
      cat_file <- file.path(data_path, paste0(cat, "_db.rds"))

      # Check for overwrite
      proceed <- TRUE
      if (confirm && file.exists(cat_file)) {
        proceed <- ask_yes_no(paste0("overwrite existing file: ", cat_file, "?"))
      }

      if (proceed) {
        if (!quiet) cli_alert_info("saving {cat} to {cat_file}")
        saveRDS(selected_db[[cat]], file = cat_file)
        saved_files <- c(saved_files, cat_file)
        if (!quiet) cli_alert_success("saved {cat} database")
      } else {
        if (!quiet) cli_alert_info("save cancelled for {cat}")
      }
    }

    if (length(saved_files) > 0) {
      if (!quiet) cli_alert_success("export completed. saved {length(saved_files)} category files")
      return(invisible(saved_files))
    } else {
      if (!quiet) cli_alert_info("no files were saved")
      return(invisible(NULL))
    }
  } else {
    # Save as a single file
    if (is.null(output_file)) {
      if (is_unified) {
        output_file <- "unified_db.rds"
      } else {
        output_file <- "exported_db.rds"
      }
      if (!quiet) cli_alert_info("using default output file: {output_file}")
    }

    output_path <- file.path(data_path, output_file)

    # Check for overwrite
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
}
