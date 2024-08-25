
<!-- README.md is generated from README.Rmd. Please edit that file -->

The `boilerplate` package offers a lightweight and flexible toolkit for
managing, accessing, and compiling reports and from templates
(boilerplates). Simple and intutive command line interfaces allows users
to efficiently store, retrieve, and update their content. Outputed
markdown text can be dropped directly into markdown documents, such as
`quarto` documents.

## Installation

You can install the development version of `boilerplate` from GitHub
with:

``` r
# Install the devtools package if you don't have it already
install.packages("devtools")

# Install boilerplate from GitHub
devtools::install_github("go-bayes/boilerplate")
```

## Example

This is a basic example that shows you how to connect to the boilerplate
database and create the necessary tables:

``` r
library(boilerplate)
library(here)

# set path to data folder
measures_path <-  here::here("boilerplate", 'data')

# open gui to enter and save measures data
boilerplate_manage_measures(measures_path = measures_path)
```

## Code

Go to: <https://github.com/go-bayes/boilerplate>
