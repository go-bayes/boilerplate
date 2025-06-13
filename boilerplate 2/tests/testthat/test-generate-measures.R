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
  expect_true(grepl("\\* Item 1", result1))
  expect_true(grepl("\\* Item 2", result1))
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

test_that("boilerplate_generate_measures handles complex measure structures", {
  # Create complex measures database
  complex_db <- list(
    demographic_age = list(
      name = "demographic_age",
      description = "Participant age in years.",
      reference = "smith2020",
      waves = "1-5",
      type = "continuous",
      range = "18-95",
      unit = "years",
      notes = "Self-reported at baseline"
    ),
    scale_anxiety = list(
      name = "scale_anxiety",
      description = "Generalized Anxiety Disorder 7-item scale.",
      reference = "spitzer2006",
      waves = "1,3,5",
      items = list(
        "Feeling nervous, anxious, or on edge",
        "Not being able to stop or control worrying",
        "Worrying too much about different things",
        "Trouble relaxing",
        "Being so restless that it is hard to sit still",
        "Becoming easily annoyed or irritable",
        "Feeling afraid, as if something awful might happen"
      ),
      keywords = c("mental health", "anxiety", "GAD-7"),
      scoring = "Sum of all items (0-21)",
      reliability = "α = 0.92"
    ),
    nested_construct = list(
      name = "nested_construct",
      description = "A measure with nested subscales.",
      subscales = list(
        subscale_a = list(
          name = "Subscale A",
          items = list("Item A1", "Item A2")
        ),
        subscale_b = list(
          name = "Subscale B",
          items = list("Item B1", "Item B2")
        )
      )
    )
  )
  
  # Test with continuous measure
  result_continuous <- boilerplate_generate_measures(
    variable_heading = "Demographics",
    variables = "demographic_age",
    db = complex_db,
    print_waves = TRUE
  )
  
  expect_true(grepl("Participant age in years", result_continuous))
  expect_true(grepl("\\[@smith2020\\]", result_continuous))
  expect_true(grepl("\\*Waves: 1-5\\*", result_continuous))
  
  # Test with scale measure including all metadata
  result_scale <- boilerplate_generate_measures(
    variable_heading = "Anxiety Measures",
    variables = "scale_anxiety",
    db = complex_db,
    print_waves = TRUE,
    print_keywords = TRUE
  )
  
  expect_true(grepl("Generalized Anxiety Disorder", result_scale))
  expect_true(grepl("\\* Feeling nervous", result_scale))
  expect_true(grepl("\\* Feeling afraid", result_scale))
  expect_true(grepl("\\*Keywords: mental health, anxiety, GAD-7\\*", result_scale))
  expect_true(grepl("\\[@spitzer2006\\]", result_scale))
  
  # Check all 7 items are present
  item_count <- length(gregexpr("\\* ", result_scale)[[1]])
  expect_equal(item_count, 7)
})

test_that("boilerplate_generate_measures handles database from file", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Create test database file with unified structure (no extra wrapper)
  test_db <- list(
    measures = list(
      test_measure = list(
        name = "test_measure",
        description = "Test measure from file",
        items = list("Item 1", "Item 2")
      )
    )
  )
  
  db_path <- file.path(temp_dir, "measures_db.rds")
  saveRDS(test_db, db_path)
  
  # Test with database loaded from file
  db_from_file <- readRDS(db_path)
  # The function will extract measures from the unified database
  result <- boilerplate_generate_measures(
    variable_heading = "From File", 
    variables = "test_measure",
    db = db_from_file
  )
  
  expect_true(grepl("Test measure from file", result))
  expect_true(grepl("\\* Item 1", result))
})

test_that("boilerplate_generate_measures handles special formatting", {
  # Database with special formatting needs
  format_db <- list(
    special_chars = list(
      name = "special_chars",
      description = "Measure with & < > \" ' special characters.",
      items = list(
        "Item with 'quotes' and \"double quotes\"",
        "Item with & ampersand",
        "Item with < and > symbols"
      )
    ),
    unicode_content = list(
      name = "unicode_content",
      description = "Measure with unicode: α β γ © ® ™ ≤ ≥ ± ∞",
      items = list(
        "Item with emoji 😊",
        "Item with accents: café, naïve, résumé"
      )
    ),
    markdown_format = list(
      name = "markdown_format",
      description = "Measure with **bold** and *italic* text.",
      items = list(
        "Item with `code` formatting",
        "Item with [link](http://example.com)"
      )
    )
  )
  
  # Test special characters
  result_special <- boilerplate_generate_measures(
    variable_heading = "Special Characters",
    variables = "special_chars",
    db = format_db
  )
  
  expect_true(grepl("& < >", result_special))
  expect_true(grepl("'quotes'", result_special))
  expect_true(grepl("& ampersand", result_special))
  
  # Test unicode
  result_unicode <- boilerplate_generate_measures(
    variable_heading = "Unicode",
    variables = "unicode_content",
    db = format_db
  )
  
  expect_true(grepl("α β γ", result_unicode))
  expect_true(grepl("café", result_unicode))
  
  # Test markdown preservation
  result_markdown <- boilerplate_generate_measures(
    variable_heading = "Markdown",
    variables = "markdown_format",
    db = format_db
  )
  
  expect_true(grepl("\\*\\*bold\\*\\*", result_markdown))
  expect_true(grepl("`code`", result_markdown))
})

test_that("boilerplate_generate_measures handles multiple selections", {
  # Database with pattern-based naming
  pattern_db <- list(
    psych_depression = list(
      name = "psych_depression",
      description = "Depression scale",
      items = list("Feeling down")
    ),
    psych_anxiety = list(
      name = "psych_anxiety",
      description = "Anxiety scale",
      items = list("Feeling nervous")
    ),
    psych_stress = list(
      name = "psych_stress",
      description = "Stress scale",
      items = list("Feeling overwhelmed")
    ),
    demo_age = list(
      name = "demo_age",
      description = "Age in years"
    ),
    demo_gender = list(
      name = "demo_gender",
      description = "Gender identity"
    )
  )
  
  # Test multiple psych measures
  result_psych <- boilerplate_generate_measures(
    variable_heading = "Psychological Measures",
    variables = c("psych_depression", "psych_anxiety", "psych_stress"),
    db = pattern_db
  )
  
  expect_true(grepl("Depression scale", result_psych))
  expect_true(grepl("Anxiety scale", result_psych))
  expect_true(grepl("Stress scale", result_psych))
  expect_false(grepl("Age in years", result_psych))
  
  # Test mix of measures
  result_multi <- boilerplate_generate_measures(
    variable_heading = "Selected Measures",
    variables = c("psych_depression", "demo_age", "demo_gender"),
    db = pattern_db
  )
  
  expect_true(grepl("Depression scale", result_multi))
  expect_true(grepl("Age in years", result_multi))
  expect_true(grepl("Gender identity", result_multi))
  expect_false(grepl("Anxiety scale", result_multi))  # Not included
})

test_that("boilerplate_generate_measures respects print options", {
  test_db <- list(
    full_measure = list(
      name = "full_measure",
      description = "Complete measure with all fields.",
      reference = "author2023",
      waves = "1-4",
      items = list("Item 1", "Item 2"),
      keywords = c("test", "complete"),
      reliability = "α = 0.85",
      validity = "Convergent validity r = 0.72"
    )
  )
  
  # Test with nothing printed
  result_minimal <- boilerplate_generate_measures(
    variable_heading = "Minimal",
    variables = "full_measure",
    db = test_db,
    print_waves = FALSE,
    print_keywords = FALSE
  )
  
  expect_false(grepl("Waves:", result_minimal))
  expect_false(grepl("Keywords:", result_minimal))
  expect_true(grepl("Complete measure", result_minimal))
  expect_true(grepl("\\[@author2023\\]", result_minimal))
  
  # Test with everything printed
  result_full <- boilerplate_generate_measures(
    variable_heading = "Full",
    variables = "full_measure",
    db = test_db,
    print_waves = TRUE,
    print_keywords = TRUE
  )
  
  expect_true(grepl("\\*Waves: 1-4\\*", result_full))
  expect_true(grepl("\\*Keywords: test, complete\\*", result_full))
})

test_that("boilerplate_generate_measures handles empty fields gracefully", {
  sparse_db <- list(
    empty_description = list(
      name = "empty_description",
      description = "",
      items = list("Item 1")
    ),
    null_description = list(
      name = "null_description",
      description = NULL,
      items = list("Item 1")
    ),
    empty_items = list(
      name = "empty_items",
      description = "Has empty items list",
      items = list()
    ),
    null_items = list(
      name = "null_items",
      description = "Has NULL items",
      items = NULL
    ),
    minimal = list(
      name = "minimal"
      # Only name, nothing else
    )
  )
  
  # Test each edge case
  result <- boilerplate_generate_measures(
    variable_heading = "Sparse Measures",
    variables = c("empty_description", "null_description", 
                  "empty_items", "null_items", "minimal"),
    db = sparse_db
  )
  
  # Should handle all cases without errors
  expect_true(grepl("#### Empty Description", result))
  expect_true(grepl("#### Null Description", result))
  expect_true(grepl("#### Empty Items", result))
  expect_true(grepl("#### Null Items", result))
  expect_true(grepl("#### Minimal", result))
})
