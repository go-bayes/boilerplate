## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup--------------------------------------------------------------------
library(boilerplate)

## ----init, eval=FALSE---------------------------------------------------------
# # Initialise unified database with default content
# # Creates a single boilerplate_unified.json file
# boilerplate_init(
#   create_dirs = TRUE,
#   create_empty = FALSE,  # Use FALSE to get example content
#   confirm = FALSE,
#   quiet = FALSE
# )

## ----import, eval=FALSE-------------------------------------------------------
# # Import all databases as a unified structure
# unified_db <- boilerplate_import()
# 
# # Or import specific categories
# methods_db <- boilerplate_import("methods")
# measures_db <- boilerplate_import("measures")

## ----generate, eval=FALSE-----------------------------------------------------
# # Generate methods text
# methods_text <- boilerplate_generate_text(
#   category = "methods",
#   sections = c("sample", "measures", "statistical_estimator"),
#   global_vars = list(
#     n_total = 5000,
#     exposure_var = "political_conservative",
#     outcome_var = "anxiety",
#     population = "New Zealand adults"
#   ),
#   db = unified_db
# )
# 
# cat(methods_text)

## ----measures, eval=FALSE-----------------------------------------------------
# # Generate measure descriptions
# measures_text <- boilerplate_generate_measures(
#   variable_heading = "Outcome Variables",
#   variables = c("anxiety", "depression"),
#   db = unified_db,
#   sample_items = 3  # Show only first 3 items
# )
# 
# cat(measures_text)

## ----view, eval=FALSE---------------------------------------------------------
# # List all paths in a database
# all_paths <- boilerplate_list_paths(unified_db)
# head(all_paths)
# 
# # Get specific content
# sample_text <- boilerplate_get_entry(unified_db, "methods.sample.default")
# cat(sample_text)

## ----update, eval=FALSE-------------------------------------------------------
# # Add a new entry
# unified_db <- boilerplate_add_entry(
#   db = unified_db,
#   path = "methods.sample.online",
#   value = "We recruited {{n_total}} participants through online platforms.",
#   category = "methods"
# )
# 
# # Update existing entry
# unified_db <- boilerplate_update_entry(
#   db = unified_db,
#   path = "methods.sample.default",
#   value = "Our sample consisted of {{n_total}} {{population}}.",
#   category = "methods"
# )
# 
# # Save changes
# boilerplate_save(unified_db)

## ----batch, eval=FALSE--------------------------------------------------------
# # Update multiple references at once
# unified_db <- boilerplate_batch_edit(
#   db = unified_db,
#   field = "reference",
#   new_value = "smith2024",
#   target_entries = c("anxiety", "depression", "stress"),
#   category = "measures"
# )
# 
# # Clean text fields
# unified_db <- boilerplate_batch_clean(
#   db = unified_db,
#   field = "description",
#   remove_chars = c("@", "[", "]"),
#   trim_whitespace = TRUE,
#   category = "measures"
# )

## ----templates, eval=FALSE----------------------------------------------------
# # Create a template
# template_text <- "We analysed data from {{n_total}} {{population}}
#   ({{n_female}} female, {{n_male}} male) with a mean age of {{age_mean}}
#   years (SD = {{age_sd}})."
# 
# # Use in your database
# unified_db <- boilerplate_add_entry(
#   db = unified_db,
#   path = "methods.participants.demographics",
#   value = template_text,
#   category = "methods"
# )
# 
# # Generate with variables
# demographics_text <- boilerplate_generate_text(
#   category = "methods",
#   sections = "participants.demographics",
#   global_vars = list(
#     n_total = 1000,
#     population = "university students",
#     n_female = 600,
#     n_male = 400,
#     age_mean = 21.3,
#     age_sd = 3.2
#   ),
#   db = unified_db
# )

## ----export, eval=FALSE-------------------------------------------------------
# boilerplate_export(
#   db = unified_db,
#   output_file = "boilerplate_backup_2024.rds"
# )

## ----organise, eval=FALSE-----------------------------------------------------
# # Good organisation
# "methods.measures.psychological.anxiety"
# "methods.measures.psychological.depression"
# "methods.measures.demographic.age"

## ----document, eval=FALSE-----------------------------------------------------
# # Add a template reference
# unified_db <- boilerplate_add_entry(
#   db = unified_db,
#   path = "templates.variable_reference",
#   value = "Common variables: {{n_total}}, {{exposure_var}}, {{outcome_var}}",
#   category = "template"
# )

## ----standardise, eval=FALSE--------------------------------------------------
# # Standardise measure entries
# unified_db$measures <- boilerplate_standardise_measures(
#   unified_db$measures,
#   extract_scale = TRUE,
#   clean_descriptions = TRUE
# )
# 
# # Generate quality report
# boilerplate_measures_report(unified_db$measures)

## ----projects, eval=FALSE-----------------------------------------------------
# # Work with multiple projects
# # Create a project for shared content
# boilerplate_init(project = "shared", confirm = FALSE)
# 
# # Copy content between projects
# boilerplate_copy_from_project(
#   from_project = "shared",
#   to_project = "default",
#   paths = c("methods.statistical", "measures.anxiety"),
#   confirm = FALSE
# )
# 
# # List available projects
# projects <- boilerplate_list_projects(details = TRUE)

## ----list-versions, eval=FALSE------------------------------------------------
# # List all database files
# files <- boilerplate_list_files()
# print(files)
# 
# # List files for a specific category
# methods_files <- boilerplate_list_files(category = "methods")
# 
# # Filter by date pattern
# jan_files <- boilerplate_list_files(pattern = "202401")

## ----timestamps, eval=FALSE---------------------------------------------------
# # Save with timestamp
# boilerplate_save(
#   db = unified_db,
#   timestamp = TRUE  # Creates boilerplate_unified_20240115_143022.rds
# )
# 
# # Import a specific timestamped version
# old_version <- boilerplate_import(
#   data_path = "boilerplate/data/boilerplate_unified_20240110_120000.rds"
# )

## ----backup-restore, eval=FALSE-----------------------------------------------
# # View latest backup without restoring
# backup_db <- boilerplate_restore_backup(category = "methods")
# 
# # Restore backup as current version
# boilerplate_restore_backup(
#   category = "methods",
#   restore = TRUE,
#   confirm = TRUE
# )
# 
# # Restore specific backup by timestamp
# boilerplate_restore_backup(
#   category = "methods",
#   backup_version = "20240110_120000",
#   restore = TRUE
# )

