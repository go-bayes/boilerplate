test_that("boilerplate_save rejects format = 'rds'", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  db <- list(methods = list(sample = list(default = "text")))

  expect_error(
    boilerplate_save(
      db = db,
      data_path = temp_dir,
      format = "rds",
      confirm = FALSE,
      quiet = TRUE,
      timestamp = FALSE
    ),
    regexp = "RDS writing is no longer supported"
  )
  expect_false(file.exists(file.path(temp_dir, "boilerplate_unified.rds")))
})

test_that("boilerplate_save rejects format = 'both'", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  db <- list(methods = list(sample = list(default = "text")))

  expect_error(
    boilerplate_save(
      db = db,
      data_path = temp_dir,
      format = "both",
      confirm = FALSE,
      quiet = TRUE,
      timestamp = FALSE
    ),
    regexp = "RDS writing is no longer supported"
  )
  expect_equal(list.files(temp_dir), character(0))
})

test_that("boilerplate_save is silent for format = 'json' (default)", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  db <- list(methods = list(sample = list(default = "text")))

  # no warning or error on the supported path
  expect_no_warning(
    boilerplate_save(
      db = db,
      data_path = temp_dir,
      format = "json",
      confirm = FALSE,
      quiet = TRUE,
      timestamp = FALSE
    )
  )
})

test_that("boilerplate_export rejects format = 'rds'", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  db <- list(methods = list(sample = list(default = "text")))

  expect_error(
    boilerplate_export(
      db = db,
      data_path = temp_dir,
      format = "rds",
      confirm = FALSE,
      quiet = TRUE
    ),
    regexp = "RDS writing is no longer supported"
  )
  expect_equal(list.files(temp_dir), character(0))
})

test_that("boilerplate_export rejects format = 'both'", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  db <- list(methods = list(sample = list(default = "text")))

  expect_error(
    boilerplate_export(
      db = db,
      data_path = temp_dir,
      format = "both",
      confirm = FALSE,
      quiet = TRUE
    ),
    regexp = "RDS writing is no longer supported"
  )
  expect_equal(list.files(temp_dir), character(0))
})

test_that("boilerplate_init rejects RDS write formats before creating directories", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))

  expect_error(
    boilerplate_init(
      data_path = temp_dir,
      format = "rds",
      create_dirs = TRUE,
      confirm = FALSE,
      quiet = TRUE
    ),
    regexp = "RDS writing is no longer supported"
  )
  expect_false(dir.exists(temp_dir))
})

test_that("boilerplate_export rejects .rds output_file before creating directories", {
  temp_dir <- tempfile()
  on.exit(unlink(temp_dir, recursive = TRUE))

  db <- list(methods = list(sample = list(default = "text")))

  expect_error(
    boilerplate_export(
      db = db,
      data_path = temp_dir,
      output_file = "export.rds",
      create_dirs = TRUE,
      confirm = FALSE,
      quiet = TRUE
    ),
    regexp = "RDS writing is no longer supported"
  )
  expect_false(dir.exists(temp_dir))
})

test_that("boilerplate_import emits a real warning before reading legacy RDS", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  saveRDS(
    list(methods = list(source = "rds")),
    file.path(temp_dir, "boilerplate_unified.rds")
  )

  expect_warning(
    imported <- boilerplate_import(data_path = temp_dir, quiet = TRUE),
    regexp = "Reading legacy RDS database"
  )
  expect_equal(imported$methods$source, "rds")
})

test_that("boilerplate_import prefers unified JSON when JSON and RDS both exist", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  saveRDS(
    list(methods = list(source = "rds")),
    file.path(temp_dir, "boilerplate_unified.rds")
  )
  jsonlite::write_json(
    list(methods = list(source = "json")),
    file.path(temp_dir, "boilerplate_unified.json"),
    auto_unbox = TRUE
  )

  expect_no_warning(
    imported <- boilerplate_import(data_path = temp_dir, quiet = TRUE)
  )
  expect_equal(imported$methods$source, "json")
})

test_that("boilerplate_import warns when newer unified RDS is shadowed by JSON", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  json_path <- file.path(temp_dir, "boilerplate_unified.json")
  rds_path <- file.path(temp_dir, "boilerplate_unified.rds")

  jsonlite::write_json(
    list(methods = list(source = "json")),
    json_path,
    auto_unbox = TRUE
  )
  saveRDS(
    list(methods = list(source = "rds")),
    rds_path
  )
  Sys.setFileTime(rds_path, Sys.time() + 10)

  expect_warning(
    imported <- boilerplate_import(data_path = temp_dir, quiet = TRUE),
    regexp = "Ignoring newer legacy RDS database"
  )
  expect_equal(imported$methods$source, "json")
})

test_that("boilerplate_import prefers category JSON when JSON and RDS both exist", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  saveRDS(
    list(source = "rds"),
    file.path(temp_dir, "methods_db.rds")
  )
  jsonlite::write_json(
    list(source = "json"),
    file.path(temp_dir, "methods_db.json"),
    auto_unbox = TRUE
  )

  expect_no_warning(
    imported <- boilerplate_import(
      category = "methods",
      data_path = temp_dir,
      quiet = TRUE
    )
  )
  expect_equal(imported$source, "json")
})

test_that("boilerplate_import warns when newer category RDS is shadowed by JSON", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  json_path <- file.path(temp_dir, "methods_db.json")
  rds_path <- file.path(temp_dir, "methods_db.rds")

  jsonlite::write_json(
    list(source = "json"),
    json_path,
    auto_unbox = TRUE
  )
  saveRDS(
    list(source = "rds"),
    rds_path
  )
  Sys.setFileTime(rds_path, Sys.time() + 10)

  expect_warning(
    imported <- boilerplate_import(
      category = "methods",
      data_path = temp_dir,
      quiet = TRUE
    ),
    regexp = "Ignoring newer legacy RDS database"
  )
  expect_equal(imported$source, "json")
})

test_that("migration helpers emit real warnings before reading legacy RDS", {
  temp_dir <- tempfile()
  output_dir <- tempfile()
  dir.create(temp_dir)
  dir.create(output_dir)
  on.exit(unlink(c(temp_dir, output_dir), recursive = TRUE))

  rds_file <- file.path(temp_dir, "methods_db.rds")
  json_file <- file.path(temp_dir, "methods_db.json")
  saveRDS(list(source = "rds"), rds_file)
  jsonlite::write_json(list(source = "rds"), json_file, auto_unbox = TRUE)

  expect_warning(
    boilerplate_rds_to_json(rds_file, quiet = TRUE),
    regexp = "Reading legacy RDS database"
  )
  expect_warning(
    boilerplate_migrate_to_json(
      source_path = rds_file,
      output_path = output_dir,
      validate = FALSE,
      quiet = TRUE
    ),
    regexp = "Reading legacy RDS database"
  )
  expect_warning(
    compare_rds_json(rds_file, json_file),
    regexp = "Reading legacy RDS database"
  )
})
