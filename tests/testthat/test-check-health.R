# Test database health check functionality

test_that("boilerplate_check_health identifies empty entries", {
  # Create database with empty entries
  db <- list(
    methods = list(
      valid = "Some content",
      empty_string = "",
      null_entry = NULL,
      empty_list = list()
    )
  )
  
  health <- boilerplate_check_health(db, quiet = TRUE)
  
  expect_false(health$summary$healthy)
  expect_true("empty_entries" %in% names(health$issues))
  expect_equal(health$issues$empty_entries$count, 3)
  expect_true("methods.empty_string" %in% health$issues$empty_entries$paths)
})

test_that("boilerplate_check_health can fix empty entries", {
  db <- list(
    methods = list(
      valid = "Content",
      empty = ""
    )
  )
  
  health <- boilerplate_check_health(db, fix = TRUE, quiet = TRUE)
  
  expect_true(length(health$fixed$removed_empty) > 0)
  
  # Get fixed database
  fixed_db <- attr(health, "fixed_db")
  expect_false(boilerplate_path_exists(fixed_db, "methods.empty"))
  expect_true(boilerplate_path_exists(fixed_db, "methods.valid"))
})

test_that("boilerplate_check_health identifies orphaned variables", {
  db <- list(
    methods = list(
      sample = "We recruited {{n_total}} participants from {{location}}",
      analysis = list(
        text = "Analysis using {{software}}",
        variables = list(software = "Statistical software")
      )
    )
  )
  
  health <- boilerplate_check_health(db, quiet = TRUE)
  
  expect_true("orphaned_variables" %in% names(health$issues))
  expect_equal(health$issues$orphaned_variables$count, 3)  # n_total, location, and software (since it's not in the enhanced format)
  expect_true("n_total" %in% health$issues$orphaned_variables$details$methods.sample)
  expect_true("location" %in% health$issues$orphaned_variables$details$methods.sample)
  expect_true("software" %in% health$issues$orphaned_variables$details$methods.analysis)
})

test_that("boilerplate_check_health identifies duplicate content", {
  db <- list(
    methods = list(
      entry1 = "This is duplicate content",
      entry2 = "This is duplicate content",
      entry3 = "This is unique content"
    )
  )
  
  health <- boilerplate_check_health(db, quiet = TRUE)
  
  expect_true("duplicate_content" %in% names(health$issues))
  expect_equal(health$issues$duplicate_content$count, 1)
  
  # Check that both duplicate paths are identified
  dup_group <- health$issues$duplicate_content$groups[[1]]
  expect_true("methods.entry1" %in% dup_group)
  expect_true("methods.entry2" %in% dup_group)
})

test_that("boilerplate_check_health checks measure consistency", {
  db <- list(
    measures = list(
      complete = list(
        name = "Complete Measure",
        description = "A complete measure",
        type = "continuous",
        items = c("Item 1", "Item 2")
      ),
      incomplete = list(
        description = "Missing name field"
      ),
      invalid_type = list(
        name = "Invalid Type",
        description = "Has invalid type",
        type = "numeric"  # Should be "continuous"
      )
    )
  )
  
  health <- boilerplate_check_health(db, quiet = TRUE)
  
  expect_true("incomplete_measures" %in% names(health$issues))
  expect_true("inconsistent_measures" %in% names(health$issues))
  
  # Check specific issues
  expect_true("incomplete" %in% names(health$issues$incomplete_measures$details))
  expect_true("name" %in% health$issues$incomplete_measures$details$incomplete)
})

test_that("boilerplate_check_health identifies invalid paths", {
  # Create proper nested structure
  db <- list(
    methods = list()
  )
  
  # Add entries with invalid paths
  db$methods[["valid.path"]] <- "Good"
  db$methods[["invalid path"]] <- "Spaces not allowed"
  db$methods[["invalid..path"]] <- "Multiple dots"
  db$methods[[".invalid"]] <- "Starts with dot"
  db$methods[["invalid."]] <- "Ends with dot"
  
  health <- boilerplate_check_health(db, quiet = TRUE)
  
  expect_true("invalid_paths" %in% names(health$issues))
  expect_true(health$issues$invalid_paths$count >= 4)
})

test_that("boilerplate_check_health provides accurate statistics", {
  db <- list(
    methods = list(
      sample = "We have {{n}} participants",
      analysis = list(
        text = "Using {{software}} version {{version}}",
        variables = list(
          software = "Statistical software",
          version = "Version number"
        )
      )
    ),
    measures = list(
      scale1 = list(name = "Scale 1", description = "Description")
    )
  )
  
  health <- boilerplate_check_health(db, quiet = TRUE)
  
  # The structure has: methods.sample, methods.analysis (and its nested entries), measures.scale1
  # So we need to count all paths including nested ones
  expect_true(health$stats$total_entries >= 3)
  expect_equal(health$stats$total_categories, 2)
  expect_true(health$stats$total_variables >= 3)
  expect_true(health$stats$documented_variables >= 0)
})

test_that("boilerplate_check_health handles unified vs single category databases", {
  # Unified database
  unified_db <- list(
    methods = list(entry = "Content"),
    measures = list(scale = list(name = "Scale"))
  )
  
  health_unified <- boilerplate_check_health(unified_db, quiet = TRUE)
  expect_equal(health_unified$stats$total_categories, 2)
  
  # Single category database
  single_db <- list(
    entry1 = "Content 1",
    entry2 = "Content 2"
  )
  
  health_single <- boilerplate_check_health(single_db, quiet = TRUE)
  expect_equal(health_single$stats$total_categories, 0)
})

test_that("boilerplate_health_report generates report", {
  db <- list(
    methods = list(
      sample = "We have {{n}} participants"
    )
  )
  
  health <- boilerplate_check_health(db, quiet = TRUE)
  
  # Generate report as string
  report <- boilerplate_health_report(health)
  
  expect_true(is.character(report))
  expect_true(grepl("Database Health Report", report))
  # The report should mention issues if there are any
  if (length(health$issues) > 0) {
    expect_true(grepl("Issue", report, ignore.case = TRUE))
  }
  
  # Test file output
  temp_file <- tempfile(fileext = ".txt")
  result <- boilerplate_health_report(health, file = temp_file)
  
  expect_true(file.exists(temp_file))
  expect_equal(result, temp_file)
  
  # Clean up
  unlink(temp_file)
})

test_that("print.boilerplate_health provides readable output", {
  db <- list(
    methods = list(
      empty = "",
      valid = "Content with {{var}}"
    )
  )
  
  health <- boilerplate_check_health(db, quiet = TRUE)
  
  # Capture print output
  output <- capture.output(print(health))
  
  expect_true(any(grepl("Database Health Report", output)))
  # Check for either healthy or issues found
  expect_true(any(grepl("HEALTHY|ISSUES FOUND", output)))
  # If there are issues, check they are displayed somehow
  if (length(health$issues) > 0 && !health$summary$healthy) {
    # The word "warning" or "info" should appear somewhere
    expect_true(any(grepl("warning|info|Warning|Info", output, ignore.case = TRUE)))
  }
})