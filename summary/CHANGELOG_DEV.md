# CHANGELOG_DEV.md

## 2025-06-19: Version Update for CRAN Resubmission (v1.3.0)

### Changes Made
1. **Version update**
   - Updated version from 1.2.1 to 1.3.0 for third CRAN resubmission
   - Updated all documentation to reflect new version number

2. **Documentation cleanup**
   - Moved `CRAN_FIXES_SUMMARY.md` and `FINAL_SUBMISSION_SUMMARY.md` to summary/ directory
   - Added `.vscode` to `.Rbuildignore` to exclude empty directory
   - Cleaned up root directory for CRAN submission

3. **Fixed pkgdown issue**
   - Made `get_default_data_path` an internal function (removed roxygen docs)
   - Resolved missing topics error in pkgdown build

### Technical Notes
- All 731 tests pass
- Code coverage remains at 71.47%
- R CMD check: 0 errors, 0 warnings, 2 expected NOTEs
- Package ready for third CRAN resubmission

## 2025-06-17: Major CRAN Policy Compliance Fixes (v1.2.1) - FINAL

### Critical Issues Fixed
1. **Removed non-standard directories from package root**
   - Deleted `/boilerplate/data/` directory containing data files
   - Deleted `/doc/` directory (should only be in inst/doc)
   - Deleted `/Meta/` directory  
   - Deleted `boilerplate_1.2.1.tar.gz` (built package)
   - Deleted `codecov.yml` (CI configuration)

2. **Fixed file system writes to use CRAN-compliant locations**
   - Changed default data path from `here::here("boilerplate", ...)` to `tools::R_user_dir("boilerplate", "data")`
   - Updated all functions: `boilerplate_init()`, `boilerplate_import()`, `boilerplate_save()`, `boilerplate_export()`
   - Fixed `write_boilerplate_db()` to not create directories automatically
   - Files now: `R/init-functions.R`, `R/import-functions.R`, `R/import-export-functions.R`, `R/project-functions.R`, `R/utilities.R`, `R/version-management.R`, `R/json-support.R`

3. **Fixed interactive prompts for non-interactive environments**
   - Added `interactive()` check to `ask_yes_no()` function
   - Replaced direct `readline()` calls with `ask_yes_no()` 
   - Returns FALSE in non-interactive mode (conservative default)
   - Files: `R/utilities.R`, `R/import-functions.R`, `R/project-functions.R`

4. **Removed duplicate function definitions**
   - Removed duplicate `ask_yes_no()` from `project-functions.R`

5. **Removed 'here' package dependency**
   - No longer needed since we use `tools::R_user_dir()` for default paths
   - Reduces dependencies from 7 to 6

### Notes
- Some vignettes have `eval=FALSE` to prevent file operations during build
- This is standard practice for packages that demonstrate file I/O operations

## 2025-06-17: CRAN Policy Compliance Fix (v1.2.1)

### Changes Made
1. **Fixed CRAN policy violation** - Replaced hardcoded `~/.boilerplate/cache` with `tools::R_user_dir("boilerplate", "cache")`
   - Modified: `R/bibliography-support.R`
   - Added migration function to move existing cache files
   - Updated default cache_dir parameter to NULL and set dynamically

2. **Fixed linting issues**
   - `R/generate-text.R`: Removed unused `category_title` variable (line 107)
   - `R/import-functions.R`: Removed unused `backup_path` assignment (line 415)

3. **Updated tests**
   - `tests/testthat/test-vignette-bibliography.R`: Removed hardcoded home directory path
   - `tests/testthat/test-bibliography-support.R`: Added test for tools::R_user_dir usage

4. **Updated documentation**
   - `vignettes/boilerplate-bibliography-workflow.Rmd`: Updated cache directory references
   - `inst/examples/json-examples/lab-workflow.R`: Updated to use tools::R_user_dir

5. **Version and metadata updates**
   - `DESCRIPTION`: Version 1.2.0 → 1.2.1
   - `NEWS.md`: Added entry for 1.2.1 with bug fixes
   - `cran-comments.md`: Added third resubmission notes

### Technical Notes
- Cache migration is automatic and preserves existing cached files
- New cache location is platform-appropriate per CRAN guidelines
- All functions maintain backward compatibility