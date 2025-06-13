## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE  # Don't evaluate code in vignette building
)

## ----setup--------------------------------------------------------------------
# library(boilerplate)

## ----init---------------------------------------------------------------------
# # Use a project-specific directory
# data_path <- ".boilerplate-data"
# 
# # Initialise all databases
# boilerplate_init(
#   data_path = data_path,
#   create_dirs = TRUE,
#   quiet = TRUE
# )

## ----methods-templates--------------------------------------------------------
# # Add participant recruitment template
# boilerplate_add_entry(
#   db_path = file.path(".boilerplate-data", "boilerplate_methods.rds"),
#   category = "methods",
#   path = "participants.recruitment",
#   value = list(
#     description = "Participant recruitment procedures",
#     text = "We recruited {{n_participants}} participants through {{recruitment_method}}."
#   ),
#   confirm = FALSE
# )

## ----measures-templates-------------------------------------------------------
# # Add a measure
# boilerplate_add_entry(
#   db_path = file.path(".boilerplate-data", "boilerplate_measures.rds"),
#   category = "measures",
#   path = "anxiety.gad7",
#   value = list(
#     name = "GAD-7",
#     description = "Generalized Anxiety Disorder 7-item scale",
#     items = list(
#       "Feeling nervous, anxious, or on edge",
#       "Not being able to stop or control worrying"
#     ),
#     reference = "Spitzer et al. (2006)"
#   ),
#   confirm = FALSE
# )

## ----quarto-example-----------------------------------------------------------
# # Import database
# db <- boilerplate_import(data_path = ".boilerplate-data", quiet = TRUE)
# 
# # Generate methods text
# methods_text <- boilerplate_generate_text(
#   category = "methods",
#   sections = "participants.recruitment",
#   global_vars = list(
#     n_participants = 250,
#     recruitment_method = "online panels"
#   ),
#   db = db,
#   quiet = TRUE
# )
# 
# # Output: "We recruited 250 participants through online panels."

## ----bibliography-setup-------------------------------------------------------
# # Add bibliography information to your database
# db <- boilerplate_import(".boilerplate-data", quiet = TRUE)
# 
# db <- boilerplate_add_bibliography(
#   db,
#   url = "https://raw.githubusercontent.com/go-bayes/templates/main/bib/references.bib",
#   local_path = "references.bib"
# )
# 
# # Save the updated database
# boilerplate_save(db, data_path = ".boilerplate-data")

## ----bibliography-copy--------------------------------------------------------
# # Generate text and copy bibliography
# methods_text <- boilerplate_generate_text(
#   category = "methods",
#   sections = "analysis.regression",
#   db = db,
#   copy_bibliography = TRUE,
#   bibliography_path = "manuscript/"  # Copy to manuscript directory
# )

## ----validate-citations-------------------------------------------------------
# # Validate references
# validation <- boilerplate_validate_references(db)
# 
# if (!validation$valid) {
#   warning("Missing references: ", paste(validation$missing, collapse = ", "))
# }

## ----batch-ops----------------------------------------------------------------
# # Update all methods entries
# db <- boilerplate_import(".boilerplate-data", quiet = TRUE)
# 
# boilerplate_batch_edit(
#   db = db$methods,
#   field = "text",
#   new_value = function(text) gsub("old text", "new text", text),
#   target_entries = "*",
#   preview = TRUE  # Preview changes first
# )

## ----params-example-----------------------------------------------------------
# methods_text <- boilerplate_generate_text(
#   category = "methods",
#   sections = "participants",
#   global_vars = list(
#     n_participants = params$n_participants,
#     study_name = params$study_name
#   ),
#   db = db
# )

