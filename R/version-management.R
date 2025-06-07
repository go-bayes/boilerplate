#' List Available boilerplate Database Files
#'
#' Lists all boilerplate database files in a directory, organised by type
#' (standard, timestamped, or backup).
#'
#' @param data_path Character. Path to the directory containing database files.
#'   If NULL (default), uses here::here("boilerplate", "data").
#' @param pattern Character. Optional regex pattern to filter files.
#' @param category Character. Optional category to filter results.
#'   Options include "measures", "methods", "results", "discussion", 
#'   "appendix", "template", or "unified".
#'
#' @return A list with class "boilerplate_files" containing:
#'   \item{standard}{Data frame of standard database files}
#'   \item{timestamped}{Data frame of timestamped versions}
#'   \item{backups}{Data frame of backup files}
#'   \item{other}{Data frame of other files that match the pattern}
#'   
#'   Each data frame contains columns: file, path, size, modified, format,
#'   base_name, timestamp, type, and category.
#'
#' @examples
#' \dontrun{
#' # List all database files
#' files <- boilerplate_list_files()
#' print(files)
#' 
#' # List only methods files
#' files <- boilerplate_list_files(category = "methods")
#' 
#' # List files matching a pattern
#' files <- boilerplate_list_files(pattern = "2024")
#' }
#'
#' @seealso \code{\link{boilerplate_import}} for importing the listed files,
#'   \code{\link{boilerplate_restore_backup}} for restoring from backups.
#'
#' @export
boilerplate_list_files <- function(data_path = NULL, pattern = NULL, category = NULL) {
  # Set default data path
  if (is.null(data_path)) {
    data_path <- here::here("boilerplate", "data")
  }
  
  if (!dir.exists(data_path)) {
    stop("Directory does not exist: ", data_path)
  }
  
  # Get all files
  all_files <- list.files(data_path, full.names = TRUE)
  
  # Filter by pattern if provided
  if (!is.null(pattern)) {
    all_files <- all_files[grepl(pattern, basename(all_files))]
  }
  
  # Filter for database files only (.rds or .json)
  db_files <- all_files[grepl("\\.(rds|json)$", all_files, ignore.case = TRUE)]
  
  if (length(db_files) == 0) {
    message("No database files found in: ", data_path)
    
    # Return empty structure
    empty_df <- data.frame(
      file = character(0),
      path = character(0),
      size = numeric(0),
      modified = as.POSIXct(character(0)),
      format = character(0),
      base_name = character(0),
      timestamp = character(0),
      type = character(0),
      category = character(0),
      stringsAsFactors = FALSE
    )
    
    result <- list(
      standard = empty_df,
      timestamped = empty_df,
      backups = empty_df,
      other = empty_df
    )
    
    class(result) <- c("boilerplate_files", "list")
    return(result)
  }
  
  # Define patterns for different file types
  standard_pattern <- "^(methods_db|measures_db|results_db|discussion_db|appendix_db|template_db|boilerplate_unified)\\.(rds|json)$"
  timestamp_pattern <- "_([0-9]{8}_[0-9]{6})\\.(rds|json)$"
  backup_pattern <- "_backup_([0-9]{8}_[0-9]{6})\\.(rds|json)$"
  
  # Create file info data frame
  files_info <- data.frame(
    file = basename(db_files),
    path = db_files,
    size = file.size(db_files),
    modified = file.mtime(db_files),
    stringsAsFactors = FALSE
  )
  
  # Add file metadata
  files_info$format <- ifelse(grepl("\\.rds$", files_info$file, ignore.case = TRUE), "rds", "json")
  
  # Extract base name (remove timestamp and extension)
  files_info$base_name <- gsub("(_[0-9]{8}_[0-9]{6}|_backup_[0-9]{8}_[0-9]{6})\\.(rds|json)$", "", files_info$file)
  
  # Extract timestamps
  files_info$timestamp <- NA_character_
  
  # Extract regular timestamps
  timestamp_matches <- regmatches(files_info$file, regexec(timestamp_pattern, files_info$file))
  for (i in seq_along(timestamp_matches)) {
    if (length(timestamp_matches[[i]]) > 1) {
      files_info$timestamp[i] <- timestamp_matches[[i]][2]
    }
  }
  
  # Extract backup timestamps
  backup_matches <- regmatches(files_info$file, regexec(backup_pattern, files_info$file))
  for (i in seq_along(backup_matches)) {
    if (length(backup_matches[[i]]) > 1) {
      files_info$timestamp[i] <- backup_matches[[i]][2]
    }
  }
  
  # Categorise files
  files_info$type <- "other"
  files_info$type[grepl(standard_pattern, files_info$file)] <- "standard"
  files_info$type[grepl(backup_pattern, files_info$file)] <- "backup"
  files_info$type[!is.na(files_info$timestamp) & files_info$type == "other"] <- "timestamped"
  
  # Extract category
  files_info$category <- NA_character_
  categories <- c("methods", "measures", "results", "discussion", "appendix", "template")
  
  for (cat in categories) {
    files_info$category[grepl(paste0("^", cat, "_db"), files_info$base_name)] <- cat
  }
  files_info$category[grepl("^boilerplate_unified", files_info$base_name)] <- "unified"
  
  # Filter by category if specified
  if (!is.null(category)) {
    files_info <- files_info[files_info$category == category & !is.na(files_info$category), ]
  }
  
  # Organise results
  result <- list(
    standard = files_info[files_info$type == "standard", ],
    timestamped = files_info[files_info$type == "timestamped", ],
    backups = files_info[files_info$type == "backup", ],
    other = files_info[files_info$type == "other", ]
  )
  
  # Sort by modified date (newest first)
  for (type in names(result)) {
    if (nrow(result[[type]]) > 0) {
      result[[type]] <- result[[type]][order(result[[type]]$modified, decreasing = TRUE), ]
      rownames(result[[type]]) <- NULL
    }
  }
  
  class(result) <- c("boilerplate_files", "list")
  result
}

#' Print Method for boilerplate_files
#'
#' @param x A boilerplate_files object from \code{\link{boilerplate_list_files}}
#' @param ... Additional arguments (ignored)
#'
#' @return Invisible NULL. Information is printed to the console.
#'
#' @export
print.boilerplate_files <- function(x, ...) {
  cat("\nboilerplate Database Files\n")
  cat("==========================\n\n")
  
  # Standard files
  if (nrow(x$standard) > 0) {
    cat("Standard files:\n")
    for (i in 1:nrow(x$standard)) {
      cat(sprintf("  - %s (modified: %s)\n", 
                  x$standard$file[i], 
                  format(x$standard$modified[i], "%Y-%m-%d %H:%M")))
    }
    cat("\n")
  }
  
  # Timestamped versions
  if (nrow(x$timestamped) > 0) {
    cat("Timestamped versions:\n")
    # Show first 5
    show_n <- min(5, nrow(x$timestamped))
    for (i in 1:show_n) {
      cat(sprintf("  - %s\n", x$timestamped$file[i]))
    }
    if (nrow(x$timestamped) > 5) {
      cat(sprintf("  ... and %d more\n", nrow(x$timestamped) - 5))
    }
    cat("\n")
  }
  
  # Backups
  if (nrow(x$backups) > 0) {
    cat("Backup files:\n")
    # Show first 5
    show_n <- min(5, nrow(x$backups))
    for (i in 1:show_n) {
      cat(sprintf("  - %s\n", x$backups$file[i]))
    }
    if (nrow(x$backups) > 5) {
      cat(sprintf("  ... and %d more\n", nrow(x$backups) - 5))
    }
    cat("\n")
  }
  
  # Other files
  if (nrow(x$other) > 0) {
    cat("Other files:\n")
    # Show first 3
    show_n <- min(3, nrow(x$other))
    for (i in 1:show_n) {
      cat(sprintf("  - %s\n", x$other$file[i]))
    }
    if (nrow(x$other) > 3) {
      cat(sprintf("  ... and %d more\n", nrow(x$other) - 3))
    }
    cat("\n")
  }
  
  # Summary
  total_files <- nrow(x$standard) + nrow(x$timestamped) + nrow(x$backups) + nrow(x$other)
  if (total_files == 0) {
    cat("No database files found.\n")
  } else {
    cat(sprintf("Total: %d files\n", total_files))
  }
  
  invisible(x)
}

#' Restore Database from Backup
#'
#' Convenience function to restore a database from backup files. Can either
#' import the backup for inspection or restore it as the current database.
#'
#' @param category Character. Category to restore, or NULL for unified database.
#' @param backup_version Character. Specific backup timestamp (format: "YYYYMMDD_HHMMSS"),
#'   or NULL to use the latest backup.
#' @param data_path Character. Path to directory containing backup files.
#'   If NULL (default), uses here::here("boilerplate", "data").
#' @param restore Logical. If TRUE, saves the backup as the current standard file
#'   (overwrites existing). If FALSE (default), just returns the backup content.
#' @param confirm Logical. If TRUE (default), asks for confirmation before overwriting.
#'   Ignored if restore = FALSE.
#' @param quiet Logical. If TRUE, suppresses messages. Default is FALSE.
#'
#' @return The restored database (invisibly if restore = TRUE).
#'
#' @examples
#' \dontrun{
#' # View latest methods backup without restoring
#' backup_db <- boilerplate_restore_backup("methods")
#' 
#' # Restore specific backup and overwrite current
#' db <- boilerplate_restore_backup(
#'   category = "methods",
#'   backup_version = "20240110_120000",
#'   restore = TRUE
#' )
#' 
#' # Restore latest unified backup
#' db <- boilerplate_restore_backup(restore = TRUE)
#' }
#'
#' @seealso \code{\link{boilerplate_list_files}} to see available backups,
#'   \code{\link{boilerplate_import}} for general import functionality.
#'
#' @export
boilerplate_restore_backup <- function(category = NULL,
                                      backup_version = NULL,
                                      data_path = NULL,
                                      restore = FALSE,
                                      confirm = TRUE,
                                      quiet = FALSE) {
  
  # List available files
  files <- boilerplate_list_files(data_path = data_path, category = category)
  
  # Filter to backups only
  backups <- files$backups
  
  if (nrow(backups) == 0) {
    stop("No backup files found", 
         if (!is.null(category)) paste0(" for category: ", category) else "")
  }
  
  # Select backup to restore
  if (!is.null(backup_version)) {
    # Find specific version
    selected <- backups[backups$timestamp == backup_version, ]
    if (nrow(selected) == 0) {
      stop("No backup found with timestamp: ", backup_version)
    }
    backup_file <- selected$path[1]
  } else {
    # Use latest backup (already sorted by date)
    backup_file <- backups$path[1]
    backup_version <- backups$timestamp[1]
  }
  
  if (!quiet) {
    cli::cli_alert_info("Using backup: {basename(backup_file)}")
  }
  
  # Import the backup
  db <- boilerplate_import(data_path = backup_file, quiet = quiet)
  
  # Optionally restore as standard file
  if (restore) {
    if (!quiet) {
      cli::cli_alert_info("Preparing to restore backup as current database...")
    }
    
    # Determine the target file
    if (is.null(data_path)) {
      data_path <- here::here("boilerplate", "data")
    }
    
    # Save as standard file (this will create its own backup!)
    boilerplate_save(
      db = db,
      category = category,
      data_path = data_path,
      timestamp = FALSE,
      create_backup = TRUE,  # Create backup of current before overwriting
      confirm = confirm,
      quiet = quiet
    )
    
    if (!quiet) {
      cli::cli_alert_success("Restored backup from {backup_version}")
    }
    
    return(invisible(db))
  } else {
    if (!quiet) {
      cli::cli_alert_success("Loaded backup from {backup_version} (not restored)")
    }
    return(db)
  }
}