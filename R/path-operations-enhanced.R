#' Enhanced Path-Based Database Operations with Variable Documentation
#'
#' These functions extend the basic path operations to support template variable
#' documentation, making it easier to track what variables are needed for each template.
#'
#' @name boilerplate_path_ops_enhanced
#' @keywords internal
NULL

#' Add Entry with Variable Documentation
#'
#' Adds an entry to the database with optional documentation for template variables.
#' Variables in the format \{\{variable_name\}\} can be documented for clarity.
#'
#' @param db List. The database to modify.
#' @param path Character. Dot-separated path (e.g., "methods.sampling.online").
#' @param value Character or list. The content to add. If character, can contain
#'   \{\{variable\}\} placeholders.
#' @param variables Named list. Optional documentation for template variables.
#'   Names should match variable names in the template (without braces).
#'   Values should be descriptions of what each variable represents.
#' @param auto_sort Logical. Whether to auto-sort at each level. Default TRUE.
#'
#' @return Modified database with the new entry.
#'
#' @examples
#' \dontrun{
#' db <- boilerplate_add_entry_enhanced(
#'   db,
#'   path = "methods.sampling.online",
#'   value = "We recruited {{n_total}} participants from {{platform}}.",
#'   variables = list(
#'     n_total = "Total sample size (integer)",
#'     platform = "Recruitment platform name (e.g., 'MTurk', 'Prolific')"
#'   )
#' )
#' }
#'
#' @export
boilerplate_add_entry_enhanced <- function(db, path, value, variables = NULL, auto_sort = TRUE) {
  # If variables are provided, create an enhanced entry structure
  if (!is.null(variables)) {
    if (is.character(value)) {
      # Extract variables from the template
      template_vars <- extract_template_variables(value)
      
      # Check if documented variables match template variables
      documented_vars <- names(variables)
      missing_vars <- setdiff(template_vars, documented_vars)
      extra_vars <- setdiff(documented_vars, template_vars)
      
      if (length(missing_vars) > 0) {
        warning("Template contains undocumented variables: ", 
                paste(missing_vars, collapse = ", "))
      }
      
      if (length(extra_vars) > 0) {
        warning("Documentation contains variables not in template: ", 
                paste(extra_vars, collapse = ", "))
      }
      
      # Create enhanced structure
      entry_value <- list(
        text = value,
        variables = variables,
        `_meta` = list(
          has_variables = TRUE,
          variable_count = length(template_vars),
          created = Sys.time()
        )
      )
    } else if (is.list(value)) {
      # For list values (like measures), add variables metadata
      value$`_variables` <- variables
      value$`_meta` <- c(value$`_meta`, list(
        has_variables = TRUE,
        documented_variables = names(variables),
        created = Sys.time()
      ))
      entry_value <- value
    } else {
      entry_value <- value
    }
  } else {
    entry_value <- value
  }
  
  # Use existing function to add the entry
  path_parts <- strsplit(path, "\\.")[[1]]
  modify_nested_entry(db, path_parts, "add", entry_value, auto_sort)
}

#' Update Entry with Variable Documentation
#'
#' Updates an existing entry and its variable documentation.
#'
#' @inheritParams boilerplate_add_entry_enhanced
#'
#' @export
boilerplate_update_entry_enhanced <- function(db, path, value, variables = NULL, auto_sort = TRUE) {
  # Check if entry exists
  if (!boilerplate_path_exists(db, path)) {
    stop("Path '", path, "' does not exist. Use boilerplate_add_entry_enhanced() to create new entries.")
  }
  
  # Get existing entry to preserve any existing metadata
  existing <- boilerplate_get_entry(db, path)
  
  # Handle variable documentation
  if (!is.null(variables)) {
    if (is.character(value)) {
      template_vars <- extract_template_variables(value)
      
      # Check variable consistency
      documented_vars <- names(variables)
      missing_vars <- setdiff(template_vars, documented_vars)
      extra_vars <- setdiff(documented_vars, template_vars)
      
      if (length(missing_vars) > 0) {
        warning("Template contains undocumented variables: ", 
                paste(missing_vars, collapse = ", "))
      }
      
      if (length(extra_vars) > 0) {
        warning("Documentation contains variables not in template: ", 
                paste(extra_vars, collapse = ", "))
      }
      
      entry_value <- list(
        text = value,
        variables = variables,
        `_meta` = list(
          has_variables = TRUE,
          variable_count = length(template_vars),
          updated = Sys.time()
        )
      )
      
      # Preserve creation time if it exists
      if (is.list(existing) && !is.null(existing$`_meta`$created)) {
        entry_value$`_meta`$created <- existing$`_meta`$created
      }
    } else if (is.list(value)) {
      value$`_variables` <- variables
      value$`_meta` <- c(value$`_meta`, list(
        has_variables = TRUE,
        documented_variables = names(variables),
        updated = Sys.time()
      ))
      
      # Preserve creation time
      if (is.list(existing) && !is.null(existing$`_meta`$created)) {
        value$`_meta`$created <- existing$`_meta`$created
      }
      
      entry_value <- value
    } else {
      entry_value <- value
    }
  } else {
    entry_value <- value
  }
  
  path_parts <- strsplit(path, "\\.")[[1]]
  modify_nested_entry(db, path_parts, "update", entry_value, auto_sort)
}

#' Get Template Variables from an Entry
#'
#' Retrieves documented variables and their descriptions from a database entry.
#'
#' @param db List. The database to query.
#' @param path Character. Dot-separated path to the entry.
#'
#' @return A list with:
#'   - `template`: The template text (if applicable)
#'   - `variables`: Named list of variable documentation
#'   - `found_in_template`: Variables found in the template
#'   - `documented`: Variables that have documentation
#'
#' @examples
#' \dontrun{
#' vars <- boilerplate_get_variables(db, "methods.sampling.online")
#' print(vars$variables)
#' }
#'
#' @export
boilerplate_get_variables <- function(db, path) {
  entry <- boilerplate_get_entry(db, path)
  
  result <- list(
    template = NULL,
    variables = NULL,
    found_in_template = character(0),
    documented = character(0)
  )
  
  if (is.character(entry)) {
    # Simple text entry
    result$template <- entry
    result$found_in_template <- extract_template_variables(entry)
  } else if (is.list(entry)) {
    # Enhanced entry with documentation
    if (!is.null(entry$text)) {
      result$template <- entry$text
      result$found_in_template <- extract_template_variables(entry$text)
    }
    
    if (!is.null(entry$variables)) {
      result$variables <- entry$variables
      result$documented <- names(entry$variables)
    } else if (!is.null(entry$`_variables`)) {
      result$variables <- entry$`_variables`
      result$documented <- names(entry$`_variables`)
    }
    
    # For measures, check description field
    if (is.null(result$template) && !is.null(entry$description)) {
      result$template <- entry$description
      result$found_in_template <- extract_template_variables(entry$description)
    }
  }
  
  class(result) <- c("boilerplate_variables", "list")
  result
}

#' Print Method for Variable Documentation
#'
#' @param x A boilerplate_variables object
#' @param ... Additional arguments (ignored)
#'
#' @keywords internal
#' @export
print.boilerplate_variables <- function(x, ...) {
  cat("Template Variables\n")
  cat("==================\n\n")
  
  if (!is.null(x$template)) {
    cat("Template text:\n")
    cat(strwrap(x$template, width = 70, prefix = "  "), sep = "\n")
    cat("\n")
  }
  
  if (length(x$found_in_template) > 0) {
    cat("Variables found in template:\n")
    for (var in x$found_in_template) {
      cat("  - {{", var, "}}", sep = "")
      if (var %in% x$documented && !is.null(x$variables[[var]])) {
        cat(": ", x$variables[[var]], sep = "")
      } else {
        cat(" [UNDOCUMENTED]")
      }
      cat("\n")
    }
  } else {
    cat("No template variables found.\n")
  }
  
  if (length(x$documented) > 0) {
    extra_docs <- setdiff(x$documented, x$found_in_template)
    if (length(extra_docs) > 0) {
      cat("\nDocumented but not in template:\n")
      for (var in extra_docs) {
        cat("  - ", var, ": ", x$variables[[var]], "\n", sep = "")
      }
    }
  }
  
  invisible(x)
}

#' Extract Template Variables from Text
#'
#' Internal function to extract \{\{variable\}\} patterns from text.
#'
#' @param text Character. Text containing template variables.
#' @return Character vector of variable names (without braces).
#'
#' @keywords internal
extract_template_variables <- function(text) {
  if (is.null(text) || !is.character(text)) return(character(0))
  
  # Find all {{variable}} patterns
  matches <- gregexpr("\\{\\{([^}]+)\\}\\}", text, perl = TRUE)
  
  if (matches[[1]][1] == -1) return(character(0))
  
  # Extract variable names
  vars <- character(0)
  for (i in seq_along(matches[[1]])) {
    start <- matches[[1]][i] + 2  # Skip {{
    length <- attr(matches[[1]], "match.length")[i] - 4  # Remove {{ and }}
    vars[i] <- substr(text, start, start + length - 1)
  }
  
  unique(trimws(vars))
}

#' List All Variables in Database
#'
#' Scans the entire database and returns a summary of all template variables.
#'
#' @param db List. The database to scan.
#' @param category Character. Optional category to limit the scan.
#'
#' @return A data frame with columns:
#'   - path: The database path
#'   - variable: The variable name
#'   - documented: Whether the variable has documentation
#'   - description: The variable description (if documented)
#'
#' @export
boilerplate_list_variables <- function(db, category = NULL) {
  # Get all paths
  paths <- boilerplate_list_paths(db)
  
  # Filter by category if specified
  if (!is.null(category)) {
    paths <- paths[startsWith(paths, paste0(category, "."))]
  }
  
  # Collect variable information
  var_info <- list()
  
  for (path in paths) {
    vars <- boilerplate_get_variables(db, path)
    
    if (length(vars$found_in_template) > 0) {
      for (var in vars$found_in_template) {
        var_info[[length(var_info) + 1]] <- data.frame(
          path = path,
          variable = var,
          documented = var %in% vars$documented,
          description = if (var %in% vars$documented) vars$variables[[var]] else NA_character_,
          stringsAsFactors = FALSE
        )
      }
    }
  }
  
  if (length(var_info) == 0) {
    return(data.frame(
      path = character(0),
      variable = character(0),
      documented = logical(0),
      description = character(0),
      stringsAsFactors = FALSE
    ))
  }
  
  result <- do.call(rbind, var_info)
  
  # Sort by variable name, then path
  result[order(result$variable, result$path), ]
}