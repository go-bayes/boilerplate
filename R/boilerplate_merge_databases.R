#' Merge Two Measure Databases
#'
#' This function merges two measure databases, allowing the user to resolve conflicts
#' when the same measure exists in both databases with different content. It supports
#' both flat and hierarchical database structures.
#'
#' @param db1 A list representing the first measure database.
#' @param db2 A list representing the second measure database.
#' @param db1_name Character string. The name of the first database (default: "Database 1").
#' @param db2_name Character string. The name of the second database (default: "Database 2").
#' @param recursive Logical. Whether to merge hierarchical structures recursively (default: TRUE).
#'
#' @return A list representing the merged measure database.
#'
#' @details
#' The function iterates through all measures in both databases. When a measure exists
#' in both databases:
#' \itemize{
#'   \item If the entries are identical, it keeps one copy.
#'   \item If the entries differ, it prompts the user to choose which entry to keep.
#' }
#' Measures that exist in only one database are automatically added to the merged database.
#' If recursive is TRUE, the function will recursively merge nested folders/categories.
#'
#' @examples
#' \dontrun{
#' # Merge two flat databases with default names
#' merged_db <- boilerplate_merge_databases(test_a, test_b)
#'
#' # Merge two hierarchical databases with custom names
#' merged_db <- boilerplate_merge_databases(test_a, test_b, "NZAVS 2009", "NZAVS 2020")
#'
#' # Merge but do not process nested structures recursively
#' merged_db <- boilerplate_merge_databases(test_a, test_b, recursive = FALSE)
#' }
#'
#' @importFrom cli cli_h1 cli_h2 cli_text cli_code cli_progress_bar cli_progress_update
#' @importFrom cli cli_progress_done cli_alert_success cli_alert_info
#'
#' @export
boilerplate_merge_databases <- function(db1, db2, db1_name = "Database 1", db2_name = "Database 2", recursive = TRUE) {
  merged_db <- list()

  # Helper function to get user choice
  get_user_choice <- function(name, db1_entry, db2_entry) {
    cli::cli_h2("Conflict found for: {.val {name}}")
    cli::cli_text("Entry from {.strong {db1_name}}:")
    cli::cli_code(capture.output(print(db1_entry)))
    cli::cli_text("Entry from {.strong {db2_name}}:")
    cli::cli_code(capture.output(print(db2_entry)))

    prompt <- cli::cli_text("Which entry do you want to keep? ({.val 1} for {db1_name}, {.val 2} for {db2_name}): ")
    choice <- readline(prompt)
    while (!(choice %in% c("1", "2"))) {
      choice <- readline(cli::cli_text("Invalid input. Please enter {.val 1} or {.val 2}: "))
    }
    return(as.integer(choice))
  }

  # Helper function to determine if an entry is a measure or a folder
  is_measure <- function(entry) {
    if (!is.list(entry)) return(TRUE)
    # If it has description or items, it's likely a measure
    if (any(c("description", "items", "reference") %in% names(entry))) {
      return(TRUE)
    }
    # Otherwise, it's probably a folder/category
    return(FALSE)
  }

  # Recursive merge function for handling nested structures
  merge_recursive <- function(db1, db2, path = "") {
    local_merged <- list()

    # Get all keys from both databases
    all_keys <- unique(c(names(db1), names(db2)))

    for (key in all_keys) {
      current_path <- if (path == "") key else paste(path, key, sep = ".")

      if (key %in% names(db1) && key %in% names(db2)) {
        # Key exists in both databases
        db1_entry <- db1[[key]]
        db2_entry <- db2[[key]]

        if (is.list(db1_entry) && is.list(db2_entry) &&
            !is_measure(db1_entry) && !is_measure(db2_entry) &&
            recursive) {
          # Both are folders/categories - recurse
          cli::cli_alert_info("Processing folder: {.val {current_path}}")
          local_merged[[key]] <- merge_recursive(db1_entry, db2_entry, current_path)
        } else if (identical(db1_entry, db2_entry)) {
          # Entries are identical
          local_merged[[key]] <- db1_entry
          cli::cli_alert_success("{.val {current_path}} is identical in both databases. Keeping it.")
        } else {
          # Entries differ - get user choice
          choice <- get_user_choice(current_path, db1_entry, db2_entry)
          local_merged[[key]] <- if (choice == 1) db1_entry else db2_entry
          cli::cli_alert_info("Kept entry from {.strong {if(choice == 1) db1_name else db2_name}} for {.val {current_path}}")
        }
      } else if (key %in% names(db1)) {
        # Key only in db1
        local_merged[[key]] <- db1[[key]]
        cli::cli_alert_info("{.val {current_path}} only found in {.strong {db1_name}}. Adding it.")
      } else {
        # Key only in db2
        local_merged[[key]] <- db2[[key]]
        cli::cli_alert_info("{.val {current_path}} only found in {.strong {db2_name}}. Adding it.")
      }
    }

    return(local_merged)
  }

  # Start merging process
  cli::cli_h1("Starting database merge")
  cli::cli_progress_bar(total = length(unique(c(names(db1), names(db2)))),
                        format = "{cli::pb_spin} Merging databases... [{cli::pb_current}/{cli::pb_total}] [{cli::pb_percent}] [{cli::pb_bar}]")

  # Call recursive merge function
  merged_db <- merge_recursive(db1, db2)

  # Set up the progress bar properly
  all_names <- unique(c(names(db1), names(db2)))
  for (i in seq_along(all_names)) {
    cli::cli_progress_update()
  }

  cli::cli_progress_done()

  # Count total measures in merged database
  count_measures <- function(db) {
    count <- 0
    for (key in names(db)) {
      item <- db[[key]]
      if (is_measure(item)) {
        count <- count + 1
      } else if (is.list(item)) {
        count <- count + count_measures(item)
      }
    }
    return(count)
  }

  total_measures <- count_measures(merged_db)
  cli::cli_alert_success("Merge completed. Total measures in merged database: {.val {total_measures}}")

  return(merged_db)
}

