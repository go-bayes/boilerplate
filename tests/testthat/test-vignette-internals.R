# Unit tests for internals vignette examples
library(testthat)

test_that("Internals path operations work correctly", {
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
  
  # Test path operations - get a nested entry
  lmtp_content <- boilerplate_get_entry(
    db = db$methods,
    path = "statistical.longitudinal.lmtp"
  )
  
  expect_type(lmtp_content, "character")
  expect_true(grepl("LMTP", lmtp_content))
  
  # Test listing nested content
  longitudinal_content <- boilerplate_get_entry(
    db = db$methods,
    path = "statistical.longitudinal"
  )
  
  expect_type(longitudinal_content, "list")
  expect_true("lmtp" %in% names(longitudinal_content))
  expect_true("sdr" %in% names(longitudinal_content))
})

test_that("Internals database merging works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Create two databases
  db1 <- list(
    methods = list(
      section1 = "Content 1",
      section2 = "Content 2"
    )
  )
  
  db2 <- list(
    methods = list(
      section2 = "Updated content 2",
      section3 = "Content 3"
    )
  )
  
  # Merge (db2 takes precedence)
  merged <- boilerplate:::merge_recursive_lists(db1, db2)
  
  expect_equal(merged$methods$section1, "Content 1")
  expect_equal(merged$methods$section2, "Updated content 2")
  expect_equal(merged$methods$section3, "Content 3")
})

test_that("Internals template variable extraction works", {
  # Test extraction function
  text <- "This is a {{variable1}} with {{variable2}} and repeated {{variable1}}"
  vars <- boilerplate:::extract_template_variables(text)
  
  expect_equal(sort(vars), sort(c("variable1", "variable2")))
  
  # Test with no variables
  text2 = "This has no variables"
  vars2 <- boilerplate:::extract_template_variables(text2)
  
  expect_equal(length(vars2), 0)
})

test_that("Internals file path handling works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Test default path creation
  default_path <- boilerplate:::get_default_data_path()
  expect_type(default_path, "character")
  expect_true(grepl("boilerplate", default_path))
  
  # Test custom path handling
  custom_path <- file.path(temp_dir, "custom", "path")
  
  # Should fail without create_dirs
  expect_error(
    boilerplate:::get_db_file_path(
      category = "methods",
      base_path = custom_path,
      create_dirs = FALSE,
      quiet = TRUE
    ),
    "directory does not exist"
  )
  
  # Should work with create_dirs
  file_path <- boilerplate:::get_db_file_path(
    category = "methods",
    base_path = custom_path,
    create_dirs = TRUE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  expect_true(dir.exists(custom_path))
  expect_true(grepl("methods_db.rds", file_path))
})

test_that("Internals validation functions work", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Create test database
  db <- list(
    methods = list(
      sample = "Sample text with @citation",
      analysis = "Analysis with @another_citation"
    ),
    measures = list(
      scale1 = list(
        name = "Scale 1",
        reference = "ref1"
      )
    )
  )
  
  # Ensure directory exists
  dir.create(temp_dir, recursive = TRUE, showWarnings = FALSE)
  
  # Write as JSON
  json_file <- file.path(temp_dir, "test.json")
  jsonlite::write_json(db, json_file, pretty = TRUE, auto_unbox = TRUE)
  
  # Validate
  validation_errors <- validate_json_database(
    json_file,
    type = "unified"
  )
  
  # If schema not found, skip validation check
  if (length(validation_errors) == 1 && grepl("Schema not found", validation_errors[1])) {
    skip("JSON schema not available for unified type")
  } else {
    # No errors means valid
    expect_equal(length(validation_errors), 0)
  }
})

test_that("Internals sorting functions work", {
  # Test database sorting
  db <- list(
    zebra = "Last",
    alpha = "First", 
    middle = "Middle"
  )
  
  sorted_db <- boilerplate:::sort_db_recursive(db)
  
  expect_equal(names(sorted_db), c("alpha", "middle", "zebra"))
  
  # Test nested sorting
  nested_db <- list(
    category2 = list(
      z_item = "Z",
      a_item = "A"
    ),
    category1 = list(
      item2 = "2",
      item1 = "1"
    )
  )
  
  sorted_nested <- boilerplate:::sort_db_recursive(nested_db)
  
  expect_equal(names(sorted_nested), c("category1", "category2"))
  expect_equal(names(sorted_nested$category1), c("item1", "item2"))
  expect_equal(names(sorted_nested$category2), c("a_item", "z_item"))
})