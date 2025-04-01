#' Generate text from boilerplate
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
#' @param db List. Optional database to use.
#' @param text_path Character. Path to the directory where text database files are stored.
#'   If NULL (default), the function will look in the following locations in order:
#'   1. "boilerplate/data/" subdirectory of the current working directory (via here::here())
#'   2. Package installation directory's "boilerplate/data/" folder
#'   3. "boilerplate/data/" relative to the current working directory
#' @param warn_missing Logical. Whether to warn about missing template variables.
#' @param add_headings Logical. Whether to add markdown headings to sections. Default is FALSE.
#' @param heading_level Character. The heading level to use (e.g., "###"). Default is "###".
#' @param custom_headings List. Custom headings for specific sections. Names should match section names.
#' @param quiet Logical. If TRUE, suppresses all CLI alerts. Default is FALSE.
#'
#' @return Character. The combined text with optional headings.
#'
#' @examples
#' \dontrun{
#' # Basic usage with methods sections
#' methods_text <- boilerplate_generate_text(
#'   category = "methods",
#'   sections = c("sample", "causal_assumptions.identification"),
#'   global_vars = list(
#'     exposure_var = "political_conservative",
#'     population = "university students"
#'   )
#' )
#'
#' # Using deeply nested paths with headings
#' methods_text <- boilerplate_generate_text(
#'   category = "methods",
#'   sections = c(
#'     "sample",
#'     "statistical.longitudinal.lmtp",
#'     "statistical.heterogeneity.grf.custom"
#'   ),
#'   global_vars = list(exposure_var = "treatment"),
#'   text_path = "path/to/project/data",
#'   add_headings = TRUE,
#'   heading_level = "###"
#' )
#' }
#'
#' @importFrom tools toTitleCase
#' @importFrom cli cli_alert_info cli_alert_success cli_alert_warning cli_alert_danger
#' @export
boilerplate_generate_text <- function(
    category = c("measures", "methods", "results", "discussion"),
    sections,
    global_vars = list(),
    section_vars = list(),
    text_overrides = list(),
    db = NULL,
    text_path = NULL,
    warn_missing = TRUE,
    add_headings = FALSE,
    heading_level = "###",
    custom_headings = list(),
    quiet = FALSE
) {
  # input validation
  category <- match.arg(category)

  if (!quiet) cli_alert_info("generating {category} text with {length(sections)} sections")

  # if category is "methods", use singular form for main heading
  category_title <- ifelse(category == "methods", "Method", tools::toTitleCase(category))

  # load database if not provided
  if (is.null(db)) {
    if (!quiet) cli_alert_info("loading text database for {category}")
    db <- boilerplate_manage_text(
      category = category,
      action = "list",
      text_path = text_path
    )
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
      vars <- c(vars, section_vars[[section]])
    }

    # attempt to retrieve text
    section_text <- tryCatch({
      boilerplate_manage_text(
        category = category,
        action = "get",
        name = section,
        db = db,
        template_vars = vars,
        warn_missing = warn_missing
      )
    }, error = function(e) {
      if (!quiet) cli_alert_danger("error retrieving section {section}: {e$message}")
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
  if (!quiet) cli_alert_success("successfully generated {category} text with {length(result)} section(s)")

  return(paste(result, collapse = "\n\n"))
}
# old
# boilerplate_generate_text <- function(
#     category = c("measures", "methods", "results", "discussion"),
#     sections,
#     global_vars = list(),
#     section_vars = list(),
#     text_overrides = list(),
#     db = NULL,
#     text_path = NULL,
#     warn_missing = TRUE,
#     add_headings = FALSE,
#     heading_level = "###",
#     custom_headings = list()
# ) {
#   # Input validation
#   category <- match.arg(category)
#
#   # If category is "methods", use singular form for main heading
#   category_title <- ifelse(category == "methods", "Method", tools::toTitleCase(category))
#
#   # Load database if not provided
#   if (is.null(db)) {
#     db <- boilerplate_manage_text(
#       category = category,
#       action = "list",
#       text_path = text_path
#     )
#   }
#
#   # Initialize result
#   result <- character(0)
#
#   # Process each section for text generation with arbitrary nesting
#   for (section in sections) {
#     # Determine section title
#     section_parts <- strsplit(section, "\\.")[[1]]
#     section_name <- section_parts[length(section_parts)]
#
#     # Create heading text
#     if (add_headings) {
#       # Check if there's a custom heading for this section
#       if (section %in% names(custom_headings)) {
#         heading_text <- paste0(heading_level, " ", custom_headings[[section]])
#       } else {
#         # Use the last part of the section path and convert to title case
#         heading_text <- paste0(heading_level, " ", tools::toTitleCase(gsub("_", " ", section_name)))
#       }
#     }
#
#     # Check for text override
#     if (section %in% names(text_overrides)) {
#       section_text <- text_overrides[[section]]
#       if (add_headings) {
#         section_text <- paste(heading_text, section_text, sep = "\n\n")
#       }
#       result <- c(result, section_text)
#       next
#     }
#
#     # Merge global and section-specific variables
#     vars <- global_vars
#     if (section %in% names(section_vars)) {
#       vars <- c(vars, section_vars[[section]])
#     }
#
#     # Attempt to retrieve text
#     section_text <- tryCatch({
#       boilerplate_manage_text(
#         category = category,
#         action = "get",
#         name = section,
#         db = db,
#         template_vars = vars,
#         warn_missing = warn_missing
#       )
#     }, error = function(e) {
#       warning(paste("Error retrieving section", section, ":", e$message))
#       return(NULL)
#     })
#
#     if (!is.null(section_text) && is.character(section_text)) {
#       if (add_headings) {
#         section_text <- paste(heading_text, section_text, sep = "\n\n")
#       }
#       result <- c(result, section_text)
#     }
#   }
#
#   # Combine all sections
#   return(paste(result, collapse = "\n\n"))
# }



