#' Generate Formatted Text for Measures
#'
#' This function generates formatted markdown text describing measures in a study.
#' It creates a simple output with customisable heading levels, focusing on presenting
#' measure information in a clean, consistent format.
#'
#' @param variable_heading Character. Heading for the variable section (e.g., "Exposure Variable", "Outcome Variables").
#' @param variables Character vector. Names of the variables to include.
#' @param db List. Measures database. Can be either a measures database or a unified database.
#'   If a unified database is provided, the measures category will be extracted.
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
#’ @examples
#’ \dontrun{
#’ # Import unified database
#’ unified_db <- boilerplate_import()
#’
#’ # Generate exposure variable text with unified database
#’ exposure_text <- boilerplate_generate_measures(
#’   variable_heading   = "Exposure Variable",
#’   variables          = "political_conservative",
#’   db                 = unified_db,  # pass the unified database
#’   print_waves        = TRUE
#’ )
#’
#’ # Import just the measures database
#’ measures_db <- boilerplate_import("measures")
#’
#’ # Generate outcome variables text with measures database
#’ outcome_text <- boilerplate_generate_measures(
#’   variable_heading     = "Outcome Variables",
#’   variables            = c("anxiety_gad7", "depression_phq9"),
#’   db                   = measures_db,  # pass just the measures database
#’   appendices_measures  = "Appendix A"
#’ )
#’ }
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

  # prepare the database
  if (!is.list(db)) {
    if (!quiet) cli_alert_danger("db must be a list")
    stop("db must be a list")
  } else if ("measures" %in% names(db)) {
    # if a unified database is provided, extract the measures category
    if (!quiet) cli_alert_info("using measures from unified database")
    db <- db$measures
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


