
<!-- README.md is generated from README.Rmd. Please edit that file -->

The `boilerplate` package offers a lightweight and flexible toolkit for
managing, accessing, and compiling boilerplate text templates. Designed
to streamline the creation and upkeep of template databases,
`boilerplate` allows users to efficiently store, retrieve, and update
their content. Initially, the package supports (quarto) markdown.

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

# connect to the default database (creates it if it doesn't exist)
conn <- boilerplate_connect_db()

# don't forget to disconnect from the database when done
dbDisconnect(conn)
```

## Code

Go to: <https://github.com/go-bayes/boilerplate>
