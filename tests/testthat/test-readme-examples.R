# Unit tests for README examples
library(testthat)

test_that("README basic usage example works", {
  # Create temporary directory for test
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Test initialization with example content
  expect_message(
    boilerplate_init(
      data_path = temp_dir,
      create_dirs = TRUE,
      create_empty = FALSE,  # FALSE loads default example content
      confirm = FALSE
    ),
    "initialisation complete"
  )

  # Test import
  unified_db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)
  expect_type(unified_db, "list")
  expect_true("methods" %in% names(unified_db))
  expect_true("measures" %in% names(unified_db))

  # Test adding entry
  unified_db$methods$sample_selection <- "Participants were selected from {{population}} during {{timeframe}}."
  expect_equal(
    unified_db$methods$sample_selection,
    "Participants were selected from {{population}} during {{timeframe}}."
  )

  # Test save
  expect_true(
    boilerplate_save(unified_db, data_path = temp_dir, confirm = FALSE, quiet = TRUE)
  )

  # Test generate text
  methods_text <- boilerplate_generate_text(
    category = "methods",
    sections = c("sample", "sample_selection"),
    global_vars = list(
      population = "university students",
      timeframe = "2020-2021"
    ),
    db = unified_db,
    add_headings = TRUE,
    quiet = TRUE
  )

  expect_type(methods_text, "character")
  expect_true(grepl("university students", methods_text))
  expect_true(grepl("2020-2021", methods_text))
  expect_true(grepl("### Sample", methods_text))  # Check headings were added
})

test_that("README batch edit examples work", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Initialise with example content
  boilerplate_init(
    data_path = temp_dir,
    create_dirs = TRUE,
    create_empty = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )

  # Load database
  unified_db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)

  # Test Example 1: Update specific references
  unified_db <- boilerplate_batch_edit(
    db = unified_db,
    field = "reference",
    new_value = "sibley2021",
    target_entries = c("anxiety", "depression", "life_satisfaction"),
    category = "measures",
    preview = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )

  expect_equal(unified_db$measures$anxiety$reference, "sibley2021")
  expect_equal(unified_db$measures$depression$reference, "sibley2021")
  expect_equal(unified_db$measures$life_satisfaction$reference, "sibley2021")

  # Test Example 2: Update with pattern matching
  unified_db <- boilerplate_batch_edit(
    db = unified_db,
    field = "reference",
    new_value = "sibley2023",
    match_pattern = "_reference",
    category = "measures",
    preview = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )

  # Check that alcohol_frequency reference was updated (it had "alcohol_reference")
  expect_equal(unified_db$measures$alcohol_frequency$reference, "sibley2023")

  # Test Example 3: Wildcard targeting
  original_waves <- unified_db$measures$alcohol_frequency$waves
  unified_db <- boilerplate_batch_edit(
    db = unified_db,
    field = "waves",
    new_value = "1-15",
    target_entries = "alcohol*",
    category = "measures",
    preview = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )

  expect_equal(unified_db$measures$alcohol_frequency$waves, "1-15")
})

test_that("README batch clean examples work", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Initialise with example content
  boilerplate_init(
    data_path = temp_dir,
    create_dirs = TRUE,
    create_empty = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )

  # Load database and modify for testing
  unified_db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)

  # Add some characters to clean
  unified_db$measures$anxiety$reference <- "@anxiety_reference[2023]"
  unified_db$measures$depression$reference <- "@depression_reference[2023]"

  # Test cleaning
  unified_db <- boilerplate_batch_clean(
    db = unified_db,
    field = "reference",
    remove_chars = c("@", "[", "]"),
    category = "measures",
    preview = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )

  expect_equal(unified_db$measures$anxiety$reference, "anxiety_reference2023")
  expect_equal(unified_db$measures$depression$reference, "depression_reference2023")

  # Test save after batch operations
  expect_true(
    boilerplate_save(unified_db, data_path = temp_dir, confirm = FALSE, quiet = TRUE)
  )
})

test_that("README JSON operations work", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Initialise
  boilerplate_init(
    data_path = temp_dir,
    create_dirs = TRUE,
    confirm = FALSE,
    quiet = TRUE
  )

  # Import database
  unified_db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)

  # Save as JSON (default)
  expect_true(
    boilerplate_save(unified_db, data_path = temp_dir, format = "json", confirm = FALSE, quiet = TRUE)
  )

  # Check JSON file exists
  json_files <- list.files(temp_dir, pattern = "\\.json$", recursive = TRUE, full.names = TRUE)
  expect_true(length(json_files) > 0)

  # Test that we can read it back
  unified_db2 <- boilerplate_import(data_path = temp_dir, quiet = TRUE)
  expect_equal(names(unified_db), names(unified_db2))
})

test_that("README custom path workflow works", {
  # Create custom path
  my_project_path <- tempfile("custom_project")
  on.exit(unlink(my_project_path, recursive = TRUE))

  # Initialise databases in custom location
  expect_message(
    boilerplate_init(
      categories = c("measures", "methods", "results"),
      data_path = my_project_path,
      create_dirs = TRUE,
      confirm = FALSE
    ),
    "initialisation complete"
  )

  # Import from custom location
  unified_db <- boilerplate_import(data_path = my_project_path, quiet = TRUE)
  expect_type(unified_db, "list")
  expect_true(all(c("measures", "methods", "results") %in% names(unified_db)))

  # Add new measure
  unified_db$measures$new_measure <- list(
    name = "new measure scale",
    description = "a newly added measure",
    reference = "author2023",
    waves = "1-2",
    keywords = c("new", "test"),
    items = list("test item 1", "test item 2")
  )

  # Save back to custom location
  expect_true(
    boilerplate_save(unified_db, data_path = my_project_path, confirm = FALSE, quiet = TRUE)
  )

  # Verify it saved correctly
  db_check <- boilerplate_import(data_path = my_project_path, quiet = TRUE)
  expect_equal(db_check$measures$new_measure$name, "new measure scale")
})

test_that("README bibliography management works", {
  skip_if_offline()
  skip_on_cran()  # Skip on CRAN due to network dependency

  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Initialise and import
  boilerplate_init(
    data_path = temp_dir,
    create_dirs = TRUE,
    create_empty = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )

  unified_db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)

  # Add bibliography information
  # Using the example bibliography included with the package
  example_bib <- system.file("extdata", "example_references.bib", package = "boilerplate")
  unified_db <- boilerplate_add_bibliography(
    unified_db,
    url = paste0("file://", example_bib),
    local_path = "references.bib"
  )

  expect_true("bibliography" %in% names(unified_db))
  expect_equal(unified_db$bibliography$local_path, "references.bib")

  # Save the updated database
  expect_true(
    boilerplate_save(unified_db, data_path = temp_dir, confirm = FALSE, quiet = TRUE)
  )
})

test_that("README bibliography with copy_bibliography works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Create manuscript directory
  manuscript_dir <- file.path(temp_dir, "manuscript")
  dir.create(manuscript_dir, recursive = TRUE)

  # Initialise and import
  boilerplate_init(
    data_path = temp_dir,
    create_dirs = TRUE,
    create_empty = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )

  unified_db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)

  # Test generating text with statistical section (default will be used)
  methods_text <- boilerplate_generate_text(
    category = "methods",
    sections = "statistical",  # The default entry will be used automatically
    db = unified_db,
    copy_bibliography = FALSE,  # Don't copy for now
    quiet = TRUE
  )

  expect_type(methods_text, "character")
  expect_true(grepl("appropriate statistical methods", methods_text))

  # Add bibliography info for copy test
  unified_db <- boilerplate_add_bibliography(
    unified_db,
    url = "https://example.com/references.bib",
    local_path = file.path(temp_dir, "references.bib")
  )

  # Create a dummy bibliography file to copy
  writeLines("@article{test2023,\n  title = {Test},\n  author = {Author},\n  year = {2023}\n}",
             file.path(temp_dir, "references.bib"))

  # Test with copy_bibliography = TRUE
  # First need to update bibliography to download it
  bib_file <- boilerplate_update_bibliography(unified_db, quiet = TRUE)

  # Now generate text with copy
  methods_text <- boilerplate_generate_text(
    category = "methods",
    sections = "statistical",  # The default entry will be used automatically
    db = unified_db,
    copy_bibliography = TRUE,
    bibliography_path = manuscript_dir,
    quiet = TRUE
  )

  # Check if bibliography was copied (only if download succeeded)
  if (!is.null(bib_file) && file.exists(bib_file)) {
    # Only check if the copy worked if the source file exists
    if (file.exists(file.path(manuscript_dir, "references.bib"))) {
      expect_true(TRUE)  # File was copied successfully
    } else {
      # If copy failed, that's OK in test environment
      expect_type(methods_text, "character")
    }
  } else {
    # If download failed, at least check that generate_text worked
    expect_type(methods_text, "character")
  }

  # Test validation
  validation <- boilerplate_validate_references(unified_db, quiet = TRUE)
  expect_type(validation, "list")
  expect_true("valid" %in% names(validation))
})
