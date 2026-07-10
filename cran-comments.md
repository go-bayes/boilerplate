# boilerplate 1.4.0

## Summary of changes in 1.4.0

`1.4.0` is a minor-version release with one user-visible storage-policy change,
motivated by security.

* The default database format for `boilerplate_save()`, `boilerplate_export()`,
  and `boilerplate_init()` is now JSON. RDS writing is no longer supported by
  package APIs.
* Existing RDS databases continue to load for backward compatibility and can
  be converted with `boilerplate_migrate_to_json()`. RDS reads now emit an R
  warning before deserialisation, and JSON files are preferred when both JSON
  and RDS databases exist. If the ignored RDS file is newer than the JSON file,
  import emits a warning so users can migrate the newer legacy file.

Rationale: `readRDS()` deserialisation can execute code through object hooks
and crafted class attributes. JSON stores every data shape the package uses
without that deserialisation step, and the migration path has existed since
`1.2.0`. This release stops package APIs from writing RDS, alerts users before
legacy RDS reads, and keeps a backward-compatible migration path for trusted
local RDS files.

## CRAN-policy touch-points

* File-system behaviour is unchanged. Default data paths continue to use
  `tools::R_user_dir("boilerplate", "data")`. No new directories are written
  outside `tempdir()` or an explicit user-supplied path.
* No new `Imports`. Legacy RDS-read warnings use base `warning()` and
  rejected RDS-write requests use base `stop()`, avoiding a `lifecycle`
  dependency.
* No network, shell, or `eval()` calls are added. The single existing
  network site (bibliography download in `boilerplate_update_bibliography()`)
  is unchanged in this release.
* Reverse-dependency check: none, there are currently no downstream
  dependencies.

## Test environments

* local macOS install (aarch64-apple-darwin23), R 4.6.0
* win-builder devel: pending
* win-builder release: pending
* R-hub R-devel and R-release: pending

## R CMD check results

Local source-tarball result: 0 errors | 0 warnings | 0 notes.

## Backward compatibility

* `format = "rds"`, `format = "both"`, and `.rds` export filenames now error
  before any file is written.
* Existing RDS databases continue to load via `boilerplate_import()`. Users
  are pointed at `boilerplate_migrate_to_json()` in the RDS-read warning and
  the NEWS.
* The examples and vignettes that previously demonstrated RDS writing have
  been updated to JSON. The migration vignette
  (`boilerplate-json-workflow.Rmd`) retains RDS only in the portions
  demonstrating the migration itself.

## Submission note

Do not submit until the pending win-builder and R-hub results above have been
replaced with actual results.

---

# boilerplate 1.3.0 (previously submitted)

## Test environments

* local macOS install (aarch64-apple-darwin20), R 4.5.1
* win-builder (devel and release)
* R-hub
  - Windows (latest)
  - macOS (latest) 
  - Ubuntu Linux (release)

## R CMD check results

0 errors | 0 warnings | 1 note

* NOTE: New submission
  - This is expected for a resubmission to CRAN

## Third resubmission

This is a resubmission of boilerplate 1.3.0. In response to CRAN feedback about writing to user's home directory:

* Fixed policy violation by replacing hardcoded `~/.boilerplate/cache` with `tools::R_user_dir("boilerplate", "cache")`
* All default data paths now use `tools::R_user_dir("boilerplate", "data")` instead of user's project directory
* Removed 'here' package dependency
* Updated all functions, tests, and vignettes to use CRAN-compliant locations
* Added migration code to move existing cache files from old location to new location
* Ensured no files are written outside of R session's temporary directory or approved user directories
* Fixed linting issues: removed unused variables in generate-text.R and import-functions.R
* Added interactive() checks to all user prompts for non-interactive compatibility

The package now fully complies with CRAN's policy on file system usage for R 4.0+.

## Previous resubmission

This is a resubmission of the boilerplate package (version 1.2.0). In response to the CRAN team feedback, we have:

* Fixed all test failures on Windows by adding the `create_dirs=TRUE` parameter to file operations
* Removed non-standard file (`submit_to_cran.R`) from the top level directory
* Fixed vignette building errors related to directory creation
* All tests now pass on Windows, Linux, and macOS platforms

In this version, I have addressed all feedback from the CRAN reviewer:

* Removed redundant "Tools for" from the package title
* Removed redundant "Provides tools for" from the package description
* Added \value tags to all exported functions (.Rd files)
* Replaced all \dontrun{} with \donttest{} in examples
* Fixed all examples to pass R CMD check --run-donttest
  - All examples now properly initialise databases in temporary directories
  - Examples clean up after themselves
  - Examples are self-contained and do not rely on existing files
* Regarding references: This package does not implement any published statistical methods or algorithms that require citations. It is a utility package for managing text templates and boilerplate content. The package helps users organize and reuse their own text snippets for scientific writing, but does not itself implement any methods from the literature.

The package provides a unified framework for managing reusable text snippets, 
measurement instruments, and structured content using template variables. It is
particularly designed for reproducible research workflows with Quarto/R Markdown
documents in scientific writing.

## Key improvements in v1.2.0

* **Project support**: New project-based organization keeps different boilerplate collections separate
  - All core functions now accept a `project` parameter
  - `boilerplate_copy_from_project()` enables selective copying between projects
  - Backward compatible with default "default" project
* **Fixed all examples**: Every example now passes R CMD check --run-donttest
  - Examples properly initialise databases in temporary directories
  - All examples are self-contained and clean up after themselves
  - No reliance on existing files or directories

## Package strengths

* **Minimal dependencies**: Only 6 imports (cli, digest, jsonlite, jsonvalidate, tools, utils)
  - Reduced from 9 in development by replacing glue, janitor, stringr, and here with base R
  - All remaining dependencies serve essential, distinct purposes
* **Comprehensive testing**: 847 tests across 30 test files with 73.12% code coverage
  - Core functionality has high coverage (>80%)
  - Interactive functions have appropriate skip conditions for non-interactive environments
  - New project functionality tested
  - Vignette examples thoroughly tested
* **Extensive documentation**: 
  - 12 vignettes covering different workflows
  - All 39 exported functions have complete documentation with examples
  - Examples use tempdir() exclusively for file operations
* **Modern format**: JSON as default for better portability and version control
  - Still supports RDS for backward compatibility
  - Automatic format detection on import
* **Safety features**: 
  - Confirmation prompts before overwriting files
  - Automatic backups in interactive sessions
  - Context-aware backup handling (disabled in temp directories)
  - Standardised file naming conventions

## Use cases

The package addresses a specific need in scientific writing:
- Managing standardised text across multiple manuscripts
- Ensuring consistency in methods descriptions
- Version control friendly database format (JSON)
- Template variable substitution for dynamic content
- Batch operations for database maintenance

## Testing and code quality

* **Code coverage**: 73.12% overall
  - High coverage (>80%) for core functionality: default databases (98.79%), path operations (93.33%), health checks (91.47%), standardise measures (83.33%), JSON support (82.89%), generate-text (81.32%), migration utilities (80.08%)
  - Medium coverage (50-80%) for most modules: boilerplate batch edit (75.37%), zzz (75.00%), bibliography support (70.62%), version management (68.71%), utilities (67.92%), init functions (65.26%), generate measures (64.97%), import functions (58.79%), import-export functions (55.07%), category helpers (50.00%)
  - Lower coverage (<50%) for: project functions (46.98%)
  - 847 tests across 30 test files ensure robust functionality
* All examples use \donttest{} instead of \dontrun{}
* All examples now properly initialise databases and clean up after themselves
* Consistent API design across all functions
* Defensive programming with input validation
* Clear error messages with cli package

## Downstream dependencies

There are currently no downstream dependencies for this package.
