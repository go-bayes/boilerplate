## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)

## ----setup--------------------------------------------------------------------
library(boilerplate)

## ----eval=FALSE---------------------------------------------------------------
# # These are equivalent:
# boilerplate_init()
# boilerplate_init(project = "default")
# 
# # Your existing code continues to work unchanged
# db <- boilerplate_import()

## ----eval=FALSE---------------------------------------------------------------
# # Create a project for your lab's shared content
# boilerplate_init(
#   project = "lab_shared",
#   categories = c("methods", "measures"),
#   create_dirs = TRUE,
#   confirm = FALSE
# )
# 
# # Create a project for content from a colleague
# boilerplate_init(
#   project = "smith_measures",
#   categories = "measures",
#   create_dirs = TRUE,
#   confirm = FALSE
# )

## ----eval=FALSE---------------------------------------------------------------
# # Import from a specific project
# lab_db <- boilerplate_import(project = "lab_shared")
# 
# # Save to a specific project
# boilerplate_save(lab_db, project = "lab_shared")
# 
# # Export from a specific project
# boilerplate_export(
#   db = lab_db,
#   project = "lab_shared",
#   format = "json"
# )

## ----eval=FALSE---------------------------------------------------------------
# # Simple list
# projects <- boilerplate_list_projects()
# print(projects)
# 
# # With details
# boilerplate_list_projects(details = TRUE)

## ----eval=FALSE---------------------------------------------------------------
# # Copy specific measures from a colleague's project
# boilerplate_copy_from_project(
#   from_project = "smith_measures",
#   to_project = "default",
#   paths = c("measures.anxiety", "measures.depression"),
#   confirm = FALSE
# )
# 
# # Copy with a prefix to avoid naming conflicts
# boilerplate_copy_from_project(
#   from_project = "smith_measures",
#   to_project = "default",
#   paths = c("measures.anxiety", "measures.depression"),
#   prefix = "smith_",  # Results in smith_anxiety, smith_depression
#   confirm = FALSE
# )

## ----eval=FALSE---------------------------------------------------------------
# # Skip conflicting entries (default)
# boilerplate_copy_from_project(
#   from_project = "lab_shared",
#   to_project = "default",
#   paths = "methods.sampling",
#   merge_strategy = "skip"
# )
# 
# # Overwrite existing entries
# boilerplate_copy_from_project(
#   from_project = "lab_shared",
#   to_project = "default",
#   paths = "methods.sampling",
#   merge_strategy = "overwrite",
#   confirm = TRUE  # Will ask for confirmation
# )
# 
# # Rename conflicting entries
# boilerplate_copy_from_project(
#   from_project = "lab_shared",
#   to_project = "default",
#   paths = "methods.sampling",
#   merge_strategy = "rename"  # Creates sampling_2, sampling_3, etc.
# )

## ----eval=FALSE---------------------------------------------------------------
# # 1. Initialize your main project (if not already done)
# boilerplate_init(
#   project = "my_research",
#   create_dirs = TRUE,
#   confirm = FALSE
# )
# 
# # 2. Create a project for colleague's content
# boilerplate_init(
#   project = "colleague_jane",
#   categories = "measures",
#   create_dirs = TRUE,
#   confirm = FALSE
# )
# 
# # 3. Import and add content to colleague's project
# jane_db <- list(
#   measures = list(
#     work_stress = list(
#       description = "Work stress scale from Jane's lab",
#       items = 15,
#       reference = "Smith2023"
#     ),
#     burnout = list(
#       description = "Burnout inventory",
#       items = 22,
#       reference = "Smith2022"
#     )
#   )
# )
# 
# boilerplate_save(jane_db, project = "colleague_jane")
# 
# # 4. Selectively import what you need
# boilerplate_copy_from_project(
#   from_project = "colleague_jane",
#   to_project = "my_research",
#   paths = "measures.work_stress",  # Only import the work stress scale
#   prefix = "jane_",  # Avoid conflicts
#   confirm = FALSE
# )
# 
# # 5. Verify the import
# my_db <- boilerplate_import(project = "my_research")
# names(my_db$measures)  # Should include "jane_work_stress"

## ----eval=FALSE---------------------------------------------------------------
# # Add source information to imported content
# my_db$measures$jane_work_stress$source <- "Jane Smith's lab, imported 2024-01-15"
# boilerplate_save(my_db, project = "my_research")

## ----eval=FALSE---------------------------------------------------------------
# boilerplate_export(
#   db = my_db,
#   project = "my_research",
#   format = "json",
#   output_file = paste0("backup_my_research_", Sys.Date(), ".json")
# )

