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
#' @param sort_results Logical. Whether to sort the merged database alphabetically (default: TRUE).
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
#' If sort_results is TRUE, the function will sort the merged database alphabetically at each level.
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
#'
#' # Merge but do not sort the result
#' merged_db <- boilerplate_merge_databases(test_a, test_b, sort_results = FALSE)
#' }
#'
#' @importFrom cli cli_h1 cli_h2 cli_text cli_code cli_progress_bar cli_progress_update
#' @importFrom cli cli_progress_done cli_alert_success cli_alert_info
#'
#' @export
boilerplate_merge_databases <- function(db1, db2, db1_name = "Database 1", db2_name = "Database 2",
                                        recursive = TRUE, sort_results = TRUE) {
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

    # sort alphabetically if requested
    if (sort_results) {
      local_merged <- local_merged[order(names(local_merged))]
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

#' Merge Unified Databases
#'
#' This function merges two unified databases, allowing the user to resolve conflicts
#' when the same entry exists in both databases with different content. It supports
#' both flat and hierarchical database structures across all categories.
#'
#' @param db1 A list representing the first unified database.
#' @param db2 A list representing the second unified database.
#' @param categories Character vector. Categories to merge (e.g., "measures", "methods").
#'   If NULL (default), merges all common categories.
#' @param db1_name Character string. The name of the first database (default: "Database 1").
#' @param db2_name Character string. The name of the second database (default: "Database 2").
#' @param recursive Logical. Whether to merge hierarchical structures recursively (default: TRUE).
#' @param sort_results Logical. Whether to sort the merged database alphabetically (default: TRUE).
#' @param quiet Logical. If TRUE, suppresses all CLI alerts. Default is FALSE.
#'
#' @return A list representing the merged unified database.
#'
#' @details
#' The function iterates through all entries in the specified categories of both databases.
#' When an entry exists in both databases:
#' \itemize{
#'   \item If the entries are identical, it keeps one copy.
#'   \item If the entries differ, it prompts the user to choose which entry to keep.
#' }
#' Entries that exist in only one database are automatically added to the merged database.
#' If recursive is TRUE, the function will recursively merge nested folders/categories.
#' If sort_results is TRUE, the function will sort the merged database alphabetically at each level.
#'
#' @examples
#' \dontrun{
#' # Import two unified databases from different locations
#' db1 <- boilerplate_import()
#' db2 <- boilerplate_import(data_path = "path/to/other/project/data")
#'
#' # Merge all common categories with custom names
#' merged_db <- boilerplate_merge_unified(db1, db2,
#'                                       db1_name = "Project A",
#'                                       db2_name = "Project B")
#'
#' # Merge only specific categories
#' merged_db <- boilerplate_merge_unified(db1, db2,
#'                                       categories = c("measures", "methods"))
#'
#' # Save the merged database
#' boilerplate_save(merged_db)
#' }
#'
#' @importFrom cli cli_h1 cli_h2 cli_alert_info cli_alert_success
#' @export
boilerplate_merge_unified <- function(
    db1,
    db2,
    categories = NULL,
    db1_name = "Database 1",
    db2_name = "Database 2",
    recursive = TRUE,
    sort_results = TRUE,
    quiet = FALSE
) {
  # validate inputs
  if (!is.list(db1) || !is.list(db2)) {
    stop("Both db1 and db2 must be lists (unified databases)")
  }

  # identify common categories if not specified
  if (is.null(categories)) {
    categories <- intersect(names(db1), names(db2))
    if (!quiet) cli_alert_info("merging all common categories: {paste(categories, collapse = ', ')}")
  } else {
    # validate that specified categories exist in both databases
    missing_in_db1 <- setdiff(categories, names(db1))
    missing_in_db2 <- setdiff(categories, names(db2))

    if (length(missing_in_db1) > 0) {
      if (!quiet) cli_alert_info("categories missing in {db1_name}: {paste(missing_in_db1, collapse = ', ')}")
    }

    if (length(missing_in_db2) > 0) {
      if (!quiet) cli_alert_info("categories missing in {db2_name}: {paste(missing_in_db2, collapse = ', ')}")
    }

    # keep only categories present in both databases
    categories <- intersect(categories, intersect(names(db1), names(db2)))
    if (length(categories) == 0) {
      stop("No common categories found to merge")
    }
  }

  # initialize result with db1
  result <- db1

  # process each category
  cli_h1("Starting unified database merge")

  for (category in categories) {
    cli_h2("Merging category: {category}")

    # merge this category using the original merge function
    result[[category]] <- boilerplate_merge_databases(
      db1 = db1[[category]],
      db2 = db2[[category]],
      db1_name = paste0(db1_name, " (", category, ")"),
      db2_name = paste0(db2_name, " (", category, ")"),
      recursive = recursive,
      sort_results = sort_results
    )

    if (!quiet) cli_alert_success("completed merge of {category} category")
  }

  if (!quiet) cli_alert_success("merged unified database complete with {length(categories)} categories")

  return(result)
}

#' Merge Selected Category Between Two Unified Databases
#'
#' This function extracts a specific category from two unified databases, merges them,
#' and returns the updated first database with the merged category.
#'
#' @param db1 A list representing the first unified database.
#' @param db2 A list representing the second unified database.
#' @param category Character. The category to merge (e.g., "measures", "methods").
#' @param db1_name Character string. The name of the first database (default: "Database 1").
#' @param db2_name Character string. The name of the second database (default: "Database 2").
#' @param recursive Logical. Whether to merge hierarchical structures recursively (default: TRUE).
#' @param sort_results Logical. Whether to sort the merged database alphabetically (default: TRUE).
#' @param quiet Logical. If TRUE, suppresses all CLI alerts. Default is FALSE.
#'
#' @return A list representing the first database with the updated merged category.
#'
#' @examples
#' \dontrun{
#' # Import two unified databases
#' db1 <- boilerplate_import()
#' db2 <- boilerplate_import(data_path = "path/to/other/project/data")
#'
#' # Merge just the measures category
#' db1 <- boilerplate_merge_category(db1, db2, "measures")
#'
#' # Save the updated database
#' boilerplate_save(db1)
#' }
#'
#' @importFrom cli cli_alert_info cli_alert_success
#' @export
boilerplate_merge_category <- function(
    db1,
    db2,
    category,
    db1_name = "Database 1",
    db2_name = "Database 2",
    recursive = TRUE,
    sort_results = TRUE,
    quiet = FALSE
) {
  # validate inputs
  if (!is.list(db1) || !is.list(db2)) {
    stop("Both db1 and db2 must be lists (unified databases)")
  }

  if (!(category %in% names(db1)) || !(category %in% names(db2))) {
    stop(paste("Category", category, "not found in both databases"))
  }

  if (!quiet) cli_alert_info("merging category: {category}")

  # merge the specified category
  db1[[category]] <- boilerplate_merge_databases(
    db1 = db1[[category]],
    db2 = db2[[category]],
    db1_name = paste0(db1_name, " (", category, ")"),
    db2_name = paste0(db2_name, " (", category, ")"),
    recursive = recursive,
    sort_results = sort_results
  )

  if (!quiet) cli_alert_success("updated {db1_name} with merged {category} database")

  return(db1)
}

#' Update Category from External Database
#'
#' This function imports a specific category from an external database and
#' updates the corresponding category in a unified database.
#'
#' @param unified_db A list representing the unified database to update.
#' @param category Character. The category to import and update (e.g., "measures", "methods").
#' @param external_path Character. Path to the external data directory.
#' @param db1_name Character string. The name of the first database (default: "Current Database").
#' @param db2_name Character string. The name of the second database (default: "External Database").
#' @param recursive Logical. Whether to merge hierarchical structures recursively (default: TRUE).
#' @param sort_results Logical. Whether to sort the merged database alphabetically (default: TRUE).
#' @param quiet Logical. If TRUE, suppresses all CLI alerts. Default is FALSE.
#'
#' @return A list representing the updated unified database.
#'
#' @examples
#' \dontrun{
#' # Import the current unified database
#' unified_db <- boilerplate_import()
#'
#' # Update its measures category from an external project
#' unified_db <- boilerplate_update_from_external(
#'   unified_db = unified_db,
#'   category = "measures",
#'   external_path = "path/to/external/project/data"
#' )
#'
#' # Save the updated database
#' boilerplate_save(unified_db)
#' }
#'
#' @importFrom cli cli_alert_info cli_alert_success
#' @export
boilerplate_update_from_external <- function(
    unified_db,
    category,
    external_path,
    db1_name = "Current Database",
    db2_name = "External Database",
    recursive = TRUE,
    sort_results = TRUE,
    quiet = FALSE
) {
  # validate inputs
  if (!is.list(unified_db)) {
    stop("unified_db must be a list")
  }

  if (!(category %in% names(unified_db))) {
    stop(paste("Category", category, "not found in unified database"))
  }

  # import the external category
  if (!quiet) cli_alert_info("importing {category} from external path: {external_path}")
  external_category <- boilerplate_import(category, data_path = external_path)

  if (is.null(external_category) || length(external_category) == 0) {
    stop(paste("Could not import", category, "from external path"))
  }

  # merge the category into the unified database
  if (!quiet) cli_alert_info("merging {category} from external database")
  unified_db[[category]] <- boilerplate_merge_databases(
    db1 = unified_db[[category]],
    db2 = external_category,
    db1_name = paste0(db1_name, " (", category, ")"),
    db2_name = paste0(db2_name, " (", category, ")"),
    recursive = recursive,
    sort_results = sort_results
  )

  if (!quiet) cli_alert_success("updated unified database with external {category} data")

  return(unified_db)
}

#===================================================
# Example Usage Scenarios
# #===================================================
#
# # Example 1: Merging entire unified databases
# merge_entire_example <- function() {
#   # Import two unified databases
#   db1 <- boilerplate_import()
#   db2 <- boilerplate_import(data_path = "path/to/collaborator/data")
#
#   # Merge all common categories
#   merged_db <- boilerplate_merge_unified(
#     db1 = db1,
#     db2 = db2,
#     db1_name = "Our Project",
#     db2_name = "Collaborator Project"
#   )
#
#   # Save the merged database
#   boilerplate_save(merged_db)
# }
#
# # Example 2: Merging just measures between projects
# merge_measures_example <- function() {
#   # Import two unified databases
#   db1 <- boilerplate_import()
#   db2 <- boilerplate_import(data_path = "path/to/measures/repository")
#
#   # Merge just the measures category
#   db1 <- boilerplate_merge_category(
#     db1 = db1,
#     db2 = db2,
#     category = "measures",
#     db1_name = "Current Project",
#     db2_name = "Measures Repository"
#   )
#
#   # Save the updated database
#   boilerplate_save(db1)
# }
#
# # Example 3: Updating from an external source
# update_from_external_example <- function() {
#   # Import current unified database
#   unified_db <- boilerplate_import()
#
#   # Update methods from the central repository
#   unified_db <- boilerplate_update_from_external(
#     unified_db = unified_db,
#     category = "methods",
#     external_path = "path/to/central/methods/repository"
#   )
#
#   # Save the updated database
#   boilerplate_save(unified_db)
# }

