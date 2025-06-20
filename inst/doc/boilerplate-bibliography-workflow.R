## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## ----setup-bibliography-------------------------------------------------------
# library(boilerplate)
# 
# # Load your database
# db <- boilerplate_import()
# 
# # Add bibliography configuration
# # Using the example bibliography included with the package
# example_bib <- system.file("extdata", "example_references.bib", package = "boilerplate")
# db <- boilerplate_add_bibliography(
#   db,
#   url = paste0("file://", example_bib),
#   local_path = "references.bib",
#   validate = TRUE
# )
# 
# # Save the updated database
# boilerplate_save(db)

## ----download-bibliography----------------------------------------------------
# # Download/update bibliography (cached for 7 days by default)
# bib_file <- boilerplate_update_bibliography(db)
# 
# # Force update if needed
# bib_file <- boilerplate_update_bibliography(db, force = TRUE)
# 
# # Check cache age
# boilerplate_update_bibliography(db, force = FALSE)
# #> ℹ Using cached bibliography from /path/to/cache/references.bib
# #> ⚠ Bibliography cache is 5.2 days old. Consider using force=TRUE to update.

## ----copy-bibliography--------------------------------------------------------
# # Copy to current project
# boilerplate_copy_bibliography(db, target_dir = ".")
# 
# # Copy and update from source first
# boilerplate_copy_bibliography(db, target_dir = ".", update_first = TRUE)
# 
# # The bibliography is now available as ./references.bib

## ----validate-references------------------------------------------------------
# # Validate references across all text categories
# validation <- boilerplate_validate_references(db)
# 
# # Check specific categories only
# validation <- boilerplate_validate_references(
#   db,
#   categories = c("methods", "results")
# )
# 
# # Review validation results
# if (!validation$valid) {
#   cat("Missing references:\n")
#   print(validation$missing)
# }
# 
# # See all available references
# length(validation$available)
# #> [1] 1847  # Example: large bibliography
# 
# # See which references are actually used
# validation$used
# #> [1] "@smith2023"     "@jones2024"     "@doe2022meta"

## ----handle-missing-----------------------------------------------------------
# # Example validation with missing references
# validation <- boilerplate_validate_references(db, quiet = TRUE)
# 
# if (length(validation$missing) > 0) {
#   cat("Please add these references to your bibliography:\n")
#   cat(paste0("- ", validation$missing, "\n"))
# 
#   # Generate BibTeX entries for missing references
#   # (This is a manual process - add to your central .bib file)
#   for (ref in validation$missing) {
#     cat("\n@article{", gsub("@", "", ref), ",\n", sep = "")
#     cat("  title = {},\n")
#     cat("  author = {},\n")
#     cat("  journal = {},\n")
#     cat("  year = {},\n")
#     cat("}\n")
#   }
# }

## ----generate-with-bibliography-----------------------------------------------
# # Generate methods text with automatic bibliography copying
# methods_text <- boilerplate_generate_text(
#   category = "methods",
#   sections = c("sample.default", "analysis.primary"),
#   global_vars = list(n = 1000),
#   db = db,
#   copy_bibliography = TRUE,
#   bibliography_path = "."  # Copy to project root
# )
# 
# # The bibliography is now available for your Quarto/R Markdown document

## ----document-setup-----------------------------------------------------------
# # Your document continues with access to all references
# # All citations in boilerplate text will be properly resolved

## ----subset-bibliography------------------------------------------------------
# # Get citations used in current project
# validation <- boilerplate_validate_references(db)
# used_refs <- validation$used
# 
# # Read full bibliography
# bib_lines <- readLines("references.bib")
# 
# # Extract entries for used citations
# # (This is a simplified example - real implementation would need proper BibTeX parsing)
# project_bib <- extract_bibtex_entries(bib_lines, used_refs)
# 
# # Write project-specific bibliography
# writeLines(project_bib, "project_references.bib")

## ----collaboration-workflow---------------------------------------------------
# # 1. Team lead sets up central bibliography
# team_db <- boilerplate_import()
# team_db <- boilerplate_add_bibliography(
#   team_db,
#   url = "https://github.com/our-lab/shared-refs/raw/main/lab_references.bib",
#   local_path = "lab_references.bib"
# )
# 
# # 2. Each team member updates their local cache
# bib_file <- boilerplate_update_bibliography(team_db, force = TRUE)
# 
# # 3. Validate before submission
# validation <- boilerplate_validate_references(team_db)
# stopifnot(validation$valid)  # Ensure no missing references

## ----ci-check-----------------------------------------------------------------
# # .github/workflows/check-references.yml
# # Run this check on every pull request
# 
# # In R script: check_references.R
# library(boilerplate)
# 
# db <- boilerplate_import()
# validation <- boilerplate_validate_references(db, quiet = TRUE)
# 
# if (!validation$valid) {
#   stop(
#     "Missing references found: ",
#     paste(validation$missing, collapse = ", ")
#   )
# }
# 
# message("All references validated successfully!")

## ----cache-management---------------------------------------------------------
# # Check cache location
# # The cache directory uses R's standard user directory
# cache_dir <- tools::R_user_dir("boilerplate", "cache")
# 
# # This provides a platform-independent location that complies with CRAN policies:
# # - On Unix-like systems (Mac/Linux): ~/.local/share/boilerplate
# # - On Windows: Usually in %LOCALAPPDATA%/boilerplate/boilerplate/cache
# 
# # View cached files
# if (dir.exists(cache_dir)) {
#   list.files(cache_dir, pattern = "\\.bib$")
# }
# 
# # Clear old cache if needed
# if (dir.exists(cache_dir)) {
#   old_files <- list.files(
#     cache_dir,
#     pattern = "\\.bib$",
#     full.names = TRUE
#   )
#   if (length(old_files) > 0) {
#     old_files <- old_files[file.mtime(old_files) < Sys.Date() - 30]
#     if (length(old_files) > 0) file.remove(old_files)
#   }
# }

## ----troubleshoot-download----------------------------------------------------
# # Check URL is accessible
# url <- db$bibliography$url
# con <- url(url)
# open(con)
# # If this fails, check network/firewall settings

## ----troubleshoot-cache-------------------------------------------------------
# # Force fresh download
# bib_file <- boilerplate_update_bibliography(db, force = TRUE)
# 
# # Check cache directory permissions
# cache_dir <- tools::R_user_dir("boilerplate", "cache")
# if (dir.exists(cache_dir)) {
#   file.access(cache_dir, mode = 2)  # 0 = success
# }

## ----troubleshoot-validation--------------------------------------------------
# # Debug validation issues
# validation <- boilerplate_validate_references(db, quiet = FALSE)
# 
# # Check specific text for citations
# text <- db$methods$sample$default
# citations <- grep("@[a-zA-Z0-9_:-]+", text, value = TRUE)
# print(citations)

## ----complete-example---------------------------------------------------------
# # 1. Initial setup (run once)
# library(boilerplate)
# 
# # Initialise new project
# boilerplate_init(create_dirs = TRUE)
# 
# # Import database
# db <- boilerplate_import()
# 
# # Configure bibliography
# # Using the example bibliography included with the package
# example_bib <- system.file("extdata", "example_references.bib", package = "boilerplate")
# db <- boilerplate_add_bibliography(
#   db,
#   url = paste0("file://", example_bib),
#   local_path = "references.bib"
# )
# 
# # Save configuration
# boilerplate_save(db)
# 
# # 2. Daily workflow
# # Update bibliography if needed
# boilerplate_update_bibliography(db)
# 
# # Copy to project
# boilerplate_copy_bibliography(db, ".")
# 
# # 3. Before submission
# # Validate all references
# validation <- boilerplate_validate_references(db)
# 
# if (validation$valid) {
#   message("Ready for submission!")
# } else {
#   warning("Missing references: ", paste(validation$missing, collapse = ", "))
# }
# 
# # 4. Generate final document
# final_text <- boilerplate_generate_text(
#   category = "methods",
#   sections = c("all"),
#   db = db,
#   copy_bibliography = TRUE
# )

