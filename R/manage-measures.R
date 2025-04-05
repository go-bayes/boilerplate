#' Manage Measures in Boilerplate Database
#'
#' This function manages measures in a boilerplate database, allowing
#' for adding, updating, removing, retrieving, and listing measure entries.
#'
#' @param action Character. Action to perform: "add", "update", "remove", "get", "list", or "save".
#' @param name Character. Name of the measure to manage.
#' @param measure List. Measure data (for add/update actions).
#' @param db List. Optional database to use (required for "save", optional for other actions).
#' @param measures_path Character. Path to the directory where measures database files are stored.
#'   If NULL (default), uses the "boilerplate/data/" subdirectory of the current working directory
#'   via the here::here() function.
#' @param file_name Character. Name of the file to save or load (without path).
#'   If NULL (default), uses "measures_db.rds". Note: For "save" action, file_name must be explicitly provided.
#' @param create_dirs Logical. If TRUE, creates directories that don't exist. Default is FALSE.
#' @param confirm Logical. If TRUE, asks for confirmation before creating directories or modifying files. Default is TRUE.
#' @param dry_run Logical. If TRUE, simulates the operation without writing files. Default is FALSE.
#' @param quiet Logical. If TRUE, suppresses all CLI alerts. Default is FALSE.
#'
#' @return Depending on the action:
#'   * "add", "update", "remove": The modified database (list).
#'   * "get": The measure data (list).
#'   * "list": The entire database (list).
#'   * "save": Invisible NULL (called for side effects).
#'
#' @examples
#' \dontrun{
#' # First, run with dry_run to see what would happen
#' boilerplate_manage_measures(
#'   action = "list",
#'   measures_path = "path/to/project/data",
#'   dry_run = TRUE
#' )
#'
#' # List existing measures
#' measures_db <- boilerplate_manage_measures(
#'   action = "list",
#'   create_dirs = TRUE,
#'   confirm = TRUE
#' )
#'
#' # Add a new measure
#' measures_db <- boilerplate_manage_measures(
#'   action = "add",
#'   name = "anxiety_gad7",
#'   measure = list(
#'     name = "Generalized Anxiety Disorder Scale (GAD-7)",
#'     description = "Anxiety was measured using the GAD-7 scale.",
#'     reference = "spitzer2006",
#'     waves = "1-3",
#'     keywords = c("anxiety", "mental health", "gad"),
#'     items = list(
#'       "Feeling nervous, anxious, or on edge",
#'       "Not being able to stop or control worrying"
#'     )
#'   )
#' )
#'
#' # Get a specific measure
#' anxiety_measure <- boilerplate_manage_measures(
#'   action = "get",
#'   name = "anxiety_gad7"
#' )
#'
#' # Save changes to database with explicit file_name to prevent accidental overwrites
#' boilerplate_manage_measures(
#'   action = "save",
#'   db = measures_db,
#'   file_name = "my_measures_db.rds",
#'   confirm = TRUE
#' )
#'
#' # Remove a measure
#' measures_db <- boilerplate_manage_measures(
#'   action = "remove",
#'   name = "anxiety_gad7"
#' )
#' }
#'
#' @importFrom cli cli_alert_info cli_alert_success cli_alert_warning cli_alert_danger
#' @export
boilerplate_manage_measures <- function(
    action = c("add", "update", "remove", "get", "list", "save"),
    name = NULL,
    measure = NULL,
    db = NULL,
    measures_path = NULL,
    file_name = NULL,
    create_dirs = FALSE,
    confirm = TRUE,
    dry_run = FALSE,
    quiet = FALSE
) {
  # input validation
  action <- match.arg(action)

  if (!quiet) cli_alert_info("managing measures: {action}")
  if (dry_run && !quiet) cli_alert_info("dry run mode: no files will be written")

  # check if name is required for the action
  if (action %in% c("add", "update", "remove", "get") && is.null(name)) {
    if (!quiet) cli_alert_danger("name parameter is required for {action} action")
    stop(paste("name parameter is required for", action, "action"))
  }

  # check if measure is required for the action
  if (action %in% c("add", "update") && is.null(measure)) {
    if (!quiet) cli_alert_danger("measure parameter is required for {action} action")
    stop(paste("measure parameter is required for", action, "action"))
  }

  # check if db is required for the action
  if (action == "save") {
    if (is.null(db)) {
      if (!quiet) cli_alert_danger("db parameter is required for save action")
      stop("db parameter is required for save action")
    }

    # check if file_name is explicitly provided for save action
    if (is.null(file_name)) {
      if (!quiet) cli_alert_danger("file_name parameter is required for save action")
      stop("file_name parameter is required for save action to prevent accidental overwrites")
    }
  }

  # default file name if not provided and not saving
  if (is.null(file_name) && action != "save") {
    file_name <- "measures_db.rds"
    if (!quiet) cli_alert_info("using default file name: {file_name}")
  }

  # get database file path
  file_path <- get_db_file_path(
    category = "measures",
    base_path = measures_path,
    file_name = file_name,
    create_dirs = create_dirs,
    confirm = confirm,
    quiet = quiet
  )

  # load database if needed and not provided
  if (is.null(db) && action != "save") {
    if (file.exists(file_path)) {
      if (!quiet) cli_alert_info("loading measures database from {file_path}")
      db <- tryCatch({
        readRDS(file_path)
      }, error = function(e) {
        if (!quiet) cli_alert_danger("error loading database: {e$message}")
        # Return empty list as default
        return(list())
      })
    } else if (action == "list") {
      if (!quiet) cli_alert_warning("database file does not exist: {file_path}, returning empty list")
      db <- list()
    } else {
      # try to load default database for measures
      if (!quiet) cli_alert_info("database file does not exist: {file_path}, attempting to load default database")
      db <- get_default_measures_db()
      if (length(db) == 0) {
        if (!quiet) cli_alert_warning("no default database available for measures, using empty database")
        db <- list()
      }
    }
  }

  # handle different actions
  if (action == "list") {
    if (!quiet) cli_alert_success("returning complete measures database")
    return(db)
  } else if (action == "get") {
    if (!(name %in% names(db))) {
      if (!quiet) cli_alert_danger("measure not found: {name}")
      stop(paste("measure not found:", name))
    }

    measure_data <- db[[name]]
    if (!quiet) cli_alert_success("retrieved measure: {name}")
    return(measure_data)
  } else if (action == "add") {
    if (name %in% names(db)) {
      if (!quiet) cli_alert_danger("measure already exists: {name}")
      stop(paste("measure already exists:", name))
    }

    if (!quiet) cli_alert_info("adding measure: {name}")

    # add measure to the database
    db[[name]] <- measure

    # sort the database alphabetically for consistency
    db <- db[order(names(db))]

    # automatically save changes if not in dry run mode
    if (!dry_run) {
      # ask for confirmation if needed
      proceed <- TRUE
      if (confirm) {
        proceed <- ask_yes_no(paste0("save changes to ", file_path, "?"))
      }

      if (proceed) {
        if (!quiet) cli_alert_info("saving changes to {file_path}")
        saveRDS(db, file = file_path)
        if (!quiet) cli_alert_success("saved updated measures database")
      } else {
        if (!quiet) cli_alert_info("changes not saved (user cancelled)")
      }
    } else {
      if (!quiet) cli_alert_info("would save changes to {file_path} (dry run)")
    }

    if (!quiet) cli_alert_success("added measure: {name}")
    return(db)
  } else if (action == "update") {
    if (!(name %in% names(db))) {
      if (!quiet) cli_alert_danger("measure not found for update: {name}")
      stop(paste("measure not found for update:", name))
    }

    if (!quiet) cli_alert_info("updating measure: {name}")

    # update measure in the database
    db[[name]] <- measure

    # automatically save changes if not in dry run mode
    if (!dry_run) {
      # ask for confirmation if needed
      proceed <- TRUE
      if (confirm) {
        proceed <- ask_yes_no(paste0("save changes to ", file_path, "?"))
      }

      if (proceed) {
        if (!quiet) cli_alert_info("saving changes to {file_path}")
        saveRDS(db, file = file_path)
        if (!quiet) cli_alert_success("saved updated measures database")
      } else {
        if (!quiet) cli_alert_info("changes not saved (user cancelled)")
      }
    } else {
      if (!quiet) cli_alert_info("would save changes to {file_path} (dry run)")
    }

    if (!quiet) cli_alert_success("updated measure: {name}")
    return(db)
  } else if (action == "remove") {
    if (!(name %in% names(db))) {
      if (!quiet) cli_alert_danger("measure not found for removal: {name}")
      stop(paste("measure not found for removal:", name))
    }

    if (!quiet) cli_alert_info("removing measure: {name}")

    # remove measure from the database
    db[[name]] <- NULL

    # automatically save changes if not in dry run mode
    if (!dry_run) {
      # ask for confirmation if needed
      proceed <- TRUE
      if (confirm) {
        proceed <- ask_yes_no(paste0("save changes to ", file_path, "?"))
      }

      if (proceed) {
        if (!quiet) cli_alert_info("saving changes to {file_path}")
        saveRDS(db, file = file_path)
        if (!quiet) cli_alert_success("saved updated measures database")
      } else {
        if (!quiet) cli_alert_info("changes not saved (user cancelled)")
      }
    } else {
      if (!quiet) cli_alert_info("would save changes to {file_path} (dry run)")
    }

    if (!quiet) cli_alert_success("removed measure: {name}")
    return(db)
  } else if (action == "save") {
    if (dry_run) {
      if (!quiet) cli_alert_info("would save database to {file_path} (dry run)")
      return(invisible(NULL))
    }

    # ask for confirmation if needed
    proceed <- TRUE
    if (confirm && file.exists(file_path)) {
      proceed <- ask_yes_no(paste0("overwrite existing file: ", file_path, "?"))
    }

    if (proceed) {
      if (!quiet) cli_alert_info("saving database to {file_path}")
      saveRDS(db, file = file_path)
      if (!quiet) cli_alert_success("saved measures database")
    } else {
      if (!quiet) cli_alert_info("save cancelled by user")
    }

    return(invisible(NULL))
  }
}
