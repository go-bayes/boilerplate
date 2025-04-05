#' Path-Based Database Operations
#'
#' These functions provide the ability to manipulate databases using
#' dot-separated paths, preserving the nice nesting capabilities from
#' the original boilerplate_manage_text functions.

#' Add a Nested Entry to a Database
#'
#' @param db List. The database to modify
#' @param path Character. Dot-separated path (e.g., "statistical.longitudinal.lmtp")
#' @param value Any. The value to set
#' @param auto_sort Logical. Whether to automatically sort at each level. Default is TRUE.
#' @return The modified database
#' @export
boilerplate_add_entry <- function(db, path, value, auto_sort = TRUE) {
  path_parts <- strsplit(path, "\\.")[[1]]
  modify_nested_entry(db, path_parts, "add", value, auto_sort)
}

#' Update a Nested Entry in a Database
#'
#' @param db List. The database to modify
#' @param path Character. Dot-separated path (e.g., "statistical.longitudinal.lmtp")
#' @param value Any. The value to set
#' @param auto_sort Logical. Whether to automatically sort at each level. Default is TRUE.
#' @return The modified database
#' @export
boilerplate_update_entry <- function(db, path, value, auto_sort = TRUE) {
  path_parts <- strsplit(path, "\\.")[[1]]
  modify_nested_entry(db, path_parts, "update", value, auto_sort)
}

#' Remove a Nested Entry from a Database
#'
#' @param db List. The database to modify
#' @param path Character. Dot-separated path (e.g., "statistical.longitudinal.lmtp")
#' @param auto_sort Logical. Whether to automatically sort at each level. Default is TRUE.
#' @return The modified database
#' @export
boilerplate_remove_entry <- function(db, path, auto_sort = TRUE) {
  path_parts <- strsplit(path, "\\.")[[1]]
  modify_nested_entry(db, path_parts, "remove", NULL, auto_sort)
}

#' Get a Nested Entry from a Database by Path
#'
#' @param db List. The database to query
#' @param path Character. Dot-separated path (e.g., "statistical.longitudinal.lmtp")
#' @return The value at the specified path
#' @export
boilerplate_get_entry <- function(db, path) {
  path_parts <- strsplit(path, "\\.")[[1]]
  current_item <- db

  for (part in path_parts) {
    if (!is.list(current_item) || !(part %in% names(current_item))) {
      stop("Path component '", part, "' not found")
    }
    current_item <- current_item[[part]]
  }

  return(current_item)
}

#' Sort a Database Recursively
#'
#' @param db List. The database to sort
#' @return The sorted database
#' @export
boilerplate_sort_db <- function(db) {
  sort_db_recursive(db)
}

#' Check if a Path Exists in a Database
#'
#' @param db List. The database to check
#' @param path Character. Dot-separated path (e.g., "statistical.longitudinal.lmtp")
#' @return Logical. TRUE if the path exists, FALSE otherwise
#' @export
boilerplate_path_exists <- function(db, path) {
  path_parts <- strsplit(path, "\\.")[[1]]
  current_item <- db

  for (part in path_parts) {
    if (!is.list(current_item) || !(part %in% names(current_item))) {
      return(FALSE)
    }
    current_item <- current_item[[part]]
  }

  return(TRUE)
}

#' List All Available Paths in a Database
#'
#' @param db List. The database to examine
#' @param prefix Character. Optional prefix for path construction
#' @return Character vector. All available paths in the database
#' @export
boilerplate_list_paths <- function(db, prefix = "") {
  if (!is.list(db)) {
    return(character(0))
  }

  result <- character(0)

  for (name in names(db)) {
    current_path <- if (prefix == "") name else paste(prefix, name, sep = ".")
    result <- c(result, current_path)

    if (is.list(db[[name]])) {
      nested_paths <- boilerplate_list_paths(db[[name]], current_path)
      result <- c(result, nested_paths)
    }
  }

  return(result)
}
# new operations
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

