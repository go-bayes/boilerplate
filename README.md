
<!-- readme.md is generated from readme.rmd. please edit that file -->

## Overview

The `boilerplate` package provides tools for managing and generating
standardised text for methods and results sections of scientific
reports. It handles template variable substitution and supports
hierarchical organisation of text through dot-separated paths. The
package features a unified database approach that simplifies workflows
and provides consistent management of all content types.

## Installation

You can install the development version of `boilerplate` from GitHub
with:

``` r
# install the devtools package if you don't have it already
install.packages("devtools")
devtools::install_github("go-bayes/boilerplate")
```

## Features

### Core Features

- **Unified Database System**: Work with all content types through a
  consistent interface
- **Multiple Categories**: Support for methods, results, discussion,
  measures, appendices and document templates
- **Hierarchical Organisation**: Organise content in nested categories
  using dot notation (e.g., `statistical.longitudinal.lmtp`)
- **Default Content**: Comes with pre-loaded defaults for common methods
  sections
- **Quarto/R Markdown Integration**: Generate sections for scientific
  reports

### Text and Document Features

- **Text Template Management**: Create, update, and retrieve reusable
  text templates
- **Variable Substitution**: Replace `{{variable}}` placeholders with
  actual values
- **Document Templates**: Streamlined creation of journal articles,
  conference presentations, and grant proposals
- **Custom Headings**: Flexible heading levels and custom text for
  generated sections

### Measurement Features

- **Measures Database**: Special handling for research measures with
  descriptions, items, and metadata
- **Measure Standardisation**: Automatically clean and standardise
  measure entries for consistency
- **Quality Reporting**: Assess completeness and consistency of your
  measures database
- **Formatted Output**: Generate publication-ready measure descriptions
  with multiple format options

### Database Management Features

- **Batch Operations**: Efficiently update or clean multiple entries at
  once with pattern matching and wildcards
- **Preview Mode**: See all changes before applying them to prevent
  accidents
- **Export Functions**: Create backups and share specific database
  subsets
- **Safety Features**: Prevention of accidental file overwrites and
  standardised file naming

## Safety Features

The `boilerplate` package includes several safety features to prevent
accidental overwrites:

- The unified `boilerplate_save()` and `boilerplate_export()` functions
  requires explicit specification of categories when saving individual
  databases
- Standard file naming conventions ensure consistency across projects
- All functions that modify files include confirmation prompts (when
  `confirm=TRUE`) before making changes
- Consistent sorting of database entries ensures predictable structure
  and easier version control

## Basic Usage with Unified Database

``` r
# install from github if not already installed
if (!require(boilerplate, quietly = TRUE)) {
  # install devtools if necessary
  if (!require(devtools, quietly = TRUE)) {
    install.packages("devtools")
  }
  devtools::install_github("go-bayes/boilerplate")
}

# initialise all databases with a single function 
# (this creates database files in the "boilerplate/data" folder relative to your project root)
boilerplate_init(create_dirs = TRUE, confirm = TRUE)

# import all databases into a unified structure
unified_db <- boilerplate_import()

# add a new method entry directly to the unified database
unified_db$methods$sample_selection <- "Participants were selected from {{population}} during {{timeframe}}."

# save all changes at once
boilerplate_save(unified_db)

# generate text with variable substitution
methods_text <- boilerplate_generate_text(
  category = "methods",
  sections = c("sample", "sample_selection"),
  global_vars = list(
    population = "university students",
    timeframe = "2020-2021"
  ),
  db = unified_db,  # pass the unified database
  add_headings = TRUE
)

cat(methods_text)
```

## Working with Custom Data Paths

By default, boilerplate stores database files in the “boilerplate/data”
subdirectory of your working directory (using `here::here()`). However,
there are many situations where you might need to use a different
location:

- Working with multiple projects that each need their own boilerplate
  databases
- Storing databases in a shared network location
- Organizing files according to a specific project structure
- Testing and development scenarios

All key functions in the package (`boilerplate_init()`,
`boilerplate_import()`, `boilerplate_save()`, and
`boilerplate_export()`) accept a `data_path` parameter to specify a
custom location. When working with custom paths, be sure to use the same
path consistently across all functions.

### Example: Full Workflow with Custom Paths

``` r
# Define your custom path
my_project_path <- "path/to/your/project/data"

# Initialize databases in your custom location
boilerplate_init(
  categories = c("measures", "methods", "results", "discussion", "appendix", "template"),
  data_path = my_project_path,  # Specify custom path here
  create_dirs = TRUE,
  confirm = FALSE
)

# Import all databases from your custom location
unified_db <- boilerplate_import(
  data_path = my_project_path  # Specify the same custom path
)

# Make some changes
unified_db$measures$new_measure <- list(
  name = "new measure scale",
  description = "a newly added measure",
  reference = "author2023",
  waves = "1-2",
  keywords = c("new", "test"),
  items = list("test item 1", "test item 2")
)

# Save changes back to your custom location
boilerplate_save(
  db = unified_db,
  data_path = my_project_path,  # Specify the same custom path
  confirm = TRUE
)

# To save just a specific category:
boilerplate_save(
  db = unified_db$measures,
  category = "measures",
  data_path = my_project_path,
  confirm = TRUE
)
```

### Multiple Projects

You can easily work with multiple distinct sets of boilerplate databases
by using different paths:

``` r
# Project A
project_a_db <- boilerplate_import(data_path = "projects/project_a/data")

# Project B
project_b_db <- boilerplate_import(data_path = "projects/project_b/data")

# Make changes specific to Project A
project_a_db$methods$sample <- "Participants for Project A were recruited from..."
boilerplate_save(project_a_db, data_path = "projects/project_a/data")
```

### Relative vs. Absolute Paths

Both relative and absolute paths are supported:

``` r
# Relative path (relative to working directory)
boilerplate_import(data_path = "my_project/data")

# Absolute path
boilerplate_import(data_path = "/Users/researcher/projects/study_2023/data")
```

For portable code, consider using relative paths or functions like
`here::here()` to construct paths.

## Working with Individual Databases

You can still work with individual databases if preferred:

``` r
# import just the methods database
methods_db <- boilerplate_import("methods")

# add a new method entry
methods_db$sample_selection <- "Participants were selected from {{population}} during {{timeframe}}."

# save just the methods database
boilerplate_save(methods_db, "methods")

# generate text with variable substitution
methods_text <- boilerplate_generate_text(
  category = "methods",
  sections = c("sample", "sample_selection"),
  global_vars = list(
    population = "university students",
    timeframe = "2020-2021"
  ),
  db = methods_db,
  add_headings = TRUE
)

cat(methods_text)
```

## Creating Empty Databases

The package supports initialising empty database structures by default,
providing a clean slate for your project without sample content.

``` r
# Initialise empty databases (default behavior)
boilerplate_init(
  categories = c("methods", "results"),
  data_path = "~/project/data",
  create_dirs = TRUE
)

# Initialise with default content when needed
boilerplate_init(
  categories = c("methods", "results"),
  data_path = "~/project/data",
  create_dirs = TRUE,
  create_empty = FALSE
)
```

Empty databases provide just the top-level structure without example
content, making it easier to start with a clean slate.

## Database Export

The package now supports exporting databases for versioning or sharing
specific elements:

``` r
# Export entire database for versioning
# Creates a point-in-time snapshot of your boilerplate content
unified_db <- boilerplate_import()
boilerplate_export(
  db = unified_db,
  output_file = "boilerplate_v1.0.rds",
  data_path = "~/project/data"
)

# Export selected elements (specific methods and results)
# Useful for sharing specialized subsets with collaborators
boilerplate_export(
  db = unified_db,
  output_file = "causal_methods_subset.rds",
  select_elements = c("methods.statistical.*", "results.main_effect"),
  data_path = "~/project/data"
)
```

The export function supports: - Full database export (ideal for
versioning) - Selective export using dot notation (e.g.,
“methods.statistical.longitudinal”) - Wildcard selections using “*”
(e.g., ”methods.*” selects all methods) - Category-prefixed paths for
unified databases

Export is distinct from save: use `boilerplate_save()` for normal
database updates and `boilerplate_export()` for creating standalone
exports.

## Managing Measures with the Unified Database

The package provides a simplified way to manage measures and generate
formatted text about them. Measures are stored as top-level entries in
the measures database, with each measure containing standardized
properties like name, description, reference, etc.

``` r
# Import the unified database
unified_db <- boilerplate_import()

# Add a measure directly to the unified database
# Note: Measures should be at the top level of the measures database
unified_db$measures$anxiety_gad7 <- list(
  name = "generalised anxiety disorder scale (GAD-7)",
  description = "anxiety was measured using the GAD-7 scale.",
  reference = "spitzer2006",
  waves = "1-3",
  keywords = c("anxiety", "mental health", "gad"),
  items = list(
    "feeling nervous, anxious, or on edge",
    "not being able to stop or control worrying",
    "worrying too much about different things",
    "trouble relaxing"
  )
)

# Save the entire unified database
boilerplate_save(unified_db)

# Alternatively, save just the measures portion
boilerplate_save(unified_db$measures, "measures")

# Then generate text referencing the measure by its top-level name
exposure_text <- boilerplate_generate_measures(
  variable_heading = "Exposure Variable",
  variables = "anxiety_gad7", # match the name you used above
  db = unified_db,  # can pass the unified database
  heading_level = 3,
  subheading_level = 4,
  print_waves = TRUE
)
cat(exposure_text)

# You can also use the helper function to extract just the measures
measures_db <- boilerplate_measures(unified_db)

# Generate text for outcome variables using just the measures database
psych_text <- boilerplate_generate_measures(
  variable_heading = "Psychological Outcomes",
  variables = c("anxiety_gad7", "depression_phq9"),
  db = measures_db,  # or use the extracted measures database
  heading_level = 3,
  subheading_level = 4,
  print_waves = TRUE
)
cat(psych_text)

# Generate statistical methods text
stats_text <- boilerplate_generate_text(
  category = "methods",
  sections = c("statistical.longitudinal.lmtp"),
  global_vars = list(software = "R version 4.2.0"),
  add_headings = TRUE,
  custom_headings = list("statistical.longitudinal.lmtp" = "LMTP"),
  heading_level = "###",
  db = unified_db  # pass the unified database
)

# Initialize a sample text (assuming this was defined earlier)
sample_text <- boilerplate_generate_text(
  category = "methods",
  sections = "sample",
  global_vars = list(population = "university students", timeframe = "2023-2024"),
  db = unified_db
)

# Combine all sections into a complete methods section
methods_section <- paste(
  "## Methods\n\n",
  sample_text, "\n\n",
  "### Variables\n\n",
  exposure_text, "\n",
  "### Outcome Variables\n\n",
  psych_text, "\n\n",
  stats_text,
  sep = ""
)
cat(methods_section)

# Save the methods section to a file that can be included in a quarto document
# writeLines(methods_section, "methods_section.qmd")
```

### Important Notes on Measure Structure

When adding measures to the database:

1.  Each measure should be a top-level entry in the measures database
2.  Standard properties include: `name`, `description`, `reference`,
    `waves`, `keywords`, and `items`
3.  The `items` property should be a list of item text strings
4.  When referencing measures in `boilerplate_generate_measures()`, use
    the top-level name

Incorrect structure (avoid this):

``` r
# Don't organize measures under categories at the top level
unified_db$measures$psychological$anxiety <- list(...)  # WRONG
```

Correct structure:

``` r
# Add measures directly at the top level
unified_db$measures$anxiety_gad7 <- list(...)  # CORRECT
unified_db$measures$depression_phq9 <- list(...) # CORRECT
```

## Standardising and Reporting on Measures

The package includes powerful tools for standardising measure entries
and reporting on database quality. This is particularly useful when
working with legacy databases or when multiple contributors have added
measures with inconsistent formatting.

### Standardising Measures

The `boilerplate_standardise_measures()` function automatically cleans
and standardises your measures:

``` r
# Import your database
unified_db <- boilerplate_import()

# Check quality before standardisation
boilerplate_measures_report(unified_db$measures)

# Standardise all measures
unified_db$measures <- boilerplate_standardise_measures(
  unified_db$measures,
  extract_scale = TRUE,      # Extract scale info from descriptions
  identify_reversed = TRUE,   # Identify reversed items
  clean_descriptions = TRUE,  # Clean up description text
  verbose = TRUE             # Show what's being done
)

# Save the standardised database
boilerplate_save(unified_db)
```

#### What Standardisation Does

1.  **Extracts Scale Information**: Identifies and extracts scale
    details from descriptions

    ``` r
    # Before:
    description = "Ordinal response: (1 = Strongly Disagree, 7 = Strongly Agree)"

    # After:
    description = NULL  # Removed if only contains scale info
    scale_info = "1 = Strongly Disagree, 7 = Strongly Agree"
    scale_anchors = c("1 = Strongly Disagree", "7 = Strongly Agree")
    ```

2.  **Identifies Reversed Items**: Detects items marked with (r),
    (reversed), etc.

    ``` r
    # Items with (r) markers are identified
    items = list(
      "I have frequent mood swings.",
      "I am relaxed most of the time. (r)",
      "I get upset easily."
    )
    # Creates: reversed_items = c(2)
    ```

3.  **Cleans Descriptions**: Removes extra whitespace, fixes punctuation

4.  **Standardises References**: Ensures consistent reference formatting

5.  **Ensures Complete Structure**: All measures have standard fields

### Quality Reporting

Use `boilerplate_measures_report()` to assess your measures database:

``` r
# Get a quality overview
boilerplate_measures_report(unified_db$measures)

# Output:
# === Measures Database Quality Report ===
# Total measures: 180
# Complete descriptions: 165 (91.7%)
# With references: 172 (95.6%)
# With items: 180 (100.0%)
# With wave info: 178 (98.9%)
# Already standardised: 180 (100.0%)

# Get detailed report as data frame
quality_report <- boilerplate_measures_report(
  unified_db$measures, 
  return_report = TRUE
)

# Find measures missing information
missing_refs <- quality_report[!quality_report$has_reference, ]
missing_desc <- quality_report[!quality_report$has_description, ]

# View specific measure details
View(quality_report)
```

### Standardising Specific Measures

You can also standardise individual measures or a subset:

``` r
# Standardise only specific measures
unified_db$measures <- boilerplate_standardise_measures(
  unified_db$measures,
  measure_names = c("anxiety_gad7", "depression_phq9", "self_esteem")
)

# Or standardise a single measure
unified_db$measures$anxiety_gad7 <- boilerplate_standardise_measures(
  unified_db$measures$anxiety_gad7
)
```

### Enhanced Output with Standardised Measures

After standardisation, the `boilerplate_generate_measures()` function
can better format your measures:

``` r
# Generate formatted output with enhanced features
measures_text <- boilerplate_generate_measures(
  variable_heading = "Psychological Measures",
  variables = c("self_control", "neuroticism"),
  db = unified_db,
  table_format = TRUE,        # Use table format
  sample_items = 3,           # Show only 3 items per measure
  check_completeness = TRUE,  # Note any missing information
  quiet = TRUE               # Suppress progress messages
)

cat(measures_text)
```

Example output:

``` markdown
### Psychological Measures

#### Self Control

| Field | Information |
|-------|-------------|
| Description | Self-control was measured using two items [@tangney_high_2004]. |
| Response Scale | 1 = Strongly Disagree, 7 = Strongly Agree |
| Waves | 5-current |

**Items:**

1. In general, I have a lot of self-control
2. I wish I had more self-discipline (r)

*(r) denotes reverse-scored item*

#### Neuroticism

| Field | Information |
|-------|-------------|
| Description | Mini-IPIP6 Neuroticism dimension [@sibley2011]. |
| Response Scale | 1 = Strongly Disagree, 7 = Strongly Agree |
| Waves | 1-current |

**Items:**

1. I have frequent mood swings.
2. I am relaxed most of the time. (r)
3. I get upset easily.

*(1 additional items not shown)*

*(r) denotes reverse-scored item*
```

### Best Practices

1.  **Run standardisation after importing** legacy databases to ensure
    consistency
2.  **Check the quality report** to identify measures needing attention
3.  **Review standardised output** before saving to ensure nothing
    important was lost
4.  **Keep the original** - use `boilerplate_export()` to create a
    backup before standardising
5.  **Document changes** - the standardisation adds metadata showing
    when measures were standardised

## Batch Editing and Cleaning Databases

The package includes powerful functions for batch editing and cleaning
your databases. These are particularly useful when you need to update
multiple entries at once or clean up inconsistent formatting.

### Batch Editing Fields

Use `boilerplate_batch_edit()` to update specific fields across multiple
entries:

``` r
# Load your database
unified_db <- boilerplate_import()

# Example 1: Update specific references
unified_db <- boilerplate_batch_edit(
  db = unified_db,
  field = "reference",
  new_value = "sibley2021",
  target_entries = c("ban_hate_speech", "born_nz", "age"),
  category = "measures"
)

# Example 2: Update all references containing "NZAVS"
unified_db <- boilerplate_batch_edit(
  db = unified_db,
  field = "reference",
  new_value = "sibley2021",
  match_pattern = "NZAVS",
  category = "measures"
)

# Example 3: Use wildcards to target groups of entries
unified_db <- boilerplate_batch_edit(
  db = unified_db,
  field = "waves",
  new_value = "1-15",
  target_entries = "anxiety*",  # All entries starting with "anxiety"
  category = "measures"
)

# Example 4: Update entries with specific values
unified_db <- boilerplate_batch_edit(
  db = unified_db,
  field = "reference",
  new_value = "sibley2024",
  match_values = c("dore2022boundaries", "string_is Developed for the NZAVS."),
  category = "measures"
)
```

### Preview Before Editing

Always preview changes before applying them:

``` r
# Preview what would change
boilerplate_batch_edit(
  db = unified_db,
  field = "reference",
  new_value = "sibley2021",
  target_entries = c("ban_hate_speech", "born_nz"),
  category = "measures",
  preview = TRUE
)

# Output shows what would change:
# Preview of changes:
# ℹ ban_hate_speech: "dore2022boundaries" -> "sibley2021"
# ℹ born_nz: "sibley2011" -> "sibley2021"
# ✓ Would update 2 entries
```

### Batch Editing Multiple Fields

Edit multiple fields in one operation:

``` r
# Update both reference and waves for specific entries
unified_db <- boilerplate_batch_edit_multi(
  db = unified_db,
  edits = list(
    list(
      field = "reference",
      new_value = "sibley2021",
      target_entries = c("ban_hate_speech", "born_nz")
    ),
    list(
      field = "waves",
      new_value = "1-15",
      target_entries = c("ban_hate_speech", "born_nz")
    )
  ),
  category = "measures"
)
```

### Batch Cleaning Fields

Clean up formatting issues across your database:

``` r
# Example 1: Remove unwanted characters from references
unified_db <- boilerplate_batch_clean(
  db = unified_db,
  field = "reference",
  remove_chars = c("@", "[", "]"),
  category = "measures"
)

# Example 2: Clean all entries EXCEPT specific ones
unified_db <- boilerplate_batch_clean(
  db = unified_db,
  field = "reference",
  remove_chars = c("@", "[", "]"),
  exclude_entries = c("forgiveness", "special_measure"),
  category = "measures"
)

# Example 3: Clean with pattern matching and exclusions
unified_db <- boilerplate_batch_clean(
  db = unified_db,
  field = "reference",
  remove_chars = c("@", "[", "]"),
  target_entries = "emp_*",        # All entries starting with "emp_"
  exclude_entries = "emp_special",  # Except this one
  category = "measures"
)

# Example 4: Multiple cleaning operations
unified_db <- boilerplate_batch_clean(
  db = unified_db,
  field = "description",
  remove_chars = c("(", ")"),
  replace_pairs = list("  " = " "),  # Replace double spaces with single
  trim_whitespace = TRUE,
  collapse_spaces = TRUE,
  category = "measures"
)
```

### Finding Entries That Need Cleaning

Before cleaning, identify which entries contain specific characters:

``` r
# Find all entries with problematic characters
entries_to_clean <- boilerplate_find_chars(
  db = unified_db,
  field = "reference",
  chars = c("@", "[", "]"),
  category = "measures"
)

# View the results
print(entries_to_clean)

# Find entries but exclude some from results
entries_to_clean <- boilerplate_find_chars(
  db = unified_db,
  field = "reference",
  chars = c("@", "[", "]"),
  exclude_entries = c("forgiveness", "special_*"),
  category = "measures"
)
```

### Workflow Example: Cleaning References

Here’s a complete workflow for cleaning up reference formatting:

``` r
# 1. First, see what needs cleaning
problem_refs <- boilerplate_find_chars(
  db = unified_db,
  field = "reference",
  chars = c("@", "[", "]", " "),
  category = "measures"
)

cat("Found", length(problem_refs), "references that need cleaning\n")

# 2. Preview the cleaning operation
boilerplate_batch_clean(
  db = unified_db,
  field = "reference",
  remove_chars = c("@", "[", "]"),
  replace_pairs = list(" " = "_"),  # Replace spaces with underscores
  trim_whitespace = TRUE,
  category = "measures",
  preview = TRUE
)

# 3. Apply the cleaning
unified_db <- boilerplate_batch_clean(
  db = unified_db,
  field = "reference",
  remove_chars = c("@", "[", "]"),
  replace_pairs = list(" " = "_"),
  trim_whitespace = TRUE,
  category = "measures",
  confirm = TRUE  # Will ask for confirmation
)

# 4. Save the cleaned database
boilerplate_save(unified_db)
```

### Best Practices for Batch Operations

1.  **Always preview first**: Use `preview = TRUE` to see what will
    change

2.  **Make backups**: Export your database before major changes

    ``` r
    boilerplate_export(unified_db, output_file = "backup_before_cleaning.rds")
    ```

3.  **Use exclusions carefully**: Some entries might have special
    formatting requirements

4.  **Test on subsets**: Try operations on a few entries before applying
    to all

5.  **Document changes**: Keep notes about what was changed and why

### Common Use Cases

#### Standardising References

``` r
# Convert various reference formats to consistent style
unified_db <- boilerplate_batch_clean(
  db = unified_db,
  field = "reference",
  remove_chars = c("@", "[", "]", "(", ")"),
  replace_pairs = list(
    " " = "",           # Remove spaces
    "," = "_",          # Replace commas
    "&" = "and"         # Replace ampersands
  ),
  category = "measures"
)
```

#### Updating Wave Information

``` r
# Update all measures from a specific wave range
unified_db <- boilerplate_batch_edit(
  db = unified_db,
  field = "waves",
  new_value = "1-16",
  match_values = c("1-15", "1-current"),
  category = "measures"
)
```

#### Fixing Description Formatting

``` r
# Clean up description formatting issues
unified_db <- boilerplate_batch_clean(
  db = unified_db,
  field = "description",
  replace_pairs = list(
    ".." = ".",         # Fix double periods
    " ." = ".",         # Fix space before period
    "  " = " "          # Fix double spaces
  ),
  trim_whitespace = TRUE,
  category = "measures"
)
```

These batch operations make it easy to maintain consistency across your
entire database, especially when dealing with legacy data or
contributions from multiple sources.

## Appendix Content with the Unified Database

The package supports appendix content that can be managed within the
unified database:

``` r
# import the unified database
unified_db <- boilerplate_import()

# add detailed measures documentation to appendix
unified_db$appendix$detailed_measures <- "# Detailed Measures Documentation\n\n## Overview\n\nThis appendix provides comprehensive documentation for all measures used in this study, including full item text, response options, and psychometric properties.\n\n## {{exposure_var}} Measure\n\n{{exposure_details}}\n\n## Outcome Measures\n\n{{outcome_details}}"

# save the changes to the unified database
boilerplate_save(unified_db)

# generate appendix text with variable substitution
appendix_text <- boilerplate_generate_text(
  category = "appendix",
  sections = c("detailed_measures"),
  global_vars = list(
    exposure_var = "Perfectionism",
    exposure_details = "The perfectionism measure consists of 3 items...",
    outcome_details = "Anxiety was measured using the GAD-7 scale..."
  ),
  db = unified_db  # pass the unified database
)

cat(appendix_text)
```

## Creating Complete Document Workflows

You can create complete workflows that integrate methods, results, and
templates using the unified database:

``` r
# import the unified database
unified_db <- boilerplate_import()

# function to generate a complete document from a template
generate_document <- function(template_name, study_params, section_contents, db) {
  # extract the template using the boilerplate_template helper
  template_text <- boilerplate_template(db, template_name)
  
  # apply template variables (combining study params and section contents)
  all_vars <- c(study_params, section_contents)
  
  # replace placeholders in template
  for (var_name in names(all_vars)) {
    placeholder <- paste0("{{", var_name, "}}")
    template_text <- gsub(placeholder, all_vars[[var_name]], template_text, fixed = TRUE)
  }
  
  return(template_text)
}

# define study parameters
study_params <- list(
  title = "Political Orientation and Social Wellbeing in New Zealand",
  authors = "Jane Smith, John Doe, and Robert Johnson",
  date = format(Sys.Date(), "%B %d, %Y")
)

# define section contents
section_contents <- list(
  abstract = "This study investigates the causal relationship between political orientation and social wellbeing using data from the New Zealand Attitudes and Values Study.",
  introduction = "Understanding the relationship between political beliefs and wellbeing has important implications for social policy and public health...",
  methods_sample = "Participants were recruited from university students during 2020-2021.",
  methods_measures = "Political orientation was measured using a 7-point scale...",
  methods_statistical = "We used the LMTP estimator to address confounding...",
  results = "Our analysis revealed significant effects of political conservatism on social wellbeing...",
  discussion = "These findings suggest that political orientation may causally influence wellbeing through several pathways..."
)

# generate the document
journal_article <- generate_document(
  template_name = "journal_article",
  study_params = study_params,
  section_contents = section_contents,
  db = unified_db
)

cat(substr(journal_article, 1, 2500), "...")
```

## Advanced Usage: Audience-Specific Reports with the Unified Database

You can create tailored reports for different audiences from the same
underlying data:

``` r
# import the unified database
unified_db <- boilerplate_import()

# add audience-specific LMTP descriptions
unified_db$methods$statistical_estimator$lmtp$technical_audience <- "We estimate causal effects using the Longitudinal Modified Treatment Policy (LMTP) estimator within a Targeted Minimum Loss-based Estimation (TMLE) framework. This semi-parametric estimator leverages the efficient influence function (EIF) to achieve double robustness and asymptotic efficiency."

unified_db$methods$statistical_estimator$lmtp$applied_audience <- "We estimate causal effects using the LMTP estimator. This approach combines machine learning with causal inference methods to estimate treatment effects while avoiding strict parametric assumptions."

unified_db$methods$statistical_estimator$lmtp$general_audience <- "We used advanced statistical methods that account for multiple factors that might influence both {{exposure_var}} and {{outcome_var}}. This method helps us distinguish between mere association and actual causal effects."

# save the updated unified database
boilerplate_save(unified_db)

# function to generate methods text for different audiences
generate_methods_by_audience <- function(audience = c("technical", "applied", "general"), db) {
  audience <- match.arg(audience)
  
  # select appropriate paths based on audience
  lmtp_path <- paste0("statistical_estimator.lmtp.", audience, "_audience")
  
  # generate text
  boilerplate_generate_text(
    category = "methods",
    sections = c("sample", lmtp_path),
    global_vars = list(
      exposure_var = "political_conservative",
      outcome_var = "social_wellbeing"
    ),
    db = db
  )
}

# generate reports for different audiences
technical_report <- generate_methods_by_audience("technical", unified_db)
applied_report <- generate_methods_by_audience("applied", unified_db)
general_report <- generate_methods_by_audience("general", unified_db)

cat("General audience report:\n\n", general_report)
```

## Helper Functions for the Unified Database

The unified database approach includes several helper functions to
extract specific categories:

``` r
# import the unified database
unified_db <- boilerplate_import()

# extract specific categories using helper functions
methods_db <- boilerplate_methods(unified_db)
measures_db <- boilerplate_measures(unified_db)
results_db <- boilerplate_results(unified_db)
discussion_db <- boilerplate_discussion(unified_db)
appendix_db <- boilerplate_appendix(unified_db)
template_db <- boilerplate_template(unified_db)

# extract specific items using dot notation
lmtp_method <- boilerplate_methods(unified_db, "statistical.longitudinal.lmtp")
anxiety_measure <- boilerplate_measures(unified_db, "anxiety_gad7")
main_result <- boilerplate_results(unified_db, "main_effect")

# you can also directly access via the list structure
causal_assumptions <- unified_db$methods$causal_assumptions$identification
```

## Document Templates with the Unified Database

The package supports document templates that can be used to create
complete documents with placeholders for dynamic content:

``` r
# import unified database
unified_db <- boilerplate_import()

# add a custom conference abstract template
unified_db$template$conference_abstract <- "# {{title}}\n\n**Authors**: {{authors}}\n\n## Background\n{{background}}\n\n## Methods\n{{methods}}\n\n## Results\n{{results}}"

# save the updated unified database
boilerplate_save(unified_db)

# generate a document from template with variables
abstract_text <- boilerplate_generate_text(
  category = "template",
  sections = "conference_abstract",
  global_vars = list(
    title = "Effect of Political Orientation on Well-being",
    authors = "Smith, J., Jones, A.",
    background = "Previous research has shown mixed findings...",
    methods = "We used data from a longitudinal study (N=47,000)...",
    results = "We found significant positive effects..."
  ),
  db = unified_db
)

cat(abstract_text)
```

## Complete Workflow Example with the Unified Database

This example demonstrates combining multiple components to create a
complete methods section using the unified database approach:

``` r
# initialise all databases and import them
boilerplate_init(create_dirs = TRUE, confirm = TRUE)
unified_db <- boilerplate_import()

# add perfectionism measure to the unified database
unified_db$measures$perfectionism <- list(
  name = "perfectionism",
  description = "Perfectionism was measured using a 3-item scale assessing maladaptive perfectionism tendencies.",
  reference = "rice_short_2014",
  waves = "10-current",
  keywords = c("personality", "mental health"),
  items = list(
    "Doing my best never seems to be enough.",
    "My performance rarely measures up to my standards.",
    "I am hardly ever satisfied with my performance."
  )
)

# save the updated unified database
boilerplate_save(unified_db)

# define parameters
study_params <- list(
  exposure_var = "perfectionism",
  population = "university students",
  timeframe = "2020-2021",
  sampling_method = "convenience"
)

# generate methods text for participant selection
sample_text <- boilerplate_generate_text(
  category = "methods",
  sections = c("sample_selection"),
  global_vars = study_params,
  add_headings = TRUE,
  heading_level = "###",
  db = unified_db
)
cat(sample_text)

# generate measures text for exposure variable
exposure_text <- boilerplate_generate_measures(
  variable_heading = "Exposure Variable",
  variables = "perfectionism",
  heading_level = 3,
  subheading_level = 4,
  print_waves = TRUE, 
  db = unified_db
)

cat(exposure_text)
```

## Citation

To cite the boilerplate package in publications, please use:

Bulbulia, J. (2025). boilerplate: Tools for Managing and Generating
Standardised Text for Scientific Reports. R package version 1.0.4
<https://doi.org/10.5281/zenodo.13370825>

A BibTeX entry for LaTeX users:

``` bibtex
@software{bulbulia_boilerplate_2025,
  author       = {Bulbulia, Joseph},
  title        = {{boilerplate: Tools for Managing and Generating 
                   Standardised Text for Scientific Reports}},
  year         = 2025,
  publisher    = {Zenodo},
  version      = {1.0.45},
  doi          = {10.5281/zenodo.13370825},
  url          = {https://github.com/go-bayes/boilerplate}
}
```

## Licence

This package is licensed under the MIT Licence.

## Code

Go to: <https://github.com/go-bayes/boilerplate>

## DOI

[![DOI](https://zenodo.org/badge/846820825.svg)](https://zenodo.org/doi/10.5281/zenodo.13370825)
