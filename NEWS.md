# boilerplate 1.3.0.9002 (development version)

This development release prepares for `1.4.0` and begins the phased removal of
RDS as a storage format. The motivation is security: loading an RDS file can
execute code through object hooks and crafted class attributes (see
CVE-2024-27322 as a representative example), and RDS was the single remaining
code-execution vector in the package. JSON covers every data shape the
package uses, and migration utilities have been in place since `1.2.0`.

## Format defaults
* `boilerplate_export()` now defaults to `format = "json"` (previously `"rds"`).
* The internal helper `write_boilerplate_db()` now defaults to `format = "json"`.
* Default database filenames constructed by `get_db_file_path()` now end in
  `.json` rather than `.rds`.

## Deprecation
* Passing `format = "rds"` or `format = "both"` to `boilerplate_save()`,
  `boilerplate_export()`, or (by delegation) `boilerplate_init()` now emits a
  deprecation warning. Writing RDS still works during the deprecation window.
* Reading RDS via `boilerplate_import()` and the migration utilities
  (`boilerplate_migrate_to_json()`, `boilerplate_rds_to_json()`,
  `compare_rds_json()`) is unchanged, so existing databases continue to load
  and can be converted with a single function call.
* `boilerplate_init()` no longer demonstrates `format = "both"` in its
  examples.

## Tests
* Tests in `test-generate-text.R` and `test-vignette-internals.R` that used
  RDS only as an incidental fixture have been migrated to JSON. Tests that
  exercise the RDS-to-JSON migration path continue to use RDS input on
  purpose.

## Planned for a future release
* Removal of RDS writing entirely, and of `readRDS()` calls from
  `boilerplate_import()`. `boilerplate_migrate_to_json()` will remain as a
  one-way door for legacy `.rds` databases.
* Symlink-safe copy and backup operations.
* Explicit URL-scheme restrictions on remote bibliography downloads.

# boilerplate 1.3.0.9001 (development version)

## Bug fixes
* `make_clean_title()` no longer strips hyphens from measure display names. Previously, `gsub("[_-]", " ", x)` treated hyphens as word separators (like underscores), converting "Honesty-Humility" to "Honesty Humility" and "Right-Wing Authoritarianism" to "Right Wing Authoritarianism". Since R identifiers cannot contain hyphens, any hyphen in a `name` field or `label_mappings` value is intentional typography and is now preserved.
* Fixed missing backup functionality for JSON format in `boilerplate_save()`. Backups are now created for both RDS and JSON formats when `create_backup = TRUE`.

# boilerplate 1.3.0 [2025-06-20]

## Bug fixes
* Fixed CRAN policy violation: package now uses `tools::R_user_dir()` for cache storage instead of `~/.boilerplate/cache`
* Cache files are now stored in the appropriate user directory as per CRAN requirements  
* Added automatic migration from old cache location to new location
* Removed 'here' package dependency - all paths now use `tools::R_user_dir()` for CRAN compliance
* Fixed linting issues: removed unused variables in generate-text.R and import-functions.R
* All default paths now use `tools::R_user_dir("boilerplate", "data")` instead of project directories
* Added `interactive()` checks to all user prompts for non-interactive compatibility
* Fixed README example to use correct section path (`statistical.default` instead of non-existent `analysis`)
* Made `get_default_data_path` an internal function to resolve pkgdown documentation issues

## Documentation
* Added comprehensive tests for all README examples
* Added tests for all vignettes to ensure examples work correctly
* Fixed `.vscode` directory inclusion in package builds

## Testing
* Test suite expanded to 847 tests (was 731)
* Added 8 new test files for previously untested vignettes and README examples
* All vignette examples now have comprehensive test coverage
* Code coverage: 73.12%
* All examples run successfully with --run-donttest
* R CMD check passes with 0 errors, 0 warnings, 1 NOTE (new submission)

# boilerplate 1.2.0 [2025-06-13]

## CRAN resubmission

* Addressed all CRAN reviewer feedback from version 1.1.0
* Fixed all examples to pass R CMD check --run-donttest
* All exported functions have \value tags
* All \dontrun{} replaced with \donttest{}

## Testing and quality

* **Code coverage**: 71.20% overall
* **Test suite**: 726 tests across 22 test files
* All examples now properly initialise databases and clean up temporary files
* Examples are self-contained and run without errors
* Added comprehensive tests for vignette examples

## Project support (NEW)

* **Project-based organization**: Added project support to keep different boilerplate collections separate
  - All core functions (`boilerplate_init()`, `boilerplate_import()`, `boilerplate_save()`, `boilerplate_export()`) now accept a `project` parameter
  - Default project is "default" for backward compatibility
  - Projects are stored in separate subdirectories under `boilerplate/projects/`
* **Cross-project operations**: New functions for managing multiple projects
  - `boilerplate_copy_from_project()` - Selectively copy content between projects with conflict handling
  - `boilerplate_list_projects()` - List all available projects
  - Support for prefixing copied entries to avoid naming conflicts

## Removed functions

* **Merge functions removed**: All merge functions have been removed in favor of project-based workflow
  - `boilerplate_merge_databases()` - Use `boilerplate_copy_from_project()` instead
  - `boilerplate_merge_unified()` - Use `boilerplate_copy_from_project()` instead
  - `boilerplate_merge_category()` - Use `boilerplate_copy_from_project()` instead
  - `boilerplate_update_from_external()` - Use `boilerplate_copy_from_project()` instead
  - The new project-based workflow is cleaner and more flexible

## Documentation improvements

* Added comprehensive bibliography management vignette showing how to use centralised BibTeX files
* Added complete "Getting Started" tutorial with real-world workflow examples
* Created enhanced introduction vignette with practical multi-study scenarios
* Updated all examples to use current API (removed references to deprecated functions)
* Enhanced vignettes to showcase new variable documentation and database health features

## Major improvements

* **Lighter package**: Reduced dependencies from 9 to 6 by removing `glue`, `janitor`, and `stringr` - replaced with base R equivalents
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
* Enhanced `boilerplate_check_health()` - Now includes integrated report generation with `report` parameter

### Version management
* Enhanced `boilerplate_import()` - Can now import database files directly by path (both timestamped and backup files)
* `boilerplate_list_files()` - List and organise all database files (standard, timestamped, backups)
* `boilerplate_restore_backup()` - Convenient function to restore from backup files
* Improved file organisation - Clearly distinguishes between standard files, timestamped versions, and backups
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
