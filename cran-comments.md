## Test environments

* local macOS install (aarch64-apple-darwin20), R 4.5.0
* win-builder (devel and release)
* R-hub
  - Windows Server 2022, R-devel, 64 bit
  - Ubuntu Linux 20.04.1 LTS, R-release, GCC
  - Fedora Linux, R-devel, clang, gfortran

## R CMD check results

0 errors | 0 warnings | 0 notes


## Third resubmission

This is a resubmission of boilerplate 1.2.1. In response to CRAN feedback about writing to user's home directory:

* Fixed policy violation by replacing hardcoded `~/.boilerplate/cache` with `tools::R_user_dir("boilerplate", "cache")`
* All default data paths now use `tools::R_user_dir("boilerplate", "data")` instead of user's project directory
* Removed 'here' package dependency - reduced imports from 7 to 6
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
  - All examples now properly initialize databases in temporary directories
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
  - Examples properly initialize databases in temporary directories
  - All examples are self-contained and clean up after themselves
  - No reliance on existing files or directories

## Package strengths

* **Minimal dependencies**: Only 7 imports (cli, digest, here, jsonlite, jsonvalidate, tools, utils)
  - Reduced from 9 in development by replacing glue, janitor, and stringr with base R
  - All remaining dependencies serve essential, distinct purposes
* **Comprehensive testing**: 726 tests across 22 test files with 71.20% code coverage
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

* **Code coverage**: 71.47% overall
  - High coverage (>80%) for core functionality: default databases (98.79%), path operations (93.33%), health checks (91.47%), JSON support (82.89%), standardise measures (83.33%), generate-text (81.32%)
  - Medium coverage (50-80%) for most modules: migration utilities (75.85%), zzz (75.00%), batch edit (73.61%), bibliography support (70.00%), version management (68.03%), init functions (65.26%), generate measures (64.97%), utilities (59.75%), import functions (58.79%)
  - Lower coverage (<50%) for: import-export functions (49.78%), project functions (46.98%), category helpers (45.45%)
  - 731 tests across 22 test files ensure robust functionality
* All examples use \donttest{} instead of \dontrun{}
* All examples now properly initialize databases and clean up after themselves
* Consistent API design across all functions
* Defensive programming with input validation
* Clear error messages with cli package

## Downstream dependencies

There are currently no downstream dependencies for this package.
