---
output: github_document
---

<!-- readme.md is generated from readme.rmd. please edit that file -->



<img src="man/figures/logo.png" align="right" width="120" alt="boilerplate hex sticker"/>

<!-- badges: start -->
[![R-CMD-check](https://github.com/go-bayes/boilerplate/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/go-bayes/boilerplate/actions/workflows/R-CMD-check.yaml)
[![R-hub](https://github.com/go-bayes/boilerplate/actions/workflows/rhub.yaml/badge.svg)](https://github.com/go-bayes/boilerplate/actions/workflows/rhub.yaml)
[![Lifecycle:
maturing](https://img.shields.io/badge/lifecycle-maturing-blue.svg)](https://lifecycle.r-lib.org/articles/stages.html#maturing)
[![Project Status:
Active](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
<!-- badges: end -->

## Overview

The `boilerplate` package provides tools for managing and generating standardised text for methods and results sections of scientific reports. It handles template variable substitution and supports hierarchical organisation of text through dot-separated paths. 

## Installation

You can install the development version of boilerplate from GitHub with:


``` r
# install the devtools package if you don't have it already
install.packages("devtools")
devtools::install_github("go-bayes/boilerplate")
```

## Features

### Core Features
- **Single Unified Database**: All content types in one JSON file by default (simplified workflow)
- **Multiple Categories**: Support for methods, results, discussion, measures, appendices and document templates
- **Hierarchical Organisation**: Organise content in nested categories using dot notation (e.g., `statistical.longitudinal.lmtp`)
- **Default Content**: Comes with pre-loaded defaults for common methods sections
- **Quarto/R Markdown Integration**: Generate sections for scientific reports
- **JSON Default Format**: Human-readable JSON as default, with RDS support for legacy workflows

### Text and Document Features
- **Text Template Management**: Create, update, and retrieve reusable text templates
- **Variable Substitution**: Replace `{{variable}}` placeholders with actual values
- **Document Templates**: Streamlined creation of journal articles, conference presentations, and grant proposals
- **Custom Headings**: Flexible heading levels and custom text for generated sections

### Measurement Features
- **Measures Database**: Special handling for research measures with descriptions, items, and metadata
- **Measure Standardisation**: Automatically clean and standardise measure entries for consistency
- **Quality Reporting**: Assess completeness and consistency of your measures database
- **Formatted Output**: Generate publication-ready measure descriptions with multiple format options

### Database Management Features
- **Batch Operations**: Efficiently update or clean multiple entries at once with pattern matching and wildcards
- **Preview Mode**: See all changes before applying them to prevent accidents
- **Export Functions**: Create backups and share specific database subsets
- **Safety Features**: Prevention of accidental file overwrites and standardised file naming
- **JSON Migration**: Easy migration from RDS to JSON format with validation tools
- **Bibliography Management**: Automatic bibliography file management and citation validation

## Safety Features

The boilerplate package includes several safety features to prevent accidental data loss:

- **Explicit category specification**: The `boilerplate_save()` function requires explicit specification of categories when saving individual databases
- **Standardised file naming**: Consistent naming conventions (`boilerplate_unified.rds` for unified databases, `{category}_db.rds` for individual categories)
- **Confirmation prompts**: All functions that modify files include confirmation prompts (when `confirm=TRUE`) before overwriting existing files
- **Automatic timestamping**: Optional timestamps can be added to filenames (when `timestamp=TRUE`) to prevent overwrites
- **Backup creation**: Automatic backup creation before overwriting files (when `create_backup=TRUE` in interactive sessions)
- **Directory safety**: Functions require explicit permission to create new directories (when `create_dirs=TRUE`)

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

# initialise unified database (default: single JSON file)
boilerplate_init(create_dirs = TRUE, confirm = TRUE)

# import the unified database
unified_db <- boilerplate_import()

# add a new method entry directly to the unified database
unified_db$methods$sample_selection <- "Participants were selected from {{population}} during {{timeframe}}."

# save all changes at once (JSON by default)
boilerplate_save(unified_db)

# generate text with variable substitution
methods_text <- boilerplate_generate_text(
  category = "methods",
  sections = c("sample", "sample_selection"),
  global_vars = list(
    population = "university students",
    timeframe = "2020-2021"
  ),
  db = unified_db,  # pass the unified database
  add_headings = TRUE
)

cat(methods_text)
```

## Bibliography Management

The boilerplate package can manage bibliography files for your projects, ensuring consistent citations across all your boilerplate text:


``` r
# Add bibliography information to your database
unified_db <- boilerplate_add_bibliography(
  unified_db,
  url = "https://raw.githubusercontent.com/go-bayes/templates/main/bib/references.bib",
  local_path = "references.bib"
)

# Generate text and automatically copy bibliography
methods_text <- boilerplate_generate_text(
  category = "methods",
  sections = "analysis",
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

The boilerplate package supports JSON format for all database operations. JSON provides several advantages over the traditional RDS format:

- **Human-readable**: JSON files can be opened and edited in any text editor
- **Version control friendly**: Changes are easily tracked in Git
- **Language agnostic**: JSON files can be read by any programming language
- **Web-friendly**: JSON is the standard format for web applications

For detailed JSON workflows, see `vignette("boilerplate-json-workflow")`.

### Basic JSON Operations


``` r
# import database (automatically detects JSON or RDS format)
unified_db <- boilerplate_import(data_path = "path/to")

# save as JSON
boilerplate_save(unified_db, format = "json")

# migrate existing RDS databases to JSON
results <- boilerplate_migrate_to_json(
  source_path = "boilerplate/data",  # Path to RDS files
  output_path = "json_data",          # Where to save JSON files
  format = "unified",                 # Create single unified file
  backup = TRUE                       # Backup RDS files first
)
```

### JSON with Custom Paths


``` r
# set path for JSON data
my_json_path <- "path/to/json/data"

# import database (auto-detects JSON format)
db <- boilerplate_import(data_path = my_json_path)

# make changes
db$methods$new_method <- "This is a new method using {{technique}}."

# save back as JSON
boilerplate_save(db, data_path = my_json_path, format = "json")
```

### Validating JSON Structure


``` r
# Validate JSON database structure
validation_errors <- validate_json_database(
  "path/to/boilerplate_unified.json",
  type = "unified"
)

if (length(validation_errors) == 0) {
  message("JSON structure is valid!")
} else {
  message("Validation errors found:")
  print(validation_errors)
}
```

## Working with Custom Data Paths

By default, boilerplate stores database files in the "boilerplate/data" subdirectory of your working directory (using `here::here()`). However, there are many situations where you might need to use a different location:

- Working with multiple projects that each need their own boilerplate databases
- Storing databases in a shared network location
- Organising files according to a specific project structure
- Testing and development scenarios

All key functions in the package (`boilerplate_init()`, `boilerplate_import()`, `boilerplate_save()`, and `boilerplate_export()`) accept a `data_path` parameter to specify a custom location. When working with custom paths, be sure to use the same path consistently across all functions.

### Example: Full Workflow with Custom Paths


``` r
# define your custom path
my_project_path <- "path/to/your/project/data"

# Initialise databases in your custom location
boilerplate_init(
  categories = c("measures", "methods", "results", "discussion", "appendix", "template"),
  data_path = my_project_path,  # Specify custom path here
  create_dirs = TRUE,
  confirm = FALSE
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
# Create a new project for shared lab content
boilerplate_init(
  project = "lab_shared",
  categories = c("methods", "measures"),
  create_dirs = TRUE,
  confirm = FALSE
)

# Import from a specific project
lab_db <- boilerplate_import(project = "lab_shared")

# Add content to the lab project
lab_db$methods$ethics <- "This study was approved by {{institution}} ethics committee (ref: {{ethics_ref}})."

# Save to the specific project
boilerplate_save(lab_db, project = "lab_shared")
```

#### Working with Multiple Projects

``` r
# List all available projects
projects <- boilerplate_list_projects()
print(projects)

# Create personal and shared projects
boilerplate_init(project = "my_analysis", create_dirs = TRUE, confirm = FALSE)
boilerplate_init(project = "team_templates", create_dirs = TRUE, confirm = FALSE)

# Each project maintains its own isolated namespace
my_db <- boilerplate_import(project = "my_analysis")
team_db <- boilerplate_import(project = "team_templates")
```

#### Cross-Project Operations

Copy content between projects with conflict handling:

``` r
# Copy specific content from team templates to your project
boilerplate_copy_from_project(
  from_project = "team_templates",
  to_project = "my_analysis",
  paths = c("methods.statistical", "measures.demographics"),
  merge_strategy = "skip",  # skip, overwrite, or rename
  confirm = FALSE
)

# Copy with a prefix to avoid naming conflicts
boilerplate_copy_from_project(
  from_project = "colleague_jane",
  to_project = "my_analysis", 
  paths = "measures.anxiety",
  prefix = "jane_",  # results in "jane_anxiety"
  confirm = FALSE
)

## Licence

MIT © Joseph Bulbulia

## See Also

For specific workflows:
- JSON support: See `vignette("boilerplate-json-workflow")`
- Quarto integration: See `vignette("boilerplate-quarto-workflow")`
- Getting started: See `vignette("boilerplate-intro")`

### Example Files

The package includes example files in the `inst/` directory: - **Quarto
example**:
`system.file("examples", "minimal-quarto-example.qmd", package = "boilerplate")` -
**JSON workflows**: See files in
`system.file("examples/json-examples", package = "boilerplate")` -
**Example data**: CSV and JSON examples in
`system.file("extdata", package = "boilerplate")`

## Development Roadmap

The `boilerplate` package is under active development. Here’s our
planned roadmap for upcoming features:

### 🚀 Near Term

**Enhanced Type Safety (v1.2.1)** - Implementation of S3 classes for all
database objects - Improved validation and error messages - Better IDE
support with autocompletion - Zero breaking changes - full backward
compatibility

### 📋 Medium Term

**Extended S3 Methods (v1.3.x)** - Custom print methods for cleaner
output - Validation methods for database integrity - Safe subsetting and
extraction operators - Enhanced merge capabilities with type checking

### 🔮 Long Term

**Modern R Infrastructure (v2.0)** - Migration to S7 object system (once
stable) - Performance optimizations - Extended validation framework -
Advanced project management features

### 🎯 Design Principles

Our development follows these principles: - **Backward compatibility**:
No breaking changes without major version bump - **User-first design**:
Features driven by real research needs - **Type safety**: Progressive
enhancement of type checking - **Modern R practices**: Adoption of new
standards as they mature

### 📊 Current State

- **Version**: 1.2.0 (CRAN submission pending)
- **Code coverage**: 63.54%
- **Dependencies**: Minimal (6 packages)
- **Test suite**: 130 tests across 16 files

We welcome feedback and contributions! Please see our [contribution
guidelines](https://github.com/go-bayes/boilerplate/blob/main/.github/CONTRIBUTING.md)
for more information.
