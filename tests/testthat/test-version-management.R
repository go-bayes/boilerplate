test_that("boilerplate_import can import from file path", {
  # Create temporary directory
  temp_dir <- tempdir()
  test_dir <- file.path(temp_dir, "test_version_management")
  dir.create(test_dir, showWarnings = FALSE)
  data_path <- file.path(test_dir, "data")
  
  # Initialise a test database
  boilerplate_init(
    categories = "methods",
    data_path = data_path,
    create_dirs = TRUE,
    create_empty = FALSE,
    confirm = FALSE,
    quiet = TRUE
  )
  
  # Create a test database
  test_db <- list(
    sample = list(default = "Test sample text"),
    analysis = list(default = "Test analysis text")
  )
  
  # Save with timestamp (explicitly as RDS for this test)
  boilerplate_save(
    db = test_db,
    category = "methods",
    data_path = data_path,
    timestamp = TRUE,
    format = "rds",
    confirm = FALSE,
    quiet = TRUE
  )
  
  # Find the timestamped file
  files <- list.files(data_path, pattern = "methods_db_.*\\.rds", full.names = TRUE)
  timestamped_file <- files[grepl("_\\d{8}_\\d{6}\\.rds$", files)][1]
  
  # Test importing from file path
  imported_db <- boilerplate_import(data_path = timestamped_file, quiet = TRUE)
  
  expect_equal(imported_db$sample$default, "Test sample text")
  expect_equal(imported_db$analysis$default, "Test analysis text")
  
  # Clean up
  unlink(test_dir, recursive = TRUE)
})

test_that("boilerplate_list_files organises files correctly", {
  # Create temporary directory
  temp_dir <- tempdir()
  test_dir <- file.path(temp_dir, "test_list_files")
  dir.create(test_dir, showWarnings = FALSE)
  data_path <- file.path(test_dir, "data")
  dir.create(data_path, showWarnings = FALSE)
  
  # Create different types of files
  # Standard file
  saveRDS(list(test = "data"), file.path(data_path, "methods_db.rds"))
  
  # Timestamped file
  saveRDS(list(test = "data"), file.path(data_path, "methods_db_20240115_143022.rds"))
  
  # Backup file
  saveRDS(list(test = "data"), file.path(data_path, "methods_db_backup_20240115_140000.rds"))
  
  # Other file
  saveRDS(list(test = "data"), file.path(data_path, "custom_file.rds"))
  
  # List files
  files <- boilerplate_list_files(data_path = data_path)
  
  # Check organisation
  expect_equal(nrow(files$standard), 1)
  expect_equal(nrow(files$timestamped), 1)
  expect_equal(nrow(files$backups), 1)
  expect_equal(nrow(files$other), 1)
  
  # Check file names
  expect_equal(files$standard$file, "methods_db.rds")
  expect_equal(files$timestamped$file, "methods_db_20240115_143022.rds")
  expect_equal(files$backups$file, "methods_db_backup_20240115_140000.rds")
  expect_equal(files$other$file, "custom_file.rds")
  
  # Clean up
  unlink(test_dir, recursive = TRUE)
})

test_that("boilerplate_list_files filters by category", {
  # Create temporary directory
  temp_dir <- tempdir()
  test_dir <- file.path(temp_dir, "test_filter_category")
  dir.create(test_dir, showWarnings = FALSE)
  data_path <- file.path(test_dir, "data")
  dir.create(data_path, showWarnings = FALSE)
  
  # Create files for different categories
  saveRDS(list(test = "data"), file.path(data_path, "methods_db.rds"))
  saveRDS(list(test = "data"), file.path(data_path, "measures_db.rds"))
  saveRDS(list(test = "data"), file.path(data_path, "methods_db_20240115_143022.rds"))
  saveRDS(list(test = "data"), file.path(data_path, "measures_db_20240115_143022.rds"))
  
  # List only methods files
  methods_files <- boilerplate_list_files(data_path = data_path, category = "methods")
  
  # Check that only methods files are returned
  all_files <- c(methods_files$standard$file, methods_files$timestamped$file)
  expect_true(all(grepl("^methods_db", all_files)))
  expect_false(any(grepl("^measures_db", all_files)))
  
  # Clean up
  unlink(test_dir, recursive = TRUE)
})

test_that("boilerplate_restore_backup works correctly", {
  # Create temporary directory
  temp_dir <- tempdir()
  test_dir <- file.path(temp_dir, "test_restore_backup")
  dir.create(test_dir, showWarnings = FALSE)
  data_path <- file.path(test_dir, "data")
  dir.create(data_path, showWarnings = FALSE)
  
  # Create initial database
  initial_db <- list(
    sample = list(default = "Initial sample text"),
    analysis = list(default = "Initial analysis text")
  )
  
  # Save as standard file
  saveRDS(initial_db, file.path(data_path, "methods_db.rds"))
  
  # Create a backup file manually
  backup_db <- list(
    sample = list(default = "Backup sample text"),
    analysis = list(default = "Backup analysis text")
  )
  
  backup_file <- file.path(data_path, "methods_db_backup_20240110_120000.rds")
  saveRDS(backup_db, backup_file)
  
  # Test viewing backup without restoring
  viewed_db <- boilerplate_restore_backup(
    category = "methods",
    data_path = data_path,
    restore = FALSE,
    quiet = TRUE
  )
  
  expect_equal(viewed_db$sample$default, "Backup sample text")
  
  # Check that standard file hasn't changed
  current_db <- boilerplate_import("methods", data_path = data_path, quiet = TRUE)
  expect_equal(current_db$sample$default, "Initial sample text")
  
  # Clean up
  unlink(test_dir, recursive = TRUE)
})

test_that("boilerplate_import handles non-existent files gracefully", {
  expect_error(
    boilerplate_import(data_path = "/non/existent/file.rds"),
    "Data path does not exist"
  )
})

test_that("boilerplate_import validates file extensions", {
  # Create a temporary text file
  temp_file <- tempfile(fileext = ".txt")
  writeLines("test", temp_file)
  
  expect_error(
    boilerplate_import(data_path = temp_file),
    "File must have .rds or .json extension"
  )
  
  unlink(temp_file)
})

test_that("print.boilerplate_files produces correct output", {
  # Create temporary directory
  temp_dir <- tempdir()
  test_dir <- file.path(temp_dir, "test_print_files")
  dir.create(test_dir, showWarnings = FALSE)
  data_path <- file.path(test_dir, "data")
  dir.create(data_path, showWarnings = FALSE)
  
  # Create a standard file
  saveRDS(list(test = "data"), file.path(data_path, "methods_db.rds"))
  
  # List files
  files <- boilerplate_list_files(data_path = data_path)
  
  # Capture print output
  output <- capture.output(print(files))
  
  # Check output contains expected sections
  expect_true(any(grepl("Boilerplate Database Files", output)))
  expect_true(any(grepl("Standard files:", output)))
  expect_true(any(grepl("methods_db.rds", output)))
  
  # Clean up
  unlink(test_dir, recursive = TRUE)
})

test_that("boilerplate_list_files handles empty directories", {
  # Create empty directory
  temp_dir <- tempdir()
  test_dir <- file.path(temp_dir, "test_empty_dir")
  dir.create(test_dir, showWarnings = FALSE)
  
  # List files in empty directory
  expect_message(
    files <- boilerplate_list_files(data_path = test_dir),
    "No database files found"
  )
  
  # Check structure is still returned
  expect_equal(nrow(files$standard), 0)
  expect_equal(nrow(files$timestamped), 0)
  expect_equal(nrow(files$backups), 0)
  expect_equal(nrow(files$other), 0)
  
  # Clean up
  unlink(test_dir, recursive = TRUE)
})

test_that("boilerplate_restore_backup handles missing backups", {
  # Create temporary directory
  temp_dir <- tempdir()
  test_dir <- file.path(temp_dir, "test_no_backups")
  dir.create(test_dir, showWarnings = FALSE)
  data_path <- file.path(test_dir, "data")
  dir.create(data_path, showWarnings = FALSE)
  
  # Create only standard file (no backups)
  saveRDS(list(test = "data"), file.path(data_path, "methods_db.rds"))
  
  # Try to restore backup
  expect_error(
    boilerplate_restore_backup(
      category = "methods",
      data_path = data_path,
      quiet = TRUE
    ),
    "No backup files found"
  )
  
  # Clean up
  unlink(test_dir, recursive = TRUE)
})