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



