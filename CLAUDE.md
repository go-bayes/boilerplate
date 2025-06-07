# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## General Guidelines
- Always use NZ English
- Always use lower case code comments
- When introducing a new function, make sure to document the tests using testthat 

## Build and Development Commands

### Package Development
- **Build and check**: `R CMD build .` then `R CMD check boilerplate_*.tar.gz`
- **Install package**: `devtools::install()`
- **Load for development**: `devtools::load_all()`
- **Document**: `devtools::document()`
- **Check package**: `devtools::check()`

### Testing
- **Run all tests**: `devtools::test()`
- **Run specific test file**: `testthat::test_file("tests/testthat/test-{name}.R")`
- **Run tests with coverage**: `covr::package_coverage()`

### Package Building
- **Build package**: `devtools::build()`
- **Build vignettes**: `devtools::build_vignettes()`
- **Update pkgdown site**: `pkgdown::build_site()`

## Package Architecture

The boilerplate package manages standardised text for scientific reports using a unified database system.

### Core Components

1. **Unified Database Structure**: All content types (methods, measures, results, discussion, appendix, template) are stored in a single `boilerplate_unified.json` file by default (new in v1.1.0).

2. **Hierarchical Path System**: Content is organised using dot notation paths (e.g., `methods.statistical.longitudinal.lmtp`) allowing nested categorisation.

3. **Template Variable System**: Text templates use `{{variable}}` placeholders that are replaced with actual values during generation.

### New Defaults (v1.1.0)

- `boilerplate_init()` now creates a single unified JSON database by default
- `boilerplate_save()` uses JSON format by default  
- Timestamps are disabled by default for cleaner file management
- Legacy mode available with `unified = FALSE` for separate category files

### Key Function Categories

- **Initialisation**: `boilerplate_init()` creates database files
- **Import/Export**: `boilerplate_import()`, `boilerplate_save()`, `boilerplate_export()`
- **Text Generation**: `boilerplate_generate_text()`, `boilerplate_generate_measures()`
- **Database Management**: `boilerplate_batch_edit()`, `boilerplate_batch_clean()`, `boilerplate_standardise_measures()`
- **Helper Functions**: Extract specific categories like `boilerplate_methods()`, `boilerplate_measures()`

### Format Support

The package supports both RDS (R's native format) and JSON formats. JSON is preferred for:
- Version control compatibility
- Cross-language interoperability
- Human readability
- Web application integration

### Database Categories

- **methods**: Statistical methods, sampling procedures, analysis approaches
- **measures**: Research instruments with items, descriptions, and metadata
- **results**: Result text templates
- **discussion**: Discussion section templates
- **appendix**: Supplementary material templates
- **template**: Complete document templates (journal articles, abstracts)

### Special Considerations

- Measures should be stored at the top level of the measures database, not nested under subcategories
- The package includes safety features like confirmation prompts and automatic backups
- Bibliography management is integrated with automatic citation validation
- Version management supports timestamped saves and backup restoration

## Development Guidelines

- **Language**: Use NZ English spelling (e.g., "colour", "organise", "standardise")
- **Code Comments**: Always use lowercase for code comments
- **Testing**: When introducing new functions, document tests using testthat framework
- **Documentation**: When introducing or modifying functions, update:
  - README.md with any new examples or features
  - Relevant vignettes in the `vignettes/` directory
  - Function documentation with roxygen2 comments