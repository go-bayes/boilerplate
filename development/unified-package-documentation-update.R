#' Boilerplate: Manage and Generate Text with Hierarchical Templates
#'
#' @description
#' The boilerplate package provides tools for managing and generating templated text for
#' scientific writing. It supports hierarchical organization, template variables,
#' and consistent formatting across documents.
#'
#' @section Unified Database System:
#' The package uses a unified database approach that can store multiple categories
#' of content in a structured format:
#'
#' \describe{
#'   \item{measures}{Information about measures, scales, and variables used in research}
#'   \item{methods}{Methodological descriptions for different analysis approaches}
#'   \item{results}{Standard results reporting text with placeholders for values}
#'   \item{discussion}{Standard discussion elements like limitations and implications}
#'   \item{appendix}{Supplementary information for appendices}
#'   \item{template}{Document templates for different purposes}
#' }
#'
#' @section Basic Workflow:
#' \describe{
#'   \item{1. Initialize}{Use `boilerplate_init()` to create the default databases}
#'   \item{2. Import}{Use `boilerplate_import()` to load the databases}
#'   \item{3. Modify}{Add or update entries in the databases}
#'   \item{4. Generate}{Use `boilerplate_generate_text()` to create text with your data}
#'   \item{5. Save}{Use `boilerplate_save()` to store your changes}
#' }
#'
#' @section Key Functions:
#' \describe{
#'   \item{boilerplate_import()}{Load one or more databases}
#'   \item{boilerplate_save()}{Save a database to disk}
#'   \item{boilerplate_init()}{Initialize databases with default values}
#'   \item{boilerplate_generate_text()}{Generate text by combining sections with variables}
#'   \item{boilerplate_generate_measures()}{Create formatted text about measures}
#' }
#'
#' @section Helper Functions:
#' \describe{
#'   \item{boilerplate_methods()}{Extract methods from a unified database}
#'   \item{boilerplate_measures()}{Extract measures from a unified database}
#'   \item{boilerplate_results()}{Extract results from a unified database}
#'   \item{boilerplate_discussion()}{Extract discussion from a unified database}
#'   \item{boilerplate_appendix()}{Extract appendix from a unified database}
#'   \item{boilerplate_template()}{Extract templates from a unified database}
#' }
#'
#' @section Legacy Functions (Deprecated):
#' \describe{
#'   \item{boilerplate_manage_measures()}{Legacy function for managing measures}
#'   \item{boilerplate_manage_text()}{Legacy function for managing text entries}
#'   \item{boilerplate_init_text()}{Legacy function for initializing text databases}
#'   \item{boilerplate_init_measures()}{Legacy function for initializing measures database}
#'   \item{boilerplate_measures_text()}{Legacy function for generating measures text}
#' }
#'
#' @docType package
#' @name boilerplate-package
NULL

#' Import Boilerplate Databases and Access Utilities
#'
#' @name boilerplate-import
#' @aliases boilerplate_import boilerplate_save
#'
#' @description
#' These functions form the core of the unified database system, allowing you
#' to import one or more databases and save changes back to disk.
#'
#' The unified approach enables you to:
#' \itemize{
#'   \item Load all categories at once for integrated workflows
#'   \item Work with individual categories when needed
#'   \item Use a consistent interface for all database operations
#' }
#'
#' @examples
#' \dontrun{
#' # Import all databases
#' unified_db <- boilerplate_import()
#'
#' # Import specific categories
#' methods_and_results <- boilerplate_import(c("methods", "results"))
#'
#' # Import a single category
#' methods_db <- boilerplate_import("methods")
#'
#' # Make changes
#' methods_db$sample <- "Participants were recruited from universities."
#'
#' # Save changes to a specific category
#' boilerplate_save(methods_db, "methods")
#'
#' # Make changes to multiple categories
#' unified_db$methods$sample <- "Updated sample description."
#' unified_db$results$main_effect <- "The effect was significant, p < .05."
#'
#' # Save all changes at once
#' boilerplate_save(unified_db)
#' }
NULL

#' Helper Functions for Accessing Specific Categories
#'
#' @name boilerplate-helpers
#' @aliases boilerplate_methods boilerplate_measures boilerplate_results
#'          boilerplate_discussion boilerplate_appendix boilerplate_template
#'
#' @description
#' These helper functions make it easier to access specific categories from a
#' unified database. They also allow you to extract nested entries using dot
#' notation.
#'
#' @examples
#' \dontrun{
#' # Import all databases
#' unified_db <- boilerplate_import()
#'
#' # Get the entire methods database
#' methods_db <- boilerplate_methods(unified_db)
#'
#' # Get a specific method using dot notation
#' lmtp_method <- boilerplate_methods(unified_db, "statistical.longitudinal.lmtp")
#'
#' # Get a specific measure
#' anxiety_measure <- boilerplate_measures(unified_db, "anxiety_gad7")
#'
#' # Check what's available in the results database
#' str(boilerplate_results(unified_db))
#' }
NULL

#' Text Generation Functions
#'
#' @name boilerplate-generate
#' @aliases boilerplate_generate_text boilerplate_generate_measures
#'
#' @description
#' These functions generate formatted text from the database entries, allowing
#' you to substitute variables and combine multiple sections.
#'
#' @examples
#' \dontrun{
#' # Import the unified database
#' unified_db <- boilerplate_import()
#'
#' # Generate methods text
#' methods_text <- boilerplate_generate_text(
#'   category = "methods",
#'   sections = c("sample", "statistical.longitudinal.lmtp"),
#'   global_vars = list(
#'     exposure_var = "treatment",
#'     population = "university students"
#'   ),
#'   db = unified_db,
#'   add_headings = TRUE
#' )
#'
#' # Generate measures text
#' measures_text <- boilerplate_generate_measures(
#'   variable_heading = "Outcome Variables",
#'   variables = c("anxiety_gad7", "depression_phq9"),
#'   db = unified_db,
#'   print_waves = TRUE
#' )
#' }
NULL
