# Bibliography Changes Summary

## Overview
Replaced all external bibliography URLs in package examples with a local example bibliography file to ensure self-contained examples that don't depend on external resources.

## Changes Made

### 1. Created Example Bibliography
- Added `inst/extdata/example_references.bib` with 5 example citations
- Contains various citation types: article, book, inproceedings, misc, etc.
- Self-contained within the package

### 2. Updated Package Code
- **R/bibliography-support.R**: Updated example in `boilerplate_add_bibliography()`
- Now uses: `system.file("extdata", "example_references.bib", package = "boilerplate")`

### 3. Updated Documentation
- **README.Rmd**: Updated bibliography example
- **README.md**: Regenerated from README.Rmd
- **man/boilerplate_add_bibliography.Rd**: Regenerated documentation

### 4. Updated Vignettes
- **boilerplate-getting-started.Rmd**: Updated bibliography setup
- **boilerplate-bibliography-workflow.Rmd**: Updated two instances
- **boilerplate-quarto-workflow.Rmd**: Updated bibliography example
- **inst/examples/minimal-quarto-example.qmd**: Updated example

### 5. Updated Tests
- **test-vignette-bibliography.R**: Updated all URL references
- **test-readme-examples.R**: Updated bibliography test
- **test-vignette-getting-started.R**: Updated bibliography setup
- Fixed URL pattern check to match new local file

## Pattern Used
```r
# Old pattern:
url = "https://raw.githubusercontent.com/go-bayes/templates/main/bib/references.bib"

# New pattern:
example_bib <- system.file("extdata", "example_references.bib", package = "boilerplate")
url = paste0("file://", example_bib)
```

## Benefits
1. Examples are now self-contained
2. No external dependencies for examples
3. Tests don't require internet access
4. Examples will always work regardless of external URL changes
5. CRAN-compliant: no hardcoded external URLs in main package

## Note
Example scripts in `inst/examples/` still contain some external URLs, but these are:
- Documentation/tutorial scripts only
- Show users how to work with remote repositories
- Not part of main package functionality