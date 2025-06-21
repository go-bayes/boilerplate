# Unit tests for architecture vignette examples
library(testthat)

test_that("Architecture unified database structure works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Initialise unified database
  boilerplate_init(
    data_path = temp_dir,
    categories = c("methods", "measures", "results", "discussion", "appendix", "template"),
    create_dirs = TRUE,
    create_empty = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )

  # Import and check structure
  db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)

  # Verify unified structure
  expect_type(db, "list")
  expect_equal(
    sort(names(db)),
    sort(c("methods", "measures", "results", "discussion", "appendix", "template"))
  )

  # Check nested structure
  expect_type(db$methods$statistical, "list")
  expect_type(db$methods$statistical$longitudinal, "list")
  expect_type(db$measures$anxiety, "list")
})

test_that("Architecture dot notation access works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Initialise
  boilerplate_init(
    data_path = temp_dir,
    create_dirs = TRUE,
    create_empty = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )

  db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)

  # Test dot notation in generate_text
  text <- boilerplate_generate_text(
    category = "methods",
    sections = "statistical.longitudinal.lmtp",
    db = db,
    quiet = TRUE
  )

  expect_type(text, "character")
  expect_true(grepl("LMTP", text))
  expect_true(grepl("TMLE", text))
})

test_that("Architecture JSON format validation works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Initialise with JSON format
  boilerplate_init(
    data_path = temp_dir,
    create_dirs = TRUE,
    create_empty = FALSE,
    format = "json",
    confirm = FALSE,
    quiet = TRUE
  )

  # Check JSON file exists
  json_file <- file.path(temp_dir, "boilerplate_unified.json")
  expect_true(file.exists(json_file))

  # Import and validate
  db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)

  # Validate JSON structure
  validation_errors <- validate_json_database(
    json_file,
    type = "unified"
  )

  # If schema not found, skip validation check
  if (length(validation_errors) == 1 && grepl("Schema not found", validation_errors[1])) {
    skip("JSON schema not available")
  } else {
    # No errors means valid
    expect_equal(length(validation_errors), 0)
  }
})

test_that("Architecture template system works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Initialise
  boilerplate_init(
    data_path = temp_dir,
    create_dirs = TRUE,
    create_empty = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )

  db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)

  # Add template with nested variables
  db$template$report <- list(
    header = "# {{project_name}} Report",
    methods = "## Methods\n\n{{methods_content}}",
    results = "## Results\n\n{{results_content}}"
  )

  # Save
  boilerplate_save(db, data_path = temp_dir, confirm = FALSE, quiet = TRUE)

  # Test template retrieval
  template <- boilerplate_template(
    unified_db = db,
    name = "report"
  )

  expect_type(template, "list")
  expect_true(all(c("header", "methods", "results") %in% names(template)))
})

test_that("Architecture extensibility works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Initialise
  boilerplate_init(
    data_path = temp_dir,
    create_dirs = TRUE,
    create_empty = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )

  db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)

  # Add custom category
  db$custom <- list(
    section1 = "Custom content 1",
    section2 = list(
      subsection1 = "Nested custom content",
      subsection2 = "More nested content"
    )
  )

  # Save and reload
  boilerplate_save(db, data_path = temp_dir, confirm = FALSE, quiet = TRUE)
  db_reload <- boilerplate_import(data_path = temp_dir, quiet = TRUE)

  # Verify custom content preserved
  expect_true("custom" %in% names(db_reload))
  expect_equal(db_reload$custom$section1, "Custom content 1")
  expect_equal(db_reload$custom$section2$subsection1, "Nested custom content")
})
