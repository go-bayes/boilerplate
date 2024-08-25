# object orient approach tba

# boilerplate_manage_entries <- function(entries_path = NULL, entry_type = "measure") {
#   require(rlang)
#   require(here)
#   require(cli)
#   require(R6)
#
#   entries_path <- entries_path %||% here::here()
#   db <- EntryDatabase$new(entries_path, entry_type)
#   ui <- UserInterface$new()
#
#   run_gui(db, ui, entry_type)
# }
#
# library(R6)
# library(cli)
# library(stringr)

# # UserInterface class definition
# UserInterface <- R6::R6Class("UserInterface",
#                              public = list(
#                                get_input = function(prompt, allow_empty = FALSE, multiline = FALSE) {
#                                  if (multiline) {
#                                    return(self$get_multiline_input(prompt))
#                                  }
#
#                                  while (TRUE) {
#                                    input <- trimws(readline(cli::col_cyan(prompt)))
#                                    if (input != "" || allow_empty)
#                                      return(input)
#                                    cli::cli_alert_danger("Input cannot be empty. Please try again.")
#                                  }
#                                },
#
#                                get_multiline_input = function(prompt) {
#                                  cli::cli_text(cli::col_cyan(prompt))
#                                  cli::cli_text(cli::col_cyan("Enter your text (press Enter twice on an empty line to finish):"))
#                                  lines <- character()
#                                  empty_line_count <- 0
#                                  repeat {
#                                    line <- readline()
#                                    if (line == "") {
#                                      empty_line_count <- empty_line_count + 1
#                                      if (empty_line_count == 2) {
#                                        break
#                                      }
#                                    } else {
#                                      empty_line_count <- 0
#                                    }
#                                    lines <- c(lines, line)
#                                  }
#                                  paste(lines, collapse = "\n")
#                                },
#
#                                display_menu = function(title, options) {
#                                  cli::cli_h2(title)
#                                  cli::cli_ol(options)
#                                },
#
#                                get_choice = function(prompt, max_choice, allow_zero = FALSE) {
#                                  while (TRUE) {
#                                    choice <- as.integer(self$get_input(prompt))
#                                    if (!is.na(choice) &&
#                                        ((allow_zero && choice >= 0 && choice <= max_choice) ||
#                                         (!allow_zero && choice >= 1 && choice <= max_choice))) {
#                                      return(choice)
#                                    }
#                                    if (allow_zero) {
#                                      cli::cli_alert_danger("Invalid choice. Please enter a number between 0 and {max_choice}.")
#                                    } else {
#                                      cli::cli_alert_danger("Invalid choice. Please enter a number between 1 and {max_choice}.")
#                                    }
#                                  }
#                                }
#                              )
# )
#
# # Main function
# boilerplate_manage_entries <- function(entries_path = NULL, entry_type = "measure") {
#   require(rlang)
#   require(here)
#   require(cli)
#   require(stringr)
#
#   entries_path <- entries_path %||% here::here()
#   db <- EntryDatabase$new(entries_path, entry_type)
#   ui <- UserInterface$new()
#
#   run_gui(db, ui, entry_type)
# }
#
#
#
# EntryDatabase <- R6::R6Class("EntryDatabase",
#                              public = list(
#                                path = NULL,
#                                current_file = NULL,
#                                data = NULL,
#                                entry_type = NULL,
#
#                                initialize = function(path, entry_type) {
#                                  self$path <- path
#                                  self$entry_type <- entry_type
#                                  self$data <- list()
#                                },
#
#                                load_data = function(file_name) {
#                                  file_path <- file.path(self$path, file_name)
#                                  if (file.exists(file_path)) {
#                                    self$data <- readRDS(file_path)
#                                    self$current_file <- file_name
#                                    cli::cli_alert_success("{self$entry_type} data loaded from: {.file {file_path}}")
#                                    return(TRUE)
#                                  } else {
#                                    cli::cli_alert_danger("File not found: {.file {file_path}}")
#                                    return(FALSE)
#                                  }
#                                },
#
#                                save_data = function(file_name = NULL, backup = FALSE) {
#                                  file_name <- file_name %||% self$current_file
#                                  if (is.null(file_name)) {
#                                    cli::cli_alert_danger("No file name specified.")
#                                    return(FALSE)
#                                  }
#
#                                  tryCatch({
#                                    file_path <- file.path(self$path, file_name)
#                                    saveRDS(self$data, file = file_path)
#                                    cli::cli_alert_success("{self$entry_type} data saved as: {.file {file_path}}")
#
#                                    if (backup) {
#                                      backup_file <- paste0("backup_", file_name)
#                                      backup_path <- file.path(self$path, backup_file)
#                                      saveRDS(self$data, file = backup_path)
#                                      cli::cli_alert_success("Backup saved as: {.file {backup_path}}")
#                                    }
#                                    self$current_file <- file_name
#                                    return(TRUE)
#                                  }, error = function(e) {
#                                    cli::cli_alert_danger("Error saving data: {e$message}")
#                                    return(FALSE)
#                                  })
#                                },
#
#                                list_entries = function() {
#                                  return(names(self$data))
#                                },
#
#                                add_entry = function(entry) {
#                                  self$data[[entry$name]] <- entry
#                                  self$data <- self$data[order(names(self$data))]
#                                },
#
#                                delete_entry = function(name) {
#                                  if (name %in% names(self$data)) {
#                                    self$data[[name]] <- NULL
#                                    self$data <- self$data[order(names(self$data))]
#                                    return(TRUE)
#                                  }
#                                  return(FALSE)
#                                },
#
#                                get_entry = function(name) {
#                                  return(self$data[[name]])
#                                },
#
#                                batch_edit_entries = function(field, old_value, new_value) {
#                                  edited_count <- 0
#                                  for (entry_name in names(self$data)) {
#                                    entry <- self$data[[entry_name]]
#                                    if (field %in% names(entry)) {
#                                      if (is.character(entry[[field]])) {
#                                        if (entry[[field]] == old_value) {
#                                          self$data[[entry_name]][[field]] <- new_value
#                                          edited_count <- edited_count + 1
#                                        }
#                                      } else if (is.list(entry[[field]])) {
#                                        for (i in seq_along(entry[[field]])) {
#                                          if (entry[[field]][[i]] == old_value) {
#                                            self$data[[entry_name]][[field]][[i]] <- new_value
#                                            edited_count <- edited_count + 1
#                                          }
#                                        }
#                                      }
#                                    }
#                                  }
#                                  return(edited_count)
#                                }
#                              )
# )
#
# Entry <- R6::R6Class("Entry",
#                      public = list(
#                        name = NULL,
#                        description = NULL,
#
#                        initialize = function(name = NULL, description = NULL) {
#                          self$name <- name
#                          self$description <- description
#                        },
#
#                        print = function() {
#                          cat("Name:", self$name, "\n")
#                          cat("Description:", self$description, "\n")
#                        }
#                      )
# )
#
# # Measure Entry class
# MeasureEntry <- R6::R6Class("MeasureEntry",
#                             inherit = Entry,
#                             public = list(
#                               items = NULL,
#                               reference = NULL,
#                               waves = NULL,
#                               keywords = NULL,
#
#                               initialize = function(name = NULL, description = NULL, items = NULL, reference = NULL, waves = NULL, keywords = NULL) {
#                                 super$initialize(name, description)
#                                 self$items <- items %||% list()
#                                 self$reference <- reference %||% ""
#                                 self$waves <- waves %||% ""
#                                 self$keywords <- keywords %||% character(0)
#                               },
#
#                               print = function() {
#                                 super$print()
#                                 cat("Items:\n")
#                                 if (length(self$items) > 0) {
#                                   for (i in seq_along(self$items)) {
#                                     cat("  ", i, ". ", self$items[[i]], "\n", sep = "")
#                                   }
#                                 } else {
#                                   cat("  No items\n")
#                                 }
#                                 cat("Reference:", self$reference, "\n")
#                                 cat("Waves:", self$waves, "\n")
#                                 cat("Keywords:", paste(self$keywords, collapse = ", "), "\n")
#                               }
#                             )
# )
# # EntryDatabase class
# EntryDatabase <- R6::R6Class("EntryDatabase",
#                              public = list(
#                                path = NULL,
#                                current_file = NULL,
#                                data = NULL,
#                                entry_type = NULL,
#
#                                initialize = function(path, entry_type) {
#                                  self$path <- path
#                                  self$entry_type <- entry_type
#                                  self$data <- list()
#                                },
#
#                                load_data = function(file_name) {
#                                  file_path <- file.path(self$path, file_name)
#                                  if (file.exists(file_path)) {
#                                    self$data <- readRDS(file_path)
#                                    self$current_file <- file_name
#                                    cli::cli_alert_success("{self$entry_type} data loaded from: {.file {file_path}}")
#                                    return(TRUE)
#                                  } else {
#                                    cli::cli_alert_danger("File not found: {.file {file_path}}")
#                                    return(FALSE)
#                                  }
#                                },
#
#                                save_data = function(file_name = NULL, backup = FALSE) {
#                                  file_name <- file_name %||% self$current_file
#                                  if (is.null(file_name)) {
#                                    cli::cli_alert_danger("No file name specified.")
#                                    return(FALSE)
#                                  }
#
#                                  tryCatch({
#                                    file_path <- file.path(self$path, file_name)
#                                    saveRDS(self$data, file = file_path)
#                                    cli::cli_alert_success("{self$entry_type} data saved as: {.file {file_path}}")
#
#                                    if (backup) {
#                                      backup_file <- paste0("backup_", file_name)
#                                      backup_path <- file.path(self$path, backup_file)
#                                      saveRDS(self$data, file = backup_path)
#                                      cli::cli_alert_success("Backup saved as: {.file {backup_path}}")
#                                    }
#                                    self$current_file <- file_name
#                                    return(TRUE)
#                                  }, error = function(e) {
#                                    cli::cli_alert_danger("Error saving data: {e$message}")
#                                    return(FALSE)
#                                  })
#                                },
#
#                                list_entries = function() {
#                                  return(names(self$data))
#                                },
#
#                                add_entry = function(entry) {
#                                  self$data[[entry$name]] <- entry
#                                  self$data <- self$data[order(names(self$data))]
#                                },
#
#                                delete_entry = function(name) {
#                                  if (name %in% names(self$data)) {
#                                    self$data[[name]] <- NULL
#                                    self$data <- self$data[order(names(self$data))]
#                                    return(TRUE)
#                                  }
#                                  return(FALSE)
#                                },
#
#                                get_entry = function(name) {
#                                  return(self$data[[name]])
#                                },
#
#                                batch_edit_entries = function(field, old_value, new_value) {
#                                  edited_count <- 0
#                                  for (entry_name in names(self$data)) {
#                                    entry <- self$data[[entry_name]]
#                                    if (field %in% names(entry)) {
#                                      if (is.character(entry[[field]])) {
#                                        if (entry[[field]] == old_value) {
#                                          self$data[[entry_name]][[field]] <- new_value
#                                          edited_count <- edited_count + 1
#                                        }
#                                      } else if (is.list(entry[[field]])) {
#                                        for (i in seq_along(entry[[field]])) {
#                                          if (entry[[field]][[i]] == old_value) {
#                                            self$data[[entry_name]][[field]][[i]] <- new_value
#                                            edited_count <- edited_count + 1
#                                          }
#                                        }
#                                      }
#                                    }
#                                  }
#                                  return(edited_count)
#                                }
#                              )
# )
#
#
# run_gui <- function(db, ui, entry_type) {
#   cli::cli_h1("Welcome to the Boilerplate {str_to_title(entry_type)} Database Manager")
#
#   repeat {
#     options <- c(
#       paste("Create new", entry_type, "database"),
#       paste("Open existing", entry_type, "database"),
#       "List available .rds files",
#       "Quit"
#     )
#     ui$display_menu(paste("Boilerplate", str_to_title(entry_type), "Manager"), options)
#
#     choice <- ui$get_choice("Enter your choice: ", length(options))
#
#     if (choice == 1) {
#       create_new_database(db, ui, entry_type)
#     } else if (choice == 2) {
#       open_existing_database(db, ui)
#     } else if (choice == 3) {
#       list_rds_files(db$path)
#     } else if (choice == 4) {
#       confirm_quit <- tolower(ui$get_input("Are you sure you want to quit? Unsaved changes will be lost. (y/n): "))
#       if (confirm_quit == "y") {
#         cli::cli_alert_success("Exiting program. Goodbye!")
#         return()
#       }
#     }
#
#     if (choice == 1 || choice == 2) break
#   }
#
#   manage_database(db, ui, entry_type)
# }
#
# create_new_database <- function(db, ui, entry_type) {
#   cli::cli_h2(paste("Creating a new", entry_type, "database"))
#
#   db_name <- ui$get_input(paste("Enter a name for the new", entry_type, "database (without .rds extension): "))
#   if (!grepl("\\.rds$", db_name)) {
#     db_name <- paste0(db_name, ".rds")
#   }
#
#   full_path <- file.path(db$path, db_name)
#   cli::cli_alert_info("The database will be created at: {.file {full_path}}")
#   confirm <- tolower(ui$get_input("Is this correct? (y/n): "))
#
#   if (confirm == "y") {
#     db$data <- list()
#     if (db$save_data(db_name)) {
#       cli::cli_alert_success("New {entry_type} database '{.file {db_name}}' created.")
#       add_initial_entries(db, ui, entry_type)
#       return(TRUE)
#     } else {
#       cli::cli_alert_danger("Failed to create new database.")
#       return(FALSE)
#     }
#   } else {
#     cli::cli_alert_warning("Database creation cancelled.")
#     return(FALSE)
#   }
# }
#
# list_rds_files <- function(path) {
#   files <- list.files(path, pattern = "\\.rds$")
#   if (length(files) == 0) {
#     cli::cli_alert_warning("No .rds files found in the directory.")
#     return(NULL)
#   } else {
#     cli::cli_h2("Available .rds files:")
#     cli::cli_ol(files)
#     return(files)
#   }
# }
#
#
# create_new_database <- function(db, ui, entry_type) {
#   cli::cli_h2(paste("Creating a new", entry_type, "database"))
#
#   db_name <- ui$get_input(paste("Enter a name for the new", entry_type, "database (without .rds extension): "))
#   if (!grepl("\\.rds$", db_name)) {
#     db_name <- paste0(db_name, ".rds")
#   }
#
#   full_path <- file.path(db$path, db_name)
#   cli::cli_alert_info("The database will be created at: {.file {full_path}}")
#   confirm <- tolower(ui$get_input("Is this correct? (y/n): "))
#
#   if (confirm == "y") {
#     db$data <- list()
#     if (db$save_data(db_name)) {
#       cli::cli_alert_success("New {entry_type} database '{.file {db_name}}' created.")
#       add_initial_entries(db, ui, entry_type)
#       return(TRUE)
#     } else {
#       cli::cli_alert_danger("Failed to create new database.")
#       return(FALSE)
#     }
#   } else {
#     cli::cli_alert_warning("Database creation cancelled.")
#     return(FALSE)
#   }
# }
#
# manage_database <- function(db, ui, entry_type) {
#   repeat {
#     options <- c(
#       paste("List", entry_type, "entries"),
#       paste("Add", entry_type, "entry"),
#       paste("Delete", entry_type, "entry"),
#       paste("Modify", entry_type, "entry"),
#       paste("Copy to new/existing", entry_type, "entry"),
#       paste("Create backup", entry_type, "data"),
#       paste("Batch edit", entry_type, "entries"),
#       "Exit"
#     )
#     ui$display_menu(paste(str_to_title(entry_type), "Database Management"), options)
#
#     choice <- ui$get_choice("Enter your choice: ", length(options))
#
#     switch(choice,
#            list_entries(db),
#            add_entry(db, ui, entry_type),
#            delete_entry(db, ui),
#            modify_entry(db, ui, entry_type),
#            copy_entry(db, ui, entry_type),
#            create_backup(db, ui),
#            batch_edit_entries(db, ui),
#            {
#              cli::cli_alert_success("Exited. Have a nice day! \U0001F600 \U0001F44D")
#              break
#            }
#     )
#   }
# }
#
# add_initial_entries <- function(db, ui, entry_type) {
#   repeat {
#     new_entry <- enter_or_modify_entry(ui, entry_type = entry_type)
#     if (!is.null(new_entry)) {
#       review_result <- review_and_save_entry(db, ui, new_entry, entry_type)
#       if (!review_result) break
#     } else {
#       cli::cli_alert_warning("Invalid entry data. Skipping.")
#     }
#
#     continue <- tolower(ui$get_input(paste("Would you like to enter another", entry_type, "entry? (y/n): "))) == "y"
#     if (!continue) break
#   }
# }
#
# list_entries <- function(db) {
#   entries <- db$list_entries()
#   if (length(entries) > 0) {
#     cli::cli_h3(paste("Available", db$entry_type, "entries:"))
#     cli::cli_ol(entries)
#   } else {
#     cli::cli_alert_warning(paste("No", db$entry_type, "entries available."))
#   }
# }
#
# add_entry <- function(db, ui, entry_type) {
#   new_entry <- enter_or_modify_entry(ui, entry_type = entry_type)
#   if (!is.null(new_entry)) {
#     review_and_save_entry(db, ui, new_entry, entry_type, is_new = TRUE)
#   } else {
#     cli::cli_alert_warning(paste(str_to_title(entry_type), "entry creation cancelled or invalid entry data."))
#   }
# }
#
# delete_entry <- function(db, ui) {
#   entries <- db$list_entries()
#   if (length(entries) == 0) {
#     cli::cli_alert_warning(paste("No", db$entry_type, "entries available to delete."))
#     return()
#   }
#
#   cli::cli_h3(paste("Available", db$entry_type, "entries:"))
#   cli::cli_ol(entries)
#   choice <- ui$get_choice("Enter the number of the entry to delete: ", length(entries))
#
#   if (db$delete_entry(entries[choice])) {
#     db$save_data()
#     cli::cli_alert_success(paste(str_to_title(db$entry_type), "entry deleted and database updated."))
#   } else {
#     cli::cli_alert_danger(paste("Failed to delete", db$entry_type, "entry."))
#   }
# }
#
# modify_entry <- function(db, ui, entry_type) {
#   entries <- db$list_entries()
#   if (length(entries) == 0) {
#     cli::cli_alert_warning(paste("No", entry_type, "entries available to modify."))
#     return()
#   }
#
#   cli::cli_h3(paste("Available", entry_type, "entries:"))
#   cli::cli_ol(entries)
#   choice <- ui$get_choice("Enter the number of the entry to modify: ", length(entries))
#
#   entry <- enter_or_modify_entry(ui, db$get_entry(entries[choice]), entry_type)
#   if (!is.null(entry)) {
#     review_and_save_entry(db, ui, entry, entry_type, is_new = FALSE)
#   }
# }
#
# copy_entry <- function(db, ui, entry_type) {
#   entries <- db$list_entries()
#   if (length(entries) == 0) {
#     cli::cli_alert_warning(paste("No", entry_type, "entries available to copy from."))
#     return()
#   }
#
#   cli::cli_h3(paste("Available", entry_type, "entries to copy from:"))
#   cli::cli_ol(entries)
#
#   from_choice <- ui$get_choice("Enter the number of the entry to copy from: ", length(entries))
#
#   from_entry <- entries[from_choice]
#   fields <- names(db$get_entry(from_entry))
#
#   cli::cli_h3("Available fields to copy:")
#   cli::cli_ol(fields)
#
#   field_choice <- ui$get_choice("Enter the number of the field to copy (0 to copy all): ", length(fields), allow_zero = TRUE)
#
#   fields_to_copy <- if (field_choice == 0) fields else fields[field_choice]
#
#   new_entry <- list()
#   for (field in fields_to_copy) {
#     new_entry[[field]] <- db$get_entry(from_entry)[[field]]
#   }
#
#   modified_entry <- enter_or_modify_entry(ui, new_entry, entry_type)
#
#   if (!is.null(modified_entry)) {
#     if (review_and_save_entry(db, ui, modified_entry, entry_type)) {
#       cli::cli_alert_success(paste(str_to_title(entry_type), "entry created/modified successfully with copied information."))
#     } else {
#       cli::cli_alert_warning("Changes were not saved.")
#     }
#   }
# }
#
# batch_edit_entries <- function(db, ui) {
#   field <- ui$get_input("Enter the field to edit: ")
#   if (field == "__back__") return()
#
#   old_value <- ui$get_input("Enter the old value: ")
#   if (old_value == "__back__") return()
#
#   new_value <- ui$get_input("Enter the new value: ")
#   if (new_value == "__back__") return()
#
#   edited_count <- db$batch_edit_entries(field, old_value, new_value)
#   db$save_data()
#   cli::cli_alert_success("Batch edit completed. {edited_count} entries updated and database saved.")
# }
#
# enter_or_modify_entry <- function(ui, existing_entry = NULL, entry_type = "measure") {
#   entry <- existing_entry %||% switch(entry_type,
#                                       "measure" = MeasureEntry$new(),
#                                       Entry$new())
#
#   fields <- names(entry)
#
#   for (field in fields) {
#     current_value <- entry[[field]]
#
#     if (field == "name") {
#       cli::cli_text(cli::col_grey("Example: alcohol_frequency"))
#       cli::cli_text("Current value: {.val {if (is.null(current_value)) 'None' else current_value}}")
#       new_value <- ui$get_input(
#         cli::col_blue("Enter new name (press enter to keep current): "),
#         allow_empty = TRUE
#       )
#       if (new_value != "") {
#         entry$name <- new_value
#       }
#     } else if (field == "items" && inherits(entry, "MeasureEntry")) {
#       if (!is.null(current_value) && length(current_value) > 0) {
#         cli::cli_h3("Current items:")
#         cli::cli_ol(current_value)
#         modify <- tolower(ui$get_input("Do you want to modify the items? (y/n): ")) == "y"
#         if (modify) {
#           entry$items <- list()
#           cli::cli_h3("Enter new items (press Enter without typing anything to finish):")
#           item_num <- 1
#           repeat {
#             item <- ui$get_input(cli::col_blue(paste("Item", item_num, "(or press enter to finish): ")), allow_empty = TRUE)
#             if (item == "") break
#             entry$items[[item_num]] <- item
#             item_num <- item_num + 1
#           }
#         }
#       } else {
#         entry$items <- list()
#         cli::cli_h3("Enter items (press Enter without typing anything to finish):")
#         cli::cli_text("Example: How often do you have a drink containing alcohol?")
#         item_num <- 1
#         repeat {
#           item <- ui$get_input(cli::col_blue(paste("Item", item_num, "(or press enter to finish): ")), allow_empty = TRUE)
#           if (item == "") break
#           entry$items[[item_num]] <- item
#           item_num <- item_num + 1
#         }
#       }
#     } else {
#       current_value_str <- if (is.null(current_value)) {
#         "None"
#       } else if (is.list(current_value)) {
#         paste(unlist(current_value), collapse = ", ")
#       } else if (is.vector(current_value) && length(current_value) > 1) {
#         paste(current_value, collapse = ", ")
#       } else {
#         as.character(current_value)
#       }
#
#       example <- switch(
#         field,
#         reference = "Example: [@nzavs2009]",
#         waves = "Example: 1-current or 1-15",
#         keywords = 'Example: alcohol, frequency, consumption (optional, press enter to skip)',
#         description = "Example: Frequency of alcohol consumption was measured using a single item...",
#         ""
#       )
#       if (example != "") cli::cli_text(cli::col_grey(example))
#       cli::cli_text("Current value: {.val {current_value_str}}")
#
#       new_value <- ui$get_input(
#         cli::col_blue(paste("Enter new", field, "(press enter to keep current): ")),
#         allow_empty = TRUE
#       )
#
#       if (new_value != "") {
#         if (field == "keywords") {
#           keywords <- strsplit(new_value, ",")[[1]]
#           keywords <- sapply(keywords, trimws)
#           entry$keywords <- keywords
#         } else {
#           entry[[field]] <- new_value
#         }
#       }
#     }
#   }
#
#   return(entry)
# }
#
#
# review_and_save_entry <- function(db, ui, entry, entry_type, is_new = TRUE) {
#   while (TRUE) {
#     cli::cli_h2("Review your entries:")
#     entry$print()
#     cli::cli_h3("What would you like to do?")
#     options <- c(
#       paste("Save", entry_type, "entry"),
#       paste("Modify", entry_type, "entry"),
#       "Start over",
#       "Cancel"
#     )
#     ui$display_menu("Options", options)
#
#     choice <- ui$get_choice("Enter your choice: ", length(options))
#
#     if (choice == 1) {
#       db$add_entry(entry)
#       if (db$save_data()) {
#         cli::cli_alert_success("{str_to_title(entry_type)} entry {.val {entry$name}} saved successfully.")
#         return(TRUE)
#       } else {
#         cli::cli_alert_danger("Failed to save {entry_type} entry to database.")
#         return(FALSE)
#       }
#     } else if (choice == 2) {
#       entry <- enter_or_modify_entry(ui, entry, entry_type)
#     } else if (choice == 3) {
#       entry <- enter_or_modify_entry(ui, entry_type = entry_type)
#     } else if (choice == 4) {
#       return(FALSE)
#     }
#   }
# }
