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
#' # Import all databases
#' unified_db <- boilerplate_import()
#'
#' # Get all methods
#' methods_db <- boilerplate_methods(unified_db)
#'
#' # Get a specific method using dot notation
#' lmtp_method <- boilerplate_methods(unified_db, "statistical.longitudinal.lmtp")
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

#' Access Measures from Unified Database
#'
#' This function extracts and returns the measures portion of a unified database,
#' optionally retrieving a specific measure by name.
#'
#' @param unified_db List. The unified boilerplate database
#' @param name Character. Optional specific measure to retrieve
#'
#' @return List. The requested measures database or specific measure
#'
#' @examples
#' # Import all databases
#' unified_db <- boilerplate_import()
#'
#' # Get all measures
#' measures_db <- boilerplate_measures(unified_db)
#'
#' # Get a specific measure
#' anxiety_measure <- boilerplate_measures(unified_db, "anxiety_gad7")
#'
#' @export
boilerplate_measures <- function(unified_db, name = NULL) {
  # check if the database contains a measures element
  if (!is.list(unified_db) || !"measures" %in% names(unified_db)) {
    stop("unified_db must contain a 'measures' element")
  }

  measures_db <- unified_db$measures

  if (is.null(name)) {
    return(measures_db)
  } else {
    if (!(name %in% names(measures_db))) {
      stop("measure '", name, "' not found")
    }
    return(measures_db[[name]])
  }
}

#' Access Results from Unified Database
#'
#' This function extracts and returns the results portion of a unified database,
#' optionally retrieving a specific result by name using dot notation.
#'
#' @param unified_db List. The unified boilerplate database
#' @param name Character. Optional specific result to retrieve using dot notation
#'
#' @return List or character. The requested results database or specific result
#'
#' @examples
#' # Import all databases
#' unified_db <- boilerplate_import()
#'
#' # Get all results
#' results_db <- boilerplate_results(unified_db)
#'
#' # Get a specific result using dot notation
#' main_effect <- boilerplate_results(unified_db, "main_effect")
#'
#' @export
boilerplate_results <- function(unified_db, name = NULL) {
  # check if the database contains a results element
  if (!is.list(unified_db) || !"results" %in% names(unified_db)) {
    stop("unified_db must contain a 'results' element")
  }

  results_db <- unified_db$results

  if (is.null(name)) {
    return(results_db)
  } else {
    # split by dots to handle nested paths
    path_parts <- strsplit(name, "\\.")[[1]]

    # navigate through nested structure
    current_item <- results_db
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
#' This function extracts and returns the discussion portion of a unified database,
#' optionally retrieving a specific discussion section by name using dot notation.
#'
#' @param unified_db List. The unified boilerplate database
#' @param name Character. Optional specific discussion section to retrieve using dot notation
#'
#' @return List or character. The requested discussion database or specific section
#'
#' @examples
#' # Import all databases
#' unified_db <- boilerplate_import()
#'
#' # Get all discussion sections
#' discussion_db <- boilerplate_discussion(unified_db)
#'
#' # Get a specific discussion section using dot notation
#' limitations <- boilerplate_discussion(unified_db, "limitations")
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
#' This function extracts and returns the appendix portion of a unified database,
#' optionally retrieving a specific appendix section by name using dot notation.
#'
#' @param unified_db List. The unified boilerplate database
#' @param name Character. Optional specific appendix section to retrieve using dot notation
#'
#' @return List or character. The requested appendix database or specific section
#'
#' @examples
#' # Import all databases
#' unified_db <- boilerplate_import()
#'
#' # Get all appendix sections
#' appendix_db <- boilerplate_appendix(unified_db)
#'
#' # Get a specific appendix section using dot notation
#' sensitivity <- boilerplate_appendix(unified_db, "sensitivity_analyses")
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
#' This function extracts and returns the template portion of a unified database,
#' optionally retrieving a specific template by name.
#'
#' @param unified_db List. The unified boilerplate database
#' @param name Character. Optional specific template to retrieve
#'
#' @return List or character. The requested template database or specific template
#'
#' @examples
#' # Import all databases
#' unified_db <- boilerplate_import()
#'
#' # Get all templates
#' template_db <- boilerplate_template(unified_db)
#'
#' # Get a specific template
#' journal_template <- boilerplate_template(unified_db, "journal_article")
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
