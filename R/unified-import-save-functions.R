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
    create_backup = TRUE
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

  # helper function to find changes between old and new databases
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
  create_db_backup <- function(file_path) {
    if (!file.exists(file_path)) return(FALSE)

    # Create backup filename with timestamp
    timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
    backup_path <- paste0(file_path, ".", timestamp, ".bak")

    # Copy file to backup
    file.copy(file_path, backup_path)
    if (!quiet) cli_alert_info("created backup at: {backup_path}")

    return(backup_path)
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
        create_backup = create_backup
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
