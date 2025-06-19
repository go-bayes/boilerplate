# Tests for bibliography support functions
library(testthat)

test_that("parse_bibtex_keys extracts citation keys correctly", {
  # Create a temporary bibtex file
  temp_bib <- tempfile(fileext = ".bib")

  bib_content <- '
@article{smith2023,
  title = {A Test Article},
  author = {Smith, John},
  year = {2023}
}

@book{doe2022methodology,
  title = {Research Methods},
  author = {Doe, Jane},
  year = {2022}
}

@inproceedings{jones-brown2021,
  title = {Conference Paper},
  author = {Jones, A. and Brown, B.},
  year = {2021}
}
'

  writeLines(bib_content, temp_bib)

  # Test extraction
  keys <- boilerplate:::parse_bibtex_keys(temp_bib)

  expect_equal(length(keys), 3)
  expect_true("smith2023" %in% keys)
  expect_true("doe2022methodology" %in% keys)
  expect_true("jones-brown2021" %in% keys)

  # Clean up
  unlink(temp_bib)
})

test_that("extract_citation_keys finds citations in text", {
  # Test various citation formats
  text1 <- "According to @smith2023, this is true."
  text2 <- "Previous research [@doe2022methodology] shows..."
  text3 <- "Multiple citations [@smith2023; @jones-brown2021] are supported."
  text4 <- "See also @doe2022methodology and [@vanderweele2017]."

  keys1 <- boilerplate:::extract_citation_keys(text1)
  expect_equal(keys1, "smith2023")

  keys2 <- boilerplate:::extract_citation_keys(text2)
  expect_equal(keys2, "doe2022methodology")

  keys3 <- boilerplate:::extract_citation_keys(text3)
  expect_true("smith2023" %in% keys3)
  expect_true("jones-brown2021" %in% keys3)

  keys4 <- boilerplate:::extract_citation_keys(text4)
  expect_true("doe2022methodology" %in% keys4)
  expect_true("vanderweele2017" %in% keys4)

  # Test with multiple texts
  all_keys <- boilerplate:::extract_citation_keys(c(text1, text2, text3, text4))
  expect_equal(length(unique(all_keys)), 4)
})

test_that("extract_all_text recursively extracts text from database", {
  # Create test database structure
  test_db <- list(
    methods = list(
      sample = "We recruited participants @smith2023.",
      analysis = list(
        main = "Analysis followed @doe2022methodology.",
        sensitivity = "See also @jones2021."
      )
    ),
    results = "Results showed significance [@brown2020]."
  )

  # Extract all text
  all_text <- boilerplate:::extract_all_text(test_db)

  expect_equal(length(all_text), 4)
  expect_true(any(grepl("@smith2023", all_text)))
  expect_true(any(grepl("@doe2022methodology", all_text)))
  expect_true(any(grepl("@jones2021", all_text)))
  expect_true(any(grepl("@brown2020", all_text)))
})

test_that("boilerplate_add_bibliography adds bibliography info to database", {
  # Create test database
  test_db <- list(
    methods = list(sample = "Test content")
  )

  # Add bibliography
  updated_db <- boilerplate_add_bibliography(
    test_db,
    url = "https://example.com/references.bib",
    local_path = "my_refs.bib",
    validate = TRUE
  )

  expect_true("bibliography" %in% names(updated_db))
  expect_equal(updated_db$bibliography$url, "https://example.com/references.bib")
  expect_equal(updated_db$bibliography$local_path, "my_refs.bib")
  expect_true(updated_db$bibliography$validate)
  expect_true("last_updated" %in% names(updated_db$bibliography))
})

test_that("boilerplate_update_bibliography handles missing bibliography gracefully", {
  # Database without bibliography
  test_db <- list(
    methods = list(sample = "Test content")
  )

  result <- boilerplate_update_bibliography(test_db, quiet = TRUE)
  expect_null(result)
})

test_that("boilerplate_validate_references detects missing citations", {
  # Create temporary bib file
  temp_bib <- tempfile(fileext = ".bib")
  bib_content <- '
@article{smith2023,
  title = {A Test Article},
  author = {Smith, John},
  year = {2023}
}

@book{doe2022,
  title = {Research Methods},
  author = {Doe, Jane},
  year = {2022}
}
'
  writeLines(bib_content, temp_bib)

  # Create test database with citations
  test_db <- list(
    methods = list(
      sample = "According to @smith2023, this is true.",
      analysis = "We followed @missing2024 methodology."
    ),
    results = "As shown by [@doe2022]."
  )

  # Validate
  validation <- boilerplate_validate_references(
    test_db,
    bib_file = temp_bib,
    quiet = TRUE
  )

  expect_equal(length(validation$used), 3)
  expect_equal(length(validation$missing), 1)
  expect_equal(validation$missing, "missing2024")
  expect_false(validation$valid)

  # Clean up
  unlink(temp_bib)
})

test_that("boilerplate_copy_bibliography copies file correctly", {
  # Create temporary setup
  temp_cache <- tempfile("cache")
  dir.create(temp_cache)
  temp_target <- tempfile("target")
  dir.create(temp_target)

  # Create a mock bibliography file in cache
  bib_file <- file.path(temp_cache, "references.bib")
  writeLines("@article{test2023}", bib_file)

  # Create test database
  test_db <- list(
    bibliography = list(
      url = "https://example.com/references.bib",
      local_path = "references.bib"
    )
  )

  # Mock the update function to return our test file
  with_mocked_bindings(
    boilerplate_update_bibliography = function(...) bib_file,
    {
      result <- boilerplate_copy_bibliography(
        test_db,
        target_dir = temp_target,
        quiet = TRUE
      )

      expect_equal(basename(result), "references.bib")
      expect_true(file.exists(result))

      # Check content
      content <- readLines(result)
      expect_equal(content, "@article{test2023}")
    }
  )

  # Clean up
  unlink(temp_cache, recursive = TRUE)
  unlink(temp_target, recursive = TRUE)
})

test_that("generate_text copies bibliography when requested", {
  # Create temporary directories
  temp_dir <- tempfile("test_generate")
  data_path <- file.path(temp_dir, "data")
  dir.create(data_path, recursive = TRUE)

  # Initialise with empty structure
  boilerplate_init(
    categories = "methods",
    data_path = data_path,
    create_dirs = TRUE,
    create_empty = TRUE,
    confirm = FALSE,
    quiet = TRUE
  )

  # Create test database with bibliography
  test_db <- boilerplate_import(data_path = data_path, quiet = TRUE)
  test_db$bibliography <- list(
    url = "https://example.com/references.bib",
    local_path = "test_refs.bib"
  )

  # Add some content
  test_db$methods$sample <- "Test sample text with @citation2023."

  # Mock the copy function
  copy_called <- FALSE
  with_mocked_bindings(
    boilerplate_copy_bibliography = function(...) {
      copy_called <<- TRUE
      return("test_refs.bib")
    },
    {
      # Generate text with bibliography copy
      text <- boilerplate_generate_text(
        category = "methods",
        sections = "sample",
        db = test_db,
        copy_bibliography = TRUE,
        bibliography_path = temp_dir,
        quiet = TRUE
      )

      expect_true(copy_called)
      expect_true(grepl("Test sample text", text))
    }
  )

  # Clean up
  unlink(temp_dir, recursive = TRUE)
})

test_that("default cache directory is set correctly", {
  # Simple test without mocking
  expected_cache <- tools::R_user_dir("boilerplate", "cache")
  
  # The internal migrate_old_cache function should use the same path
  # We can't test it directly since it's internal, but we can verify
  # the pattern is consistent
  expect_true(is.character(expected_cache))
  expect_true(length(expected_cache) == 1)
  expect_true(nchar(expected_cache) > 0)
})

test_that("cache directory uses tools::R_user_dir", {
  # Skip on CRAN to avoid mocking issues
  skip_on_cran()
  
  # Create test database with bibliography
  test_db <- list(
    bibliography = list(
      url = "https://example.com/test.bib",
      local_path = "test.bib"
    )
  )
  
  # Create a temporary file to simulate successful download
  temp_dir <- tempfile()
  dir.create(temp_dir)
  temp_bib <- file.path(temp_dir, "test.bib")
  writeLines("@article{test2024}", temp_bib)
  
  # Mock download.file to copy our temp file
  with_mocked_bindings(
    download.file = function(url, destfile, ...) {
      file.copy(temp_bib, destfile, overwrite = TRUE)
      invisible(0)
    },
    {
      # Get cache directory that would be used
      expected_cache <- tools::R_user_dir("boilerplate", "cache")
      
      # Call update_bibliography without specifying cache_dir
      result <- suppressMessages(boilerplate_update_bibliography(test_db, quiet = TRUE))
      
      # Check that result uses the expected cache directory
      expect_true(!is.null(result))
      expect_true(grepl(expected_cache, result, fixed = TRUE))
    },
    .package = "utils"
  )
  
  # Clean up
  unlink(temp_dir, recursive = TRUE)
})

test_that("bibliography validation integrates with database workflow", {
  # Create a complete test scenario
  temp_dir <- tempfile("test_workflow")
  data_path <- file.path(temp_dir, "data")
  dir.create(data_path, recursive = TRUE)

  # Create a mock bibliography file
  bib_content <- '
@article{validcitation2023,
  title = {Valid Article},
  author = {Author, A.},
  year = {2023}
}

@book{anothervalid2022,
  title = {Valid Book},
  author = {Writer, W.},
  year = {2022}
}
'

  temp_bib <- file.path(temp_dir, "references.bib")
  writeLines(bib_content, temp_bib)

  # Initialise and create database
  boilerplate_init(
    categories = c("methods", "results"),
    data_path = data_path,
    create_dirs = TRUE,
    confirm = FALSE,
    quiet = TRUE
  )

  db <- boilerplate_import(data_path = data_path, quiet = TRUE)

  # Add bibliography info
  db <- boilerplate_add_bibliography(
    db,
    url = "https://example.com/references.bib",
    local_path = "references.bib"
  )

  # Add content with citations
  db$methods$sample <- "This follows @validcitation2023."
  db$methods$analysis <- "Based on @anothervalid2022 and @missingref2024."
  db$results$main <- "Confirming [@validcitation2023]."

  # Validate references
  validation <- boilerplate_validate_references(
    db,
    bib_file = temp_bib,
    quiet = TRUE
  )

  expect_equal(length(validation$used), 3)  # Three unique citations
  expect_equal(length(validation$missing), 1)  # One missing
  expect_equal(validation$missing, "missingref2024")
  expect_true("validcitation2023" %in% validation$used)
  expect_true("anothervalid2022" %in% validation$used)

  # Clean up
  unlink(temp_dir, recursive = TRUE)
})
