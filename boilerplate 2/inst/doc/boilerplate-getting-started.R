## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## ----install------------------------------------------------------------------
# # Install from CRAN (when available)
# # install.packages("boilerplate")
# 
# # Or install development version
# # devtools::install_github("go-bayes/boilerplate")
# 
# # Load the package
# library(boilerplate)

## ----setup-project------------------------------------------------------------
# # Set up your project directory
# project_dir <- "~/Documents/my_wellbeing_study"
# dir.create(project_dir, showWarnings = FALSE)
# setwd(project_dir)
# 
# # Initialise unified database (new default)
# boilerplate_init(
#   data_path = "data/boilerplate",
#   create_dirs = TRUE,
#   create_empty = FALSE  # Start with example content
# )
# #> ✔ Created directory: data/boilerplate
# #> ✔ Initialising unified database with 6 categories
# #> ✔ Saved unified database to data/boilerplate/boilerplate_unified.json

## ----explore-methods----------------------------------------------------------
# # Import the database
# db <- boilerplate_import(data_path = "data/boilerplate")
# 
# # See what methods are available
# methods_db <- boilerplate_methods(db)
# boilerplate_list_paths(methods_db)
# #> [1] "sample.default"
# #> [2] "sample.online"
# #> [3] "sample.student"
# #> [4] "design.cross_sectional"
# #> [5] "design.longitudinal"
# #> [6] "design.experimental"
# #> [7] "analysis.regression"
# #> [8] "analysis.multilevel"
# #> [9] "missing.listwise"
# #> [10] "missing.multiple_imputation"
# 
# # Look at a specific method
# cat(methods_db$sample$default)
# #> Participants were recruited from {{recruitment_source}}. The final sample
# #> consisted of {{n_total}} participants ({{n_female}} female, {{n_male}} male,
# #> {{n_other}} other/not specified).

## ----explore-measures---------------------------------------------------------
# # See what measures are available
# measures_db <- boilerplate_measures(db)
# names(measures_db)
# #> [1] "anxiety"      "depression"   "life_satisfaction"  "political_orientation"
# 
# # Examine a measure
# measures_db$political_orientation
# #> $name
# #> [1] "political_orientation"
# #>
# #> $description
# #> [1] "Political orientation from 1 (extremely liberal) to 7 (extremely conservative)"
# #>
# #> $type
# #> [1] "continuous"
# #>
# #> $scale
# #> [1] "1-7"

## ----add-custom-methods-------------------------------------------------------
# # Add your sampling method
# db <- boilerplate_add_entry(
#   db,
#   path = "methods.sample.nz_national",
#   value = paste0(
#     "Data were collected as part of the New Zealand Attitudes and Values Study ",
#     "(NZAVS), a longitudinal national probability sample of New Zealand adults. ",
#     "For this study, we analysed data from Wave {{wave}} ({{year}}), which included ",
#     "{{n_total}} participants ({{pct_female}}% female, {{pct_maori}}% Māori, ",
#     "Mage = {{m_age}}, SD = {{sd_age}})."
#   )
# )
# 
# # Add your analysis approach
# db <- boilerplate_add_entry(
#   db,
#   path = "methods.analysis.political_wellbeing",
#   value = paste0(
#     "We examined the relationship between political orientation and well-being ",
#     "using {{analysis_type}}. Political orientation was measured on a 7-point scale ",
#     "from very liberal (1) to very conservative (7). Well-being was assessed using ",
#     "{{wellbeing_measure}}. We controlled for {{covariates}} in all analyses. ",
#     "All analyses were conducted in R version {{r_version}} using the ",
#     "{{packages}} packages."
#   )
# )
# 
# # Save your customizations
# boilerplate_save(db, data_path = "data/boilerplate")

## ----add-custom-measures------------------------------------------------------
# # Add a well-being measure
# db <- boilerplate_add_entry(
#   db,
#   path = "measures.wellbeing_index",
#   value = list(
#     name = "wellbeing_index",
#     description = "Composite well-being index combining life satisfaction, positive affect, and meaning in life",
#     type = "continuous",
#     items = c(
#       "In general, how satisfied are you with your life?",
#       "In general, how often do you experience positive emotions?",
#       "To what extent do you feel your life has meaning and purpose?"
#     ),
#     scale = "0-10",
#     reference = "@diener2009"
#   )
# )
# 
# # Update the database
# boilerplate_save(db, data_path = "data/boilerplate")

## ----setup-bibliography-------------------------------------------------------
# # Configure bibliography source
# db <- boilerplate_add_bibliography(
#   db,
#   url = "https://raw.githubusercontent.com/go-bayes/templates/refs/heads/main/bib/references.bib",
#   local_path = "references.bib"
# )
# 
# # Download and copy bibliography
# boilerplate_copy_bibliography(db, target_dir = ".")
# 
# # Save configuration
# boilerplate_save(db, data_path = "data/boilerplate")

## ----define-parameters--------------------------------------------------------
# # Set all your study-specific values
# study_params <- list(
#   # Sample characteristics
#   wave = 13,
#   year = "2021-2022",
#   n_total = 34782,
#   pct_female = 62.3,
#   pct_maori = 15.7,
#   m_age = 48.2,
#   sd_age = 13.9,
# 
#   # Analysis details
#   analysis_type = "multilevel regression models",
#   wellbeing_measure = "the Well-being Index",
#   covariates = "age, gender, education, and income",
#   r_version = "4.3.2",
#   packages = "lme4 and marginaleffects",
# 
#   # Other parameters
#   recruitment_source = "electoral rolls",
#   n_female = 21680,
#   n_male = 13102,
#   n_other = 0
# )

## ----generate-methods---------------------------------------------------------
# # Generate methods text with your parameters
# methods_text <- boilerplate_generate_text(
#   category = "methods",
#   sections = c(
#     "sample.nz_national",
#     "design.longitudinal",
#     "analysis.political_wellbeing",
#     "missing.multiple_imputation"
#   ),
#   global_vars = study_params,
#   db = db,
#   copy_bibliography = TRUE
# )
# 
# # View the generated text
# cat(methods_text)

## ----generate-measures--------------------------------------------------------
# # Generate description of your measures
# measures_text <- boilerplate_generate_measures(
#   measures = c("political_orientation", "wellbeing_index", "anxiety", "depression"),
#   db = db
# )
# 
# cat(measures_text)

## ----check-structure----------------------------------------------------------
# # Check that all paths exist
# required_paths <- c(
#   "methods.sample.nz_national",
#   "methods.analysis.political_wellbeing",
#   "measures.wellbeing_index"
# )
# 
# for (path in required_paths) {
#   exists <- boilerplate_path_exists(db, path)
#   cat(sprintf("%s: %s\n", path, ifelse(exists, "✓", "✗")))
# }
# 
# # List all available methods paths
# methods_db <- boilerplate_methods(db)
# cat("\nAvailable methods paths:\n")
# print(boilerplate_list_paths(methods_db))
# 
# # List all measures
# measures_db <- boilerplate_measures(db)
# cat("\nAvailable measures:\n")
# print(names(measures_db))

## ----validate-references------------------------------------------------------
# # Ensure all citations are in your bibliography
# validation <- boilerplate_validate_references(db)
# 
# if (!validation$valid) {
#   warning("Missing references found:")
#   print(validation$missing)
# } else {
#   message("All references validated! ✓")
# }

## ----export-version-control---------------------------------------------------
# # Export your complete database for version control
# boilerplate_export(
#   db,
#   paths = c("methods.*", "measures.*"),
#   data_path = "data/boilerplate",
#   output_file = "project_boilerplate.json",
#   format = "json"  # JSON is git-friendly
# )

## ----load-methods, echo=FALSE, results='asis'---------------------------------
# library(boilerplate)
# db <- boilerplate_import("data/boilerplate")
# 
# # Generate and display methods
# methods_text <- boilerplate_generate_text(
#   category = "methods",
#   sections = c(
#     "sample.nz_national",
#     "design.longitudinal",
#     "analysis.political_wellbeing"
#   ),
#   global_vars = study_params,
#   db = db
# )
# 
# cat(methods_text)

## ----load-measures, echo=FALSE, results='asis'--------------------------------
# measures_text <- boilerplate_generate_measures(
#   measures = c("political_orientation", "wellbeing_index"),
#   db = db
# )
# 
# cat(measures_text)

## ----team-collaboration-------------------------------------------------------
# # Export to shared location
# boilerplate_export(
#   db,
#   data_path = "data/boilerplate",
#   output_file = "~/Dropbox/TeamProject/shared_boilerplate.json",
#   format = "json"
# )
# 
# # Collaborator imports
# team_db <- boilerplate_import("~/Dropbox/TeamProject/shared_boilerplate.json")

## ----multiple-papers----------------------------------------------------------
# # Paper 1: Focus on political orientation
# db <- boilerplate_add_entry(
#   db,
#   path = "methods.sample.paper1",
#   value = "We analysed data from {{n_conservatives}} conservative and {{n_liberals}} liberal participants..."
# )
# 
# # Paper 2: Focus on well-being
# db <- boilerplate_add_entry(
#   db,
#   path = "methods.sample.paper2",
#   value = "We examined well-being trajectories among {{n_high_wellbeing}} high and {{n_low_wellbeing}} low well-being participants..."
# )
# 
# # Check all methods entries
# methods_db <- boilerplate_methods(db)
# cat("Available sample methods:\n")
# sample_paths <- grep("^sample\\.", boilerplate_list_paths(methods_db), value = TRUE)
# print(sample_paths)

## ----batch-updates------------------------------------------------------------
# # Update all methods to include ethics statement
# db <- boilerplate_batch_edit(
#   db,
#   field = "ethics",
#   new_value = "This study was approved by the University Ethics Committee (ref: {{ethics_ref}}).",
#   target_entries = "methods.*",
#   category = "methods"
# )

## ----quality-control----------------------------------------------------------
# check_manuscript_ready <- function(db) {
#   cat("Manuscript Checklist:\n")
#   cat("==================\n\n")
# 
#   # Check all sections exist
#   cat("Required Sections:\n")
#   required_sections <- c(
#     "methods.sample", "methods.design",
#     "methods.analysis", "methods.missing"
#   )
# 
#   for (section in required_sections) {
#     exists <- boilerplate_path_exists(db, section)
#     status <- if (exists) "✓" else "✗"
#     cat(sprintf("%s %s\n", status, section))
#   }
# 
#   # Check references
#   cat("\nReferences:\n")
#   validation <- boilerplate_validate_references(db, quiet = TRUE)
#   ref_status <- if (validation$valid) "✓" else "✗"
#   cat(sprintf("%s All references validated\n", ref_status))
# 
#   # Check measures
#   cat("\nMeasures:\n")
#   measures_db <- boilerplate_measures(db)
#   cat(sprintf("✓ %d measures documented\n", length(measures_db)))
# 
#   # Count total entries
#   cat("\nDatabase Summary:\n")
#   methods_count <- length(boilerplate_list_paths(boilerplate_methods(db)))
#   measures_count <- length(boilerplate_measures(db))
#   cat(sprintf("✓ %d methods entries\n", methods_count))
#   cat(sprintf("✓ %d measures entries\n", measures_count))
# 
#   invisible(list(
#     sections_ok = all(sapply(required_sections,
#                              function(s) boilerplate_path_exists(db, s))),
#     references_ok = validation$valid,
#     methods_count = methods_count,
#     measures_count = measures_count
#   ))
# }
# 
# # Run the check
# readiness <- check_manuscript_ready(db)
# #> Manuscript Checklist:
# #> ==================
# #>
# #> Required Sections:
# #> ✓ methods.sample
# #> ✓ methods.design
# #> ✓ methods.analysis
# #> ✓ methods.missing
# #>
# #> References:
# #> ✓ All references validated
# #>
# #> Measures:
# #> ✓ 5 measures documented
# #>
# #> Database Summary:
# #> ✓ 15 methods entries
# #> ✓ 5 measures entries

