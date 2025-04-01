
<!-- readme.md is generated from readme.rmd. please edit that file -->

## Overview

The `boilerplate` package provides tools for managing and generating
standardised text for methods and results sections of scientific
reports. It handles template variable substitution and supports
hierarchical organisation of text through dot-separated paths.

## Features

- **Text Template Management**: Create, update, and retrieve reusable
  text templates
- **Variable Substitution**: Replace `{{variable}}` placeholders with
  actual values
- **Hierarchical Organisation**: Organise text in nested categories
  using dot notation (e.g., `statistical.longitudinal.lmtp`)
- **Measures Database**: Special handling for research measures with
  descriptions, items, and metadata
- **Document Templates**: Streamlined creation of journal articles,
  conference presentations, and grant proposals
- **Multiple Categories**: Support for methods, results, discussion,
  measures, appendices and document templates
- **Default Content**: Comes with pre-loaded defaults for common methods
  sections
- **Quarto/R Markdown Integration**: Generate sections for scientific
  reports
- **Safety Features**: Prevention of accidental file overwrites and
  clear separation of text and measures databases

## Safety Features

The `boilerplate` package includes several safety features to prevent
accidental overwrites:

- When using `boilerplate_manage_measures()` or
  `boilerplate_manage_text()` with `action="save"`, you must explicitly
  provide both `db` and `file_name` parameters
- Text and measures databases are initialized separately using
  `boilerplate_init_text()` and `boilerplate_init_measures()`
  respectively
- All functions that modify files include confirmation prompts (when
  `confirm=TRUE`) before making changes
- Consistent sorting of database entries ensures predictable structure
  and easier version control

## Installation

You can install the development version of `boilerplate` from GitHub
with:

``` r
# install the devtools package if you don't have it already
install.packages("devtools")
devtools::install_github("go-bayes/boilerplate")
```

## Basic Usage

``` r
# install from GitHub if not already installed
if (!require(boilerplate, quietly = TRUE)) {
  # install devtools if necessary
  if (!require(devtools, quietly = TRUE)) {
    install.packages("devtools")
  }
  devtools::install_github("go-bayes/boilerplate")
}

# initialise the default text databases (excluding measures)
boilerplate_init_text(create_dirs = TRUE, confirm = TRUE)

# initialise the measures database separately
boilerplate_init_measures(create_dirs = TRUE, confirm = TRUE)

# add a new method entry
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  name = "sample_selection",
  value = "Participants were selected from {{population}} during {{timeframe}}."
)

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

## Managing Measures

The package provides functions for managing measures and generating
formatted text about them:

``` r
# First initialise the measures database separately from text databases
boilerplate_init_measures(create_dirs = TRUE, confirm = TRUE)

# Then load the database
measures_db <- boilerplate_manage_measures(action = "list")

# Add a measure with a flat name (no dots)
measures_db <- boilerplate_manage_measures(
  action = "add",
  name = "anxiety_gad7", # use underscore instead of dot
  measure = list(
    description = "Anxiety was measured using the GAD-7 scale.",
    reference = "spitzer2006",
    waves = "1-3",
    keywords = c("anxiety", "mental health", "gad"),
    items = list(
      "Feeling nervous, anxious, or on edge",
      "Not being able to stop or control worrying",
      "Worrying too much about different things",
      "Trouble relaxing"
    )
  ),
  db = measures_db
)

# Save the measures database with an explicit file name (required for save action)
boilerplate_manage_measures(
  action = "save",
  db = measures_db,
  file_name = "measures_db.rds"  # explicit file name required for save action
)

# Then reference it with the same flat name
exposure_text <- boilerplate_generate_measures(
  variable_heading = "Exposure Variable",
  variables = "anxiety_gad7", # match the name you used above
  db = measures_db,
  heading_level = 3,
  subheading_level = 4,
  print_waves = TRUE
)

cat(exposure_text)

# Generate text for outcome variables by domain
psych_text <- boilerplate_generate_measures(
  variable_heading = "Psychological Outcomes",
  variables = c("anxiety.gad7", "depression.phq9"),
  db = measures_db,
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
  db = methods_db
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
# save the methods section to a file that can be included in a quarto document
# writeLines(methods_section, "methods_section.qmd")
```

## Appendix Content

The package now supports appendix content that can be managed separately
from the main document:

``` r
# initialise appendix database
boilerplate_init_text(
  categories = "appendix",
  create_dirs = TRUE, 
  confirm = TRUE
)

# load appendix database
appendix_db <- boilerplate_manage_text(
  category = "appendix", 
  action = "list"
)

# add detailed measures documentation to appendix
appendix_db <- boilerplate_manage_text(
  category = "appendix",
  action = "add",
  name = "detailed_measures",
  value = "# Detailed Measures Documentation\n\n## Overview\n\nThis appendix provides comprehensive documentation for all measures used in this study, including full item text, response options, and psychometric properties.\n\n## {{exposure_var}} Measure\n\n{{exposure_details}}\n\n## Outcome Measures\n\n{{outcome_details}}",
  db = appendix_db
)

# save appendix database with explicit file name
boilerplate_manage_text(
  category = "appendix",
  action = "save",
  db = appendix_db,
  file_name = "appendix_db.rds"  # explicit file name required for save action
)

# generate appendix text with variable substitution
appendix_text <- boilerplate_generate_text(
  category = "appendix",
  sections = c("detailed_measures"),
  global_vars = list(
    exposure_var = "Perfectionism",
    exposure_details = "The perfectionism measure consists of 3 items...",
    outcome_details = "Anxiety was measured using the GAD-7 scale..."
  ),
  db = appendix_db
)

cat(appendix_text)
```

## Creating Complete Document Workflows

You can create complete workflows that integrate methods, results, and
templates:

``` r
# load template database
template_db <- boilerplate_manage_text(
  category = "template", 
  action = "list"
)

# function to generate a complete document from a template
generate_document <- function(template_name, study_params, section_contents) {
  # get the template
  template_text <- boilerplate_manage_text(
    category = "template",
    action = "get",
    name = template_name
  )
  
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
  section_contents = section_contents
)

cat(substr(journal_article, 1, 500), "...")
```

## Advanced Usage: Audience-Specific Reports

You can create tailored reports for different audiences from the same
underlying data:

``` r
# define audience-specific methods databases
methods_db <- boilerplate_manage_text(category = "methods", action = "list")

# add audience-specific LMTP descriptions
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  name = "statistical_estimator.lmtp.technical_audience",
  value = "We estimate causal effects using the Longitudinal Modified Treatment Policy (LMTP) estimator within a Targeted Minimum Loss-based Estimation (TMLE) framework. This semi-parametric estimator leverages the efficient influence function (EIF) to achieve double robustness and asymptotic efficiency.",
  db = methods_db
)

methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  name = "statistical_estimator.lmtp.applied_audience",
  value = "We estimate causal effects using the LMTP estimator. This approach combines machine learning with causal inference methods to estimate treatment effects while avoiding strict parametric assumptions.",
  db = methods_db
)

methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  name = "statistical_estimator.lmtp.general_audience",
  value = "We used advanced statistical methods that account for multiple factors that might influence both {{exposure_var}} and {{outcome_var}}. This method helps us distinguish between mere association and actual causal effects.",
  db = methods_db
)

# save methods database with explicit file name
boilerplate_manage_text(
  category = "methods",
  action = "save",
  db = methods_db,
  file_name = "methods_db.rds"  # explicit file name required for save action
)

# function to generate methods text for different audiences
generate_methods_by_audience <- function(audience = c("technical", "applied", "general")) {
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
    db = methods_db
  )
}

# generate reports for different audiences
technical_report <- generate_methods_by_audience("technical")
applied_report <- generate_methods_by_audience("applied")
general_report <- generate_methods_by_audience("general")

cat("General audience report:\n\n", general_report)
```

## Text and Measure Management

The core functions for managing text and measures are:

``` r
# add text to a database
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  name = "data_analysis",
  value = "Data were analysed using {{software}} version {{version}}.",
  db = methods_db
)

# get text with variables substituted
analysis_text <- boilerplate_manage_text(
  category = "methods",
  action = "get",
  name = "data_analysis",
  template_vars = list(software = "R", version = "4.2.0"),
  db = methods_db
)

# add a measure to a database
measures_db <- boilerplate_manage_measures(
  action = "add",
  name = "wellbeing",
  measure = list(
    description = "Wellbeing was measured using a 5-item scale.",
    reference = "smith2020",
    items = list("I am satisfied with my life", "My life has meaning"),
    keywords = c("wellbeing", "satisfaction")
  ),
  db = measures_db
)

# save measures explicitly
boilerplate_manage_measures(
  action = "save",
  db = measures_db,
  file_name = "wellbeing_measures.rds"  # explicit file name required
)

str(measures_db$wellbeing)
```

## Document Templates

The package now supports document templates that can be used to create
complete documents with placeholders for dynamic content:

``` r
# list available templates
template_db <- boilerplate_manage_text(
  category = "template", 
  action = "list"
)
names(template_db)

# add a custom conference abstract template
template_db <- boilerplate_manage_text(
  category = "template",
  action = "add",
  name = "conference_abstract",
  value = "# {{title}}\n\n**Authors**: {{authors}}\n\n## Background\n{{background}}\n\n## Methods\n{{methods}}\n\n## Results\n{{results}}"
)

# save template database with explicit file name
boilerplate_manage_text(
  category = "template",
  action = "save",
  db = template_db,
  file_name = "template_db.rds"  # explicit file name required
)

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
  )
)

cat(abstract_text)
```

## Audience-Specific Methods Descriptions

You can create and manage audience-specific descriptions for different
contexts:

``` r
# load methods database
methods_db <- boilerplate_manage_text(category = "methods", action = "list")

# add statistical descriptions for different audiences
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  name = "statistical_estimator.lmtp.technical_audience",
  value = "We estimate causal effects using the Longitudinal Modified Treatment Policy (LMTP) estimator within a Targeted Minimum Loss-based Estimation (TMLE) framework [@van2014targeted; @van2012targeted]. This semi-parametric estimator leverages the efficient influence function (EIF) to achieve double robustness and asymptotic efficiency.",
  db = methods_db
)

methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  name = "statistical_estimator.lmtp.general_audience",
  value = "We used advanced statistical methods that account for multiple factors that might influence both {{exposure_var}} and {{outcome_var}}. Our approach uses recent developments in causal inference that provide more reliable estimates than traditional statistical methods.",
  db = methods_db
)

# save methods database with explicit file name
boilerplate_manage_text(
  category = "methods",
  action = "save",
  db = methods_db,
  file_name = "audience_methods_db.rds"  # explicit file name required
)

# function to generate methods text for different audiences
generate_methods_by_audience <- function(audience = c("technical", "general")) {
  audience <- match.arg(audience)
  
  # select appropriate path based on audience
  if (audience == "technical") {
    lmtp_path <- "statistical_estimator.lmtp.technical_audience"
  } else {
    lmtp_path <- "statistical_estimator.lmtp.general_audience"
  }
  
  # generate text
  boilerplate_generate_text(
    category = "methods",
    sections = c("sample", lmtp_path),
    global_vars = list(
      exposure_var = "political_conservative",
      outcome_var = "social_wellbeing"
    )
  )
}

# generate reports for different audiences
technical_report <- generate_methods_by_audience("technical")
general_report <- generate_methods_by_audience("general")

cat(general_report)
```

## Complete Workflow Example

This example demonstrates combining multiple components to create a
complete methods section:

``` r
# initialise databases and define study parameters
boilerplate_init_measures(create_dirs = TRUE, confirm = TRUE)

measures_db <- boilerplate_manage_measures(action = "list")

# load the measures database
measures_db <- boilerplate_manage_measures(action = "list")

# add perfectionism measure
measures_db <- boilerplate_manage_measures(
  action = "add",
  name = "perfectionism",
  measure = list(
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
  ),
  db = measures_db
)

# save the updated database with explicit file name
boilerplate_manage_measures(
  action = "save",
  db = measures_db,
  file_name = "perfectionism_measures.rds"  # explicit file name required
)

# define parameters
study_params <- list(
  exposure_var = "perfectionism",
  population = "university students",
  timeframe = "2020-2021",
  sampling_method = "convenience"
)

# generate methods text for participant selection
sample_text <- boilerplate_generate_text(
  sections = c("sample_selection"),
  global_vars = study_params,
  add_headings = TRUE,
  heading_level = "###",
  db = methods_db
)
cat(sample_text)

# generate measures text for exposure variable
exposure_text <- boilerplate_generate_measures(
  variable_heading = "Exposure Variable",
  variables = "perfectionism",
  heading_level = 3,
  subheading_level = 4,
  print_waves = TRUE, 
  db = measures_db)

cat(exposure_text)
```

## Citation

To cite the boilerplate package in publications, please use:

Bulbulia, J. (2025). boilerplate: Tools for Managing and Generating
Standardised Text for Scientific Reports. R package version 0.3.0.
<https://doi.org/10.5281/zenodo.13370825>

A BibTeX entry for LaTeX users:

``` bibtex
@software{bulbulia_boilerplate_2025,
  author       = {Bulbulia, Joseph},
  title        = {{boilerplate: Tools for Managing and Generating 
                   Standardised Text for Scientific Reports}},
  year         = 2025,
  publisher    = {Zenodo},
  version      = {0.3.0},
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
\`\`\`
