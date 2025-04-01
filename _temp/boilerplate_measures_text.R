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
#'
#' @return Character string with formatted text describing the measures.
#'
#' @examples
#' \dontrun{
#' # Get measures database
#' measures_db <- boilerplate_manage_measures(action = "list")
#'
#' # Generate exposure variable text
#' exposure_text <- boilerplate_measures_text(
#'   variable_heading = "Exposure Variable",
#'   variables = "political_conservative",
#'   db = measures_db,
#'   print_waves = TRUE
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
#' @export
boilerplate_measures_text <- function(
    variable_heading,
    variables,
    db,
    heading_level = 3,
    subheading_level = 4,
    print_waves = FALSE,
    print_keywords = FALSE,
    appendices_measures = NULL
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

    if (is.null(measure_info)) {
      # handle missing measures
      title <- janitor::make_clean_names(var, case = "title")
      var_text <- paste0(subheading_marker, " ", title, "\n\n",
                         "No information available for this variable.\n\n")
    } else {
      # get variable title
      title <- if (!is.null(measure_info$name)) {
        janitor::make_clean_names(measure_info$name, case = "title")
      } else {
        janitor::make_clean_names(var, case = "title")
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

