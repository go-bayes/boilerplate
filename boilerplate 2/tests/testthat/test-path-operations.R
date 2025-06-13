library(testthat)

test_that("boilerplate_path_exists works correctly", {
  # Create test database
  test_db <- list(
    methods = list(
      analysis = list(
        regression = list(
          linear = list(
            description = "Linear regression",
            text = "We used linear models..."
          )
        ),
        clustering = list(
          description = "Cluster analysis",
          text = "K-means was applied..."
        )
      ),
      sampling = list(
        description = "Sampling procedure",
        text = "Random sampling..."
      )
    ),
    results = list(
      main = list(
        findings = list(
          description = "Main findings",
          text = "Significant effects..."
        )
      )
    )
  )

  # Test existing paths
  expect_true(boilerplate_path_exists(test_db, "methods"))
  expect_true(boilerplate_path_exists(test_db, "methods.analysis"))
  expect_true(boilerplate_path_exists(test_db, "methods.analysis.regression"))
  expect_true(boilerplate_path_exists(test_db, "methods.analysis.regression.linear"))
  expect_true(boilerplate_path_exists(test_db, "results.main.findings"))

  # Test non-existing paths
  expect_false(boilerplate_path_exists(test_db, "nonexistent"))
  expect_false(boilerplate_path_exists(test_db, "methods.nonexistent"))
  expect_false(boilerplate_path_exists(test_db, "methods.analysis.nonexistent"))
  expect_false(boilerplate_path_exists(test_db, "results.main.findings.extra"))

  # Test edge cases - empty path returns TRUE (whole db exists)
  expect_true(boilerplate_path_exists(test_db, ""))

  # Test with empty database
  expect_false(boilerplate_path_exists(list(), "methods"))

  # Test with NULL - returns FALSE
  expect_false(boilerplate_path_exists(NULL, "methods"))
})

test_that("boilerplate_sort_db works correctly", {
  # Create unsorted database
  unsorted_db <- list(
    zebra = list(description = "Last alphabetically"),
    methods = list(
      zzz_last = list(description = "Should be last"),
      aaa_first = list(description = "Should be first"),
      bbb_second = list(description = "Should be second")
    ),
    apple = list(description = "First alphabetically"),
    measures = list(
      weight = list(description = "Weight measure"),
      age = list(description = "Age measure"),
      height = list(description = "Height measure")
    )
  )

  # Sort the database
  sorted_db <- boilerplate_sort_db(unsorted_db)

  # Check top-level sorting
  top_level_names <- names(sorted_db)
  expect_equal(top_level_names[1], "apple")
  expect_equal(top_level_names[length(top_level_names)], "zebra")

  # Check nested sorting
  methods_names <- names(sorted_db$methods)
  expect_equal(methods_names[1], "aaa_first")
  expect_equal(methods_names[2], "bbb_second")
  expect_equal(methods_names[3], "zzz_last")

  measures_names <- names(sorted_db$measures)
  expect_equal(measures_names[1], "age")
  expect_equal(measures_names[2], "height")
  expect_equal(measures_names[3], "weight")

  # Test with empty database
  expect_equal(boilerplate_sort_db(list()), list())

  # Test with NULL
  expect_null(boilerplate_sort_db(NULL))

  # Test with deeply nested structure
  deep_db <- list(
    level1 = list(
      z_level2 = list(
        z_level3 = list(
          z_item = "last",
          a_item = "first"
        ),
        a_level3 = list(
          description = "Should be first at level 3"
        )
      ),
      a_level2 = list(
        description = "Should be first at level 2"
      )
    )
  )

  sorted_deep <- boilerplate_sort_db(deep_db)
  level2_names <- names(sorted_deep$level1)
  expect_equal(level2_names[1], "a_level2")
  expect_equal(level2_names[2], "z_level2")

  level3_names <- names(sorted_deep$level1$z_level2)
  expect_equal(level3_names[1], "a_level3")
  expect_equal(level3_names[2], "z_level3")

  level4_names <- names(sorted_deep$level1$z_level2$z_level3)
  expect_equal(level4_names[1], "a_item")
  expect_equal(level4_names[2], "z_item")
})

test_that("boilerplate_list_paths works correctly", {
  # Create test database
  test_db <- list(
    methods = list(
      analysis = list(
        regression = list(
          description = "Regression methods",
          linear = list(
            description = "Linear regression"
          ),
          logistic = list(
            description = "Logistic regression"
          )
        ),
        clustering = list(
          description = "Clustering methods"
        )
      ),
      sampling = list(
        description = "Sampling methods"
      )
    ),
    results = list(
      main = list(
        description = "Main results"
      )
    )
  )

  # Get all paths
  paths <- boilerplate_list_paths(test_db)

  # Check that all paths are included (including leaf nodes with values)
  expected_paths <- c(
    "methods",
    "methods.analysis",
    "methods.analysis.regression",
    "methods.analysis.regression.description",
    "methods.analysis.regression.linear",
    "methods.analysis.regression.linear.description",
    "methods.analysis.regression.logistic",
    "methods.analysis.regression.logistic.description",
    "methods.analysis.clustering",
    "methods.analysis.clustering.description",
    "methods.sampling",
    "methods.sampling.description",
    "results",
    "results.main",
    "results.main.description"
  )

  expect_setequal(paths, expected_paths)

  # Test with empty database
  expect_equal(boilerplate_list_paths(list()), character(0))

  # Test with NULL
  expect_equal(boilerplate_list_paths(NULL), character(0))
})

test_that("path operations handle special cases", {
  # Test with numeric names (should be converted to character)
  numeric_db <- list(
    "123" = list(
      "456" = list(
        description = "Numeric keys"
      )
    )
  )

  expect_true(boilerplate_path_exists(numeric_db, "123"))
  expect_true(boilerplate_path_exists(numeric_db, "123.456"))

  # Test with multiple dots
  multi_dot_db <- list(
    methods = list(
      stats = list(
        regression = list(
          linear = list(
            simple = list(
              description = "Simple linear regression"
            )
          )
        )
      )
    )
  )

  expect_true(boilerplate_path_exists(multi_dot_db, "methods.stats.regression.linear.simple"))
  paths <- boilerplate_list_paths(multi_dot_db)
  expect_true("methods.stats.regression.linear.simple" %in% paths)
})

test_that("boilerplate_sort_db preserves data integrity", {
  # Create database with various data types
  mixed_db <- list(
    strings = list(
      item1 = "text value",
      item2 = "another text"
    ),
    numbers = list(
      item1 = 42,
      item2 = 3.14
    ),
    lists = list(
      item1 = list(a = 1, b = 2),
      item2 = list(x = "hello", y = "world")
    ),
    vectors = list(
      item1 = c(1, 2, 3),
      item2 = c("a", "b", "c")
    ),
    nulls = list(
      item1 = NULL,
      item2 = list(nested = NULL)
    )
  )

  # Sort database
  sorted_db <- boilerplate_sort_db(mixed_db)

  # Check that all values are preserved
  expect_equal(sorted_db$strings$item1, "text value")
  expect_equal(sorted_db$numbers$item1, 42)
  expect_equal(sorted_db$numbers$item2, 3.14)
  expect_equal(sorted_db$lists$item1$a, 1)
  expect_equal(sorted_db$vectors$item1, c(1, 2, 3))
  expect_null(sorted_db$nulls$item1)
  expect_null(sorted_db$nulls$item2$nested)

  # Check structure is maintained
  expect_true(is.list(sorted_db))
  expect_true(is.numeric(sorted_db$numbers$item1))
  expect_true(is.character(sorted_db$strings$item1))
  expect_true(is.vector(sorted_db$vectors$item1))
})

