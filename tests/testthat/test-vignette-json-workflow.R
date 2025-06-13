# Unit tests for json-workflow vignette examples
library(testthat)

test_that("json-workflow vignette: basic JSON operations work", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Initialize with JSON format
  boilerplate_init(
    data_path = temp_dir,
    create_dirs = TRUE,
    format = "json",
    confirm = FALSE,
    quiet = TRUE
  )
  
  # Import database
  db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)
  
  # Verify JSON format is being used
  json_files <- list.files(temp_dir, pattern = "\\.json$", full.names = TRUE)
  expect_true(length(json_files) > 0)
  
  # Add content
  db$methods$new_method <- "This is a test method using {{variable}}."
  
  # Save as JSON
  expect_true(
    boilerplate_save(db, data_path = temp_dir, format = "json", confirm = FALSE, quiet = TRUE)
  )
  
  # Verify it saved as JSON
  expect_true(file.exists(file.path(temp_dir, "boilerplate_unified.json")))
})

test_that("json-workflow vignette: JSON validation works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Create a JSON database
  db <- list(
    methods = list(
      sample = list(
        default = "Sample text"
      )
    ),
    measures = list(
      test_measure = list(
        name = "test",
        description = "A test measure"
      )
    )
  )
  
  # Save as JSON
  json_file <- file.path(temp_dir, "test_unified.json")
  jsonlite::write_json(db, json_file, auto_unbox = TRUE, pretty = TRUE)
  
  # Validate structure
  validation_errors <- validate_json_database(json_file, type = "unified")
  
  # Should be valid
  expect_equal(length(validation_errors), 0)
})

test_that("json-workflow vignette: RDS to JSON migration works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Create RDS files
  rds_dir <- file.path(temp_dir, "rds_data")
  dir.create(rds_dir, recursive = TRUE)
  
  # Create test databases
  methods_db <- list(
    sample = list(default = "Sample text"),
    analysis = list(default = "Analysis text")
  )
  measures_db <- list(
    anxiety = list(name = "anxiety", description = "Anxiety measure")
  )
  
  saveRDS(methods_db, file.path(rds_dir, "methods_db.rds"))
  saveRDS(measures_db, file.path(rds_dir, "measures_db.rds"))
  
  # Migrate to JSON
  json_dir <- file.path(temp_dir, "json_data")
  
  results <- boilerplate_migrate_to_json(
    source_path = rds_dir,
    output_path = json_dir,
    format = "unified",
    backup = FALSE,
    quiet = TRUE
  )
  
  expect_true(results$success)
  expect_true(file.exists(file.path(json_dir, "boilerplate_unified.json")))
  
  # Verify content was preserved
  migrated_db <- boilerplate_import(data_path = json_dir, quiet = TRUE)
  expect_equal(migrated_db$methods$sample$default, "Sample text")
  expect_equal(migrated_db$measures$anxiety$name, "anxiety")
})

test_that("json-workflow vignette: batch operations with JSON work", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Initialize with example content
  boilerplate_init(
    data_path = temp_dir,
    create_dirs = TRUE,
    create_empty = FALSE,
    format = "json",
    confirm = FALSE,
    quiet = TRUE
  )
  
  # Import database
  db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)
  
  # Batch edit operation
  db <- boilerplate_batch_edit(
    db = db,
    field = "reference",
    new_value = "updated_ref_2024",
    target_entries = c("anxiety", "depression"),
    category = "measures",
    preview = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  expect_equal(db$measures$anxiety$reference, "updated_ref_2024")
  expect_equal(db$measures$depression$reference, "updated_ref_2024")
  
  # Save back as JSON
  expect_true(
    boilerplate_save(db, data_path = temp_dir, format = "json", confirm = FALSE, quiet = TRUE)
  )
})

test_that("json-workflow vignette: JSON compatibility features work", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Create measures database
  measures_db <- list(
    test_scale = list(
      name = "test_scale",
      description = "A test scale",
      items = c("Item 1", "Item 2"),
      extra_field = "should be preserved",
      `_meta` = list(created = "2024-01-01")
    )
  )
  
  # Standardize with JSON compatibility
  std_db <- boilerplate_standardise_measures(
    measures_db,
    json_compatible = TRUE,
    quiet = TRUE
  )
  
  # Check that all fields are preserved (JSON compatible mode)
  expect_true("extra_field" %in% names(std_db$test_scale))
  expect_true("_meta" %in% names(std_db$test_scale))
})

test_that("json-workflow vignette: compare RDS and JSON formats work", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Create test database
  test_db <- list(
    methods = list(
      sample = list(
        default = "Test sample text",
        custom = "Custom sample text"
      )
    )
  )
  
  # Save as both formats
  rds_file <- file.path(temp_dir, "test.rds")
  json_file <- file.path(temp_dir, "test.json")
  
  saveRDS(test_db, rds_file)
  jsonlite::write_json(test_db, json_file, auto_unbox = TRUE, pretty = TRUE)
  
  # Compare formats
  differences <- compare_rds_json(rds_file, json_file)
  
  # Should have no differences for this simple structure
  expect_equal(length(differences), 0)
})

test_that("json-workflow vignette: JSON file operations work", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Test reading JSON files directly
  test_db <- list(
    methods = list(
      intro = list(text = "Introduction text")
    )
  )
  
  json_file <- file.path(temp_dir, "test_methods.json")
  jsonlite::write_json(test_db, json_file, auto_unbox = TRUE, pretty = TRUE)
  
  # Read using internal function
  read_db <- boilerplate:::read_boilerplate_db(json_file, format = "json")
  
  expect_equal(read_db$methods$intro$text, "Introduction text")
  
  # Test auto-detection
  auto_db <- boilerplate:::read_boilerplate_db(json_file)
  expect_equal(auto_db$methods$intro$text, "Introduction text")
})