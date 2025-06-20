# Unit tests for json-schema vignette examples
library(testthat)

test_that("JSON schema basic structure works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Initialize with JSON format
  boilerplate_init(
    data_path = temp_dir,
    create_dirs = TRUE,
    create_empty = FALSE,
    format = "json",
    confirm = FALSE,
    quiet = TRUE
  )
  
  # Read JSON file
  json_file <- file.path(temp_dir, "boilerplate_unified.json")
  json_data <- jsonlite::read_json(json_file)
  
  # Check top-level structure
  expect_type(json_data, "list")
  expect_true(all(c("methods", "measures") %in% names(json_data)))
  
  # Check methods structure
  expect_type(json_data$methods$sample, "character")
  expect_type(json_data$methods$statistical, "list")
  
  # Check measures structure
  expect_type(json_data$measures$anxiety, "list")
  expect_true(all(c("name", "description", "reference", "waves", "keywords", "items") %in% 
                  names(json_data$measures$anxiety)))
})

test_that("JSON schema validation works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Create valid JSON
  valid_db <- list(
    methods = list(
      section1 = "Text content",
      nested = list(
        subsection = "Nested content"
      )
    ),
    measures = list(
      scale1 = list(
        name = "Scale Name",
        description = "Scale description",
        reference = "author2024",
        waves = "1-3",
        keywords = c("keyword1", "keyword2"),
        items = list("item1", "item2")
      )
    )
  )
  
  # Ensure directory exists
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
  
  json_file <- file.path(temp_dir, "valid.json")
  jsonlite::write_json(valid_db, json_file, pretty = TRUE, auto_unbox = TRUE)
  
  # Validate
  validation_errors <- validate_json_database(json_file, type = "unified")
  
  # If schema not found, skip validation check
  if (length(validation_errors) == 1 && grepl("Schema not found", validation_errors[1])) {
    skip("JSON schema not available")
  } else {
    # No errors means valid
    expect_equal(length(validation_errors), 0)
  }
})

test_that("JSON schema measures format works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Create measures database
  measures_db <- list(
    gad7 = list(
      name = "Generalized Anxiety Disorder 7-item scale",
      description = "A brief measure for assessing generalized anxiety disorder",
      reference = "spitzer2006",
      waves = "1-5",
      keywords = c("anxiety", "GAD", "mental health"),
      items = list(
        "Feeling nervous, anxious, or on edge",
        "Not being able to stop or control worrying",
        "Worrying too much about different things",
        "Trouble relaxing",
        "Being so restless that it is hard to sit still",
        "Becoming easily annoyed or irritable",
        "Feeling afraid, as if something awful might happen"
      )
    ),
    phq9 = list(
      name = "Patient Health Questionnaire-9",
      description = "A 9-item depression screening instrument",
      reference = "kroenke2001",
      waves = "1-5",
      keywords = c("depression", "PHQ", "mental health"),
      items = list(
        "Little interest or pleasure in doing things",
        "Feeling down, depressed, or hopeless",
        "Trouble falling or staying asleep, or sleeping too much",
        "Feeling tired or having little energy",
        "Poor appetite or overeating",
        "Feeling bad about yourself",
        "Trouble concentrating on things",
        "Moving or speaking slowly/being fidgety or restless",
        "Thoughts of self-harm"
      )
    )
  )
  
  # Ensure directory exists
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
  
  # Save as JSON
  json_file <- file.path(temp_dir, "measures.json")
  jsonlite::write_json(measures_db, json_file, pretty = TRUE, auto_unbox = TRUE)
  
  # Import and verify structure
  imported <- jsonlite::read_json(json_file)
  
  expect_equal(length(imported$gad7$items), 7)
  expect_equal(length(imported$phq9$items), 9)
  expect_equal(imported$gad7$reference, "spitzer2006")
})

test_that("JSON schema methods format works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Create methods database with nested structure
  methods_db <- list(
    sample = list(
      recruitment = "Participants were recruited through {{method}}",
      size = "The target sample size was {{n}} participants",
      eligibility = list(
        inclusion = "Inclusion criteria: {{inclusion_criteria}}",
        exclusion = "Exclusion criteria: {{exclusion_criteria}}"
      )
    ),
    analysis = list(
      primary = list(
        description = "Primary analyses used {{statistical_method}}",
        software = "Analyses were conducted using {{software}} version {{version}}"
      ),
      sensitivity = list(
        description = "Sensitivity analyses included {{sensitivity_checks}}"
      )
    )
  )
  
  # Ensure directory exists
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
  
  # Save as JSON
  json_file <- file.path(temp_dir, "methods.json")
  jsonlite::write_json(methods_db, json_file, pretty = TRUE, auto_unbox = TRUE)
  
  # Import and verify nested structure
  imported <- jsonlite::read_json(json_file)
  
  expect_type(imported$sample$eligibility, "list")
  expect_type(imported$analysis$primary$description, "character")
  expect_true(grepl("\\{\\{statistical_method\\}\\}", imported$analysis$primary$description))
})

test_that("JSON schema template format works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Create template database
  template_db <- list(
    manuscript = list(
      title_page = "---\ntitle: '{{title}}'\nauthor: '{{authors}}'\ndate: '{{date}}'\n---",
      abstract = list(
        heading = "## Abstract",
        content = "{{abstract_content}}",
        keywords = "**Keywords:** {{keywords}}"
      ),
      sections = list(
        introduction = "## Introduction\n\n{{intro_content}}",
        methods = "## Methods\n\n{{methods_content}}",
        results = "## Results\n\n{{results_content}}",
        discussion = "## Discussion\n\n{{discussion_content}}"
      )
    ),
    report = list(
      header = "# {{report_title}}\n\n**Date:** {{date}}\n**Author:** {{author}}",
      summary = "## Executive Summary\n\n{{summary_content}}"
    )
  )
  
  # Ensure directory exists
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
  
  # Save as JSON
  json_file <- file.path(temp_dir, "templates.json")
  jsonlite::write_json(template_db, json_file, pretty = TRUE, auto_unbox = TRUE)
  
  # Import and verify structure
  imported <- jsonlite::read_json(json_file)
  
  expect_type(imported$manuscript$abstract, "list")
  expect_type(imported$manuscript$sections, "list")
  expect_equal(length(imported$manuscript$sections), 4)
  expect_true(grepl("\\{\\{title\\}\\}", imported$manuscript$title_page))
})