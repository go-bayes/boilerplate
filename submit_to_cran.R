#!/usr/bin/env Rscript

# Script to submit boilerplate package to CRAN
# Run this interactively in R

# First, run release() to check everything and prepare for release
devtools::release()

# This will:
# 1. Run R CMD check
# 2. Check that you're using the latest versions of dependencies
# 3. Check your DESCRIPTION file
# 4. Check NEWS.md
# 5. Check GitHub for any issues
# 6. Build the package
# 7. Submit to CRAN

# If you need to submit manually after running release(), use:
# devtools::submit_cran()