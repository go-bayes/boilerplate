# Unit tests for boilerplate init functions
library(testthat)

test_that("boilerplate_init creates correct structure", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  test_path <- file.path(temp_dir, "data")
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Test unified init - creates all categories by default
  result <- boilerplate_init(data_path = test_path, confirm = FALSE, quiet = TRUE, create_dirs = TRUE)

  # Init functions now return logical indicating success
  expect_type(result, "logical")
  expect_true(all(result))

  # Check that files were created
  expect_true(file.exists(file.path(test_path, "methods_db.rds")))
  expect_true(file.exists(file.path(test_path, "results_db.rds")))
  expect_true(file.exists(file.path(test_path, "discussion_db.rds")))
  expect_true(file.exists(file.path(test_path, "measures_db.rds")))
  expect_true(file.exists(file.path(test_path, "appendix_db.rds")))
  expect_true(file.exists(file.path(test_path, "template_db.rds")))

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

test_that("boilerplate_init_text creates correct text database", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  test_path <- file.path(temp_dir, "data")
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Test text db structure - now returns logical
  expect_warning(
    result <- boilerplate_init_text(text_path = test_path, quiet = TRUE, create_dirs = TRUE, confirm = FALSE),
    "deprecated"
  )

  expect_type(result, "logical")
  expect_true(all(result))

  # The deprecated function actually calls boilerplate_init internally
  # It creates standard category databases, not the old text sections
  # Check that category files were created
  expect_true(file.exists(file.path(test_path, "methods_db.rds")))
  expect_true(file.exists(file.path(test_path, "results_db.rds")))
})

test_that("boilerplate_init_measures creates correct measures database", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  test_path <- file.path(temp_dir, "data")
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Test measures db structure - now returns logical
  expect_warning(
    result <- boilerplate_init_measures(measures_path = test_path, quiet = TRUE, create_dirs = TRUE, confirm = FALSE),
    "deprecated"
  )

  expect_type(result, "logical")
  expect_true(result)

  # Check file was created and load to verify structure
  expect_true(file.exists(file.path(test_path, "measures_db.rds")))

  measures_db <- readRDS(file.path(test_path, "measures_db.rds"))
  expect_type(measures_db, "list")

  # Check if it has the expected wrapper
  if ("measures_db" %in% names(measures_db)) {
    measures_db <- measures_db$measures_db
  }

  # Should have at least one example measure
  expect_true(length(measures_db) > 0)
})

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
  expect_true(all(result))

  # Try with overwrite_all - should also work
  result2 <- boilerplate_init(
    data_path = test_path,
    confirm = FALSE,
    quiet = TRUE,
    merge_strategy = "overwrite_all"
  )
  expect_true(all(result2))
})

test_that("boilerplate_init_category creates category databases", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  test_path <- file.path(temp_dir, "data")
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Test each category type
  categories <- c("methods", "results", "discussion", "appendix", "template")

  for (category in categories) {
    result <- boilerplate_init_category(category, data_path = test_path, quiet = TRUE, create_dirs = TRUE, confirm = FALSE)
    expect_true(result)  # Now returns logical
    expect_true(file.exists(file.path(test_path, paste0(category, "_db.rds"))))
  }
})

test_that("boilerplate_init with categories parameter works", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  test_path <- file.path(temp_dir, "data")
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Test creating specific categories only
  result <- boilerplate_init(
    categories = c("methods", "measures"),
    data_path = test_path,
    confirm = FALSE,
    quiet = TRUE,
    create_dirs = TRUE
  )

  expect_true(all(result))
  expect_true(file.exists(file.path(test_path, "methods_db.rds")))
  expect_true(file.exists(file.path(test_path, "measures_db.rds")))
  expect_false(file.exists(file.path(test_path, "results_db.rds")))
})

test_that("boilerplate_init handles edge cases", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  test_path <- file.path(temp_dir, "data")
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Test with empty categories vector - should work (returns empty logical vector)
  result <- boilerplate_init(
    categories = character(0),
    data_path = test_path,
    confirm = FALSE,
    quiet = TRUE,
    create_dirs = TRUE
  )
  expect_type(result, "logical")
  expect_length(result, 0)

  # Test with invalid category
  expect_error(
    boilerplate_init(
      categories = "invalid_category",
      data_path = test_path,
      confirm = FALSE,
      quiet = TRUE,
      create_dirs = TRUE
    ),
    "Invalid category"
  )

  # Test with mixed valid/invalid categories
  expect_error(
    boilerplate_init(
      categories = c("methods", "invalid"),
      data_path = test_path,
      confirm = FALSE,
      quiet = TRUE,
      create_dirs = TRUE
    ),
    "Invalid category"
  )
})

test_that("boilerplate_init_text includes all expected sections", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  test_path <- file.path(temp_dir, "data")
  on.exit(unlink(temp_dir, recursive = TRUE))

  # The deprecated function now just creates standard category databases
  expect_warning(
    result <- boilerplate_init_text(
      text_path = test_path,
      quiet = TRUE,
      create_dirs = TRUE,
      confirm = FALSE
    ),
    "deprecated"
  )

  expect_type(result, "logical")

  # The old text sections don't exist anymore in the new system
  # Instead, check that standard category files were created
  expect_true(file.exists(file.path(test_path, "methods_db.rds")))
  expect_true(file.exists(file.path(test_path, "results_db.rds")))
  expect_true(file.exists(file.path(test_path, "discussion_db.rds")))
})

test_that("boilerplate_init_measures creates valid measure structures", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  test_path <- file.path(temp_dir, "data")
  on.exit(unlink(temp_dir, recursive = TRUE))

  expect_warning(
    result <- boilerplate_init_measures(
      measures_path = test_path,
      quiet = TRUE,
      create_dirs = TRUE,
      confirm = FALSE
    ),
    "deprecated"
  )

  expect_true(result)

  # Load and check structure
  db <- readRDS(file.path(test_path, "measures_db.rds"))

  # Handle wrapper if present
  if ("measures_db" %in% names(db)) {
    db <- db$measures_db
  }

  # If empty structure was created, it might just have example placeholders
  # Skip detailed checks if db is empty or minimal
  if (length(db) > 0) {
    # Check first measure if it exists
    first_key <- names(db)[1]
    if (!is.null(first_key)) {
      measure <- db[[first_key]]
      expect_type(measure, "list")
    }
  }
})

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
  expect_true(all(result))
  expect_true(dir.exists(test_path))
})

test_that("boilerplate_init_category handles all category types", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  test_path <- file.path(temp_dir, "data")
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Test each category returns expected result
  methods_result <- boilerplate_init_category("methods", data_path = test_path, quiet = TRUE, create_dirs = TRUE, confirm = FALSE)
  expect_true(methods_result)

  results_result <- boilerplate_init_category("results", data_path = test_path, quiet = TRUE, create_dirs = TRUE, confirm = FALSE)
  expect_true(results_result)

  discussion_result <- boilerplate_init_category("discussion", data_path = test_path, quiet = TRUE, create_dirs = TRUE, confirm = FALSE)
  expect_true(discussion_result)

  appendix_result <- boilerplate_init_category("appendix", data_path = test_path, quiet = TRUE, create_dirs = TRUE, confirm = FALSE)
  expect_true(appendix_result)

  template_result <- boilerplate_init_category("template", data_path = test_path, quiet = TRUE, create_dirs = TRUE, confirm = FALSE)
  expect_true(template_result)

  # Test invalid category
  expect_error(
    boilerplate_init_category("invalid", data_path = test_path, quiet = TRUE),
    "Invalid category"
  )
})

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

  expect_true(all(result))

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
