# Unit tests for batch edit functions
library(testthat)

test_that("boilerplate_batch_edit updates fields correctly", {
  test_db <- list(
    measures = list(
      anxiety_1 = list(name = "anxiety_1", reference = "old_ref"),
      anxiety_2 = list(name = "anxiety_2", reference = "old_ref"),
      depression = list(name = "depression", reference = "other_ref")
    )
  )

  # Update specific entries
  updated_db <- boilerplate_batch_edit(
    db = test_db,
    field = "reference",
    new_value = "new_ref_2023",
    target_entries = c("anxiety_1", "anxiety_2"),
    category = "measures",
    preview = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )

  expect_equal(updated_db$measures$anxiety_1$reference, "new_ref_2023")
  expect_equal(updated_db$measures$anxiety_2$reference, "new_ref_2023")
  expect_equal(updated_db$measures$depression$reference, "other_ref")
})

test_that("boilerplate_batch_edit handles wildcard patterns", {
  test_db <- list(
    measures = list(
      anxiety_gad7 = list(name = "anxiety_gad7", reference = "old"),
      anxiety_phq = list(name = "anxiety_phq", reference = "old"),
      depression_phq9 = list(name = "depression_phq9", reference = "old")
    )
  )

  # Update with wildcard
  updated_db <- boilerplate_batch_edit(
    db = test_db,
    field = "reference",
    new_value = "updated_ref",
    target_entries = "anxiety*",
    category = "measures",
    confirm = FALSE,
    quiet = TRUE
  )

  expect_equal(updated_db$measures$anxiety_gad7$reference, "updated_ref")
  expect_equal(updated_db$measures$anxiety_phq$reference, "updated_ref")
  expect_equal(updated_db$measures$depression_phq9$reference, "old")
})

test_that("boilerplate_batch_clean removes characters correctly", {
  test_db <- list(
    measures = list(
      test1 = list(description = "This is a @test@ description"),
      test2 = list(description = "Another @example@ here")
    )
  )

  # Remove @ characters
  cleaned_db <- boilerplate_batch_clean(
    db = test_db,
    field = "description",
    remove_chars = c("@"),
    category = "measures",
    confirm = FALSE,
    quiet = TRUE
  )

  expect_equal(cleaned_db$measures$test1$description, "This is a test description")
  expect_equal(cleaned_db$measures$test2$description, "Another example here")
})

test_that("boilerplate_batch_clean handles replacements", {
  test_db <- list(
    measures = list(
      test1 = list(reference = "Smith_2023"),
      test2 = list(reference = "Jones_2022")
    )
  )

  # Replace underscores with spaces
  cleaned_db <- boilerplate_batch_clean(
    db = test_db,
    field = "reference",
    replace_pairs = list("_" = " "),
    category = "measures",
    confirm = FALSE,
    quiet = TRUE
  )

  expect_equal(cleaned_db$measures$test1$reference, "Smith 2023")
  expect_equal(cleaned_db$measures$test2$reference, "Jones 2022")
})

test_that("boilerplate_batch_edit_multi updates multiple fields", {
  test_db <- list(
    measures = list(
      test_measure = list(
        name = "test_measure",
        reference = "old_ref",
        waves = "1-3"
      )
    )
  )

  # Update multiple fields at once
  updated_db <- boilerplate_batch_edit_multi(
    db = test_db,
    edits = list(
      list(
        field = "reference",
        new_value = "new_ref_2023",
        target_entries = "test_measure"
      ),
      list(
        field = "waves",
        new_value = "1-5",
        target_entries = "test_measure"
      )
    ),
    category = "measures",
    confirm = FALSE,
    quiet = TRUE
  )

  expect_equal(updated_db$measures$test_measure$reference, "new_ref_2023")
  expect_equal(updated_db$measures$test_measure$waves, "1-5")
  expect_equal(updated_db$measures$test_measure$name, "test_measure")  # Unchanged
})

test_that("boilerplate_find_chars finds special characters", {
  test_db <- list(
    measures = list(
      test1 = list(
        description = "This has @special@ characters",
        reference = "Normal reference"
      ),
      test2 = list(
        description = "This has [brackets]"
      )
    )
  )

  # Find @ characters
  result <- boilerplate_find_chars(
    db = test_db,
    field = "description",
    chars = "@",
    category = "measures"
  )
  expect_true("test1" %in% names(result))
  expect_true(grepl("@special@", result$test1))

  # Find brackets
  result2 <- boilerplate_find_chars(
    db = test_db,
    field = "description",
    chars = "[",
    category = "measures"
  )
  expect_true("test2" %in% names(result2))
  expect_true(grepl("\\[brackets\\]", result2$test2))
})

test_that("batch edit functions handle complex database structures", {
  # Create deeply nested database
  complex_db <- list(
    methods = list(
      statistical = list(
        longitudinal = list(
          lmtp = list(
            description = "LMTP with @old@ notation",
            reference = "old_ref_2020"
          ),
          gcomp = list(
            description = "G-comp with @old@ style",
            reference = "old_ref_2019"
          )
        ),
        crosssectional = list(
          regression = list(
            description = "Standard regression",
            reference = "smith_2021"
          )
        )
      )
    ),
    measures = list(
      demographics = list(
        age = list(
          description = "Age in @years@",
          type = "continuous"
        ),
        gender = list(
          description = "Gender @categories@",
          type = "categorical"
        )
      )
    )
  )

  # Test batch edit on nested paths - need to specify category for unified db
  updated_db <- boilerplate_batch_edit(
    db = complex_db,
    field = "reference",
    new_value = "updated_2023",
    target_entries = c("lmtp", "gcomp"),
    category = "methods",
    preview = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )

  expect_equal(
    updated_db$methods$statistical$longitudinal$lmtp$reference,
    "updated_2023"
  )
  expect_equal(
    updated_db$methods$statistical$longitudinal$gcomp$reference,
    "updated_2023"
  )
  expect_equal(
    updated_db$methods$statistical$crosssectional$regression$reference,
    "smith_2021"  # Unchanged
  )

  # Test batch clean for methods category
  cleaned_methods <- boilerplate_batch_clean(
    db = complex_db,
    field = "description",
    remove_chars = "@",
    category = "methods",
    confirm = FALSE,
    quiet = TRUE
  )

  expect_equal(
    cleaned_methods$methods$statistical$longitudinal$lmtp$description,
    "LMTP with old notation"
  )

  # Test batch clean for measures category
  cleaned_measures <- boilerplate_batch_clean(
    db = complex_db,
    field = "description",
    remove_chars = "@",
    category = "measures",
    confirm = FALSE,
    quiet = TRUE
  )

  expect_equal(
    cleaned_measures$measures$demographics$age$description,
    "Age in years"
  )
})

test_that("boilerplate_batch_edit handles edge cases", {
  # Empty database
  empty_db <- list(measures = list())

  result <- boilerplate_batch_edit(
    db = empty_db,
    field = "reference",
    new_value = "new",
    target_entries = "*",
    category = "measures",
    confirm = FALSE,
    quiet = TRUE
  )

  expect_equal(result, empty_db)

  # Non-existent field
  test_db <- list(
    measures = list(
      test1 = list(name = "test1", description = "Test")
    )
  )

  # batch_edit only updates existing fields, doesn't add new ones
  result <- boilerplate_batch_edit(
    db = test_db,
    field = "reference",
    new_value = "new_value",
    target_entries = "test1",
    category = "measures",
    confirm = FALSE,
    quiet = TRUE
  )

  # Field doesn't exist so nothing should change
  expect_equal(result, test_db)

  # Add a reference field and test update
  test_db$measures$test1$reference <- "old_ref"
  result2 <- boilerplate_batch_edit(
    db = test_db,
    field = "reference",
    new_value = "new_ref",
    target_entries = "test1",
    category = "measures",
    confirm = FALSE,
    quiet = TRUE
  )

  expect_equal(result2$measures$test1$reference, "new_ref")
})

test_that("boilerplate_batch_clean handles multiple replacements", {
  test_db <- list(
    methods = list(
      sample = list(
        description = "Sample_size:_N=100;_power=0.80"
      )
    )
  )

  # Multiple replacements
  cleaned_db <- boilerplate_batch_clean(
    db = test_db,
    field = "description",
    replace_pairs = list(
      "_" = " ",
      ":" = ":",
      ";" = ","
    ),
    category = "methods",
    confirm = FALSE,
    quiet = TRUE
  )

  expect_equal(
    cleaned_db$methods$sample$description,
    "Sample size: N=100, power=0.80"
  )
})

test_that("boilerplate_batch_edit_multi handles sequential edits correctly", {
  test_db <- list(
    measures = list(
      scale1 = list(
        name = "scale1",
        description = "Original description",
        reference = "old_ref",
        items = list("Item 1", "Item 2"),
        keywords = "original,keywords"
      ),
      scale2 = list(
        name = "scale2",
        description = "Another description",
        reference = "old_ref",
        keywords = "original,keywords"
      )
    )
  )

  # Multiple edits with different targets
  edits <- list(
    list(
      field = "reference",
      new_value = "smith2023",
      target_entries = "*"  # All entries
    ),
    list(
      field = "description",
      new_value = "Updated description for scale1",
      target_entries = "scale1"  # Specific entry
    ),
    list(
      field = "keywords",
      new_value = "psychometric,validated",
      target_entries = c("scale1", "scale2")
    )
  )

  result <- boilerplate_batch_edit_multi(
    db = test_db,
    edits = edits,
    category = "measures",
    confirm = FALSE,
    quiet = TRUE
  )

  # Check all edits applied correctly
  expect_equal(result$measures$scale1$reference, "smith2023")
  expect_equal(result$measures$scale2$reference, "smith2023")
  expect_equal(result$measures$scale1$description, "Updated description for scale1")
  expect_equal(result$measures$scale2$description, "Another description")
  expect_equal(result$measures$scale1$keywords, "psychometric,validated")
  expect_equal(result$measures$scale2$keywords, "psychometric,validated")
})

test_that("boilerplate_find_chars handles regex special characters", {
  test_db <- list(
    methods = list(
      test1 = list(
        description = "Cost is $100.50 (approx.)"
      ),
      test2 = list(
        description = "Significance level: p < .05*"
      ),
      test3 = list(
        description = "Range [0-100] with mean±SD"
      )
    )
  )

  # Find dollar signs
  result1 <- boilerplate_find_chars(
    db = test_db,
    field = "description",
    chars = "$",
    category = "methods"
  )
  expect_true("test1" %in% names(result1))

  # Find asterisks
  result2 <- boilerplate_find_chars(
    db = test_db,
    field = "description",
    chars = "*",
    category = "methods"
  )
  expect_true("test2" %in% names(result2))

  # Find brackets
  result3 <- boilerplate_find_chars(
    db = test_db,
    field = "description",
    chars = c("[", "]"),
    category = "methods"
  )
  expect_true("test3" %in% names(result3))

  # Find multiple characters
  result4 <- boilerplate_find_chars(
    db = test_db,
    field = "description",
    chars = c("$", "*", "["),
    category = "methods"
  )
  expect_equal(length(result4), 3)
})

test_that("batch edit functions work with loaded databases", {
  # Create test database - batch edit functions work with database objects, not file paths
  test_db <- list(
    measures = list(
      test_measure = list(
        name = "test_measure",
        description = "Original @description@",
        reference = "old_ref"
      )
    )
  )

  # Test batch edit with database object
  updated_db <- boilerplate_batch_edit(
    db = test_db,
    field = "reference",
    new_value = "new_ref_2023",
    target_entries = "test_measure",
    category = "measures",
    confirm = FALSE,
    quiet = TRUE
  )

  expect_equal(
    updated_db$measures$test_measure$reference,
    "new_ref_2023"
  )

  # Test batch clean
  cleaned_db <- boilerplate_batch_clean(
    db = updated_db,
    field = "description",
    remove_chars = "@",
    category = "measures",
    confirm = FALSE,
    quiet = TRUE
  )

  expect_equal(
    cleaned_db$measures$test_measure$description,
    "Original description"
  )
})

test_that("batch edit loads JSON file paths but rejects RDS file paths", {
  skip_if_not_installed("jsonlite")

  test_db <- list(
    measures = list(
      test_measure = list(
        name = "test_measure",
        description = "Original description",
        reference = "old_ref"
      )
    )
  )

  temp_dir <- tempfile("batch_edit_files")
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  json_file <- file.path(temp_dir, "boilerplate_unified.json")
  rds_file <- file.path(temp_dir, "boilerplate_unified.rds")
  jsonlite::write_json(test_db, json_file, auto_unbox = TRUE, pretty = TRUE)
  saveRDS(test_db, rds_file)

  updated_db <- boilerplate_batch_edit(
    db = json_file,
    field = "reference",
    new_value = "new_ref_2026",
    target_entries = "test_measure",
    category = "measures",
    confirm = FALSE,
    quiet = TRUE
  )
  expect_equal(updated_db$measures$test_measure$reference, "new_ref_2026")

  expect_error(
    boilerplate_batch_edit(
      db = rds_file,
      field = "reference",
      new_value = "new_ref_2026",
      target_entries = "test_measure",
      category = "measures",
      confirm = FALSE,
      quiet = TRUE
    ),
    "only loads JSON file paths directly"
  )
})

test_that("batch edit preview mode works correctly", {
  test_db <- list(
    measures = list(
      test1 = list(reference = "old1"),
      test2 = list(reference = "old2")
    )
  )

  # Test preview mode (should not modify database)
  result <- boilerplate_batch_edit(
    db = test_db,
    field = "reference",
    new_value = "new_ref",
    target_entries = "*",
    category = "measures",
    preview = TRUE,
    confirm = FALSE,
    quiet = TRUE
  )

  # Database should be unchanged
  expect_equal(result$measures$test1$reference, "old1")
  expect_equal(result$measures$test2$reference, "old2")
})
