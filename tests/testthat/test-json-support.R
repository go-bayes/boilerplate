library(testthat)

# Test JSON support functions

test_that("read_boilerplate_db can read both JSON and RDS formats", {
  skip_if_not_installed("jsonlite")
  
  # Create test data
  test_db <- list(
    methods = list(
      sample = list(
        description = "Sample description",
        text = "Sample text"
      )
    )
  )
  
  # Test RDS format
  temp_rds <- tempfile(fileext = ".rds")
  saveRDS(test_db, temp_rds)
  
  db_from_rds <- boilerplate:::read_boilerplate_db(temp_rds, format = "rds")
  expect_equal(db_from_rds, test_db)
  
  # Test JSON format
  temp_json <- tempfile(fileext = ".json")
  jsonlite::write_json(test_db, temp_json, auto_unbox = TRUE)
  
  db_from_json <- boilerplate:::read_boilerplate_db(temp_json, format = "json")
  expect_equal(db_from_json$methods$sample$text, test_db$methods$sample$text)
  
  # Test auto-detection
  db_auto_rds <- boilerplate:::read_boilerplate_db(temp_rds)
  expect_equal(db_auto_rds, test_db)
  
  db_auto_json <- boilerplate:::read_boilerplate_db(temp_json)
  expect_equal(db_auto_json$methods$sample$text, test_db$methods$sample$text)
  
  # Clean up
  unlink(c(temp_rds, temp_json))
})

test_that("write_boilerplate_db can write both JSON and RDS formats", {
  skip_if_not_installed("jsonlite")
  
  test_db <- list(
    measures = list(
      age = list(
        name = "age",
        description = "Age in years",
        type = "continuous"
      )
    )
  )
  
  temp_dir <- tempdir()
  base_path <- file.path(temp_dir, "test_db")
  
  # Test writing RDS
  rds_path <- paste0(base_path, ".rds")
  boilerplate:::write_boilerplate_db(test_db, rds_path, format = "rds")
  expect_true(file.exists(rds_path))
  
  # Test writing JSON
  json_path <- paste0(base_path, ".json")
  boilerplate:::write_boilerplate_db(test_db, json_path, format = "json")
  expect_true(file.exists(json_path))
  
  # Test writing both
  base_path2 <- file.path(temp_dir, "test_db2.rds")  # Provide extension for both
  boilerplate:::write_boilerplate_db(test_db, base_path2, format = "both")
  expect_true(file.exists(base_path2))
  expect_true(file.exists(sub("\\.rds$", ".json", base_path2)))
  
  # Clean up
  unlink(list.files(temp_dir, pattern = "test_db", full.names = TRUE))
})

test_that("boilerplate_import handles JSON files", {
  skip_if_not_installed("jsonlite")
  
  # Create test JSON files
  temp_dir <- tempdir()
  test_data_dir <- file.path(temp_dir, "test_json_import")
  dir.create(test_data_dir, showWarnings = FALSE)
  
  # Create methods JSON
  methods_db <- list(
    sample = list(
      text = "Sample methods text",
      description = "Sample description"
    )
  )
  jsonlite::write_json(
    methods_db, 
    file.path(test_data_dir, "methods_db.json"),
    auto_unbox = TRUE
  )
  
  # Create measures JSON
  measures_db <- list(
    demographics = list(
      age = list(
        name = "age",
        description = "Age in years",
        type = "continuous"
      )
    )
  )
  jsonlite::write_json(
    measures_db,
    file.path(test_data_dir, "measures_db.json"),
    auto_unbox = TRUE
  )
  
  # Test importing all categories
  db <- boilerplate_import(
    data_path = test_data_dir,
    quiet = TRUE
  )
  
  expect_type(db, "list")
  expect_true("methods" %in% names(db))
  expect_true("measures" %in% names(db))
  expect_equal(db$methods$sample$text, "Sample methods text")
  expect_equal(db$measures$demographics$age$name, "age")
  
  # Test importing specific category - returns unwrapped content
  db_methods <- boilerplate_import(
    category = "methods",
    data_path = test_data_dir,
    quiet = TRUE
  )
  
  # When importing single category, it returns the content directly
  expect_true("sample" %in% names(db_methods))
  expect_equal(db_methods$sample$text, "Sample methods text")
  
  # Clean up
  unlink(test_data_dir, recursive = TRUE)
})

test_that("boilerplate_save handles JSON format", {
  skip_if_not_installed("jsonlite")
  
  # Create test database
  test_db <- list(
    methods = list(
      sample = list(
        text = "Test methods text",
        description = "Test description"
      )
    )
  )
  
  temp_dir <- tempdir()
  test_data_dir <- file.path(temp_dir, "test_json_save")
  dir.create(test_data_dir, showWarnings = FALSE)
  
  # Test saving as JSON only
  result <- boilerplate_save(
    test_db$methods,
    data_path = test_data_dir,
    category = "methods",
    format = "json",
    confirm = FALSE,
    quiet = TRUE
  )
  
  expect_true(result)
  json_files <- list.files(test_data_dir, pattern = "\\.json$")
  expect_length(json_files, 1)
  
  # Test saving as both formats
  result2 <- boilerplate_save(
    test_db,
    data_path = test_data_dir,
    format = "both",
    confirm = FALSE,
    quiet = TRUE
  )
  
  expect_true(result2)
  all_files <- list.files(test_data_dir)
  expect_true(any(grepl("\\.json$", all_files)))
  expect_true(any(grepl("\\.rds$", all_files)))
  
  # Clean up
  unlink(test_data_dir, recursive = TRUE)
})

test_that("boilerplate_rds_to_json converts files correctly", {
  skip_if_not_installed("jsonlite")
  
  # Create test RDS file
  test_db <- list(
    test_db = list(
      entry1 = list(text = "Test text 1"),
      entry2 = list(text = "Test text 2")
    )
  )
  
  temp_dir <- tempdir()
  rds_file <- file.path(temp_dir, "test_convert.rds")
  saveRDS(test_db, rds_file)
  
  # Convert single file
  result <- boilerplate_rds_to_json(rds_file, quiet = TRUE)
  expect_true(result)
  
  json_file <- sub("\\.rds$", ".json", rds_file)
  expect_true(file.exists(json_file))
  
  # Verify content
  converted_db <- jsonlite::read_json(json_file)
  expect_equal(converted_db$test_db$entry1$text, "Test text 1")
  
  # Test directory conversion
  test_dir <- file.path(temp_dir, "test_rds_dir")
  dir.create(test_dir, showWarnings = FALSE)
  
  # Create multiple RDS files
  saveRDS(list(methods_db = list(a = 1)), file.path(test_dir, "methods_db.rds"))
  saveRDS(list(measures_db = list(b = 2)), file.path(test_dir, "measures_db.rds"))
  
  result2 <- boilerplate_rds_to_json(test_dir, quiet = TRUE)
  expect_true(result2)
  
  json_files <- list.files(test_dir, pattern = "\\.json$")
  expect_length(json_files, 2)
  
  # Clean up
  unlink(c(rds_file, json_file))
  unlink(test_dir, recursive = TRUE)
})

test_that("boilerplate_batch_edit works with JSON files", {
  skip_if_not_installed("jsonlite")
  
  # Create test database
  test_db <- list(
    methods = list(
      stat1 = list(
        text = "Original text 1",
        description = "Original description"
      ),
      stat2 = list(
        text = "Original text 2",
        description = "Original description"
      )
    )
  )
  
  # Test batch edit
  edited_db <- boilerplate_batch_edit(
    test_db,
    field = "description",
    new_value = "Updated description",
    target_entries = "*",
    category = "methods",
    preview = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  expect_equal(edited_db$methods$stat1$description, "Updated description")
  expect_equal(edited_db$methods$stat2$description, "Updated description")
  
  # Test with JSON file input
  temp_json <- tempfile(fileext = ".json")
  jsonlite::write_json(test_db, temp_json, auto_unbox = TRUE)
  
  edited_db2 <- boilerplate_batch_edit(
    temp_json,  # Can pass file path directly
    field = "text",
    new_value = "New text",
    target_entries = "stat1",
    category = "methods",
    preview = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  expect_equal(edited_db2$methods$stat1$text, "New text")
  expect_equal(edited_db2$methods$stat2$text, "Original text 2")
  
  # Clean up
  unlink(temp_json)
})

test_that("boilerplate_standardise_measures with json_compatible preserves JSON structure", {
  skip_if_not_installed("jsonlite")
  
  # Create test measures database
  measures_db <- list(
    demographics = list(
      age = list(
        name = "age",
        description = "Age in years",
        custom_field = "should be removed"
      ),
      gender = list(
        description = "Gender"  # Missing name field
      )
    )
  )
  
  # Test standardization
  std_db <- boilerplate_standardise_measures(
    measures_db,
    json_compatible = TRUE,
    quiet = TRUE
  )
  
  # Check that entries were processed
  expect_equal(names(std_db), names(measures_db))  # Structure preserved
  expect_true(is.list(std_db$demographics$age))
  expect_true(is.list(std_db$demographics$gender))
  
  # Check that the field still exists (base function doesn't remove extra fields)
  expect_true("custom_field" %in% names(std_db$demographics$age))
  
  # Test with metadata preservation
  measures_db2 <- list(
    demographics = list(
      age = list(
        name = "age",
        description = "Age",
        `_meta` = list(created = "2024-01-01"),
        extra_field = "remove me"
      )
    )
  )
  
  std_db2 <- boilerplate_standardise_measures(
    measures_db2,
    json_compatible = TRUE,
    quiet = TRUE
  )
  
  # Check metadata preserved - base function keeps all fields
  expect_true("_meta" %in% names(std_db2$demographics$age))
  expect_true("extra_field" %in% names(std_db2$demographics$age))
})

test_that("JSON databases maintain compatibility with RDS workflows", {
  skip_if_not_installed("jsonlite")
  
  # Create a unified test database
  test_db <- list(
    methods = list(
      sample = list(
        text = "The sample size was {{n}} participants",
        description = "Sample size statement"
      )
    ),
    measures = list(
      demographics = list(
        age = list(
          name = "age",
          description = "Age in years",
          type = "continuous"
        )
      )
    )
  )
  
  temp_dir <- tempdir()
  test_path <- file.path(temp_dir, "compat_test")
  dir.create(test_path, showWarnings = FALSE)
  
  # Save in both formats
  boilerplate_save(
    test_db,
    data_path = test_path,
    format = "both",
    confirm = FALSE,
    quiet = TRUE
  )
  
  # Find the saved files
  files <- list.files(test_path, full.names = TRUE)
  json_file <- files[grepl("\\.json$", files)][1]
  rds_file <- files[grepl("\\.rds$", files)][1]
  
  # Load from both formats
  db_from_json <- jsonlite::read_json(json_file)
  db_from_rds <- readRDS(rds_file)
  
  # Compare structure
  expect_equal(names(db_from_json), names(db_from_rds))
  expect_equal(
    db_from_json$methods$sample$text,
    db_from_rds$methods$sample$text
  )
  
  # Clean up
  unlink(test_path, recursive = TRUE)
})