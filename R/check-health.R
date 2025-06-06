#' Check Database Health
#'
#' Performs comprehensive health checks on a boilerplate database to identify
#' potential issues such as orphaned variables, empty entries, and structural problems.
#' Can optionally generate a detailed report.
#'
#' @param db List. The database to check (can be unified or single category).
#' @param fix Logical. If TRUE, attempts to fix issues where possible. Default FALSE.
#' @param report Character or NULL. If a file path is provided, saves a detailed report.
#'   If "text", returns the report as a character string. If NULL (default), returns
#'   the health check object.
#' @param quiet Logical. If TRUE, suppresses non-critical messages. Default FALSE.
#'
#' @return Depends on the `report` parameter:
#'   - If `report = NULL`: A list with class "boilerplate_health" containing summary,
#'     issues, stats, and fixed items
#'   - If `report = "text"`: A character string containing the detailed report
#'   - If `report` is a file path: Invisibly returns the file path after saving report
#'
#' @examples
#' \dontrun{
#' # Check database health
#' health <- boilerplate_check_health(db)
#' print(health)
#'
#' # Generate text report
#' report_text <- boilerplate_check_health(db, report = "text")
#' cat(report_text)
#'
#' # Save report to file
#' boilerplate_check_health(db, report = "health_report.txt")
#'
#' # Check and fix issues
#' health <- boilerplate_check_health(db, fix = TRUE)
#'
#' # Get the fixed database
#' if (health$summary$issues_fixed > 0) {
#'   db <- attr(health, "fixed_db")
#' }
#' }
#'
#' @export
boilerplate_check_health <- function(db, fix = FALSE, report = NULL, quiet = FALSE) {
  if (!quiet) cli::cli_alert_info("Checking database health...")

  # Initialise results
  issues <- list()
  stats <- list(
    total_entries = 0,
    total_categories = 0,
    total_variables = 0,
    documented_variables = 0
  )
  fixed_items <- list(
    removed_empty = character(0)
  )

  # Detect if unified or single category
  is_unified <- any(c("methods", "measures", "results", "discussion", "appendix", "template") %in% names(db))

  # Get all paths
  all_paths <- boilerplate_list_paths(db)
  stats$total_entries <- length(all_paths)

  if (is_unified) {
    stats$total_categories <- sum(c("methods", "measures", "results", "discussion", "appendix", "template") %in% names(db))
  }

  # Check 1: Empty or NULL entries
  empty_entries <- character(0)
  for (path in all_paths) {
    # Skip if path was already removed
    if (fix && path %in% fixed_items$removed_empty) next

    entry <- tryCatch(
      boilerplate_get_entry(db, path),
      error = function(e) NULL
    )

    if (is.null(entry) ||
        (is.character(entry) && length(entry) == 1 && nchar(trimws(entry)) == 0) ||
        (is.list(entry) && length(entry) == 0)) {
      empty_entries <- c(empty_entries, path)

      if (fix) {
        # Remove empty entries
        db <- boilerplate_remove_entry(db, path)
        fixed_items$removed_empty <- c(fixed_items$removed_empty, path)
      }
    }
  }

  if (length(empty_entries) > 0) {
    issues$empty_entries <- list(
      type = "warning",
      message = "Empty or NULL entries found",
      count = length(empty_entries),
      paths = empty_entries
    )
  }

  # Check 2: Orphaned template variables
  all_vars <- list()
  orphaned_vars <- list()

  # Get updated paths if fixes were applied
  paths_to_check <- if (fix && length(fixed_items$removed_empty) > 0) {
    setdiff(all_paths, fixed_items$removed_empty)
  } else {
    all_paths
  }

  for (path in paths_to_check) {
    # Skip .text paths if the parent has already been processed
    # This avoids double-counting variables in entries that have a text field
    if (grepl("\\.text$", path)) {
      parent_path <- sub("\\.text$", "", path)
      if (parent_path %in% paths_to_check) {
        parent_entry <- tryCatch(
          boilerplate_get_entry(db, parent_path),
          error = function(e) NULL
        )
        if (is.list(parent_entry) && !is.null(parent_entry$text)) {
          next  # Skip this .text path since parent will handle it
        }
      }
    }

    entry <- tryCatch(
      boilerplate_get_entry(db, path),
      error = function(e) NULL
    )

    if (is.null(entry)) next

    # Extract text content
    text_content <- NULL
    if (is.character(entry)) {
      text_content <- entry
    } else if (is.list(entry)) {
      if (!is.null(entry$text)) text_content <- entry$text
      else if (!is.null(entry$description)) text_content <- entry$description
      else if (!is.null(entry$default)) text_content <- entry$default
    }

    if (!is.null(text_content)) {
      vars <- extract_template_variables(text_content)
      if (length(vars) > 0) {
        stats$total_variables <- stats$total_variables + length(vars)

        # For now, all variables are considered orphaned/undocumented
        # unless we have a more sophisticated variable documentation system
        stats$documented_variables <- stats$documented_variables + 0

        if (length(vars) > 0) {
          orphaned_vars[[path]] <- vars
        }

        for (var in vars) {
          all_vars[[var]] <- c(all_vars[[var]], path)
        }
      }
    }
  }

  if (length(orphaned_vars) > 0) {
    issues$orphaned_variables <- list(
      type = "info",
      message = "Template variables without documentation",
      count = sum(lengths(orphaned_vars)),
      details = orphaned_vars
    )
  }

  # Check 3: Duplicate content
  content_hashes <- list()
  duplicates <- list()

  for (path in paths_to_check) {
    entry <- tryCatch(
      boilerplate_get_entry(db, path),
      error = function(e) NULL
    )

    if (is.null(entry)) next

    # Get content for hashing
    content <- NULL
    if (is.character(entry)) {
      content <- entry
    } else if (is.list(entry) && !is.null(entry$text)) {
      content <- entry$text
    } else if (is.list(entry) && !is.null(entry$description)) {
      content <- entry$description
    }

    if (!is.null(content) && length(content) == 1 && nchar(content) > 0) {
      # Create hash of content
      hash <- digest::digest(content, algo = "md5", serialize = FALSE)

      if (hash %in% names(content_hashes)) {
        # Found duplicate
        duplicates[[hash]] <- c(content_hashes[[hash]], path)
      } else {
        content_hashes[[hash]] <- path
      }
    }
  }

  # Only report duplicates with more than one path
  duplicates <- duplicates[lengths(duplicates) > 1]

  if (length(duplicates) > 0) {
    issues$duplicate_content <- list(
      type = "info",
      message = "Duplicate content found across paths",
      count = length(duplicates),
      groups = duplicates
    )
  }

  # Check 4: Measure structure consistency
  if (is_unified && "measures" %in% names(db)) {
    measures_issues <- check_measures_consistency(db$measures, stats)
    issues <- c(issues, measures_issues)
  } else if (!is_unified && any(grepl("^(name|description|items|scale|reference)$", names(db)))) {
    # This might be a measures database
    measures_issues <- check_measures_consistency(db, stats)
    issues <- c(issues, measures_issues)
  }

  # Check 5: Path naming conventions
  invalid_paths <- character(0)
  for (path in paths_to_check) {
    # Check for invalid characters or patterns
    if (grepl("[^a-zA-Z0-9._-]", path) ||
        grepl("\\.\\.+", path) ||  # Multiple dots
        startsWith(path, ".") ||
        endsWith(path, ".")) {
      invalid_paths <- c(invalid_paths, path)
    }
  }

  if (length(invalid_paths) > 0) {
    issues$invalid_paths <- list(
      type = "warning",
      message = "Paths with invalid naming conventions",
      count = length(invalid_paths),
      paths = invalid_paths
    )
  }

  # Create summary
  summary <- list(
    healthy = length(issues) == 0,
    total_issues = length(issues),
    warnings = if (length(issues) > 0) sum(sapply(issues, function(x) if (!is.null(x) && !is.null(x$type)) x$type == "warning" else FALSE)) else 0,
    info = if (length(issues) > 0) sum(sapply(issues, function(x) if (!is.null(x) && !is.null(x$type)) x$type == "info" else FALSE)) else 0,
    database_stats = stats
  )

  if (fix && length(fixed_items) > 0) {
    summary$issues_fixed <- sum(lengths(fixed_items))

    if (!quiet) {
      cli::cli_alert_success("Fixed {summary$issues_fixed} issue{?s}")
    }
  }

  # Create result object
  result <- list(
    summary = summary,
    issues = issues,
    stats = stats,
    fixed = if (fix) fixed_items else NULL,
    checked_at = Sys.time()
  )

  class(result) <- c("boilerplate_health", "list")

  # Attach fixed database if fixes were made
  if (fix && length(fixed_items) > 0) {
    attr(result, "fixed_db") <- db
  }

  if (!quiet) {
    if (summary$healthy) {
      cli::cli_alert_success("Database is healthy!")
    } else {
      cli::cli_alert_warning("Found {summary$total_issues} issue{?s} ({summary$warnings} warning{?s}, {summary$info} info)")
    }
  }

  # Handle report generation if requested
  if (!is.null(report)) {
    # Generate the report text
    report_lines <- utils::capture.output(print(result))

    # Add detailed information
    report_lines <- c(report_lines, "", "Detailed Issue Information", "=========================", "")

    # Add all orphaned variables
    if (!is.null(issues$orphaned_variables)) {
      report_lines <- c(report_lines, "All Undocumented Variables:", "")

      vars_by_name <- list()
      for (path in names(issues$orphaned_variables$details)) {
        for (var in issues$orphaned_variables$details[[path]]) {
          vars_by_name[[var]] <- c(vars_by_name[[var]], path)
        }
      }

      for (var in sort(names(vars_by_name))) {
        report_lines <- c(report_lines,
                    sprintf("  {{%s}} used in %d location%s:",
                            var, length(vars_by_name[[var]]),
                            ifelse(length(vars_by_name[[var]]) > 1, "s", "")))
        for (path in vars_by_name[[var]]) {
          report_lines <- c(report_lines, paste0("    - ", path))
        }
        report_lines <- c(report_lines, "")
      }
    }

    # Join report lines
    report_text <- paste(report_lines, collapse = "\n")

    if (report == "text") {
      return(report_text)
    } else {
      # Save to file
      writeLines(report_text, report)
      if (!quiet) cli::cli_alert_success("Health report saved to {report}")
      return(invisible(report))
    }
  }

  result
}

#' Print Method for Database Health Check
#'
#' @param x A boilerplate_health object
#' @param ... Additional arguments (ignored)
#'
#' @keywords internal
#' @export
print.boilerplate_health <- function(x, ...) {
  cat("\nDatabase Health Report\n")
  cat("======================\n")
  cat("Checked at:", format(x$checked_at, "%Y-%m-%d %H:%M:%S"), "\n\n")

  # Summary
  cat("Summary\n")
  cat("-------\n")
  cat("Status:", ifelse(x$summary$healthy, "\u2713 HEALTHY", "\u26a0 ISSUES FOUND"), "\n")
  cat("Total entries:", x$stats$total_entries, "\n")
  if (x$stats$total_categories > 0) {
    cat("Categories:", x$stats$total_categories, "\n")
  }
  cat("Template variables:", x$stats$total_variables, "\n")
  cat("Documented variables:", x$stats$documented_variables,
      sprintf("(%.1f%%)", 100 * x$stats$documented_variables / max(x$stats$total_variables, 1)), "\n")

  if (x$summary$total_issues > 0) {
    cat("\nIssues Found\n")
    cat("------------\n")

    for (issue_name in names(x$issues)) {
      issue <- x$issues[[issue_name]]

      # Format issue name
      formatted_name <- gsub("_", " ", issue_name)
      formatted_name <- tools::toTitleCase(formatted_name)

      cat("\n", issue$type, ": ", formatted_name, " (", issue$count, ")\n", sep = "")
      cat("  ", issue$message, "\n", sep = "")

      # Show details based on issue type
      if (issue_name == "empty_entries" && length(issue$paths) <= 5) {
        cat("  Paths:\n")
        for (path in issue$paths) {
          cat("    - ", path, "\n", sep = "")
        }
      } else if (issue_name == "orphaned_variables" && length(issue$details) <= 5) {
        for (path in names(issue$details)[1:min(5, length(issue$details))]) {
          cat("    ", path, ": ", paste(issue$details[[path]], collapse = ", "), "\n", sep = "")
        }
        if (length(issue$details) > 5) {
          cat("    ... and ", length(issue$details) - 5, " more paths\n", sep = "")
        }
      } else if (issue_name == "duplicate_content" && length(issue$groups) <= 3) {
        for (i in seq_along(issue$groups)[1:min(3, length(issue$groups))]) {
          cat("    Group ", i, ": ", paste(issue$groups[[i]], collapse = ", "), "\n", sep = "")
        }
      }
    }
  }

  if (!is.null(x$fixed) && length(x$fixed) > 0) {
    cat("\nFixed Issues\n")
    cat("------------\n")
    cat("Total fixes applied:", x$summary$issues_fixed, "\n")

    if (!is.null(x$fixed$removed_empty)) {
      cat("  Removed empty entries:", length(x$fixed$removed_empty), "\n")
    }
  }

  cat("\n")
  invisible(x)
}

#' Check Measures Database Consistency
#'
#' Internal function to check consistency of measures entries.
#'
#' @param measures_db The measures database or section
#' @param stats List to update statistics
#' @return List of issues found
#'
#' @keywords internal
#' @noRd
check_measures_consistency <- function(measures_db, stats) {
  issues <- list()
  required_fields <- c("name", "description")
  recommended_fields <- c("type", "items", "reference")

  incomplete_measures <- list()
  inconsistent_measures <- list()

  measure_names <- names(measures_db)

  for (measure_name in measure_names) {
    measure <- measures_db[[measure_name]]

    if (!is.list(measure)) next

    # Check required fields
    missing_required <- setdiff(required_fields, names(measure))
    if (length(missing_required) > 0) {
      incomplete_measures[[measure_name]] <- missing_required
    }

    # Check if items is properly formatted
    if (!is.null(measure$items)) {
      if (!is.list(measure$items) && !is.character(measure$items)) {
        inconsistent_measures[[measure_name]] <- c(inconsistent_measures[[measure_name]],
                                                   "items should be a list or character vector")
      }
    }

    # Check type field
    if (!is.null(measure$type)) {
      valid_types <- c("continuous", "categorical", "ordinal", "binary", "text")
      if (!measure$type %in% valid_types) {
        inconsistent_measures[[measure_name]] <- c(inconsistent_measures[[measure_name]],
                                                   paste("invalid type:", measure$type))
      }
    }
  }

  if (length(incomplete_measures) > 0) {
    issues$incomplete_measures <- list(
      type = "warning",
      message = "Measures missing required fields",
      count = length(incomplete_measures),
      details = incomplete_measures
    )
  }

  if (length(inconsistent_measures) > 0) {
    issues$inconsistent_measures <- list(
      type = "warning",
      message = "Measures with structural issues",
      count = length(inconsistent_measures),
      details = inconsistent_measures
    )
  }

  stats$total_measures <- length(measure_names)
  stats$complete_measures <- length(measure_names) - length(incomplete_measures)

  return(issues)
}

