#' ---
#' title: "Boilerplate Package Unified Database Workflow Examples"
#' author: "Your Name"
#' date: "`r Sys.Date()`"
#' output: html_document
#' ---

#' ## Setup
library(boilerplate)

# First, initialise all databases with default values
# This creates the directory structure and default databases
boilerplate_init(
  categories = c("measures", "methods", "results", "discussion", "appendix", "template"),
  create_dirs = TRUE
)

#' ## Working with the Unified Database
# Import all databases at once into a unified structure
unified_db <- boilerplate_import()

# Examine the structure
str(unified_db, max.level = 2)

# Access specific categories using helper functions
methods_db <- boilerplate_methods(unified_db)
measures_db <- boilerplate_measures(unified_db)
results_db <- boilerplate_results(unified_db)

# Access specific items using dot notation
lmtp_method <- boilerplate_methods(unified_db, "statistical.longitudinal.lmtp")
cat(lmtp_method)

#' ## Generating Text with the Unified Database
# Generate methods text
methods_text <- boilerplate_generate_text(
  category = "methods",
  sections = c("sample", "statistical.longitudinal.lmtp"),
  global_vars = list(
    exposure_var = "political_conservative",
    population = "university students",
    timeframe = "2020-2022"
  ),
  db = unified_db,  # Pass the unified database
  add_headings = TRUE
)

# Print the result
cat(methods_text)

# Generate measures text
measures_text <- boilerplate_generate_measures(
  variable_heading = "Outcome Variables",
  variables = c("anxiety_gad7", "depression_phq9"),
  db = unified_db,  # Pass the unified database
  print_waves = TRUE,
  print_keywords = TRUE
)

# Print the result
cat(measures_text)

#' ## Modifying and Saving the Unified Database
# Add a new method
unified_db$methods$statistical$mediation <- "We tested mediation using the approach of {{mediation_approach}} with bootstrapped confidence intervals."

# Add a new measure
unified_db$measures$wellbeing <- list(
  name = "wellbeing scale",
  description = "wellbeing was measured using the WEMWBS scale.",
  reference = "tennant2007",
  waves = "1-3",
  keywords = c("wellbeing", "mental health"),
  items = list(
    "I've been feeling optimistic about the future",
    "I've been feeling useful",
    "I've been feeling relaxed"
  )
)

# Save the updated unified database
boilerplate_save(unified_db)

#' ## Working with Individual Databases
# Import just the methods database
methods_db <- boilerplate_import("methods")

# Modify the methods database
methods_db$new_section <- "This is a new method section."
methods_db$statistical$heterogeneity$new_approach <- "We used a novel approach to heterogeneity detection."

# Save just the methods database
boilerplate_save(methods_db, "methods")

# Generate text using just the methods database
methods_text <- boilerplate_generate_text(
  category = "methods",
  sections = c("new_section", "statistical.heterogeneity.new_approach"),
  db = methods_db,
  add_headings = TRUE
)

# Print the result
cat(methods_text)

#' ## Using Template Variables
# Generate report text with variable substitution
report_text <- boilerplate_generate_text(
  category = "template",
  sections = "journal_article",
  global_vars = list(
    title = "Effect of Political Conservatism on Mental Health Outcomes",
    authors = "Smith, J. & Jones, K.",
    date = "2025-04-01",
    abstract = "This study examines the relationship between political orientation and mental health.",
    introduction = "Political polarization has increased in recent years...",
    methods_sample = "We recruited 500 participants from a national panel.",
    methods_measures = "We used validated scales for all measures.",
    methods_statistical = "We used causal inference techniques.",
    results = "We found significant effects.",
    discussion = "Our findings have important implications."
  ),
  db = unified_db
)

# Print the result
cat(report_text)

#' ## Backward Compatibility
# The old functions still work for backward compatibility
measures_db_old <- boilerplate_manage_measures(action = "list")
methods_db_old <- boilerplate_manage_text(action = "list", category = "methods")

# But you'll see deprecation warnings
# It's recommended to use the new functions instead

#' ## Advanced: Adding Complex Nested Structures
# Let's add a complex nested structure to the methods database
methods_db <- boilerplate_import("methods")

# Add a nested structure for machine learning methods
methods_db$ml <- list(
  default = "We used machine learning techniques for prediction.",
  random_forest = list(
    default = "Random forests were used for classification.",
    standard = "We used the standard implementation of random forests.",
    custom = "We used a custom implementation of random forests with modified parameters."
  ),
  neural_network = list(
    default = "Neural networks were used for classification.",
    cnn = "We used convolutional neural networks for image classification.",
    rnn = "We used recurrent neural networks for sequence prediction."
  ),
  gradient_boosting = "We used gradient boosting machines for regression."
)

# Save the updated methods database
boilerplate_save(methods_db, "methods")

# Generate text from the nested structure
ml_text <- boilerplate_generate_text(
  category = "methods",
  sections = c(
    "ml",
    "ml.random_forest",
    "ml.random_forest.custom",
    "ml.neural_network.cnn",
    "ml.gradient_boosting"
  ),
  db = methods_db,
  add_headings = TRUE
)

# Print the result
cat(ml_text)

#' ## Advanced: Domain-Specific Helper Functions
# For complex workflows, you might want to create domain-specific helper functions

#' Create a standard methods section for a causal analysis paper
#'
#' @param unified_db List. The unified database
#' @param exposure Character. The exposure variable
#' @param outcome Character. The outcome variable
#' @param population Character. The study population
#' @param timeframe Character. The study timeframe
#' @return Character. The generated methods text
create_causal_methods_section <- function(
    unified_db,
    exposure,
    outcome,
    population,
    timeframe
) {
  # Define the sections we need
  sections <- c(
    "sample",
    "causal_assumptions.identification",
    "causal_assumptions.confounding_control",
    "statistical.longitudinal.lmtp"
  )

  # Generate text with all the variables
  methods_text <- boilerplate_generate_text(
    category = "methods",
    sections = sections,
    global_vars = list(
      exposure_var = exposure,
      outcome_var = outcome,
      population = population,
      timeframe = timeframe
    ),
    db = unified_db,
    add_headings = TRUE,
    heading_level = "###"
  )

  return(methods_text)
}

# Use the helper function
methods_section <- create_causal_methods_section(
  unified_db = unified_db,
  exposure = "treatment_exposure",
  outcome = "mental_health_outcome",
  population = "adult community sample",
  timeframe = "2020-2023"
)

# Print the result
cat(methods_section)
