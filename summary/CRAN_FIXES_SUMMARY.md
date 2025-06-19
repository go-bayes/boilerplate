# CRAN Policy Compliance Fixes Summary

## Package: boilerplate v1.3.0

### Issues Fixed

1. **Non-Standard Directory Structure** ✓
   - Removed `/boilerplate/data/` directory containing data files
   - Removed `/doc/` directory (should only be in `/inst/doc/`)
   - Removed `/Meta/` directory
   - Removed `boilerplate_1.2.1.tar.gz` (built package file)
   - Removed `codecov.yml` (CI configuration)

2. **File System Writes Outside Allowed Locations** ✓
   - Changed default data path from `here::here("boilerplate", "projects", project, "data")` to `tools::R_user_dir("boilerplate", "data")`
   - Updated ALL functions that write to disk: `boilerplate_init()`, `boilerplate_import()`, `boilerplate_save()`, `boilerplate_export()`, etc.
   - Fixed `write_boilerplate_db()` to require directories exist (no automatic creation)

3. **Interactive Prompts in Non-Interactive Contexts** ✓
   - Added `interactive()` check to `ask_yes_no()` function
   - Replaced all direct `readline()` calls with `ask_yes_no()`
   - Returns FALSE (conservative default) in non-interactive mode

4. **Directory Creation Without Permission** ✓
   - Fixed `write_boilerplate_db()` to throw error if directory doesn't exist
   - All directory creation now requires explicit `create_dirs=TRUE` parameter

5. **Package Dependencies** ✓
   - Removed 'here' package from Imports (reduced from 7 to 6 dependencies)
   - Removed all `@importFrom here here` statements

### Files Modified

- **R Code Files:**
  - `R/init-functions.R`
  - `R/import-functions.R` 
  - `R/import-export-functions.R`
  - `R/project-functions.R`
  - `R/utilities.R`
  - `R/version-management.R`
  - `R/json-support.R`

- **Package Metadata:**
  - `DESCRIPTION` (version 1.2.1 → 1.3.0, removed 'here' from Imports)
  - `NEWS.md` (added v1.2.2 entry)
  - `cran-comments.md` (added fourth resubmission notes)

### Testing Recommendations

Before CRAN submission, run:
```r
# Full check with all tests
R CMD check boilerplate_1.2.2.tar.gz --as-cran --run-donttest

# Check examples specifically
R CMD check boilerplate_1.2.2.tar.gz --as-cran --run-donttest --examples

# Run on multiple platforms via rhub
rhub::check_for_cran()
```

### Notes

- All examples use `tempdir()` for file operations
- Vignettes use `eval=FALSE` for file operation demonstrations (standard practice)
- Package maintains backward compatibility while fixing CRAN violations
- Conservative defaults ensure package works in all environments