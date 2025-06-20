# Unit tests for quarto-workflow vignette examples
library(testthat)

test_that("Quarto workflow basic integration works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Initialize boilerplate
  boilerplate_init(
    data_path = file.path(temp_dir, ".boilerplate-data"),
    create_dirs = TRUE,
    create_empty = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  # Import database
  db <- boilerplate_import(
    data_path = file.path(temp_dir, ".boilerplate-data"),
    quiet = TRUE
  )
  
  # Test generating methods section
  methods_text <- boilerplate_generate_text(
    category = "methods",
    sections = c("sample", "statistical.default"),
    global_vars = list(
      population = "New Zealand adults",
      timeframe = "2020-2024"
    ),
    db = db,
    add_headings = TRUE,
    quiet = TRUE
  )
  
  expect_type(methods_text, "character")
  expect_true(grepl("### Sample", methods_text))
  expect_true(grepl("New Zealand adults", methods_text))
  expect_true(grepl("2020-2024", methods_text))
})

test_that("Quarto workflow with child documents works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Create project structure
  project_dir <- file.path(temp_dir, "quarto_project")
  dir.create(project_dir, recursive = TRUE)
  
  # Initialize boilerplate
  boilerplate_init(
    data_path = file.path(project_dir, ".boilerplate-data"),
    create_dirs = TRUE,
    create_empty = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  db <- boilerplate_import(
    data_path = file.path(project_dir, ".boilerplate-data"),
    quiet = TRUE
  )
  
  # Generate and save methods to file
  methods_text <- boilerplate_generate_text(
    category = "methods",
    sections = c("sample", "causal_assumptions.identification"),
    db = db,
    add_headings = TRUE,
    quiet = TRUE
  )
  
  # Write to child document
  methods_file <- file.path(project_dir, "_methods.qmd")
  writeLines(methods_text, methods_file)
  
  expect_true(file.exists(methods_file))
  expect_true(length(readLines(methods_file)) > 0)
})

test_that("Quarto workflow with bibliography works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Create project structure
  project_dir <- file.path(temp_dir, "quarto_project")
  manuscript_dir <- file.path(project_dir, "manuscript")
  dir.create(manuscript_dir, recursive = TRUE)
  
  # Initialize
  boilerplate_init(
    data_path = file.path(project_dir, ".boilerplate-data"),
    create_dirs = TRUE,
    create_empty = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  db <- boilerplate_import(
    data_path = file.path(project_dir, ".boilerplate-data"),
    quiet = TRUE
  )
  
  # Add bibliography
  db <- boilerplate_add_bibliography(
    db,
    url = "https://example.com/refs.bib",
    local_path = file.path(project_dir, "references.bib")
  )
  
  # Save database
  boilerplate_save(
    db,
    data_path = file.path(project_dir, ".boilerplate-data"),
    confirm = FALSE,
    quiet = TRUE
  )
  
  # Create dummy bib file
  writeLines(
    "@article{test2024,\n  title = {Test Article},\n  author = {Author, A.},\n  year = {2024}\n}",
    file.path(project_dir, "references.bib")
  )
  
  # Generate with bibliography copy
  # Since we're not actually downloading, skip the copy test
  methods_text <- boilerplate_generate_text(
    category = "methods",
    sections = "statistical.longitudinal.lmtp",
    db = db,
    copy_bibliography = FALSE,  # Don't try to copy non-existent file
    quiet = TRUE
  )
  
  expect_type(methods_text, "character")
  expect_true(grepl("LMTP", methods_text))
})

test_that("Quarto workflow template document works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Initialize
  boilerplate_init(
    data_path = file.path(temp_dir, ".boilerplate-data"),
    create_dirs = TRUE,
    create_empty = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  db <- boilerplate_import(
    data_path = file.path(temp_dir, ".boilerplate-data"),
    quiet = TRUE
  )
  
  # Add template content
  db$template$manuscript <- list(
    yaml_header = "---\ntitle: '{{title}}'\nauthor: '{{author}}'\ndate: '{{date}}'\n---\n",
    abstract = "## Abstract\n\n{{abstract_text}}\n",
    intro = "## Introduction\n\n{{intro_text}}\n"
  )
  
  # Save
  boilerplate_save(
    db,
    data_path = file.path(temp_dir, ".boilerplate-data"),
    confirm = FALSE,
    quiet = TRUE
  )
  
  # Generate template - correct function signature
  template_text <- boilerplate_template(
    unified_db = db,
    name = "manuscript"
  )
  
  expect_type(template_text, "list")
  expect_true("yaml_header" %in% names(template_text))
  expect_true(grepl("\\{\\{title\\}\\}", template_text$yaml_header))
})