# Unit tests for boilerplate init functions
library(testthat)

test_that("boilerplate_init creates correct structure", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  test_path <- file.path(temp_dir, "data")
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Test unified init - creates single JSON file by default
  result <- boilerplate_init(data_path = test_path, confirm = FALSE, quiet = TRUE, create_dirs = TRUE)

  # Init functions now return logical indicating success
  expect_type(result, "logical")
  expect_true(result)

  # Check that unified JSON file was created
  expect_true(file.exists(file.path(test_path, "boilerplate_unified.json")))

  # Import and check structure
  unified_db <- boilerplate_import(data_path = test_path, quiet = TRUE)
  expect_type(unified_db, "list")
  expect_true("methods" %in% names(unified_db))
  expect_true("results" %in% names(unified_db))
  expect_true("discussion" %in% names(unified_db))
  expect_true("measures" %in% names(unified_db))
  expect_true("appendix" %in% names(unified_db))
  expect_true("template" %in% names(unified_db))
})

# Removed legacy mode test - no longer supported

# Removed deprecated function tests - no longer supported

test_that("boilerplate_init handles file conflicts correctly", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  test_path <- file.path(temp_dir, "data")
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Create a file first
  boilerplate_init(data_path = test_path, confirm = FALSE, quiet = TRUE, create_dirs = TRUE)

  # Try to create again with keep_existing strategy - should not error
  result <- boilerplate_init(
    data_path = test_path,
    confirm = FALSE,
    quiet = TRUE,
    merge_strategy = "keep_existing"
  )
  expect_true(result)

  # Try with overwrite_all - should also work
  result2 <- boilerplate_init(
    data_path = test_path,
    confirm = FALSE,
    quiet = TRUE,
    merge_strategy = "overwrite_all"
  )
  expect_true(all(result2))
})

# Removed test for boilerplate_init_category - function no longer exists

test_that("boilerplate_init with categories parameter works", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  test_path <- file.path(temp_dir, "data")
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Test creating specific categories only in unified mode
  result <- boilerplate_init(
    categories = c("methods", "measures"),
    data_path = test_path,
    confirm = FALSE,
    quiet = TRUE,
    create_dirs = TRUE
  )

  expect_true(result)
  
  # Check that unified JSON file was created
  expect_true(file.exists(file.path(test_path, "boilerplate_unified.json")))
  
  # Import and check that only requested categories are present
  unified_db <- boilerplate_import(data_path = test_path, quiet = TRUE)
  expect_true("methods" %in% names(unified_db))
  expect_true("measures" %in% names(unified_db))
  
  # Test that only requested categories are in the database
  expect_length(unified_db, 2)
})

test_that("boilerplate_init handles edge cases", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  test_path <- file.path(temp_dir, "data")
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Test with empty categories vector - should create empty unified database
  result <- boilerplate_init(
    categories = character(0),
    data_path = test_path,
    confirm = FALSE,
    quiet = TRUE,
    create_dirs = TRUE
  )
  expect_type(result, "logical")
  expect_true(result)
  
  # Should create an empty unified database
  expect_true(file.exists(file.path(test_path, "boilerplate_unified.json")))
  db <- boilerplate_import(data_path = test_path, quiet = TRUE)
  expect_length(db, 0)

  # Invalid categories are silently ignored in unified mode
  # The function will just create categories it recognizes
})

# Removed deprecated boilerplate_init_text test

# Removed deprecated boilerplate_init_measures test

test_that("boilerplate_init respects create_dirs parameter", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  test_path <- file.path(temp_dir, "nonexistent", "data")
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Test without creating directories - should fail
  expect_error(
    boilerplate_init(
      data_path = test_path,
      confirm = FALSE,
      quiet = TRUE,
      create_dirs = FALSE
    ),
    "Directory does not exist"
  )

  # Test with creating directories
  result <- boilerplate_init(
    data_path = test_path,
    confirm = FALSE,
    quiet = TRUE,
    create_dirs = TRUE
  )
  expect_true(result)
  expect_true(dir.exists(test_path))
})

# Removed test for boilerplate_init_category - no longer exposed as public function

test_that("init functions handle file permissions correctly", {
  skip_on_cran()  # Skip on CRAN as file permissions may vary
  skip_on_os("windows")  # Windows handles permissions differently

  temp_dir <- tempfile()
  dir.create(temp_dir)
  readonly_path <- file.path(temp_dir, "readonly_dir")
  dir.create(readonly_path)
  on.exit({
    Sys.chmod(readonly_path, "755")  # Reset permissions before cleanup
    unlink(temp_dir, recursive = TRUE)
  })

  # Make directory read-only
  Sys.chmod(readonly_path, "555")  # Read + execute only

  # Try to create database in read-only directory
  expect_error(
    boilerplate_init(
      data_path = file.path(readonly_path, "data"),
      confirm = FALSE,
      quiet = TRUE,
      create_dirs = TRUE
    )
  )
})

test_that("boilerplate_init creates valid unified database structure", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  test_path <- file.path(temp_dir, "data")
  on.exit(unlink(temp_dir, recursive = TRUE))

  result <- boilerplate_init(
    data_path = test_path,
    confirm = FALSE,
    quiet = TRUE,
    create_dirs = TRUE
  )

  expect_true(result)

  # Import to check structure
  db <- boilerplate_import(data_path = test_path, quiet = TRUE)

  # Check all categories are present (note: singular forms in new system)
  expect_setequal(
    names(db),
    c("methods", "results", "discussion", "measures", "appendix", "template")
  )

  # Each category should be a list
  for (category in names(db)) {
    expect_type(db[[category]], "list")
  }
})
