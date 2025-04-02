#===================================================
# Boilerplate Package: Extended Workflow with Unified Database
#
# This script demonstrates a comprehensive workflow using
# the unified database approach in the boilerplate package.
#===================================================

# load required packages
library(tidyverse)  # for data manipulation
library(here)       # for file path management
library(boilerplate) # our package

#===================================================
# 1. initialisation and setup
#===================================================

# initialise all databases at once with default values
# note: this creates the directory structure and saves default databases
boilerplate_init(
  categories = c("measures", "methods", "results", "discussion", "appendix", "template"),
  create_dirs = TRUE,
  confirm = TRUE
)

# import all databases into a unified structure
unified_db <- boilerplate_import()

# examine the structure to see what we're working with
str(unified_db, max.level = 2)

#===================================================
# 2. basic unified database operations
#===================================================

# add a new method using direct list manipulation
unified_db$methods$sample_selection <- "Participants were selected from {{population}} during {{timeframe}}."

# add a nested entry using direct list manipulation
unified_db$methods$statistical$longitudinal$custom_method <- "We used a custom longitudinal approach with {{algorithm}} as implemented in the {{software}} package."

# save the entire unified database
boilerplate_save(unified_db)

# alternatively, import and work with just one category
methods_db <- boilerplate_import("methods")
methods_db$new_entry <- "This is a new entry."
boilerplate_save(methods_db, "methods")  # save just the methods database

#===================================================
# 3. path-based operations for nested structures
#===================================================

# import the unified database
unified_db <- boilerplate_import()

# add entries using path notation
unified_db <- boilerplate_add_entry(
  db = unified_db$methods,
  path = "statistical.heterogeneity.grf.custom",
  value = "We implemented a custom GRF approach with modified splitting criteria."
)

# the above applies to the methods component, update it in the unified db
unified_db$methods <- unified_db

# check if a specific path exists
path_exists <- boilerplate_path_exists(
  unified_db$methods,
  "statistical.heterogeneity.grf.custom"
)
print(paste("Path exists:", path_exists))

# retrieve an entry by path
custom_grf <- boilerplate_get_entry(
  unified_db$methods,
  "statistical.heterogeneity.grf.custom"
)
print(custom_grf)

# list all available paths in the methods database
method_paths <- boilerplate_list_paths(unified_db$methods)
head(method_paths, 10)  # show the first 10 paths

# sort the database recursively
unified_db$methods <- boilerplate_sort_db(unified_db$methods)

# save the updated unified database
boilerplate_save(unified_db)

#===================================================
# 4. measures database management
#===================================================

# add a new measure to the unified database
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

# add another measure
unified_db$measures$depression_phq9 <- list(
  name = "patient health questionnaire (PHQ-9)",
  description = "depression was measured using the PHQ-9, a 9-item instrument that measures the severity of depression.",
  reference = "kroenke2001",
  waves = "1-3",
  keywords = c("depression", "mental health", "phq"),
  items = list(
    "little interest or pleasure in doing things",
    "feeling down, depressed, or hopeless",
    "trouble falling or staying asleep"
  )
)

# save the unified database
boilerplate_save(unified_db)

#===================================================
# 5. basic text generation
#===================================================

# define study parameters for template variables
study_params <- list(
  exposure_var = "political_conservative",
  outcome_var = "social_wellbeing",
  population = "university students",
  timeframe = "2020-2021",
  n_total = 47000,
  baseline_wave = "NZAVS time 10, years 2018-2019",
  exposure_wave = "NZAVS time 11, years 2019-2020",
  outcome_wave = "NZAVS time 12, years 2020-2021",
  algorithm = "Super Learner",
  software = "R version 4.2.0"
)

# generate methods text
methods_text <- boilerplate_generate_text(
  category = "methods",
  sections = c("sample", "sample_selection", "statistical.longitudinal.custom_method"),
  global_vars = study_params,
  db = unified_db,  # pass the unified database
  add_headings = TRUE
)

# print the result
cat(methods_text)

#===================================================
# 6. audience-specific content
#===================================================

# add audience-specific versions of methods text
unified_db$methods$statistical_estimator$lmtp$technical_audience <-
  "We estimate causal effects using the Longitudinal Modified Treatment Policy (LMTP) estimator within a Targeted Minimum Loss-based Estimation (TMLE) framework. This semi-parametric estimator leverages the efficient influence function (EIF) to achieve double robustness and asymptotic efficiency."

unified_db$methods$statistical_estimator$lmtp$applied_audience <-
  "We estimate causal effects using the LMTP estimator. This approach combines machine learning with causal inference methods to estimate treatment effects while avoiding strict parametric assumptions."

unified_db$methods$statistical_estimator$lmtp$general_audience <-
  "We used advanced statistical methods that account for multiple factors that might influence both {{exposure_var}} and {{outcome_var}}. This method helps us distinguish between mere association and actual causal effects."

# save the unified database
boilerplate_save(unified_db)

# function to generate methods text for different audiences
generate_methods_by_audience <- function(audience = c("technical", "applied", "general"),
                                         study_params,
                                         db) {
  audience <- match.arg(audience)

  # select appropriate path based on audience
  lmtp_path <- paste0("statistical_estimator.lmtp.", audience, "_audience")

  # generate text
  boilerplate_generate_text(
    category = "methods",
    sections = c("sample", lmtp_path),
    global_vars = study_params,
    db = db,
    add_headings = TRUE
  )
}

# generate reports for different audiences
technical_report <- generate_methods_by_audience("technical", study_params, unified_db)
applied_report <- generate_methods_by_audience("applied", study_params, unified_db)
general_report <- generate_methods_by_audience("general", study_params, unified_db)

# print the general audience report
cat("General audience report:\n\n", general_report)

#===================================================
# 7. measures text generation
#===================================================

# generate text for exposure variable
exposure_text <- boilerplate_generate_measures(
  variable_heading = "Exposure Variable",
  variables = "anxiety_gad7",
  db = unified_db,  # pass the unified database
  heading_level = 3,
  subheading_level = 4,
  print_waves = TRUE
)

# print the result
cat(exposure_text)

# generate text for outcome variables
outcome_text <- boilerplate_generate_measures(
  variable_heading = "Outcome Variables",
  variables = c("depression_phq9"),
  db = unified_db,
  heading_level = 3,
  subheading_level = 4,
  print_waves = TRUE,
  print_keywords = TRUE,
  appendices_measures = "Appendix A"
)

# print the result
cat(outcome_text)

#===================================================
# 8. document templates
#===================================================

# add a journal article template to the unified database
unified_db$template$journal_article <- "---
title: \"{{title}}\"
author: \"{{authors}}\"
date: \"{{date}}\"
format:
  docx:
    reference-doc: journal_template.docx
bibliography: references.bib
---

# Abstract

{{abstract}}

# Introduction

{{introduction}}

# Methods

## Sample
{{methods_sample}}

## Measures
{{methods_measures}}

## Statistical Approach
{{methods_statistical}}

# Results

{{results}}

# Discussion

{{discussion}}

# References
"

# add a conference abstract template
unified_db$template$conference_abstract <- "# {{title}}

**Authors**: {{authors}}

## Background
{{background}}

## Methods
{{methods}}

## Results
{{results}}

## Conclusion
{{conclusion}}
"

# save the updated unified database
boilerplate_save(unified_db)

# function to generate a complete document from a template
generate_document <- function(template_name, study_params, section_contents, db) {
  # get the template
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

# prepare content for journal article
section_contents <- list(
  title = "Political Orientation and Social Wellbeing in New Zealand",
  authors = "Jane Smith, John Doe, and Robert Johnson",
  date = format(Sys.Date(), "%B %d, %Y"),
  abstract = "This study investigates the causal relationship between political orientation and social wellbeing using data from the New Zealand Attitudes and Values Study.",
  introduction = "Understanding the relationship between political beliefs and wellbeing has important implications for social policy and public health...",
  methods_sample = methods_text,
  methods_measures = paste(exposure_text, outcome_text, sep="\n\n"),
  methods_statistical = applied_report,
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

# print a preview
cat(substr(journal_article, 1, 1000), "...\n")

# prepare content for conference abstract
abstract_contents <- list(
  title = "Effect of Political Orientation on Well-being",
  authors = "Smith, J., Jones, A.",
  background = "Previous research has shown mixed findings on the relationship between political orientation and well-being...",
  methods = "We used data from a longitudinal study (N=47,000) and applied causal inference methods to estimate effects...",
  results = "We found significant positive effects of political conservatism on certain domains of well-being...",
  conclusion = "Our findings suggest that political orientation may influence well-being through several pathways..."
)

# generate the abstract
conference_abstract <- generate_document(
  template_name = "conference_abstract",
  study_params = study_params,
  section_contents = abstract_contents,
  db = unified_db
)

# print the abstract
cat(conference_abstract)

#===================================================
# 9. complete research workflow example
#===================================================

# define study parameters
research_params <- list(
  exposure_var = "perfectionism",
  outcome_var = "wellbeing",
  population = "general adult population",
  timeframe = "2018-2021",
  n_total = 47000,
  baseline_wave = "Time 1 (2018)",
  exposure_wave = "Time 2 (2019)",
  outcome_wave = "Time 3 (2021)",
  algorithm = "Generalized Random Forests",
  software = "R package 'grf'",
  flipped_outcomes = c("anxiety", "depression", "stress"),
  baseline_missing_data_proportion = 0.15
)

# add study-specific content to the unified database

# add a custom sample description
unified_db$methods$sample$nzavs <- "Participants were drawn from the New Zealand Attitudes and Values Study (NZAVS), a longitudinal panel study of social attitudes, personality, and health outcomes in New Zealand. The NZAVS began in 2009 and includes over {{n_total}} participants. Data were collected during {{timeframe}}."

# add a missing data handling method
unified_db$methods$missing_data$grf <- "To mitigate bias from missing data, we employed predictive mean matching from the mice package to impute missing baseline values (comprising {{baseline_missing_data_proportion}}% of the baseline data). For each column with missing values, we created a binary indicator of missingness so that the machine learning algorithms could condition on missingness information during estimation."

# add a custom statistical approach
unified_db$methods$statistical_approach$heterogeneity <- "We estimated heterogeneous treatment effects with Generalized Random Forests (GRF), which extends random forests for causal inference by focusing on conditional average treatment effects (CATE). GRF handles complex interactions and non-linearities without explicit model specification, and provides 'honest' estimates by splitting data between model-fitting and inference."

# save the updated unified database
boilerplate_save(unified_db)

# generate sample section
sample_text <- boilerplate_generate_text(
  category = "methods",
  sections = "sample.nzavs",
  global_vars = research_params,
  db = unified_db,
  add_headings = TRUE,
  heading_level = "##"
)

# generate missing data section
missing_data_text <- boilerplate_generate_text(
  category = "methods",
  sections = "missing_data.grf",
  global_vars = research_params,
  db = unified_db,
  add_headings = TRUE,
  heading_level = "##"
)

# generate statistical approach section
statistical_text <- boilerplate_generate_text(
  category = "methods",
  sections = "statistical_approach.heterogeneity",
  global_vars = research_params,
  db = unified_db,
  add_headings = TRUE,
  heading_level = "##"
)

# combine all sections into a complete methods section
methods_section <- paste(
  "# Methods\n\n",
  sample_text, "\n\n",
  missing_data_text, "\n\n",
  statistical_text, "\n\n",
  "## Measures\n\n",
  exposure_text, "\n\n",
  outcome_text,
  sep = ""
)

# print the complete methods section
cat(methods_section)

#===================================================
# 10. backward compatibility example
#===================================================

# the old functions still work with deprecation warnings
measures_db_old <- boilerplate_manage_measures(action = "list")
methods_db_old <- boilerplate_manage_text(action = "list", category = "methods")

# add a new method using the old approach
updated_methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  name = "backward_compatible_entry",
  value = "This entry was added using the backward-compatible API."
)

# verify it was added
cat(updated_methods_db$backward_compatible_entry)

# the new functions work with both old and new databases
backward_text <- boilerplate_generate_text(
  category = "methods",
  sections = "backward_compatible_entry",
  db = updated_methods_db
)

cat(backward_text)

#===================================================
# 11. export methods to a standalone document
#===================================================

# write the methods section to a Quarto markdown file
writeLines(methods_section, "methods_for_publication.qmd")

# in a Quarto document, you can include this section with:
# ```{r, echo=FALSE, results='asis'}
# cat(readLines("methods_for_publication.qmd"), sep = "\n")
# ```

print("Methods section has been saved to 'methods_for_publication.qmd'")

# show final message
cat("\nBoilerplate workflow complete. The unified database approach simplifies management\n",
    "of text templates while maintaining all the powerful features of the original package.\n")




#===================================================
# Example Merge Usage Scenarios
#===================================================

# Example 1: Merging entire unified databases
merge_entire_example <- function() {
  # Import two unified databases
  db1 <- boilerplate_import()
  db2 <- boilerplate_import(data_path = "path/to/collaborator/data")

  # Merge all common categories
  merged_db <- boilerplate_merge_unified(
    db1 = db1,
    db2 = db2,
    db1_name = "Our Project",
    db2_name = "Collaborator Project"
  )

  # Save the merged database
  boilerplate_save(merged_db)
}

# Example 2: Merging just measures between projects
merge_measures_example <- function() {
  # Import two unified databases
  db1 <- boilerplate_import()
  db2 <- boilerplate_import(data_path = "path/to/measures/repository")

  # Merge just the measures category
  db1 <- boilerplate_merge_category(
    db1 = db1,
    db2 = db2,
    category = "measures",
    db1_name = "Current Project",
    db2_name = "Measures Repository"
  )

  # Save the updated database
  boilerplate_save(db1)
}

# Example 3: Updating from an external source
update_from_external_example <- function() {
  # Import current unified database
  unified_db <- boilerplate_import()

  # Update methods from the central repository
  unified_db <- boilerplate_update_from_external(
    unified_db = unified_db,
    category = "methods",
    external_path = "path/to/central/methods/repository"
  )

  # Save the updated database
  boilerplate_save(unified_db)
}
