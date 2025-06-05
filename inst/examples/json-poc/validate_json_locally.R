# Local JSON Validation Script
# Run this before committing changes to ensure JSON is valid

library(jsonlite)
library(cli)

#' Validate Boilerplate JSON Files Locally
#'
#' @param json_path Path to JSON file or directory containing JSON files
#' @param verbose Show detailed validation messages?
#' @return Logical indicating if all validations passed
validate_boilerplate_json <- function(json_path, verbose = TRUE) {
  
  all_valid <- TRUE
  
  # Get all JSON files
  if (dir.exists(json_path)) {
    json_files <- list.files(json_path, pattern = "\\.json$", full.names = TRUE, recursive = TRUE)
  } else if (file.exists(json_path)) {
    json_files <- json_path
  } else {
    cli_alert_danger("Path not found: {json_path}")
    return(FALSE)
  }
  
  if (verbose) cli_h1("Validating {length(json_files)} JSON file{?s}")
  
  for (file in json_files) {
    if (verbose) cli_h2("Checking {basename(file)}")
    
    # 1. Check JSON syntax
    tryCatch({
      db <- read_json(file)
      if (verbose) cli_alert_success("Valid JSON syntax")
    }, error = function(e) {
      cli_alert_danger("Invalid JSON syntax: {e$message}")
      all_valid <<- FALSE
      next
    })
    
    # 2. Check structure based on filename
    file_type <- detect_file_type(basename(file))
    
    if (file_type == "unified") {
      validation_result <- validate_unified_structure(db, verbose)
    } else if (file_type == "measures") {
      validation_result <- validate_measures_structure(db, verbose)
    } else if (file_type == "methods") {
      validation_result <- validate_methods_structure(db, verbose)
    } else {
      validation_result <- validate_generic_structure(db, verbose)
    }
    
    if (!validation_result) all_valid <- FALSE
    
    # 3. Check for common issues
    issues <- check_common_issues(db)
    if (length(issues) > 0) {
      all_valid <- FALSE
      if (verbose) {
        cli_alert_warning("Found {length(issues)} potential issue{?s}:")
        for (issue in issues) {
          cli_bullets(c("!" = issue))
        }
      }
    }
  }
  
  if (verbose) {
    if (all_valid) {
      cli_alert_success("All validations passed!")
    } else {
      cli_alert_danger("Validation failed - please fix issues before committing")
    }
  }
  
  return(all_valid)
}

# Helper functions
detect_file_type <- function(filename) {
  if (grepl("unified", filename, ignore.case = TRUE)) return("unified")
  if (grepl("measures", filename, ignore.case = TRUE)) return("measures")
  if (grepl("methods", filename, ignore.case = TRUE)) return("methods")
  if (grepl("results", filename, ignore.case = TRUE)) return("results")
  if (grepl("discussion", filename, ignore.case = TRUE)) return("discussion")
  return("generic")
}

validate_unified_structure <- function(db, verbose) {
  valid <- TRUE
  expected_categories <- c("methods", "results", "discussion", "measures", "appendix", "template")
  
  # Check for expected categories
  db_categories <- names(db)[!grepl("^_", names(db))]
  missing <- setdiff(expected_categories, db_categories)
  
  if (length(missing) > 0 && verbose) {
    cli_alert_info("Missing categories: {paste(missing, collapse = ', ')}")
  }
  
  # Validate each category
  for (cat in db_categories) {
    if (!is.list(db[[cat]])) {
      cli_alert_danger("{cat} should be a list/object")
      valid <- FALSE
    }
  }
  
  if (verbose && valid) cli_alert_success("Valid unified structure")
  return(valid)
}

validate_measures_structure <- function(db, verbose) {
  valid <- TRUE
  
  check_measure <- function(measure, path) {
    issues <- character()
    
    # Required fields
    required <- c("name", "description", "type")
    missing <- setdiff(required, names(measure))
    if (length(missing) > 0) {
      issues <- c(issues, sprintf("%s missing required fields: %s", 
                                  path, paste(missing, collapse = ", ")))
    }
    
    # Check type validity
    if ("type" %in% names(measure)) {
      valid_types <- c("continuous", "categorical", "ordinal", "binary")
      if (!measure$type %in% valid_types) {
        issues <- c(issues, sprintf("%s has invalid type: %s", path, measure$type))
      }
    }
    
    # Check value consistency
    if ("values" %in% names(measure) && "value_labels" %in% names(measure)) {
      if (length(measure$values) != length(measure$value_labels)) {
        issues <- c(issues, sprintf("%s: values and value_labels have different lengths", path))
      }
    }
    
    return(issues)
  }
  
  # Recursively check all measures
  all_issues <- character()
  
  check_recursive <- function(obj, path = "") {
    if (is.list(obj)) {
      # Check if this is a measure (has required fields)
      if (any(c("name", "description", "type") %in% names(obj))) {
        issues <- check_measure(obj, path)
        all_issues <<- c(all_issues, issues)
      } else {
        # It's a category, check children
        for (name in names(obj)) {
          if (!grepl("^_", name)) {
            check_recursive(obj[[name]], paste0(path, "/", name))
          }
        }
      }
    }
  }
  
  check_recursive(db)
  
  if (length(all_issues) > 0) {
    valid <- FALSE
    if (verbose) {
      for (issue in all_issues) {
        cli_alert_danger(issue)
      }
    }
  } else if (verbose) {
    cli_alert_success("Valid measures structure")
  }
  
  return(valid)
}

validate_methods_structure <- function(db, verbose) {
  valid <- TRUE
  
  check_method <- function(method, path) {
    issues <- character()
    
    # Should have either 'text' or 'default'
    if (!any(c("text", "default") %in% names(method))) {
      issues <- c(issues, sprintf("%s missing 'text' or 'default' field", path))
    }
    
    # Check for template variables
    text_fields <- c("text", "default", "large", "brief")
    for (field in text_fields) {
      if (field %in% names(method) && is.character(method[[field]])) {
        # Check for unclosed template variables
        text <- method[[field]]
        open_count <- lengths(regmatches(text, gregexpr("\\{\\{", text)))
        close_count <- lengths(regmatches(text, gregexpr("\\}\\}", text)))
        
        if (open_count != close_count) {
          issues <- c(issues, sprintf("%s has unclosed template variables in '%s'", path, field))
        }
      }
    }
    
    return(issues)
  }
  
  # Check all methods recursively
  all_issues <- character()
  
  check_recursive <- function(obj, path = "") {
    if (is.list(obj)) {
      # Check if this is a method entry
      if (any(c("text", "default") %in% names(obj))) {
        issues <- check_method(obj, path)
        all_issues <<- c(all_issues, issues)
      } else {
        # Check children
        for (name in names(obj)) {
          if (!grepl("^_", name)) {
            check_recursive(obj[[name]], paste0(path, "/", name))
          }
        }
      }
    }
  }
  
  check_recursive(db)
  
  if (length(all_issues) > 0) {
    valid <- FALSE
    if (verbose) {
      for (issue in all_issues) {
        cli_alert_danger(issue)
      }
    }
  } else if (verbose) {
    cli_alert_success("Valid methods structure")
  }
  
  return(valid)
}

validate_generic_structure <- function(db, verbose) {
  # Basic validation for other types
  if (!is.list(db)) {
    if (verbose) cli_alert_danger("Database should be a list/object")
    return(FALSE)
  }
  
  if (verbose) cli_alert_success("Valid generic structure")
  return(TRUE)
}

check_common_issues <- function(db) {
  issues <- character()
  
  check_recursive <- function(obj, path = "") {
    if (is.list(obj)) {
      for (name in names(obj)) {
        current_path <- if (path == "") name else paste0(path, "/", name)
        
        # Check for potentially problematic names
        if (grepl("[^a-zA-Z0-9_.-]", name)) {
          issues <<- c(issues, sprintf("Path '%s' contains special characters", current_path))
        }
        
        # Check for very long text fields
        if (is.character(obj[[name]]) && length(obj[[name]]) == 1) {
          if (nchar(obj[[name]]) > 5000) {
            issues <<- c(issues, sprintf("Very long text at '%s' (%d chars)", 
                                       current_path, nchar(obj[[name]])))
          }
        }
        
        # Recurse
        if (is.list(obj[[name]])) {
          check_recursive(obj[[name]], current_path)
        }
      }
    }
  }
  
  check_recursive(db)
  return(issues)
}

# Run validation if script is sourced directly
if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) > 0) {
    path <- args[1]
    valid <- validate_boilerplate_json(path, verbose = TRUE)
    quit(status = if (valid) 0 else 1)
  } else {
    cli_alert_info("Usage: Rscript validate_json_locally.R <path_to_json>")
  }
} else {
  # Interactive usage example
  cli_h1("Boilerplate JSON Validator")
  cli_alert_info("Usage: validate_boilerplate_json('path/to/json')")
  cli_alert_info("Returns TRUE if all validations pass")
}