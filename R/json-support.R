#' JSON Support Functions for boilerplate Package
#'
#' These functions add JSON support to the boilerplate package while maintaining
#' backward compatibility with RDS format.

#' Read boilerplate Database from JSON or RDS
#'
#' Internal function to read database files in either JSON or RDS format.
#' Automatically detects the format based on file extension when format="auto".
#'
#' @param file_path Path to the database file
#' @param format Format to read ("auto", "json", "rds"). Default is "auto" which
#'   detects format from file extension.
#' @return List containing the database
#' @keywords internal
#' @noRd
read_boilerplate_db <- function(file_path, format = "auto") {
  if (!file.exists(file_path)) {
    stop("File not found: ", file_path)
  }

  # Auto-detect format
  if (format == "auto") {
    ext <- tolower(tools::file_ext(file_path))
    format <- if (ext == "json") "json" else "rds"
  }

  if (format == "json") {
    if (!requireNamespace("jsonlite", quietly = TRUE)) {
      stop("Package 'jsonlite' is required for JSON support. Please install it.")
    }
    db <- jsonlite::read_json(file_path, simplifyVector = FALSE)
    # Convert JSON structure to match RDS structure if needed
    db <- standardise_json_structure(db)
  } else {
    db <- readRDS(file_path)
  }

  return(db)
}

#' Write boilerplate Database to JSON or RDS
#'
#' Internal function to write database files in JSON and/or RDS format.
#' Can write to both formats simultaneously for compatibility.
#'
#' @param db Database to write
#' @param file_path Path to save the file
#' @param format Format to write ("json", "rds", "both"). Default is "json".
#'   RDS writing is retained for round-trip and migration testing, but is
#'   deprecated for new databases.
#' @param pretty Logical. Pretty print JSON? Default is TRUE for human readability.
#' @return Invisible TRUE on success
#' @keywords internal
#' @noRd
write_boilerplate_db <- function(db, file_path, format = "json", pretty = TRUE) {
  # only create directory if it doesn't exist
  dir_path <- dirname(file_path)
  if (!dir.exists(dir_path)) {
    stop("Directory does not exist: ", dir_path, ". Directory must be created explicitly by the user or calling function.")
  }

  if (format %in% c("json", "both")) {
    if (!requireNamespace("jsonlite", quietly = TRUE)) {
      stop("Package 'jsonlite' is required for JSON support. Please install it.")
    }

    json_path <- if (tools::file_ext(file_path) == "json") {
      file_path
    } else {
      sub("\\.rds$", ".json", file_path)
    }

    jsonlite::write_json(
      db,
      json_path,
      pretty = pretty,
      auto_unbox = TRUE,
      null = "null"
    )
  }

  if (format %in% c("rds", "both")) {
    rds_path <- if (tools::file_ext(file_path) == "rds") {
      file_path
    } else {
      sub("\\.json$", ".rds", file_path)
    }
    saveRDS(db, rds_path)
  }

  invisible(TRUE)
}

#' Standardise JSON Structure
#'
#' Internal function to ensure JSON structure matches expected RDS structure.
#' Handles NULL values and structural differences between formats.
#'
#' @param db Database from JSON
#' @return Standardised database
#' @keywords internal
#' @noRd
standardise_json_structure <- function(db) {
  # Handle any structural differences between JSON and RDS formats
  # For example, ensure NULL values are properly handled
  recursive_null_fix <- function(x) {
    if (is.list(x)) {
      lapply(x, function(item) {
        if (is.null(item) || (is.character(item) && length(item) == 1 && item == "null")) {
          NULL
        } else {
          recursive_null_fix(item)
        }
      })
    } else {
      x
    }
  }

  recursive_null_fix(db)
}

#' Convert RDS Database to JSON
#'
#' Utility function to convert existing RDS databases to JSON format. Can convert
#' a single file or batch convert all RDS files in a directory.
#'
#' @param input_path Path to RDS file or directory containing RDS files
#' @param output_path Path to save JSON files. If NULL, saves in same location
#'   as input with .json extension.
#' @param pretty Pretty print JSON for readability? Default is TRUE.
#' @param quiet Suppress messages? Default is FALSE.
#'
#' @return Invisible TRUE on success
#'
#' @details
#' This function is useful for migrating existing RDS-based databases to the
#' more portable JSON format. JSON files are human-readable, work well with
#' version control, and can be used across different programming languages.
#'
#' @examples
#' \donttest{
#' # Create temporary directory for example
#' temp_dir <- tempfile()
#' dir.create(temp_dir)
#' 
#' # Create sample RDS file
#' sample_db <- list(methods = list(sampling = "Random sampling"))
#' saveRDS(sample_db, file.path(temp_dir, "methods_db.rds"))
#' 
#' # Convert single file
#' boilerplate_rds_to_json(file.path(temp_dir, "methods_db.rds"))
#'
#' # Convert all RDS files in directory
#' boilerplate_rds_to_json(temp_dir)
#'
#' # Convert to different location
#' output_dir <- tempfile()
#' dir.create(output_dir)
#' boilerplate_rds_to_json(temp_dir, output_path = output_dir)
#' 
#' # Clean up
#' unlink(temp_dir, recursive = TRUE)
#' unlink(output_dir, recursive = TRUE)
#' }
#'
#' @seealso \code{\link{boilerplate_migrate_to_json}} for full migration workflow
#'
#' @export
boilerplate_rds_to_json <- function(
    input_path,
    output_path = NULL,
    pretty = TRUE,
    quiet = FALSE
) {
  if (dir.exists(input_path)) {
    # Convert all RDS files in directory
    rds_files <- list.files(input_path, pattern = "\\.rds$", full.names = TRUE)

    if (length(rds_files) == 0) {
      if (!quiet) cli::cli_alert_warning("No RDS files found in {input_path}")
      return(invisible(FALSE))
    }

    for (rds_file in rds_files) {
      if (!quiet) cli::cli_alert_info("Converting {basename(rds_file)}")

      db <- readRDS(rds_file)
      json_file <- sub("\\.rds$", ".json", rds_file)

      if (!is.null(output_path)) {
        json_file <- file.path(output_path, basename(json_file))
      }

      write_boilerplate_db(db, json_file, format = "json", pretty = pretty)

      if (!quiet) cli::cli_alert_success("Created {basename(json_file)}")
    }
  } else {
    # Convert single file
    if (!file.exists(input_path)) {
      stop("File not found: ", input_path)
    }

    db <- readRDS(input_path)
    json_file <- if (!is.null(output_path)) {
      output_path
    } else {
      sub("\\.rds$", ".json", input_path)
    }

    write_boilerplate_db(db, json_file, format = "json", pretty = pretty)

    if (!quiet) cli::cli_alert_success("Converted to {json_file}")
  }

  invisible(TRUE)
}


