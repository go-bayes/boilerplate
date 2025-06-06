#' Shared Utility Functions for the Boilerplate Package
#'
#' This file contains helper functions used by multiple parts of the package.
#' Moving these functions to a shared utilities file reduces code duplication.

#' Sort a Database Recursively
#'
#' Recursively sorts a database alphabetically at each level.
#'
#' @param db A database (list).
#' @param is_measure_fn Function to determine if an entry is a measure (not a folder).
#'   Default is NULL, which treats all list entries as potential folders.
#' @return The same database with all levels sorted alphabetically.
#'
#' @noRd
sort_db_recursive <- function(db, is_measure_fn = NULL) {
  if (!is.list(db)) {
    return(db)
  }

  # sort the top level
  sorted_names <- sort(names(db))
  sorted_db <- db[sorted_names]

  # recursively sort any nested structures
  for (name in sorted_names) {
    if (is.list(sorted_db[[name]])) {
      # check if this is a measure or a folder
      is_folder <- TRUE
      if (!is.null(is_measure_fn)) {
        is_folder <- !is_measure_fn(sorted_db[[name]])
      }

      if (is_folder) {
        # this is a folder/category, sort it recursively
        sorted_db[[name]] <- sort_db_recursive(sorted_db[[name]], is_measure_fn)
      }
    }
  }

  return(sorted_db)
}

#' Retrieve a Nested Folder from a Database
#'
#' Navigates through a nested list structure to retrieve a specific folder.
#'
#' @param db List. The database to navigate.
#' @param path_parts Character vector. Path components.
#'
#' @return The nested list at the specified path.
#'
#' @noRd
get_nested_folder <- function(db, path_parts) {
  if (length(path_parts) == 0) {
    return(db)
  }

  current_part <- path_parts[1]
  remaining_parts <- path_parts[-1]

  if (!(current_part %in% names(db))) {
    stop(paste("path component", current_part, "not found"))
  }

  current_item <- db[[current_part]]

  if (!is.list(current_item)) {
    stop(paste("path component", current_part, "is not a folder"))
  }

  if (length(remaining_parts) == 0) {
    return(current_item)
  } else {
    return(get_nested_folder(current_item, remaining_parts))
  }
}

#' Modify a Nested Entry in a Database
#'
#' Recursively navigates a nested list structure to add, update, or remove an entry.
#'
#' @param db List. The database to modify.
#' @param path_parts Character vector. Path components.
#' @param action Character. The action to perform ("add", "update", or "remove").
#' @param value Any. The value to set (for add or update).
#' @param auto_sort Logical. Whether to automatically sort at each level.
#'
#' @return The modified database.
#'
#' @noRd
modify_nested_entry <- function(db, path_parts, action, value = NULL, auto_sort = TRUE) {
  if (length(path_parts) == 0) {
    stop("empty path")
  }

  current_part <- path_parts[1]
  remaining_parts <- path_parts[-1]

  # when adding, create missing folders as needed
  if (action == "add" && !(current_part %in% names(db))) {
    if (length(remaining_parts) > 0) {
      # create folder for intermediate path
      db[[current_part]] <- list()
    } else {
      # add leaf value
      db[[current_part]] <- value

      # sort after adding if auto_sort is TRUE
      if (auto_sort) {
        db <- db[order(names(db))]
      }

      return(db)
    }
  } else if (action != "add" && !(current_part %in% names(db))) {
    stop(paste("path component", current_part, "not found"))
  }

  if (length(remaining_parts) == 0) {
    # we've reached the leaf node
    if (action == "add") {
      if (current_part %in% names(db)) {
        stop(paste("entry", current_part, "already exists"))
      }
      db[[current_part]] <- value

      # sort after adding if auto_sort is TRUE
      if (auto_sort) {
        db <- db[order(names(db))]
      }
    } else if (action == "update") {
      db[[current_part]] <- value

      # sort after updating if auto_sort is TRUE
      if (auto_sort) {
        db <- db[order(names(db))]
      }
    } else if (action == "remove") {
      db[[current_part]] <- NULL
    }
  } else {
    # continue navigation
    current_item <- db[[current_part]]

    if (!is.list(current_item)) {
      stop(paste("path component", current_part, "is not a folder"))
    }

    # recursively modify the nested structure
    db[[current_part]] <- modify_nested_entry(current_item, remaining_parts, action, value, auto_sort)

    # sort the current level after modifying deeper levels if auto_sort is TRUE
    if (auto_sort && action %in% c("add", "update")) {
      db <- db[order(names(db))]
    }
  }

  return(db)
}

#' Get File Path for Database
#'
#' Constructs the file path for a database based on the provided parameters.
#' Directory creation is optional and can be controlled with parameters.
#'
#' @param category Character. Category of data (e.g., "methods", "measures").
#' @param base_path Character. Path to the directory where database files are stored.
#'   If NULL, uses the "boilerplate/data/" subdirectory of the current working directory
#'   via the here::here() function.
#' @param file_name Character. Name of the file (without path).
#'   If NULL, uses "[category]_db.rds".
#' @param create_dirs Logical. If TRUE, creates directories that don't exist. Default is FALSE.
#' @param confirm Logical. If TRUE, asks for confirmation before creating directories. Default is TRUE.
#' @param quiet Logical. If TRUE, suppresses all CLI alerts. Default is FALSE.
#'
#' @return Character. The file path for the database.
#'
#' @importFrom cli cli_alert_info cli_alert_success cli_alert_warning cli_alert_danger
#' @noRd
get_db_file_path <- function(category, base_path = NULL, file_name = NULL,
                             create_dirs = FALSE, confirm = TRUE, quiet = FALSE) {
  # default file name
  if (is.null(file_name)) {
    file_name <- paste0(category, "_db.rds")
    if (!quiet) cli_alert_info("using default file name: {file_name}")
  }

  # determine directory path
  if (is.null(base_path)) {
    if (!requireNamespace("here", quietly = TRUE)) {
      if (!quiet) cli_alert_danger("package 'here' is required for default path resolution")
      stop("package 'here' is required for default path resolution. please install it or specify 'base_path' manually.")
    }
    base_path <- here::here("boilerplate", "data")
    if (!quiet) cli_alert_info("using default path: {base_path}")
  }

  # check if directory exists
  if (!dir.exists(base_path)) {
    if (!create_dirs) {
      if (!quiet) cli_alert_danger("directory does not exist: {base_path}")
      stop("directory does not exist. set create_dirs=TRUE to create it or specify an existing directory.")
    }

    # ask for confirmation if needed
    proceed <- TRUE
    if (confirm) {
      proceed <- ask_yes_no(paste0("directory does not exist: ", base_path, ". create it?"))
    }

    if (proceed) {
      dir.create(base_path, recursive = TRUE)
      if (!quiet) cli_alert_success("created directory: {base_path}")
    } else {
      if (!quiet) cli_alert_danger("directory creation cancelled by user")
      stop("directory creation cancelled by user.")
    }
  }

  # combine directory and file name
  file_path <- file.path(base_path, file_name)
  if (!quiet) cli_alert_info("full file path: {file_path}")

  return(file_path)
}

#' Helper function to ask for user confirmation
#'
#' @param question Character. The question to ask the user.
#' @return Logical. TRUE if user confirms, FALSE otherwise.
#' @keywords internal
ask_yes_no <- function(question) {
  # add a default if not already present
  if (!grepl("\\[y/n\\]", question)) {
    question <- paste0(question, " [y/n]: ")
  }

  # ask and get response
  answer <- tolower(trimws(readline(question)))

  # return TRUE for yes variations, FALSE otherwise
  if (answer %in% c("y", "yes")) {
    return(TRUE)
  } else {
    return(FALSE)
  }
}

#' Recursively Merge Two Lists
#'
#' Performs a deep recursive merge of two lists,
#' combining nested structures properly.
#'
#' @param x First list
#' @param y Second list (takes precedence in conflicts)
#'
#' @return Merged list
#'
#' @noRd
merge_recursive_lists <- function(x, y) {
  # Handle base cases
  if (is.null(x) && is.null(y)) return(NULL)
  if (is.null(x)) return(y)
  if (is.null(y)) return(x)

  # If either is not a list, y takes precedence
  if (!is.list(x) || !is.list(y)) return(y)

  # Start with y as the base
  result <- y

  # Add elements from x that are not in y
  for (name in names(x)) {
    if (!(name %in% names(result))) {
      # Name doesn't exist in y, add from x
      result[[name]] <- x[[name]]
    } else {
      # Name exists in both, merge recursively
      if (is.list(x[[name]]) && is.list(result[[name]])) {
        # Both are lists, merge recursively
        result[[name]] <- merge_recursive_lists(x[[name]], result[[name]])
      }
      # Otherwise, y's value takes precedence (already in result)
    }
  }

  return(result)
}

#' Apply Template Variables to Text
#'
#' Substitutes template variables in text using the {{variable_name}} syntax.
#' Uses glue package for robust variable replacement, with a fallback method.
#'
#' @param text Character. The template text with placeholders.
#' @param template_vars List. Variables to substitute in the template.
#' @param warn_missing Logical. Whether to warn about missing template variables.
#'
#' @return Character. The text with variables substituted.
#'
#' @noRd
apply_template_vars <- function(text, template_vars = list(), warn_missing = TRUE) {
  # return early for non-character text or empty variables
  if (!is.character(text)) {
    return(text)
  }

  if (length(template_vars) == 0) {
    return(text)
  }

  # check for malformed template variables - empty names like {{}}
  if (grepl("\\{\\{\\s*\\}\\}", text)) {
    warning("template contains empty variable name(s) - {{}}. please check your template.")
  }

  # for vector values, convert to comma-separated strings
  template_vars_processed <- template_vars
  for (var_name in names(template_vars)) {
    var_value <- template_vars[[var_name]]
    if (length(var_value) > 1) {
      template_vars_processed[[var_name]] <- paste(as.character(var_value), collapse = ", ")
    }
  }

  # perform substitution with base R
  for (var_name in names(template_vars_processed)) {
    if (var_name == "") {
      next  # skip empty variable names
    }
    var_value <- template_vars_processed[[var_name]]
    if (is.character(var_value) || is.numeric(var_value)) {
      # use fixed = TRUE for exact string matching to avoid regex issues
      pattern <- paste0("{{", var_name, "}}")
      text <- gsub(pattern, as.character(var_value), text, fixed = TRUE)
    }
  }

  # issue a warning for unresolved variables if requested
  if (warn_missing) {
    # look for any remaining {{variable}} patterns
    var_pattern <- "\\{\\{([^\\}]+)\\}\\}"
    if (grepl(var_pattern, text)) {
      # extract unresolved variables using base R
      matches <- regmatches(text, gregexpr(var_pattern, text))[[1]]
      if (length(matches) > 0) {
        remaining_vars <- unique(gsub("\\{\\{|\\}\\}", "", matches))
        warning(paste("unresolved template variables:", paste(remaining_vars, collapse = ", ")))
      }
    }
  }

  return(text)
}


#' Convert String to Title Case
#'
#' Replaces janitor::make_clean_names functionality for title case conversion.
#' Cleans and converts strings to title case.
#'
#' @param x Character. String to convert.
#' @param case Character. Case type (only "title" is implemented).
#'
#' @return Character. Cleaned title case string.
#'
#' @noRd
make_clean_title <- function(x, case = "title") {
  if (case != "title") {
    stop("Only 'title' case is currently implemented")
  }

  # replace underscores and hyphens with spaces
  x <- gsub("[_-]", " ", x)

  # remove extra whitespace
  x <- gsub("\\s+", " ", trimws(x))

  # convert to title case
  x <- tools::toTitleCase(x)

  return(x)
}


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

#' Extract Template Variables from Text
#'
#' Extracts all template variable names from text using {{variable}} syntax.
#' Returns unique variable names found in the text.
#'
#' @param text Character. The text containing template variables.
#'
#' @return Character vector of unique variable names found in the text.
#'
#' @noRd
extract_template_variables <- function(text) {
  if (!is.character(text) || length(text) == 0) {
    return(character(0))
  }
  
  # Pattern to match {{variable_name}} with optional spaces
  var_pattern <- "\\{\\{\\s*([^\\}]+?)\\s*\\}\\}"
  
  # Extract all matches
  matches <- gregexpr(var_pattern, text, perl = TRUE)
  
  if (matches[[1]][1] == -1) {
    return(character(0))
  }
  
  # Extract the variable names from the matches
  match_starts <- as.vector(matches[[1]])
  match_lengths <- attr(matches[[1]], "match.length")
  
  # Get the full matches
  full_matches <- substring(text, match_starts, match_starts + match_lengths - 1)
  
  # Extract just the variable names (remove {{ and }} and trim whitespace)
  var_names <- gsub("^\\{\\{\\s*|\\s*\\}\\}$", "", full_matches)
  
  # Return unique variable names
  unique(var_names)
}

