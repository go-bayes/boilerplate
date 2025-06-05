# boilerplate 1.1.0 [2025-06-06]

## Documentation improvements

* Added comprehensive bibliography management vignette showing how to use centralised BibTeX files
* Added complete "Getting Started" tutorial with real-world workflow examples
* Created enhanced introduction vignette with practical multi-study scenarios
* Updated all examples to use current API (removed references to deprecated functions)
* Enhanced vignettes to showcase new variable documentation and database health features

## Major improvements

* **Lighter package**: Reduced dependencies from 9 to 6 by removing glue, janitor, and stringr - replaced with base R equivalents
* **Cleaner codebase**: Removed deprecated backward compatibility functions (`boilerplate_manage_text()` and `boilerplate_manage_measures()`) - saving 625+ lines of code
* **Streamlined JSON support**: Consolidated JSON functionality into existing functions rather than separate `_json` variants
* **Enhanced base functions**: `boilerplate_import()`, `boilerplate_save()`, and `boilerplate_export()` now auto-detect and handle both JSON and RDS formats seamlessly
* **Quarto integration**: Package now emphasises support for Quarto documents with new vignette and updated README
* **Smart backup handling**: Backup creation is now context-aware - automatically disabled in temporary directories and non-interactive sessions
* **Cleaner directory structure**: Removed confusing nested directory structure

## New features

### Enhanced core functions
* `boilerplate_import()` - Now auto-detects JSON or RDS format based on file extensions
* `boilerplate_save()` - Added `format` parameter supporting "json", "rds", or "both"
* `boilerplate_export()` - Added `format` parameter for flexible export options
* `boilerplate_batch_edit()` - Can now load databases directly from file paths (JSON or RDS)
* `boilerplate_standardise_measures()` - Added `json_compatible` parameter for JSON-specific formatting

### JSON utilities
* `boilerplate_migrate_to_json()` - Migrate RDS databases to JSON format
* `boilerplate_rds_to_json()` - Convert individual RDS files to JSON
* `compare_rds_json()` - Compare RDS and JSON databases for migration validation
* `validate_json_database()` - Validate JSON structure against schemas

### Template variable documentation
* `boilerplate_add_entry_enhanced()` - Add entries with documented template variables
* `boilerplate_update_entry_enhanced()` - Update entries while preserving variable documentation
* `boilerplate_get_variables()` - Retrieve variable documentation for a specific path
* `boilerplate_list_variables()` - List all template variables across database with documentation status
* `extract_template_variables()` - Extract variables from template strings

### Database health checking
* `boilerplate_check_health()` - Comprehensive database health checks including:
  - Empty or NULL entries detection
  - Orphaned template variables identification
  - Duplicate content detection
  - Measure structure consistency checks
  - Path naming convention validation
* `boilerplate_health_report()` - Generate detailed health reports for documentation
* `print.boilerplate_health()` - Formatted output for health check results

### Bibliography support
* `boilerplate_add_bibliography()` - Add bibliography information to database
* `boilerplate_update_bibliography()` - Download and cache bibliography files
* `boilerplate_copy_bibliography()` - Copy bibliography to project directory
* `boilerplate_validate_references()` - Check that all citations exist in bibliography
* `boilerplate_generate_text()` - Now supports automatic bibliography copying with `copy_bibliography` parameter

### Measures enhancements
* `boilerplate_generate_measures()` - Now fully replaces deprecated `boilerplate_measures_text()`
* `boilerplate_standardise_measures()` - Standardises measure entries by extracting scale information, identifying reversed items, cleaning descriptions, and ensuring consistent structure
* `boilerplate_measures_report()` - Analyses a measures database and reports on completeness and consistency

## Breaking changes

* Removed `boilerplate_import_json()` - use `boilerplate_import()` instead (auto-detects format)
* Removed `boilerplate_save_json()` - use `boilerplate_save(..., format = "json")` instead
* Removed `boilerplate_batch_edit_json()` - use `boilerplate_batch_edit()` instead (accepts file paths)
* Removed `boilerplate_standardise_measures_json()` - use `boilerplate_standardise_measures(..., json_compatible = TRUE)` instead
* Removed `boilerplate_manage_text()` and `boilerplate_manage_measures()` - deprecated functions no longer needed

## Minor improvements

* Updated package examples with Quarto-focused workflows
* Fixed Rd line width issues in documentation
* Improved example code in export function
* Replaced janitor::make_clean_names with lightweight base R alternative
* Replaced glue::glue with base R template substitution
* Updated all vignettes and tests for consolidated functions
* Fixed trailing whitespace and indentation issues throughout package
* Updated pkgdown configuration to reflect current function set

# boilerplate [2025-05-06] 1.0.44

## New features

* `boilerplate_batch_edit()` allows batch editing of specific fields across multiple entries in a boilerplate database
* `boilerplate_batch_edit_multi()` allows editing multiple fields across multiple entries in a single operation
* `boilerplate_batch_clean()` - allows batch cleaning of text fields by removing or replacing specific characters or patterns across multiple entries in a boilerplate database
* `boilerplate_find_chars()` - helper to search across a boilerplate database

# boilerplate [2025-04-06] 1.0.43

## Bug fixes

* `boilerplate_export()` fixed, works now

# boilerplate [2025-04-06] 1.0.42

## Bug fixes

* `extract_selected_elements()` fixed (was not properly handling the traversal to get all elements)
* `merge_recursive_lists()` improved handling

# boilerplate [2025-04-06] 1.0.41

## Minor improvements

* Added helpers to enable selective save using `boilerplate_save()`

# boilerplate [2025-04-06] 1.0.4

## Minor improvements

* Cleaned up codebase
* Added back missing helper function `find_changes()`

# boilerplate [2025-04-05] 1.0.3

## New features

* `boilerplate_init()` supports initialising empty database structures by default
* `boilerplate_export()` export wholes or parts of databases, for:
  - Full database export (ideal for versioning)
  - Selective export using dot notation (e.g., "methods.statistical.longitudinal")
  - Wildcard selections using "*" (e.g., "methods.*" selects all methods)
  - Category-prefixed paths for unified databases
* Export is distinct from save: use `boilerplate_save()` for normal database updates and `boilerplate_export()` for creating standalone exports

# boilerplate [2025-04-03] 1.0.2

## Minor improvements

* `get_default_measures_db()` creates measures data with the correct structure
* Improved README examples for clarity
* Tidied up R folder to remove old functions

# boilerplate [2025-04-03] 1.0.1

## New features

* Unified database system introduced - manage all content types through a single interface
* New accessors for different content types: `boilerplate_methods()`, `boilerplate_results()`, etc.
* `boilerplate_merge_databases()` for merging databases with conflict resolution
* `boilerplate_merge_category()` for category-specific merging
* `boilerplate_merge_unified()` for merging unified databases

## Breaking changes

* Database structure changed to unified format
* Old separate database functions deprecated in favor of unified approach



## [2024-12-22] boilerplate 0.0.1.6
### Improved
- `boilerplate_report_statistical_estimator()` enhanced for `grf` and allows short and long reporting. 

## [2024-12-22] boilerplate 0.0.1.5

### New
`boilerplate_measures()` - one function that does all we need for measures reporting

## [2024-09-25] boilerplate 0.0.1.4

- more flexible handling of additional sections in methods (still work to be done)

## [2024-08-24] boilerplate 0.0.1.3

### Improved

* fixed issue in `boilerplate_report_measures()` works if only `baseline_vars`, `exposure_var`, or `outcome_vars` are passed. 



## [2024-08-24] boilerplate 0.0.1.2

### Improved

* fixed issue in `boilerplate_manage_measures()`: now, if 'n' is selected for new database name, the manager will return to the main menu instead of charging along. 

## [24-08-2024] boilerplate 0.0.1.1-alpha

### New

* `boilerplate_merge_databases()`: merges databases, currently implemented for measures_data.
* fixed helper functions on the `boilerplate_report_methods()` function.

## [2024-08-24] boilerplate 0.0.1.0-alpha

* alpha release
* doi: 10.5281/zenodo.13370816


## [2024-08-24] boilerplate 0.0.0.92

*  boilerplate_report_additional_sections()
*  boilerplate_report_confounding_control()
*  boilerplate_report_eligibility_criteria()
*  boilerplate_report_identification_assumptions()
*  boilerplate_report_methods()
*  boilerplate_report_missing_data()
*  boilerplate_report_sample()
*  boilerplate_report_statistical_estimator()
*  boilerplate_report_target_population()

## [2024-08-24] boilerplate 0.0.0.91

* `boilerplate_manage_measures()`: simple gui to input measures, saves as .rds files 
* `boilerplate_report_measures()`:  report an appendix of measures with items described.
* `boilerplate_report_causal_interventions()`: report causal contrasts
* `boilerplate_report_variables()`:report variables in methods section (exposure/ outcomes)

## [2024-08-24] boilerplate 0.0.0.9

### New

* first package commit 
