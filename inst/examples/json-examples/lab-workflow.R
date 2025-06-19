# Lab Workflow: Central JSON Database with Project Copies
# This example shows how to use a central GitHub repository for your lab's boilerplate content

library(boilerplate)
library(cli)

# Configuration
CENTRAL_REPO <- "https://raw.githubusercontent.com/go-bayes/templates/main/boilerplate_data/"
LOCAL_CACHE <- file.path(tools::R_user_dir("boilerplate", "cache"), "lab_workflow")
PROJECT_DATA <- "data/boilerplate/"

# 1. Setup function for new projects
# ----------------------------------
setup_boilerplate_for_project <- function(
    project_path = ".",
    use_cache = TRUE,
    categories = NULL  # NULL means all categories
) {
  
  cli_h1("Setting up boilerplate for project")
  
  # Create project data directory
  data_path <- file.path(project_path, PROJECT_DATA)
  dir.create(data_path, recursive = TRUE, showWarnings = FALSE)
  
  # Check for cached version first
  cache_path <- path.expand(LOCAL_CACHE)
  cache_file <- file.path(cache_path, "boilerplate_unified.json")
  
  if (use_cache && file.exists(cache_file)) {
    cache_age <- difftime(Sys.time(), file.mtime(cache_file), units = "days")
    cli_alert_info("Using cached database (age: {round(cache_age, 1)} days)")
    
    if (cache_age > 7) {
      cli_alert_warning("Cache is older than 7 days, consider updating")
    }
    
    # Copy from cache
    file.copy(cache_file, file.path(data_path, "boilerplate_unified.json"))
    
  } else {
    # Download from GitHub
    cli_alert_info("Downloading from central repository")
    
    download.file(
      paste0(CENTRAL_REPO, "boilerplate_unified.json"),
      destfile = file.path(data_path, "boilerplate_unified.json"),
      quiet = TRUE
    )
    
    # Update cache
    if (use_cache) {
      dir.create(cache_path, recursive = TRUE, showWarnings = FALSE)
      file.copy(
        file.path(data_path, "boilerplate_unified.json"),
        cache_file,
        overwrite = TRUE
      )
    }
  }
  
  # Load and optionally filter categories
  db <- boilerplate_import(data_path = data_path)
  
  if (!is.null(categories)) {
    db <- db[categories]
    boilerplate_save(
      db = db,
      data_path = data_path,
      format = "json",
      confirm = FALSE,
      quiet = TRUE
    )
  }
  
  cli_alert_success("Boilerplate database ready at: {data_path}")
  
  # Create .gitignore to exclude from version control
  gitignore_path <- file.path(data_path, ".gitignore")
  if (!file.exists(gitignore_path)) {
    writeLines(c(
      "# Exclude boilerplate database from version control",
      "# Each project gets its own copy from central repo",
      "boilerplate_unified.json",
      "*.rds"
    ), gitignore_path)
    cli_alert_info("Created .gitignore to exclude database from git")
  }
  
  invisible(db)
}

# 2. Update from central repository
# ---------------------------------
update_from_central <- function(
    project_path = ".",
    backup = TRUE,
    show_changes = TRUE
) {
  
  cli_h1("Updating from central repository")
  
  data_path <- file.path(project_path, PROJECT_DATA)
  current_file <- file.path(data_path, "boilerplate_unified.json")
  
  # Backup current version
  if (backup && file.exists(current_file)) {
    backup_file <- file.path(
      data_path, 
      paste0("backup_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".json")
    )
    file.copy(current_file, backup_file)
    cli_alert_info("Backed up current database")
  }
  
  # Load current version
  if (file.exists(current_file) && show_changes) {
    current_db <- boilerplate_import(data_path = data_path)
  }
  
  # Download new version
  temp_file <- tempfile(fileext = ".json")
  download.file(
    paste0(CENTRAL_REPO, "boilerplate_unified.json"),
    destfile = temp_file,
    quiet = TRUE
  )
  
  # Show changes if requested
  if (show_changes && exists("current_db")) {
    new_db <- jsonlite::read_json(temp_file)
    
    # Compare versions
    changes <- compare_databases(current_db, new_db)
    if (length(changes$added) > 0) {
      cli_alert_info("New entries: {length(changes$added)}")
    }
    if (length(changes$modified) > 0) {
      cli_alert_info("Modified entries: {length(changes$modified)}")
    }
    if (length(changes$removed) > 0) {
      cli_alert_warning("Removed entries: {length(changes$removed)}")
    }
  }
  
  # Update file
  file.copy(temp_file, current_file, overwrite = TRUE)
  
  # Update cache
  cache_file <- file.path(path.expand(LOCAL_CACHE), "boilerplate_unified.json")
  file.copy(current_file, cache_file, overwrite = TRUE)
  
  cli_alert_success("Updated from central repository")
}

# 3. Submit changes back to central repo
# --------------------------------------
prepare_contribution <- function(
    project_path = ".",
    category = NULL,
    output_path = "contributions"
) {
  
  cli_h1("Preparing contribution for central repository")
  
  data_path <- file.path(project_path, PROJECT_DATA)
  db <- boilerplate_import(data_path = data_path)
  
  # Create contribution directory
  contrib_path <- file.path(project_path, output_path)
  dir.create(contrib_path, recursive = TRUE, showWarnings = FALSE)
  
  if (!is.null(category)) {
    # Export specific category
    contribution <- db[[category]]
    output_file <- file.path(contrib_path, paste0(category, "_contribution.json"))
  } else {
    # Export all
    contribution <- db
    output_file <- file.path(contrib_path, "boilerplate_contribution.json")
  }
  
  # Add metadata
  contribution[["_contribution"]] <- list(
    date = Sys.time(),
    contributor = Sys.info()["user"],
    R_version = R.version.string,
    categories = if(is.null(category)) names(db) else category
  )
  
  # Save contribution
  jsonlite::write_json(
    contribution,
    output_file,
    pretty = TRUE,
    auto_unbox = TRUE
  )
  
  # Create pull request template
  pr_template <- sprintf('
## Boilerplate Contribution

**Categories affected**: %s
**Number of changes**: [Please fill in]

### Summary of changes
[Please describe your changes]

### Checklist
- [ ] JSON validates against schema
- [ ] No duplicate entries
- [ ] References are complete
- [ ] Template variables are documented
- [ ] Tested in example project

### Testing
```r
# Validated with:
boilerplate::validate_json_database("%s")
```
', 
    if(is.null(category)) "Multiple" else category,
    output_file
  )
  
  writeLines(pr_template, file.path(contrib_path, "PULL_REQUEST_TEMPLATE.md"))
  
  cli_alert_success("Contribution prepared at: {contrib_path}")
  cli_alert_info("Next steps:")
  cli_bullets(c(
    "*" = "Review the generated JSON file",
    "*" = "Fork go-bayes/templates on GitHub",
    "*" = "Add your contribution to the fork",
    "*" = "Submit pull request using the template"
  ))
}

# 4. Compare database versions
# -----------------------------
compare_databases <- function(old_db, new_db, path = "") {
  added <- character()
  removed <- character()
  modified <- character()
  
  # Get all keys from both databases
  old_keys <- names(old_db)
  new_keys <- names(new_db)
  
  # Find additions and removals
  added <- c(added, paste0(path, "/", setdiff(new_keys, old_keys)))
  removed <- c(removed, paste0(path, "/", setdiff(old_keys, new_keys)))
  
  # Check for modifications in common keys
  common_keys <- intersect(old_keys, new_keys)
  
  for (key in common_keys) {
    current_path <- if (path == "") key else paste0(path, "/", key)
    
    if (is.list(old_db[[key]]) && is.list(new_db[[key]])) {
      # Recurse for nested structures
      nested <- compare_databases(old_db[[key]], new_db[[key]], current_path)
      added <- c(added, nested$added)
      removed <- c(removed, nested$removed)
      modified <- c(modified, nested$modified)
    } else {
      # Compare values
      if (!identical(old_db[[key]], new_db[[key]])) {
        modified <- c(modified, current_path)
      }
    }
  }
  
  list(
    added = added[added != ""],
    removed = removed[removed != ""],
    modified = modified[modified != ""]
  )
}

# 5. Example usage in a research project
# --------------------------------------
# Initial setup for new project
db <- setup_boilerplate_for_project(
  project_path = "~/research/study_2024",
  categories = c("methods", "measures")  # Only need these two
)

# Generate methods text
methods_text <- boilerplate_generate_text(
  db = db,
  category = "methods",
  sections = c("sample.default", "missing_data.multiple_imputation"),
  replacements = list(
    n_total = 523,
    location = "Aotearoa New Zealand",
    n_imputations = 40,
    imputation_vars = "all variables in the analysis model plus auxiliary variables"
  )
)

# Later: check for updates
update_from_central(
  project_path = "~/research/study_2024",
  show_changes = TRUE
)

# If you've added new content to contribute back
prepare_contribution(
  project_path = "~/research/study_2024",
  category = "methods"
)

# 6. Validate before manuscript submission
# ----------------------------------------
validate_project_boilerplate <- function(project_path = ".") {
  data_path <- file.path(project_path, PROJECT_DATA)
  
  cli_h2("Validating boilerplate content")
  
  # Check JSON validity
  json_valid <- validate_json_database(
    file.path(data_path, "boilerplate_unified.json"),
    verbose = FALSE
  )
  
  if (!json_valid$valid) {
    cli_alert_danger("JSON validation failed")
    return(FALSE)
  }
  
  # Check for required content
  db <- boilerplate_import(data_path = data_path)
  
  # Example checks
  checks <- list(
    "Has methods section" = !is.null(db$methods),
    "Has measures section" = !is.null(db$measures),
    "Methods have references" = check_references(db$methods),
    "No template variables left" = !check_template_vars(db)
  )
  
  all_passed <- all(unlist(checks))
  
  for (check_name in names(checks)) {
    if (checks[[check_name]]) {
      cli_alert_success(check_name)
    } else {
      cli_alert_danger(check_name)
    }
  }
  
  return(all_passed)
}

# Helper functions
check_references <- function(obj) {
  # Check if all entries have references where expected
  # Returns TRUE if OK
  TRUE  # Simplified for example
}

check_template_vars <- function(obj) {
  # Check for unreplaced template variables
  # Returns TRUE if any found
  FALSE  # Simplified for example
}