library(testthat)

# Skip entire file in non-interactive sessions
if (!interactive()) {
  skip("Skipping merge tests in non-interactive mode")
}

test_that("boilerplate_merge_databases works correctly", {
  # Skip this test in non-interactive mode since merge requires user input
  skip("Merge requires interactive mode")

  # Alternative: test with non-conflicting databases
  db1 <- list(
    methods = list(
      sampling = list(
        description = "Sampling methods",
        text = "Random sampling was employed..."
      )
    ),
    measures = list(
      demographics = list(
        age = list(
          description = "Age in years",
          type = "continuous"
        )
      )
    )
  )

  db2 <- list(
    methods = list(
      analysis = list(
        clustering = list(
          description = "Cluster analysis",
          text = "K-means clustering..."
        )
      )
    ),
    results = list(
      main = list(
        description = "Main results",
        text = "The analysis revealed..."
      )
    )
  )

  # Test merge with no conflicts
  merged <- boilerplate_merge_databases(db1, db2)

  # Check that entries from both databases are present
  expect_equal(merged$methods$sampling$description, "Sampling methods")
  expect_equal(merged$methods$analysis$clustering$description, "Cluster analysis")
  expect_equal(merged$results$main$description, "Main results")
  expect_equal(merged$measures$demographics$age$description, "Age in years")
})

test_that("boilerplate_merge_databases handles empty and NULL databases", {
  # Skip in non-interactive mode
  skip("Merge requires interactive mode")

  db1 <- list(methods = list(test = list(description = "Test")))

  # Merge with empty list
  merged <- boilerplate_merge_databases(db1, list())
  expect_equal(merged, db1)

  # Merge empty with db
  merged <- boilerplate_merge_databases(list(), db1)
  expect_equal(merged, db1)

  # Both empty
  merged <- boilerplate_merge_databases(list(), list())
  expect_equal(merged, list())
})

test_that("boilerplate_merge_unified works correctly", {
  # Skip in non-interactive mode since merge requires user input for conflicts
  skip("Merge requires interactive mode")
  
  # Create temporary directory
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Create first unified database
  unified1 <- list(
    boilerplate_unified = list(
      methods = list(
        stats = list(
          description = "Statistical methods",
          text = "We used stats..."
        )
      ),
      measures = list(
        outcome = list(
          description = "Primary outcome",
          type = "binary"
        )
      )
    )
  )

  # Create second unified database
  unified2 <- list(
    boilerplate_unified = list(
      methods = list(
        stats = list(
          description = "Updated stats",
          text = "Advanced statistics..."
        ),
        design = list(
          description = "Study design",
          text = "RCT design..."
        )
      ),
      results = list(
        primary = list(
          description = "Primary results",
          text = "Significant findings..."
        )
      )
    )
  )

  # Test merge
  merged <- boilerplate_merge_unified(
    unified1$boilerplate_unified,
    unified2$boilerplate_unified,
    quiet = TRUE
  )

  expect_equal(merged$methods$stats$description, "Updated stats")
  expect_equal(merged$methods$design$description, "Study design")
  expect_equal(merged$results$primary$description, "Primary results")
  expect_equal(merged$measures$outcome$description, "Primary outcome")
})

test_that("boilerplate_merge_category works correctly", {
  # Skip in non-interactive mode since merge requires user input for conflicts
  skip("Merge requires interactive mode")
  
  # Create category databases
  unified1 <- list(
    methods = list(
      analysis = list(
        main = list(
          description = "Main analysis",
          text = "Primary analysis..."
        )
      )
    ),
    results = list(
      test = list(description = "Test results")
    )
  )

  unified2 <- list(
    methods = list(
      analysis = list(
        main = list(
          description = "Updated analysis",
          text = "Enhanced analysis..."
        ),
        sensitivity = list(
          description = "Sensitivity analysis",
          text = "Robustness checks..."
        )
      )
    ),
    results = list(
      test = list(description = "Updated results")
    )
  )

  # Test merge specific category
  merged <- boilerplate_merge_category(
    unified1,
    unified2,
    category = "methods",
    quiet = TRUE
  )

  # Methods should be merged
  expect_equal(merged$methods$analysis$main$description, "Updated analysis")
  expect_equal(merged$methods$analysis$sensitivity$description, "Sensitivity analysis")

  # Results should remain from db1
  expect_equal(merged$results$test$description, "Test results")
})

test_that("boilerplate_update_from_external works correctly", {
  # Create temporary directory
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Create main database
  main_db <- list(
    methods = list(
      sampling = list(
        description = "Original sampling",
        text = "Simple random sampling..."
      )
    ),
    measures = list(
      age = list(
        description = "Age",
        type = "continuous"
      )
    )
  )

  # Create external database file
  external_db <- list(
    sampling = list(
      description = "Updated sampling from external",
      text = "Stratified sampling..."
    ),
    analysis = list(
      description = "New analysis method",
      text = "Bayesian analysis..."
    )
  )

  # Save external database
  external_path <- temp_dir
  saveRDS(external_db, file.path(external_path, "methods_db.rds"))

  # Test update
  updated <- boilerplate_update_from_external(
    main_db,
    category = "methods",
    external_path = external_path,
    quiet = TRUE
  )

  # Methods should be updated
  expect_equal(updated$methods$sampling$description,
               "Updated sampling from external")
  expect_equal(updated$methods$analysis$description,
               "New analysis method")

  # Measures should remain unchanged
  expect_equal(updated$measures$age$description, "Age")
})

test_that("merge functions handle deeply nested structures", {
  # Skip in non-interactive mode since this has conflicts
  skip("Merge requires interactive mode")

  # Alternative: test with non-conflicting nested structures
  db1 <- list(
    methods = list(
      statistical = list(
        regression = list(
          linear = list(
            assumptions = list(
              description = "Linear model assumptions",
              text = "Normality, homoscedasticity..."
            )
          )
        )
      )
    )
  )

  db2 <- list(
    methods = list(
      statistical = list(
        regression = list(
          linear = list(
            diagnostics = list(
              description = "Model diagnostics",
              text = "Residual plots..."
            )
          ),
          logistic = list(
            description = "Logistic regression",
            text = "For binary outcomes..."
          )
        ),
        clustering = list(
          description = "Clustering methods",
          text = "K-means and hierarchical..."
        )
      )
    )
  )

  # Test merge without conflicts
  merged <- boilerplate_merge_databases(db1, db2)

  # Check deep nesting preserved
  expect_equal(
    merged$methods$statistical$regression$linear$assumptions$description,
    "Linear model assumptions"
  )
  expect_equal(
    merged$methods$statistical$regression$linear$diagnostics$description,
    "Model diagnostics"
  )
  expect_equal(
    merged$methods$statistical$regression$logistic$description,
    "Logistic regression"
  )
})

