#' Generate Text from boilerplate
#'
#' This function generates text by retrieving and combining text from
#' a boilerplate database. It allows for template variable substitution and
#' customisation through overrides. Supports arbitrarily nested section paths
#' using dot notation.
#'
#' @param category Character. Category of text to generate.
#' @param sections Character vector. The sections to include (can use dot notation for nesting).
#' @param global_vars List. Variables available to all sections.
#' @param section_vars List. Section-specific variables.
#' @param text_overrides List. Direct text overrides for specific sections.
#' @param db List. Optional database to use. Can be either a category-specific database or a unified database.
#'   If a unified database is provided, the appropriate category will be extracted.
#' @param data_path Character. Path to the directory where database files are stored.
#'   If NULL (default), uses here::here("boilerplate", "data").
#' @param warn_missing Logical. Whether to warn about missing template variables.
#' @param add_headings Logical. Whether to add markdown headings to sections. Default is FALSE.
#' @param heading_level Character. The heading level to use (e.g., "###"). Default is "###".
#' @param custom_headings List. Custom headings for specific sections. Names should match section names.
#' @param quiet Logical. If TRUE, suppresses all CLI alerts. Default is FALSE.
#' @param create_dirs Logical. If TRUE, creates directories that don't exist. Default is FALSE.
#' @param confirm Logical. If TRUE, asks for confirmation before creating directories. Default is TRUE.
#' @param copy_bibliography Logical. If TRUE, copies bibliography file to the project. Default is FALSE.
#' @param bibliography_path Character. Directory to copy bibliography file to. Default is "." (current directory).
#'
#' @return Character. The combined text with optional headings.
#'
#' @examples
#' # Create a temporary directory and initialise databases
#' temp_dir <- tempdir()
#' data_path <- file.path(temp_dir, "boilerplate_text_example", "data")
#'
#' # Initialise with default content
#' boilerplate_init(
#'   categories = c("methods", "results"),
#'   data_path = data_path,
#'   create_dirs = TRUE,
#'   create_empty = FALSE,
#'   confirm = FALSE,
#'   quiet = TRUE
#' )
#'
#' # Import the databases
#' unified_db <- boilerplate_import(data_path = data_path, quiet = TRUE)
#'
#' # Basic usage with methods sections
#' methods_text <- boilerplate_generate_text(
#'   category = "methods",
#'   sections = c("sample"),
#'   global_vars = list(
#'     exposure_var = "political_conservative",
#'     population = "university students",
#'     timeframe = "2023-2024"
#'   ),
#'   db = unified_db,
#'   quiet = TRUE
#' )
#'
#' # Check the output
#' cat(substr(methods_text, 1, 100), "...\n")
#'
#' # Using with headings
#' methods_text <- boilerplate_generate_text(
#'   category = "methods",
#'   sections = c("sample"),
#'   global_vars = list(
#'     exposure_var = "treatment",
#'     timeframe = "2023-2024"
#'   ),
#'   db = unified_db,
#'   add_headings = TRUE,
#'   heading_level = "##",
#'   quiet = TRUE
#' )
#'
#' # Clean up
#' unlink(file.path(temp_dir, "boilerplate_text_example"), recursive = TRUE)
#'
#' @importFrom tools toTitleCase
#' @importFrom cli cli_alert_info cli_alert_success cli_alert_warning cli_alert_danger
#' @export
boilerplate_generate_text <- function(
    category = c("measures", "methods", "results", "discussion", "appendix", "template"),
    sections,
    global_vars = list(),
    section_vars = list(),
    text_overrides = list(),
    db = NULL,
    data_path = NULL,
    warn_missing = TRUE,
    add_headings = FALSE,
    heading_level = "###",
    custom_headings = list(),
    quiet = FALSE,
    create_dirs = FALSE,
    confirm = TRUE,
    copy_bibliography = FALSE,
    bibliography_path = "."
) {
  # input validation
  category <- match.arg(category)

  if (!quiet) cli_alert_info("generating {category} text with {length(sections)} sections")

  # prepare the database
  if (is.null(db)) {
    # if no database is provided, load it from disk
    if (!quiet) cli_alert_info("importing {category} database")
    db <- boilerplate_import(category, data_path = data_path, quiet = quiet)
  } else if (is.list(db) && category %in% names(db)) {
    # if a unified database is provided, extract the appropriate category
    if (!quiet) cli_alert_info("using {category} from unified database")
    db <- db[[category]]
  }

  # check that db is valid
  if (!is.list(db)) {
    if (!quiet) cli_alert_danger("invalid database - must be a list")
    stop("Invalid database - must be a list")
  }

  # initialise result
  result <- character(0)
  missing_sections <- character(0)

  # process each section for text generation with arbitrary nesting
  for (section in sections) {
    if (!quiet) cli_alert_info("processing section: {section}")

    # determine section title
    section_parts <- strsplit(section, "\\.")[[1]]
    section_name <- section_parts[length(section_parts)]

    # create heading text
    if (add_headings) {
      # check if there's a custom heading for this section
      if (section %in% names(custom_headings)) {
        heading_text <- paste0(heading_level, " ", custom_headings[[section]])
      } else {
        # use the last part of the section path and convert to title case
        heading_text <- paste0(heading_level, " ", tools::toTitleCase(gsub("_", " ", section_name)))
      }
    }

    # check for text override
    if (section %in% names(text_overrides)) {
      if (!quiet) cli_alert_info("using text override for {section}")
      section_text <- text_overrides[[section]]
      if (add_headings) {
        section_text <- paste(heading_text, section_text, sep = "\n\n")
      }
      result <- c(result, section_text)
      next
    }

    # merge global and section-specific variables
    vars <- global_vars
    if (section %in% names(section_vars)) {
      if (!quiet) cli_alert_info("applying section-specific variables for {section}")
      # use modifyList to ensure section-specific variables override global ones
      vars <- utils::modifyList(vars, section_vars[[section]])
    }

    # attempt to retrieve text
    section_text <- tryCatch({
      # extract text from nested structure
      text_result <- NULL

      # split the name by dots to handle nested paths
      path_parts <- strsplit(section, "\\.")[[1]]

      # navigate through nested structure
      current_item <- db
      for (part in path_parts) {
        if (!is.list(current_item) || !(part %in% names(current_item))) {
          stop(paste("path component", part, "not found"))
        }
        current_item <- current_item[[part]]
      }

      text_result <- current_item

      # if the result is a list, it might have a 'default' entry
      if (is.list(text_result) && "default" %in% names(text_result)) {
        if (is.character(text_result$default)) {
          # use the default entry
          if (!quiet) cli_alert_info("using default text for {section}")
          text_result <- text_result$default
        } else {
          # not a character, can't use
          stop(paste("section", section, "default is not a character string"))
        }
      }

      # check if it's a character string now
      if (is.character(text_result)) {
        # apply template variables
        if (!quiet) cli_alert_info("applying template variables to {section}")
        text_result <- apply_template_vars(text_result, vars, warn_missing)
      } else {
        # not usable
        stop(paste("section", section, "is not a character string or list with default"))
      }

      text_result
    }, error = function(e) {
      if (!quiet) cli_alert_warning("error retrieving section {section}: {e$message}")
      missing_sections <- c(missing_sections, section)
      return(NULL)
    })

    if (!is.null(section_text) && is.character(section_text)) {
      if (add_headings) {
        section_text <- paste(heading_text, section_text, sep = "\n\n")
      }
      result <- c(result, section_text)
    } else if (!quiet) {
      cli_alert_warning("no text found for section {section}")
    }
  }

  # report on missing sections
  if (length(missing_sections) > 0 && !quiet) {
    cli_alert_warning("could not retrieve {length(missing_sections)} section(s): {paste(missing_sections, collapse = ', ')}")
  }

  # combine all sections and report success
  if (length(result) > 0) {
    if (!quiet) cli_alert_success("successfully generated {category} text with {length(result)} section(s)")

    # Copy bibliography if requested
    if (copy_bibliography && !is.null(db)) {
      # Need to ensure we have the full database
      full_db <- if (category %in% names(db)) {
        # db was the category-specific database, need to wrap it
        temp_db <- list()
        temp_db[[category]] <- db
        temp_db
      } else {
        # db is already the full unified database
        db
      }

      # Copy bibliography
      bib_result <- boilerplate_copy_bibliography(
        full_db,
        target_dir = bibliography_path,
        quiet = quiet
      )

      if (!is.null(bib_result) && !quiet) {
        cli_alert_info("Bibliography available at: {bib_result}")
      }
    }

    return(paste(result, collapse = "\n\n"))
  } else {
    if (!quiet) cli_alert_warning("no text was generated - all sections were missing or invalid")
    return("")
  }
}





