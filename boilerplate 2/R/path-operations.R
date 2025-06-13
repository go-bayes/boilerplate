#' Path-Based Database Operations
#'
#' These functions manipulate databases using dot-separated paths, preserving nesting.
#'
#' @name boilerplate_path_ops
#' @rdname boilerplate_path_ops
NULL

#' Add a Nested Entry to a Database
#'
#' @rdname boilerplate_path_ops
#' @param db List. The database to modify.
#' @param path Character. Dot-separated path (e.g., "statistical.longitudinal.lmtp").
#' @param value Any. The value to set.
#' @param auto_sort Logical. Whether to auto-sort at each level. Default `TRUE`.
#' @return Modified database (list).
#' @export
boilerplate_add_entry <- function(db, path, value, auto_sort = TRUE) {
  path_parts <- strsplit(path, "\\.")[[1]]
  modify_nested_entry(db, path_parts, "add", value, auto_sort)
}

#' Update a Nested Entry in a Database
#'
#' @rdname boilerplate_path_ops
#' @param db List. The database to modify.
#' @param path Character. Dot-separated path.
#' @param value Any. The value to set.
#' @param auto_sort Logical. Whether to auto-sort at each level. Default `TRUE`.
#' @return Modified database (list).
#' @export
boilerplate_update_entry <- function(db, path, value, auto_sort = TRUE) {
  path_parts <- strsplit(path, "\\.")[[1]]
  modify_nested_entry(db, path_parts, "update", value, auto_sort)
}

#' Remove a Nested Entry from a Database
#'
#' @rdname boilerplate_path_ops
#' @param db List. The database to modify.
#' @param path Character. Dot-separated path.
#' @param auto_sort Logical. Whether to auto-sort at each level. Default `TRUE`.
#' @return Modified database (list).
#' @export
boilerplate_remove_entry <- function(db, path, auto_sort = TRUE) {
  path_parts <- strsplit(path, "\\.")[[1]]
  modify_nested_entry(db, path_parts, "remove", NULL, auto_sort)
}

#' Get a Nested Entry from a Database by Path
#'
#' @rdname boilerplate_path_ops
#' @param db List. The database to query.
#' @param path Character. Dot-separated path.
#' @return The value at the specified path.
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
  current_item
}

#' Sort a Database Recursively
#'
#' @rdname boilerplate_path_ops
#' @param db List. The database to sort.
#' @return The sorted database.
#' @export
boilerplate_sort_db <- function(db) {
  sort_db_recursive(db)
}

#' Check if a Path Exists in a Database
#'
#' @rdname boilerplate_path_ops
#' @param db List. The database to check.
#' @param path Character. Dot-separated path.
#' @return Logical. `TRUE` if the path exists, `FALSE` otherwise.
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
  TRUE
}

#' List All Available Paths in a Database
#'
#' @rdname boilerplate_path_ops
#' @param db List. The database to examine.
#' @param prefix Character. Optional prefix for path construction.
#' @return Character vector of all available paths.
#' @export
boilerplate_list_paths <- function(db, prefix = "") {
  if (!is.list(db)) return(character(0))
  result <- character(0)
  for (name in names(db)) {
    current_path <- if (prefix == "") name else paste(prefix, name, sep = ".")
    result <- c(result, current_path)
    if (is.list(db[[name]])) {
      nested <- boilerplate_list_paths(db[[name]], current_path)
      result <- c(result, nested)
    }
  }
  result
}
