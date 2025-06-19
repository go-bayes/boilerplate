# internal function to migrate cache from old location to new cran-compliant location
migrate_old_cache <- function() {
  old_cache <- path.expand("~/.boilerplate/cache")
  new_cache <- tools::R_user_dir("boilerplate", "cache")
  
  if (dir.exists(old_cache) && !identical(old_cache, new_cache)) {
    if (!dir.exists(new_cache)) {
      dir.create(new_cache, recursive = TRUE, showWarnings = FALSE)
    }
    # copy files from old to new location
    files <- list.files(old_cache, full.names = TRUE)
    if (length(files) > 0) {
      file.copy(files, new_cache, overwrite = FALSE)
      message("Migrated bibliography cache from old location to ", new_cache)
    }
  }
}

#' Update Bibliography from Remote Source
#'
#' Downloads and caches a bibliography file from a remote URL specified in the database.
#'
#' @param db Database object containing bibliography information
#' @param cache_dir Directory to cache the bibliography file.
#'   Default uses tools::R_user_dir("boilerplate", "cache")
#' @param force Logical. Force re-download even if cached file exists
#' @param quiet Logical. Suppress messages
#'
#' @return Path to the local bibliography file, or NULL if no bibliography specified
#'
#' @examples
#' \donttest{
#' # Create temporary directory for example
#' temp_dir <- tempfile()
#' dir.create(temp_dir)
#' 
#' # Initialize and import
#' boilerplate_init(data_path = temp_dir, create_dirs = TRUE, confirm = FALSE, quiet = TRUE)
#' db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)
#' 
#' # Update bibliography
#' bib_file <- boilerplate_update_bibliography(db)
#' 
#' # Clean up
#' unlink(temp_dir, recursive = TRUE)
#' }
#'
#' @importFrom utils download.file
#' @export
boilerplate_update_bibliography <- function(
  db,
    cache_dir = NULL,
    force = FALSE,
    quiet = FALSE
) {
  # use cran-compliant cache directory
  if (is.null(cache_dir)) {
    cache_dir <- tools::R_user_dir("boilerplate", "cache")
    # migrate from old location if needed
    migrate_old_cache()
  }
  
  # Extract bibliography info
  bib_info <- if (is.list(db) && "bibliography" %in% names(db)) {
    db$bibliography
  } else {
    NULL
  }

  if (is.null(bib_info) || is.null(bib_info$url)) {
    if (!quiet) cli::cli_alert_info("No bibliography URL specified in database")
    return(invisible(NULL))
  }

  # Ensure cache directory exists
  cache_dir <- path.expand(cache_dir)
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  }

  # Determine local file path
  local_filename <- if (!is.null(bib_info$local_path)) {
    basename(bib_info$local_path)
  } else {
    basename(bib_info$url)
  }

  local_file <- file.path(cache_dir, local_filename)

  # Check if download is needed
  download_needed <- force || !file.exists(local_file)
  if (file.exists(local_file) && !force) {
    # Check file age
    file_age <- difftime(Sys.time(), file.mtime(local_file), units = "days")
    if (file_age > 7 && !quiet) {
      cli::cli_alert_warning("Bibliography cache is {round(file_age, 1)} days old. Consider using force=TRUE to update.")
    }
  }

  # Download if needed
  if (download_needed) {
    if (!quiet) cli::cli_alert_info("Downloading bibliography from {bib_info$url}")

    tryCatch({
      # Use download.file with appropriate method
      utils::download.file(
        url = bib_info$url,
        destfile = local_file,
        quiet = quiet,
        mode = "wb"
      )

      if (!quiet) cli::cli_alert_success("Downloaded bibliography to {local_file}")
    }, error = function(e) {
      cli::cli_alert_danger("Failed to download bibliography: {e$message}")
      return(NULL)
    })
  } else {
    if (!quiet) cli::cli_alert_info("Using cached bibliography from {local_file}")
  }

  return(local_file)
}

#' Copy Bibliography to Project Directory
#'
#' Copies the bibliography file from cache to a specified directory,
#' typically for use with Quarto documents.
#'
#' @param db Database object containing bibliography information
#' @param target_dir Directory to copy the bibliography file to. Default is current directory.
#' @param overwrite Logical. Whether to overwrite existing file
#' @param update_first Logical. Whether to update from remote before copying
#' @param quiet Logical. Suppress messages
#'
#' @return Path to the copied bibliography file, or NULL if operation failed
#'
#' @examples
#' \donttest{
#' # Create temporary directory for example
#' temp_dir <- tempfile()
#' dir.create(temp_dir)
#' 
#' # Initialize and import
#' boilerplate_init(data_path = temp_dir, create_dirs = TRUE, confirm = FALSE, quiet = TRUE)
#' db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)
#' 
#' # Copy bibliography
#' boilerplate_copy_bibliography(db, temp_dir)
#' 
#' # Clean up
#' unlink(temp_dir, recursive = TRUE)
#' }
#'
#' @export
boilerplate_copy_bibliography <- function(
  db,
    target_dir = ".",
    overwrite = TRUE,
    update_first = FALSE,
    quiet = FALSE
) {
  # Get bibliography from cache
  if (update_first) {
    bib_file <- boilerplate_update_bibliography(db, force = TRUE, quiet = quiet)
  } else {
    bib_file <- boilerplate_update_bibliography(db, force = FALSE, quiet = quiet)
  }

  if (is.null(bib_file) || !file.exists(bib_file)) {
    return(invisible(NULL))
  }

  # Determine target filename
  bib_info <- db$bibliography
  target_filename <- if (!is.null(bib_info$local_path)) {
    basename(bib_info$local_path)
  } else {
    basename(bib_file)
  }

  target_path <- file.path(target_dir, target_filename)

  # Check if file exists
  if (file.exists(target_path) && !overwrite) {
    if (!quiet) cli::cli_alert_warning("Bibliography already exists at {target_path}. Use overwrite=TRUE to replace.")
    return(invisible(target_path))
  }

  # Copy file
  success <- file.copy(bib_file, target_path, overwrite = overwrite)

  if (success) {
    if (!quiet) cli::cli_alert_success("Bibliography copied to {target_path}")
    return(target_path)
  } else {
    cli::cli_alert_danger("Failed to copy bibliography to {target_path}")
    return(invisible(NULL))
  }
}

#' Parse BibTeX File
#'
#' Internal function to parse a BibTeX file and extract citation keys.
#' This is a simple parser that extracts entry types and keys.
#'
#' @param bib_file Path to the BibTeX file
#'
#' @return Character vector of citation keys
#'
#' @noRd
parse_bibtex_keys <- function(bib_file) {
  if (!file.exists(bib_file)) {
    return(character(0))
  }

  # Read file
  bib_content <- readLines(bib_file, warn = FALSE)

  # Pattern to match BibTeX entries: @type{key,
  # This regex captures the key after @ and before the comma
  pattern <- "^\\s*@[a-zA-Z]+\\s*\\{\\s*([^,\\s]+)"

  # Extract keys
  keys <- character(0)
  for (line in bib_content) {
    match <- regexpr(pattern, line, perl = TRUE)
    if (match[1] > 0) {
      # Extract the captured group (the key)
      key <- regmatches(line, match)
      key <- gsub(pattern, "\\1", key, perl = TRUE)
      keys <- c(keys, key)
    }
  }

  return(unique(keys))
}

#' Extract Citation Keys from Text
#'
#' Internal function to extract citation keys from boilerplate text.
#'
#' @param text Character vector of text to search
#'
#' @return Character vector of unique citation keys
#'
#' @noRd
extract_citation_keys <- function(text) {
  if (length(text) == 0 || all(is.na(text))) {
    return(character(0))
  }

  # Combine all text into a single string to avoid indexing issues
  all_text <- paste(text, collapse = " ")

  # Patterns for different citation formats
  patterns <- c(
    "@([a-zA-Z0-9_:-]+)",           # Standard @key format
    "\\[@([a-zA-Z0-9_:-]+)\\]",     # [@key] format
    "\\[@([a-zA-Z0-9_:-]+);",       # [@key; ...] format (first key)
    ";\\s*@([a-zA-Z0-9_:-]+)"       # [@key1; @key2] format (subsequent keys)
  )

  all_keys <- character(0)

  for (pattern in patterns) {
    matches <- gregexpr(pattern, all_text, perl = TRUE)

    if (matches[[1]][1] > 0) {
      # Extract all matches
      matched_text <- regmatches(all_text, matches)[[1]]
      # Extract just the keys
      keys <- gsub(pattern, "\\1", matched_text, perl = TRUE)
      all_keys <- c(all_keys, keys)
    }
  }

  # Clean up keys - remove @ symbols and brackets
  all_keys <- gsub("^@", "", all_keys)
  all_keys <- gsub("\\]$", "", all_keys)
  all_keys <- gsub("^\\[", "", all_keys)

  return(unique(all_keys))
}

#' Extract All Text from Database
#'
#' Internal function to recursively extract all text content from a database.
#'
#' @param db Database or database section
#'
#' @return Character vector of all text content
#'
#' @noRd
extract_all_text <- function(db) {
  text_content <- character(0)

  if (is.character(db)) {
    return(db)
  } else if (is.list(db)) {
    for (item in db) {
      text_content <- c(text_content, extract_all_text(item))
    }
  }

  return(text_content)
}

#' Validate References in boilerplate Database
#'
#' Checks that all citations in the boilerplate text exist in the bibliography file.
#'
#' @param db Database object to validate
#' @param bib_file Path to bibliography file. If NULL, will try to download from database
#' @param categories Character vector of categories to check.
#'   Default is all text categories.
#' @param quiet Logical. Suppress detailed messages
#'
#' @return List with validation results including used keys, available keys, and missing keys
#'
#' @examples
#' \donttest{
#' # Create temporary directory for example
#' temp_dir <- tempfile()
#' dir.create(temp_dir)
#' 
#' # Initialize and import
#' boilerplate_init(data_path = temp_dir, create_dirs = TRUE, confirm = FALSE, quiet = TRUE)
#' db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)
#' 
#' # Validate references
#' validation <- boilerplate_validate_references(db)
#' if (length(validation$missing) > 0) {
#'   warning("Missing references: ", paste(validation$missing, collapse = ", "))
#' }
#' 
#' # Clean up
#' unlink(temp_dir, recursive = TRUE)
#' }
#'
#' @export
boilerplate_validate_references <- function(
  db,
    bib_file = NULL,
    categories = c("methods", "results", "discussion", "appendix"),
    quiet = FALSE
) {
  # Get bibliography file
  if (is.null(bib_file)) {
    bib_file <- boilerplate_update_bibliography(db, quiet = quiet)
    if (is.null(bib_file)) {
      if (!quiet) cli::cli_alert_warning("No bibliography file available for validation")
      return(list(
        used = character(0),
        available = character(0),
        missing = character(0),
        valid = FALSE
      ))
    }
  }

  # Parse bibliography
  if (!quiet) cli::cli_alert_info("Parsing bibliography file")
  available_keys <- parse_bibtex_keys(bib_file)

  if (!quiet) cli::cli_alert_info("Found {length(available_keys)} references in bibliography")

  # Extract text from specified categories
  all_text <- character(0)
  for (category in categories) {
    if (category %in% names(db)) {
      if (!quiet) cli::cli_alert_info("Checking {category} for citations")
      category_text <- extract_all_text(db[[category]])
      all_text <- c(all_text, category_text)
    }
  }

  # Extract citation keys
  used_keys <- extract_citation_keys(all_text)

  if (!quiet) cli::cli_alert_info("Found {length(used_keys)} citations in text")

  # Find missing references
  missing <- setdiff(used_keys, available_keys)
  # Report results
  if (!quiet) {
    if (length(missing) > 0) {
      cli::cli_alert_warning("Missing {length(missing)} references:")
      for (key in missing) {
        cli::cli_alert_danger("  - @{key}")
      }
    } else if (length(used_keys) > 0) {
      cli::cli_alert_success("All {length(used_keys)} citations have corresponding references")
    } else {
      cli::cli_alert_info("No citations found in text")
    }
  }

  # Find unused references (optional information)
  unused <- setdiff(available_keys, used_keys)

  return(list(
    used = used_keys,
    available = available_keys,
    missing = missing,
    unused = unused,
    valid = length(missing) == 0
  ))
}

#' Add Bibliography to Database
#'
#' Adds or updates bibliography information in a boilerplate database.
#'
#' @param db Database object
#' @param url URL to the bibliography file
#' @param local_path Local filename to use when copying (default: basename of URL)
#' @param validate Whether to validate citations on updates
#'
#' @return Updated database object
#'
#' @examples
#' \donttest{
#' # Create temporary directory for example
#' temp_dir <- tempfile()
#' dir.create(temp_dir)
#' 
#' # Initialize and import
#' boilerplate_init(data_path = temp_dir, create_dirs = TRUE, confirm = FALSE, quiet = TRUE)
#' db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)
#' 
#' # Add bibliography
#' db <- boilerplate_add_bibliography(
#'   db,
#'   url = "https://raw.githubusercontent.com/go-bayes/templates/main/bib/references.bib",
#'   local_path = "references.bib"
#' )
#' 
#' # Save the updated database
#' boilerplate_save(db, data_path = temp_dir, confirm = FALSE, quiet = TRUE)
#' 
#' # Clean up
#' unlink(temp_dir, recursive = TRUE)
#' }
#'
#' @export
boilerplate_add_bibliography <- function(
  db,
    url,
    local_path = NULL,
    validate = TRUE
) {
  if (is.null(local_path)) {
    local_path <- basename(url)
  }

  db$bibliography <- list(
    url = url,
    local_path = local_path,
    validate = validate,
    last_updated = Sys.time()
  )

  cli::cli_alert_success("Bibliography information added to database")
  cli::cli_alert_info("URL: {url}")
  cli::cli_alert_info("Local path: {local_path}")

  return(db)
}