# Unit tests for intro-enhanced vignette examples
library(testthat)

test_that("Enhanced intro hierarchical organization works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Initialize with all categories
  boilerplate_init(
    data_path = temp_dir,
    categories = c("methods", "measures", "results", "discussion", "appendix", "template"),
    create_dirs = TRUE,
    create_empty = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)
  
  # Test hierarchical access
  expect_type(db$methods$statistical$longitudinal$lmtp, "character")
  expect_true(grepl("LMTP", db$methods$statistical$longitudinal$lmtp))
  
  # Test generating from nested sections
  methods_text <- boilerplate_generate_text(
    category = "methods",
    sections = c(
      "causal_assumptions.identification",
      "statistical.longitudinal.lmtp"
    ),
    db = db,
    add_headings = TRUE,
    quiet = TRUE
  )
  
  expect_true(grepl("### Identification", methods_text))
  expect_true(grepl("### Lmtp", methods_text))
})

test_that("Enhanced intro template variables work", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Initialize
  boilerplate_init(
    data_path = temp_dir,
    create_dirs = TRUE,
    create_empty = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)
  
  # Test with complex template variables
  methods_text <- boilerplate_generate_text(
    category = "methods",
    sections = "causal_assumptions.identification",
    global_vars = list(
      exposure_var = "physical activity levels"
    ),
    db = db,
    quiet = TRUE
  )
  
  expect_true(grepl("physical activity levels", methods_text))
  
  # Test section-specific variables
  section_vars <- list(
    sample = list(
      population = "adolescents aged 13-18",
      timeframe = "September 2023 - March 2024"
    ),
    "causal_assumptions.confounding_control" = list(
      confounders = "age, gender, socioeconomic status"
    )
  )
  
  methods_text <- boilerplate_generate_text(
    category = "methods",
    sections = c("sample", "causal_assumptions.confounding_control"),
    section_vars = section_vars,
    db = db,
    quiet = TRUE
  )
  
  expect_true(grepl("adolescents aged 13-18", methods_text))
  expect_true(grepl("September 2023 - March 2024", methods_text))
})

test_that("Enhanced intro batch operations work", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Initialize
  boilerplate_init(
    data_path = temp_dir,
    create_dirs = TRUE,
    create_empty = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)
  
  # Test batch edit on nested structure
  db <- boilerplate_batch_edit(
    db = db,
    field = "reference",
    new_value = "sibley2024",
    category = "measures",
    target_entries = c("anxiety", "depression"),
    preview = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  expect_equal(db$measures$anxiety$reference, "sibley2024")
  expect_equal(db$measures$depression$reference, "sibley2024")
  
  # Test batch clean
  db$methods$test_section <- "Remove @special# characters[2024]"
  
  db <- boilerplate_batch_clean(
    db = db,
    field = "test_section",
    remove_chars = c("@", "#", "[", "]"),
    category = "methods",
    preview = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  expect_equal(db$methods$test_section, "Remove special characters2024")
})

test_that("Enhanced intro project workflow works", {
  skip_on_cran()  # Skip due to file system operations
  
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Initialize project structure
  project_root <- file.path(temp_dir, "my_project")
  
  # Create boilerplate in shared location
  boilerplate_init(
    data_path = file.path(project_root, "shared/boilerplate"),
    categories = c("methods", "measures", "results"),
    create_dirs = TRUE,
    create_empty = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  # Check structure created
  expect_true(dir.exists(file.path(project_root, "shared/boilerplate")))
  
  # Import and modify
  db <- boilerplate_import(
    data_path = file.path(project_root, "shared/boilerplate"),
    quiet = TRUE
  )
  
  db$methods$project_specific <- "This method is specific to my project."
  
  # Save back
  expect_true(
    boilerplate_save(
      db,
      data_path = file.path(project_root, "shared/boilerplate"),
      confirm = FALSE,
      quiet = TRUE
    )
  )
})