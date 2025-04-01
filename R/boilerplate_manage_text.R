#' Manage Boilerplate Text
#'
#' This function provides a unified interface for managing boilerplate text
#' across different categories (measures, methods, etc.). It allows listing,
#' adding, updating, removing, and retrieving text entries with template
#' variable substitution. Supports arbitrarily nested hierarchical organization
#' through dot-separated paths.
#'
#' @param category Character. Category of text to manage, e.g., "measures", "methods".
#'   Default options are "measures", "methods", "results", and "discussion".
#' @param action Character. Action to perform: "list", "add", "update", "remove", "get", or "save".
#' @param name Character. Identifier for the text entry (required for add/update/remove/get).
#'   For nested entries, use dot-separated paths (e.g., "methods.statistical.lmtp").
#' @param value Text content for the entry (required for add/update).
#' @param db Optional existing database. If not supplied, the default db is loaded.
#' @param text_path Character. Path to the directory where text database files are stored.
#'   If NULL (default), the function will look in the following locations in order:
#'   1. "boilerplate/data/" subdirectory of the current working directory (via here::here())
#'   2. Package installation directory's "boilerplate/data/" folder
#'   3. "boilerplate/data/" relative to the current working directory
#' @param file_name Character. Name of the file to save or load (without path).
#'   If NULL (default), uses "[category]_db.rds".
#' @param template_vars List. Optional variables for template substitution.
#' @param warn_missing Logical. Whether to warn about missing template variables. Default is TRUE.
#' @param auto_sort Logical. Whether to automatically sort the database alphabetically
#'   after add/update operations. Default is TRUE.
#'
#' @return Depending on action:
#'   - "list": Returns the database or part of it
#'   - "add"/"update"/"remove": Returns the modified database
#'   - "get": Returns a specific text entry, with template variables substituted
#'   - "save": Returns TRUE if successful, FALSE otherwise
#'
#' @examples
#' # List default methods
#' methods_db <- boilerplate_manage_text(category = "methods", action = "list")
#'
#' # Add a new method entry
#' methods_db <- boilerplate_manage_text(
#'   category = "methods",
#'   action = "add",
#'   name = "causal_assumptions",
#'   value = "We made the following assumptions: {{assumptions}}"
#' )
#'
#' # Add a nested entry
#' methods_db <- boilerplate_manage_text(
#'   category = "methods",
#'   action = "add",
#'   name = "statistical.longitudinal.lmtp",
#'   value = "We used the LMTP estimator with {{software}}."
#' )
#'
#' # Get a specific entry with template substitution
#' text <- boilerplate_manage_text(
#'   category = "methods",
#'   action = "get",
#'   name = "causal_assumptions",
#'   db = methods_db,
#'   template_vars = list(assumptions = "no unmeasured confounding")
#' )
#'
#' # Get a nested entry with template substitution
#' text <- boilerplate_manage_text(
#'   category = "methods",
#'   action = "get",
#'   name = "statistical.longitudinal.lmtp",
#'   db = methods_db,
#'   template_vars = list(software = "lmtp R package")
#' )
#'
#' # Update an existing entry
#' methods_db <- boilerplate_manage_text(
#'   category = "methods",
#'   action = "update",
#'   name = "causal_assumptions",
#'   value = "Updated assumptions: {{assumptions}}",
#'   db = methods_db
#' )
#'
#' # Save the database to a specific location
#' boilerplate_manage_text(
#'   category = "methods",
#'   action = "save",
#'   db = methods_db,
#'   text_path = "path/to/data",
#'   file_name = "my_methods.rds"
#' )
#'
#' @importFrom glue glue
#' @importFrom here here
#' @importFrom stringr str_extract_all
#' @importFrom tools toTitleCase
#' @importFrom utils modifyList
#' @export
boilerplate_manage_text <- function(
    category = c("measures", "methods", "results", "discussion"),
    action = c("list", "add", "update", "remove", "get", "save"),
    name = NULL,
    value = NULL,
    db = NULL,
    text_path = NULL,
    file_name = NULL,
    template_vars = list(),
    warn_missing = TRUE,
    auto_sort = TRUE  # Default set to TRUE
) {
  # Validate inputs
  category <- match.arg(category)
  action <- match.arg(action)

  # validate name for actions that require it
  if (action %in% c("add", "update", "remove", "get") && is.null(name)) {
    stop(paste("The", action, "action requires a name parameter."))
  }

  # validate value for actions that require it
  if (action %in% c("add", "update") && is.null(value)) {
    stop(paste("The", action, "action requires a value parameter."))
  }

  # load default database if not provided
  if (is.null(db)) {
    db <- load_text_db(category, text_path, file_name)
  }

  # input validation: ensure db is a list
  if (!is.list(db)) {
    stop("Database must be a list.")
  }

  # handle path-based navigation or simple name
  if (!is.null(name) && grepl("\\.", name)) {
    # We have a nested path
    path_parts <- strsplit(name, "\\.")[[1]]

    if (action == "list") {
      # For list action, navigate to the requested folder
      return(get_nested_folder(db, path_parts))
    } else if (action == "get") {
      # For get action, retrieve and process the text
      return(get_nested_text(db, path_parts, template_vars, warn_missing))
    } else if (action %in% c("add", "update", "remove")) {
      # For modification actions, update the nested structure
      db <- modify_nested_entry(db, path_parts, action, value, auto_sort)

      # Sort the entire database if auto_sort is TRUE
      if (auto_sort && action %in% c("add", "update")) {
        db <- sort_db_recursive(db)
      }

      return(db)
    }
  } else {
    # handle regular key-based operations
    if (action == "list") {
      if (!is.null(name)) {
        # List a specific top-level entry
        if (!(name %in% names(db))) {
          stop(paste("Text entry", name, "not found."))
        }
        return(db[[name]])
      }
      return(db)
    } else if (action == "add") {
      if (name %in% names(db)) {
        stop("text entry already exists")
      }
      db[[name]] <- value

      # Sort the database if auto_sort is TRUE
      if (auto_sort) {
        db <- db[order(names(db))]
      }
    } else if (action == "update") {
      if (!(name %in% names(db))) {
        stop("text entry does not exist")
      }
      db[[name]] <- value

      # Sort the database if auto_sort is TRUE
      if (auto_sort) {
        db <- db[order(names(db))]
      }
    } else if (action == "remove") {
      if (!(name %in% names(db))) {
        stop("text entry does not exist")
      }
      db[[name]] <- NULL
    } else if (action == "get") {
      if (!(name %in% names(db))) {
        stop("text entry does not exist")
      }
      text <- db[[name]]
      # Apply template substitution
      return(apply_template_vars(text, template_vars, warn_missing))
    } else if (action == "save") {
      return(save_text_db(db, category, text_path, file_name))
    }
  }

  return(db)
}

# Helper functions specific to text management

#' Retrieve Text from a Nested Structure
#'
#' This helper function recursively navigates a nested list structure
#' to retrieve text at any depth of nesting.
#'
#' @param db The database or sublist to search within
#' @param path_parts Character vector of path components
#' @param template_vars Variables for template substitution
#' @param warn_missing Whether to warn about missing template variables
#'
#' @return Retrieved text with template variables substituted
#'
#' @noRd
get_nested_text <- function(db, path_parts, template_vars = list(), warn_missing = TRUE) {
  if (length(path_parts) == 0) {
    stop("Empty path")
  }

  current_part <- path_parts[1]
  remaining_parts <- path_parts[-1]

  if (!(current_part %in% names(db))) {
    stop(paste("Path component", current_part, "not found"))
  }

  current_item <- db[[current_part]]

  if (length(remaining_parts) == 0) {
    # We've reached the leaf node
    if (is.list(current_item)) {
      # If this is a folder, look for a default entry
      if ("default" %in% names(current_item)) {
        current_item <- current_item[["default"]]
      } else {
        stop(paste("Path component", current_part, "is a folder without a default entry"))
      }
    }

    # Apply template substitution and return
    return(apply_template_vars(current_item, template_vars, warn_missing))
  } else {
    # Keep navigating deeper
    if (!is.list(current_item)) {
      stop(paste("Path component", current_part, "is not a folder"))
    }

    return(get_nested_text(current_item, remaining_parts, template_vars, warn_missing))
  }
}

#' Load Text Database from File
#'
#' @param category Character. Category of text to load.
#' @param text_path Character. Path to the directory where text database files are stored.
#'   If NULL, uses default locations.
#' @param file_name Character. Name of the file to load (without path).
#'   If NULL, uses "[category]_db.rds".
#'
#' @return List. The loaded text database or default if not found.
#'
#' @noRd
load_text_db <- function(category, text_path = NULL, file_name = NULL) {
  # determine file path
  file_path <- get_db_file_path(category, text_path, file_name)

  # check if file exists
  if (file.exists(file_path)) {
    tryCatch({
      db <- readRDS(file_path)
      message(paste(category, "text database loaded from", file_path))
      return(db)
    }, error = function(e) {
      warning(paste("Error loading database:", e$message))
      # fall back to defaults if loading fails
    })
  }

  # return built-in defaults if file doesn't exist or couldn't be loaded
  return(get_default_db(category))
}

#' Save Text Database to File
#'
#' @param db List. The database to save.
#' @param category Character. Category of text to save.
#' @param text_path Character. Path to the directory where text database files are stored.
#'   If NULL, uses the "boilerplate/data/" subdirectory of the current working directory.
#' @param file_name Character. Name of the file to save (without path).
#'   If NULL, uses "[category]_db.rds".
#'
#' @return Logical. TRUE if successful, FALSE otherwise.
#'
#' @noRd
save_text_db <- function(db, category, text_path = NULL, file_name = NULL) {
  # determine file path
  file_path <- get_db_file_path(category, text_path, file_name)

  # ensure directory exists
  dir_path <- dirname(file_path)
  if (!dir.exists(dir_path)) {
    dir.create(dir_path, recursive = TRUE)
    message(paste("Created directory:", dir_path))
  }

  # check if file exists and warn
  if (file.exists(file_path)) {
    warning(paste("Overwriting existing", category, "database file:", file_path))
  }

  # save database
  tryCatch({
    saveRDS(db, file = file_path)
    message(paste(category, "text database saved to", file_path))
    return(TRUE)
  }, error = function(e) {
    warning(paste("Error saving database:", e$message))
    return(FALSE)
  })
}

#' Get Default Database for a Category
#'
#' @param category Character. Category to get defaults for.
#'
#' @return List. The default database for the category.
#'
#' @noRd
get_default_db <- function(category) {
  # return built-in defaults based on category
  if (category == "measures") {
    return(get_default_measures_db())
  } else if (category == "methods") {
    return(get_default_methods_db())
  } else if (category == "results") {
    return(get_default_results_db())
  } else if (category == "discussion") {
    return(get_default_discussion_db())
  }

  # Default to empty database for unknown categories
  warning(paste("Unknown category:", category))
  return(list())
}

