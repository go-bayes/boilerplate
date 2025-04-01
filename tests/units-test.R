# Unit tests forboilerplate::boilerplate_generate_measures
library(testthat)
test_that("boilerplate_generate_measures generates correct formatted output", {
  # Create a test measures database
  test_db <- list(
    test_var1 = list(
      name = "test_var1",
      description = "This is a test variable.",
      reference = "test2023",
      waves = "1-3",
      items = list("Item 1", "Item 2"),
      keywords = c("test", "example")
    ),
    test_var2 = list(
      name = "test_var2",
      description = "This is another test variable.",
      reference = "test2023",
      waves = "2-4",
      items = list("Another item"),
      keywords = c("test", "another")
    )
  )

  # Test with single variable
  result1 <- boilerplate::boilerplate_generate_measures(
    variable_heading = "Test Heading",
    variables = "test_var1",
    db = test_db,
    print_waves = TRUE
  )

  # Check structure and content
  expect_true(grepl("^### Test Heading", result1))
  expect_true(grepl("#### Test Var1", result1))
  expect_true(grepl("\\*Item 1\\*", result1))
  expect_true(grepl("\\*Item 2\\*", result1))
  expect_true(grepl("This is a test variable", result1))
  expect_true(grepl("\\[@test2023\\]", result1))
  expect_true(grepl("\\*Waves: 1-3\\*", result1))
  expect_false(grepl("Keywords", result1)) # Keywords not printed by default

  # Test with multiple variables
  result2 <- boilerplate::boilerplate_generate_measures(
    variable_heading = "Multiple Variables",
    variables = c("test_var1", "test_var2"),
    db = test_db,
    print_waves = TRUE,
    print_keywords = TRUE
  )

  # Check structure and content
  expect_true(grepl("^### Multiple Variables", result2))
  expect_true(grepl("#### Test Var1", result2))
  expect_true(grepl("#### Test Var2", result2))
  expect_true(grepl("\\*Keywords: test, example\\*", result2))
  expect_true(grepl("\\*Waves: 2-4\\*", result2))

  # Test with custom heading levels
  result3 <- boilerplate::boilerplate_generate_measures(
    variable_heading = "Custom Headings",
    variables = "test_var1",
    db = test_db,
    heading_level = 2,
    subheading_level = 3
  )

  # Check heading levels
  expect_true(grepl("^## Custom Headings", result3))
  expect_true(grepl("### Test Var1", result3))

  # Test with appendix reference
  result4 <- boilerplate::boilerplate_generate_measures(
    variable_heading = "With Appendix",
    variables = "test_var1",
    db = test_db,
    appendices_measures = "Appendix B"
  )

  # Check appendix reference
  expect_true(grepl("found in \\*\\*Appendix B\\*\\*", result4))

  # Test with missing measure
  result5 <- boilerplate::boilerplate_generate_measures(
    variable_heading = "Missing Measure",
    variables = c("test_var1", "nonexistent_var"),
    db = test_db
  )

  # Check handling of missing measure
  expect_true(grepl("#### Nonexistent Var", result5))
  expect_true(grepl("No information available for this variable", result5))
})

test_that("boilerplate_generate_measures handles edge cases", {
  # Empty measures database
  empty_db <- list()
  result1 <- boilerplate::boilerplate_generate_measures(
    variable_heading = "Empty DB",
    variables = "test_var",
    db = empty_db
  )
  expect_true(grepl("No information available for this variable", result1))

  # Empty variables list
  test_db <- list(test_var = list(name = "test"))
  result2 <- boilerplate::boilerplate_generate_measures(
    variable_heading = "Empty Variables",
    variables = character(0),
    db = test_db
  )
  expect_equal(result2, "### Empty Variables\n\n")

  # Measure with no items
  test_db <- list(
    no_items = list(
      name = "no_items",
      description = "This variable has no items."
    )
  )
  result3 <-  boilerplate::boilerplate_generate_measures(
    variable_heading = "No Items",
    variables = "no_items",
    db = test_db
  )
  expect_true(grepl("#### No Items", result3))
  expect_true(grepl("This variable has no items", result3))
  expect_false(grepl("\\*", result3)) # No italic text for items
})
