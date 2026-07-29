# Example Data Files

This directory contains example data files for the boilerplate package:

## example_measures.csv
A CSV file containing example measure definitions with the following fields:
- name: The measure identifier
- description: Brief description of the measure
- reference: Citation key
- items: Pipe-separated list of items
- waves: Which waves the measure was collected
- keywords: Pipe-separated keywords

## example_methods.json
A JSON file showing how methods text can be organized hierarchically with template variables.

## lmtp_boilerplate.json
A unified database (`methods` and `results` categories) holding the standardised
narration for longitudinal modified treatment policy reporting under the
NZAVS-LMTP-v1 workflow. Reporting software resolves entries by dot-separated
path — for example `methods.lmtp.density_ratio_report.upper_tail` — and
substitutes realised values through the `{{variable}}` syntax, so that a
registration, its reports, and any later manuscript speak identical language
from one versioned source.

Every string in this database is taken verbatim from the approved NZAVS-LMTP-v1
registration; template variables replace registered or study-specific values
only. Entries whose value begins `TODO(author)` await author wording and name
the variables their narration will carry. The file is rebuilt by
`data-raw/lmtp-boilerplate-entries.R`, which verifies each non-templated
sentence against the registration source.

```r
lmtp_db <- boilerplate_import(
  data_path = system.file("extdata", "lmtp_boilerplate.json", package = "boilerplate"),
  quiet = TRUE
)
boilerplate_generate_text(
  category = "methods",
  sections = "lmtp.instrument_limits.denominator_bound",
  global_vars = list(lmtp_version = "1.5.4"),
  db = lmtp_db
)
```

## Usage

These files can be used as templates for organizing your own boilerplate content. To load them:

```r
# Get path to example files
measures_file <- system.file("extdata", "example_measures.csv", package = "boilerplate")
methods_file <- system.file("extdata", "example_methods.json", package = "boilerplate")

# Read the files
measures_df <- read.csv(measures_file, stringsAsFactors = FALSE)
methods_list <- jsonlite::fromJSON(methods_file)
```