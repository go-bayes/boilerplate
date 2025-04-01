#' Manage Boilerplate Measures Database (Deprecated)
#'
#' @description
#' \lifecycle{deprecated}
#' This function is deprecated and will be removed in a future version.
#' Please use `boilerplate_manage_measures2()` for programmatic database management instead.
#'
#' This function provides a command-line interface for managing a database of
#' boilerplate measures. It allows users to create new databases, open existing
#' ones, and perform various operations on the measures within the database.
#'
#' @param measures_path A character string specifying the path to the directory
#'   where the measures database files are stored. If NULL (default), the
#'   function will use the current working directory as determined by here::here().
#'
#' @return This function does not return a value. It runs an interactive
#'   command-line interface for database management.
#'
#' @details
#' The function provides the following main functionalities:
#' \itemize{
#'   \item Create a new measures database
#'   \item Open an existing measures database
#'   \item List available .rds files in the specified directory
#'   \item Add, delete, modify, and copy measures
#'   \item Create backups of the measures database
#'   \item Perform batch edits on measures
#' }
#'
#' @note This function uses the rlang, here, cli, and R6 packages.
#'
#' @examples
#' \dontrun{
#' # DEPRECATED (command-line interface approach):
#' boilerplate_manage_measures()
#'
#' # RECOMMENDED (programmatic approach):
#' # List all measures
#' measures_db <- boilerplate_manage_measures2(action = "list")
#'
#' # Add a new measure
#' measures_db <- boilerplate_manage_measures2(
#'   action = "add",
#'   name = "alcohol_frequency",
#'   measure = list(
#'     description = "Frequency of alcohol consumption was measured using a single item.",
#'     reference = "nzavs2009",
#'     waves = "1-current",
#'     keywords = c("alcohol", "frequency", "consumption"),
#'     items = list("How often do you have a drink containing alcohol?")
#'   )
#' )
#'
#' # Save the database
#' boilerplate_manage_measures2(
#'   action = "save",
#'   db = measures_db
#' )
#' }
#'
#' @importFrom rlang .data
#' @importFrom here here
#' @importFrom cli cli_alert cli_h1 cli_h2 cli_h3 cli_ol cli_text cli_alert_success cli_alert_danger cli_alert_warning cli_alert_info col_cyan col_blue col_grey
#' @importFrom lifecycle deprecate_warn
#' @importFrom R6 R6Class
boilerplate_manage_measures <- function(measures_path = NULL) {
  # Issue deprecation warning
  lifecycle::deprecate_warn(
    when = "0.2.0",
    what = "boilerplate_manage_measures()",
    with = "boilerplate_manage_measures2()",
    details = c(
      "!" = "The command-line interface for managing measures is being deprecated.",
      "i" = "Please use boilerplate_manage_measures2() for programmatic database management.",
      "i" = "See ?boilerplate_manage_measures2 for examples of the new approach."
    )
  )

  if (is.null(measures_path)) {
    measures_path <- here::here()
  }

  measures_path <- measures_path %||% here::here()
  db <- MeasuresDatabase$new(measures_path)
  ui <- UserInterface$new()

  run_gui(db, ui)
}

# Helper function for NULL coalescing (similar to %||% in rlang)
`%||%` <- function(x, y) if (is.null(x)) y else x

# All internal helper functions and R6 classes would follow here...
# MeasuresDatabase class, UserInterface class, and various helper functions like:
# run_gui, create_new_database, open_existing_database, list_rds_files,
# manage_database, add_initial_measures, list_measures, add_measure, delete_measure,
# modify_measure, copy_measure, create_backup, batch_edit_measures,
# enter_or_modify_measure, review_and_save_measure




