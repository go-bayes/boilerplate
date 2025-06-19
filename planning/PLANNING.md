# PLANNING.md

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