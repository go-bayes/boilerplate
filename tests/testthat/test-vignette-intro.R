# Unit tests for intro vignette examples
library(testthat)

test_that("Basic intro vignette examples work", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Test basic initialization
  expect_message(
    boilerplate_init(
      data_path = temp_dir,
      create_dirs = TRUE,
      create_empty = FALSE,
      confirm = FALSE
    ),
    "initialisation complete"
  )
  
  # Import database
  db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)
  expect_type(db, "list")
  expect_true("methods" %in% names(db))
  expect_true("measures" %in% names(db))
  
  # Test generating methods text
  methods_text <- boilerplate_generate_text(
    category = "methods",
    sections = c("sample", "causal_assumptions.confounding_control"),
    db = db,
    quiet = TRUE
  )
  
  expect_type(methods_text, "character")
  expect_true(nchar(methods_text) > 0)
  
  # Test with template variables
  methods_text <- boilerplate_generate_text(
    category = "methods",
    sections = "sample",
    global_vars = list(
      population = "New Zealand adults",
      timeframe = "2021-2022"
    ),
    db = db,
    quiet = TRUE
  )
  
  expect_true(grepl("New Zealand adults", methods_text))
  expect_true(grepl("2021-2022", methods_text))
})

test_that("Intro vignette measures workflow works", {
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
  
  # Test measures report
  # Capture output since the function prints to console
  output <- capture.output({
    report <- boilerplate_measures_report(
      db = db$measures,
      return_report = TRUE
    )
  })
  
  expect_s3_class(report, "data.frame")
  expect_true("measure" %in% names(report))
  expect_true(any(grepl("anxiety", report$measure, ignore.case = TRUE)))
  expect_true(any(grepl("depression", report$measure, ignore.case = TRUE)))
})

test_that("Intro vignette save and export works", {
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
  
  # Add new content
  db$methods$new_section <- "This is a new methods section."
  
  # Save
  expect_true(
    boilerplate_save(db, data_path = temp_dir, confirm = FALSE, quiet = TRUE)
  )
  
  # Export to different location
  export_dir <- file.path(temp_dir, "export")
  export_result <- boilerplate_export(
    db = db,
    data_path = export_dir,
    format = "json",
    confirm = FALSE,
    create_dirs = TRUE,
    quiet = TRUE
  )
  
  # Export returns character vector of file paths
  expect_type(export_result, "character")
  expect_true(length(export_result) > 0)
  
  # Check export exists
  json_files <- list.files(export_dir, pattern = "\\.json$", full.names = TRUE, recursive = TRUE)
  expect_true(length(json_files) > 0)
})