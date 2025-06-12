#' Copy Elements from One Project to Another
#'
#' This function allows selective copying of boilerplate elements from one project
#' to another, enabling controlled sharing of content between projects.
#'
#' @param from_project Character. Name of the source project.
#' @param to_project Character. Name of the destination project.
#' @param paths Character vector. Paths to copy (e.g., c("measures.anxiety", "methods.sampling")).
#'   If NULL, copies everything (requires confirmation).
#' @param prefix Character. Optional prefix to add to copied entries to avoid conflicts.
#'   For example, prefix = "colleague_" would rename "anxiety" to "colleague_anxiety".
#' @param data_path Character. Base path for boilerplate data. If NULL, uses default location.
#' @param merge_strategy Character. How to handle conflicts: "skip", "overwrite", or "rename".
#' @param confirm Logical. If TRUE, asks for confirmation. Default is TRUE.
#' @param quiet Logical. If TRUE, suppresses messages. Default is FALSE.
#'
#' @return Invisibly returns the updated database from the destination project.
#'
#' @examples
#' \donttest{
#' # Create temporary directory for example
#' temp_dir <- tempfile()
#' dir.create(temp_dir)
#' 
#' # Initialize two projects
#' boilerplate_init(data_path = temp_dir, project = "colleague_measures", 
#'                  create_dirs = TRUE, confirm = FALSE, quiet = TRUE)
#' boilerplate_init(data_path = temp_dir, project = "my_research", 
#'                  create_dirs = TRUE, confirm = FALSE, quiet = TRUE)
#' 
#' # Add some content to source project
#' source_db <- boilerplate_import(data_path = temp_dir, 
#'                                  project = "colleague_measures", quiet = TRUE)
#' source_db$measures$anxiety <- list(name = "Anxiety Scale", items = 10)
#' source_db$measures$depression <- list(name = "Depression Scale", items = 20)
#' boilerplate_save(source_db, data_path = temp_dir, 
#'                  project = "colleague_measures", confirm = FALSE, quiet = TRUE)
#' 
#' # Copy specific measures from colleague's project
#' boilerplate_copy_from_project(
#'   from_project = "colleague_measures",
#'   to_project = "my_research",
#'   paths = c("measures.anxiety", "measures.depression"),
#'   prefix = "smith_",
#'   data_path = temp_dir,
#'   confirm = FALSE,
#'   quiet = TRUE
#' )
#' 
#' # Clean up
#' unlink(temp_dir, recursive = TRUE)
#' }
#'
#' @export
boilerplate_copy_from_project <- function(
    from_project,
    to_project,
    paths = NULL,
    prefix = NULL,
    data_path = NULL,
    merge_strategy = c("skip", "overwrite", "rename"),
    confirm = TRUE,
    quiet = FALSE
) {
  merge_strategy <- match.arg(merge_strategy)
  
  # Validate project names
  if (!is.character(from_project) || length(from_project) != 1 || from_project == "") {
    stop("from_project must be a non-empty character string")
  }
  if (!is.character(to_project) || length(to_project) != 1 || to_project == "") {
    stop("to_project must be a non-empty character string")
  }
  if (from_project == to_project) {
    stop("Source and destination projects must be different")
  }
  
  # Import source database
  if (!quiet) cli::cli_alert_info("Loading source project: {from_project}")
  source_db <- boilerplate_import(data_path = data_path, project = from_project, quiet = TRUE)
  
  if (length(source_db) == 0) {
    stop("Source project '", from_project, "' is empty or does not exist")
  }
  
  # Import destination database
  if (!quiet) cli::cli_alert_info("Loading destination project: {to_project}")
  tryCatch({
    dest_db <- boilerplate_import(data_path = data_path, project = to_project, quiet = TRUE)
  }, error = function(e) {
    # If destination doesn't exist, create empty structure
    dest_db <- list()
  })
  
  # Extract selected elements if paths specified
  if (!is.null(paths)) {
    if (!quiet) cli::cli_alert_info("Extracting {length(paths)} specified path(s)")
    selected_elements <- list()
    
    # Extract specified paths manually
    for (path in paths) {
      parts <- strsplit(path, "\\.")[[1]]
      if (length(parts) >= 1) {
        category <- parts[1]
        if (category %in% names(source_db)) {
          if (length(parts) == 1) {
            # Copy entire category
            selected_elements[[category]] <- source_db[[category]]
          } else if (length(parts) == 2) {
            # Copy specific entry
            entry <- parts[2]
            if (entry %in% names(source_db[[category]])) {
              if (!category %in% names(selected_elements)) {
                selected_elements[[category]] <- list()
              }
              selected_elements[[category]][[entry]] <- source_db[[category]][[entry]]
            }
          }
        }
      }
    }
    
    if (length(selected_elements) == 0) {
      stop("No elements found matching the specified paths")
    }
  } else {
    # Copy everything - requires confirmation
    if (confirm) {
      if (!quiet) cli::cli_alert_warning("No paths specified - this will copy ALL content from {from_project}")
      proceed <- ask_yes_no("Copy ALL content from project?")
      if (!proceed) {
        if (!quiet) cli::cli_alert_info("Copy cancelled")
        return(invisible(NULL))
      }
    }
    selected_elements <- source_db
  }
  
  # Apply prefix if specified
  if (!is.null(prefix)) {
    if (!quiet) cli::cli_alert_info("Applying prefix '{prefix}' to copied entries")
    selected_elements <- apply_prefix_to_entries(selected_elements, prefix)
  }
  
  # Merge with destination based on strategy
  conflicts <- find_conflicts(dest_db, selected_elements)
  
  if (length(conflicts) > 0) {
    if (!quiet) cli::cli_alert_warning("Found {length(conflicts)} conflicting entries")
    
    if (merge_strategy == "skip") {
      # Remove conflicting entries from selection
      for (conflict in conflicts) {
        selected_elements <- remove_path(selected_elements, conflict)
      }
      if (!quiet) cli::cli_alert_info("Skipping {length(conflicts)} conflicting entries")
      
    } else if (merge_strategy == "overwrite") {
      if (confirm) {
        proceed <- ask_yes_no(paste0("Overwrite ", length(conflicts), " existing entries?"))
        if (!proceed) {
          if (!quiet) cli::cli_alert_info("Copy cancelled")
          return(invisible(NULL))
        }
      }
      if (!quiet) cli::cli_alert_info("Overwriting {length(conflicts)} existing entries")
      
    } else if (merge_strategy == "rename") {
      # Add numeric suffix to conflicting entries
      selected_elements <- rename_conflicts(selected_elements, conflicts, dest_db)
      if (!quiet) cli::cli_alert_info("Renamed {length(conflicts)} conflicting entries")
    }
  }
  
  # Merge databases
  merged_db <- merge_recursive_lists(dest_db, selected_elements)
  
  # Save updated destination database
  if (!quiet) cli::cli_alert_info("Saving to project: {to_project}")
  boilerplate_save(
    merged_db,
    data_path = data_path,
    project = to_project,
    confirm = FALSE,
    quiet = quiet
  )
  
  # Report results
  if (!quiet) {
    cli::cli_alert_success("Successfully copied content from '{from_project}' to '{to_project}'")
    
    # Count what was copied
    count_info <- count_entries(selected_elements)
    for (cat in names(count_info)) {
      cli::cli_alert_info("{cat}: {count_info[[cat]]} entries")
    }
  }
  
  invisible(merged_db)
}


#' List Available Projects
#'
#' Lists all available boilerplate projects in the specified data path.
#'
#' @param data_path Character. Base path for boilerplate data. If NULL, uses default location.
#' @param details Logical. If TRUE, shows additional information about each project.
#'
#' @return Character vector of project names.
#'
#' @examples
#' \donttest{
#' # Create temporary directory for example
#' temp_dir <- tempfile()
#' dir.create(temp_dir)
#' 
#' # Initialize some projects
#' boilerplate_init(data_path = temp_dir, project = "project1", 
#'                  create_dirs = TRUE, confirm = FALSE, quiet = TRUE)
#' boilerplate_init(data_path = temp_dir, project = "project2", 
#'                  create_dirs = TRUE, confirm = FALSE, quiet = TRUE)
#' 
#' # List all projects
#' projects <- boilerplate_list_projects(data_path = temp_dir)
#' print(projects)
#'
#' # List with details
#' boilerplate_list_projects(data_path = temp_dir, details = TRUE)
#' 
#' # Clean up
#' unlink(temp_dir, recursive = TRUE)
#' }
#'
#' @export
boilerplate_list_projects <- function(data_path = NULL, details = FALSE) {
  # Set default path
  if (is.null(data_path)) {
    base_path <- here::here("boilerplate", "projects")
  } else {
    base_path <- file.path(data_path, "projects")
  }
  
  if (!dir.exists(base_path)) {
    if (!details) {
      return(character(0))
    } else {
      cli::cli_alert_info("No projects directory found at: {base_path}")
      return(NULL)
    }
  }
  
  # List subdirectories
  projects <- list.dirs(base_path, full.names = FALSE, recursive = FALSE)
  projects <- projects[projects != ""]
  
  if (length(projects) == 0) {
    if (details) {
      cli::cli_alert_info("No projects found")
    }
    return(character(0))
  }
  
  if (!details) {
    return(projects)
  }
  
  # Show details
  cli::cli_h1("Available Boilerplate Projects")
  
  for (proj in projects) {
    proj_path <- file.path(base_path, proj, "data")
    
    if (dir.exists(proj_path)) {
      # Count files
      files <- list.files(proj_path, pattern = "\\.(rds|json)$")
      
      # Check for unified database
      has_unified <- any(grepl("boilerplate_unified", files))
      
      # Get modification time
      mod_time <- file.info(proj_path)$mtime
      
      cli::cli_alert_info(
        "{.strong {proj}} - {length(files)} file(s), {if (has_unified) 'unified' else 'separate'} format, modified {format(mod_time, '%Y-%m-%d')}"
      )
    }
  }
  
  invisible(projects)
}


# Helper functions (not exported)

#' Apply prefix to all top-level entries in a database
#' @noRd
apply_prefix_to_entries <- function(db, prefix) {
  if (!is.list(db)) return(db)
  
  result <- list()
  for (name in names(db)) {
    # Apply prefix to top-level names in each category
    if (is.list(db[[name]])) {
      result[[name]] <- list()
      for (entry_name in names(db[[name]])) {
        new_name <- paste0(prefix, entry_name)
        result[[name]][[new_name]] <- db[[name]][[entry_name]]
      }
    } else {
      result[[name]] <- db[[name]]
    }
  }
  
  result
}


#' Find conflicting paths between two databases
#' @noRd
find_conflicts <- function(db1, db2) {
  conflicts <- character()
  
  for (cat in intersect(names(db1), names(db2))) {
    if (is.list(db1[[cat]]) && is.list(db2[[cat]])) {
      for (entry in intersect(names(db1[[cat]]), names(db2[[cat]]))) {
        conflicts <- c(conflicts, paste0(cat, ".", entry))
      }
    }
  }
  
  conflicts
}


#' Remove a path from a database
#' @noRd
remove_path <- function(db, path) {
  parts <- strsplit(path, "\\.")[[1]]
  
  if (length(parts) == 2) {
    cat <- parts[1]
    entry <- parts[2]
    
    if (cat %in% names(db) && entry %in% names(db[[cat]])) {
      db[[cat]][[entry]] <- NULL
      if (length(db[[cat]]) == 0) {
        db[[cat]] <- NULL
      }
    }
  }
  
  db
}


#' Rename conflicting entries by adding numeric suffix
#' @noRd
rename_conflicts <- function(db, conflicts, existing_db) {
  for (conflict in conflicts) {
    parts <- strsplit(conflict, "\\.")[[1]]
    if (length(parts) == 2) {
      cat <- parts[1]
      entry <- parts[2]
      
      if (cat %in% names(db) && entry %in% names(db[[cat]])) {
        # Find a unique name
        counter <- 2
        new_name <- paste0(entry, "_", counter)
        
        while (new_name %in% names(existing_db[[cat]])) {
          counter <- counter + 1
          new_name <- paste0(entry, "_", counter)
        }
        
        # Rename
        db[[cat]][[new_name]] <- db[[cat]][[entry]]
        db[[cat]][[entry]] <- NULL
      }
    }
  }
  
  db
}


#' Count entries in each category
#' @noRd
count_entries <- function(db) {
  counts <- list()
  
  for (cat in names(db)) {
    if (is.list(db[[cat]])) {
      counts[[cat]] <- length(db[[cat]])
    }
  }
  
  counts
}


#' Merge two lists recursively
#' @noRd
merge_recursive_lists <- function(list1, list2) {
  if (!is.list(list1) || !is.list(list2)) {
    return(list2)
  }
  
  result <- list1
  
  for (name in names(list2)) {
    if (name %in% names(result) && is.list(result[[name]]) && is.list(list2[[name]])) {
      result[[name]] <- merge_recursive_lists(result[[name]], list2[[name]])
    } else {
      result[[name]] <- list2[[name]]
    }
  }
  
  result
}


#' Ask yes/no question
#' @noRd
ask_yes_no <- function(prompt) {
  if (!interactive()) return(TRUE)
  
  response <- readline(paste0(prompt, " [y/n]: "))
  tolower(response) %in% c("y", "yes")
}