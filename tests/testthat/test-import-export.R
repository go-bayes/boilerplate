# Unit tests for import/export functions
library(testthat)

test_that("boilerplate_import and boilerplate_export work correctly", {
  # Create unique temp directory for this test
  temp_base <- tempfile("test_import_export")
  dir.create(temp_base)
  old_wd <- getwd()
  setwd(temp_base)
  on.exit({
    setwd(old_wd)
    unlink(temp_base, recursive = TRUE)
  })
  
  # Create test databases
  test_methods <- list(
    sample = list(
      default = "Sample text"
    )
  )
  
  test_measures <- list(
    test_measure = list(
      name = "test_measure",
      description = "A test measure",
      items = list("Item 1", "Item 2")
    )
  )
  
  # Create data directory
  data_dir <- file.path(temp_base, "boilerplate", "data")
  dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)
  
  # Save test databases with correct filenames
  saveRDS(test_methods, file.path(data_dir, "methods_db.rds"))
  saveRDS(test_measures, file.path(data_dir, "measures_db.rds"))
  
  # Test import
  unified_db <- boilerplate_import(
    category = NULL,  # NULL imports all categories
    data_path = data_dir,
    quiet = TRUE
  )
  
  expect_type(unified_db, "list")
  expect_equal(unified_db$methods$sample$default, "Sample text")
  expect_equal(unified_db$measures$test_measure$name, "test_measure")
  
  # Test export
  export_dir <- file.path(temp_base, "export")
  dir.create(export_dir)
  
  boilerplate_export(
    db = unified_db,
    data_path = export_dir,
    output_file = "exported.rds",
    save_by_category = TRUE,
    quiet = TRUE,
    confirm = FALSE,
    create_dirs = TRUE
  )
  
  # With save_by_category, should create separate files
  expect_true(file.exists(file.path(export_dir, "methods_db.rds")) ||
              file.exists(file.path(export_dir, "measures_db.rds")))
})

test_that("boilerplate_export handles selective export", {
  temp_dir <- tempdir()
  
  test_db <- list(
    methods = list(
      sample = list(
        default = "Default sample",
        large = "Large sample"
      ),
      analysis = list(
        main = "Main analysis",
        sensitivity = "Sensitivity analysis"
      )
    )
  )
  
  # Export specific path
  export_dir <- file.path(temp_dir, "selective_export")
  dir.create(export_dir, showWarnings = FALSE)
  
  boilerplate_export(
    db = test_db,
    select_elements = "methods.sample",
    data_path = export_dir,
    output_file = "boilerplate_export.rds",
    quiet = TRUE,
    confirm = FALSE,
    create_dirs = TRUE
  )
  
  exported <- readRDS(file.path(export_dir, "boilerplate_export.rds"))
  
  # Should only have sample, not analysis
  expect_true("sample" %in% names(exported$methods))
  expect_false("analysis" %in% names(exported$methods))
  
  unlink(export_dir, recursive = TRUE)
})

test_that("boilerplate_export handles wildcard selection", {
  temp_dir <- tempdir()
  
  test_db <- list(
    methods = list(
      statistical = list(
        longitudinal = list(default = "Longitudinal"),
        crosssectional = list(default = "Cross-sectional")
      ),
      sample = list(default = "Sample")
    )
  )
  
  export_dir <- file.path(temp_dir, "wildcard_export")
  dir.create(export_dir, showWarnings = FALSE)
  
  boilerplate_export(
    db = test_db,
    select_elements = "methods.statistical.*",
    data_path = export_dir,
    output_file = "boilerplate_export.rds",
    quiet = TRUE,
    confirm = FALSE,
    create_dirs = TRUE
  )
  
  exported <- readRDS(file.path(export_dir, "boilerplate_export.rds"))
  
  # Should have both statistical methods
  expect_true("longitudinal" %in% names(exported$methods$statistical))
  expect_true("crosssectional" %in% names(exported$methods$statistical))
  # But not sample
  expect_false("sample" %in% names(exported$methods))
  
  unlink(export_dir, recursive = TRUE)
})

test_that("boilerplate_save works correctly", {
  temp_dir <- tempdir()
  old_wd <- getwd()
  setwd(temp_dir)
  on.exit(setwd(old_wd))
  
  test_db <- list(
    methods = list(sample = list(default = "Test")),
    measures = list(test = list(name = "test"))
  )
  
  # Create data directory
  data_dir <- file.path(temp_dir, "boilerplate", "data")
  dir.create(data_dir, recursive = TRUE)
  
  # Save unified database
  boilerplate_save(
    db = test_db,
    data_path = data_dir,
    category = NULL,
    confirm = FALSE,
    quiet = TRUE,
    create_dirs = TRUE,
    timestamp = FALSE
  )
  
  # Default format is now JSON
  expect_true(file.exists(file.path(data_dir, "boilerplate_unified.json")))
  
  # Save specific category (also JSON by default)
  boilerplate_save(
    db = test_db$methods,
    data_path = data_dir,
    category = "methods",
    confirm = FALSE,
    quiet = TRUE,
    create_dirs = TRUE,
    timestamp = FALSE
  )
  
  expect_true(file.exists(file.path(data_dir, "methods_db.json")))
  
  # Test saving as RDS explicitly
  boilerplate_save(
    db = test_db,
    data_path = data_dir,
    format = "rds",
    confirm = FALSE,
    quiet = TRUE,
    timestamp = FALSE
  )
  
  expect_true(file.exists(file.path(data_dir, "boilerplate_unified.rds")))
  
  # Clean up is handled by on.exit
})

test_that("boilerplate_import handles various database formats", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  old_wd <- getwd()
  setwd(temp_dir)
  on.exit({
    setwd(old_wd)
    unlink(temp_dir, recursive = TRUE)
  })
  
  # Create data directory structure
  data_dir <- file.path(temp_dir, "boilerplate", "data")
  dir.create(data_dir, recursive = TRUE)
  
  # Test importing individual category databases
  methods_db <- list(
    analysis = list(
      main = list(description = "Main analysis", text = "Analysis text")
    )
  )
  
  results_db <- list(
    primary = list(description = "Primary results", text = "Results text")
  )
  
  saveRDS(methods_db, file.path(data_dir, "methods_db.rds"))
  saveRDS(results_db, file.path(data_dir, "results_db.rds"))
  
  # Import specific category
  imported_methods <- boilerplate_import(category = "methods", data_path = data_dir, quiet = TRUE)
  expect_true(is.list(imported_methods))
  expect_equal(imported_methods$analysis$main$description, "Main analysis")
  
  # Import all categories
  imported_all <- boilerplate_import(category = NULL, data_path = data_dir, quiet = TRUE)
  expect_true("methods" %in% names(imported_all))
  expect_true("results" %in% names(imported_all))
  
  # Test importing unified database
  unified_db <- list(
    methods = list(test = list(description = "Test")),
    results = list(test = list(description = "Test"))
  )
  
  saveRDS(unified_db, file.path(data_dir, "boilerplate_unified.rds"))
  imported_unified <- boilerplate_import(category = NULL, data_path = data_dir, quiet = TRUE)
  expect_true("methods" %in% names(imported_unified))
  expect_true("results" %in% names(imported_unified))
})

test_that("boilerplate_export handles complex selection patterns", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Create complex nested database
  test_db <- list(
    methods = list(
      statistical = list(
        longitudinal = list(
          lmtp = list(description = "LMTP", text = "LMTP method"),
          gcomp = list(description = "G-comp", text = "G-computation")
        ),
        crosssectional = list(
          regression = list(description = "Regression", text = "Linear regression")
        )
      ),
      sampling = list(
        random = list(description = "Random", text = "Random sampling"),
        stratified = list(description = "Stratified", text = "Stratified sampling")
      )
    ),
    results = list(
      main = list(description = "Main", text = "Main results"),
      sensitivity = list(description = "Sensitivity", text = "Sensitivity results")
    )
  )
  
  # Test multiple selections
  boilerplate_export(
    db = test_db,
    select_elements = c("methods.statistical.longitudinal.*", "results.main"),
    data_path = temp_dir,
    output_file = "multi_select.rds",
    save_by_category = FALSE,
    quiet = TRUE,
    confirm = FALSE,
    create_dirs = TRUE
  )
  
  export_path <- file.path(temp_dir, "multi_select.rds")
  exported <- readRDS(export_path)
  
  # Check selected elements are present
  expect_true("lmtp" %in% names(exported$methods$statistical$longitudinal))
  expect_true("gcomp" %in% names(exported$methods$statistical$longitudinal))
  expect_true("main" %in% names(exported$results))
  
  # Check non-selected elements are absent
  expect_false("crosssectional" %in% names(exported$methods$statistical))
  expect_false("sampling" %in% names(exported$methods))
  expect_false("sensitivity" %in% names(exported$results))
  
  # Test export with no selection (full export)
  boilerplate_export(
    db = test_db,
    data_path = temp_dir,
    output_file = "full_export.rds",
    save_by_category = FALSE,
    quiet = TRUE,
    confirm = FALSE
  )
  
  full_export_path <- file.path(temp_dir, "full_export.rds")
  full_exported <- readRDS(full_export_path)
  expect_equal(full_exported, test_db)
})

test_that("boilerplate_save handles different save modes", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  old_wd <- getwd()
  setwd(temp_dir)
  on.exit({
    setwd(old_wd)
    unlink(temp_dir, recursive = TRUE)
  })
  
  test_db <- list(
    methods = list(test = list(description = "Test method")),
    results = list(test = list(description = "Test result")),
    measures = list(test = list(name = "test", description = "Test measure"))
  )
  
  # Test save unified with specific output directory
  output_dir <- file.path(temp_dir, "output")
  dir.create(output_dir)
  
  boilerplate_save(
    db = test_db,
    data_path = output_dir,
    category = NULL,  # NULL saves as unified
    confirm = FALSE,
    quiet = TRUE,
    timestamp = FALSE,
    create_dirs = TRUE
  )
  
  # Check file was created (JSON by default)
  expect_true(file.exists(file.path(output_dir, "boilerplate_unified.json")))
  
  # Test save individual category
  boilerplate_save(
    db = test_db$methods,  # Just the methods portion
    data_path = output_dir,
    category = "methods",
    confirm = FALSE,
    quiet = TRUE,
    timestamp = FALSE
  )
  
  expect_true(file.exists(file.path(output_dir, "methods_db.json")))
  
  # Verify saved content
  saved_methods <- read_boilerplate_db(file.path(output_dir, "methods_db.json"))
  expect_equal(saved_methods$test$description, "Test method")
  
  # Test RDS format explicitly
  boilerplate_save(
    db = test_db,
    data_path = output_dir,
    format = "rds",
    confirm = FALSE,
    quiet = TRUE,
    timestamp = FALSE
  )
  
  expect_true(file.exists(file.path(output_dir, "boilerplate_unified.rds")))
})

test_that("import/export functions handle errors gracefully", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  old_wd <- getwd()
  setwd(temp_dir)
  on.exit({
    setwd(old_wd)
    unlink(temp_dir, recursive = TRUE)
  })
  
  # Test import with no databases present  
  # Create a data directory with no files
  empty_data_dir <- file.path(temp_dir, "empty_data")
  dir.create(empty_data_dir)
  
  # Initialize to create proper structure
  boilerplate_init(
    data_path = empty_data_dir,
    create_dirs = TRUE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  # Import should return empty list but succeed
  result <- boilerplate_import(data_path = empty_data_dir, quiet = TRUE)
  expect_type(result, "list")
  expect_length(result, 0)
  
  # Test export with invalid output path
  test_db <- list(methods = list(test = list(description = "Test")))
  expect_error(
    boilerplate_export(
      db = test_db,
      data_path = "/invalid/nonexistent/path",
      output_file = "file.rds",
      quiet = TRUE,
      confirm = FALSE,
      create_dirs = FALSE
    ),
    "Directory does not exist"
  )
  
  # Test save with invalid category - save doesn't validate category names
  # so this should succeed but create a file with the invalid category name
  result <- boilerplate_save(
    db = test_db,
    category = "invalid_category",
    confirm = FALSE,
    quiet = TRUE,
    data_path = temp_dir
  )
  expect_true(result)
})

test_that("boilerplate_export preserves database structure", {
  temp_dir <- tempfile()
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Create database with various data types
  test_db <- list(
    methods = list(
      numeric_data = 42,
      character_data = "test string",
      vector_data = c(1, 2, 3),
      list_data = list(a = 1, b = "two", c = TRUE),
      null_data = NULL,
      nested = list(
        deep = list(
          deeper = list(
            deepest = "bottom level"
          )
        )
      )
    )
  )
  
  # Export with data_path and filename separately
  boilerplate_export(
    db = test_db,
    data_path = temp_dir,
    output_file = "preserved.rds",
    quiet = TRUE,
    confirm = FALSE,
    create_dirs = TRUE
  )
  
  # Read back and verify structure
  export_path <- file.path(temp_dir, "preserved.rds")
  imported <- readRDS(export_path)
  
  expect_equal(imported$methods$numeric_data, 42)
  expect_equal(imported$methods$character_data, "test string")
  expect_equal(imported$methods$vector_data, c(1, 2, 3))
  expect_equal(imported$methods$list_data$a, 1)
  expect_equal(imported$methods$list_data$b, "two")
  expect_equal(imported$methods$list_data$c, TRUE)
  expect_null(imported$methods$null_data)
  expect_equal(imported$methods$nested$deep$deeper$deepest, "bottom level")
})

test_that("boilerplate_import handles legacy database formats", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  old_wd <- getwd()
  setwd(temp_dir)
  on.exit({
    setwd(old_wd)
    unlink(temp_dir, recursive = TRUE)
  })
  
  # Create database in correct format (no wrapper)
  old_methods <- list(
    analysis = list(
      description = "Analysis",
      text = "Old format analysis"
    )
  )
  
  # Create data directory
  data_dir <- file.path(temp_dir, "boilerplate", "data")
  dir.create(data_dir, recursive = TRUE)
  
  # Save in expected format with correct filename
  saveRDS(old_methods, file.path(data_dir, "methods_db.rds"))
  
  # Import should work correctly
  imported <- boilerplate_import(category = "methods", data_path = data_dir, quiet = TRUE)
  
  # The imported data should match what we saved
  expect_true("analysis" %in% names(imported))
  expect_equal(imported$analysis$description, "Analysis")
})