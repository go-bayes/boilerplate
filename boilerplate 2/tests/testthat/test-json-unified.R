library(testthat)

# Test unified JSON database functionality

test_that("unified JSON structure maintains category organization", {
  skip_if_not_installed("jsonlite")
  
  # Create unified database structure
  unified_db <- list(
    `_meta` = list(
      version = "1.0.0",
      created = Sys.time(),
      lab = "test-lab"
    ),
    methods = list(
      statistical = list(
        regression = list(
          text = "Regression methods text",
          description = "Standard regression approach"
        )
      )
    ),
    measures = list(
      demographics = list(
        age = list(
          name = "age",
          description = "Age in years",
          type = "continuous"
        )
      )
    ),
    results = list(
      descriptive = list(
        table1 = list(
          text = "Table 1 presents {{stats}}",
          description = "Descriptive statistics table"
        )
      )
    )
  )
  
  # Save as unified JSON
  temp_json <- tempfile(fileext = ".json")
  jsonlite::write_json(unified_db, temp_json, pretty = TRUE, auto_unbox = TRUE)
  
  # Read back and verify structure
  loaded_db <- jsonlite::read_json(temp_json)
  
  expect_true("_meta" %in% names(loaded_db))
  expect_true(all(c("methods", "measures", "results") %in% names(loaded_db)))
  expect_equal(loaded_db$methods$statistical$regression$text, "Regression methods text")
  expect_equal(loaded_db$measures$demographics$age$type, "continuous")
  
  # Clean up
  unlink(temp_json)
})

test_that("unified JSON supports hierarchical path access", {
  skip_if_not_installed("jsonlite")
  
  # Create database with deep paths
  unified_db <- list(
    methods = list(
      statistical = list(
        longitudinal = list(
          gee = list(
            text = "GEE analysis text",
            variables = c("time", "outcome")
          ),
          mixed_models = list(
            lme4 = list(
              text = "Mixed models using lme4",
              formula = "outcome ~ time + (1|id)"
            )
          )
        )
      )
    )
  )
  
  # Helper function to access by path
  get_by_path <- function(db, path) {
    parts <- strsplit(path, "\\.")[[1]]
    current <- db
    for (part in parts) {
      if (!is.null(current[[part]])) {
        current <- current[[part]]
      } else {
        return(NULL)
      }
    }
    current
  }
  
  # Test path access
  gee_entry <- get_by_path(unified_db, "methods.statistical.longitudinal.gee")
  expect_equal(gee_entry$text, "GEE analysis text")
  
  lme4_formula <- get_by_path(unified_db, "methods.statistical.longitudinal.mixed_models.lme4.formula")
  expect_equal(lme4_formula, "outcome ~ time + (1|id)")
  
  # Test non-existent path
  missing <- get_by_path(unified_db, "methods.nonexistent.path")
  expect_null(missing)
})

test_that("unified JSON preserves metadata fields", {
  skip_if_not_installed("jsonlite")
  
  # Create database with various metadata
  unified_db <- list(
    `_meta` = list(
      version = "1.0.0",
      schema_version = "1.0",
      created = "2024-01-01T00:00:00Z",
      modified = "2024-01-02T00:00:00Z",
      contributors = list(
        list(name = "User 1", role = "author"),
        list(name = "User 2", role = "reviewer")
      )
    ),
    methods = list(
      sample = list(
        text = "Sample text",
        `_meta` = list(
          author = "Method Author",
          last_edited = "2024-01-01"
        )
      )
    )
  )
  
  # Round trip through JSON
  temp_json <- tempfile(fileext = ".json")
  jsonlite::write_json(unified_db, temp_json, pretty = TRUE, auto_unbox = TRUE)
  loaded_db <- jsonlite::read_json(temp_json)
  
  # Check global metadata
  expect_equal(loaded_db$`_meta`$version, "1.0.0")
  expect_equal(length(loaded_db$`_meta`$contributors), 2)
  expect_equal(loaded_db$`_meta`$contributors[[1]]$name, "User 1")
  
  # Check entry-level metadata
  expect_equal(loaded_db$methods$sample$`_meta`$author, "Method Author")
  
  # Clean up
  unlink(temp_json)
})

test_that("unified JSON handles cross-references between categories", {
  skip_if_not_installed("jsonlite")
  
  # Create database with cross-references
  unified_db <- list(
    methods = list(
      analysis = list(
        primary = list(
          text = "Analysis using {{measures.primary_outcome}}",
          measures_used = c("measures.outcomes.primary", "measures.outcomes.secondary")
        )
      )
    ),
    measures = list(
      outcomes = list(
        primary = list(
          name = "primary_outcome",
          description = "Primary outcome measure"
        ),
        secondary = list(
          name = "secondary_outcome",
          description = "Secondary outcome measure"
        )
      )
    ),
    results = list(
      main = list(
        text = "Results for {{methods.analysis.primary}}",
        references = list(
          method = "methods.analysis.primary",
          measures = c("measures.outcomes.primary", "measures.outcomes.secondary")
        )
      )
    )
  )
  
  # Function to resolve references
  resolve_reference <- function(db, ref_path) {
    if (!grepl("^(methods|measures|results|discussion|appendix|template)\\.", ref_path)) {
      return(NULL)
    }
    
    parts <- strsplit(ref_path, "\\.")[[1]]
    current <- db
    for (part in parts) {
      if (!is.null(current[[part]])) {
        current <- current[[part]]
      } else {
        return(NULL)
      }
    }
    current
  }
  
  # Test reference resolution
  primary_measure <- resolve_reference(unified_db, "measures.outcomes.primary")
  expect_equal(primary_measure$name, "primary_outcome")
  
  # Test multiple references
  main_results <- unified_db$results$main
  method_ref <- resolve_reference(unified_db, main_results$references$method)
  expect_true(!is.null(method_ref))
  expect_equal(method_ref$measures_used[1], "measures.outcomes.primary")
})

test_that("unified JSON supports web interface data structure", {
  skip_if_not_installed("jsonlite")
  
  # Create database matching web interface expectations
  web_db <- list(
    `_meta` = list(
      version = "1.0.0",
      lab = "test-lab",
      modified = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ")
    ),
    methods = list(),
    measures = list(),
    results = list(),
    discussion = list()
  )
  
  # Add entry via web interface pattern
  add_web_entry <- function(db, category, path, content) {
    parts <- strsplit(path, "\\.")[[1]]
    
    # Add metadata to content
    content$`_meta` <- list(modified = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ"))
    
    # Helper to set nested value
    set_nested <- function(lst, keys, value) {
      if (length(keys) == 1) {
        lst[[keys[1]]] <- value
      } else {
        if (is.null(lst[[keys[1]]])) {
          lst[[keys[1]]] <- list()
        }
        lst[[keys[1]]] <- set_nested(lst[[keys[1]]], keys[-1], value)
      }
      lst
    }
    
    # Set the value
    db[[category]] <- set_nested(
      if (is.null(db[[category]])) list() else db[[category]], 
      parts, 
      content
    )
    
    db
  }
  
  # Test adding entries
  web_db <- add_web_entry(
    web_db, 
    "methods", 
    "statistical.regression",
    list(
      text = "Regression analysis was performed",
      description = "Standard regression methods"
    )
  )
  
  web_db <- add_web_entry(
    web_db,
    "measures",
    "psychological.anxiety.gad7",
    list(
      name = "gad7",
      description = "GAD-7 anxiety scale",
      type = "ordinal",
      items = 7
    )
  )
  
  # Debug: Check what we have
  # print(str(web_db, max.level = 4))
  
  # Verify structure
  expect_true("methods" %in% names(web_db))
  expect_true("statistical" %in% names(web_db$methods))
  expect_true("regression" %in% names(web_db$methods$statistical))
  
  expect_equal(web_db$methods$statistical$regression$text, "Regression analysis was performed")
  expect_equal(web_db$measures$psychological$anxiety$gad7$name, "gad7")
  expect_true(!is.null(web_db$methods$statistical$regression$`_meta`$modified))
})

test_that("unified JSON handles large databases efficiently", {
  skip_if_not_installed("jsonlite")
  
  # Create a larger test database
  large_db <- list(
    `_meta` = list(version = "1.0.0"),
    methods = list(),
    measures = list()
  )
  
  # Add many entries
  n_categories <- 10
  n_entries <- 20
  
  for (i in 1:n_categories) {
    cat_name <- paste0("category", i)
    large_db$methods[[cat_name]] <- list()
    
    for (j in 1:n_entries) {
      entry_name <- paste0("method", j)
      large_db$methods[[cat_name]][[entry_name]] <- list(
        text = paste("Method text for", cat_name, entry_name),
        description = paste("Description for", cat_name, entry_name),
        keywords = c("keyword1", "keyword2", "keyword3"),
        variables = letters[1:5]
      )
    }
  }
  
  # Test save and load performance
  temp_json <- tempfile(fileext = ".json")
  
  # Time the write
  write_time <- system.time({
    jsonlite::write_json(large_db, temp_json, pretty = TRUE, auto_unbox = TRUE)
  })
  
  # Time the read
  read_time <- system.time({
    loaded_db <- jsonlite::read_json(temp_json)
  })
  
  # Should complete reasonably quickly (under 5 seconds each)
  expect_true(write_time["elapsed"] < 5)
  expect_true(read_time["elapsed"] < 5)
  
  # Verify content integrity
  expect_equal(
    loaded_db$methods$category5$method10$text,
    "Method text for category5 method10"
  )
  
  # Check file size is reasonable
  file_size <- file.info(temp_json)$size
  expect_true(file_size < 10 * 1024 * 1024)  # Less than 10MB
  
  # Clean up
  unlink(temp_json)
})

test_that("unified JSON supports partial updates", {
  skip_if_not_installed("jsonlite")
  
  # Create initial database
  db <- list(
    `_meta` = list(version = "1.0.0"),
    methods = list(
      existing = list(
        entry1 = list(text = "Original text 1"),
        entry2 = list(text = "Original text 2")
      )
    )
  )
  
  # Function to update specific path
  update_at_path <- function(db, category, path, updates) {
    parts <- strsplit(path, "\\.")[[1]]
    
    # Helper to update nested value
    update_nested <- function(lst, keys, updates) {
      if (length(keys) == 1) {
        if (is.null(lst[[keys[1]]])) {
          lst[[keys[1]]] <- list()
        }
        # Merge updates
        for (key in names(updates)) {
          lst[[keys[1]]][[key]] <- updates[[key]]
        }
      } else {
        if (is.null(lst[[keys[1]]])) {
          lst[[keys[1]]] <- list()
        }
        lst[[keys[1]]] <- update_nested(lst[[keys[1]]], keys[-1], updates)
      }
      lst
    }
    
    # Update the value
    if (is.null(db[[category]])) {
      db[[category]] <- list()
    }
    db[[category]] <- update_nested(db[[category]], parts, updates)
    
    db
  }
  
  # Test partial update
  db <- update_at_path(
    db, 
    "methods", 
    "existing.entry1",
    list(text = "Updated text 1", new_field = "New value")
  )
  
  # Add new entry
  db <- update_at_path(
    db,
    "methods",
    "new_category.new_entry",
    list(text = "New entry text", description = "New entry")
  )
  
  # Verify updates
  expect_equal(db$methods$existing$entry1$text, "Updated text 1")
  expect_equal(db$methods$existing$entry1$new_field, "New value")
  expect_equal(db$methods$existing$entry2$text, "Original text 2")  # Unchanged
  expect_equal(db$methods$new_category$new_entry$text, "New entry text")
})