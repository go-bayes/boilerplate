# Unit tests for projects vignette examples
library(testthat)

test_that("projects vignette: default project basics work", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Test default project initialization
  boilerplate_init(
    data_path = temp_dir,
    create_dirs = TRUE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  # Import from default project
  db <- boilerplate_import(data_path = temp_dir, quiet = TRUE)
  
  expect_type(db, "list")
  expect_true("methods" %in% names(db))
  
  # Verify default project behavior
  db2 <- boilerplate_import(data_path = temp_dir, project = "default", quiet = TRUE)
  expect_equal(names(db), names(db2))
})

test_that("projects vignette: creating new projects works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Create lab shared project
  lab_path <- file.path(temp_dir, "projects", "lab_shared", "data")
  boilerplate_init(
    data_path = lab_path,
    project = "lab_shared",
    categories = c("methods", "measures"),
    create_dirs = TRUE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  expect_true(dir.exists(lab_path))
  expect_true(file.exists(file.path(lab_path, "boilerplate_unified.json")))
  
  # Create colleague's project
  smith_path <- file.path(temp_dir, "projects", "smith_measures", "data")
  boilerplate_init(
    data_path = smith_path,
    project = "smith_measures",
    categories = "measures",
    create_dirs = TRUE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  expect_true(dir.exists(smith_path))
})

test_that("projects vignette: working with specific projects works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Initialize lab project
  lab_path <- file.path(temp_dir, "projects", "lab_shared", "data")
  boilerplate_init(
    data_path = lab_path,
    project = "lab_shared",
    create_dirs = TRUE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  # Import from specific project
  lab_db <- boilerplate_import(
    data_path = lab_path,
    project = "lab_shared",
    quiet = TRUE
  )
  
  # Add content
  lab_db <- boilerplate_add_entry(
    lab_db,
    path = "methods.lab_protocol",
    value = "Standard lab protocol for data collection."
  )
  
  # Save to specific project
  expect_true(
    boilerplate_save(
      lab_db,
      data_path = lab_path,
      project = "lab_shared",
      confirm = FALSE,
      quiet = TRUE
    )
  )
  
  # Export from specific project
  export_file <- file.path(temp_dir, "lab_export.json")
  boilerplate_export(
    db = lab_db,
    output_file = export_file,
    data_path = lab_path,
    format = "json",
    confirm = FALSE,
    quiet = TRUE
  )
  
  expect_true(file.exists(export_file))
})

test_that("projects vignette: project organization structure works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Create multiple projects
  projects <- c("default", "lab_shared", "smith_measures")
  
  for (proj in projects) {
    proj_path <- file.path(temp_dir, "projects", proj, "data")
    boilerplate_init(
      data_path = proj_path,
      project = proj,
      create_dirs = TRUE,
      confirm = FALSE,
      quiet = TRUE
    )
  }
  
  # Check directory structure
  expect_true(dir.exists(file.path(temp_dir, "projects")))
  
  project_dirs <- list.dirs(
    file.path(temp_dir, "projects"),
    full.names = FALSE,
    recursive = FALSE
  )
  
  expect_true(all(projects %in% project_dirs))
  
  # Check each project has data directory
  for (proj in projects) {
    expect_true(
      dir.exists(file.path(temp_dir, "projects", proj, "data"))
    )
    expect_true(
      file.exists(
        file.path(temp_dir, "projects", proj, "data", "boilerplate_unified.json")
      )
    )
  }
})

test_that("projects vignette: importing content between projects works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Create source project
  source_path <- file.path(temp_dir, "projects", "source", "data")
  boilerplate_init(
    data_path = source_path,
    project = "source",
    create_dirs = TRUE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  source_db <- boilerplate_import(data_path = source_path, quiet = TRUE)
  
  # Add custom content
  source_db <- boilerplate_add_entry(
    source_db,
    path = "methods.special_technique",
    value = "This is a special technique we developed."
  )
  
  source_db <- boilerplate_add_entry(
    source_db,
    path = "measures.custom_scale",
    value = list(
      name = "Custom Scale",
      description = "A custom measurement scale",
      items = c("Item 1", "Item 2")
    )
  )
  
  boilerplate_save(source_db, data_path = source_path, confirm = FALSE, quiet = TRUE)
  
  # Create destination project
  dest_path <- file.path(temp_dir, "projects", "destination", "data")
  boilerplate_init(
    data_path = dest_path,
    project = "destination",
    create_dirs = TRUE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  dest_db <- boilerplate_import(data_path = dest_path, quiet = TRUE)
  
  # Import specific content from source
  dest_db$methods$special_technique <- source_db$methods$special_technique
  dest_db$measures$custom_scale <- source_db$measures$custom_scale
  
  boilerplate_save(dest_db, data_path = dest_path, confirm = FALSE, quiet = TRUE)
  
  # Verify content was imported
  final_db <- boilerplate_import(data_path = dest_path, quiet = TRUE)
  expect_equal(
    final_db$methods$special_technique,
    "This is a special technique we developed."
  )
  expect_equal(final_db$measures$custom_scale$name, "Custom Scale")
})

test_that("projects vignette: listing available projects works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Create several projects
  project_names <- c("project_a", "project_b", "research_2024")
  
  for (proj in project_names) {
    proj_path <- file.path(temp_dir, "projects", proj, "data")
    boilerplate_init(
      data_path = proj_path,
      project = proj,
      create_dirs = TRUE,
      confirm = FALSE,
      quiet = TRUE
    )
  }
  
  # List projects
  projects_dir <- file.path(temp_dir, "projects")
  available_projects <- list.dirs(
    projects_dir,
    full.names = FALSE,
    recursive = FALSE
  )
  
  expect_true(all(project_names %in% available_projects))
  expect_equal(length(available_projects), length(project_names))
})

test_that("projects vignette: project isolation works", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))
  
  # Create two independent projects
  proj1_path <- file.path(temp_dir, "projects", "project1", "data")
  proj2_path <- file.path(temp_dir, "projects", "project2", "data")
  
  # Initialize project 1
  boilerplate_init(
    data_path = proj1_path,
    project = "project1",
    create_dirs = TRUE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  db1 <- boilerplate_import(data_path = proj1_path, quiet = TRUE)
  db1 <- boilerplate_add_entry(
    db1,
    path = "methods.unique_to_proj1",
    value = "This method is only in project 1"
  )
  boilerplate_save(db1, data_path = proj1_path, confirm = FALSE, quiet = TRUE)
  
  # Initialize project 2
  boilerplate_init(
    data_path = proj2_path,
    project = "project2",
    create_dirs = TRUE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  db2 <- boilerplate_import(data_path = proj2_path, quiet = TRUE)
  db2 <- boilerplate_add_entry(
    db2,
    path = "methods.unique_to_proj2",
    value = "This method is only in project 2"
  )
  boilerplate_save(db2, data_path = proj2_path, confirm = FALSE, quiet = TRUE)
  
  # Verify isolation
  db1_check <- boilerplate_import(data_path = proj1_path, quiet = TRUE)
  db2_check <- boilerplate_import(data_path = proj2_path, quiet = TRUE)
  
  expect_true("unique_to_proj1" %in% names(db1_check$methods))
  expect_false("unique_to_proj2" %in% names(db1_check$methods))
  
  expect_true("unique_to_proj2" %in% names(db2_check$methods))
  expect_false("unique_to_proj1" %in% names(db2_check$methods))
})