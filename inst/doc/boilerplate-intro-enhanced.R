## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## ----example-setup------------------------------------------------------------
# library(boilerplate)
# 
# # Sarah's project structure
# # Note: In practice, use here::here() for project paths or specify full paths
# # Example with here package: project_root <- here::here()
# # Example with full path: project_root <- "/Users/sarah/Research/workplace_wellbeing_project"
# project_root <- tempfile("workplace_wellbeing_project")  # For this example
# dir.create(project_root, recursive = TRUE)

## ----project-setup------------------------------------------------------------
# # Initialise boilerplate for the entire project
# boilerplate_init(
#   data_path = file.path(project_root, "shared/boilerplate"),
#   categories = c("methods", "measures", "results", "discussion"),
#   create_dirs = TRUE,
#   create_empty = FALSE  # Start with helpful examples
# )

## ----create-methods-----------------------------------------------------------
# # Load the database
# db <- boilerplate_import(file.path(project_root, "shared/boilerplate"))
# 
# # Create a base recruitment method
# db <- boilerplate_add_entry(
#   db,
#   path = "methods.recruitment.online_panel",
#   value = paste0(
#     "Participants were recruited through {{platform}}, a professional online ",
#     "research panel. Eligible participants were {{eligibility_criteria}}. ",
#     "The survey took approximately {{duration}} minutes to complete, and ",
#     "participants received {{compensation}} as compensation. The final sample ",
#     "consisted of {{n}} participants ({{gender_breakdown}})."
#   )
# )
# 
# # Create variants for different platforms
# db <- boilerplate_add_entry(
#   db,
#   path = "methods.recruitment.mturk",
#   value = paste0(
#     "We recruited {{n}} participants through Amazon Mechanical Turk (MTurk). ",
#     "Participation was limited to workers with a HIT approval rate ≥ {{approval_rate}}% ",
#     "and ≥ {{min_hits}} completed HITs. Workers received ${{payment}} USD for ",
#     "completing the {{duration}}-minute survey. After excluding {{n_excluded}} ",
#     "participants who failed attention checks, the final sample included {{n_final}} ",
#     "participants (Mage = {{m_age}}, SD = {{sd_age}}; {{pct_female}}% female)."
#   )
# )
# 
# # Save the database
# boilerplate_save(db, file.path(project_root, "shared/boilerplate"))

## ----study1-methods-----------------------------------------------------------
# # Study 1 parameters
# study1_params <- list(
#   platform = "Prolific",
#   eligibility_criteria = "currently employed full-time and based in the UK",
#   duration = 15,
#   compensation = "£2.50",
#   n = 150,
#   gender_breakdown = "52% female, 47% male, 1% non-binary"
# )
# 
# # Generate methods for Study 1
# study1_methods <- boilerplate_generate_text(
#   category = "methods",
#   sections = c(
#     "recruitment.online_panel",
#     "design.cross_sectional",
#     "analysis.regression"
#   ),
#   global_vars = study1_params,
#   db = db
# )
# 
# # Save to Study 1 manuscript
# cat(study1_methods, file = file.path(project_root, "study1/methods.txt"))

## ----study2-methods-----------------------------------------------------------
# # Study 2 parameters - MTurk this time
# study2_params <- list(
#   n = 500,
#   approval_rate = 95,
#   min_hits = 100,
#   payment = 4.00,
#   duration = 20,
#   n_excluded = 47,
#   n_final = 453,
#   m_age = 34.7,
#   sd_age = 10.2,
#   pct_female = 58.3
# )
# 
# # Generate methods for Study 2
# study2_methods <- boilerplate_generate_text(
#   category = "methods",
#   sections = c(
#     "recruitment.mturk",
#     "design.cross_sectional",
#     "measures.job_satisfaction",
#     "measures.burnout",
#     "analysis.sem"
#   ),
#   global_vars = study2_params,
#   db = db
# )

## ----measures-library---------------------------------------------------------
# # Add burnout measure used across studies
# db <- boilerplate_add_entry(
#   db,
#   path = "measures.burnout.mbi",
#   value = list(
#     name = "Maslach Burnout Inventory",
#     abbreviation = "MBI",
#     description = paste0(
#       "Burnout was assessed using the {{version}} ({{citation}}). ",
#       "This scale consists of {{n_items}} items measuring three dimensions: ",
#       "emotional exhaustion ({{n_ee}} items, e.g., '{{example_ee}}'), ",
#       "depersonalization ({{n_dp}} items, e.g., '{{example_dp}}'), and ",
#       "personal accomplishment ({{n_pa}} items, e.g., '{{example_pa}}'). ",
#       "Items are rated on a {{scale}} frequency scale. {{scoring_note}}"
#     ),
#     items = list(
#       emotional_exhaustion = c(
#         "I feel emotionally drained from my work",
#         "I feel used up at the end of the workday",
#         "I feel fatigued when I get up in the morning"
#       ),
#       depersonalization = c(
#         "I feel I treat some recipients as if they were impersonal objects",
#         "I've become more callous toward people since I took this job"
#       ),
#       personal_accomplishment = c(
#         "I can easily understand how my recipients feel",
#         "I deal very effectively with the problems of my recipients"
#       )
#     ),
#     psychometrics = list(
#       reliability = "Internal consistency in the current sample was excellent (α = {{alpha}})",
#       validity = "The three-factor structure was confirmed using CFA, χ²({{df}}) = {{chi2}}, CFI = {{cfi}}, RMSEA = {{rmsea}}"
#     )
#   )
# )

## ----generate-measures--------------------------------------------------------
# # Parameters for MBI
# mbi_params <- list(
#   version = "Maslach Burnout Inventory - General Survey",
#   citation = "Maslach et al., 1996",
#   n_items = 16,
#   n_ee = 5,
#   n_dp = 5,
#   n_pa = 6,
#   example_ee = "I feel emotionally drained from my work",
#   example_dp = "I've become more callous toward people",
#   example_pa = "I feel I'm positively influencing people's lives",
#   scale = "7-point",
#   scoring_note = "Higher scores indicate greater burnout for EE and DP; scores are reversed for PA.",
#   alpha = ".91",
#   df = 101,
#   chi2 = "247.3",
#   cfi = ".94",
#   rmsea = ".068"
# )
# 
# # Generate measure description
# mbi_description <- boilerplate_generate_text(
#   category = "measures",
#   sections = "burnout.mbi",
#   global_vars = mbi_params,
#   db = db
# )

## ----team-sharing-------------------------------------------------------------
# # Export to JSON for version control
# boilerplate_export(
#   db,
#   data_path = file.path(project_root, "shared/boilerplate"),
#   output_file = "lab_boilerplate_v2.json",
#   format = "json"
# )
# 
# # Team member imports
# team_db <- boilerplate_import(
#   file.path(project_root, "shared/boilerplate/lab_boilerplate_v2.json")
# )

## ----batch-updates------------------------------------------------------------
# # Add exclusion criteria to all recruitment methods
# db <- boilerplate_batch_edit(
#   db,
#   field = "exclusion_note",
#   new_value = paste0(
#     " Participants were excluded if **before randomisation** they: (a) failed more than {{n_attention}} ",
#     "attention check items, (b) completed the survey in less than {{min_time}} ",
#     "of the median completion time, or (c) provided nonsensical open-ended responses."
#   ),
#   target_entries = "methods.recruitment.*",
#   category = "methods"
# )

## ----dynamic-generation-------------------------------------------------------
# generate_study_methods <- function(study_config, db) {
#   # Extract sections to include based on study type
#   sections <- c(
#     paste0("recruitment.", study_config$recruitment_method),
#     paste0("design.", study_config$design),
#     study_config$measures,
#     paste0("analysis.", study_config$analysis)
#   )
# 
#   # Add standard sections
#   if (study_config$has_missing_data) {
#     sections <- c(sections, "missing.multiple_imputation")
#   }
# 
#   if (study_config$has_power_analysis) {
#     sections <- c(sections, "power.post_hoc")
#   }
# 
#   # Generate text
#   boilerplate_generate_text(
#     category = "methods",
#     sections = sections,
#     global_vars = study_config$parameters,
#     db = db
#   )
# }
# 
# # Use for any study
# study3_config <- list(
#   recruitment_method = "mturk",
#   design = "experimental",
#   measures = c("measures.burnout.mbi", "measures.engagement.uwes"),
#   analysis = "anova",
#   has_missing_data = TRUE,
#   has_power_analysis = TRUE,
#   parameters = list(
#     n = 300,
#     approval_rate = 98,
#     # ... other parameters
#   )
# )
# 
# study3_methods <- generate_study_methods(study3_config, db)

## ----quality-control----------------------------------------------------------
# # Check all papers use current measure descriptions
# papers <- c("study1", "study2", "study3")
# 
# for (paper in papers) {
#   paper_db <- boilerplate_import(
#     file.path(project_root, paper, "boilerplate")
#   )
# 
#   # Compare measure descriptions
#   differences <- compare_entries(
#     paper_db$measures$burnout,
#     db$measures$burnout
#   )
# 
#   if (length(differences) > 0) {
#     message("Update needed for ", paper, ": ", differences)
#   }
# }

## ----setup, include=FALSE-----------------------------------------------------
# library(boilerplate)
# db <- boilerplate_import("shared/boilerplate")
# 
# # Study-specific parameters
# params <- list(
#   n = 300,
#   m_age = 36.2,
#   sd_age = 11.4,
#   pct_female = 54.7,
#   # ... more parameters
# )

## ----methods, echo=FALSE, results='asis'--------------------------------------
# methods <- boilerplate_generate_text(
#   category = "methods",
#   sections = c(
#     "recruitment.mturk",
#     "design.experimental",
#     "measures.burnout.mbi",
#     "measures.engagement.uwes",
#     "analysis.moderation"
#   ),
#   global_vars = params,
#   db = db,
#   copy_bibliography = TRUE  # Ensures references.bib is available
# )
# 
# cat(methods)

## ----results, echo=FALSE, results='asis'--------------------------------------
# results_intro <- boilerplate_generate_text(
#   category = "results",
#   sections = "preliminary.descriptives",
#   global_vars = params,
#   db = db
# )
# 
# cat(results_intro)

## ----organization-------------------------------------------------------------
# # Good: Clear hierarchy
# "methods.recruitment.online.mturk"
# "methods.recruitment.online.prolific"
# "methods.recruitment.in_person.lab"
# "methods.recruitment.in_person.field"
# 
# # Less optimal: Flat structure
# "methods.mturk_recruitment"
# "methods.prolific_recruitment"
# "methods.lab_recruitment"

## ----variable-naming----------------------------------------------------------
# # Good: Self-documenting variables
# "{{n_participants}}"
# "{{mean_age}}"
# "{{pct_female}}"
# "{{cronbach_alpha}}"
# 
# # Less clear
# "{{n}}"
# "{{m1}}"
# "{{p1}}"
# "{{a}}"

## ----version-control----------------------------------------------------------
# # Export with timestamp for versioning
# timestamp <- format(Sys.time(), "%Y%m%d")
# filename <- paste0("boilerplate_backup_", timestamp, ".json")
# 
# boilerplate_export(
#   db,
#   output_file = filename,
#   format = "json"
# )
# 
# # Track in git
# # git add boilerplate_backup_20240115.json
# # git commit -m "Boilerplate snapshot after reviewer revisions"

## ----project-templates--------------------------------------------------------
# # Create a template for your specific journal's requirements
# db <- boilerplate_add_entry(
#   db,
#   path = "templates.journal.plos_one",
#   value = list(
#     word_limit = 3500,
#     abstract_limit = 300,
#     methods_requirements = paste0(
#       "PLOS ONE requires detailed methods including: ",
#       "{{sampling_procedure}}, {{ethics_statement}}, ",
#       "{{data_availability}}, and {{statistical_approach}}."
#     )
#   )
# )

