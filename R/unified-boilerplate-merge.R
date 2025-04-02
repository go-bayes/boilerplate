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
