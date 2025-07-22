
<!-- readme.md is generated from readme.rmd. please edit that file -->

<img src="man/figures/logo.png" align="right" width="130" alt="boilerplate hex sticker"/>

<!-- badges: start -->

[![R-CMD-check](https://github.com/go-bayes/boilerplate/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/go-bayes/boilerplate/actions/workflows/R-CMD-check.yaml)
[![R-hub](https://github.com/go-bayes/boilerplate/actions/workflows/rhub.yaml/badge.svg)](https://github.com/go-bayes/boilerplate/actions/workflows/rhub.yaml)
[![Lifecycle:
maturing](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://lifecycle.r-lib.org/articles/stages.html#maturing)
[![Project Status:
Active](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![CRAN
status](https://www.r-pkg.org/badges/version/boilerplate)](https://cran.r-project.org/web/packages/boilerplate)

<!-- badges: end -->

## Overview

The `boilerplate` package offers tools for managing and generating
standardised text for methods and results sections of scientific
reports. The package handles template variable substitution and supports
hierarchical organisation of text through dot-separated paths.

## Installation

You can install the development version of boilerplate from GitHub with:

``` r
# install the devtools package if you don't have it already
install.packages("devtools")
devtools::install_github("go-bayes/boilerplate")
```

## Features

### Core Features

- **Single Unified Database**: all content types in one JSON file by
  default (simplified workflow)
- **Multiple Categories**: support for methods, results, discussion,
  measures, appendices and document templates
- **Hierarchical Organisation**: organise content in nested categories
  using dot notation (e.g., `statistical.longitudinal.lmtp`)
- **Default Content**: comes with pre-loaded defaults for common methods
  sections
- **Quarto/R Markdown Integration**: generate sections for scientific
  reports
- **JSON Default Format**: human-readable JSON as default, with RDS
  support for legacy workflows

### Text and Document Features

- **Text Template Management**: create, update, and retrieve reusable
  text templates
- **Variable Substitution**: replace `{{variable}}` placeholders with
  actual values
- **Document Templates**: streamlined creation of journal articles,
  conference presentations, and grant proposals
- **Custom Headings**: flexible heading levels and custom text for
  generated sections

### Measurement Features

- **Measures Database**: special handling for research measures with
  descriptions, items, and metadata
- **Measure Standardisation**: automatically clean and standardise
  measure entries for consistency
- **Quality Reporting**: assess completeness and consistency of your
  measures database
- **Formatted Output**: generate publication-ready measure descriptions
  with multiple format options

### Database Management Features

- **Batch Operations**: efficiently update or clean multiple entries at
  once with pattern matching and wildcards
- **Preview Mode**: see all changes before applying them to prevent
  accidents
- **Export Functions**: create backups and share specific database
  subsets
- **Safety Features**: prevent accidental file overwrites and
  standardised file naming
- **JSON Migration**: easy migration from RDS to JSON format with
  validation tools
- **Bibliography Management**: automatic bibliography file management
  and citation validation

## Safety Features

`boilerplate` includes several safety features to prevent
accidental data loss:

- **Explicit category specification**: the `boilerplate_save()` function
  requires explicit specification of categories when saving individual
  databases
- **Standardised file naming**: consistent naming conventions
  (`boilerplate_unified.rds` for unified databases, `{category}_db.rds`
  for individual categories)
- **Confirmation prompts**: all functions that modify files include
  confirmation prompts (when `confirm=TRUE`) before overwriting existing
  files
- **Automatic timestamping**: optional timestamps can be added to
  filenames (when `timestamp=TRUE`) to prevent overwrites
- **Backup creation**: automatic backup creation before overwriting
  files (when `create_backup=TRUE` in interactive sessions)
- **Directory safety**: functions require explicit permission to create
  new directories (when `create_dirs=TRUE`)

## Basic Usage with Unified Database

``` r
# install from github if not already installed
if (!require(boilerplate, quietly = TRUE)) {
  # install devtools if necessary
  if (!require(devtools, quietly = TRUE)) {
    install.packages("devtools")
  }
  devtools::install_github("go-bayes/boilerplate")
}

# create a directory for this example (in practice, use your project directory)
example_dir <- file.path(tempdir(), "boilerplate_example")
dir.create(example_dir, showWarnings = FALSE)

# initialise unified database with example content
boilerplate_init(
  data_path = example_dir,
  create_dirs = TRUE, 
  create_empty = FALSE,  # FALSE loads default example content
  confirm = FALSE,
  quiet = TRUE
)

# import the unified database
unified_db <- boilerplate_import(data_path = example_dir, quiet = TRUE)

# add a new method entry directly to the unified database
unified_db$methods$sample_selection <- "Participants were selected from {{population}} during {{timeframe}}."

# save all changes at once (JSON by default)
boilerplate_save(unified_db, data_path = example_dir, confirm = FALSE, quiet = TRUE)

# generate text with variable substitution
methods_text <- boilerplate_generate_text(
  category = "methods",
  sections = c("sample.default", "sample_selection"),
  global_vars = list(
    population = "university students",
    timeframe = "2020-2021"
  ),
  db = unified_db,
  add_headings = TRUE
)

cat(methods_text)
```

## Bibliography Management

The boilerplate package can manage bibliography files for your projects,
ensuring consistent citations across all your boilerplate text:

``` r
# make sure you have the unified_db loaded from previous example
# if not, load it:
# unified_db <- boilerplate_import(data_path = example_dir, quiet = TRUE)

# add bibliography information to your database
# using the example bibliography included with the package
example_bib <- system.file("extdata", "example_references.bib", package = "boilerplate")
unified_db <- boilerplate_add_bibliography(
  unified_db,
  url = paste0("file://", example_bib),
  local_path = "references.bib"
)

# save the updated database
boilerplate_save(unified_db, data_path = example_dir, confirm = FALSE, quiet = TRUE)

# generate text and automatically copy bibliography
methods_text <- boilerplate_generate_text(
  category = "methods",
  sections = "statistical.default",  # Use full path to the default text
  db = unified_db,
  copy_bibliography = TRUE,
  bibliography_path = "manuscript/"
)

# Validate all citations exist in bibliography
validation <- boilerplate_validate_references(unified_db)
if (!validation$valid) {
  warning("Missing references: ", paste(validation$missing, collapse = ", "))
}
```

## Working with JSON Format

The boilerplate package supports JSON format for all database
operations. JSON provides several advantages over the traditional RDS
format:

- **Human-readable**: JSON files can be opened and edited in any text
  editor
- **Version control friendly**: Changes are easily tracked in Git
- **Language agnostic**: JSON files can be read by any programming
  language
- **Web-friendly**: JSON is the standard format for web applications

For detailed JSON workflows, see
`vignette("boilerplate-json-workflow")`.

### Basic JSON Operations

``` r
# first ensure you have a database to import
# init if needed:
# boilerplate_init(data_path = "path/to", create_dirs = TRUE)

# first ensure you have a database to import
# Initialise if needed:
boilerplate_init(data_path = "my_project/data", create_dirs = TRUE, confirm = FALSE, quiet = TRUE)

# import database (automatically detects JSON or RDS format)
unified_db <- boilerplate_import(data_path = "my_project/data", quiet = TRUE)

# save as JSON (this is the default format)
boilerplate_save(unified_db, data_path = "my_project/data", format = "json", confirm = FALSE, quiet = TRUE)

# if you have old RDS files from a previous version, you can migrate them:
# results <- boilerplate_migrate_to_json(
#   source_path = "old_project/data",  # Path containing .rds files
#   output_path = "new_project/data",   # Where to save JSON files
#   format = "unified",                 # Create single unified file
#   backup = TRUE                       # Backup RDS files first
# )
```

### JSON with Custom Paths

``` r
# e.g: Using a specific project directory for JSON data
my_json_path <- file.path("my_analysis", "boilerplate_data")

# initialise if needed
# boilerplate_init(data_path = my_json_path, create_dirs = TRUE, confirm = FALSE, quiet = TRUE)

# import database (auto-detects JSON format)
# db <- boilerplate_import(data_path = my_json_path, quiet = TRUE)

# make changes
# db$methods$new_method <- "This is a new method using {{technique}}."

# save back as JSON (default format)
# boilerplate_save(db, data_path = my_json_path, confirm = FALSE, quiet = TRUE)
```

### Validating JSON Structure

``` r
# e.g: validate JSON database structure
# Note: This requires the JSON schema files to be installed
# validation_errors <- validate_json_database(
#   file.path("my_project/data", "boilerplate_unified.json"),
#   type = "unified"
# )
# 
# if (length(validation_errors) == 0) {
#   message("JSON structure is valid!")
# } else {
#   message("Validation errors found:")
#   print(validation_errors)
# }
```

## Working with Custom Data Paths

By default, `boilerplate` stores database files using
`tools::R_user_dir("boilerplate", "data")` for CRAN compliance. However,
there are many situations where you might need to use a different
location:

```r
 # uncomment and set up to your preferences
 #  # load here to manage paths 
 #  dep <- requireNamespace("here", quietly = TRUE)
 #  if (!dep) install.packages("here")
 # library(here)
 #  # create required folder (add others if needed)
 #  dirs <- c(
 #    here::here("my_project_directory"),
 #  )
 # for (d in dirs) {
 #   if (!dir.exists(d)) dir.create(d, recursive = TRUE)
 # }
 # # then use this is as your project directory 
 # my_project_directory = here:here("my_project_directory")
``` 
 
 
- Working with multiple projects that each need their own boilerplate
  databases
- Storing databases in a shared network location
- Organising files according to a specific project structure
- Testing and development scenarios
- I recommend using the `here` of `fs` packages to quicky set directory paths to your liking. 

All key functions in the package (`boilerplate_init()`,
`boilerplate_import()`, `boilerplate_save()`, and
`boilerplate_export()`) accept a `data_path` parameter to specify a
custom location. When working with custom paths, be sure to use the same
path consistently across all functions.

### Example: Full Workflow with Custom Paths

``` r
# define your custom path
my_project_path <- file.path("my_research_project", "data")

# init databases in your custom location
boilerplate_init(
  categories = c("measures", "methods", "results", "discussion", "appendix", "template"),
  data_path = my_project_path,  # Specify custom path here
  create_dirs = TRUE,
  confirm = FALSE,
  quiet = TRUE
)

# import all databases from your custom location
unified_db <- boilerplate_import(
  data_path = my_project_path  # Specify the same custom path
)

# make some changes
unified_db$measures$new_measure <- list(
  name = "new measure scale",
  description = "a newly added measure",
  reference = "author2023",
  waves = "1-2",
  keywords = c("new", "test"),
  items = list("test item 1", "test item 2")
)

# save changes back to your custom location
boilerplate_save(
  db = unified_db,
  data_path = my_project_path,  # Specify the same custom path
  confirm = TRUE
)

# to save just a specific category:
boilerplate_save(
  db = unified_db$measures,
  category = "measures",
  data_path = my_project_path,
  confirm = TRUE
)
```

### Project Management (New in v1.2.0)

The boilerplate package now supports **projects** - isolated namespaces
that keep different boilerplate collections separate. This is ideal for:

- Managing personal vs. shared boilerplate content
- Working with multiple research projects simultaneously  
- Collaborating with colleagues who have their own collections
- Experimenting without affecting your main database

#### Using Projects

All core functions now accept a `project` parameter:

``` r
# create new project for shared lab content
boilerplate_init(
  project = "lab_shared",
  categories = c("methods", "measures"),
  create_dirs = TRUE,
  confirm = FALSE
)

# import from specific project
lab_db <- boilerplate_import(project = "lab_shared")

# add content to your labs project
lab_db$methods$ethics <- "This study was approved by {{institution}} ethics committee (ref: {{ethics_ref}})."

# save to this project
boilerplate_save(lab_db, project = "lab_shared")
```

#### Working with Multiple Projects

``` r
# list all available projects
projects <- boilerplate_list_projects()
print(projects)

# create personal and shared projects
boilerplate_init(project = "my_analysis", create_dirs = TRUE, confirm = FALSE, quiet = TRUE)
boilerplate_init(project = "team_templates", create_dirs = TRUE, confirm = FALSE, quiet = TRUE)

# each project maintains its own isolated namespace
my_db <- boilerplate_import(project = "my_analysis", quiet = TRUE)
team_db <- boilerplate_import(project = "team_templates", quiet = TRUE)
```

#### Cross-Project Operations

Copy content between projects with conflict handling:

``` r
# copy specific content from team templates to your project
boilerplate_copy_from_project(
  from_project = "team_templates",
  to_project = "my_analysis",
  paths = c("methods.statistical", "measures.demographics"),
  merge_strategy = "skip",  # skip, overwrite, or rename
  confirm = FALSE
)

# e.g: copy with a prefix to avoid naming conflicts
# first create the colleague's project
# boilerplate_init(project = "colleague_jane", create_dirs = TRUE, confirm = FALSE, quiet = TRUE)
# Then copy their content:
# boilerplate_copy_from_project(
#   from_project = "colleague_jane",
#   to_project = "my_analysis", 
#   paths = "measures.anxiety",
#   prefix = "jane_",  # results in "jane_anxiety"
#   confirm = FALSE
# )
```

### Relative vs. Absolute Paths

Both relative and absolute paths are supported:

``` r
# e.g.: relative path (relative to working directory)
# boilerplate_import(data_path = "my_project/data", quiet = TRUE)

# e.g.: absolute path
# boilerplate_import(data_path = "/Users/researcher/projects/study_2023/data", quiet = TRUE)
```

For portable code, consider using relative paths or the `file.path()`
function to construct paths.

## Lab Workflow: Central Database with Project Copies

A common workflow in research labs involves maintaining a central
boilerplate database on GitHub that team members copy for
project-specific use:

``` r
# 1. clone central database from GitHub, e.g.
# git clone https://github.com/yourlab/boilerplate-database.git

# 2. copy the database files to your project
# cp -r boilerplate-database/.boilerplate-data my-project/.boilerplate-data

# 3. import and use in your project (auto-detects format)
# db <- boilerplate_import(data_path = ".boilerplate-data")

# 4. make project-specific changes
# db$methods$sample_size <- "We recruited {{n}} participants for {{study_name}}."

# 5. save locally for your project
# boilerplate_save(db, data_path = ".boilerplate-data")

# for JSON format (now the default):
# boilerplate_save(db, data_path = ".boilerplate-data", format = "json")

# 6. if you make changes that should be shared:
# - copy back to the central repository
# - submit a pull request with your improvements
```

## Managing Database Versions

The boilerplate package now supports version management for your
databases. When you save databases with timestamps or when backups are
created, you can easily manage and restore these versions.

### Listing Available Versions

Use `boilerplate_list_files()` to see all available database files:

``` r
# list all database files in your data directory
# first, ensure you have initialised a database:
# boilerplate_init(data_path = "my_project/data", create_dirs = TRUE, confirm = FALSE, quiet = TRUE)

# next list files:
# files <- boilerplate_list_files(data_path = "my_project/data")
# print(files)

# list only methods database files
# files <- boilerplate_list_files(data_path = "my_project/data", category = "methods")

# list files from a specific period
# files <- boilerplate_list_files(data_path = "my_project/data", pattern = "202401")  # January 2024 files
```

The function organises files into: - **Standard files**: Current working
versions (e.g., `methods_db.rds`) - **Timestamped versions**: Saved with
timestamps (e.g., `methods_db_20240115_143022.rds`) - **Backup files**:
Automatic backups (e.g., `methods_db_backup_20240115_140000.rds`)

### Importing Specific Versions

The enhanced `boilerplate_import()` function can now import any database
file directly:

``` r
# import database examples
# Note: These examples show the pattern - replace paths with your actual files

# import the current standard version
# db <- boilerplate_import("methods")

# import a specific timestamped version  
# db <- boilerplate_import(data_path = "path/to/methods_db_20240115_143022.rds")

# import a backup file
# db <- boilerplate_import(data_path = "path/to/methods_db_backup_20240115_140000.rds")
```

### Restoring from Backups

Use `boilerplate_restore_backup()` for convenient backup restoration:

``` r
# backup restoration examples
# note: these require existing backup files in your data directory

# view the latest backup without restoring
# backup_db <- boilerplate_restore_backup("methods")

# restore the latest backup as the current version
# db <- boilerplate_restore_backup(
#   category = "methods",
#   restore = TRUE,
#   confirm = TRUE  # Will ask for confirmation
# )

# restore a specific backup by timestamp
# db <- boilerplate_restore_backup(
#   category = "methods",
#   backup_version = "20240110_120000",
#   restore = TRUE
# )
```

### Version Management Workflow

Here’s a typical workflow for managing versions:

``` r
# 1. check what versions are available
# files <- boilerplate_list_files(data_path = "my_project/data", category = "methods")

# 2. save current work with timestamp
# boilerplate_save(
#   db = unified_db,
#   data_path = "my_project/data",
#   timestamp = TRUE,  # Creates timestamped backup
#   confirm = FALSE,
#   quiet = TRUE
# )

# 3. if you need to revert changes, restore from backup
# boilerplate_restore_backup(
#   data_path = "my_project/data",
#   category = "methods",
#   restore = TRUE,
#   confirm = FALSE
# )

# 4. work with specific versions
# list available backups first:
# backups <- boilerplate_list_files(data_path = "my_project/data", pattern = "backup")
# Then load a specific version if needed
```

### Best Practices

1.  **Regular timestamped saves**: Save important milestones with
    timestamps
2.  **Keep recent backups**: The package automatically creates backups,
    but consider archiving important versions
3.  **Document version changes**: Use meaningful commit messages when
    saving versions
4.  **Clean up old files**: Periodically review and remove unnecessary
    old versions

### Embedding in Analysis Documents

Rather than creating separate `.qmd` files, you can embed boilerplate
directly in your analysis code chunks:

``` r
# at the beginning of your analysis script or Quarto document
library(boilerplate)

# define global variables
study_params <- list(
  n_participants = 250,
  study_name = "Study 1",
  recruitment_method = "online panels",
  analysis_software = "R version 4.3.0"
)

# Example 1: using default location (recommended for persistent storage)
# the default location uses tools::R_user_dir() and includes project structure
# db <- boilerplate_import()  # Uses default project

# Example 2: using a temporary directory (for this example)
temp_analysis <- file.path(tempdir(), "analysis_example")
boilerplate_init(
  data_path = temp_analysis, 
  create_dirs = TRUE, 
  create_empty = FALSE,  # Load default content
  confirm = FALSE, 
  quiet = TRUE
)

# import database
db <- boilerplate_import(data_path = temp_analysis, quiet = TRUE)

# generate methods text when needed
methods_sample <- boilerplate_generate_text(
  category = "methods",
  sections = "sample.default",  # Use full path to the default text
  global_vars = study_params,
  db = db
)

# use the text directly in your document
cat("## Methods\n\n", methods_sample)

# clean up
unlink(temp_analysis, recursive = TRUE)

# example 3: For a real project with existing .boilerplate-data directory:
# If you have an existing directory structure, you may need to specify:
# db <- boilerplate_import(data_path = ".boilerplate-data/projects/default/data")
# or initialise it first:
# boilerplate_init(data_path = ".boilerplate-data", create_dirs = TRUE)
```

## Working with Individual Databases

You can still work with individual databases if preferred:

``` r
# working with individual databases example
# use the here::here() from the `here` package as an alternative
# # load here to manage paths
# dep <- requireNamespace("here", quietly = TRUE)
# if (!dep) install.packages("here")
# library(here)
# create required folder (add others if needed)
# dirs <- c(
#   here::here("temp_dir"),
# )
# for (d in dirs) {
#   if (!dir.exists(d)) dir.create(d, recursive = TRUE)
# }
# temp_dir = here:here("temp_dir")

# for this example
temp_dir <- file.path(tempdir(), "individual_db_example")
boilerplate_init(data_path = temp_dir, create_dirs = TRUE, confirm = FALSE, quiet = TRUE)

# import just the methods database
methods_db <- boilerplate_import("methods", data_path = temp_dir, quiet = TRUE)

# add a new method entry
methods_db$sample_selection <- "Participants were selected from {{population}} during {{timeframe}}."

# save just the methods database
boilerplate_save(methods_db, "methods", data_path = temp_dir, confirm = FALSE, quiet = TRUE)

# generate text with variable substitution
methods_text <- boilerplate_generate_text(
  category = "methods",
  sections = c("sample.default", "sample_selection"),
  global_vars = list(
    population = "university students",
    timeframe = "2020-2021"
  ),
  db = methods_db,
  add_headings = TRUE
)

cat(methods_text)

# clean up
unlink(temp_dir, recursive = TRUE)
```

## Creating Empty Databases

The package supports initialising empty database structures by default,
providing a clean slate for your project without sample content.

``` r
# create empty databases example
temp_empty <- file.path(tempdir(), "empty_db_example")

# init empty databases (default behavior)
boilerplate_init(
  categories = c("methods", "results"),
  data_path = temp_empty,
  create_dirs = TRUE,
  confirm = FALSE,
  quiet = TRUE
)

# check that databases are empty
db_empty <- boilerplate_import(data_path = temp_empty, quiet = TRUE)
print(length(db_empty$methods))  # Should be 0

# clean 
unlink(temp_empty, recursive = TRUE)

# initialise with default content when needed
temp_content <- file.path(tempdir(), "content_db_example")
boilerplate_init(
  categories = c("methods", "results"),
  data_path = temp_content,
  create_dirs = TRUE,
  create_empty = FALSE,  # This loads default content
  confirm = FALSE,
  quiet = TRUE
)

# check that databases have content
db_content <- boilerplate_import(data_path = temp_content, quiet = TRUE)
print(length(db_content$methods))  # Should be > 0

# clean up
unlink(temp_content, recursive = TRUE)
```

Empty databases provide just the top-level structure without example
content, making it easier to start with a clean slate.

## Database Export

The package now supports exporting databases for versioning or sharing
specific elements:

``` r
# export database example
temp_export <- file.path(tempdir(), "export_example")
boilerplate_init(data_path = temp_export, create_dirs = TRUE, confirm = FALSE, quiet = TRUE)

# import database
unified_db <- boilerplate_import(data_path = temp_export, quiet = TRUE)

# export entire database for versioning
boilerplate_export(
  db = unified_db,
  output_file = "boilerplate_v1.0.json",
  data_path = temp_export,
  confirm = FALSE,
  quiet = TRUE
)

# export selected elements (specific methods and results)
boilerplate_export(
  db = unified_db,
  output_file = "causal_methods_subset.json",
  select_elements = c("methods.statistical.*", "results.main_effect"),
  data_path = temp_export,
  confirm = FALSE,
  quiet = TRUE
)

# check exported files exist
list.files(temp_export, pattern = "\\.(json|rds)$")

# clean up
unlink(temp_export, recursive = TRUE)
```

The export function supports: - Full database export (ideal for
versioning) - Selective export using dot notation (e.g.,
“methods.statistical.longitudinal”) - Wildcard selections using “*”
(e.g., ”methods.*” selects all methods) - Category-prefixed paths for
unified databases

Export is distinct from save: use `boilerplate_save()` for normal
database updates and `boilerplate_export()` for creating standalone
exports.

## Managing Measures with the Unified Database

The package provides a simplified way to manage measures and generate
formatted text about them. Measures are stored as top-level entries in
the measures database, with each measure containing standardised
properties like name, description, reference, etc.

``` r
# measures example with temporary directory
temp_measures <- file.path(tempdir(), "measures_example")
boilerplate_init(data_path = temp_measures, create_empty = FALSE, create_dirs = TRUE, confirm = FALSE, quiet = TRUE)

# import the unified database
unified_db <- boilerplate_import(data_path = temp_measures, quiet = TRUE)

# add a measure directly to the unified database
# note: measures should be at the top level of the measures database
unified_db$measures$anxiety_gad7 <- list(
  name = "generalised anxiety disorder scale (GAD-7)",
  description = "anxiety was measured using the GAD-7 scale.",
  reference = "spitzer2006",
  waves = "1-3",
  keywords = c("anxiety", "mental health", "gad"),
  items = list(
    "feeling nervous, anxious, or on edge",
    "not being able to stop or control worrying",
    "worrying too much about different things",
    "trouble relaxing"
  )
)

# save the entire unified database
boilerplate_save(unified_db, data_path = temp_measures, confirm = FALSE, quiet = TRUE)

# alternatively, save just the measures portion
boilerplate_save(unified_db$measures, "measures", data_path = temp_measures, confirm = FALSE, quiet = TRUE)

# then generate text referencing the measure by its top-level name
exposure_text <- boilerplate_generate_measures(
  variable_heading = "Exposure Variable",
  variables = "anxiety_gad7", # match the name you used above
  db = unified_db,  # can pass the unified database
  heading_level = 3,
  subheading_level = 4,
  print_waves = TRUE
)
cat(exposure_text)

# you can also use the helper function to extract just the measures
measures_db <- boilerplate_measures(unified_db)

# generate text for outcome variables using just the measures database
psych_text <- boilerplate_generate_measures(
  variable_heading = "Psychological Outcomes",
  variables = c("anxiety_gad7", "depression_phq9"),
  db = measures_db,  # or use the extracted measures database
  heading_level = 3,
  subheading_level = 4,
  print_waves = TRUE
)
cat(psych_text)

# generate statistical methods text
stats_text <- boilerplate_generate_text(
  category = "methods",
  sections = c("statistical.longitudinal.lmtp"),
  global_vars = list(software = "R version 4.2.0"),
  add_headings = TRUE,
  custom_headings = list("statistical.longitudinal.lmtp" = "LMTP"),
  heading_level = "###",
  db = unified_db  # pass the unified database
)

# initialise a sample text (assuming this was defined earlier)
sample_text <- boilerplate_generate_text(
  category = "methods",
  sections = "sample.default",
  global_vars = list(population = "university students", timeframe = "2023-2024"),
  db = unified_db
)

# combine all sections into a complete methods section
methods_section <- paste(
  "## Methods\n\n",
  sample_text, "\n\n",
  "### Variables\n\n",
  exposure_text, "\n",
  "### Outcome Variables\n\n",
  psych_text, "\n\n",
  stats_text,
  sep = ""
)
cat(methods_section)

# Save the methods section to a file that can be included in a quarto document
# writeLines(methods_section, "methods_section.qmd")

# Clean up
unlink(temp_measures, recursive = TRUE)
```

### Important Notes on Measure Structure

When adding measures to the database:

- Each measure should be a top-level entry in the measures database
- Standard properties include: name, description, reference, waves,
  keywords, and items
- The items property should be a list of item text strings
- When referencing measures in `boilerplate_generate_measures()`, use
  the top-level name

**Incorrect structure (avoid this):**

``` r
# don't organise measures under categories at the top level
unified_db$measures$psychological$anxiety <- list(...)  # WRONG
```

**Correct structure:**

``` r
# add measures directly at the top level
unified_db$measures$anxiety_gad7 <- list(...)  # CORRECT
unified_db$measures$depression_phq9 <- list(...) # CORRECT
```

## Standardising and Reporting on Measures

The package includes powerful tools for standardising measure entries
and reporting on database quality. This is particularly useful when
working with legacy databases or when multiple contributors have added
measures with inconsistent formatting.

### Standardising Measures

The `boilerplate_standardise_measures()` function automatically cleans
and standardises your measures:

``` r
# standardisation example
temp_standard <- file.path(tempdir(), "standardise_example")
boilerplate_init(data_path = temp_standard, create_empty = FALSE, create_dirs = TRUE, confirm = FALSE, quiet = TRUE)

# import your database
unified_db <- boilerplate_import(data_path = temp_standard, quiet = TRUE)

# check quality before standardisation
boilerplate_measures_report(unified_db$measures)

# standardise all measures
unified_db$measures <- boilerplate_standardise_measures(
  unified_db$measures,
  extract_scale = TRUE,      # Extract scale info from descriptions
  identify_reversed = TRUE,   # Identify reversed items
  clean_descriptions = TRUE,  # Clean up description text
  verbose = TRUE             # Show what's being done
)

# save the standardised database
boilerplate_save(unified_db, data_path = temp_standard, confirm = FALSE, quiet = TRUE)

# clean up
unlink(temp_standard, recursive = TRUE)
```

### What Standardisation Does

1.  **Extracts Scale Information**: Identifies and extracts scale
    details from descriptions

    ``` r
    # before:
    description = "Ordinal response: (1 = Strongly Disagree, 7 = Strongly Agree)"

    # after:
    description = NULL  # Removed if only contains scale info
    scale_info = "1 = Strongly Disagree, 7 = Strongly Agree"
    scale_anchors = c("1 = Strongly Disagree", "7 = Strongly Agree")
    ```

2.  **Identifies Reversed Items**: Detects items marked with (r),
    (reversed), etc.

    ``` r
    # items with (r) markers are identified
    items = list(
      "I have frequent mood swings.",
      "I am relaxed most of the time. (r)",
      "I get upset easily."
    )
    # Creates: reversed_items = c(2)
    ```

3.  **Cleans Descriptions**: Removes extra whitespace, fixes punctuation

4.  **Standardises References**: Ensures consistent reference formatting

5.  **Ensures Complete Structure**: All measures have standard fields

### Quality Reporting

Use `boilerplate_measures_report()` to assess your measures database:

``` r
# get a quality overview
boilerplate_measures_report(unified_db$measures)

# output:
# === Measures Database Quality Report ===
# Total measures: 180
# Complete descriptions: 165 (91.7%)
# With references: 172 (95.6%)
# With items: 180 (100.0%)
# With wave info: 178 (98.9%)
# Already standardised: 180 (100.0%)

# get detailed report as data frame
quality_report <- boilerplate_measures_report(
  unified_db$measures, 
  return_report = TRUE
)

# find measures missing information
missing_refs <- quality_report[!quality_report$has_reference, ]
missing_desc <- quality_report[!quality_report$has_description, ]

# view specific measure details
View(quality_report)
```

### Standardising Specific Measures

You can also standardise individual measures or a subset:

``` r
# standardise only specific measures
unified_db$measures <- boilerplate_standardise_measures(
  unified_db$measures,
  measure_names = c("anxiety_gad7", "depression_phq9", "self_esteem")
)

# or standardise a single measure
unified_db$measures$anxiety_gad7 <- boilerplate_standardise_measures(
  unified_db$measures$anxiety_gad7
)
```

### Enhanced Output with Standardised Measures

After standardisation, the `boilerplate_generate_measures()` function
can better format your measures:

``` r
# generate formatted output with enhanced features
measures_text <- boilerplate_generate_measures(
  variable_heading = "Psychological Measures",
  variables = c("self_control", "neuroticism"),
  db = unified_db,
  table_format = TRUE,        # Use table format
  sample_items = 3,           # Show only 3 items per measure
  check_completeness = TRUE,  # Note any missing information
  quiet = TRUE               # Suppress progress messages
)

cat(measures_text)
```

Example output:

    ### Psychological Measures

    #### Self Control

    | Field | Information |
    |-------|-------------|
    | Description | Self-control was measured using two items [@tangney_high_2004]. |
    | Response Scale | 1 = Strongly Disagree, 7 = Strongly Agree |
    | Waves | 5-current |

    **Items:**

    1. In general, I have a lot of self-control
    2. I wish I had more self-discipline (r)

    *(r) denotes reverse-scored item*

    #### Neuroticism

    | Field | Information |
    |-------|-------------|
    | Description | Mini-IPIP6 Neuroticism dimension [@sibley2011]. |
    | Response Scale | 1 = Strongly Disagree, 7 = Strongly Agree |
    | Waves | 1-current |

    **Items:**

    1. I have frequent mood swings.
    2. I am relaxed most of the time. (r)
    3. I get upset easily.

    *(1 additional items not shown)*

    *(r) denotes reverse-scored item*

### Best Practices

1.  Run standardisation after importing legacy databases to ensure
    consistency
2.  Check the quality report to identify measures needing attention
3.  Review standardised output before saving to ensure nothing important
    was lost
4.  Keep the original - use `boilerplate_export()` to create a backup
    before standardising
5.  Document changes - the standardisation adds metadata showing when
    measures were standardised

## Batch Editing and Cleaning Databases

The package includes powerful functions for batch editing and cleaning
your databases. These are particularly useful when you need to update
multiple entries at once or clean up inconsistent formatting.

### Batch Editing Fields

Use `boilerplate_batch_edit()` to update specific fields across multiple
entries:

``` r
# first, ensure you have a database to work with
# example using a temporary directory:
temp_batch <- file.path(tempdir(), "batch_example")
boilerplate_init(
  data_path = temp_batch,
  create_dirs = TRUE,
  create_empty = FALSE,  # FALSE loads example content with actual measures
  confirm = FALSE,
  quiet = TRUE
)

# load your database
unified_db <- boilerplate_import(data_path = temp_batch, quiet = TRUE)

# example 1: update specific references
unified_db <- boilerplate_batch_edit(
  db = unified_db,
  field = "reference",
  new_value = "sibley2021",
  target_entries = c("anxiety", "depression", "life_satisfaction"),
  category = "measures"
)

# example 2: update all references containing "_reference"
unified_db <- boilerplate_batch_edit(
  db = unified_db,
  field = "reference",
  new_value = "sibley2023",
  match_pattern = "_reference",
  category = "measures"
)

# example 3: use wildcards to target groups of entries
unified_db <- boilerplate_batch_edit(
  db = unified_db,
  field = "waves",
  new_value = "1-15",
  target_entries = "alcohol*",  # All entries starting with "alcohol"
  category = "measures"
)

# Example 4: update entries with specific values
unified_db <- boilerplate_batch_edit(
  db = unified_db,
  field = "reference",
  new_value = "sibley2024",
  match_values = c("anxiety_reference", "depression_reference"),
  category = "measures"
)
```

### Preview Before Editing

Always preview changes before applying them:

``` r
# preview what would change
boilerplate_batch_edit(
  db = unified_db,
  field = "reference",
  new_value = "sibley2021",
  target_entries = c("ban_hate_speech", "born_nz"),
  category = "measures",
  preview = TRUE
)

# output shows what would change:
# Preview of changes:
# ℹ ban_hate_speech: "dore2022boundaries" -> "sibley2021"
# ℹ born_nz: "sibley2011" -> "sibley2021"
# ✓ Would update 2 entries
```

### Batch Editing Multiple Fields

Edit multiple fields in one operation:

``` r
# update both reference and waves for specific entries
unified_db <- boilerplate_batch_edit_multi(
  db = unified_db,
  edits = list(
    list(
      field = "reference",
      new_value = "sibley2021",
      target_entries = c("ban_hate_speech", "born_nz")
    ),
    list(
      field = "waves",
      new_value = "1-15",
      target_entries = c("ban_hate_speech", "born_nz")
    )
  ),
  category = "measures"
)
```

### Batch Cleaning Fields

Clean up formatting issues across your database:

``` r
# continue with the unified_db from previous examples
# example 1: remove unwanted characters from references
unified_db <- boilerplate_batch_clean(
  db = unified_db,
  field = "reference",
  remove_chars = c("@", "[", "]"),
  category = "measures"
)

# example 2: clean all entries EXCEPT specific ones
unified_db <- boilerplate_batch_clean(
  db = unified_db,
  field = "reference",
  remove_chars = c("_", "[", "]"),
  exclude_entries = c("anxiety", "depression"),
  category = "measures"
)

# example 3: clean with pattern matching and exclusions
unified_db <- boilerplate_batch_clean(
  db = unified_db,
  field = "description",
  remove_chars = c("(", ")"),
  target_entries = "life_*",        # All entries starting with "life_"
  exclude_entries = "life_events",  # Except this one (if it existed)
  category = "measures"
)

# example 4: multiple cleaning operations
unified_db <- boilerplate_batch_clean(
  db = unified_db,
  field = "description",
  remove_chars = c("(", ")"),
  replace_pairs = list("  " = " "),  # Replace double spaces with single
  trim_whitespace = TRUE,
  collapse_spaces = TRUE,
  category = "measures"
)

# save all changes made through batch operations
boilerplate_save(unified_db, data_path = temp_batch, confirm = FALSE, quiet = TRUE)

# clean up
unlink(temp_batch, recursive = TRUE)
```

### Finding Entries That Need Cleaning

Before cleaning, identify which entries contain specific characters:

``` r
# using the same unified_db from previous examples
# find all entries with problematic characters
entries_to_clean <- boilerplate_find_chars(
  db = unified_db,
  field = "reference",
  chars = c("@", "[", "]"),
  category = "measures"
)

# view the results
print(entries_to_clean)

# find entries but exclude some from results
entries_to_clean <- boilerplate_find_chars(
  db = unified_db,
  field = "reference",
  chars = c("@", "[", "]"),
  exclude_entries = c("forgiveness", "special_*"),
  category = "measures"
)
```

### Workflow Example: Cleaning References

Here’s a complete workflow for cleaning up reference formatting:

``` r
# 1. first, see what needs cleaning
problem_refs <- boilerplate_find_chars(
  db = unified_db,
  field = "reference",
  chars = c("@", "[", "]", " "),
  category = "measures"
)

cat("Found", length(problem_refs), "references that need cleaning\n")

# 2. preview the cleaning operation
boilerplate_batch_clean(
  db = unified_db,
  field = "reference",
  remove_chars = c("@", "[", "]"),
  replace_pairs = list(" " = "_"),  # Replace spaces with underscores
  trim_whitespace = TRUE,
  category = "measures",
  preview = TRUE
)

# 3. apply cleaning
unified_db <- boilerplate_batch_clean(
  db = unified_db,
  field = "reference",
  remove_chars = c("@", "[", "]"),
  replace_pairs = list(" " = "_"),
  trim_whitespace = TRUE,
  category = "measures",
  confirm = TRUE  # Will ask for confirmation
)

# 4. save cleaned database
boilerplate_save(unified_db)
```

### Best Practices for Batch Operations

1.  **always preview first**: Use `preview = TRUE` to see what will
    change

2.  **make backups**: export your database before major changes

    ``` r
    boilerplate_export(unified_db, output_file = "backup_before_cleaning.rds")
    ```


### Common Use Cases

**Standardising References**

``` r
# convert various reference formats to consistent style
unified_db <- boilerplate_batch_clean(
  db = unified_db,
  field = "reference",
  remove_chars = c("@", "[", "]", "(", ")"),
  replace_pairs = list(
    " " = "",           # Remove spaces
    "," = "_",          # Replace commas
    "&" = "and"         # Replace ampersands
  ),
  category = "measures"
)
```

**Updating Wave Information**

``` r
# update all measures from specific wave range
unified_db <- boilerplate_batch_edit(
  db = unified_db,
  field = "waves",
  new_value = "1-16",
  match_values = c("1-15", "1-current"),
  category = "measures"
)
```

**Fixing Description Formatting**

``` r
# clean description formatting issues
unified_db <- boilerplate_batch_clean(
  db = unified_db,
  field = "description",
  replace_pairs = list(
    ".." = ".",         # Fix double periods
    " ." = ".",         # Fix space before period
    "  " = " "          # Fix double spaces
  ),
  trim_whitespace = TRUE,
  category = "measures"
)
```

These batch operations make it easy to maintain consistency across your
entire database, especially when dealing with legacy data or
contributions from multiple sources.

## Appendix Content with the Unified Database

The package supports appendix content that can be managed within the
unified database:

``` r
# import the unified database
unified_db <- boilerplate_import()

# add detailed measures documentation to appendix
unified_db$appendix$detailed_measures <- "# Detailed Measures Documentation\n\n## Overview\n\nThis appendix provides comprehensive documentation for all measures used in this study, including full item text, response options, and psychometric properties.\n\n## {{exposure_var}} Measure\n\n{{exposure_details}}\n\n## Outcome Measures\n\n{{outcome_details}}"

# save the changes to the unified database
boilerplate_save(unified_db)

# generate appendix text with variable substitution
appendix_text <- boilerplate_generate_text(
  category = "appendix",
  sections = c("detailed_measures"),
  global_vars = list(
    exposure_var = "Perfectionism",
    exposure_details = "The perfectionism measure consists of 3 items...",
    outcome_details = "Anxiety was measured using the GAD-7 scale..."
  ),
  db = unified_db  # pass the unified database
)

cat(appendix_text)
```

## Advanced Usage: Audience-Specific Reports with the Unified Database

You can create tailored reports for different audiences from the same
underlying data:

``` r
# import the unified database
unified_db <- boilerplate_import()

# add audience-specific LMTP descriptions
unified_db$methods$statistical_estimator$lmtp$technical_audience <- "We estimate causal effects using the Longitudinal Modified Treatment Policy (LMTP) estimator within a Targeted Minimum Loss-based Estimation (TMLE) framework. This semi-parametric estimator leverages the efficient influence function (EIF) to achieve double robustness and asymptotic efficiency."

unified_db$methods$statistical_estimator$lmtp$applied_audience <- "We estimate causal effects using the LMTP estimator. This approach combines machine learning with causal inference methods to estimate treatment effects while avoiding strict parametric assumptions."

unified_db$methods$statistical_estimator$lmtp$general_audience <- "We used advanced statistical methods that account for multiple factors that might influence both {{exposure_var}} and {{outcome_var}}. This method helps us distinguish between mere association and actual causal effects."

# save the updated unified database
boilerplate_save(unified_db)

# function to generate methods text for different audiences
generate_methods_by_audience <- function(audience = c("technical", "applied", "general"), db) {
  audience <- match.arg(audience)
  
  # select appropriate paths based on audience
  lmtp_path <- paste0("statistical_estimator.lmtp.", audience, "_audience")
  
  # generate text
  boilerplate_generate_text(
    category = "methods",
    sections = c("sample.default", lmtp_path),
    global_vars = list(
      exposure_var = "political_conservative",
      outcome_var = "social_wellbeing"
    ),
    db = db
  )
}

# generate reports for different audiences
technical_report <- generate_methods_by_audience("technical", unified_db)
applied_report <- generate_methods_by_audience("applied", unified_db)
general_report <- generate_methods_by_audience("general", unified_db)

cat("General audience report:\n\n", general_report)
```

## Helper Functions for the Unified Database

The unified database approach includes several helper functions to
extract specific categories:

``` r
# import the unified database
unified_db <- boilerplate_import()

# extract specific categories using helper functions
methods_db <- boilerplate_methods(unified_db)
measures_db <- boilerplate_measures(unified_db)
results_db <- boilerplate_results(unified_db)
discussion_db <- boilerplate_discussion(unified_db)
appendix_db <- boilerplate_appendix(unified_db)
template_db <- boilerplate_template(unified_db)

# extract specific items using dot notation
lmtp_method <- boilerplate_methods(unified_db, "statistical.longitudinal.lmtp")
anxiety_measure <- boilerplate_measures(unified_db, "anxiety_gad7")
main_result <- boilerplate_results(unified_db, "main_effect")

# you can also directly access via the list structure
causal_assumptions <- unified_db$methods$causal_assumptions$identification
```

## Document Templates with the Unified Database

The package supports document templates that can be used to create
complete documents with placeholders for dynamic content:

``` r
# import unified database
unified_db <- boilerplate_import()

# add a custom conference abstract template
unified_db$template$conference_abstract <- "# {{title}}\n\n**Authors**: {{authors}}\n\n## Background\n{{background}}\n\n## Methods\n{{methods}}\n\n## Results\n{{results}}"

# save the updated unified database
boilerplate_save(unified_db)

# generate a document from template with variables
abstract_text <- boilerplate_generate_text(
  category = "template",
  sections = "conference_abstract",
  global_vars = list(
    title = "Effect of Political Orientation on Well-being",
    authors = "Smith, J., Jones, A.",
    background = "Previous research has shown mixed findings...",
    methods = "We used data from a longitudinal study (N=47,000)...",
    results = "We found significant positive effects..."
  ),
  db = unified_db
)

cat(abstract_text)
```

## Complete Workflow Example with the Unified Database

This example demonstrates combining multiple components to create a
complete methods section using the unified database approach:

``` r
# init all databases and import them
boilerplate_init(create_dirs = TRUE, confirm = TRUE)
unified_db <- boilerplate_import()

# add perfectionism measure to the unified database
unified_db$measures$perfectionism <- list(
  name = "perfectionism",
  description = "Perfectionism was measured using a 3-item scale assessing maladaptive perfectionism tendencies.",
  reference = "rice_short_2014",
  waves = "10-current",
  keywords = c("personality", "mental health"),
  items = list(
    "Doing my best never seems to be enough.",
    "My performance rarely measures up to my standards.",
    "I am hardly ever satisfied with my performance."
  )
)

# save the updated unified database
boilerplate_save(unified_db)

# define parameters
study_params <- list(
  exposure_var = "perfectionism",
  population = "New Zealand Residents Enroled in Electoral Roll in 2021",
  timeframe = "2021-2025",
  sampling_method = "convenience"
)

# generate methods text for participant selection
sample_text <- boilerplate_generate_text(
  category = "methods",
  sections = c("sample_selection"),
  global_vars = study_params,
  add_headings = TRUE,
  heading_level = "###",
  db = unified_db
)
cat(sample_text)

# generate measures text for exposure variable
exposure_text <- boilerplate_generate_measures(
  variable_heading = "Exposure Variable",
  variables = "perfectionism",
  heading_level = 3,
  subheading_level = 4,
  print_waves = TRUE, 
  db = unified_db
)

cat(exposure_text)
```

## Citation

To cite the boilerplate package in publications, please use:

Bulbulia, J. (2025). boilerplate: Tools for Managing and Generating
Standardised Text for Scientific Reports. R package version 1.2.0
<https://doi.org/10.5281/zenodo.13370825>

A BibTeX entry for LaTeX users:

    @software{bulbulia_boilerplate_2025,
      author       = {Bulbulia, Joseph},
      title        = {{boilerplate: Tools for Managing and Generating 
                       Standardised Text for Scientific Reports}},
      year         = 2025,
      publisher    = {Zenodo},
      version      = {1.3.0},
      doi          = {10.5281/zenodo.13370825},
      url          = {https://github.com/go-bayes/boilerplate}
    }

## Licence

MIT © Joseph Bulbulia

## See Also

For specific workflows: - JSON support: See
`vignette("boilerplate-json-workflow")` - Quarto integration: See
`vignette("boilerplate-quarto-workflow")` - Getting started: See
`vignette("boilerplate-intro")` d \### Example Files

The package includes example files in the `inst/` directory: - **Quarto
example**:
`system.file("examples", "minimal-quarto-example.qmd", package = "boilerplate")` -
**JSON workflows**: See files in
`system.file("examples/json-examples", package = "boilerplate")` -
**Example data**: CSV and JSON examples in
`system.file("extdata", package = "boilerplate")`

## Development Roadmap

The `boilerplate` package is remains under active development. 

Roadmap:

### Near Term

**Enhanced Documentation and Examples (v1.3.1)** - comprehensive example
testing framework - Enhanced vignette coverage for all workflows -
Improved error messages with helpful suggestions

### Medium Term

**Enhanced Type Safety (v1.4.x)** - implement S3 classes for all
database objects - Custom print methods

### Long Term

**Modern R Infrastructure (v2.0)** - migrate to S7 object system (once
stable) 

###Design Principles

Our development follows these principles: - **Backward compatibility**:
No breaking changes without major version bump - **User-first design**:
Features driven by real research needs - **Type safety**: progressive
enhancement of type checking 

### Current State

- **Version**: 1.3.0 (CRAN submission ready)
- **Code coverage**: 73.12%
- **Dependencies**: Minimal (6 packages)
- **Test suite**: 847 tests across 30 files

We welcome feedback and contributions! Please see our [contribution
guidelines](https://github.com/go-bayes/boilerplate/blob/main/.github/CONTRIBUTING.md)
for more information.
