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
#' @param create_dirs Logical. If TRUE, creates directories that don't exist. Default is FALSE.
#' @param confirm Logical. If TRUE, asks for confirmation before creating directories. Default is TRUE.
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
#' # Using deeply nested paths with headings and creating directories safely
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
#'   heading_level = "###",
#'   create_dirs = TRUE,
#'   confirm = TRUE
#' )
#'
#' # Generate text for a template with variable substitution
#' template_text <- boilerplate_generate_text(
#'   category = "template",
#'   sections = "journal_article",
#'   global_vars = list(
#'     title = "Effect of X on Y",
#'     authors = "Smith, J. & Jones, K.",
#'     date = "2025-04-01"
#'   )
#' )
#'
#' # Generate appendix content
#' appendix_text <- boilerplate_generate_text(
#'   category = "appendix",
#'   sections = c("supplementary_methods", "sensitivity_analyses"),
#'   global_vars = list(model_specification = "logistic regression")
#' )
#' }
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
    text_path = NULL,
    warn_missing = TRUE,
    add_headings = FALSE,
    heading_level = "###",
    custom_headings = list(),
    quiet = FALSE,
    create_dirs = FALSE,
    confirm = TRUE
) {
  # input validation
  category <- match.arg(category)

  if (!quiet) cli_alert_info("generating {category} text with {length(sections)} sections")

  # if category is "methods", use singular form for main heading
  category_title <- ifelse(category == "methods", "Method", tools::toTitleCase(category))

  # load database if not provided
  if (is.null(db)) {
    if (!quiet) cli_alert_info("loading text database for {category}")
    db <- tryCatch({
      boilerplate_manage_text(
        category = category,
        action = "list",
        text_path = text_path,
        create_dirs = create_dirs,
        confirm = confirm,
        quiet = quiet
      )
    }, error = function(e) {
      if (!quiet) cli_alert_danger("failed to load text database: {e$message}")
      stop(paste("failed to load text database:", e$message))
    })
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
      # first try to get it directly
      text_result <- boilerplate_manage_text(
        category = category,
        action = "get",
        name = section,
        db = db,
        template_vars = vars,
        warn_missing = warn_missing,
        quiet = quiet  # pass through quiet parameter
      )

      # if the result is a list, it might have a 'default' entry
      if (is.list(text_result) && "default" %in% names(text_result)) {
        if (is.character(text_result$default)) {
          # use the default entry
          if (!quiet) cli_alert_info("using default text for {section}")
          text_result$default
        } else {
          # not a character, can't use
          stop(paste("section", section, "default is not a character string"))
        }
      } else if (is.character(text_result)) {
        # it's already a character, use it
        text_result
      } else {
        # not usable
        stop(paste("section", section, "is not a character string or list with default"))
      }
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
  if (length(result) > 0) {
    if (!quiet) cli_alert_success("successfully generated {category} text with {length(result)} section(s)")
    return(paste(result, collapse = "\n\n"))
  } else {
    if (!quiet) cli_alert_warning("no text was generated - all sections were missing or invalid")
    return("")
  }
}

#' Generate Formatted Text for Measures
#'
#' This function generates formatted markdown text describing measures in a study.
#' It creates a simple output with customisable heading levels, focusing on presenting
#' measure information in a clean, consistent format.
#'
#' @param variable_heading Character. Heading for the variable section (e.g., "Exposure Variable", "Outcome Variables").
#' @param variables Character vector. Names of the variables to include.
#' @param db List. Measures database typically obtained from boilerplate_manage_measures().
#' @param heading_level Integer. Heading level for the section header (e.g., 2 for ##, 3 for ###). Default is 3.
#' @param subheading_level Integer. Heading level for individual variables (e.g., 3 for ###, 4 for ####). Default is 4.
#' @param print_waves Logical. Whether to include wave information in the output. Default is FALSE.
#' @param print_keywords Logical. Whether to include keyword information in the output. Default is FALSE.
#' @param appendices_measures Character. Optional reference to appendices containing measure details.
#' @param label_mappings Named character vector. Mappings to transform variable names in the output.
#'   For example, c("sdo" = "Social Dominance Orientation", "born_nz_binary" = "Born in NZ").
#'   If a variable name contains any of the keys in this vector, that part will be replaced with the corresponding value.
#' @param quiet Logical. If TRUE, suppresses all CLI alerts. Default is FALSE.
#'
#' @return Character string with formatted text describing the measures.
#'
#' @examples
#' \dontrun{
#' # Load measures database with safety parameters
#' measures_db <- boilerplate_manage_measures(
#'   action = "list",
#'   create_dirs = TRUE,
#'   confirm = TRUE
#' )
#'
#' # Define variable label mappings
#' var_labels <- c(
#'   "sdo" = "Social Dominance Orientation",
#'   "born_nz_binary" = "Born in NZ"
#' )
#'
#' # Generate exposure variable text with custom labels
#' exposure_text <- boilerplate_generate_measures(
#'   variable_heading = "Exposure Variable",
#'   variables = "political_conservative",
#'   db = measures_db,
#'   print_waves = TRUE,
#'   label_mappings = var_labels
#' )
#'
#' # Generate outcome variables text
#' outcome_text <- boilerplate_generate_measures(
#'   variable_heading = "Outcome Variables",
#'   variables = c("anxiety.gad7", "depression.phq9"),
#'   db = measures_db,
#'   appendices_measures = "Appendix A"
#' )
#'
#' # Print the results
#' cat(exposure_text)
#' cat(outcome_text)
#' }
#'
#' @importFrom janitor make_clean_names
#' @importFrom cli cli_alert_info cli_alert_success cli_alert_warning cli_alert_danger
#' @export
boilerplate_generate_measures <- function(
    variable_heading,
    variables,
    db,
    heading_level = 3,
    subheading_level = 4,
    print_waves = FALSE,
    print_keywords = FALSE,
    appendices_measures = NULL,
    label_mappings = NULL,
    quiet = FALSE
) {
  # input validation
  if (!is.character(variable_heading)) {
    if (!quiet) cli_alert_danger("variable_heading must be a character string")
    stop("variable_heading must be a character string")
  }

  if (!is.character(variables)) {
    if (!quiet) cli_alert_danger("variables must be a character vector")
    stop("variables must be a character vector")
  }

  if (!is.list(db)) {
    if (!quiet) cli_alert_danger("db must be a list")
    stop("db must be a list")
  }

  if (!quiet) cli_alert_info("generating formatted text for {length(variables)} {variable_heading}")

  # create heading markers
  heading_marker <- paste(rep("#", heading_level), collapse = "")
  subheading_marker <- paste(rep("#", subheading_level), collapse = "")

  if (!quiet) cli_alert_info("using heading level {heading_level} and subheading level {subheading_level}")

  # initialise output text
  output_text <- paste0(heading_marker, " ", variable_heading, "\n\n")

  # process each variable
  for (var in variables) {
    if (!quiet) cli_alert_info("processing variable: {var}")

    # get measure info
    measure_info <- db[[var]]

    # transform variable name if mapping is provided
    var_display <- if (!is.null(label_mappings)) {
      if (!quiet) cli_alert_info("applying label mappings to {var}")
      transform_label(var, label_mappings, quiet)
    } else {
      var
    }

    if (is.null(measure_info)) {
      # handle missing measures
      if (!quiet) cli_alert_warning("no information available for variable: {var}")
      title <- janitor::make_clean_names(var_display, case = "title")
      var_text <- paste0(subheading_marker, " ", title, "\n\n",
                         "no information available for this variable.\n\n")
    } else {
      # get variable title, applying mapping if provided
      title <- if (!is.null(measure_info$name)) {
        # apply mapping to the name from measure_info
        name_display <- if (!is.null(label_mappings)) {
          if (!quiet) cli_alert_info("applying label mappings to measure name: {measure_info$name}")
          transform_label(measure_info$name, label_mappings, quiet)
        } else {
          measure_info$name
        }
        janitor::make_clean_names(name_display, case = "title")
      } else {
        janitor::make_clean_names(var_display, case = "title")
      }

      # start with variable title
      var_text <- paste0(subheading_marker, " ", title, "\n\n")

      # add items if available
      items <- measure_info$items
      if (!is.null(items) && length(items) > 0) {
        if (!quiet) cli_alert_info("adding {length(items)} items for {var}")
        if (is.list(items)) {
          items_text <- paste(sapply(items, function(item) {
            paste0("*", item, "*")
          }), collapse = "\n")
        } else if (is.character(items)) {
          items_text <- paste(sapply(items, function(item) {
            paste0("*", item, "*")
          }), collapse = "\n")
        }
        var_text <- paste0(var_text, items_text, "\n\n")
      }

      # add description if available
      if (!is.null(measure_info$description)) {
        if (!quiet) cli_alert_info("adding description for {var}")
        var_text <- paste0(var_text, measure_info$description)

        # add reference if available
        if (!is.null(measure_info$reference)) {
          if (!quiet) cli_alert_info("adding reference: {measure_info$reference}")
          var_text <- paste0(var_text, " [@", measure_info$reference, "]")
        }

        var_text <- paste0(var_text, "\n\n")
      }

      # add waves if requested and available
      if (print_waves && !is.null(measure_info$waves)) {
        if (!quiet) cli_alert_info("adding waves information: {measure_info$waves}")
        var_text <- paste0(var_text, "*waves: ", measure_info$waves, "*\n\n")
      }

      # add keywords if requested and available
      if (print_keywords && !is.null(measure_info$keywords)) {
        if (is.character(measure_info$keywords)) {
          if (length(measure_info$keywords) > 1) {
            keywords <- paste(measure_info$keywords, collapse = ", ")
          } else {
            keywords <- measure_info$keywords
          }
          if (!quiet) cli_alert_info("adding keywords: {keywords}")
          var_text <- paste0(var_text, "*keywords: ", keywords, "*\n\n")
        }
      }
    }

    # add to output
    output_text <- paste0(output_text, var_text)
  }

  # add appendix reference if provided
  if (!is.null(appendices_measures)) {
    if (!quiet) cli_alert_info("adding appendix reference: {appendices_measures}")
    output_text <- paste0(
      output_text,
      "detailed descriptions of how these variables were measured and operationalised can be found in **",
      appendices_measures,
      "**.\n\n"
    )
  }

  if (!quiet) cli_alert_success("successfully generated formatted text for {variable_heading}")
  return(output_text)
}

#' @rdname boilerplate_generate_measures
#' @export
boilerplate_measures_text <- function(
    variable_heading,
    variables,
    db,
    heading_level = 3,
    subheading_level = 4,
    print_waves = FALSE,
    print_keywords = FALSE,
    appendices_measures = NULL,
    label_mappings = NULL,
    quiet = FALSE
) {
  # This function is being kept for backward compatibility
  # Issue a deprecation warning
  warning("boilerplate_measures_text() is deprecated. Please use boilerplate_generate_measures() instead.",
          call. = FALSE)

  boilerplate_generate_measures(
    variable_heading = variable_heading,
    variables = variables,
    db = db,
    heading_level = heading_level,
    subheading_level = subheading_level,
    print_waves = print_waves,
    print_keywords = print_keywords,
    appendices_measures = appendices_measures,
    label_mappings = label_mappings,
    quiet = quiet
  )
}


#' Transform a label using provided mappings
#'
#' @param label Character. The original label to transform
#' @param label_mapping Named character vector. Mappings to transform the label
#' @param quiet Logical. If TRUE, suppresses all CLI alerts. Default is FALSE.
#'
#' @return Character. The transformed label
#' @noRd
transform_label <- function(label, label_mapping = NULL, quiet = FALSE) {
  # apply mapping with partial substitutions
  if (!is.null(label_mapping)) {
    for (pattern in names(label_mapping)) {
      if (grepl(pattern, label, fixed = TRUE)) {
        replacement <- label_mapping[[pattern]]
        label <- gsub(pattern, replacement, label, fixed = TRUE)
        if (!quiet) cli_alert_info("mapped label: {pattern} -> {replacement}")
      }
    }
  }
  return(label)
}

# Removed duplicated boilerplate_measures_text function



