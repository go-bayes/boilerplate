# Database structure (using R environment for simplicity)
boilerplate_db <- new.env()

#' Initialize Boilerplate Database
#'
#' @param default_path Path to load default values from
#' @export
initialize_boilerplate_db <- function(default_path = NULL) {
  if (!is.null(default_path) && file.exists(default_path)) {
    boilerplate_db <- readRDS(default_path)
  } else {
    # Initialize with default sections
    sections <- c("sample", "variables", "causal_interventions", "identification_assumptions",
                  "target_population", "eligibility_criteria", "confounding_control",
                  "missing_data", "statistical_estimator", "additional_sections")
    for (section in sections) {
      boilerplate_db[[section]] <- list(content = "", options = list())
    }
  }
}

#' Manage Boilerplate Database
#'
#' @export
manage_boilerplate_db <- function() {
  repeat {
    cat("\nBoilerplate Database Manager\n")
    cat("1. View/Edit Section\n")
    cat("2. Add New Section\n")
    cat("3. Delete Section\n")
    cat("4. Backup Database\n")
    cat("5. Exit\n")

    choice <- as.integer(readline("Enter your choice: "))

    switch(choice,
           view_edit_section(),
           add_new_section(),
           delete_section(),
           backup_database(),
           {
             cat("Exiting Database Manager\n")
             break
           }
    )
  }
}

view_edit_section <- function() {
  sections <- names(boilerplate_db)
  cat("Available sections:\n")
  for (i in seq_along(sections)) {
    cat(i, ". ", sections[i], "\n", sep = "")
  }

  choice <- as.integer(readline("Enter section number to view/edit (0 to cancel): "))
  if (choice == 0 || choice > length(sections)) return()

  section <- sections[choice]
  cat("\nCurrent content for", section, ":\n")
  print(boilerplate_db[[section]]$content)

  edit <- tolower(readline("Do you want to edit this section? (y/n): "))
  if (edit == "y") {
    new_content <- readline_multiline("Enter new content (press Enter twice to finish):\n")
    boilerplate_db[[section]]$content <- new_content

    # Edit options
    edit_options <- tolower(readline("Do you want to edit options for this section? (y/n): "))
    if (edit_options == "y") {
      options <- list()
      repeat {
        key <- readline("Enter option key (or press Enter to finish): ")
        if (key == "") break
        value <- readline("Enter option value: ")
        options[[key]] <- value
      }
      boilerplate_db[[section]]$options <- options
    }

    cat("Section updated.\n")
  }
}

add_new_section <- function() {
  section_name <- readline("Enter new section name: ")
  content <- readline_multiline("Enter section content (press Enter twice to finish):\n")
  boilerplate_db[[section_name]] <- list(content = content, options = list())
  cat("New section added.\n")
}

delete_section <- function() {
  sections <- names(boilerplate_db)
  cat("Available sections:\n")
  for (i in seq_along(sections)) {
    cat(i, ". ", sections[i], "\n", sep = "")
  }

  choice <- as.integer(readline("Enter section number to delete (0 to cancel): "))
  if (choice == 0 || choice > length(sections)) return()

  section <- sections[choice]
  confirm <- tolower(readline(paste("Are you sure you want to delete", section, "? (y/n): ")))
  if (confirm == "y") {
    rm(list = section, envir = boilerplate_db)
    cat("Section deleted.\n")
  }
}

backup_database <- function() {
  backup_path <- readline("Enter backup file path (including filename): ")
  saveRDS(boilerplate_db, file = backup_path)
  cat("Database backed up to", backup_path, "\n")
}

readline_multiline <- function(prompt) {
  cat(prompt)
  lines <- character()
  repeat {
    line <- readline()
    if (line == "") break
    lines <- c(lines, line)
  }
  paste(lines, collapse = "\n")
}

#' Generate Boilerplate Report
#'
#' @param sections Character vector of section names to include
#' @param variables List of variables to replace in the text
#' @export
generate_boilerplate_report <- function(sections = names(boilerplate_db), variables = list()) {
  report <- character()

  for (section in sections) {
    if (section %in% names(boilerplate_db)) {
      content <- boilerplate_db[[section]]$content
      options <- boilerplate_db[[section]]$options

      # Replace variables in content
      for (var_name in names(variables)) {
        content <- gsub(paste0("{{", var_name, "}}"), variables[[var_name]], content, fixed = TRUE)
      }

      # Apply section-specific function if it exists
      section_func_name <- paste0("boilerplate_report_", section)
      if (exists(section_func_name, mode = "function")) {
        section_func <- get(section_func_name, mode = "function")
        content <- do.call(section_func, c(list(content = content), options, variables))
      }

      report <- c(report, content, "")
    } else {
      warning(paste("Section", section, "not found in database."))
    }
  }

  paste(report, collapse = "\n")
}

# Example usage:
# initialize_boilerplate_db()
# manage_boilerplate_db()
# report <- generate_boilerplate_report(
#   variables = list(exposure_var = "political_conservative",
#                    baseline_wave = "NZAVS time 10, years 2018-2019",
#                    n_total = 47000)
# )
# cat(report)





# extensions --------------------------------------------------------------

# Extend the boilerplate database to include measures
boilerplate_db <- new.env()
boilerplate_db$measures <- new.env()

#' Initialize Boilerplate Database
#'
#' @param default_path Path to load default values from
#' @param measures_path Path to load measures data from
#' @export
initialize_boilerplate_db <- function(default_path = NULL, measures_path = NULL) {
  if (!is.null(default_path) && file.exists(default_path)) {
    boilerplate_db <- readRDS(default_path)
  } else {
    # Initialize with default sections
    sections <- c("sample", "variables", "causal_interventions", "identification_assumptions",
                  "target_population", "eligibility_criteria", "confounding_control",
                  "missing_data", "statistical_estimator", "additional_sections")
    for (section in sections) {
      boilerplate_db[[section]] <- list(content = "", options = list())
    }
  }

  if (!is.null(measures_path) && file.exists(measures_path)) {
    boilerplate_db$measures <- readRDS(measures_path)
  } else {
    boilerplate_db$measures <- new.env()
  }
}

#' Manage Boilerplate Database
#'
#' @export
manage_boilerplate_db <- function() {
  repeat {
    cat("\nBoilerplate Database Manager\n")
    cat("1. View/Edit Section\n")
    cat("2. Add New Section\n")
    cat("3. Delete Section\n")
    cat("4. Manage Measures\n")
    cat("5. Backup Database\n")
    cat("6. Exit\n")

    choice <- as.integer(readline("Enter your choice: "))

    switch(choice,
           view_edit_section(),
           add_new_section(),
           delete_section(),
           manage_measures(),
           backup_database(),
           {
             cat("Exiting Database Manager\n")
             break
           }
    )
  }
}

#' Manage Measures
#'
#' @export
manage_measures <- function() {
  # This function will integrate with your existing boilerplate_manage_measures() function
  measures_path <- file.path(here::here(), "data")
  boilerplate_manage_measures(measures_path)

  # After managing measures, update the boilerplate_db$measures
  measures_file <- list.files(measures_path, pattern = "\\.rds$")[1]
  if (!is.null(measures_file)) {
    boilerplate_db$measures <- readRDS(file.path(measures_path, measures_file))
  }
}

#' Generate Boilerplate Report
#'
#' @param sections Character vector of section names to include
#' @param variables List of variables to replace in the text
#' @export
generate_boilerplate_report <- function(sections = names(boilerplate_db), variables = list()) {
  report <- character()

  for (section in sections) {
    if (section %in% names(boilerplate_db)) {
      content <- boilerplate_db[[section]]$content
      options <- boilerplate_db[[section]]$options

      # Replace variables in content
      for (var_name in names(variables)) {
        content <- gsub(paste0("{{", var_name, "}}"), variables[[var_name]], content, fixed = TRUE)
      }

      # Apply section-specific function if it exists
      section_func_name <- paste0("boilerplate_report_", section)
      if (exists(section_func_name, mode = "function")) {
        section_func <- get(section_func_name, mode = "function")

        # Special handling for 'variables' section
        if (section == "variables") {
          content <- do.call(section_func, c(list(measure_data = boilerplate_db$measures), options, variables))
        } else {
          content <- do.call(section_func, c(list(content = content), options, variables))
        }
      }

      report <- c(report, content, "")
    } else {
      warning(paste("Section", section, "not found in database."))
    }
  }

  paste(report, collapse = "\n")
}

# Modified boilerplate_report_variables function
#' Generate Variables Section for Methods
#'
#' @param measure_data A list containing information about each measure.
#' @param content Optional custom content for the variables section.
#' @param exposure_var A character string specifying the name of the exposure variable.
#' @param outcome_vars A named list of character vectors specifying the outcome variables by domain.
#' @param appendices_measures An optional character string for the appendix reference.
#' @param ... Additional arguments.
#'
#' @export
boilerplate_report_variables <- function(measure_data, content = NULL, exposure_var, outcome_vars, appendices_measures = NULL, ...) {
  if (!is.null(content) && content != "") {
    # Use custom content if provided
    return(content)
  }

  # Use the existing implementation if no custom content is provided
  # Generate the bibliography
  bibliography_text <- boilerplate_report_measures(
    all_vars = c(exposure_var, unlist(outcome_vars)),
    exposure_var = exposure_var,
    outcome_vars = unlist(outcome_vars),
    measure_data = measure_data,
    print_keywords = FALSE,
    print_waves = FALSE
  )

  # Create sections for each domain
  domain_sections <- lapply(names(outcome_vars), function(domain) {
    domain_vars <- outcome_vars[[domain]]
    domain_title <- tools::toTitleCase(gsub("_", " ", domain))
    domain_text <- paste0("### ", domain_title, "\n\n")
    for (var in domain_vars) {
      var_info <- measure_data[[var]]
      if (!is.null(var_info)) {
        var_title <- janitor::make_clean_names(var, case = "title")
        var_description <- var_info$description
        var_reference <- var_info$reference
        var_items <- var_info$item

        domain_text <- paste0(domain_text, "#### ", var_title, "\n\n")

        # Handle multiple items
        if (length(var_items) > 1) {
          items_text <- paste(sapply(var_items, function(item) paste0("*", item, "*")), collapse = "\n")
          domain_text <- paste0(domain_text, items_text, "\n\n")
        } else {
          domain_text <- paste0(domain_text, "*", var_items, "*\n\n")
        }

        domain_text <- paste0(domain_text, var_description, " [@", var_reference, "]\n\n")
      }
    }
    return(domain_text)
  })

  # Combine all sections
  full_text <- paste0("## Variables\n\n",
                      "### Exposure Variable\n\n",
                      format_measure(exposure_var, measure_data[[exposure_var]]),
                      "### Outcome Variables\n\n",
                      paste(domain_sections, collapse = "\n"))

  # Add appendix reference if provided
  if (!is.null(appendices_measures)) {
    appendix_text <- paste0("\n\nDetailed descriptions of how these variables were measured and operationalized can be found in **", appendices_measures, "**.")
    full_text <- paste0(full_text, appendix_text)
  }

  return(full_text)
}

# Example usage:
# initialize_boilerplate_db(measures_path = "path/to/measures.rds")
# manage_boilerplate_db()
# report <- generate_boilerplate_report(
#   variables = list(
#     exposure_var = "political_conservative",
#     outcome_vars = list(
#       health = c("smoker_binary", "hlth_bmi", "log_hours_exercise"),
#       psychological = c("hlth_fatigue", "kessler_latent_anxiety"),
#       social = c("belong", "neighbourhood_community")
#     ),
#     appendices_measures = "Appendix C"
#   )
# )
# cat(report)
