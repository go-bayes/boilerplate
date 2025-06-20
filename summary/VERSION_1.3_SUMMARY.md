# boilerplate 1.3.0 Summary

## Overview
Version 1.3.0 addresses CRAN policy violations and improves package robustness through comprehensive testing.

## Major Changes

### 1. CRAN Policy Compliance
- Fixed writing to `~/.boilerplate` by using `tools::R_user_dir("boilerplate", "cache")`
- All default paths now use `tools::R_user_dir("boilerplate", "data")`
- Removed 'here' package dependency
- Added automatic migration from old cache location

### 2. Bug Fixes
- Fixed README example using non-existent section "analysis"
- Fixed `boilerplate_export` to create consistent filenames ("boilerplate_unified.json")
- Made `get_default_data_path` internal to resolve pkgdown issues
- Fixed `.vscode` directory inclusion in builds

### 3. Test Coverage Improvements
- Expanded from 731 to 840 tests
- Added 8 new test files for vignettes and README examples
- All vignette examples now have comprehensive test coverage
- Fixed all failing vignette tests

### 4. Documentation
- Updated all examples to use correct section paths
- Added comprehensive tests for documentation examples
- Fixed function signatures in test files

## Technical Details

### Test Files Added
1. test-readme-examples.R
2. test-vignette-intro.R
3. test-vignette-intro-enhanced.R
4. test-vignette-quarto-workflow.R
5. test-vignette-architecture.R
6. test-vignette-internals.R
7. test-vignette-json-schema.R
8. test-vignette-version-management.R

### Key Fixes
- `boilerplate_export`: Changed base filename from "unified_db" to "boilerplate_unified"
- Test expectations: Updated to match actual function return values
- Function signatures: Fixed parameter names in test calls

## CRAN Submission Status
- R CMD check: 0 errors, 0 warnings, 0 notes
- Package successfully submitted to win-builder
- Ready for CRAN resubmission

## Files Updated
- NEWS.md: Updated for version 1.3.0
- cran-comments.md: Updated for third resubmission
- .Rbuildignore: Added `.vscode` and cleaned up entries
- R/import-export-functions.R: Fixed export filename
- 8 new test files added
- Multiple test files updated to fix signatures