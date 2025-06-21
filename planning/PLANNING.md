# PLANNING.md

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