#' Manage Text in Boilerplate Database
#'
#' This function manages text entries in a boilerplate database, allowing
#' for adding, updating, removing, retrieving, and listing text entries.
#' Supports hierarchical organisation through dot-separated paths.
#'
#' @param category Character. Category of text (e.g., "methods", "results").
#' @param action Character. Action to perform: "add", "update", "remove", "get", "list", or "save".
#' @param name Character. Name/path of the text entry. Can use dot notation for nesting (e.g., "statistical.longitudinal.lmtp").
#' @param value Character. Text content to add or update.
#' @param db List. Optional database to use (required for "save", optional for other actions).
#' @param template_vars List. Variables to substitute in template when getting text.
#' @param text_path Character. Path to the directory where text database files are stored.
#'   If NULL (default), the function will look in the following locations in order:
#'   1. "boilerplate/data/" subdirectory of the current working directory (via here::here())
#'   2. Package installation directory's "boilerplate/data/" folder
#'   3. "boilerplate/data/" relative to the current working directory
#' @param file_name Character. Name of the file to save or load (without path).
#'   If NULL (default), uses "[category]_db.rds". Note: For "save" action, file_name must be explicitly provided.
#' @param warn_missing Logical. Whether to warn about missing template variables.
#' @param create_dirs Logical. If TRUE, creates directories that don't exist. Default is FALSE.
#' @param confirm Logical. If TRUE, asks for confirmation before creating directories or modifying files. Default is TRUE.
#' @param dry_run Logical. If TRUE, simulates the operation without writing files. Default is FALSE.
#' @param quiet Logical. If TRUE, suppresses all CLI alerts. Default is FALSE.
#'
#' @return Depending on the action:
#'   * "add", "update", "remove": The modified database (list).
#'   * "get": The text with template variables substituted (character).
#'   * "list": The entire database (list).
#'   * "save": Invisible NULL (called for side effects).
#'
#' @examples
#' \dontrun{
#' # List existing text entries
#' methods_db <- boilerplate_manage_text(
#'   category = "methods",
#'   action = "list"
#' )
#'
#' # Add a new text entry with dot notation for nesting
#' methods_db <- boilerplate_manage_text(
#'   category = "methods",
#'   action = "add",
#'   name = "statistical.longitudinal.lmtp",
#'   value = "We used the LMTP estimator with {{algorithm}} as the base learner."
#' )
#'
#' # Add a document template
#' template_db <- boilerplate_manage_text(
#'   category = "template",
#'   action = "add",
#'   name = "conference_abstract",
#'   value = "# {{title}}\n\n**Authors**: {{authors}}\n\n## Background\n{{background}}\n\n## Methods\n{{methods}}\n\n## Results\n{{results}}"
#' )
#'
#' # Retrieve text with template variables substituted
#' lmtp_text <- boilerplate_manage_text(
#'   category = "methods",
#'   action = "get",
#'   name = "statistical.longitudinal.lmtp",
#'   template_vars = list(algorithm = "Super Learner")
#' )
#'
#' # Save changes to database with explicit file_name to prevent accidental overwrites
#' boilerplate_manage_text(
#'   category = "methods",
#'   action = "save",
#'   db = methods_db,
#'   file_name = "my_methods_db.rds"
#' )
#'
#' # Remove an entry
#' methods_db <- boilerplate_manage_text(
#'   category = "methods",
#'   action = "remove",
#'   name = "statistical.longitudinal.lmtp"
#' )
#' }
#'
#' @importFrom cli cli_alert_info cli_alert_success cli_alert_warning cli_alert_danger
#' @export
boilerplate_manage_text <- function(
    category = c("measures", "methods", "results", "discussion", "appendix", "template"),
    action = c("add", "update", "remove", "get", "list", "save"),
    name = NULL,
    value = NULL,
    db = NULL,
    template_vars = list(),
    text_path = NULL,
    file_name = NULL,
    warn_missing = TRUE,
    create_dirs = FALSE,
    confirm = TRUE,
    dry_run = FALSE,
    quiet = FALSE
) {
  # input validation
  category <- match.arg(category)
  action <- match.arg(action)

  if (!quiet) cli_alert_info("managing {category} text: {action}")
  if (dry_run && !quiet) cli_alert_info("dry run mode: no files will be written")

  # check if name is required for the action
  if (action %in% c("add", "update", "remove", "get") && is.null(name)) {
    if (!quiet) cli_alert_danger("name parameter is required for {action} action")
    stop(paste("name parameter is required for", action, "action"))
  }

  # check if value is required for the action
  if (action %in% c("add", "update") && is.null(value)) {
    if (!quiet) cli_alert_danger("value parameter is required for {action} action")
    stop(paste("value parameter is required for", action, "action"))
  }

  # check if db and file_name are required for the action
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

  # get database file path
  file_path <- get_db_file_path(
    category = category,
    base_path = text_path,
    file_name = file_name,
    create_dirs = create_dirs,
    confirm = confirm,
    quiet = quiet
  )

  # load database if needed and not provided
  if (is.null(db) && action != "save") {
    if (file.exists(file_path)) {
      if (!quiet) cli_alert_info("loading {category} database from {file_path}")
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
      # try to load default database for the category
      if (!quiet) cli_alert_info("database file does not exist: {file_path}, attempting to load default database")
      db <- get_default_db(category)
      if (length(db) == 0) {
        if (!quiet) cli_alert_warning("no default database available for {category}, using empty database")
        db <- list()
      }
    }
  }

  # handle different actions
  if (action == "list") {
    if (!quiet) cli_alert_success("returning complete {category} database")
    return(db)
  } else if (action == "get") {
    # split the name by dots to handle nested paths
    path_parts <- strsplit(name, "\\.")[[1]]

    # try to navigate to the requested item
    item <- tryCatch({
      if (length(path_parts) == 1) {
        if (!(name %in% names(db))) {
          stop(paste("item", name, "not found"))
        }
        db[[name]]
      } else {
        # for nested paths, get the parent folder and then the item
        folder_parts <- path_parts[-length(path_parts)]
        item_name <- path_parts[length(path_parts)]

        folder <- get_nested_folder(db, folder_parts)

        if (!(item_name %in% names(folder))) {
          stop(paste("item", item_name, "not found in path", paste(folder_parts, collapse = ".")))
        }

        folder[[item_name]]
      }
    }, error = function(e) {
      if (!quiet) cli_alert_danger("error retrieving item: {e$message}")
      stop(e$message)
    })

    # apply template variables if it's a character string
    if (is.character(item)) {
      if (!quiet) cli_alert_info("applying template variables to {name}")
      item <- apply_template_vars(item, template_vars, warn_missing)
      if (!quiet) cli_alert_success("retrieved and processed text for {name}")
    } else {
      if (!quiet) cli_alert_success("retrieved item {name}")
    }

    return(item)
  } else if (action %in% c("add", "update", "remove")) {
    # split the name by dots to handle nested paths
    path_parts <- strsplit(name, "\\.")[[1]]

    if (!quiet) cli_alert_info("{action} item: {name}")

    # modify the database
    db <- tryCatch({
      modify_nested_entry(db, path_parts, action, value)
    }, error = function(e) {
      if (!quiet) cli_alert_danger("error modifying database: {e$message}")
      stop(e$message)
    })

    # automatically save changes to file
    if (!dry_run) {
      # ask for confirmation if needed
      proceed <- TRUE
      if (confirm) {
        proceed <- ask_yes_no(paste0("save changes to ", file_path, "?"))
      }

      if (proceed) {
        if (!quiet) cli_alert_info("saving changes to {file_path}")
        saveRDS(db, file = file_path)
        if (!quiet) cli_alert_success("saved updated {category} database")
      } else {
        if (!quiet) cli_alert_info("changes not saved (user cancelled)")
      }
    } else {
      if (!quiet) cli_alert_info("would save changes to {file_path} (dry run)")
    }

    if (!quiet) cli_alert_success("{action} operation completed for {name}")
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
      if (!quiet) cli_alert_success("saved {category} database")
    } else {
      if (!quiet) cli_alert_info("save cancelled by user")
    }

    return(invisible(NULL))
  }
}
#' Get default database for a category
#'
#' @param category Character. Category to get default database for.
#'
#' @return List. Default database for the category.
#'
#' @noRd
get_default_db <- function(category) {
  # this would be implemented to return category-specific defaults
  # placeholder implementation - in reality this would have actual default content
  if (category == "methods") {
    return(list(
      sample = "Participants were recruited from {{population}}.",
      statistical = list(
        longitudinal = list(
          lmtp = "We used the longitudinal modified treatment policy estimator."
        )
      )
    ))
  } else if (category == "results") {
    return(list(
      descriptive = "We describe the characteristics of the sample.",
      primary = "Our primary analysis revealed {{result}}."
    ))
  } else if (category == "discussion") {
    return(list(
      limitations = "This study has several limitations.",
      strengths = "The strengths of this study include {{strengths}}.",
      future = "Future research should explore {{future_directions}}."
    ))
  } else if (category == "measures") {
    return(list(
      demographics = "Standard demographic information was collected.",
      outcomes = "Our primary outcome was {{primary_outcome}}."
    ))
  } else {
    return(list())
  }
}
