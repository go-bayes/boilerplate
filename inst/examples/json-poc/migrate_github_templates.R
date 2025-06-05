# Migration Script for go-bayes/templates Repository
# This script migrates your existing boilerplate_data to JSON format

# Load required packages
library(boilerplate)
library(jsonlite)
library(cli)

# Configuration
GITHUB_REPO_PATH <- "~/github/go-bayes/templates"  # Adjust this path
OUTPUT_PATH <- "~/github/go-bayes/templates/boilerplate_data_json"
CREATE_UNIFIED <- TRUE  # Create a single unified JSON file?
VALIDATE_OUTPUT <- TRUE  # Validate against schemas?

# Step 1: Analyze Current Structure
# ---------------------------------
cli_h1("Analyzing Current Database Structure")

rds_path <- file.path(GITHUB_REPO_PATH, "boilerplate_data")
rds_files <- list.files(rds_path, pattern = "\\.rds$", full.names = TRUE)

cli_alert_info("Found {length(rds_files)} RDS files")

# Examine each file
file_info <- list()
for (file in rds_files) {
  tryCatch({
    db <- readRDS(file)
    
    # Get structure info
    info <- list(
      filename = basename(file),
      size = file.size(file),
      top_level_keys = names(db),
      entry_count = length(db),
      has_wrapper = any(grepl("_db$", names(db)))
    )
    
    # Count nested entries
    count_entries <- function(x) {
      if (is.list(x)) {
        sum(sapply(x, function(item) {
          if (is.list(item) && !any(c("text", "description", "name") %in% names(item))) {
            count_entries(item)
          } else {
            1
          }
        }))
      } else {
        0
      }
    }
    
    info$total_entries <- count_entries(db)
    file_info[[basename(file)]] <- info
    
    cli_alert_success("{basename(file)}: {info$total_entries} entries")
    
  }, error = function(e) {
    cli_alert_danger("Error reading {basename(file)}: {e$message}")
  })
}

# Step 2: Recommended Structure
# -----------------------------
cli_h1("Recommended JSON Structure")

cat("
Based on your current structure, I recommend:

1. **Unified JSON approach** - Single boilerplate_unified.json file
   - Easier to manage and version control
   - Single source of truth
   - Better for cross-category references
   
2. **Improved organization**:
   ```
   boilerplate_data/
   ├── boilerplate_unified.json     # Main database
   ├── schemas/                     # JSON schemas for validation
   │   ├── measures_schema.json
   │   ├── methods_schema.json
   │   └── unified_schema.json
   └── archive/                     # Historical versions
       └── boilerplate_unified_20240601.json
   ```

3. **Version control benefits**:
   - Clear diffs showing exactly what changed
   - Easy to review changes in pull requests
   - Can add comments in JSON (_meta fields)
")

# Step 3: Perform Migration
# -------------------------
if (interactive()) {
  proceed <- readline("Proceed with migration? (y/n): ")
  if (tolower(proceed) != "y") {
    stop("Migration cancelled")
  }
}

cli_h1("Migrating to JSON Format")

# Create output directory
dir.create(OUTPUT_PATH, recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(OUTPUT_PATH, "archive"), recursive = TRUE, showWarnings = FALSE)

# Build unified database
unified_db <- list()

# Process each RDS file
for (file in rds_files) {
  filename <- tools::file_path_sans_ext(basename(file))
  
  tryCatch({
    cli_alert_info("Processing {filename}")
    
    db <- readRDS(file)
    
    # Determine category
    category <- gsub("_db$", "", filename)
    if (category == "selected_elements") {
      # Skip this special file
      next
    }
    
    # Handle wrapper structure
    if (paste0(category, "_db") %in% names(db)) {
      content <- db[[paste0(category, "_db")]]
    } else {
      content <- db
    }
    
    # Clean and standardise
    content <- clean_database_for_json(content)
    
    # Add to unified structure
    unified_db[[category]] <- content
    
    # Also save individual JSON for comparison
    if (!CREATE_UNIFIED) {
      individual_path <- file.path(OUTPUT_PATH, paste0(filename, ".json"))
      write_json(
        content,
        individual_path,
        pretty = TRUE,
        auto_unbox = TRUE
      )
      cli_alert_success("Created {basename(individual_path)}")
    }
    
  }, error = function(e) {
    cli_alert_danger("Failed to process {filename}: {e$message}")
  })
}

# Save unified database
if (CREATE_UNIFIED) {
  unified_path <- file.path(OUTPUT_PATH, "boilerplate_unified.json")
  
  # Add metadata
  unified_db[["_meta"]] <- list(
    version = "1.0.0",
    created = Sys.time(),
    source = "Migrated from RDS files",
    schema_version = "1.0"
  )
  
  write_json(
    unified_db,
    unified_path,
    pretty = TRUE,
    auto_unbox = TRUE
  )
  
  cli_alert_success("Created unified database: {basename(unified_path)}")
  
  # Create timestamped archive
  archive_path <- file.path(
    OUTPUT_PATH, 
    "archive",
    paste0("boilerplate_unified_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".json")
  )
  file.copy(unified_path, archive_path)
}

# Step 4: Validation
# ------------------
if (VALIDATE_OUTPUT) {
  cli_h1("Validating JSON Output")
  
  # Check JSON is valid
  tryCatch({
    test_read <- read_json(unified_path)
    cli_alert_success("JSON syntax is valid")
    
    # Check expected categories
    expected_categories <- c("methods", "results", "discussion", "measures", "appendix", "template")
    present_categories <- intersect(names(test_read), expected_categories)
    missing_categories <- setdiff(expected_categories, present_categories)
    
    cli_alert_info("Categories present: {paste(present_categories, collapse = ', ')}")
    if (length(missing_categories) > 0) {
      cli_alert_warning("Categories missing: {paste(missing_categories, collapse = ', ')}")
    }
    
    # Count entries per category
    for (cat in present_categories) {
      count <- length(test_read[[cat]])
      cli_alert_info("{cat}: {count} top-level entries")
    }
    
  }, error = function(e) {
    cli_alert_danger("JSON validation failed: {e$message}")
  })
}

# Step 5: Create README
# ---------------------
readme_content <- '# Boilerplate Database (JSON Format)

This directory contains the boilerplate database in JSON format, migrated from the original RDS files.

## Structure

- `boilerplate_unified.json` - Main unified database containing all categories
- `archive/` - Historical versions with timestamps
- `schemas/` - JSON schemas for validation (if using validation)

## Categories

- **methods** - Statistical and methodological text templates
- **results** - Results reporting templates  
- **discussion** - Discussion section templates
- **measures** - Variable/measure definitions
- **appendix** - Appendix content templates
- **template** - General templates

## Usage

### In R
```r
library(jsonlite)
db <- read_json("boilerplate_unified.json")

# Access specific content
methods_text <- db$methods$sample$default
```

### In Python
```python
import json

with open("boilerplate_unified.json", "r") as f:
    db = json.load(f)

# Access specific content  
methods_text = db["methods"]["sample"]["default"]
```

## Editing

1. Edit the JSON file directly in any text editor
2. Validate changes against schema (if available)
3. Commit with clear message describing changes

## Version Control

The JSON format provides clear diffs in git, making it easy to track changes:
- What text was modified
- What entries were added/removed
- Who made changes and when

Generated: ' %s% format(Sys.time(), "%Y-%m-%d")

writeLines(readme_content, file.path(OUTPUT_PATH, "README.md"))
cli_alert_success("Created README.md")

# Helper function to clean database for JSON
clean_database_for_json <- function(db) {
  if (is.data.frame(db)) {
    return(as.list(db))
  }
  
  if (is.list(db)) {
    # Clean each element
    db <- lapply(db, clean_database_for_json)
    
    # Ensure valid names
    if (!is.null(names(db))) {
      names(db) <- gsub("[^a-zA-Z0-9_]", "_", names(db))
    }
    
    # Add helpful metadata where appropriate
    if ("description" %in% names(db) || "text" %in% names(db)) {
      if (is.null(db[["_meta"]])) {
        db[["_meta"]] <- list(
          last_modified = Sys.time()
        )
      }
    }
  }
  
  return(db)
}

cli_h1("Migration Complete!")
cli_alert_info("Output directory: {OUTPUT_PATH}")
cli_alert_info("Next steps:")
cli_bullets(c(
  "*" = "Review the generated JSON files",
  "*" = "Test loading in your boilerplate workflow", 
  "*" = "Set up GitHub Actions for validation",
  "*" = "Consider adding JSON schemas for strict validation"
))