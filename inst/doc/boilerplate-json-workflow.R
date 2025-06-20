## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup--------------------------------------------------------------------
library(boilerplate)

## ----json-basic---------------------------------------------------------------
# Create a temporary directory for examples
temp_dir <- tempdir()
json_path <- file.path(temp_dir, "json_example")
dir.create(json_path, showWarnings = FALSE)

# Create a sample database
sample_db <- list()

# Add methods entries
sample_db <- boilerplate_add_entry(
  sample_db,
  path = "methods.sampling",
  value = "Participants were randomly selected from {{population}}."
)

sample_db <- boilerplate_add_entry(
  sample_db,
  path = "methods.analysis.regression",
  value = "We conducted linear regression using {{software}}."
)

# Add measures
sample_db <- boilerplate_add_entry(
  sample_db,
  path = "measures.age",
  value = list(
    name = "Age",
    description = "Participant age in years",
    type = "continuous",
    range = c(18, 65)
  )
)

# Save as JSON
boilerplate_save(
  sample_db,
  data_path = json_path,
  format = "json",
  confirm = FALSE,
  quiet = TRUE,
  create_dirs = TRUE
)

# Import JSON database (auto-detects format)
imported_db <- boilerplate_import(
  data_path = json_path,
  quiet = TRUE
)

# Check structure
str(imported_db, max.level = 3)

## ----json-categories----------------------------------------------------------
# Save categories with proper structure
methods_db <- list(methods_db = sample_db$methods)
measures_db <- list(measures_db = sample_db$measures)

jsonlite::write_json(
  methods_db,
  file.path(json_path, "methods_db.json"),
  pretty = TRUE,
  auto_unbox = TRUE
)

jsonlite::write_json(
  measures_db,
  file.path(json_path, "measures_db.json"),
  pretty = TRUE,
  auto_unbox = TRUE
)

# Import specific category
methods_only <- boilerplate_import(
  data_path = json_path,
  category = "methods",
  quiet = TRUE
)

names(methods_only)

## ----migration----------------------------------------------------------------
# Create RDS databases for migration example
rds_path <- file.path(temp_dir, "rds_example")
dir.create(rds_path, showWarnings = FALSE)

# Save as RDS first
saveRDS(sample_db$methods, file.path(rds_path, "methods_db.rds"))
saveRDS(sample_db$measures, file.path(rds_path, "measures_db.rds"))

# Migrate to JSON
migration_output <- file.path(temp_dir, "migrated_json")
results <- boilerplate_migrate_to_json(
  source_path = rds_path,
  output_path = migration_output,
  format = "unified",  # Creates a single unified JSON file
  backup = TRUE,       # Creates backup of RDS files
  quiet = FALSE
)

# Check migration results
print(results$migrated)

# Verify the migrated data  
# The migrated file is in the output directory
migrated_file <- file.path(migration_output, "boilerplate_unified.json")
if (file.exists(migrated_file)) {
  migrated_db <- boilerplate_import(
    data_path = migrated_file,
    quiet = TRUE
  )
  names(migrated_db)
} else {
  # Alternative: import from the directory
  migrated_db <- boilerplate_import(
    data_path = migration_output,
    quiet = TRUE
  )
  names(migrated_db)
}

## ----batch-edit---------------------------------------------------------------
# Create a measures database for editing
measures_db <- list(
  anxiety_scale = list(
    name = "Generalized Anxiety Disorder 7-item",
    description = "GAD-7 anxiety measure",
    reference = "Spitzer2006",
    items = list(
      "Feeling nervous or on edge",
      "Not being able to stop worrying"
    )
  ),
  depression_scale = list(
    name = "Patient Health Questionnaire",
    description = "PHQ-9 depression measure",
    reference = "Kroenke2001",
    items = list(
      "Little interest or pleasure",
      "Feeling down or hopeless"
    )
  )
)

# Batch update all references to include @ symbol
updated_db <- boilerplate_batch_edit(
  db = measures_db,  # Can also pass file path directly
  field = "reference",
  new_value = "@reference_2024",  # This will update all references
  target_entries = "*",           # Apply to all entries
  preview = FALSE,                # Don't preview, just update
  confirm = FALSE,                # Don't ask for confirmation
  quiet = TRUE                    # Suppress messages
)

# For more complex edits, use boilerplate_batch_clean
# to add @ prefix to existing references
for (measure in names(measures_db)) {
  if (!is.null(measures_db[[measure]]$reference)) {
    ref <- measures_db[[measure]]$reference
    if (!startsWith(ref, "@")) {
      measures_db[[measure]]$reference <- paste0("@", ref)
    }
  }
}

# Check the updates
measures_db$anxiety_scale$reference
measures_db$depression_scale$reference

## ----standardise--------------------------------------------------------------
# Standardise measures database
standardised <- boilerplate_standardise_measures(
  db = measures_db,
  json_compatible = TRUE,
  quiet = TRUE
)

# Check standardization added missing fields
str(standardised$anxiety_scale)

## ----validate, eval=FALSE-----------------------------------------------------
# # Save a JSON database
# boilerplate_save(
#   measures_db,
#   data_path = temp_dir,
#   category = "measures",
#   format = "json",
#   confirm = FALSE,
#   quiet = TRUE
# )
# json_file <- file.path(temp_dir, "measures_db.json")
# 
# # Validate structure (requires schema files)
# validation_errors <- validate_json_database(
#   json_file,
#   type = "measures"
# )
# 
# if (length(validation_errors) == 0) {
#   message("JSON structure is valid!")
# } else {
#   message("Validation errors found:")
#   print(validation_errors)
# }

## ----validation---------------------------------------------------------------
# Validate the saved JSON file
json_file <- file.path(json_path, "boilerplate_unified.json")
if (file.exists(json_file)) {
  validation_errors <- validate_json_database(json_file, type = "unified")
  
  if (length(validation_errors) == 0) {
    message("JSON database structure is valid!")
  } else {
    warning("Database validation found issues:")
    print(validation_errors)
  }
}

# Check that paths exist
methods_paths <- boilerplate_list_paths(boilerplate_methods(sample_db))
cat("Methods entries:", length(methods_paths), "\n")

measures_names <- names(boilerplate_measures(sample_db))
cat("Measures entries:", length(measures_names), "\n")

## ----integration--------------------------------------------------------------
# Generate text using JSON database
text <- boilerplate_generate_text(
  category = "methods",
  sections = "sampling",
  db = imported_db,
  global_vars = list(
    population = "university students"
  )
)

cat(text)

# Generate text from nested path
analysis_text <- boilerplate_generate_text(
  category = "methods",
  sections = "analysis.regression",
  db = imported_db,
  global_vars = list(
    software = "R version 4.3.0"
  )
)

cat(analysis_text)

# Generate measures text
measures_text <- boilerplate_generate_measures(
  variable_heading = "Demographics",
  variables = "age",
  db = imported_db
)

cat(measures_text)

## ----cleanup, include=FALSE---------------------------------------------------
# Clean up
unlink(c(json_path, rds_path, migration_output), recursive = TRUE)

