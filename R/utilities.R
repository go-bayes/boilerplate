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

  # Sort the top level
  sorted_names <- sort(names(db))
  sorted_db <- db[sorted_names]

  # Recursively sort any nested structures
  for (name in sorted_names) {
    if (is.list(sorted_db[[name]])) {
      # Check if this is a measure or a folder
      is_folder <- TRUE
      if (!is.null(is_measure_fn)) {
        is_folder <- !is_measure_fn(sorted_db[[name]])
      }

      if (is_folder) {
        # This is a folder/category, sort it recursively
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
    stop(paste("Path component", current_part, "not found"))
  }

  current_item <- db[[current_part]]

  if (!is.list(current_item)) {
    stop(paste("Path component", current_part, "is not a folder"))
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
    stop("Empty path")
  }

  current_part <- path_parts[1]
  remaining_parts <- path_parts[-1]

  # When adding, create missing folders as needed
  if (action == "add" && !(current_part %in% names(db))) {
    if (length(remaining_parts) > 0) {
      # Create folder for intermediate path
      db[[current_part]] <- list()
    } else {
      # Add leaf value
      db[[current_part]] <- value

      # Sort after adding if auto_sort is TRUE
      if (auto_sort) {
        db <- db[order(names(db))]
      }

      return(db)
    }
  } else if (action != "add" && !(current_part %in% names(db))) {
    stop(paste("Path component", current_part, "not found"))
  }

  if (length(remaining_parts) == 0) {
    # We've reached the leaf node
    if (action == "add") {
      if (current_part %in% names(db)) {
        stop(paste("Entry", current_part, "already exists"))
      }
      db[[current_part]] <- value

      # Sort after adding if auto_sort is TRUE
      if (auto_sort) {
        db <- db[order(names(db))]
      }
    } else if (action == "update") {
      db[[current_part]] <- value

      # Sort after updating if auto_sort is TRUE
      if (auto_sort) {
        db <- db[order(names(db))]
      }
    } else if (action == "remove") {
      db[[current_part]] <- NULL
    }
  } else {
    # Continue navigation
    current_item <- db[[current_part]]

    if (!is.list(current_item)) {
      stop(paste("Path component", current_part, "is not a folder"))
    }

    # Recursively modify the nested structure
    db[[current_part]] <- modify_nested_entry(current_item, remaining_parts, action, value, auto_sort)

    # Sort the current level after modifying deeper levels if auto_sort is TRUE
    if (auto_sort && action %in% c("add", "update")) {
      db <- db[order(names(db))]
    }
  }

  return(db)
}

#' Get File Path for Database
#'
#' Constructs the file path for a database based on the provided parameters.
#'
#' @param category Character. Category of data (e.g., "methods", "measures").
#' @param base_path Character. Path to the directory where database files are stored.
#'   If NULL, uses the "boilerplate/data/" subdirectory of the current working directory
#'   via the here::here() function.
#' @param file_name Character. Name of the file (without path).
#'   If NULL, uses "[category]_db.rds".
#'
#' @return Character. The file path for the database.
#'
#' @noRd
get_db_file_path <- function(category, base_path = NULL, file_name = NULL) {
  # default file name
  if (is.null(file_name)) {
    file_name <- paste0(category, "_db.rds")
  }

  # determine directory path
  if (is.null(base_path)) {
    if (!requireNamespace("here", quietly = TRUE)) {
      stop("Package 'here' is required for default path resolution. Please install it or specify 'base_path' manually.")
    }
    dir_path <- here::here("boilerplate", "data")

    # Create directory if it doesn't exist
    if (!dir.exists(dir_path)) {
      dir.create(dir_path, recursive = TRUE)
      message(paste("Created directory:", dir_path))
    }
  } else {
    dir_path <- base_path
  }

  # combine directory and file name
  return(file.path(dir_path, file_name))
}

#' Recursively Merge Two Lists
#'
#' Performs a deep recursive merge of two lists,
#' combining nested structures.
#'
#' @param x First list
#' @param y Second list (takes precedence in conflicts)
#'
#' @return Merged list
#'
#' @noRd
merge_recursive_lists <- function(x, y) {
  if (!is.list(x) || !is.list(y)) return(y)

  # For each name in x
  for (name in names(x)) {
    if (name %in% names(y)) {
      if (is.list(x[[name]]) && is.list(y[[name]])) {
        # Recursively merge lists
        y[[name]] <- merge_recursive_lists(x[[name]], y[[name]])
      }
      # Otherwise y's value takes precedence
    } else {
      # If not in y, add from x
      y[[name]] <- x[[name]]
    }
  }

  return(y)
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
#' @importFrom glue glue
#' @noRd
apply_template_vars <- function(text, template_vars = list(), warn_missing = TRUE) {
  # Return early for non-character text or empty variables
  if (length(template_vars) == 0 || !is.character(text)) {
    return(text)
  }

  # For vector values, convert to comma-separated strings
  template_vars_processed <- template_vars
  for (var_name in names(template_vars)) {
    var_value <- template_vars[[var_name]]
    if (length(var_value) > 1) {
      template_vars_processed[[var_name]] <- paste(as.character(var_value), collapse = ", ")
    }
  }

  # Prepare the environment for glue
  env <- list2env(template_vars_processed, parent = emptyenv())

  # Try to use glue for substitution
  tryCatch({
    # Convert {{var}} syntax to glue's {var} syntax
    glue_ready_text <- gsub("\\{\\{([^\\}]+)\\}\\}", "{\\1}", text)
    result <- glue::glue(glue_ready_text, .envir = env)
    return(as.character(result))
  }, error = function(e) {
    # Fallback to manual substitution if glue fails
    for (var_name in names(template_vars_processed)) {
      var_value <- template_vars_processed[[var_name]]
      if (is.character(var_value) || is.numeric(var_value)) {
        text <- gsub(
          paste0("\\{\\{", var_name, "\\}\\}"),
          as.character(var_value),
          text,
          fixed = FALSE
        )
      }
    }

    # Issue a warning for unresolved variables if requested
    if (warn_missing) {
      # Look for any remaining {{variable}} patterns
      var_pattern <- "\\{\\{([^\\}]+)\\}\\}"
      if (requireNamespace("stringr", quietly = TRUE)) {
        # Use stringr if available
        remaining_vars <- stringr::str_extract_all(text, var_pattern)
        if (length(remaining_vars[[1]]) > 0) {
          remaining_vars <- unique(gsub("\\{\\{|\\}\\}", "", remaining_vars[[1]]))
          warning(paste("Unresolved template variables:", paste(remaining_vars, collapse = ", ")))
        }
      } else {
        # Fallback to base R
        if (grepl(var_pattern, text)) {
          matches <- gregexpr(var_pattern, text)
          if (matches[[1]][1] != -1) {
            warning("Unresolved template variables present. Consider installing the 'stringr' package for detailed information.")
          }
        }
      }
    }

    return(text)
  })
}

