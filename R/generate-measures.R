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
#' @param quiet Logical. If TRUE, suppresses all CLI alerts. Default is FALSE.
#' @param sample_items Integer or FALSE. If numeric (1-3), shows only that many sample items. Default is FALSE (show all).
#' @param table_format Logical. If TRUE, formats output as markdown tables. Default is FALSE.
#' @param check_completeness Logical. If TRUE, adds notes about missing information. Default is FALSE.
#' @param extract_scale_info Logical. If TRUE, attempts to extract scale information from descriptions. Default is TRUE.
#'
#' @return Character string with formatted text describing the measures.
#'
#' @examples
#' # Create a temporary directory and initialise databases
#' temp_dir <- tempdir()
#' data_path <- file.path(temp_dir, "boilerplate_measures_example", "data")
#'
#' # Initialise measures database with default content
#' boilerplate_init(
#'   categories = "measures",
#'   data_path = data_path,
#'   create_dirs = TRUE,
#'   create_empty = FALSE,
#'   confirm = FALSE,
#'   quiet = TRUE
#' )
#'
#' # Import the unified database
#' unified_db <- boilerplate_import(data_path = data_path, quiet = TRUE)
#' measures_db <- unified_db$measures
#'
#' # Generate with sample items only
#' exposure_text <- boilerplate_generate_measures(
#'   variable_heading = "Exposure Variable",
#'   variables = "anxiety",
#'   db = measures_db,
#'   sample_items = 2,  # Show only first 2 items
#'   quiet = TRUE
#' )
#'
#' # Check the output
#' cat(substr(exposure_text, 1, 150), "...\n")
#'
#' # Generate with table format for multiple variables
#' outcome_text <- boilerplate_generate_measures(
#'   variable_heading = "Outcome Variables",
#'   variables = c("anxiety", "depression"),
#'   db = measures_db,
#'   table_format = TRUE,
#'   quiet = TRUE
#' )
#'
#' # Clean up
#' unlink(file.path(temp_dir, "boilerplate_measures_example"), recursive = TRUE)
#'
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
    quiet = FALSE,
    sample_items = FALSE,
    table_format = FALSE,
    check_completeness = FALSE,
    extract_scale_info = TRUE
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

  # validate sample_items
  if (!isFALSE(sample_items) && (!is.numeric(sample_items) || sample_items < 1 || sample_items > 3)) {
    if (!quiet) cli_alert_danger("sample_items must be FALSE or a number between 1 and 3")
    stop("sample_items must be FALSE or a number between 1 and 3")
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
      title <- make_clean_title(var_display)
      var_text <- paste0(subheading_marker, " ", title, "\n\n",
                         "No information available for this variable.\n\n")
    } else {
      # get variable title
      title <- if (!is.null(measure_info$name)) {
        name_display <- if (!is.null(label_mappings)) {
          if (!quiet) cli_alert_info("applying label mappings to measure name: {measure_info$name}")
          transform_label(measure_info$name, label_mappings, quiet)
        } else {
          measure_info$name
        }
        make_clean_title(name_display)
      } else {
        make_clean_title(var_display)
      }

      # extract scale information if present in description
      scale_info <- NULL
      description_text <- measure_info$description
      reversed_items <- character()

      if (extract_scale_info && !is.null(description_text)) {
        # extract scale information from description
        scale_pattern <- "(?i)(ordinal response|scale|response format|response options?)\\s*:?\\s*\\(([^)]+)\\)"
        scale_match <- regmatches(description_text, regexpr(scale_pattern, description_text, perl = TRUE))

        if (length(scale_match) > 0) {
          scale_info <- gsub(scale_pattern, "\\2", scale_match, perl = TRUE)
          # remove scale info from description to avoid duplication
          description_text <- trimws(gsub(scale_pattern, "", description_text, perl = TRUE))
          if (description_text == "") description_text <- NULL
        }
      }

      # check for reversed items in item text
      if (!is.null(measure_info$items)) {
        for (i in seq_along(measure_info$items)) {
          if (grepl("\\(reversed\\)|\\(r\\)|\\breversed\\b", measure_info$items[[i]], ignore.case = TRUE)) {
            reversed_items <- c(reversed_items, as.character(i))
          }
        }
      }

      # check if variable name indicates reversal
      if (grepl("_reversed$", var)) {
        if (!quiet) cli_alert_info("variable name indicates reversed scoring: {var}")
      }

      # check completeness if requested
      missing_info <- character()
      if (check_completeness) {
        if (is.null(measure_info$description) && is.null(description_text)) missing_info <- c(missing_info, "description")
        if (is.null(measure_info$reference)) missing_info <- c(missing_info, "reference")
        if (is.null(measure_info$items) || length(measure_info$items) == 0) missing_info <- c(missing_info, "items")
        if (is.null(measure_info$waves)) missing_info <- c(missing_info, "waves")
      }

      # build output based on format
      if (table_format) {
        # table format output
        var_text <- paste0(subheading_marker, " ", title, "\n\n")

        # create info table
        var_text <- paste0(var_text, "| Field | Information |\n")
        var_text <- paste0(var_text, "|-------|-------------|\n")

        # add description
        if (!is.null(description_text)) {
          desc_with_ref <- description_text
          if (!is.null(measure_info$reference)) {
            # Remove trailing punctuation from description
            desc_with_ref <- sub("[.:;]\\s*$", "", desc_with_ref)
            desc_with_ref <- paste0(desc_with_ref, " [@", measure_info$reference, "].")
          } else if (!grepl("[.!?]\\s*$", desc_with_ref)) {
            desc_with_ref <- paste0(desc_with_ref, ".")
          }
          var_text <- paste0(var_text, "| Description | ", desc_with_ref, " |\n")
        }

        # add scale info
        if (!is.null(scale_info)) {
          var_text <- paste0(var_text, "| Response Scale | ", scale_info, " |\n")
        }

        # add waves
        if (!is.null(measure_info$waves) && measure_info$waves != "") {
          var_text <- paste0(var_text, "| Waves | ", measure_info$waves, " |\n")
        }

        # add reversed items info
        if (length(reversed_items) > 0) {
          var_text <- paste0(var_text, "| Reversed Items | ", paste(reversed_items, collapse = ", "), " |\n")
        }

        var_text <- paste0(var_text, "\n")

        # add items
        if (!is.null(measure_info$items) && length(measure_info$items) > 0) {
          var_text <- paste0(var_text, "**Items:**\n\n")

          # determine how many items to show
          n_items <- length(measure_info$items)
          items_to_show <- if (!isFALSE(sample_items)) min(sample_items, n_items) else n_items

          for (i in 1:items_to_show) {
            item_text <- measure_info$items[[i]]
            var_text <- paste0(var_text, i, ". ", item_text, "\n")
          }

          if (!isFALSE(sample_items) && n_items > items_to_show) {
            var_text <- paste0(var_text, "\n*(", n_items - items_to_show, " additional items not shown)*\n")
          }

          var_text <- paste0(var_text, "\n")
        }

      } else {
        # standard format output
        var_text <- paste0(subheading_marker, " ", title, "\n\n")

        # add description and reference
        if (!is.null(description_text)) {
          if (!quiet) cli_alert_info("adding description for {var}")

          # Remove trailing punctuation from description if reference will be added
          if (!is.null(measure_info$reference)) {
            # Remove trailing period, colon, or semicolon
            description_text <- sub("[.:;]\\s*$", "", description_text)
          }

          var_text <- paste0(var_text, description_text)

          if (!is.null(measure_info$reference)) {
            if (!quiet) cli_alert_info("adding reference: {measure_info$reference}")
            var_text <- paste0(var_text, " [@", measure_info$reference, "].")
          } else {
            # Add period if no reference and description doesn't end with punctuation
            if (!grepl("[.!?]\\s*$", description_text)) {
              var_text <- paste0(var_text, ".")
            }
          }

          var_text <- paste0(var_text, "\n\n")
        }

        # add scale info if extracted
        if (!is.null(scale_info)) {
          var_text <- paste0(var_text, "**Response scale:** ", scale_info, "\n\n")
        }

        # add waves if requested
        if (print_waves && !is.null(measure_info$waves) && measure_info$waves != "") {
          if (!quiet) cli_alert_info("adding waves information: {measure_info$waves}")
          var_text <- paste0(var_text, "*Waves: ", measure_info$waves, "*\n\n")
        }

        # add items
        items <- measure_info$items
        if (!is.null(items) && length(items) > 0) {
          if (!quiet) cli_alert_info("adding {length(items)} items for {var}")

          if (!is.null(description_text)) {
            var_text <- paste0(var_text, "Items:\n\n")
          }

          # determine how many items to show
          n_items <- length(items)
          items_to_show <- if (!isFALSE(sample_items)) min(sample_items, n_items) else n_items

          for (i in 1:items_to_show) {
            var_text <- paste0(var_text, "* ", items[[i]], "\n")
          }

          if (!isFALSE(sample_items) && n_items > items_to_show) {
            var_text <- paste0(var_text, "\n*(", n_items - items_to_show, " additional items not shown)*\n")
          }

          var_text <- paste0(var_text, "\n")
        }

        # add keywords if requested
        if (print_keywords && !is.null(measure_info$keywords)) {
          if (is.character(measure_info$keywords)) {
            if (length(measure_info$keywords) > 1) {
              keywords <- paste(measure_info$keywords, collapse = ", ")
            } else {
              keywords <- measure_info$keywords
            }
            if (!quiet) cli_alert_info("adding keywords: {keywords}")
            var_text <- paste0(var_text, "*Keywords: ", keywords, "*\n\n")
          }
        }
      }

      # add completeness note if requested and info is missing
      if (check_completeness && length(missing_info) > 0) {
        var_text <- paste0(var_text, "*Note: Missing ", paste(missing_info, collapse = ", "), "*\n\n")
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
      "Detailed descriptions of how these variables were measured and operationalised can be found in **",
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
  # Default options - could be extended later
  options <- list(
    remove_tx_prefix = FALSE,
    remove_z_suffix = FALSE,
    remove_underscores = FALSE,
    use_title_case = FALSE
  )

  # coerce each flag to a single TRUE/FALSE
  remove_tx_prefix   <- isTRUE(options$remove_tx_prefix)
  remove_z_suffix    <- isTRUE(options$remove_z_suffix)
  remove_underscores <- isTRUE(options$remove_underscores)
  use_title_case     <- isTRUE(options$use_title_case)

  original_label <- label

  # 1) explicit mappings
  if (!is.null(label_mapping)) {
    for (pat in names(label_mapping)) {
      if (grepl(pat, label, fixed = TRUE)) {
        repl  <- label_mapping[[pat]]
        label <- gsub(pat, repl, label, fixed = TRUE)
        if (!quiet) cli::cli_alert_info("Mapped label: {pat} -> {repl}")
      }
    }
  }

  # 2) strip trailing numeric-range suffix
  label <- sub(" - \\(.*\\]$", "", label)

  # 3) default transforms if unmapped
  if (identical(label, original_label)) {
    if (remove_tx_prefix)   label <- sub("^t[0-9]+_", "", label)
    if (remove_z_suffix)    label <- sub("_z$", "", label)
    if (remove_underscores) label <- gsub("_", " ", label, fixed = TRUE)

    if (use_title_case) {
      # convert to title case and enforce specific uppercase acronyms
      label <- tools::toTitleCase(label)
      label <- gsub("Nz",  "NZ",  label, fixed = TRUE)
      label <- gsub("Sdo", "SDO", label, fixed = TRUE)
      label <- gsub("Rwa", "RWA", label, fixed = TRUE)
    }
  }

  # log if changed
  if (!identical(label, original_label) && !quiet) {
    cli::cli_alert_info("Transformed label: {original_label} -> {label}")
  }

  label
}
