#' Connect to the Boilerplate SQLite Database
#'
#' This function establishes a connection to the SQLite database used for storing
#' boilerplate templates and measures. If the database doesn't exist, it will be
#' created. The default location is in the 'data' directory of the project.
#'
#' @param db_name A character string specifying the name of the database file.
#'   Defaults to "boilerplate.sqlite".
#' @param data_dir A character string specifying the directory where the database
#'   should be stored. Defaults to "data" in the project root.
#'
#' @return A DBIConnection object representing the database connection.
#'
#' @import RSQLite
#' @import DBI
#' @import here
#'
#' @examples
#' # Connect to the default database
#' conn <- boilerplate_connect_db()
#'
#' # Connect to a specific database
#' conn <- boilerplate_connect_db("my_boilerplate.sqlite")
#'
#' # Don't forget to close the connection when you're done
#' dbDisconnect(conn)
#'
#' @export
boilerplate_connect_db <- function(db_name = "boilerplate.sqlite", data_dir = "data") {
  # Ensure the data directory exists
  dir.path <- here::here(data_dir)
  if (!dir.exists(dir.path)) {
    dir.create(dir.path, recursive = TRUE)
  }

  # Construct the full path to the database
  db_path <- here::here(data_dir, db_name)

  # Connect to the database (it will be created if it doesn't exist)
  conn <- dbConnect(RSQLite::SQLite(), db_path)

  # Create the 'templates' table if it doesn't exist
  if (!dbExistsTable(conn, "templates")) {
    result <- try(dbExecute(conn, "
      CREATE TABLE templates (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        content TEXT NOT NULL,
        tags TEXT
      )
    "), silent = TRUE)
    if (inherits(result, "try-error")) {
      stop("Failed to create 'templates' table.")
    }
  }

  # Create the 'measures' table if it doesn't exist
  if (!dbExistsTable(conn, "measures")) {
    result <- try(dbExecute(conn, "
      CREATE TABLE measures (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        reference TEXT,
        waves TEXT,
        keywords TEXT
      )
    "), silent = TRUE)
    if (inherits(result, "try-error")) {
      stop("Failed to create 'measures' table.")
    }
  }

  # Create the 'items' table if it doesn't exist
  if (!dbExistsTable(conn, "items")) {
    result <- try(dbExecute(conn, "
      CREATE TABLE items (
        id INTEGER PRIMARY KEY,
        measure_id INTEGER,
        item_text TEXT,
        FOREIGN KEY (measure_id) REFERENCES measures (id)
      )
    "), silent = TRUE)
    if (inherits(result, "try-error")) {
      stop("Failed to create 'items' table.")
    }
  }

  return(conn)
}
