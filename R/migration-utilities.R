#' Migration Utilities for RDS to JSON Conversion
#'
#' Functions to help migrate from individual RDS files to unified JSON structure

#' Migrate Boilerplate Database from RDS to JSON
#'
#' Comprehensive migration tool that converts existing RDS-based boilerplate
#' databases to JSON format. Supports both unified (single file) and separate
#' (multiple files) output formats with optional schema validation.
#'
#' @param source_path Path to directory containing RDS files or single RDS file
#' @param output_path Path where JSON files should be saved
#' @param format Output format: "unified" (single JSON) or "separate" (one per category)
#' @param validate Logical. Validate against JSON schema after conversion?
#'   Default is TRUE.
#' @param backup Logical. Create backup of original files? Default is TRUE.
#' @param quiet Logical. Suppress progress messages? Default is FALSE.
#'
#' @return List with migration results containing:
#'   \itemize{
#'     \item \code{migrated}: Character vector of successfully migrated files
#'     \item \code{errors}: List of any errors encountered during migration
#'     \item \code{validation}: Validation results if validate=TRUE
#'   }
#'
#' @details
#' The migration process:
#' \enumerate{
#'   \item Scans source directory for RDS files
#'   \item Creates timestamped backup if requested
#'   \item Converts RDS to JSON format
#'   \item Validates against schema if requested
#'   \item Reports results and any issues
#' }
#'
#' The "unified" format creates a single JSON file containing all categories,
#' which is recommended for version control and collaborative workflows.
#'
#' @examples
#' \dontrun{
#' # Migrate from GitHub templates structure
#' results <- boilerplate_migrate_to_json(
#'   source_path = "~/templates/boilerplate_data",
#'   output_path = "~/my_project/boilerplate/data",
#'   format = "unified",
#'   validate = TRUE
#' )
#'
#' # Check results
#' if (length(results$errors) == 0) {
#'   message("Migration successful!")
#' } else {
#'   print(results$errors)
#' }
#' }
#'
#' @seealso \code{\link{boilerplate_rds_to_json}}, \code{\link{validate_json_database}}
#'
#' @export
boilerplate_migrate_to_json <- function(
    source_path,
    output_path,
    format = c("unified", "separate"),
    validate = TRUE,
    backup = TRUE,
    quiet = FALSE
) {
  format <- match.arg(format)

  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Package 'jsonlite' is required. Please install it.")
  }

  # Create output directory
  dir.create(output_path, recursive = TRUE, showWarnings = FALSE)

  # Initialise results
  results <- list(
    migrated = character(),
    errors = list(),
    validation = list()
  )

  # Find all RDS files
  if (dir.exists(source_path)) {
    rds_files <- list.files(
      source_path,
      pattern = "\\.rds$",
      full.names = TRUE,
      ignore.case = TRUE
    )
  } else if (file.exists(source_path) && grepl("\\.rds$", source_path, ignore.case = TRUE)) {
    rds_files <- source_path
  } else {
    stop("Source path must be a directory or RDS file")
  }

  if (length(rds_files) == 0) {
    stop("No RDS files found in source path")
  }

  if (!quiet) cli::cli_h2("Migrating {length(rds_files)} RDS file{?s} to JSON")

  # Create backup if requested
  if (backup) {
    backup_dir <- file.path(output_path, paste0("backup_", format(Sys.time(), "%Y%m%d_%H%M%S")))
    dir.create(backup_dir, recursive = TRUE)

    if (!quiet) cli::cli_alert_info("Creating backup in {backup_dir}")

    for (rds_file in rds_files) {
      file.copy(rds_file, backup_dir)
    }
  }

  # Process based on format
  if (format == "unified") {
    results <- migrate_to_unified_json(
      rds_files, output_path, validate, quiet, results
    )
  } else {
    results <- migrate_to_separate_json(
      rds_files, output_path, validate, quiet, results
    )
  }

  # Summary
  if (!quiet) {
    cli::cli_h3("Migration Summary")
    cli::cli_alert_success("Migrated {length(results$migrated)} database{?s}")

    if (length(results$errors) > 0) {
      cli::cli_alert_danger("{length(results$errors)} error{?s} occurred")
    }

    if (validate && length(results$validation) > 0) {
      valid_count <- sum(sapply(results$validation, function(x) length(x) == 0))
      cli::cli_alert_info("{valid_count}/{length(results$validation)} passed validation")
    }
  }

  invisible(results)
}

#' Migrate to Unified JSON Format
#' @noRd
migrate_to_unified_json <- function(rds_files, output_path, validate, quiet, results) {
  unified_db <- list()

  # Map common file names to categories
  category_map <- list(
    "methods_db" = "methods",
    "results_db" = "results",
    "discussion_db" = "discussion",
    "measures_db" = "measures",
    "appendix_db" = "appendix",
    "template_db" = "template"
  )

  for (rds_file in rds_files) {
    tryCatch({
      if (!quiet) cli::cli_alert_info("Processing {basename(rds_file)}")

      # Load RDS
      db <- readRDS(rds_file)

      # Determine category from filename
      base_name <- tools::file_path_sans_ext(basename(rds_file))
      category <- category_map[[base_name]]

      if (is.null(category)) {
        # Try to infer from structure
        if ("boilerplate_unified" %in% names(db)) {
          # It's already a unified database
          unified_db <- merge_unified_dbs(unified_db, db$boilerplate_unified)
        } else {
          # Skip unknown files
          if (!quiet) cli::cli_alert_warning("Skipping unknown file: {basename(rds_file)}")
          next
        }
      } else {
        # Add to unified structure
        if (paste0(category, "_db") %in% names(db)) {
          unified_db[[category]] <- db[[paste0(category, "_db")]]
        } else {
          unified_db[[category]] <- db
        }
      }

      results$migrated <- c(results$migrated, rds_file)

    }, error = function(e) {
      results$errors[[rds_file]] <- e$message
      if (!quiet) cli::cli_alert_danger("Error processing {basename(rds_file)}: {e$message}")
    })
  }

  # Save unified JSON
  output_file <- file.path(output_path, "boilerplate_unified.json")

  if (!quiet) cli::cli_alert_info("Saving unified database to {basename(output_file)}")

  # Clean and prepare for JSON
  unified_db <- prepare_for_json(unified_db)

  # Write JSON
  jsonlite::write_json(
    unified_db,
    output_file,
    pretty = TRUE,
    auto_unbox = TRUE,
    null = "null"
  )

  # Validate if requested
  if (validate) {
    validation_result <- validate_json_database(output_file, "unified")
    results$validation[["unified"]] <- validation_result
  }

  results
}

#' Migrate to Separate JSON Files
#' @noRd
migrate_to_separate_json <- function(rds_files, output_path, validate, quiet, results) {

  for (rds_file in rds_files) {
    tryCatch({
      if (!quiet) cli::cli_alert_info("Converting {basename(rds_file)}")

      # Load RDS
      db <- readRDS(rds_file)

      # Prepare for JSON
      db <- prepare_for_json(db)

      # Output filename
      json_file <- file.path(
        output_path,
        sub("\\.rds$", ".json", basename(rds_file), ignore.case = TRUE)
      )

      # Write JSON
      jsonlite::write_json(
        db,
        json_file,
        pretty = TRUE,
        auto_unbox = TRUE,
        null = "null"
      )

      results$migrated <- c(results$migrated, json_file)

      # Validate if requested
      if (validate) {
        # Determine type from filename
        type <- detect_database_type(basename(rds_file))
        if (!is.null(type)) {
          validation_result <- validate_json_database(json_file, type)
          results$validation[[basename(json_file)]] <- validation_result
        }
      }

    }, error = function(e) {
      results$errors[[rds_file]] <- e$message
      if (!quiet) cli::cli_alert_danger("Error converting {basename(rds_file)}: {e$message}")
    })
  }

  results
}

#' Prepare Database for JSON Conversion
#' @noRd
prepare_for_json <- function(db) {
  # Recursive function to clean data for JSON
  clean_for_json <- function(x) {
    if (is.data.frame(x)) {
      # Convert data frames to lists
      x <- as.list(x)
    }

    if (is.list(x)) {
      # Process each element
      x <- lapply(x, clean_for_json)

      # Remove NULL values (optional - you might want to keep them)
      # x <- x[!sapply(x, is.null)]

      # Ensure all names are valid
      if (!is.null(names(x))) {
        names(x) <- make.names(names(x), unique = TRUE)
      }
    } else if (is.factor(x)) {
      # Convert factors to characters
      x <- as.character(x)
    } else if (inherits(x, "Date")) {
      # Convert dates to ISO format
      x <- format(x, "%Y-%m-%d")
    } else if (inherits(x, "POSIXt")) {
      # Convert date-times to ISO format
      x <- format(x, "%Y-%m-%dT%H:%M:%SZ")
    }

    x
  }

  clean_for_json(db)
}

#' Validate JSON Database Against Schema
#'
#' Validates a JSON database file against the appropriate JSON schema to ensure
#' data integrity and structure compliance.
#'
#' @param json_file Path to JSON file to validate
#' @param type Database type ("methods", "measures", "results", "discussion",
#'   "appendix", "template", "unified"). Default is "unified".
#'
#' @return Character vector of validation errors (empty if valid)
#'
#' @details
#' Uses JSON Schema Draft 7 for validation via the jsonvalidate package.
#' Schemas define required fields, data types, and structure for each database
#' type. This ensures consistency across different database files and helps
#' catch errors early.
#'
#' If jsonvalidate is not installed, validation is skipped with a message.
#'
#' @examples
#' \dontrun{
#' # Validate a measures database
#' errors <- validate_json_database("measures_db.json", "measures")
#' if (length(errors) == 0) {
#'   message("Database is valid!")
#' } else {
#'   cat("Validation errors:\n", paste(errors, collapse = "\n"))
#' }
#'
#' # Validate unified database
#' errors <- validate_json_database("boilerplate_unified.json")
#' }
#'
#' @seealso \code{\link{boilerplate_migrate_to_json}}
#'
#' @export
validate_json_database <- function(json_file, type = "unified") {
  if (!requireNamespace("jsonvalidate", quietly = TRUE)) {
    message("Package 'jsonvalidate' not installed. Skipping validation.")
    return(character())
  }

  # Get schema path
  schema_file <- system.file(
    "examples", "json-poc", "schema",
    paste0(type, "_schema.json"),
    package = "boilerplate"
  )

  if (!file.exists(schema_file)) {
    # Try to use the one we just created
    schema_file <- file.path(
      dirname(dirname(dirname(json_file))),
      "inst", "examples", "json-poc", "schema",
      paste0(type, "_schema.json")
    )
  }

  if (!file.exists(schema_file)) {
    return(paste("Schema not found for type:", type))
  }

  # Validate
  validator <- jsonvalidate::json_validator(schema_file)
  valid <- validator(json_file, verbose = TRUE, error = FALSE)

  if (valid) {
    return(character())
  } else {
    # Convert data.frame errors to character vector
    errors_df <- attr(valid, "errors")
    if (is.null(errors_df)) {
      # No detailed errors available, return generic message
      return("Validation failed")
    } else if (is.data.frame(errors_df)) {
      return(paste(errors_df$field, errors_df$message, sep = ": "))
    } else if (is.list(errors_df)) {
      # Handle list format
      return(as.character(unlist(errors_df)))
    } else {
      return(as.character(errors_df))
    }
  }
}

#' Detect Database Type from Filename
#' @noRd
detect_database_type <- function(filename) {
  if (grepl("measures", filename, ignore.case = TRUE)) return("measures")
  if (grepl("methods", filename, ignore.case = TRUE)) return("methods")
  if (grepl("results", filename, ignore.case = TRUE)) return("results")
  if (grepl("discussion", filename, ignore.case = TRUE)) return("discussion")
  if (grepl("appendix", filename, ignore.case = TRUE)) return("appendix")
  if (grepl("template", filename, ignore.case = TRUE)) return("template")
  if (grepl("unified", filename, ignore.case = TRUE)) return("unified")
  NULL
}

#' Merge Unified Databases
#' @noRd
merge_unified_dbs <- function(db1, db2) {
  for (key in names(db2)) {
    if (key %in% names(db1)) {
      if (is.list(db1[[key]]) && is.list(db2[[key]])) {
        db1[[key]] <- merge_unified_dbs(db1[[key]], db2[[key]])
      } else {
        # Keep db2 value (newer)
        db1[[key]] <- db2[[key]]
      }
    } else {
      db1[[key]] <- db2[[key]]
    }
  }
  db1
}

#' Compare RDS and JSON Databases
#'
#' Compares RDS and JSON database files to verify migration accuracy and identify
#' any differences in structure or content.
#'
#' @param rds_path Path to RDS file
#' @param json_path Path to JSON file
#' @param ignore_meta Logical. Ignore metadata fields (those starting with
#'   underscore)? Default is TRUE.
#'
#' @return List of differences, each containing:
#'   \itemize{
#'     \item \code{path}: Location of difference in database structure
#'     \item \code{type}: Type of difference (type_mismatch, missing_in_json,
#'       missing_in_rds, value_mismatch)
#'     \item Additional fields depending on difference type
#'   }
#'
#' @details
#' This function performs a deep comparison of database structures, checking:
#' \itemize{
#'   \item Data types match between formats
#'   \item All keys/fields are present in both versions
#'   \item Values are equivalent (accounting for format differences)
#' }
#'
#' Useful for verifying that migration from RDS to JSON preserves all data
#' and structure correctly.
#'
#' @examples
#' \dontrun{
#' # Compare original and migrated databases
#' differences <- compare_rds_json(
#'   "original/methods_db.rds",
#'   "migrated/methods_db.json"
#' )
#'
#' if (length(differences) == 0) {
#'   message("Migration successful - databases are equivalent!")
#' } else {
#'   # Review differences
#'   for (diff in differences) {
#'     cat(sprintf("Difference at %s: %s\n", diff$path, diff$type))
#'   }
#' }
#' }
#'
#' @seealso \code{\link{boilerplate_migrate_to_json}},
#'   \code{\link{boilerplate_rds_to_json}}
#'
#' @export
compare_rds_json <- function(rds_path, json_path, ignore_meta = TRUE) {
  # Load both
  rds_db <- readRDS(rds_path)
  json_db <- jsonlite::read_json(json_path, simplifyVector = FALSE)

  # Prepare RDS for comparison
  rds_db <- prepare_for_json(rds_db)

  # Compare
  differences <- compare_recursive(rds_db, json_db, ignore_meta)

  if (length(differences) == 0) {
    message("Databases are equivalent!")
  } else {
    message(sprintf("Found %d difference(s)", length(differences)))
  }

  differences
}

#' Recursive Database Comparison
#' @noRd
compare_recursive <- function(a, b, ignore_meta = TRUE, path = "") {
  differences <- list()

  # Check types
  if (typeof(a) != typeof(b)) {
    return(list(list(
      path = path,
      type = "type_mismatch",
      a = typeof(a),
      b = typeof(b)
    )))
  }

  if (is.list(a) && is.list(b)) {
    # Compare keys
    keys_a <- names(a)
    keys_b <- names(b)

    if (ignore_meta) {
      keys_a <- keys_a[!grepl("^_", keys_a)]
      keys_b <- keys_b[!grepl("^_", keys_b)]
    }

    # Check for missing keys
    only_in_a <- setdiff(keys_a, keys_b)
    only_in_b <- setdiff(keys_b, keys_a)

    if (length(only_in_a) > 0) {
      differences <- c(differences, list(list(
        path = path,
        type = "missing_in_json",
        keys = only_in_a
      )))
    }

    if (length(only_in_b) > 0) {
      differences <- c(differences, list(list(
        path = path,
        type = "missing_in_rds",
        keys = only_in_b
      )))
    }

    # Compare common keys
    common_keys <- intersect(keys_a, keys_b)
    for (key in common_keys) {
      sub_diff <- compare_recursive(
        a[[key]],
        b[[key]],
        ignore_meta,
        paste0(path, "/", key)
      )
      differences <- c(differences, sub_diff)
    }
  } else {
    # Compare values
    if (!identical(a, b)) {
      differences <- c(differences, list(list(
        path = path,
        type = "value_mismatch",
        rds = a,
        json = b
      )))
    }
  }

  differences
}
