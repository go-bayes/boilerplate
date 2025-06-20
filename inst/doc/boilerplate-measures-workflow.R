## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## ----setup--------------------------------------------------------------------
# library(boilerplate)

## -----------------------------------------------------------------------------
# # Initialise and import the database
# boilerplate_init(create_dirs = TRUE, confirm = FALSE)
# unified_db <- boilerplate_import()
# 
# # Add a measure directly to the unified database
# # IMPORTANT: Measures must be at the top level, not nested in categories
# unified_db$measures$anxiety_gad7 <- list(
#   name = "generalised anxiety disorder scale (GAD-7)",
#   description = "anxiety was measured using the GAD-7 scale.",
#   reference = "spitzer2006",
#   waves = "1-3",
#   keywords = c("anxiety", "mental health", "gad"),
#   items = list(
#     "feeling nervous, anxious, or on edge",
#     "not being able to stop or control worrying",
#     "worrying too much about different things",
#     "trouble relaxing",
#     "being so restless that it is hard to sit still",
#     "becoming easily annoyed or irritable",
#     "feeling afraid, as if something awful might happen"
#   )
# )
# 
# # Save the database
# boilerplate_save(unified_db)
# 
# # Generate formatted text about the measure
# measures_text <- boilerplate_generate_measures(
#   variable_heading = "Anxiety Measure",
#   variables = "anxiety_gad7",
#   db = unified_db,
#   heading_level = 3,
#   print_waves = TRUE
# )
# 
# cat(measures_text)

## -----------------------------------------------------------------------------
# # DON'T DO THIS - measures should not be nested under categories
# unified_db$measures$psychological$anxiety <- list(...)  # WRONG

## -----------------------------------------------------------------------------
# # DO THIS - add measures directly at the top level
# unified_db$measures$anxiety_gad7 <- list(...)  # CORRECT
# unified_db$measures$depression_phq9 <- list(...)  # CORRECT

## -----------------------------------------------------------------------------
# # Add several psychological measures
# unified_db$measures$depression_phq9 <- list(
#   name = "patient health questionnaire-9 (PHQ-9)",
#   description = "depression symptoms were assessed using the PHQ-9.",
#   type = "ordinal",
#   reference = "kroenke2001",
#   waves = "1-3",
#   items = list(
#     "little interest or pleasure in doing things",
#     "feeling down, depressed, or hopeless",
#     "trouble falling or staying asleep, or sleeping too much",
#     "feeling tired or having little energy",
#     "poor appetite or overeating",
#     "feeling bad about yourself — or that you are a failure",
#     "trouble concentrating on things",
#     "moving or speaking slowly, or being fidgety or restless",
#     "thoughts that you would be better off dead"
#   ),
#   values = c(0, 1, 2, 3),
#   value_labels = c("not at all", "several days",
#                    "more than half the days", "nearly every day")
# )
# 
# unified_db$measures$self_esteem <- list(
#   name = "rosenberg self-esteem scale",
#   description = "self-esteem was measured using a 3-item version of the Rosenberg scale.",
#   type = "continuous",
#   reference = "rosenberg1965",
#   waves = "5-current",
#   range = c(1, 7),
#   items = list(
#     "On the whole, I am satisfied with myself.",
#     "I take a positive attitude toward myself.",
#     "I feel that I am a person of worth, at least on an equal plane with others."
#   )
# )
# 
# # Save all changes
# boilerplate_save(unified_db)

## -----------------------------------------------------------------------------
# # View all measures
# names(unified_db$measures)
# 
# # Access a specific measure
# unified_db$measures$anxiety
# 
# # Add or update measures using boilerplate_add_entry() or boilerplate_update_entry()

## -----------------------------------------------------------------------------
# # Check quality before standardisation
# boilerplate_measures_report(unified_db$measures)
# 
# # Standardise all measures
# unified_db$measures <- boilerplate_standardise_measures(
#   unified_db$measures,
#   extract_scale = TRUE,      # Extract scale info from descriptions
#   identify_reversed = TRUE,   # Identify reversed items
#   clean_descriptions = TRUE,  # Clean up description text
#   verbose = TRUE             # Show progress
# )
# 
# # Check quality after standardisation
# boilerplate_measures_report(unified_db$measures)
# 
# # Save the standardised database
# boilerplate_save(unified_db)

## -----------------------------------------------------------------------------
# # Messy measure entry
# unified_db$measures$perfectionism <- list(
#   name = "perfectionism scale",
#   description = "Perfectionism (1 = Strongly Disagree, 7 = Strongly Agree). Higher scores indicate greater perfectionism.",
#   items = list(
#     "Doing my best never seems to be enough.",
#     "My performance rarely measures up to my standards.",
#     "I am hardly ever satisfied with my performance. (r)"
#   )
# )

## -----------------------------------------------------------------------------
# # Clean, standardised entry
# # The standardisation process will:
# # - Extract scale: "1 = Strongly Disagree, 7 = Strongly Agree"
# # - Clean description: "Perfectionism. Higher scores indicate greater perfectionism."
# # - Identify reversed items: item 3 marked as reversed
# # - Add missing fields: type, scale_info, scale_anchors, reversed_items

## -----------------------------------------------------------------------------
# # Get a quality overview
# boilerplate_measures_report(unified_db$measures)
# 
# # Output shows:
# # - Total measures
# # - Completeness percentages
# # - Missing information
# # - Standardisation status

## -----------------------------------------------------------------------------
# # Get detailed report as data frame
# quality_report <- boilerplate_measures_report(
#   unified_db$measures,
#   return_report = TRUE
# )
# 
# # Find measures missing critical information
# missing_refs <- quality_report[!quality_report$has_reference, ]
# missing_items <- quality_report[!quality_report$has_items, ]
# 
# # View specific issues
# cat("Measures without references:", missing_refs$measure_name, sep = "\n")
# cat("\nMeasures without items:", missing_items$measure_name, sep = "\n")

## -----------------------------------------------------------------------------
# # Find measures with specific characters in references
# problematic_refs <- boilerplate_find_chars(
#   db = unified_db,
#   field = "reference",
#   chars = c("@", "[", "]", " "),
#   category = "measures"
# )
# 
# print(problematic_refs)

## -----------------------------------------------------------------------------
# # Clean reference formatting
# unified_db <- boilerplate_batch_clean(
#   db = unified_db,
#   field = "reference",
#   remove_chars = c("@", "[", "]"),
#   replace_pairs = list(" " = "_"),
#   trim_whitespace = TRUE,
#   category = "measures",
#   preview = TRUE  # Preview first
# )
# 
# # If preview looks good, run without preview
# unified_db <- boilerplate_batch_clean(
#   db = unified_db,
#   field = "reference",
#   remove_chars = c("@", "[", "]"),
#   replace_pairs = list(" " = "_"),
#   trim_whitespace = TRUE,
#   category = "measures"
# )

## -----------------------------------------------------------------------------
# # Update references for multiple measures
# unified_db <- boilerplate_batch_edit(
#   db = unified_db,
#   field = "reference",
#   new_value = "sibley2024",
#   target_entries = c("political_orientation", "social_dominance"),
#   category = "measures",
#   preview = TRUE
# )
# 
# # Update wave information using wildcards
# unified_db <- boilerplate_batch_edit(
#   db = unified_db,
#   field = "waves",
#   new_value = "1-16",
#   target_entries = "political_*",  # All political measures
#   category = "measures"
# )
# 
# # Update based on current values
# unified_db <- boilerplate_batch_edit(
#   db = unified_db,
#   field = "waves",
#   new_value = "1-current",
#   match_values = c("1-15", "1-16"),  # Update these specific values
#   category = "measures"
# )

## -----------------------------------------------------------------------------
# # Generate text for a single measure
# exposure_text <- boilerplate_generate_measures(
#   variable_heading = "Exposure Variable",
#   variables = "perfectionism",
#   db = unified_db,
#   heading_level = 3,
#   subheading_level = 4,
#   print_waves = TRUE
# )
# 
# cat(exposure_text)

## -----------------------------------------------------------------------------
# # Generate text for multiple measures grouped by type
# psychological_measures <- boilerplate_generate_measures(
#   variable_heading = "Psychological Measures",
#   variables = c("anxiety_gad7", "depression_phq9", "self_esteem"),
#   db = unified_db,
#   heading_level = 3,
#   subheading_level = 4,
#   print_waves = TRUE,
#   sample_items = 3  # Show only first 3 items
# )
# 
# demographic_measures <- boilerplate_generate_measures(
#   variable_heading = "Demographic Variables",
#   variables = c("age", "gender", "education"),
#   db = unified_db,
#   heading_level = 3,
#   subheading_level = 4,
#   print_waves = FALSE  # Don't show waves for demographics
# )
# 
# # Combine into methods section
# methods_measures <- paste(
#   "## Measures\n\n",
#   psychological_measures, "\n\n",
#   demographic_measures,
#   sep = ""
# )

## -----------------------------------------------------------------------------
# # Table format for enhanced presentation
# measures_table <- boilerplate_generate_measures(
#   variable_heading = "Study Measures",
#   variables = c("anxiety_gad7", "perfectionism"),
#   db = unified_db,
#   table_format = TRUE,        # Use table format
#   sample_items = 3,           # Show only 3 items
#   check_completeness = TRUE,  # Note missing information
#   quiet = TRUE               # Suppress progress messages
# )
# 
# cat(measures_table)

## -----------------------------------------------------------------------------
# # 1. Initialise and import
# boilerplate_init(create_dirs = TRUE, confirm = FALSE)
# unified_db <- boilerplate_import()
# 
# # 2. Add your measures
# unified_db$measures$political_orientation <- list(
#   name = "political orientation",
#   description = "political orientation on a liberal-conservative spectrum",
#   type = "continuous",
#   reference = "jost2009",
#   waves = "all",
#   range = c(1, 7),
#   items = list("Please rate your political orientation")
# )
# 
# unified_db$measures$social_wellbeing <- list(
#   name = "social wellbeing scale",
#   description = "social wellbeing measured using the Keyes Social Well-Being Scale",
#   type = "continuous",
#   reference = "keyes1998",
#   waves = "5-current",
#   items = list(
#     "I feel like I belong to a community",
#     "I feel that people are basically good",
#     "I have something important to contribute to society",
#     "Society is becoming a better place for everyone"
#   )
# )
# 
# # 3. Standardise the measures
# unified_db$measures <- boilerplate_standardise_measures(
#   unified_db$measures,
#   verbose = FALSE
# )
# 
# # 4. Check quality
# boilerplate_measures_report(unified_db$measures)
# 
# # 5. Save the database
# boilerplate_save(unified_db)
# 
# # 6. Generate formatted output
# exposure_text <- boilerplate_generate_measures(
#   variable_heading = "Exposure Variable",
#   variables = "political_orientation",
#   db = unified_db,
#   heading_level = 3
# )
# 
# outcome_text <- boilerplate_generate_measures(
#   variable_heading = "Outcome Variable",
#   variables = "social_wellbeing",
#   db = unified_db,
#   heading_level = 3
# )
# 
# # 7. Combine with other methods text
# sample_text <- boilerplate_generate_text(
#   category = "methods",
#   sections = "sample",
#   global_vars = list(
#     population = "New Zealand adults",
#     timeframe = "2020-2024"
#   ),
#   db = unified_db
# )
# 
# # 8. Create complete methods section
# methods_section <- paste(
#   "# Methods\n\n",
#   "## Participants\n\n",
#   sample_text, "\n\n",
#   "## Measures\n\n",
#   exposure_text, "\n\n",
#   outcome_text,
#   sep = ""
# )
# 
# cat(methods_section)

## -----------------------------------------------------------------------------
# # Error: Measure 'anxiety' not found
# # Solution: Check exact name
# names(unified_db$measures)  # List all measure names

## -----------------------------------------------------------------------------
# # Warning: Some measures already standardised
# # Solution: This is normal - already standardised measures are skipped

## -----------------------------------------------------------------------------
# # Error: Measure missing required field 'type'
# # Solution: Add the missing field
# unified_db$measures$my_measure$type <- "continuous"

