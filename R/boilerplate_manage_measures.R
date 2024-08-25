#' Manage Boilerplate Measures Database
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
#' @note This function requires the rlang, here, cli, and R6 packages.
#'
#' @examples
#' \dontrun{
#' # Run the function with default path (current working directory)
#' boilerplate_manage_measures()
#'
#' # Run the function with a specific path
#' boilerplate_manage_measures("/path/to/measures/directory")
#' }
#'
#' @import rlang
#' @import here
#' @import cli
#' @import R6
#' @export
boilerplate_manage_measures <- function(measures_path = NULL) {
  require(rlang)
  require(here)
  require(cli)

  measures_path <- measures_path %||% here::here()
  db <- MeasuresDatabase$new(measures_path)
  ui <- UserInterface$new()

  run_gui(db, ui)
}

# measures database class
# this class handles loading, saving, and editing the measures database.
MeasuresDatabase <- R6::R6Class("MeasuresDatabase",
                                public = list(
                                  path = NULL,
                                  current_file = NULL,
                                  data = NULL,

                                  initialize = function(path) {
                                    self$path <- path
                                    self$data <- list()
                                  },

                                  load_data = function(file_name) {
                                    file_path <- file.path(self$path, file_name)
                                    if (file.exists(file_path)) {
                                      self$data <- readRDS(file_path)
                                      self$current_file <- file_name
                                      cli::cli_alert_success("Data loaded from: {.file {file_path}}")
                                      return(TRUE)
                                    } else {
                                      cli::cli_alert_danger("File not found: {.file {file_path}}")
                                      return(FALSE)
                                    }
                                  },

                                  save_data = function(file_name = NULL, backup = FALSE) {
                                    file_name <- file_name %||% self$current_file
                                    if (is.null(file_name)) {
                                      cli::cli_alert_danger("No file name specified.")
                                      return(FALSE)
                                    }

                                    tryCatch({
                                      file_path <- file.path(self$path, file_name)
                                      saveRDS(self$data, file = file_path)
                                      cli::cli_alert_success("Data saved as: {.file {file_path}}")

                                      if (backup) {
                                        backup_file <- paste0("backup_", file_name)
                                        backup_path <- file.path(self$path, backup_file)
                                        saveRDS(self$data, file = backup_path)
                                        cli::cli_alert_success("Backup saved as: {.file {backup_path}}")
                                      }
                                      self$current_file <- file_name
                                      return(TRUE)
                                    }, error = function(e) {
                                      cli::cli_alert_danger("Error saving data: {e$message}")
                                      return(FALSE)
                                    })
                                  },

                                  list_measures = function() {
                                    return(names(self$data))
                                  },

                                  add_measure = function(measure) {
                                    self$data[[measure$name]] <- measure
                                    self$data <- self$data[order(names(self$data))]
                                  },

                                  delete_measure = function(name) {
                                    if (name %in% names(self$data)) {
                                      self$data[[name]] <- NULL
                                      self$data <- self$data[order(names(self$data))]
                                      return(TRUE)
                                    }
                                    return(FALSE)
                                  },

                                  get_measure = function(name) {
                                    return(self$data[[name]])
                                  },

                                  batch_edit_measures = function(field, old_value, new_value) {
                                    edited_count <- 0
                                    for (measure_name in names(self$data)) {
                                      measure <- self$data[[measure_name]]
                                      if (field %in% names(measure)) {
                                        if (is.character(measure[[field]])) {
                                          if (measure[[field]] == old_value) {
                                            self$data[[measure_name]][[field]] <- new_value
                                            edited_count <- edited_count + 1
                                          }
                                        } else if (is.list(measure[[field]])) {
                                          for (i in seq_along(measure[[field]])) {
                                            if (measure[[field]][[i]] == old_value) {
                                              self$data[[measure_name]][[field]][[i]] <- new_value
                                              edited_count <- edited_count + 1
                                            }
                                          }
                                        }
                                      }
                                    }
                                    return(edited_count)
                                  }
                                )
)

# user interface class
# this class handles user input and output, including menus and prompts.
UserInterface <- R6::R6Class("UserInterface",
                             public = list(
                               get_input = function(prompt, allow_empty = FALSE, multiline = FALSE) {
                                 if (multiline) {
                                   return(self$get_multiline_input(prompt))
                                 }

                                 while (TRUE) {
                                   input <- trimws(readline(cli::col_cyan(prompt)))
                                   if (input != "" || allow_empty)
                                     return(input)
                                   cli::cli_alert_danger("Input cannot be empty. Please try again.")
                                 }
                               },

                               get_multiline_input = function(prompt) {
                                 cli::cli_text(cli::col_cyan(prompt))
                                 cli::cli_text(cli::col_cyan("Enter your text (press Enter twice on an empty line to finish):"))
                                 lines <- character()
                                 empty_line_count <- 0
                                 repeat {
                                   line <- readline()
                                   if (line == "") {
                                     empty_line_count <- empty_line_count + 1
                                     if (empty_line_count == 2) {
                                       break
                                     }
                                   } else {
                                     empty_line_count <- 0
                                   }
                                   lines <- c(lines, line)
                                 }
                                 paste(lines, collapse = "\n")
                               },

                               display_menu = function(title, options) {
                                 cli::cli_h2(title)
                                 cli::cli_ol(options)
                               },

                               get_choice = function(prompt, max_choice, allow_zero = FALSE) {
                                 while (TRUE) {
                                   choice <- as.integer(self$get_input(prompt))
                                   if (!is.na(choice) &&
                                       ((allow_zero && choice >= 0 && choice <= max_choice) ||
                                        (!allow_zero && choice >= 1 && choice <= max_choice))) {
                                     return(choice)
                                   }
                                   if (allow_zero) {
                                     cli::cli_alert_danger("Invalid choice. Please enter a number between 0 and {max_choice}.")
                                   } else {
                                     cli::cli_alert_danger("Invalid choice. Please enter a number between 1 and {max_choice}.")
                                   }
                                 }
                               }
                             )
)
# runs the graphical user interface for the measures database manager
run_gui <- function(db, ui) {
  cli::cli_h1("Welcome to the Boilerplate Measures Database Manager")

  repeat {
    options <- c(
      "Create new measures database",
      "Open existing measures database",
      "List available .rds files",
      "Quit"
    )
    ui$display_menu("Boilerplate Measures Manager", options)

    choice <- ui$get_choice("Enter your choice: ", length(options))

    if (choice == 1) {
      create_new_database(db, ui)
    } else if (choice == 2) {
      open_existing_database(db, ui)
    } else if (choice == 3) {
      list_rds_files(db$path)
    } else if (choice == 4) {
      confirm_quit <- tolower(ui$get_input("Are you sure you want to quit? Unsaved changes will be lost. (y/n): "))
      if (confirm_quit == "y") {
        cli::cli_alert_success("Exiting program. Goodbye!")
        return()
      }
    }

    if (choice == 1 || choice == 2) break
  }

  manage_database(db, ui)
}

# creates a new measures database
create_new_database <- function(db, ui) {
  cli::cli_h2("Creating a new measures database")

  db_name <- ui$get_input("Enter a name for the new database (without .rds extension): ")
  if (!grepl("\\.rds$", db_name)) {
    db_name <- paste0(db_name, ".rds")
  }

  full_path <- file.path(db$path, db_name)
  cli::cli_alert_info("The database will be created at: {.file {full_path}}")
  confirm <- tolower(ui$get_input("Is this correct? (y/n): "))

  if (confirm == "y") {
    db$data <- list()
    if (db$save_data(db_name)) {
      cli::cli_alert_success("New measures database '{.file {db_name}}' created.")
      add_initial_measures(db, ui)
      return(TRUE)
    } else {
      cli::cli_alert_danger("Failed to create new database.")
      return(FALSE)
    }
  } else {
    cli::cli_alert_warning("Database creation cancelled.")
    return(FALSE)
  }
}

# opens an existing measures database
open_existing_database <- function(db, ui) {
  files <- list_rds_files(db$path)
  if (is.null(files)) return()

  file_choice <- ui$get_choice("Enter the number of the file you want to open: ", length(files))

  file_name <- files[file_choice]
  db$load_data(file_name)
}

# lists available .rds files in the specified directory
list_rds_files <- function(path) {
  files <- list.files(path, pattern = "\\.rds$")
  if (length(files) == 0) {
    cli::cli_alert_warning("No .rds files found in the directory.")
    return(NULL)
  } else {
    cli::cli_h2("Available .rds files:")
    cli::cli_ol(files)
    return(files)
  }
}

# manages the measures database through various operations
manage_database <- function(db, ui) {
  repeat {
    options <- c(
      "List measures",
      "Add measure",
      "Delete measure",
      "Modify measure",
      "Copy to new/existing measure",
      "Create backup measures data",
      "Batch edit measures",
      "Exit"
    )
    ui$display_menu("Measures Database Management", options)

    choice <- ui$get_choice("Enter your choice: ", length(options))

    switch(choice,
           list_measures(db),
           add_measure(db, ui),
           delete_measure(db, ui),
           modify_measure(db, ui),
           copy_measure(db, ui),
           create_backup(db, ui),
           batch_edit_measures(db, ui),
           {
             cli::cli_alert_success("Exited. Have a nice day! \U0001F600 \U0001F44D")
             break
           }
    )
  }
}


# adds initial measures to a newly created database
add_initial_measures <- function(db, ui) {
  repeat {
    new_measure <- enter_or_modify_measure(ui)
    if (is.list(new_measure) && length(new_measure) > 0) {
      review_result <- review_and_save_measure(db, ui, new_measure)
      if (!review_result) break
    } else {
      cli::cli_alert_warning("Invalid measure data. Skipping.")
    }

    continue <- tolower(ui$get_input("Would you like to enter another measure? (y/n): ")) == "y"
    if (!continue) break
  }
}

# lists available .rds files in the specified directory
list_measures <- function(db) {
  measures <- db$list_measures()
  if (length(measures) > 0) {
    cli::cli_h3("Available measures:")
    cli::cli_ol(measures)
  } else {
    cli::cli_alert_warning("No measures available.")
  }
}

# adds a new measure to the database
add_measure <- function(db, ui) {
  new_measure <- enter_or_modify_measure(ui)
  if (!is.null(new_measure) && is.list(new_measure) && length(new_measure) > 0) {
    review_and_save_measure(db, ui, new_measure, is_new = TRUE)
  } else {
    cli::cli_alert_warning("Measure creation cancelled or invalid measure data.")
  }
}

# deletes a measure from the database
delete_measure <- function(db, ui) {
  measures <- db$list_measures()
  if (length(measures) == 0) {
    cli::cli_alert_warning("No measures available to delete.")
    return()
  }

  cli::cli_h3("Available measures:")
  cli::cli_ol(measures)
  choice <- ui$get_choice("Enter the number of the measure to delete: ", length(measures))

  if (db$delete_measure(measures[choice])) {
    db$save_data()
    cli::cli_alert_success("Measure deleted and database updated.")
  } else {
    cli::cli_alert_danger("Failed to delete measure.")
  }
}

# modifies an existing measure in the database
modify_measure <- function(db, ui) {
  measures <- db$list_measures()
  if (length(measures) == 0) {
    cli::cli_alert_warning("No measures available to modify.")
    return()
  }

  cli::cli_h3("Available measures:")
  cli::cli_ol(measures)
  choice <- ui$get_choice("Enter the number of the measure to modify: ", length(measures))

  measure <- enter_or_modify_measure(ui, db$get_measure(measures[choice]))
  if (!is.null(measure)) {
    review_and_save_measure(db, ui, measure, is_new = FALSE)
  }
}

# copies an existing measure to a new or existing measure
copy_measure <- function(db, ui) {
  measures <- db$list_measures()
  if (length(measures) == 0) {
    cli::cli_alert_warning("No measures available to copy from.")
    return()
  }

  cli::cli_h3("Available measures to copy from:")
  cli::cli_ol(measures)

  from_choice <- ui$get_choice("Enter the number of the measure to copy from: ", length(measures))

  from_measure <- measures[from_choice]
  fields <- c("description", "reference", "waves", "keywords", "items")
  available_fields <- fields[fields %in% names(db$get_measure(from_measure))]

  cli::cli_h3("Available fields to copy:")
  cli::cli_ol(available_fields)

  field_choice <- ui$get_choice("Enter the number of the field to copy (0 to copy all): ", length(available_fields), allow_zero = TRUE)

  fields_to_copy <- if (field_choice == 0) available_fields else available_fields[field_choice]

  new_measure <- list()
  for (field in fields_to_copy) {
    new_measure[[field]] <- db$get_measure(from_measure)[[field]]
  }

  modified_measure <- enter_or_modify_measure(ui, new_measure)

  if (!is.null(modified_measure)) {
    if (review_and_save_measure(db, ui, modified_measure)) {
      cli::cli_alert_success("Measure created/modified successfully with copied information.")
    } else {
      cli::cli_alert_warning("Changes were not saved.")
    }
  }
}

# creates a backup of the current measures data
create_backup <- function(db, ui) {
  default_name <- gsub("^backup_", "", db$current_file %||% "measures_data.rds")
  cli::cli_h3("Save options:")
  options <- c(
    paste("Use backup file name:", paste0("backup_", default_name)),
    "Enter a new file name"
  )
  cli::cli_ol(options)
  save_choice <- ui$get_choice("Enter your choice: ", length(options))

  if (save_choice == 1) {
    file_name <- default_name
  } else if (save_choice == 2) {
    file_name <- ui$get_input("Enter new file name (including .rds extension): ")
  }

  db$save_data(file_name, backup = TRUE)
}

# performs a batch edit on measures in the database
batch_edit_measures <- function(db, ui) {
  field <- ui$get_input("Enter the field to edit (e.g., 'reference', 'name', 'description'): ")
  if (field == "__back__") return()

  old_value <- ui$get_input("Enter the old value: ")
  if (old_value == "__back__") return()

  new_value <- ui$get_input("Enter the new value: ")
  if (new_value == "__back__") return()

  edited_count <- db$batch_edit_measures(field, old_value, new_value)
  db$save_data()
  cli::cli_alert_success("Batch edit completed. {edited_count} entries updated and database saved.")
}

# enters or modifies a measure based on user input
enter_or_modify_measure <- function(ui, existing_measure = NULL) {
  measure <- existing_measure %||% list()
  fields <- c("name", "items", "description", "reference", "waves", "keywords")

  for (field in fields) {
    current_value <- measure[[field]]

    if (field == "name") {
      cli::cli_text(cli::col_grey("Example: alcohol_frequency"))
      cli::cli_text("Current value: {.val {if (is.null(current_value)) 'None' else current_value}}")
      new_value <- ui$get_input(
        cli::col_blue("Enter new name (press enter to keep current): "),
        allow_empty = TRUE
      )
      if (new_value != "") {
        measure[[field]] <- new_value
      }
    } else if (field == "items") {
      if (!is.null(current_value)) {
        cli::cli_h3("Current items:")
        cli::cli_ol(current_value)
        modify <- tolower(ui$get_input("Do you want to modify the items? (y/n): ")) == "y"
        if (modify) {
          measure[[field]] <- list()
          cli::cli_h3("Enter new items (press Enter without typing anything to finish):")
          item_num <- 1
          repeat {
            item <- ui$get_input(cli::col_blue(paste("Item", item_num, "(or press enter to finish): ")), allow_empty = TRUE)
            if (item == "") break
            measure[[field]][[item_num]] <- item
            item_num <- item_num + 1
          }
        }
      } else {
        measure[[field]] <- list()
        cli::cli_h3("Enter items (press Enter without typing anything to finish):")
        cli::cli_text("Example: How often do you have a drink containing alcohol?")
        item_num <- 1
        repeat {
          item <- ui$get_input(cli::col_blue(paste("Item", item_num, "(or press enter to finish): ")), allow_empty = TRUE)
          if (item == "") break
          measure[[field]][[item_num]] <- item
          item_num <- item_num + 1
        }
      }
    } else if (field == "description") {
      cli::cli_text(cli::col_grey("Example: Frequency of alcohol consumption was measured using a single item..."))
      cli::cli_text("Current value: {.val {if (is.null(current_value)) 'None' else current_value}}")
      modify <- tolower(ui$get_input("Do you want to modify the description? (y/n): ")) == "y"
      if (modify) {
        new_value <- ui$get_input(
          cli::col_blue("Enter new description: "),
          allow_empty = FALSE,
          multiline = TRUE
        )
        measure[[field]] <- new_value
      }
    } else {
      example <- switch(
        field,
        reference = "Example: [@nzavs2009]",
        waves = "Example: 1-current or 1-15",
        keywords = 'Example: alcohol, frequency, consumption (optional, press enter to skip)'
      )
      cli::cli_text(cli::col_grey(example))
      cli::cli_text("Current value: {.val {if (is.null(current_value)) 'None' else paste(current_value, collapse = ', ')}}")

      new_value <- ui$get_input(
        cli::col_blue(paste("Enter new", field, "(press enter to keep current): ")),
        allow_empty = TRUE
      )

      if (new_value != "") {
        if (field == "keywords") {
          keywords <- strsplit(new_value, ",")[[1]]
          keywords <- sapply(keywords, trimws)
          measure[[field]] <- keywords
        } else {
          measure[[field]] <- new_value
        }
      }
    }
  }

  return(measure)
}

# reviews and saves the measure to the database
review_and_save_measure <- function(db, ui, measure, is_new = TRUE) {
  while (TRUE) {
    cli::cli_h2("Review your entries:")
    print(measure)
    cli::cli_h3("What would you like to do?")
    options <- c(
      "Save measure",
      "Modify measure",
      "Start over",
      "Cancel"
    )
    ui$display_menu("Options", options)

    choice <- ui$get_choice("Enter your choice: ", length(options))

    if (choice == 1) {
      db$add_measure(measure)
      if (db$save_data()) {
        cli::cli_alert_success("Measure {.val {measure$name}} saved successfully.")
        return(TRUE)
      } else {
        cli::cli_alert_danger("Failed to save measure to database.")
        return(FALSE)
      }
    } else if (choice == 2) {
      measure <- enter_or_modify_measure(ui, measure)
    } else if (choice == 3) {
      measure <- enter_or_modify_measure(ui)
    } else if (choice == 4) {
      return(FALSE)
    }
  }
}
