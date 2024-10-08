% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/boilerplate_merge_database.R
\name{boilerplate_merge_databases}
\alias{boilerplate_merge_databases}
\title{Merge Two Measure Databases}
\usage{
boilerplate_merge_databases(
  db1,
  db2,
  db1_name = "Database 1",
  db2_name = "Database 2"
)
}
\arguments{
\item{db1}{A list representing the first measure database.}

\item{db2}{A list representing the second measure database.}

\item{db1_name}{Character string. The name of the first database (default: "Database 1").}

\item{db2_name}{Character string. The name of the second database (default: "Database 2").}
}
\value{
A list representing the merged measure database.
}
\description{
This function merges two measure databases, allowing the user to resolve conflicts
when the same measure exists in both databases with different content.
}
\details{
The function iterates through all measures in both databases. When a measure exists
in both databases:
\itemize{
\item If the entries are identical, it keeps one copy.
\item If the entries differ, it prompts the user to choose which entry to keep.
}
Measures that exist in only one database are automatically added to the merged database.
}
\examples{
\dontrun{
# Merge two databases with default names
merged_db <- boilerplate_merge_databases(test_a, test_b)

# Merge two databases with custom names
merged_db <- boilerplate_merge_database(test_a, test_b, "NZAVS 2009", "NZAVS 2020")
}

}
