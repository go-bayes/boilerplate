# PLANNING.md

## 2025-06-21: Comprehensive Vignette and Example Fixes (v1.3.0)

### Issue
User reported that the README example `sections = "statistical"` was failing with error "section statistical is not a character string or list with default". Further investigation revealed systematic issues across all vignettes.

### Solution
1. Fixed README.Rmd:
   - Changed `sections = "statistical"` to `sections = "statistical.default"` to use full path
   - Fixed embedding example to use `create_empty = FALSE` to load default content
   - Updated all section paths to use complete paths (e.g., "sample.default" not just "sample")

2. Fixed 12 vignettes:
   - Added `create_empty = FALSE` to initialization calls that need default content
   - Added missing `data_path` parameters to all function calls
   - Used temporary directories for all examples to avoid file system issues
   - Fixed section paths to use valid entries from default database
   - Commented out examples that reference non-existent entries with explanations

3. Systematic fixes across all vignettes:
   - boilerplate-bibliography-workflow.Rmd: Fixed initialization and section paths
   - boilerplate-getting-started.Rmd: Fixed paths and added checks for optional entries
   - boilerplate-intro-enhanced.Rmd: Updated all examples with proper paths
   - boilerplate-intro.Rmd: Added temp directories and fixed export example
   - boilerplate-json-workflow.Rmd: Added clarifying comments
   - boilerplate-measures-workflow.Rmd: Fixed all save calls and added existence checks
   - boilerplate-quarto-workflow.Rmd: Complete rewrite to use unified database approach
   - version-management-section.Rmd: Added data_path to all function calls

### Technical Details
- The issue was that `create_empty = TRUE` (default) creates empty database structures
- Users need `create_empty = FALSE` to get the default example content
- Section paths must be complete (e.g., "statistical.default" not just "statistical")

### Testing
- All examples now use self-contained temporary directories
- Examples are runnable without prior setup
- Fixed examples test user workflows accurately

## 2025-06-20: Documentation and Example Fixes (v1.3.0)

### Issue
User testing revealed several issues with README examples:
1. `sections = "statistical.default"` caused errors because "default" is a field within "statistical", not a nested path
2. Examples used `here::here()` even though the package no longer depends on 'here'
3. Some examples referenced non-existent projects or used paths that wouldn't work for users
4. Migration example failed because it's only for old RDS files, not the default JSON format

### Solution
1. Changed all instances of `"statistical.default"` to just `"statistical"` with comment explaining default will be used
2. Replaced all `here::here()` references with temporary directories using `tempdir()` for examples
3. Made all examples self-contained and runnable without prior setup
4. Commented out examples that require specific setup with explanatory notes
5. Added cleanup code (`unlink()`) to examples that create temporary files
6. Fixed `boilerplate_list_files()` examples to include required `data_path` parameter

### Technical Details
- The `boilerplate_generate_text()` function navigates nested paths with dots, but when it finds a list with a "default" entry, it automatically uses that
- All examples now use temporary directories that are cleaned up after running
- Examples that can't be run directly (like cross-project operations) are commented with explanations

### Testing
- Created comprehensive test script to verify all README examples work
- Updated test files to match corrected section paths
- All 34 tests in test-readme-examples.R pass
- README rebuilds correctly from Rmd source

## 2025-06-17: CRAN Policy Compliance (v1.2.1)

### Issue
CRAN flagged that boilerplate was writing to `~/.boilerplate`, violating their policy that packages should not write to user's home filespace.

### Solution
1. Updated `boilerplate_update_bibliography()` to use `tools::R_user_dir("boilerplate", "cache")` instead of hardcoded `~/.boilerplate/cache`
2. Added migration function to automatically move existing cache files from old location to new location
3. Updated all tests and vignettes to remove hardcoded home directory references
4. Fixed linting issues in generate-text.R and import-functions.R

### Technical Details
- `tools::R_user_dir()` provides platform-specific appropriate directories:
  - Unix/Mac: `~/.local/share/boilerplate/cache`
  - Windows: `%LOCALAPPDATA%/boilerplate/boilerplate/cache`
- Migration is automatic and silent for users
- Backward compatible - old cache files are migrated on first use

### Testing
- Added specific test for cache directory location
- All existing tests pass
- No writes outside approved directories