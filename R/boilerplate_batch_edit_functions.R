#' Batch Edit Fields in boilerplate Database
#'
#' This function allows batch editing of specific fields across multiple entries
#' in a boilerplate database. It supports pattern matching, explicit lists, and
#' various editing operations.
#'
#' @param db List or character. The database to edit (can be a single category or unified database),
#'   or a file path to a JSON/RDS database file which will be loaded automatically.
#' @param field Character. The field to edit (e.g., "reference", "description").
#' @param new_value Character. The new value to set for the field.
#' @param target_entries Character vector. Entries to edit. Can be:
#'   - Specific entry names (e.g., c("ban_hate_speech", "born_nz"))
#'   - Patterns with wildcards (e.g., "anxiety*" matches all entries starting with "anxiety")
#'   - "all" to edit all entries
#'   - NULL to use pattern/value matching
#' @param match_pattern Character. Pattern to match in the current field values.
#'   Only entries with matching values will be updated. Ignored if target_entries is specified.
#' @param match_values Character vector. Specific values to match.
#'   Only entries with these exact values will be updated. Ignored if target_entries is specified.
#' @param category Character. If db is unified, specifies which category to edit
#'   (e.g., "measures", "methods"). If NULL, attempts to detect.
#' @param recursive Logical. Whether to search recursively through nested structures.
#' @param case_sensitive Logical. Whether pattern matching is case sensitive.
#' @param preview Logical. If TRUE, shows what would be changed without making changes.
#' @param confirm Logical. If TRUE, asks for confirmation before making changes.
#' @param quiet Logical. If TRUE, suppresses non-essential messages.
#'
#' @return The modified database (invisibly if preview=TRUE).
#'
#' @examples
#' # Create a temporary directory and initialise database
#' temp_dir <- tempdir()
#' data_path <- file.path(temp_dir, "boilerplate_batch_edit_example", "data")
#'
#' # Initialise database with default content
#' boilerplate_init(
#'   categories = "measures",
#'   data_path = data_path,
#'   create_dirs = TRUE,
#'   create_empty = FALSE,
#'   confirm = FALSE,
#'   quiet = TRUE
#' )
#'
#' # Load database
#' unified_db <- boilerplate_import(data_path = data_path, quiet = TRUE)
#'
#' # Example 1: Change specific references
#' unified_db <- boilerplate_batch_edit(
#'   db = unified_db,
#'   field = "reference",
#'   new_value = "example2024",
#'   target_entries = c("anxiety", "depression"),
#'   category = "measures",
#'   confirm = FALSE,
#'   quiet = TRUE
#' )
#'
#' # Check the changes
#' unified_db$measures$anxiety$reference
#'
#' # Example 2: Preview changes before applying
#' boilerplate_batch_edit(
#'   db = unified_db,
#'   field = "waves",
#'   new_value = "1-5",
#'   target_entries = "anxiety*",  # All entries starting with "anxiety"
#'   category = "measures",
#'   preview = TRUE,
#'   quiet = TRUE
#' )
#'
#' # Example 3: Load database directly from file
#' \donttest{
#' # First save the database to a JSON file
#' json_file <- file.path(temp_dir, "boilerplate_unified.json")
#' boilerplate_save(unified_db, format = "json", data_path = temp_dir, quiet = TRUE)
#' 
#' # Now edit directly from the file
#' db <- boilerplate_batch_edit(
#'   db = json_file,  # File path instead of database object
#'   field = "description",
#'   new_value = "Updated description",
#'   target_entries = "anxiety",
#'   category = "measures",
#'   confirm = FALSE,
#'   quiet = TRUE
#' )
#' }
#'
#' # Clean up
#' unlink(file.path(temp_dir, "boilerplate_batch_edit_example"), recursive = TRUE)
#'
#' @export
boilerplate_batch_edit <- function(
  db,
    field,
    new_value,
    target_entries = NULL,
    match_pattern = NULL,
    match_values = NULL,
    category = NULL,
    recursive = TRUE,
    case_sensitive = FALSE,
    preview = FALSE,
    confirm = TRUE,
    quiet = FALSE
) {

  # Load required functions from cli
  if (!requireNamespace("cli", quietly = TRUE)) {
    stop("Package 'cli' is required. Please install it.")
  }

  # If db is a file path, load it using the internal function
  if (is.character(db) && length(db) == 1 && file.exists(db)) {
    # Get the format parameter value or default to "auto"
    format <- "auto"
    db <- read_boilerplate_db(db, format = format)
  }

  # Input validation
  if (!is.list(db)) {
    stop("db must be a list")
  }

  if (!is.character(field) || length(field) != 1) {
    stop("field must be a single character string")
  }

  # Determine if this is a unified database and extract the relevant category
  if (!is.null(category)) {
    if (category %in% names(db)) {
      working_db <- db[[category]]
      is_unified <- TRUE
    } else {
      stop(paste("Category", category, "not found in database"))
    }
  } else {
    # Try to detect if it's a unified database
    all_categories <- c("measures", "methods", "results", "discussion", "appendix", "template")
    if (any(all_categories %in% names(db))) {
      stop("This appears to be a unified database. Please specify the category parameter.")
    }
    working_db <- db
    is_unified <- FALSE
  }

  # initialise tracking variables
  changes_made <- list()
  entries_checked <- 0

  # helper function to check if entry should be edited
  should_edit_entry <- function(entry_name, entry_data) {
    # Check if entry has the field
    if (!is.list(entry_data) || !(field %in% names(entry_data))) {
      return(FALSE)
    }

    current_value <- entry_data[[field]]

    # If target_entries is specified, use that
    if (!is.null(target_entries)) {
      if (length(target_entries) == 1 && target_entries == "all") {
        return(TRUE)
      }

      # Check for exact match or wildcard pattern match
      for (target in target_entries) {
        if (grepl("\\*", target)) {
          # Convert wildcard pattern to regex
          pattern <- gsub("\\*", ".*", target)
          if (grepl(paste0("^", pattern, "$"), entry_name, ignore.case = !case_sensitive)) {
            return(TRUE)
          }
        } else {
          # Exact match
          if (entry_name == target) {
            return(TRUE)
          }
        }
      }
      return(FALSE)
    }

    # Otherwise, use pattern/value matching on the field content
    if (!is.null(match_pattern)) {
      return(grepl(match_pattern, as.character(current_value), ignore.case = !case_sensitive))
    }

    if (!is.null(match_values)) {
      return(as.character(current_value) %in% match_values)
    }

    # If no criteria specified, don't edit
    return(FALSE)
  }

  # Recursive function to process entries
  process_entries <- function(db_section, path = "") {
    local_changes <- list()

    for (name in names(db_section)) {
      current_path <- if (path == "") name else paste(path, name, sep = ".")
      entries_checked <<- entries_checked + 1

      item <- db_section[[name]]

      if (is.list(item)) {
        # Check if this is a measure/entry with fields or a nested category
        has_fields <- any(c("name", "description", "reference", "items", "waves", "keywords") %in% names(item))

        if (has_fields && should_edit_entry(name, item)) {
          # This is an entry that should be edited
          old_value <- item[[field]]
          if (!is.null(old_value)) {
            local_changes[[current_path]] <- list(
              old = as.character(old_value),
              new = new_value
            )

            if (!preview) {
              db_section[[name]][[field]] <- new_value
            }
          }
        } else if (!has_fields && recursive) {
          # This is a nested category, recurse into it
          nested_result <- process_entries(item, current_path)
          if (length(nested_result$changes) > 0) {
            local_changes <- c(local_changes, nested_result$changes)
          }
          if (!preview) {
            db_section[[name]] <- nested_result$db
          }
        }
      }
    }

    return(list(db = db_section, changes = local_changes))
  }

  # Process the database
  if (!quiet && !preview) cli::cli_alert_info("Scanning database for entries to edit...")

  result <- process_entries(working_db)
  changes_made <- result$changes

  # Report results
  n_changes <- length(changes_made)

  if (n_changes == 0) {
    if (!quiet) cli::cli_alert_warning("No matching entries found to edit.")
    return(invisible(db))
  }

  # Show what will be/was changed
  if (!quiet || preview) {
    cli::cli_h2(ifelse(preview, "Preview of changes:", "Changes made:"))

    for (path in names(changes_made)) {
      change <- changes_made[[path]]
      cli::cli_alert_info(
        "{.field {path}}: {.val {change$old}} -> {.val {change$new}}"
      )
    }

    cli::cli_alert_success(
      ifelse(preview,
             "Would update {n_changes} {cli::qty(n_changes)}entr{?y/ies}",
             "Updated {n_changes} {cli::qty(n_changes)}entr{?y/ies}")
    )
  }

  if (preview) {
    return(invisible(db))
  }

  # Confirm changes if requested
  if (confirm && !preview) {
    proceed <- ask_yes_no(paste0("Apply these ", n_changes, " changes?"))
    if (!proceed) {
      if (!quiet) cli::cli_alert_info("Changes cancelled by user")
      return(invisible(db))
    }
  }

  # Return the modified database
  if (is_unified) {
    db[[category]] <- result$db
  } else {
    db <- result$db
  }

  if (!quiet) cli::cli_alert_success("Batch edit completed successfully")

  return(db)
}


#' Batch Edit Multiple Fields at Once
#'
#' This function allows editing multiple fields across multiple entries in a single operation.
#'
#' @param db List. The database to edit.
#' @param edits List of lists. Each sub-list should contain:
#'   - field: The field to edit
#'   - new_value: The new value
#'   - target_entries: Which entries to edit (optional)
#'   - match_pattern: Pattern to match (optional)
#'   - match_values: Values to match (optional)
#' @param category Character. Category to edit if db is unified.
#' @param preview Logical. If TRUE, shows what would be changed.
#' @param confirm Logical. If TRUE, asks for confirmation.
#' @param quiet Logical. If TRUE, suppresses messages.
#' @return List. The modified database with the batch edits applied.
#'
#' @examples
#' \donttest{
#' # First create a sample database
#' unified_db <- list(
#'   measures = list(
#'     ban_hate_speech = list(reference = "old_ref", waves = "1-10"),
#'     born_nz = list(reference = "old_ref", waves = "1-10")
#'   )
#' )
#' 
#' # Update multiple fields for specific entries
#' unified_db <- boilerplate_batch_edit_multi(
#'   db = unified_db,
#'   edits = list(
#'     list(
#'       field = "reference",
#'       new_value = "sibley2021",
#'       target_entries = c("ban_hate_speech", "born_nz")
#'     ),
#'     list(
#'       field = "waves",
#'       new_value = "1-15",
#'       target_entries = c("ban_hate_speech", "born_nz")
#'     )
#'   ),
#'   category = "measures"
#' )
#' }
#'
#' @export
boilerplate_batch_edit_multi <- function(
  db,
    edits,
    category = NULL,
    preview = FALSE,
    confirm = TRUE,
    quiet = FALSE
) {

  if (!is.list(edits)) {
    stop("edits must be a list of edit specifications")
  }

  # Process each edit
  for (i in seq_along(edits)) {
    edit <- edits[[i]]

    if (!quiet) cli::cli_h3("Edit {i} of {length(edits)}: {.field {edit$field}}")

    # Apply the edit
    db <- boilerplate_batch_edit(
      db = db,
      field = edit$field,
      new_value = edit$new_value,
      target_entries = edit$target_entries,
      match_pattern = edit$match_pattern,
      match_values = edit$match_values,
      category = category,
      preview = preview,
      confirm = FALSE,  # We'll confirm at the end
      quiet = quiet
    )
  }

  if (!quiet && !preview) {
    cli::cli_alert_success("All batch edits completed")
  }

  return(db)
}


#' Batch Clean Fields in boilerplate Database
#'
#' This function allows batch cleaning of text fields by removing or replacing
#' specific characters or patterns across multiple entries in a boilerplate database.
#'
#' @param db List. The database to clean (can be a single category or unified database).
#' @param field Character. The field to clean (e.g., "reference", "description").
#' @param remove_chars Character vector. Characters to remove from text fields.
#' @param replace_pairs List. Named list for replacements (e.g., list(" " = "_")).
#' @param trim_whitespace Logical. Whether to trim leading/trailing whitespace.
#' @param collapse_spaces Logical. Whether to collapse multiple spaces to single space.
#' @param target_entries Character vector. Entries to clean. Can be:
#'   - Specific entry names (e.g., c("ban_hate_speech", "born_nz"))
#'   - Patterns with wildcards (e.g., "anxiety*")
#'   - "all" to clean all entries
#'   - NULL to clean all entries with the specified field
#' @param exclude_entries Character vector. Entries to exclude from cleaning.
#'   Can use specific names or wildcard patterns like target_entries
#' @param category Character. If db is unified, specifies which category to clean.
#' @param recursive Logical. Whether to search recursively through nested structures.
#' @param preview Logical. If TRUE, shows what would be changed without making changes.
#' @param confirm Logical. If TRUE, asks for confirmation before making changes.
#' @param quiet Logical. If TRUE, suppresses non-essential messages.
#'
#' @return The modified database.
#'
#' @examples
#' \donttest{
#' # First create a sample database
#' unified_db <- list(
#'   measures = list(
#'     test1 = list(reference = "@Smith2023[p.45]"),
#'     test2 = list(reference = "Jones[2022]")
#'   )
#' )
#' 
#' # Remove @, [, and ] from all references
#' unified_db <- boilerplate_batch_clean(
#'   db = unified_db,
#'   field = "reference",
#'   remove_chars = c("@", "[", "]"),
#'   category = "measures"
#' )
#'
#' # Clean all entries EXCEPT specific ones
#' unified_db <- boilerplate_batch_clean(
#'   db = unified_db,
#'   field = "reference",
#'   remove_chars = c("@", "[", "]"),
#'   exclude_entries = c("forgiveness", "special_measure"),
#'   category = "measures"
#' )
#'
#' # Clean specific entries only
#' unified_db <- boilerplate_batch_clean(
#'   db = unified_db,
#'   field = "reference",
#'   remove_chars = c("@", "[", "]"),
#'   target_entries = c("ban_hate_speech", "born_nz"),
#'   category = "measures"
#' )
#'
#' # Clean all entries starting with "emp_" except "emp_special"
#' unified_db <- boilerplate_batch_clean(
#'   db = unified_db,
#'   field = "reference",
#'   remove_chars = c("@", "[", "]"),
#'   target_entries = "emp_*",
#'   exclude_entries = "emp_special",
#'   category = "measures"
#' )
#'
#' # Replace characters and clean
#' unified_db <- boilerplate_batch_clean(
#'   db = unified_db,
#'   field = "reference",
#'   remove_chars = c("@", "[", "]"),
#'   replace_pairs = list(" " = "_", "." = ""),
#'   trim_whitespace = TRUE,
#'   category = "measures"
#' )
#'
#' # Preview changes first
#' boilerplate_batch_clean(
#'   db = unified_db,
#'   field = "reference",
#'   remove_chars = c("@", "[", "]"),
#'   exclude_entries = "forgiveness",
#'   category = "measures",
#'   preview = TRUE
#' )
#' }
#'
#' @export
boilerplate_batch_clean <- function(
  db,
    field,
    remove_chars = NULL,
    replace_pairs = NULL,
    trim_whitespace = TRUE,
    collapse_spaces = FALSE,
    target_entries = NULL,
    exclude_entries = NULL,
    category = NULL,
    recursive = TRUE,
    preview = FALSE,
    confirm = TRUE,
    quiet = FALSE
) {

  # Load required functions from cli
  if (!requireNamespace("cli", quietly = TRUE)) {
    stop("Package 'cli' is required. Please install it.")
  }

  # Input validation
  if (!is.list(db)) {
    stop("db must be a list")
  }

  if (!is.character(field) || length(field) != 1) {
    stop("field must be a single character string")
  }

  if (is.null(remove_chars) && is.null(replace_pairs) && !trim_whitespace && !collapse_spaces) {
    stop("No cleaning operations specified. Set remove_chars, replace_pairs, trim_whitespace, or collapse_spaces.")
  }

  # Determine if this is a unified database
  if (!is.null(category)) {
    if (category %in% names(db)) {
      working_db <- db[[category]]
      is_unified <- TRUE
    } else {
      stop(paste("Category", category, "not found in database"))
    }
  } else {
    all_categories <- c("measures", "methods", "results", "discussion", "appendix", "template")
    if (any(all_categories %in% names(db))) {
      stop("This appears to be a unified database. Please specify the category parameter.")
    }
    working_db <- db
    is_unified <- FALSE
  }

  # Initialise tracking
  changes_made <- list()
  entries_checked <- 0

  # Helper function to clean a string
  clean_string <- function(text) {
    if (!is.character(text) || length(text) == 0 || is.na(text)) {
      return(text)
    }

    cleaned <- text

    # Remove specified characters
    if (!is.null(remove_chars)) {
      for (char in remove_chars) {
        cleaned <- gsub(char, "", cleaned, fixed = TRUE)
      }
    }

    # Apply replacements
    if (!is.null(replace_pairs)) {
      for (from in names(replace_pairs)) {
        to <- replace_pairs[[from]]
        cleaned <- gsub(from, to, cleaned, fixed = TRUE)
      }
    }

    # Collapse multiple spaces
    if (collapse_spaces) {
      cleaned <- gsub("\\s+", " ", cleaned)
    }

    # Trim whitespace
    if (trim_whitespace) {
      cleaned <- trimws(cleaned)
    }

    return(cleaned)
  }

  # Helper function to check if entry should be cleaned
  should_clean_entry <- function(entry_name, entry_data) {
    if (!is.list(entry_data) || !(field %in% names(entry_data))) {
      return(FALSE)
    }

    # First check exclusions - if entry is excluded, don't clean it
    if (!is.null(exclude_entries)) {
      for (exclude in exclude_entries) {
        if (grepl("\\*", exclude)) {
          # Wildcard pattern
          pattern <- gsub("\\*", ".*", exclude)
          if (grepl(paste0("^", pattern, "$"), entry_name)) {
            return(FALSE)  # Entry is excluded
          }
        } else {
          # Exact match
          if (entry_name == exclude) {
            return(FALSE)  # Entry is excluded
          }
        }
      }
    }

    # Then check if it should be included
    if (is.null(target_entries)) {
      return(TRUE)  # Clean all (except excluded)
    }

    if (length(target_entries) == 1 && target_entries == "all") {
      return(TRUE)  # Clean all (except excluded)
    }

    # Check if entry matches target criteria
    for (target in target_entries) {
      if (grepl("\\*", target)) {
        pattern <- gsub("\\*", ".*", target)
        if (grepl(paste0("^", pattern, "$"), entry_name)) {
          return(TRUE)
        }
      } else {
        if (entry_name == target) {
          return(TRUE)
        }
      }
    }

    return(FALSE)
  }

  # Recursive function to process entries
  process_entries <- function(db_section, path = "") {
    local_changes <- list()

    for (name in names(db_section)) {
      current_path <- if (path == "") name else paste(path, name, sep = ".")
      entries_checked <<- entries_checked + 1

      item <- db_section[[name]]

      if (is.list(item)) {
        has_fields <- any(c("name", "description", "reference", "items", "waves", "keywords") %in% names(item))

        if (has_fields && should_clean_entry(name, item)) {
          old_value <- item[[field]]
          if (!is.null(old_value) && is.character(old_value)) {
            new_value <- clean_string(old_value)

            if (old_value != new_value) {
              local_changes[[current_path]] <- list(
                old = old_value,
                new = new_value
              )

              if (!preview) {
                db_section[[name]][[field]] <- new_value
              }
            }
          }
        } else if (!has_fields && recursive) {
          nested_result <- process_entries(item, current_path)
          if (length(nested_result$changes) > 0) {
            local_changes <- c(local_changes, nested_result$changes)
          }
          if (!preview) {
            db_section[[name]] <- nested_result$db
          }
        }
      }
    }

    return(list(db = db_section, changes = local_changes))
  }

  # Process the database
  if (!quiet && !preview) cli::cli_alert_info("Scanning database for fields to clean...")

  result <- process_entries(working_db)
  changes_made <- result$changes

  # Report results
  n_changes <- length(changes_made)

  if (n_changes == 0) {
    if (!quiet) cli::cli_alert_info("No changes needed - all fields are already clean.")
    return(invisible(db))
  }

  # Show changes
  if (!quiet || preview) {
    cli::cli_h2(ifelse(preview, "Preview of changes:", "Changes made:"))

    for (path in names(changes_made)) {
      change <- changes_made[[path]]
      cli::cli_alert_info(
        "{.field {path}}: \"{.val {change$old}}\" -> \"{.val {change$new}}\""
      )
    }

    cli::cli_alert_success(
      ifelse(preview,
             "Would clean {n_changes} {cli::qty(n_changes)}field{?s}",
             "Cleaned {n_changes} {cli::qty(n_changes)}field{?s}")
    )
  }

  if (preview) {
    return(invisible(db))
  }

  # Confirm changes if requested
  if (confirm && !preview) {
    proceed <- ask_yes_no(paste0("Apply these ", n_changes, " cleaning operations?"))
    if (!proceed) {
      if (!quiet) cli::cli_alert_info("Changes cancelled by user")
      return(invisible(db))
    }
  }

  # Return the modified database
  if (is_unified) {
    db[[category]] <- result$db
  } else {
    db <- result$db
  }

  if (!quiet) cli::cli_alert_success("Batch cleaning completed successfully")

  return(db)
}


#' Find Entries with Specific Characters in Fields
#'
#' This helper function finds all entries containing specific characters in a field.
#' Useful for identifying which entries need cleaning.
#'
#' @param db List. The database to search.
#' @param field Character. The field to check.
#' @param chars Character vector. Characters to search for.
#' @param exclude_entries Character vector. Entries to exclude from results.
#' @param category Character. Category if db is unified.
#'
#' @return A named list of entries containing the specified characters.
#'
#' @examples
#' \donttest{
#' # First create a sample database
#' unified_db <- list(
#'   measures = list(
#'     test1 = list(reference = "@Smith2023[p.45]"),
#'     test2 = list(reference = "Jones (2022)"),
#'     test3 = list(reference = "Brown[2021]")
#'   )
#' )
#' 
#' # Find all entries with @, [, or ] in references
#' entries_to_clean <- boilerplate_find_chars(
#'   db = unified_db,
#'   field = "reference",
#'   chars = c("@", "[", "]"),
#'   category = "measures"
#' )
#'
#' # Find entries but exclude specific ones
#' entries_to_clean <- boilerplate_find_chars(
#'   db = unified_db,
#'   field = "reference",
#'   chars = c("@", "[", "]"),
#'   exclude_entries = c("forgiveness", "special_*"),
#'   category = "measures"
#' )
#' }
#'
#' @export
boilerplate_find_chars <- function(db, field, chars, exclude_entries = NULL, category = NULL) {
  # Extract working database
  if (!is.null(category)) {
    if (category %in% names(db)) {
      working_db <- db[[category]]
    } else {
      stop(paste("Category", category, "not found in database"))
    }
  } else {
    working_db <- db
  }

  results <- list()

  # Recursive search function
  search_entries <- function(db_section, path = "") {
    for (name in names(db_section)) {
      current_path <- if (path == "") name else paste(path, name, sep = ".")

      # Check if this entry should be excluded
      should_exclude <- FALSE
      if (!is.null(exclude_entries)) {
        for (exclude in exclude_entries) {
          if (grepl("\\*", exclude)) {
            pattern <- gsub("\\*", ".*", exclude)
            if (grepl(paste0("^", pattern, "$"), name)) {
              should_exclude <- TRUE
              break
            }
          } else {
            if (name == exclude) {
              should_exclude <- TRUE
              break
            }
          }
        }
      }

      if (should_exclude) {
        next  # Skip this entry
      }

      item <- db_section[[name]]

      if (is.list(item)) {
        has_fields <- any(c("name", "description", "reference", "items", "waves", "keywords") %in% names(item))

        if (has_fields && field %in% names(item)) {
          value <- item[[field]]
          if (!is.null(value) && is.character(value)) {
            contains_chars <- FALSE
            for (char in chars) {
              if (grepl(char, value, fixed = TRUE)) {
                contains_chars <- TRUE
                break
              }
            }
            if (contains_chars) {
              results[[current_path]] <<- value
            }
          }
        } else if (!has_fields) {
          search_entries(item, current_path)
        }
      }
    }
  }

  search_entries(working_db)

  if (length(results) == 0) {
    cli::cli_alert_info("No entries found containing the specified characters.")
  } else {
    cli::cli_alert_success("Found {length(results)} {cli::qty(length(results))}entr{?y/ies} containing specified characters")
  }

  return(results)
}
