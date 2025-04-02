#' Manage Measures in Boilerplate Database (Deprecated)
#'
#' This function is partially deprecated. For basic list/get operations,
#' please use boilerplate_import("measures") instead.
#' Other functionality is maintained for backward compatibility.
#'
#' @param action Character. Action to perform: "add", "update", "remove", "get", "list", or "save".
#' @param name Character. Name of the measure to manage.
#' @param measure List. Measure data (for add/update actions).
#' @param db List. Optional database to use (required for "save", optional for other actions).
#' @param measures_path Character. Path to the directory where measures database files are stored.
#' @param file_name Character. Name of the file to save or load (without path).
#' @param create_dirs Logical. If TRUE, creates directories that don't exist.
#' @param confirm Logical. If TRUE, asks for confirmation before making changes.
#' @param dry_run Logical. If TRUE, simulates the operation without writing files.
#' @param quiet Logical. If TRUE, suppresses all CLI alerts.
#'
#' @return Depends on the action (see original function documentation).
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
  action <- match.arg(action)

  # add deprecation warning for specific actions
  if (action %in% c("list", "get")) {
    warning(
      "The '", action, "' action in boilerplate_manage_measures() is deprecated. ",
      "Please use boilerplate_import(\"measures\") instead for listing, ",
      "and boilerplate_import(\"measures\")[[\"name\"]] for getting specific measures.",
      call. = FALSE
    )
  } else if (action == "save") {
    warning(
      "The 'save' action in boilerplate_manage_measures() is deprecated. ",
      "Please use boilerplate_save(db, \"measures\") instead.",
      call. = FALSE
    )
  }

  # handle deprecated file_name parameter
  if (!is.null(file_name) && file_name != "measures_db.rds") {
    warning(
      "Custom file_name parameter is deprecated and will be ignored. ",
      "The unified system uses standardized file names.",
      call. = FALSE
    )
  }

  # for list action, use the new import function
  if (action == "list" && is.null(db)) {
    return(boilerplate_import("measures", data_path = measures_path, quiet = quiet))
  }

  # for save action, use the new save function
  if (action == "save") {
    if (is.null(db)) {
      if (!quiet) cli_alert_danger("db parameter is required for save action")
      stop("db parameter is required for save action")
    }
    return(boilerplate_save(
      db = db,
      category = "measures",
      data_path = measures_path,
      confirm = confirm,
      create_dirs = create_dirs,
      quiet = quiet
    ))
  }

  # for get action, use the new import function if db not provided
  if (action == "get") {
    if (is.null(db)) {
      db <- boilerplate_import("measures", data_path = measures_path, quiet = quiet)
    }

    if (is.null(name)) {
      if (!quiet) cli_alert_danger("name parameter is required for get action")
      stop("name parameter is required for get action")
    }

    if (!(name %in% names(db))) {
      if (!quiet) cli_alert_danger("measure not found: {name}")
      stop(paste("measure not found:", name))
    }

    if (!quiet) cli_alert_success("retrieved measure: {name}")
    return(db[[name]])
  }

  # for add/update/remove actions, first get the database if not provided
  if (is.null(db) && action %in% c("add", "update", "remove")) {
    db <- boilerplate_import("measures", data_path = measures_path, quiet = quiet)
  }

  # handle add action
  if (action == "add") {
    if (is.null(name)) {
      if (!quiet) cli_alert_danger("name parameter is required for add action")
      stop("name parameter is required for add action")
    }

    if (is.null(measure)) {
      if (!quiet) cli_alert_danger("measure parameter is required for add action")
      stop("measure parameter is required for add action")
    }

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
        proceed <- ask_yes_no(paste0("save changes to measures database?"))
      }

      if (proceed) {
        if (!quiet) cli_alert_info("saving measures database")
        boilerplate_save(
          db = db,
          category = "measures",
          data_path = measures_path,
          confirm = FALSE,  # already confirmed
          create_dirs = create_dirs,
          quiet = quiet
        )
        if (!quiet) cli_alert_success("saved updated measures database")
      } else {
        if (!quiet) cli_alert_info("changes not saved (user cancelled)")
      }
    } else {
      if (!quiet) cli_alert_info("would save changes (dry run)")
    }

    if (!quiet) cli_alert_success("added measure: {name}")
    return(db)
  }

  # handle update action
  if (action == "update") {
    if (is.null(name)) {
      if (!quiet) cli_alert_danger("name parameter is required for update action")
      stop("name parameter is required for update action")
    }

    if (is.null(measure)) {
      if (!quiet) cli_alert_danger("measure parameter is required for update action")
      stop("measure parameter is required for update action")
    }

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
        proceed <- ask_yes_no(paste0("save changes to measures database?"))
      }

      if (proceed) {
        if (!quiet) cli_alert_info("saving measures database")
        boilerplate_save(
          db = db,
          category = "measures",
          data_path = measures_path,
          confirm = FALSE,  # already confirmed
          create_dirs = create_dirs,
          quiet = quiet
        )
        if (!quiet) cli_alert_success("saved updated measures database")
      } else {
        if (!quiet) cli_alert_info("changes not saved (user cancelled)")
      }
    } else {
      if (!quiet) cli_alert_info("would save changes (dry run)")
    }

    if (!quiet) cli_alert_success("updated measure: {name}")
    return(db)
  }

  # handle remove action
  if (action == "remove") {
    if (is.null(name)) {
      if (!quiet) cli_alert_danger("name parameter is required for remove action")
      stop("name parameter is required for remove action")
    }

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
        proceed <- ask_yes_no(paste0("save changes to measures database?"))
      }

      if (proceed) {
        if (!quiet) cli_alert_info("saving measures database")
        boilerplate_save(
          db = db,
          category = "measures",
          data_path = measures_path,
          confirm = FALSE,  # already confirmed
          create_dirs = create_dirs,
          quiet = quiet
        )
        if (!quiet) cli_alert_success("saved updated measures database")
      } else {
        if (!quiet) cli_alert_info("changes not saved (user cancelled)")
      }
    } else {
      if (!quiet) cli_alert_info("would save changes (dry run)")
    }

    if (!quiet) cli_alert_success("removed measure: {name}")
    return(db)
  }
}

#' Manage Text in Boilerplate Database (Deprecated)
#'
#' This function is partially deprecated. For basic list operations,
#' please use boilerplate_import(category) instead.
#' Other functionality is maintained for backward compatibility.
#'
#' @param category Character. Category of text.
#' @param action Character. Action to perform: "add", "update", "remove", "get", "list", or "save".
#' @param name Character. Name/path of the text entry.
#' @param value Character. Text content to add or update.
#' @param db List. Optional database to use.
#' @param template_vars List. Variables to substitute in template when getting text.
#' @param text_path Character. Path to the directory where text database files are stored.
#' @param file_name Character. Name of the file to save or load (without path).
#' @param warn_missing Logical. Whether to warn about missing template variables.
#' @param create_dirs Logical. If TRUE, creates directories that don't exist.
#' @param confirm Logical. If TRUE, asks for confirmation before making changes.
#' @param dry_run Logical. If TRUE, simulates the operation without writing files.
#' @param quiet Logical. If TRUE, suppresses all CLI alerts.
#'
#' @return Depends on the action (see original function documentation).
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
  category <- match.arg(category)
  action <- match.arg(action)

  # add deprecation warning for specific actions
  if (action %in% c("list")) {
    warning(
      "The '", action, "' action in boilerplate_manage_text() is deprecated. ",
      "Please use boilerplate_import(\"", category, "\") instead.",
      call. = FALSE
    )
  } else if (action == "save") {
    warning(
      "The 'save' action in boilerplate_manage_text() is deprecated. ",
      "Please use boilerplate_save(db, \"", category, "\") instead.",
      call. = FALSE
    )
  }

  # handle deprecated file_name parameter
  if (!is.null(file_name) && file_name != paste0(category, "_db.rds")) {
    warning(
      "Custom file_name parameter is deprecated and will be ignored. ",
      "The unified system uses standardized file names.",
      call. = FALSE
    )
  }

  # for list action, use the new import function
  if (action == "list" && is.null(db)) {
    return(boilerplate_import(category, data_path = text_path, quiet = quiet))
  }

  # for save action, use the new save function
  if (action == "save") {
    if (is.null(db)) {
      if (!quiet) cli_alert_danger("db parameter is required for save action")
      stop("db parameter is required for save action")
    }
    return(boilerplate_save(
      db = db,
      category = category,
      data_path = text_path,
      confirm = confirm,
      create_dirs = create_dirs,
      quiet = quiet
    ))
  }

  # get database if not provided for other actions
  if (is.null(db) && action != "save") {
    db <- boilerplate_import(category, data_path = text_path, quiet = quiet)
  }

  # handle get action with nested paths
  if (action == "get") {
    if (is.null(name)) {
      if (!quiet) cli_alert_danger("name parameter is required for get action")
      stop("name parameter is required for get action")
    }

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
  }

  # handle add/update/remove actions
  if (action %in% c("add", "update", "remove")) {
    if (is.null(name)) {
      if (!quiet) cli_alert_danger("name parameter is required for {action} action")
      stop(paste("name parameter is required for", action, "action"))
    }

    if (action %in% c("add", "update") && is.null(value)) {
      if (!quiet) cli_alert_danger("value parameter is required for {action} action")
      stop(paste("value parameter is required for", action, "action"))
    }

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
        proceed <- ask_yes_no(paste0("save changes to ", category, " database?"))
      }

      if (proceed) {
        if (!quiet) cli_alert_info("saving changes to {category} database")
        boilerplate_save(
          db = db,
          category = category,
          data_path = text_path,
          confirm = FALSE,  # already confirmed
          create_dirs = create_dirs,
          quiet = quiet
        )
        if (!quiet) cli_alert_success("saved updated {category} database")
      } else {
        if (!quiet) cli_alert_info("changes not saved (user cancelled)")
      }
    } else {
      if (!quiet) cli_alert_info("would save changes (dry run)")
    }

    if (!quiet) cli_alert_success("{action} operation completed for {name}")
    return(db)
  }
}
