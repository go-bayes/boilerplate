# Test variable documentation features

test_that("boilerplate_add_entry_enhanced adds entries with variable documentation", {
  # Create empty database
  db <- list()
  
  # Add entry with variable documentation
  db <- boilerplate_add_entry_enhanced(
    db,
    path = "methods.sampling",
    value = "We recruited {{n_total}} participants from {{location}}.",
    variables = list(
      n_total = "Total sample size (integer)",
      location = "Recruitment location"
    )
  )
  
  # Check entry was added
  expect_true(boilerplate_path_exists(db, "methods.sampling"))
  
  # Get the entry
  entry <- boilerplate_get_entry(db, "methods.sampling")
  expect_true(is.list(entry))
  expect_equal(entry$text, "We recruited {{n_total}} participants from {{location}}.")
  expect_equal(entry$variables$n_total, "Total sample size (integer)")
  expect_equal(entry$variables$location, "Recruitment location")
  expect_true(entry$`_meta`$has_variables)
  expect_equal(entry$`_meta`$variable_count, 2)
})

test_that("boilerplate_add_entry_enhanced warns about variable mismatches", {
  db <- list()
  
  # Missing documentation
  expect_warning(
    db <- boilerplate_add_entry_enhanced(
      db,
      path = "test.entry",
      value = "Testing {{var1}} and {{var2}}",
      variables = list(var1 = "First variable")
    ),
    "undocumented variables: var2"
  )
  
  # Extra documentation
  expect_warning(
    db <- boilerplate_add_entry_enhanced(
      db,
      path = "test.entry2",
      value = "Testing {{var1}}",
      variables = list(
        var1 = "First variable",
        var2 = "Second variable"
      )
    ),
    "variables not in template: var2"
  )
})

test_that("extract_template_variables works correctly", {
  # Test various template patterns
  expect_equal(
    extract_template_variables("No variables here"),
    character(0)
  )
  
  expect_equal(
    extract_template_variables("One {{variable}} here"),
    "variable"
  )
  
  expect_equal(
    sort(extract_template_variables("Multiple {{var1}} and {{var2}} variables")),
    c("var1", "var2")
  )
  
  expect_equal(
    extract_template_variables("Repeated {{var}} and {{var}} variable"),
    "var"
  )
  
  expect_equal(
    extract_template_variables("Spaces {{ var_with_spaces }} handled"),
    "var_with_spaces"
  )
})

test_that("boilerplate_get_variables retrieves variable documentation", {
  db <- list()
  
  # Add entry with documentation
  db <- boilerplate_add_entry_enhanced(
    db,
    path = "methods.analysis",
    value = "We used {{software}} version {{version}}.",
    variables = list(
      software = "Statistical software name",
      version = "Software version number"
    )
  )
  
  # Get variables
  vars <- boilerplate_get_variables(db, "methods.analysis")
  
  expect_equal(vars$template, "We used {{software}} version {{version}}.")
  expect_equal(sort(vars$found_in_template), c("software", "version"))
  expect_equal(sort(vars$documented), c("software", "version"))
  expect_equal(vars$variables$software, "Statistical software name")
})

test_that("boilerplate_get_variables handles entries without documentation", {
  db <- list(
    methods = list(
      simple = "Just {{n}} participants"
    )
  )
  
  vars <- boilerplate_get_variables(db, "methods.simple")
  
  expect_equal(vars$template, "Just {{n}} participants")
  expect_equal(vars$found_in_template, "n")
  expect_equal(vars$documented, character(0))
  expect_null(vars$variables)
})

test_that("boilerplate_update_entry_enhanced preserves metadata", {
  db <- list()
  
  # Add initial entry
  db <- boilerplate_add_entry_enhanced(
    db,
    path = "test.entry",
    value = "Original {{var1}}",
    variables = list(var1 = "First variable")
  )
  
  # Get creation time
  entry1 <- boilerplate_get_entry(db, "test.entry")
  created_time <- entry1$`_meta`$created
  
  # Wait a moment
  Sys.sleep(0.1)
  
  # Update entry
  db <- boilerplate_update_entry_enhanced(
    db,
    path = "test.entry",
    value = "Updated {{var1}} and {{var2}}",
    variables = list(
      var1 = "First variable updated",
      var2 = "Second variable"
    )
  )
  
  # Check update
  entry2 <- boilerplate_get_entry(db, "test.entry")
  expect_equal(entry2$text, "Updated {{var1}} and {{var2}}")
  expect_equal(entry2$`_meta`$created, created_time)
  expect_true(entry2$`_meta`$updated > created_time)
})

test_that("boilerplate_list_variables scans entire database", {
  # Create database with multiple entries
  db <- list()
  
  db <- boilerplate_add_entry_enhanced(
    db,
    path = "methods.sample",
    value = "Sample of {{n}} participants",
    variables = list(n = "Sample size")
  )
  
  db <- boilerplate_add_entry_enhanced(
    db,
    path = "methods.analysis",
    value = "Analysis using {{software}}",
    variables = list(software = "Analysis software")
  )
  
  db <- boilerplate_add_entry(
    db,
    path = "results.main",
    value = "Effect size was {{effect_size}}"
  )
  
  # List all variables
  all_vars <- boilerplate_list_variables(db)
  
  # Should have at least the 3 variables we added
  expect_true(nrow(all_vars) >= 3)
  expect_true("n" %in% all_vars$variable)
  expect_true("software" %in% all_vars$variable)
  expect_true("effect_size" %in% all_vars$variable)
  
  # Check documentation status for specific variables
  n_rows <- all_vars[all_vars$variable == "n", ]
  software_rows <- all_vars[all_vars$variable == "software", ]
  effect_rows <- all_vars[all_vars$variable == "effect_size", ]
  
  expect_true(any(n_rows$documented))
  expect_true(any(software_rows$documented))
  expect_false(any(effect_rows$documented))
  
  # Filter by category
  methods_vars <- boilerplate_list_variables(db, category = "methods")
  expect_true(nrow(methods_vars) >= 2)
  expect_false("effect_size" %in% methods_vars$variable)
})

test_that("variable documentation works with measures", {
  db <- list()
  
  # Add measure with template in description
  db <- boilerplate_add_entry_enhanced(
    db,
    path = "measures.anxiety",
    value = list(
      name = "GAD-7",
      description = "Anxiety measured using {{n_items}} items on a {{scale}} scale",
      items = c("Feeling nervous", "Unable to stop worrying")
    ),
    variables = list(
      n_items = "Number of items in scale",
      scale = "Scale range (e.g., '0-3')"
    )
  )
  
  # Check it worked
  vars <- boilerplate_get_variables(db, "measures.anxiety")
  expect_equal(sort(vars$found_in_template), c("n_items", "scale"))
  expect_equal(vars$variables$n_items, "Number of items in scale")
})