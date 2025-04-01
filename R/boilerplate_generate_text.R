#' Generate Text from Boilerplate
#'
#' This function generates text by retrieving and combining text from
#' a boilerplate database. It allows for template variable substitution and
#' customization through overrides. Supports arbitrarily nested section paths
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
    custom_headings = list()
) {
  # Input validation
  category <- match.arg(category)

  # If category is "methods", use singular form for main heading
  category_title <- ifelse(category == "methods", "Method", tools::toTitleCase(category))

  # Load database if not provided
  if (is.null(db)) {
    db <- boilerplate_manage_text(
      category = category,
      action = "list",
      text_path = text_path
    )
  }

  # Initialize result
  result <- character(0)

  # Process each section for text generation with arbitrary nesting
  for (section in sections) {
    # Determine section title
    section_parts <- strsplit(section, "\\.")[[1]]
    section_name <- section_parts[length(section_parts)]

    # Create heading text
    if (add_headings) {
      # Check if there's a custom heading for this section
      if (section %in% names(custom_headings)) {
        heading_text <- paste0(heading_level, " ", custom_headings[[section]])
      } else {
        # Use the last part of the section path and convert to title case
        heading_text <- paste0(heading_level, " ", tools::toTitleCase(gsub("_", " ", section_name)))
      }
    }

    # Check for text override
    if (section %in% names(text_overrides)) {
      section_text <- text_overrides[[section]]
      if (add_headings) {
        section_text <- paste(heading_text, section_text, sep = "\n\n")
      }
      result <- c(result, section_text)
      next
    }

    # Merge global and section-specific variables
    vars <- global_vars
    if (section %in% names(section_vars)) {
      vars <- c(vars, section_vars[[section]])
    }

    # Attempt to retrieve text
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
      warning(paste("Error retrieving section", section, ":", e$message))
      return(NULL)
    })

    if (!is.null(section_text) && is.character(section_text)) {
      if (add_headings) {
        section_text <- paste(heading_text, section_text, sep = "\n\n")
      }
      result <- c(result, section_text)
    }
  }

  # Combine all sections
  return(paste(result, collapse = "\n\n"))
}



#' Generate Methods Text from Boilerplate
#'
#' This function generates methods text by retrieving and combining text from
#' the methods database. It's a wrapper around boilerplate_generate_text with
#' methods-specific defaults. Supports arbitrarily nested section paths
#' using dot notation for flexible organization.
#'
#' @param sections Character vector. The methods sections to include (can use dot notation for nesting).
#' @param global_vars List. Variables available to all sections.
#' @param section_vars List. Section-specific variables.
#' @param text_overrides List. Direct text overrides for specific sections.
#' @param db List. Optional methods database to use.
#' @param text_path Character. Path to the directory where text database files are stored.
#' @param warn_missing Logical. Whether to warn about missing template variables.
#' @param add_headings Logical. Whether to add markdown headings to sections. Default is FALSE.
#' @param heading_level Character. The heading level to use (e.g., "###"). Default is "###".
#' @param custom_headings List. Custom headings for specific sections. Names should match section names.
#'
#' @return Character. The combined methods text.
#'
#' @examples
#' \dontrun{
#' # Basic usage with default sections
#' methods_text <- boilerplate_methods_text(
#'   global_vars = list(
#'     exposure_var = "political_conservative",
#'     population = "university students"
#'   )
#' )
#'
#' # Using deeply nested organization with headings
#' methods_text <- boilerplate_methods_text(
#'   sections = c(
#'     "sample",
#'     "causal_assumptions.identification",
#'     "statistical.longitudinal.lmtp",
#'     "statistical.heterogeneity.grf.custom"
#'   ),
#'   global_vars = list(exposure_var = "treatment"),
#'   add_headings = TRUE
#' )
#' }
#'
#' @export
boilerplate_methods_text <- function(
    sections = c(
      "sample",
      "causal_assumptions.identification",
      "causal_assumptions.confounding_control",
      "statistical.longitudinal.lmtp"
    ),
    global_vars = list(),
    section_vars = list(),
    text_overrides = list(),
    db = NULL,
    text_path = NULL,
    warn_missing = TRUE,
    add_headings = FALSE,
    heading_level = "###",
    custom_headings = list()
) {
  boilerplate_generate_text(
    category = "methods",
    sections = sections,
    global_vars = global_vars,
    section_vars = section_vars,
    text_overrides = text_overrides,
    db = db,
    text_path = text_path,
    warn_missing = warn_missing,
    add_headings = add_headings,
    heading_level = heading_level,
    custom_headings = custom_headings
  )
}

#' Generate Results Text from Boilerplate
#'
#' This function generates results text by retrieving and combining text from
#' the results database with appropriate variable substitution. It's a wrapper
#' around boilerplate_generate_text with results-specific defaults.
#' Supports arbitrarily nested section paths using dot notation.
#'
#' @param sections Character vector. The results sections to include (can use dot notation for nesting).
#' @param results_data List. Data from analysis results to use in template variables.
#' @param section_vars List. Section-specific variables if needed beyond results_data.
#' @param text_overrides List. Direct text overrides for specific sections.
#' @param db List. Optional results database to use.
#' @param text_path Character. Path to the directory where text database files are stored.
#' @param warn_missing Logical. Whether to warn about missing template variables.
#' @param add_headings Logical. Whether to add markdown headings to sections. Default is FALSE.
#' @param heading_level Character. The heading level to use (e.g., "###"). Default is "###".
#' @param custom_headings List. Custom headings for specific sections. Names should match section names.
#'
#' @return Character. The combined results text.
#'
#' @examples
#' \dontrun{
#' # Basic usage with analysis results
#' results_text <- boilerplate_results_text(
#'   sections = c("main_effect"),
#'   results_data = list(
#'     effect_size = "0.35",
#'     confidence_interval = "95% CI: 0.21, 0.49",
#'     interpretation = "a moderate positive effect"
#'   )
#' )
#'
#' # Using domain-specific results with nested paths and headings
#' results_text <- boilerplate_results_text(
#'   sections = c("main_effect", "domain.health", "domain.psychological"),
#'   results_data = list(
#'     effect_size = "0.35",
#'     confidence_interval = "95% CI: 0.21, 0.49",
#'     interpretation = "a moderate positive effect",
#'     health_finding = "improved physical outcomes",
#'     psych_finding = "reduced stress levels"
#'   ),
#'   add_headings = TRUE
#' )
#' }
#'
#' @export
boilerplate_results_text <- function(
    sections = c("main_effect"),
    results_data = list(),
    section_vars = list(),
    text_overrides = list(),
    db = NULL,
    text_path = NULL,
    warn_missing = TRUE,
    add_headings = FALSE,
    heading_level = "###",
    custom_headings = list()
) {
  boilerplate_generate_text(
    category = "results",
    sections = sections,
    global_vars = results_data,
    section_vars = section_vars,
    text_overrides = text_overrides,
    db = db,
    text_path = text_path,
    warn_missing = warn_missing,
    add_headings = add_headings,
    heading_level = heading_level,
    custom_headings = custom_headings
  )
}

#' Transform a label using provided mappings
#'
#' @param label Character. The original label to transform
#' @param label_mapping Named character vector. Mappings to transform the label
#'
#' @return Character. The transformed label
#' @noRd
transform_label <- function(label, label_mapping = NULL) {
  # Apply mapping with partial substitutions
  if (!is.null(label_mapping)) {
    for (pattern in names(label_mapping)) {
      if (grepl(pattern, label, fixed = TRUE)) {
        replacement <- label_mapping[[pattern]]
        label <- gsub(pattern, replacement, label, fixed = TRUE)
        cli::cli_alert_info("Mapped label: {pattern} -> {replacement}")
      }
    }
  }
  return(label)
}

#' Generate Formatted Text for Measures
#'
#' This function generates formatted markdown text describing measures in a study.
#' It creates a simple output with customizable heading levels, focusing on presenting
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
#'
#' @return Character string with formatted text describing the measures.
#'
#' @examples
#' \dontrun{
#' # Get measures database
#' measures_db <- boilerplate_manage_measures(action = "list")
#'
#' # Define variable label mappings
#' var_labels <- c(
#'   "sdo" = "Social Dominance Orientation",
#'   "born_nz_binary" = "Born in NZ"
#' )
#'
#' # Generate exposure variable text with custom labels
#' exposure_text <- boilerplate_measures_text(
#'   variable_heading = "Exposure Variable",
#'   variables = "political_conservative",
#'   db = measures_db,
#'   print_waves = TRUE,
#'   label_mappings = var_labels
#' )
#'
#' # Generate outcome variables text
#' outcome_text <- boilerplate_measures_text(
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
#' @importFrom cli cli_alert_info
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
    label_mappings = NULL
) {
  # input validation
  if (!is.character(variable_heading)) {
    stop("variable_heading must be a character string")
  }

  if (!is.character(variables)) {
    stop("variables must be a character vector")
  }

  if (!is.list(db)) {
    stop("db must be a list")
  }

  # create heading markers
  heading_marker <- paste(rep("#", heading_level), collapse = "")
  subheading_marker <- paste(rep("#", subheading_level), collapse = "")

  # initialize output text
  output_text <- paste0(heading_marker, " ", variable_heading, "\n\n")

  # process each variable
  for (var in variables) {
    # get measure info
    measure_info <- db[[var]]

    # transform variable name if mapping is provided
    var_display <- if (!is.null(label_mappings)) {
      transform_label(var, label_mappings)
    } else {
      var
    }

    if (is.null(measure_info)) {
      # handle missing measures
      title <- janitor::make_clean_names(var_display, case = "title")
      var_text <- paste0(subheading_marker, " ", title, "\n\n",
                         "No information available for this variable.\n\n")
    } else {
      # get variable title, applying mapping if provided
      title <- if (!is.null(measure_info$name)) {
        # apply mapping to the name from measure_info
        name_display <- if (!is.null(label_mappings)) {
          transform_label(measure_info$name, label_mappings)
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
        var_text <- paste0(var_text, measure_info$description)

        # add reference if available
        if (!is.null(measure_info$reference)) {
          var_text <- paste0(var_text, " [@", measure_info$reference, "]")
        }

        var_text <- paste0(var_text, "\n\n")
      }

      # add waves if requested and available
      if (print_waves && !is.null(measure_info$waves)) {
        var_text <- paste0(var_text, "*Waves: ", measure_info$waves, "*\n\n")
      }

      # add keywords if requested and available
      if (print_keywords && !is.null(measure_info$keywords)) {
        if (is.character(measure_info$keywords)) {
          if (length(measure_info$keywords) > 1) {
            keywords <- paste(measure_info$keywords, collapse = ", ")
          } else {
            keywords <- measure_info$keywords
          }
          var_text <- paste0(var_text, "*Keywords: ", keywords, "*\n\n")
        }
      }
    }

    # add to output
    output_text <- paste0(output_text, var_text)
  }

  # add appendix reference if provided
  if (!is.null(appendices_measures)) {
    output_text <- paste0(
      output_text,
      "Detailed descriptions of how these variables were measured and operationalized can be found in **",
      appendices_measures,
      "**.\n\n"
    )
  }

  return(output_text)
}



