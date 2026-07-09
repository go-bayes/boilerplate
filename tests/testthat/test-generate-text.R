# Unit tests for boilerplate_generate_text
library(testthat)

test_that("boilerplate_generate_text handles basic template substitution", {
  # Create test database
  test_db <- list(
    methods = list(
      sample = list(
        default = "We recruited {{n_total}} participants from {{location}}."
      ),
      analysis = list(
        main = "Analysis was conducted using {{software}} version {{version}}."
      )
    ),
    templates = list(
      report = list(
        value = "# {{title}}\n\n{{content}}"
      )
    )
  )

  # Test basic substitution
  result <- boilerplate_generate_text(
    category = "methods",
    sections = c("sample.default", "analysis.main"),
    global_vars = list(
      n_total = 100,
      location = "online platforms",
      software = "R",
      version = "4.3.0"
    ),
    db = test_db,
    quiet = TRUE
  )

  expect_type(result, "character")
  expect_true(grepl("100 participants", result))
  expect_true(grepl("online platforms", result))
  expect_true(grepl("R version 4.3.0", result))
})

test_that("boilerplate_generate_text handles missing variables gracefully", {
  test_db <- list(
    methods = list(
      sample = list(
        default = "We recruited {{n_total}} participants."
      )
    )
  )

  # Missing variable should leave placeholder
  result <- boilerplate_generate_text(
    category = "methods",
    sections = "sample.default",
    global_vars = list(),  # No variables provided
    db = test_db,
    quiet = TRUE
  )

  expect_true(grepl("\\{\\{n_total\\}\\}", result))
})

test_that("boilerplate_generate_text handles section-specific variables", {
  test_db <- list(
    methods = list(
      sample = list(
        default = "Sample: {{sample_var}}"
      ),
      analysis = list(
        default = "Analysis: {{analysis_var}}"
      )
    )
  )

  result <- boilerplate_generate_text(
    category = "methods",
    sections = c("sample", "analysis"),
    global_vars = list(sample_var = "global_value"),
    section_vars = list(
      sample = list(sample_var = "section_specific"),
      analysis = list(analysis_var = "analysis_specific")
    ),
    db = test_db,
    quiet = TRUE
  )

  # Section-specific should override global
  expect_true(grepl("Sample: section_specific", result))
  expect_true(grepl("Analysis: analysis_specific", result))
})

test_that("boilerplate_generate_text handles text overrides", {
  test_db <- list(
    methods = list(
      sample = list(
        default = "Original text"
      )
    )
  )

  result <- boilerplate_generate_text(
    category = "methods",
    sections = "sample",
    text_overrides = list(
      sample = "Override text"
    ),
    db = test_db,
    quiet = TRUE
  )

  expect_equal(result, "Override text")
  expect_false(grepl("Original text", result))
})

test_that("boilerplate_generate_text handles unified database", {
  unified_db <- list(
    methods = list(
      sample = list(
        default = "Methods text"
      )
    ),
    results = list(
      main = list(
        default = "Results text"
      )
    )
  )

  # Should extract correct category
  result <- boilerplate_generate_text(
    category = "methods",
    sections = "sample",
    db = unified_db,
    quiet = TRUE
  )

  expect_true(grepl("Methods text", result))
  expect_false(grepl("Results text", result))
})

test_that("boilerplate_generate_text handles invalid inputs", {
  test_db <- list(
    methods = list(
      sample = list(default = "Text")
    )
  )

  # Invalid category
  expect_error(
    boilerplate_generate_text(
      category = "invalid",
      sections = "sample",
      db = test_db,
      quiet = TRUE
    )
  )

  # Invalid section
  expect_message(
    boilerplate_generate_text(
      category = "methods",
      sections = "nonexistent",
      db = test_db,
      quiet = FALSE
    ),
    "not found"
  )
})

test_that("boilerplate_generate_text handles complex template patterns", {
  test_db <- list(
    methods = list(
      complex = list(
        default = "Study with {{n}} participants ({{pct}}%) using {{{{nested}}}} variables."
      ),
      multiline = list(
        default = "Line 1: {{var1}}\nLine 2: {{var2}}\nLine 3: {{var3}}"
      )
    )
  )

  # Test nested braces and special characters
  # Suppress the expected warning about unresolved template variable "special"
  # When {{{{nested}}}} is replaced with "special", it becomes {{special}}
  # which is then treated as an unresolved template variable
  suppressWarnings({
    result <- boilerplate_generate_text(
      category = "methods",
      sections = "complex",
      global_vars = list(
        n = 100,
        pct = 75.5,
        nested = "special"
      ),
      db = test_db,
      quiet = TRUE
    )
  })

  expect_true(grepl("100 participants", result))
  expect_true(grepl("75.5%", result))
  # Quadruple braces {{{{nested}}}} become {{special}} after substitution, 
  # which remain as is since 'special' is not a variable
  expect_true(grepl("\\{\\{special\\}\\} variables", result))

  # Test multiline templates
  multiline_result <- boilerplate_generate_text(
    category = "methods",
    sections = "multiline",
    global_vars = list(
      var1 = "First",
      var2 = "Second",
      var3 = "Third"
    ),
    db = test_db,
    quiet = TRUE
  )

  lines <- strsplit(multiline_result, "\n")[[1]]
  expect_equal(length(lines), 3)
  expect_true(grepl("First", lines[1]))
  expect_true(grepl("Second", lines[2]))
  expect_true(grepl("Third", lines[3]))
})

test_that("boilerplate_generate_text handles database from file", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  # Create test database file
  test_db <- list(
    methods = list(
      sample = list(
        default = "Sample size: {{n}}"
      )
    )
  )

  db_path <- file.path(temp_dir, "test_db.json")
  jsonlite::write_json(test_db, db_path, pretty = TRUE, auto_unbox = TRUE)

  # Test with database loaded from file
  db_from_file <- jsonlite::read_json(db_path, simplifyVector = FALSE)
  result <- boilerplate_generate_text(
    category = "methods",
    sections = "sample",
    global_vars = list(n = 250),
    db = db_from_file,
    quiet = TRUE
  )

  # The result might have trailing whitespace or newlines
  expect_true(grepl("Sample size: 250", result, fixed = TRUE))
})

test_that("boilerplate_generate_text handles multiple nested sections", {
  test_db <- list(
    methods = list(
      statistical = list(
        regression = list(
          default = "Regression analysis"
        ),
        anova = list(
          default = "ANOVA analysis"
        ),
        clustering = list(
          default = "Cluster analysis"
        )
      ),
      sampling = list(
        default = "Sampling method"
      )
    )
  )

  # Test multiple section selection
  result <- boilerplate_generate_text(
    category = "methods",
    sections = c("statistical.regression", "statistical.anova", "statistical.clustering"),
    db = test_db,
    quiet = TRUE
  )

  expect_true(grepl("Regression analysis", result))
  expect_true(grepl("ANOVA analysis", result))
  expect_true(grepl("Cluster analysis", result))
  expect_false(grepl("Sampling method", result))
})

test_that("boilerplate_generate_text preserves whitespace and formatting", {
  test_db <- list(
    methods = list(
      formatted = list(
        default = "  Indented text\n\n\tTabbed line\n    Four spaces"
      ),
      markdown = list(
        default = "# Heading\n\n**Bold** and *italic* text\n\n- List item 1\n- List item 2"
      )
    )
  )

  # Test whitespace preservation
  result <- boilerplate_generate_text(
    category = "methods",
    sections = "formatted",
    db = test_db,
    quiet = TRUE
  )

  expect_true(grepl("^  Indented text", result))
  expect_true(grepl("\tTabbed line", result))
  expect_true(grepl("    Four spaces", result))

  # Test markdown formatting
  md_result <- boilerplate_generate_text(
    category = "methods",
    sections = "markdown",
    db = test_db,
    quiet = TRUE
  )

  expect_true(grepl("# Heading", md_result))
  expect_true(grepl("\\*\\*Bold\\*\\*", md_result))
  expect_true(grepl("\\*italic\\*", md_result))
  expect_true(grepl("- List item", md_result))
})

test_that("boilerplate_generate_text handles empty and NULL values", {
  test_db <- list(
    methods = list(
      empty = list(
        default = ""
      ),
      null = list(
        default = NULL
      ),
      valid = list(
        default = "Valid text"
      )
    )
  )

  # Test empty string
  result_empty <- boilerplate_generate_text(
    category = "methods",
    sections = "empty",
    db = test_db,
    quiet = TRUE
  )
  expect_equal(result_empty, "")

  # Test NULL value (should skip)
  result_null <- boilerplate_generate_text(
    category = "methods",
    sections = c("null", "valid"),
    db = test_db,
    quiet = TRUE
  )
  expect_equal(result_null, "Valid text")
})

test_that("boilerplate_generate_text handles special characters in variables", {
  test_db <- list(
    methods = list(
      special = list(
        default = "Value: {{special_var}}"
      )
    )
  )

  # Test various special characters
  special_chars <- list(
    special_var = "Test & < > \" ' \\ / | $ % @ # ! ~ ` ^ * ( ) [ ] { } ; : , . ?"
  )

  result <- boilerplate_generate_text(
    category = "methods",
    sections = "special",
    global_vars = special_chars,
    db = test_db,
    quiet = TRUE
  )

  expect_true(grepl("Test & < > \\\"", result))
  expect_true(grepl("\\$", result))
  expect_true(grepl("%", result))
})

test_that("boilerplate_generate_text handles deeply nested sections", {
  test_db <- list(
    methods = list(
      level1 = list(
        level2 = list(
          level3 = list(
            level4 = list(
              default = "Deep content: {{deep_var}}"
            )
          )
        )
      )
    )
  )

  result <- boilerplate_generate_text(
    category = "methods",
    sections = "level1.level2.level3.level4",
    global_vars = list(deep_var = "found it"),
    db = test_db,
    quiet = TRUE
  )

  expect_equal(result, "Deep content: found it")
})

test_that("boilerplate_generate_text combines multiple sections correctly", {
  test_db <- list(
    methods = list(
      intro = list(
        default = "Introduction paragraph."
      ),
      middle = list(
        default = "Middle section content."
      ),
      conclusion = list(
        default = "Concluding remarks."
      )
    )
  )

  # Test section ordering
  result <- boilerplate_generate_text(
    category = "methods",
    sections = c("intro", "middle", "conclusion"),
    db = test_db,
    quiet = TRUE
  )

  # Check order is preserved
  intro_pos <- regexpr("Introduction", result)[1]
  middle_pos <- regexpr("Middle", result)[1]
  conclusion_pos <- regexpr("Concluding", result)[1]

  expect_true(intro_pos < middle_pos)
  expect_true(middle_pos < conclusion_pos)

  # Note: Custom separator functionality was removed from the function
})

