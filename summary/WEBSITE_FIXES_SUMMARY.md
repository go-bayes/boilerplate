# Website and Documentation Fixes Summary

## Issues Fixed

### 1. Removed all `here::here()` references
- Updated function documentation in R files
- Fixed README.Rmd examples
- Updated vignettes to use `file.path()` or relative paths
- Fixed example files

### 2. Updated example bibliography
Added citations that are actually used in the default content:
- @vanderweele2019
- @van2014targeted  
- @van2012targeted
- @diaz2021
- @grf2024

This prevents "missing references" warnings when users run the examples.

### 3. Fixed path examples
Changed from vague "path/to" to realistic examples:
- `"my_project/data"`
- `file.path("my_research_project", "data")`
- Uses `quiet = TRUE` in examples to reduce output noise

### 4. Updated documentation
- Rebuilt all man pages with `devtools::document()`
- Rebuilt README.md from README.Rmd
- Rebuilt pkgdown site with updated examples

## Key Changes

### README.Rmd
- Replaced `here::here()` references with `tools::R_user_dir()` explanation
- Fixed JSON examples to use realistic paths
- Added `confirm = FALSE, quiet = TRUE` to examples

### Vignettes
- boilerplate-intro-enhanced.Rmd: Updated path recommendations
- boilerplate-getting-started.Rmd: Removed here package reference
- boilerplate-quarto-workflow.Rmd: Updated alternative path suggestion

### inst/extdata/example_references.bib
- Now contains all citations used in default boilerplate content
- Prevents validation warnings in examples

## Result
- All examples now work without external dependencies
- No more `here::here()` references (package was removed)
- Bibliography examples validate correctly
- Website documentation is consistent with package behavior