#' Access Methods from Unified Database
#'
#' This function extracts and returns the methods portion of a unified database,
#' optionally retrieving a specific method by name.
#'
#' @param unified_db List. The unified boilerplate database
#' @param name Character. Optional specific method to retrieve using dot notation
#'
#' @return List or character. The requested methods database or specific method
#'
#' @examples
#' # Create a temporary directory and initialise database
#' temp_dir <- tempdir()
#' data_path <- file.path(temp_dir, "boilerplate_methods_example", "data")
#'
#' # Initialise with default methods content
#' boilerplate_init(
#'   categories = "methods",
#'   data_path = data_path,
#'   create_dirs = TRUE,
#'   create_empty = FALSE,
#'   confirm = FALSE,
#'   quiet = TRUE
#' )
#'
#' # Import all databases
#' unified_db <- boilerplate_import(data_path = data_path, quiet = TRUE)
#'
#' # Get all methods
#' methods_db <- boilerplate_methods(unified_db)
#' names(methods_db)
#'
#' # Get a specific method using dot notation (if it exists)
#' if ("statistical" %in% names(methods_db) &&
#'     "longitudinal" %in% names(methods_db$statistical) &&
#'     "lmtp" %in% names(methods_db$statistical$longitudinal)) {
#'   lmtp_method <- boilerplate_methods(unified_db, "statistical.longitudinal.lmtp")
#' }
#'
#' # Clean up
#' unlink(file.path(temp_dir, "boilerplate_methods_example"), recursive = TRUE)
#'
#' @export
boilerplate_methods <- function(unified_db, name = NULL) {
  # check if the database contains a methods element
  if (!is.list(unified_db) || !"methods" %in% names(unified_db)) {
    stop("unified_db must contain a 'methods' element")
  }

  methods_db <- unified_db$methods

  if (is.null(name)) {
    return(methods_db)
  } else {
    # split by dots to handle nested paths
    path_parts <- strsplit(name, "\\.")[[1]]

    # navigate through nested structure
    current_item <- methods_db
    for (part in path_parts) {
      if (!is.list(current_item) || !(part %in% names(current_item))) {
        stop("path component '", part, "' not found")
      }
      current_item <- current_item[[part]]
    }

    return(current_item)
  }
}

#' Access Discussion from Unified Database
#'
#' @title Access Discussion Content
#' @description This function extracts and returns the discussion portion of a unified database,
#' optionally retrieving a specific discussion section by name using dot notation.
#'
#' @param unified_db List. The unified boilerplate database containing discussion content
#' @param name Character. Optional specific discussion section to retrieve using dot notation
#'   (e.g., "limitations.statistical" for nested content)
#'
#' @return List or character. The requested discussion database or specific section.
#'   If name is NULL, returns the entire discussion database. If name is specified,
#'   returns the content at that path.
#'
#' @examples
#' # Create a temporary directory and initialise database
#' temp_dir <- tempdir()
#' data_path <- file.path(temp_dir, "boilerplate_discussion_example", "data")
#'
#' # Initialise with default discussion content
#' boilerplate_init(
#'   categories = "discussion",
#'   data_path = data_path,
#'   create_dirs = TRUE,
#'   create_empty = FALSE,
#'   confirm = FALSE,
#'   quiet = TRUE
#' )
#'
#' # Import all databases
#' unified_db <- boilerplate_import(data_path = data_path, quiet = TRUE)
#'
#' # Get all discussion sections
#' discussion_db <- boilerplate_discussion(unified_db)
#' names(discussion_db)
#'
#' # Get a specific discussion section (if it exists)
#' if ("discussion" %in% names(unified_db) && length(unified_db$discussion) > 0) {
#'   section_names <- names(unified_db$discussion)
#'   if (length(section_names) > 0) {
#'     first_section <- boilerplate_discussion(unified_db, section_names[1])
#'   }
#' }
#'
#' # Clean up
#' unlink(file.path(temp_dir, "boilerplate_discussion_example"), recursive = TRUE)
#'
#' @export
boilerplate_discussion <- function(unified_db, name = NULL) {
  # check if the database contains a discussion element
  if (!is.list(unified_db) || !"discussion" %in% names(unified_db)) {
    stop("unified_db must contain a 'discussion' element")
  }

  discussion_db <- unified_db$discussion

  if (is.null(name)) {
    return(discussion_db)
  } else {
    # split by dots to handle nested paths
    path_parts <- strsplit(name, "\\.")[[1]]

    # navigate through nested structure
    current_item <- discussion_db
    for (part in path_parts) {
      if (!is.list(current_item) || !(part %in% names(current_item))) {
        stop("path component '", part, "' not found")
      }
      current_item <- current_item[[part]]
    }

    return(current_item)
  }
}

#' Access Appendix from Unified Database
#'
#' @title Access Appendix Content
#' @description This function extracts and returns the appendix portion of a unified database,
#' optionally retrieving a specific appendix section by name using dot notation.
#'
#' @param unified_db List. The unified boilerplate database containing appendix content
#' @param name Character. Optional specific appendix section to retrieve using dot notation
#'   (e.g., "supplementary.tables" for nested content)
#'
#' @return List or character. The requested appendix database or specific section.
#'   If name is NULL, returns the entire appendix database. If name is specified,
#'   returns the content at that path.
#'
#' @examples
#' # Create a temporary directory and initialise database
#' temp_dir <- tempdir()
#' data_path <- file.path(temp_dir, "boilerplate_appendix_example", "data")
#'
#' # Initialise with default appendix content
#' boilerplate_init(
#'   categories = "appendix",
#'   data_path = data_path,
#'   create_dirs = TRUE,
#'   create_empty = FALSE,
#'   confirm = FALSE,
#'   quiet = TRUE
#' )
#'
#' # Import all databases
#' unified_db <- boilerplate_import(data_path = data_path, quiet = TRUE)
#'
#' # Get all appendix sections
#' appendix_db <- boilerplate_appendix(unified_db)
#' names(appendix_db)
#'
#' # Get a specific appendix section (if it exists)
#' if ("appendix" %in% names(unified_db) && length(unified_db$appendix) > 0) {
#'   section_names <- names(unified_db$appendix)
#'   if (length(section_names) > 0) {
#'     first_section <- boilerplate_appendix(unified_db, section_names[1])
#'   }
#' }
#'
#' # Clean up
#' unlink(file.path(temp_dir, "boilerplate_appendix_example"), recursive = TRUE)
#'
#' @export
boilerplate_appendix <- function(unified_db, name = NULL) {
  # check if the database contains a appendix element
  if (!is.list(unified_db) || !"appendix" %in% names(unified_db)) {
    stop("unified_db must contain an 'appendix' element")
  }

  appendix_db <- unified_db$appendix

  if (is.null(name)) {
    return(appendix_db)
  } else {
    # split by dots to handle nested paths
    path_parts <- strsplit(name, "\\.")[[1]]

    # navigate through nested structure
    current_item <- appendix_db
    for (part in path_parts) {
      if (!is.list(current_item) || !(part %in% names(current_item))) {
        stop("path component '", part, "' not found")
      }
      current_item <- current_item[[part]]
    }

    return(current_item)
  }
}

#' Access Templates from Unified Database
#'
#' @title Access Template Content
#' @description This function extracts and returns the template portion of a unified database,
#' optionally retrieving a specific template by name.
#'
#' @param unified_db List. The unified boilerplate database containing template content
#' @param name Character. Optional specific template to retrieve by name
#'
#' @return List or character. The requested template database or specific template.
#'   If name is NULL, returns the entire template database. If name is specified,
#'   returns the template with that name.
#'
#' @examples
#' # Create a temporary directory and initialise database
#' temp_dir <- tempdir()
#' data_path <- file.path(temp_dir, "boilerplate_template_example", "data")
#'
#' # Initialise with default template content
#' boilerplate_init(
#'   categories = "template",
#'   data_path = data_path,
#'   create_dirs = TRUE,
#'   create_empty = FALSE,
#'   confirm = FALSE,
#'   quiet = TRUE
#' )
#'
#' # Import all databases
#' unified_db <- boilerplate_import(data_path = data_path, quiet = TRUE)
#'
#' # Get all templates
#' template_db <- boilerplate_template(unified_db)
#' names(template_db)
#'
#' # Get a specific template (if it exists)
#' if ("template" %in% names(unified_db) && length(unified_db$template) > 0) {
#'   template_names <- names(unified_db$template)
#'   if (length(template_names) > 0) {
#'     first_template <- boilerplate_template(unified_db, template_names[1])
#'   }
#' }
#'
#' # Clean up
#' unlink(file.path(temp_dir, "boilerplate_template_example"), recursive = TRUE)
#'
#' @export
boilerplate_template <- function(unified_db, name = NULL) {
  # check if the database contains a template element
  if (!is.list(unified_db) || !"template" %in% names(unified_db)) {
    stop("unified_db must contain a 'template' element")
  }

  template_db <- unified_db$template

  if (is.null(name)) {
    return(template_db)
  } else {
    if (!(name %in% names(template_db))) {
      stop("template '", name, "' not found")
    }
    return(template_db[[name]])
  }
}
