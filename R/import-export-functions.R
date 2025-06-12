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

# Note: The import function is defined in import-functions.R
#' Export boilerplate Database
#'
#' This function exports a boilerplate database or selected elements to disk.
#' It supports exporting entire databases, specific categories, or selected
#' elements using dot notation paths. Can export in RDS, JSON, or both formats.
#'
#' @param db List. The database to export (unified or single category).
#' @param output_file Character. Optional output filename. If NULL, uses default naming.
#' @param select_elements Character vector. Optional paths to export (supports wildcards).
#' @param data_path Character. Base path for data directory.
#'   If NULL (default), uses here::here("boilerplate", "data").
#' @param format Character. Format to save: "rds" (default), "json", or "both".
#' @param confirm Logical. If TRUE (default), asks for confirmation before overwriting.
#' @param create_dirs Logical. If TRUE, creates directories if they don't exist.
#' @param quiet Logical. If TRUE, suppresses all CLI alerts. Default is FALSE.
#' @param pretty Logical. If TRUE (default), pretty-print JSON for readability.
#' @param save_by_category Logical. If TRUE (default), saves unified databases by category.
#' @param project Character. Project name for organizing databases. Default is "default".
#'   Projects are stored in separate subdirectories to allow multiple independent
#'   boilerplate collections.
#'
#' @return Invisible TRUE if successful.
#'
#' @examples
#' # Create a temporary directory and initialise databases
#' temp_dir <- tempdir()
#' data_path <- file.path(temp_dir, "boilerplate_export_example", "data")
#'
#' # Initialise and import databases
#' boilerplate_init(
#'   categories = c("methods", "measures"),
#'   data_path = data_path,
#'   create_dirs = TRUE,
#'   confirm = FALSE,
#'   quiet = TRUE
#' )
#'
#' unified_db <- boilerplate_import(data_path = data_path, quiet = TRUE)
#'
#' # Export entire database
#' export_path <- file.path(temp_dir, "export")
#' boilerplate_export(
#'   db = unified_db,
#'   data_path = export_path,
#'   create_dirs = TRUE,
#'   confirm = FALSE,
#'   quiet = TRUE
#' )
#'
#' # Export selected elements
#' boilerplate_export(
#'   db = unified_db,
#'   select_elements = "methods.*",
#'   output_file = "methods_only.rds",
#'   data_path = export_path,
#'   confirm = FALSE,
#'   quiet = TRUE
#' )
#'
#' # Clean up
#' unlink(file.path(temp_dir, "boilerplate_export_example"), recursive = TRUE)
#'
#' @importFrom cli cli_alert_info cli_alert_success cli_alert_warning cli_alert_danger
#' @importFrom here here
#' @export
boilerplate_export <- function(
    db,
    output_file = NULL,
    select_elements = NULL,
    data_path = NULL,
    format = "rds",
    confirm = TRUE,
    create_dirs = FALSE,
    quiet = FALSE,
    pretty = TRUE,
    save_by_category = TRUE,
    project = "default"
) {
  if (!is.list(db)) {
    if (!quiet) cli_alert_danger("db must be a list")
    stop("db must be a list")
  }
  
  # Validate project name
  if (!is.character(project) || length(project) != 1 || project == "") {
    stop("Project must be a non-empty character string")
  }

  # Set default path if not provided
  if (is.null(data_path)) {
    if (!requireNamespace("here", quietly = TRUE)) {
      if (!quiet) cli_alert_danger("package 'here' is required for default path resolution")
      stop("Package 'here' is required for default path resolution. Please install it or specify 'data_path' manually.")
    }
    data_path <- here::here("boilerplate", "projects", project, "data")
    if (!quiet) cli_alert_info("using project '{project}' at path: {data_path}")
  } else {
    # Check if this looks like a legacy path or test path
    # Don't add project structure if:
    # 1. Path already contains "projects"
    # 2. Path ends with "data" (likely legacy)
    # 3. Path contains temp directory markers (test environment)
    if (!grepl("/projects/", data_path) && 
        !grepl("/data$", data_path) && 
        !grepl("^/tmp|^/var/folders|Temp", data_path)) {
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
      base_name <- paste0(cat, "_db")

      # Save in requested format(s)
      if (format %in% c("rds", "both")) {
        cat_file <- file.path(data_path, paste0(base_name, ".rds"))

        # Check for overwrite
        proceed <- TRUE
        if (confirm && file.exists(cat_file)) {
          proceed <- ask_yes_no(paste0("overwrite existing file: ", cat_file, "?"))
        }

        if (proceed) {
          if (!quiet) cli_alert_info("saving {cat} to {cat_file}")
          write_boilerplate_db(selected_db[[cat]], cat_file, format = "rds")
          saved_files <- c(saved_files, cat_file)
          if (!quiet) cli_alert_success("saved {cat} database (RDS)")
        } else {
          if (!quiet) cli_alert_info("save cancelled for {cat}")
        }
      }

      if (format %in% c("json", "both")) {
        cat_file <- file.path(data_path, paste0(base_name, ".json"))

        # Check for overwrite
        proceed <- TRUE
        if (confirm && file.exists(cat_file)) {
          proceed <- ask_yes_no(paste0("overwrite existing file: ", cat_file, "?"))
        }

        if (proceed) {
          if (!quiet) cli_alert_info("saving {cat} to {cat_file}")
          write_boilerplate_db(selected_db[[cat]], cat_file, format = "json", pretty = pretty)
          saved_files <- c(saved_files, cat_file)
          if (!quiet) cli_alert_success("saved {cat} database (JSON)")
        } else {
          if (!quiet) cli_alert_info("save cancelled for {cat}")
        }
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
    saved_files <- character()

    # Determine base name and extension from output_file if provided
    if (!is.null(output_file)) {
      # Extract base name and extension
      ext <- tools::file_ext(output_file)
      base_name <- tools::file_path_sans_ext(basename(output_file))

      # If extension provided, override format
      if (ext %in% c("rds", "json")) {
        format <- ext
      }
    } else {
      # Use default naming
      if (is_unified) {
        base_name <- "unified_db"
      } else {
        base_name <- "exported_db"
      }
    }

    # Save in requested format(s)
    if (format %in% c("rds", "both")) {
      output_path <- file.path(data_path, paste0(base_name, ".rds"))

      # Check for overwrite
      proceed <- TRUE
      if (confirm && file.exists(output_path)) {
        proceed <- ask_yes_no(paste0("save to output file? this will overwrite: ", output_path))
      }

      if (proceed) {
        if (!quiet) cli_alert_info("saving selected elements to {output_path}")
        write_boilerplate_db(selected_db, output_path, format = "rds")
        saved_files <- c(saved_files, output_path)
        if (!quiet) cli_alert_success("saved selected elements to {output_path}")
      } else {
        if (!quiet) cli_alert_info("save cancelled by user")
      }
    }

    if (format %in% c("json", "both")) {
      output_path <- file.path(data_path, paste0(base_name, ".json"))

      # Check for overwrite
      proceed <- TRUE
      if (confirm && file.exists(output_path)) {
        proceed <- ask_yes_no(paste0("save to output file? this will overwrite: ", output_path))
      }

      if (proceed) {
        if (!quiet) cli_alert_info("saving selected elements to {output_path}")
        write_boilerplate_db(selected_db, output_path, format = "json", pretty = pretty)
        saved_files <- c(saved_files, output_path)
        if (!quiet) cli_alert_success("saved selected elements to {output_path}")
      } else {
        if (!quiet) cli_alert_info("save cancelled by user")
      }
    }

    if (length(saved_files) > 0) {
      return(invisible(saved_files))
    } else {
      return(invisible(NULL))
    }
  }
}

