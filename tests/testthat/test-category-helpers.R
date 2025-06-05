library(testthat)

test_that("category accessor functions work correctly", {
  # Create a unified database with all categories
  unified_db <- list(
    methods = list(
      analysis = list(
        description = "Analysis methods",
        text = "We performed analysis..."
      ),
      sampling = list(
        description = "Sampling approach",
        text = "Random sampling..."
      )
    ),
    results = list(
      primary = list(
        description = "Primary outcomes",
        text = "Significant findings..."
      )
    ),
    discussion = list(
      implications = list(
        description = "Study implications",
        text = "These findings suggest..."
      )
    ),
    measures = list(
      demographics = list(
        age = list(
          description = "Age in years",
          type = "continuous"
        ),
        gender = list(
          description = "Gender identity",
          type = "categorical",
          values = c("Male", "Female", "Other")
        )
      )
    ),
    appendix = list(
      supplementary = list(
        description = "Supplementary materials",
        text = "Additional analyses..."
      )
    ),
    template = list(
      standard = list(
        description = "Standard template",
        content = "Template content here"
      )
    )
  )

  # Test boilerplate_methods()
  methods <- boilerplate_methods(unified_db)
  expect_equal(names(methods), c("analysis", "sampling"))
  expect_equal(methods$analysis$description, "Analysis methods")
  expect_equal(methods$sampling$text, "Random sampling...")

  # Test boilerplate_results()
  results <- boilerplate_results(unified_db)
  expect_equal(names(results), "primary")
  expect_equal(results$primary$description, "Primary outcomes")

  # Test boilerplate_discussion()
  discussion <- boilerplate_discussion(unified_db)
  expect_equal(names(discussion), "implications")
  expect_equal(discussion$implications$text, "These findings suggest...")

  # Test boilerplate_measures()
  measures <- boilerplate_measures(unified_db)
  expect_equal(names(measures), "demographics")
  expect_equal(measures$demographics$age$type, "continuous")
  expect_equal(measures$demographics$gender$values, c("Male", "Female", "Other"))

  # Test boilerplate_appendix()
  appendix <- boilerplate_appendix(unified_db)
  expect_equal(names(appendix), "supplementary")
  expect_equal(appendix$supplementary$description, "Supplementary materials")

  # Test boilerplate_template()
  template <- boilerplate_template(unified_db)
  expect_equal(names(template), "standard")
  expect_equal(template$standard$content, "Template content here")
})

test_that("category accessors handle missing categories gracefully", {
  # Create database with only some categories
  partial_db <- list(
    methods = list(
      test = list(description = "Test method")
    ),
    results = list(
      test = list(description = "Test result")
    )
    # Missing: discussion, measures, appendix, template
  )

  # Test that accessors throw errors for missing categories
  expect_error(
    boilerplate_discussion(partial_db),
    "unified_db must contain a 'discussion' element"
  )
  expect_error(
    boilerplate_measures(partial_db),
    "unified_db must contain a 'measures' element"
  )
  expect_error(
    boilerplate_appendix(partial_db),
    "unified_db must contain an 'appendix' element"
  )
  expect_error(
    boilerplate_template(partial_db),
    "unified_db must contain a 'template' element"
  )

  # Existing categories should still work
  expect_equal(names(boilerplate_methods(partial_db)), "test")
  expect_equal(names(boilerplate_results(partial_db)), "test")
})

test_that("category accessors handle non-unified databases", {
  # Create old-style category database without methods key
  methods_db <- list(
    methods_db = list(
      analysis = list(
        description = "Analysis method",
        text = "Statistical analysis..."
      )
    )
  )

  # Should error with informative message
  expect_error(
    boilerplate_methods(methods_db),
    "unified_db must contain a 'methods' element"
  )
})

test_that("category accessors handle invalid inputs", {
  # Non-list input
  expect_error(
    boilerplate_methods("not a list"),
    "unified_db must contain a 'methods' element"
  )

  # NULL input
  expect_error(
    boilerplate_methods(NULL),
    "unified_db must contain a 'methods' element"
  )

  # Empty list
  expect_error(
    boilerplate_methods(list()),
    "unified_db must contain a 'methods' element"
  )
})

test_that("category accessors preserve nested structure", {
  # Create deeply nested database
  nested_db <- list(
    methods = list(
      statistical = list(
        regression = list(
          linear = list(
            simple = list(
              description = "Simple linear regression",
              text = "y = mx + b"
            ),
            multiple = list(
              description = "Multiple regression",
              text = "y = b0 + b1*x1 + b2*x2"
            )
          ),
          logistic = list(
            binary = list(
              description = "Binary logistic",
              text = "For binary outcomes"
            )
          )
        )
      )
    )
  )

  # Test that nested structure is preserved
  methods <- boilerplate_methods(nested_db)

  expect_true("statistical" %in% names(methods))
  expect_true("regression" %in% names(methods$statistical))
  expect_true("linear" %in% names(methods$statistical$regression))
  expect_true("simple" %in% names(methods$statistical$regression$linear))
  expect_equal(
    methods$statistical$regression$linear$simple$text,
    "y = mx + b"
  )
})

test_that("category accessors work with large databases", {
  # Create large database
  large_db <- list()

  # Add many measures
  measures <- list()
  for (i in 1:100) {
    measures[[paste0("measure_", i)]] <- list(
      description = paste("Measure", i),
      type = ifelse(i %% 2 == 0, "continuous", "categorical"),
      values = if (i %% 2 == 1) letters[1:3] else NULL
    )
  }
  large_db$measures <- measures

  # Add many methods
  methods <- list()
  for (i in 1:50) {
    methods[[paste0("method_", i)]] <- list(
      description = paste("Method", i),
      text = paste("Description of method", i)
    )
  }
  large_db$methods <- methods

  # Test that large databases are handled efficiently
  retrieved_measures <- boilerplate_measures(large_db)
  retrieved_methods <- boilerplate_methods(large_db)

  expect_equal(length(retrieved_measures), 100)
  expect_equal(length(retrieved_methods), 50)
  expect_equal(retrieved_measures$measure_50$type, "continuous")
  expect_equal(retrieved_methods$method_25$description, "Method 25")
})

test_that("category accessors handle special cases", {
  # Database with NULL values and empty lists
  special_db <- list(
    methods = list(
      null_method = NULL,
      empty_list = list(),
      valid_method = list(
        description = "Valid method",
        text = "Method text"
      )
    ),
    measures = list(),  # Empty measures
    results = list()  # Empty results
  )

  # Test handling of special cases
  methods <- boilerplate_methods(special_db)
  expect_null(methods$null_method)
  expect_equal(methods$empty_list, list())
  expect_equal(methods$valid_method$description, "Valid method")

  expect_equal(boilerplate_measures(special_db), list())
  expect_equal(boilerplate_results(special_db), list())
})

