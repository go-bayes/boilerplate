test_that("boilerplate_save emits deprecation warning for format = 'rds'", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  db <- list(methods = list(sample = list(default = "text")))

  expect_warning(
    boilerplate_save(
      db = db,
      data_path = temp_dir,
      format = "rds",
      confirm = FALSE,
      quiet = TRUE,
      timestamp = FALSE
    ),
    regexp = "deprecated"
  )
})

test_that("boilerplate_save emits deprecation warning for format = 'both'", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  db <- list(methods = list(sample = list(default = "text")))

  expect_warning(
    boilerplate_save(
      db = db,
      data_path = temp_dir,
      format = "both",
      confirm = FALSE,
      quiet = TRUE,
      timestamp = FALSE
    ),
    regexp = "deprecated"
  )
})

test_that("boilerplate_save is silent for format = 'json' (default)", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  db <- list(methods = list(sample = list(default = "text")))

  # no deprecation warning on the supported path
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

test_that("boilerplate_export emits deprecation warning for format = 'rds'", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  db <- list(methods = list(sample = list(default = "text")))

  expect_warning(
    boilerplate_export(
      db = db,
      data_path = temp_dir,
      format = "rds",
      confirm = FALSE,
      quiet = TRUE
    ),
    regexp = "deprecated"
  )
})

test_that("boilerplate_export emits deprecation warning for format = 'both'", {
  temp_dir <- tempfile()
  dir.create(temp_dir)
  on.exit(unlink(temp_dir, recursive = TRUE))

  db <- list(methods = list(sample = list(default = "text")))

  expect_warning(
    boilerplate_export(
      db = db,
      data_path = temp_dir,
      format = "both",
      confirm = FALSE,
      quiet = TRUE
    ),
    regexp = "deprecated"
  )
})
