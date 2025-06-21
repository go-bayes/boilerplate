#' Standardise Measure Entries in Database
#'
#' This function standardises measure entries by extracting scale information,
#' identifying reversed items, cleaning descriptions, and ensuring consistent structure.
#'
#' @param db List. Either a single measure or a measures database to standardise.
#' @param measure_names Character vector. Specific measures to standardise. If NULL, processes all.
#' @param extract_scale Logical. Extract scale information from descriptions. Default is TRUE.
#' @param identify_reversed Logical. Identify reversed items. Default is TRUE.
#' @param clean_descriptions Logical. Clean up description text. Default is TRUE.
#' @param ensure_structure Logical. Ensure all measures have standard fields. Default is TRUE.
#' @param standardise_references Logical. Standardise reference format. Default is TRUE.
#' @param json_compatible Logical. Ensure JSON-compatible structure by converting vectors to lists
#'   and removing NULL values. Default is FALSE.
#' @param verbose Logical. Show detailed progress information. Default is FALSE.
#' @param quiet Logical. Suppress all messages. Default is FALSE.
#'
#' @return List. The standardised measure(s) or database.
#'
#' @examples
#' # Create a temporary directory and initialise database
#' temp_dir <- tempdir()
#' data_path <- file.path(temp_dir, "boilerplate_standardise_example", "data")
#'
#' # Initialise database
#' boilerplate_init(
#'   categories = "measures",
#'   data_path = data_path,
#'   create_dirs = TRUE,
#'   create_empty = FALSE,
#'   confirm = FALSE,
#'   quiet = TRUE
#' )
#'
#' # Import database
#' unified_db <- boilerplate_import(data_path = data_path, quiet = TRUE)
#'
#' # Standardise all measures in database
#' unified_db$measures <- boilerplate_standardise_measures(
#'   unified_db$measures,
#'   quiet = TRUE
#' )
#'
#' # Standardise with JSON compatibility
#' unified_db$measures <- boilerplate_standardise_measures(
#'   unified_db$measures,
#'   json_compatible = TRUE,
#'   quiet = TRUE
#' )
#'
#' # Check that standardisation worked
#' names(unified_db$measures$anxiety)
#'
#' # Standardise specific measures only
#' unified_db$measures <- boilerplate_standardise_measures(
#'   unified_db$measures,
#'   measure_names = c("anxiety", "depression"),
#'   quiet = TRUE
#' )
#'
#' # Clean up
#' unlink(file.path(temp_dir, "boilerplate_standardise_example"), recursive = TRUE)
#'
#' @importFrom cli cli_alert_info cli_alert_success cli_alert_warning
#' @export
boilerplate_standardise_measures <- function(
  db,
    measure_names = NULL,
    extract_scale = TRUE,
    identify_reversed = TRUE,
    clean_descriptions = TRUE,
    ensure_structure = TRUE,
    standardise_references = TRUE,
    json_compatible = FALSE,
    verbose = FALSE,
    quiet = FALSE
) {

  # Helper function to check if input is a single measure
  is_single_measure <- function(x) {
    if (!is.list(x)) return(FALSE)
    # Check for measure-like fields
    measure_fields <- c("name", "description", "reference", "items", "waves", "keywords")
    return(any(names(x) %in% measure_fields))
  }

  # Helper function to standardise a single measure
  standardise_single_measure <- function(measure, measure_name = NULL) {
    if (verbose && !quiet) cli_alert_info("Standardising measure: {measure_name}")

    # Ensure standard structure
    if (ensure_structure) {
      standard_fields <- c("name", "description", "reference", "items", "waves", "keywords")
      for (field in standard_fields) {
        if (!(field %in% names(measure))) {
          measure[[field]] <- NULL
        }
      }
    }

    # Ensure name field matches the key
    if (!is.null(measure_name) && (is.null(measure$name) || measure$name != measure_name)) {
      measure$name <- measure_name
    }

    # Extract scale information
    if (extract_scale && !is.null(measure$description)) {
      scale_patterns <- list(
        ordinal = "(?i)(ordinal response|ordinal scale|scale)\\s*:?\\s*\\(([^)]+)\\)",
        response = "(?i)(response format|response options?|response scale)\\s*:?\\s*\\(([^)]+)\\)",
        likert = "(?i)(\\d+)\\s*[-]\\s*point\\s+(likert\\s+)?scale",
        range = "(?i)\\((\\d+)\\s*=\\s*[^,]+,?\\s*\\.+\\s*(\\d+)\\s*=\\s*[^)]+\\)"
      )

      for (pattern_name in names(scale_patterns)) {
        pattern <- scale_patterns[[pattern_name]]
        if (grepl(pattern, measure$description, perl = TRUE)) {
          # Extract the scale info
          scale_match <- regmatches(measure$description,
                                    regexpr(pattern, measure$description, perl = TRUE))

          if (length(scale_match) > 0) {
            # Parse scale information
            if (pattern_name %in% c("ordinal", "response")) {
              scale_text <- gsub(pattern, "\\2", scale_match, perl = TRUE)
              measure$scale_info <- trimws(scale_text)

              # Try to extract anchors
              anchor_pattern <- "(\\d+)\\s*=\\s*([^,;]+)"
              anchors <- gregexpr(anchor_pattern, scale_text, perl = TRUE)
              if (anchors[[1]][1] != -1) {
                measure$scale_anchors <- regmatches(scale_text, anchors)[[1]]
              }
            } else if (pattern_name == "likert") {
              points <- as.numeric(gsub(pattern, "\\1", scale_match, perl = TRUE))
              measure$scale_points <- points
              measure$scale_type <- "Likert"
            }

            # Remove scale info from description to avoid duplication
            measure$description <- trimws(gsub(pattern, "", measure$description, perl = TRUE))

            # Clean up empty description
            if (measure$description == "") {
              measure$description <- NULL
            }

            break  # Use first matching pattern only
          }
        }
      }
    }

    # Identify reversed items
    if (identify_reversed && !is.null(measure$items)) {
      reversed_items <- c()

      for (i in seq_along(measure$items)) {
        item_text <- measure$items[[i]]

        # Check for reversed indicators
        reversed_patterns <- c(
          "\\(reversed\\s*(scored)?\\s*\\)",
          "\\(r\\)",
          "\\breversed\\b"
        )

        for (pattern in reversed_patterns) {
          if (grepl(pattern, item_text, ignore.case = TRUE)) {
            reversed_items <- c(reversed_items, i)
            break
          }
        }
      }

      # Add reversed items field if any found
      if (length(reversed_items) > 0) {
        measure$reversed_items <- reversed_items
      }

      # Note: We're keeping the (r) markers in the text for clarity
    }

    # Clean descriptions
    if (clean_descriptions && !is.null(measure$description)) {
      # Remove extra whitespace
      measure$description <- trimws(gsub("\\s+", " ", measure$description))

      # Remove double periods or period before colon (common errors)
      measure$description <- gsub("\\.\\.", ".", measure$description)
      measure$description <- gsub("\\.:", ":", measure$description)
      measure$description <- gsub(":\\.", ":", measure$description)

      # Don't add punctuation if description will have a reference appended
      # The generate function will handle this properly

      # Capitalise first letter
      measure$description <- paste0(
        toupper(substr(measure$description, 1, 1)),
        substr(measure$description, 2, nchar(measure$description))
      )
    }

    # Standardise references
    if (standardise_references && !is.null(measure$reference)) {
      # Remove common prefixes
      measure$reference <- gsub("^@", "", measure$reference)
      measure$reference <- trimws(measure$reference)

      # Ensure lowercase for consistency (typical bibtex style)
      # But preserve camelCase within the reference
      if (!grepl("[A-Z]", substr(measure$reference, 2, nchar(measure$reference)))) {
        measure$reference <- tolower(measure$reference)
      }
    }

    # Standardise waves
    if (!is.null(measure$waves) && measure$waves == "") {
      measure$waves <- NULL
    }

    # Standardise keywords
    if (!is.null(measure$keywords)) {
      # If keywords is a named vector, extract just the values
      if (!is.null(names(measure$keywords))) {
        measure$keywords <- unname(measure$keywords)
      }

      # Ensure it's a character vector
      measure$keywords <- as.character(measure$keywords)

      # Remove empty keywords
      measure$keywords <- measure$keywords[measure$keywords != ""]

      # If no keywords left, set to NULL
      if (length(measure$keywords) == 0) {
        measure$keywords <- NULL
      }
    }

    # Add metadata about standardisation
    measure$standardised <- TRUE
    measure$standardised_date <- Sys.Date()

    # Ensure JSON compatibility if requested
    if (json_compatible) {
      # Convert vectors to lists for JSON arrays
      if (!is.null(measure$values) && !is.list(measure$values)) {
        measure$values <- as.list(measure$values)
      }
      if (!is.null(measure$keywords) && !is.list(measure$keywords)) {
        measure$keywords <- as.list(measure$keywords)
      }
      if (!is.null(measure$waves) && !is.list(measure$waves)) {
        measure$waves <- as.list(measure$waves)
      }
      if (!is.null(measure$reversed_items) && !is.list(measure$reversed_items)) {
        measure$reversed_items <- as.list(measure$reversed_items)
      }

      # Remove NULL values if needed for cleaner JSON
      measure <- measure[!sapply(measure, is.null)]
    }

    return(measure)
  }

  # Main function logic
  if (is_single_measure(db)) {
    # Process single measure
    if (!quiet) cli_alert_info("Standardising single measure")
    result <- standardise_single_measure(db)
    if (!quiet) cli_alert_success("Standardisation complete")
    return(result)
  } else {
    # Process database of measures
    if (!is.list(db)) {
      stop("Input must be a list (either a single measure or a measures database)")
    }

    # Determine which measures to process
    if (is.null(measure_names)) {
      measure_names <- names(db)
      if (!quiet) cli_alert_info("Standardising all {length(measure_names)} measures")
    } else {
      # Validate measure names
      invalid_names <- setdiff(measure_names, names(db))
      if (length(invalid_names) > 0) {
        cli_alert_warning("Measures not found: {paste(invalid_names, collapse = ', ')}")
        measure_names <- intersect(measure_names, names(db))
      }
      if (!quiet) cli_alert_info("Standardising {length(measure_names)} selected measures")
    }

    # Process each measure
    for (name in measure_names) {
      db[[name]] <- standardise_single_measure(db[[name]], name)
    }

    if (!quiet) cli_alert_success("Standardised {length(measure_names)} measures")

    # Sort database alphabetically for consistency
    db <- db[order(names(db))]

    return(db)
  }
}

#' Report on Measure Database Quality
#'
#' Analyses a measures database and reports on completeness and consistency.
#'
#' @param db List. Measures database to analyse.
#' @param measure_names Character vector. Specific measures to analyse. If NULL, analyses all.
#' @param return_report Logical. If TRUE, returns a data frame report. Default is FALSE.
#'
#' @return If return_report is TRUE, returns a data frame with quality metrics.
#'
#' @examples
#' \donttest{
#' # Create temporary directory for example
#' temp_dir <- tempfile()
#' dir.create(temp_dir)
#'
#' # Initialise and import
#' boilerplate_init(data_path = temp_dir, categories = "measures",
#'                  create_dirs = TRUE, confirm = FALSE, quiet = TRUE)
#' unified_db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)
#'
#' # Get a quality report
#' report <- boilerplate_measures_report(unified_db$measures, return_report = TRUE)
#'
#' # Just print summary
#' boilerplate_measures_report(unified_db$measures)
#'
#' # Clean up
#' unlink(temp_dir, recursive = TRUE)
#' }
#'
#' @export
boilerplate_measures_report <- function(db, measure_names = NULL, return_report = FALSE) {
  if (is.null(measure_names)) {
    measure_names <- names(db)
  }

  report <- data.frame(
    measure = character(),
    has_description = logical(),
    has_reference = logical(),
    has_items = logical(),
    n_items = integer(),
    has_waves = logical(),
    has_keywords = logical(),
    has_scale_info = logical(),
    has_reversed = logical(),
    is_standardised = logical(),
    stringsAsFactors = FALSE
  )

  for (name in measure_names) {
    measure <- db[[name]]
    if (!is.null(measure)) {
      report <- rbind(report, data.frame(
        measure = name,
        has_description = !is.null(measure$description) && measure$description != "",
        has_reference = !is.null(measure$reference) && measure$reference != "",
        has_items = !is.null(measure$items) && length(measure$items) > 0,
        n_items = if (!is.null(measure$items)) length(measure$items) else 0,
        has_waves = !is.null(measure$waves) && measure$waves != "",
        has_keywords = !is.null(measure$keywords) && length(measure$keywords) > 0,
        has_scale_info = !is.null(measure$scale_info) || !is.null(measure$scale_points),
        has_reversed = !is.null(measure$reversed_items),
        is_standardised = isTRUE(measure$standardised),
        stringsAsFactors = FALSE
      ))
    }
  }

  # Print summary
  cat("\n=== Measures Database Quality Report ===\n")
  cat(sprintf("Total measures: %d\n", nrow(report)))
  cat(sprintf("Complete descriptions: %d (%.1f%%)\n",
              sum(report$has_description),
              100 * mean(report$has_description)))
  cat(sprintf("With references: %d (%.1f%%)\n",
              sum(report$has_reference),
              100 * mean(report$has_reference)))
  cat(sprintf("With items: %d (%.1f%%)\n",
              sum(report$has_items),
              100 * mean(report$has_items)))
  cat(sprintf("With wave info: %d (%.1f%%)\n",
              sum(report$has_waves),
              100 * mean(report$has_waves)))
  cat(sprintf("Already standardised: %d (%.1f%%)\n",
              sum(report$is_standardised),
              100 * mean(report$is_standardised)))

  if (return_report) {
    return(report)
  }
}
