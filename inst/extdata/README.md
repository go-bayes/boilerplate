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