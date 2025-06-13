# Unit tests for measures-workflow vignette examples
library(testthat)

test_that("measures-workflow vignette: creating measures database works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Initialize
  boilerplate_init(
    data_path = temp_dir,
    categories = "measures",
    create_dirs = TRUE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  # Import measures database
  db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)
  measures_db <- boilerplate_measures(db)
  
  # Add a psychological scale
  db <- boilerplate_add_entry(
    db,
    path = "measures.gad7",
    value = list(
      name = "Generalized Anxiety Disorder 7-item scale",
      abbreviation = "GAD-7",
      description = "A brief measure for assessing generalized anxiety disorder",
      reference = "Spitzer et al. (2006)",
      n_items = 7,
      scale = "0-3",
      subscales = NULL,
      reverse_items = NULL,
      instructions = "Over the last 2 weeks, how often have you been bothered by the following problems?",
      response_options = c(
        "0 = Not at all",
        "1 = Several days", 
        "2 = More than half the days",
        "3 = Nearly every day"
      ),
      items = list(
        "gad7_1" = "Feeling nervous, anxious or on edge",
        "gad7_2" = "Not being able to stop or control worrying",
        "gad7_3" = "Worrying too much about different things",
        "gad7_4" = "Trouble relaxing",
        "gad7_5" = "Being so restless that it is hard to sit still",
        "gad7_6" = "Becoming easily annoyed or irritable",
        "gad7_7" = "Feeling afraid as if something awful might happen"
      )
    )
  )
  
  expect_true("gad7" %in% names(db$measures))
  expect_equal(db$measures$gad7$n_items, 7)
  expect_equal(length(db$measures$gad7$items), 7)
})

test_that("measures-workflow vignette: standardizing measures works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Create measures with inconsistent structure
  measures_db <- list(
    scale1 = list(
      name = "Scale 1",
      description = "Description without proper capitalization",
      items = c("item 1", "item 2"),
      extra_field = "should be handled"
    ),
    scale2 = list(
      description = "Missing name field",
      items = list(
        item1 = "First item",
        item2 = "Second item"
      )
    )
  )
  
  # Standardize
  std_db <- boilerplate_standardise_measures(measures_db, quiet = TRUE)
  
  # Check standardization
  expect_true(is.list(std_db))
  expect_equal(names(std_db), names(measures_db))
  
  # Original structure is preserved but could be enhanced
  expect_true("name" %in% names(std_db$scale1))
  expect_true("description" %in% names(std_db$scale2))
})

test_that("measures-workflow vignette: measures report generation works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Initialize with example content
  boilerplate_init(
    data_path = temp_dir,
    create_dirs = TRUE,
    create_empty = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)
  
  # Generate measures report
  report <- boilerplate_measures_report(db$measures, return_report = TRUE)
  
  expect_true(is.data.frame(report))
  expect_true(nrow(report) > 0)
  expect_true("measure" %in% names(report))
  expect_true("has_description" %in% names(report))
})

test_that("measures-workflow vignette: generating measures text works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Initialize with example content
  boilerplate_init(
    data_path = temp_dir,
    create_dirs = TRUE,
    create_empty = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)
  
  # Generate measures text for methods section
  measures_text <- boilerplate_generate_measures(
    variable_heading = "Study Measures",
    variables = c("anxiety", "depression", "life_satisfaction"),
    db = db,
    quiet = TRUE
  )
  
  expect_type(measures_text, "character")
  expect_true(grepl("anxiety", measures_text, ignore.case = TRUE))
  expect_true(grepl("depression", measures_text, ignore.case = TRUE))
  expect_true(grepl("life satisfaction", measures_text, ignore.case = TRUE))
  
  # Generate appendix format
  appendix_text <- boilerplate_generate_measures(
    variable_heading = "Measures Appendix",
    variables = c("anxiety", "depression", "life_satisfaction"),
    db = db,
    table_format = TRUE,
    sample_items = FALSE,  # Show all items
    quiet = TRUE
  )
  
  expect_type(appendix_text, "character")
  expect_true(nchar(appendix_text) > nchar(measures_text))  # Appendix should be longer
})

test_that("measures-workflow vignette: batch operations on measures work", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Initialize with example content
  boilerplate_init(
    data_path = temp_dir,
    create_dirs = TRUE,
    create_empty = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)
  
  # Batch update references
  db <- boilerplate_batch_edit(
    db = db,
    field = "reference",
    new_value = "Study Protocol v2.0",
    target_entries = "*",  # All measures
    category = "measures",
    preview = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  # Verify updates
  expect_equal(db$measures$anxiety$reference, "Study Protocol v2.0")
  expect_equal(db$measures$depression$reference, "Study Protocol v2.0")
  
  # Batch update waves
  db <- boilerplate_batch_edit(
    db = db,
    field = "waves",
    new_value = "1-10",
    match_pattern = "1-",  # Match measures with waves starting with "1-"
    category = "measures",
    preview = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  # Check that matched measures were updated
  for (measure_name in names(db$measures)) {
    measure <- db$measures[[measure_name]]
    if (!is.null(measure$waves) && grepl("^1-", measure$waves)) {
      expect_equal(measure$waves, "1-10")
    }
  }
})

test_that("measures-workflow vignette: exporting measures subset works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Initialize with example content
  boilerplate_init(
    data_path = temp_dir,
    create_dirs = TRUE,
    create_empty = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)
  
  # Export specific measures
  output_file <- file.path(temp_dir, "mental_health_measures.json")
  
  boilerplate_export(
    db = db,
    select_elements = c("measures.anxiety", "measures.depression"),
    data_path = temp_dir,
    output_file = output_file,
    format = "json",
    save_by_category = FALSE,
    quiet = TRUE,
    confirm = FALSE
  )
  
  expect_true(file.exists(output_file))
  
  # Verify only selected measures were exported
  exported <- jsonlite::read_json(output_file)
  expect_true("anxiety" %in% names(exported$measures))
  expect_true("depression" %in% names(exported$measures))
  expect_false("life_satisfaction" %in% names(exported$measures))
})

test_that("measures-workflow vignette: integrating with analysis works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Initialize
  boilerplate_init(
    data_path = temp_dir,
    create_dirs = TRUE,
    create_empty = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)
  
  # Add analysis method that references measures
  db <- boilerplate_add_entry(
    db,
    path = "methods.analysis.mental_health",
    value = paste0(
      "Mental health was assessed using {{measures_list}}. ",
      "All scales demonstrated good internal consistency (α > .80). ",
      "Composite scores were calculated as {{scoring_method}}."
    )
  )
  
  # Generate integrated text
  methods_text <- boilerplate_generate_text(
    category = "methods",
    sections = "analysis.mental_health",
    global_vars = list(
      measures_list = "the GAD-7 for anxiety and PHQ-9 for depression",
      scoring_method = "the mean of all items after reverse-scoring where applicable"
    ),
    db = db,
    quiet = TRUE
  )
  
  expect_true(grepl("GAD-7", methods_text))
  expect_true(grepl("PHQ-9", methods_text))
  expect_true(grepl("α > .80", methods_text))
})