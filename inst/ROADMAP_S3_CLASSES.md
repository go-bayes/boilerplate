# Roadmap: S3 Class Implementation for boilerplate Package

## Overview

This document outlines the plan to implement S3 classes for the boilerplate package, based on code review feedback received on 2025-06-12. The goal is to improve type safety, discoverability, and maintainability without breaking existing user code.

## Current State (v1.2.0)

- Package uses plain R lists for all database objects
- No formal type checking or validation
- Users can pass malformed data that fails deep in the call stack
- No IDE autocompletion support for database fields

## Proposed Implementation Timeline

### Phase 1: Light-weight S3 Facade (v1.2.1 - July 2025)

**Goal**: Add basic S3 class with zero breaking changes

**Implementation**:

```r
# New file: R/class-boilerplate-db.R

#' Constructor for boilerplate database objects
#' @param x A named list containing boilerplate categories
#' @param validate Logical. Should the structure be validated?
#' @return An object of class 'boilerplate_db'
#' @export
new_boilerplate_db <- function(x = list(), validate = TRUE) {
  stopifnot(is.list(x))
  
  if (validate && length(x) > 0) {
    # Check for valid top-level categories
    valid_categories <- c("methods", "measures", "results", "discussion", 
                         "appendix", "template", "bibliography", "meta")
    invalid <- setdiff(names(x), valid_categories)
    if (length(invalid) > 0) {
      warning("Unknown categories: ", paste(invalid, collapse = ", "))
    }
  }
  
  structure(x, 
    class = c("boilerplate_db", "list"),
    version = utils::packageVersion("boilerplate"),
    created = Sys.time()
  )
}

#' Coerce to boilerplate database
#' @param x An object to coerce
#' @return An object of class 'boilerplate_db'
#' @export
as_boilerplate_db <- function(x) {
  if (inherits(x, "boilerplate_db")) return(x)
  if (!is.list(x)) stop("Cannot coerce non-list to boilerplate_db")
  new_boilerplate_db(x)
}

#' @export
print.boilerplate_db <- function(x, ...) {
  cat("<boilerplate database>\n")
  cat("  Version:", attr(x, "version"), "\n")
  cat("  Categories:", paste(names(x), collapse = ", "), "\n")
  
  # Show entry counts
  for (cat in names(x)) {
    if (is.list(x[[cat]])) {
      cat(sprintf("  - %s: %d entries\n", cat, length(x[[cat]])))
    }
  }
  invisible(x)
}
```

**Changes needed**:
1. Update `boilerplate_import()` to return `new_boilerplate_db(db)`
2. Update `boilerplate_init()` to create classed objects
3. Add `as_boilerplate_db()` calls at the start of exported functions
4. Add tests for S3 methods
5. Update NEWS.md and increment to v1.2.1

### Phase 2: Enhanced S3 Methods (v1.3.0 - September 2025)

**Goal**: Add useful S3 generics for better UX

**New methods**:
- `validate.boilerplate_db()` - comprehensive validation
- `[.boilerplate_db()` - subset while maintaining class
- `[[.boilerplate_db()` - safe extraction with validation
- `summary.boilerplate_db()` - database statistics
- `merge.boilerplate_db()` - type-safe merging

**Example implementation**:

```r
#' @export
validate.boilerplate_db <- function(x, ...) {
  errors <- character()
  
  # Check structure
  if (!is.list(x)) {
    errors <- c(errors, "Database must be a list")
  }
  
  # Check categories
  for (cat in names(x)) {
    if (!is.list(x[[cat]]) && !is.null(x[[cat]])) {
      errors <- c(errors, sprintf("Category '%s' must be a list or NULL", cat))
    }
  }
  
  # Return validation result
  if (length(errors) == 0) {
    message("✓ Valid boilerplate database")
    invisible(TRUE)
  } else {
    warning("Validation failed:\n", paste("  -", errors, collapse = "\n"))
    invisible(FALSE)
  }
}

#' @export
`[[.boilerplate_db` <- function(x, i, ...) {
  result <- NextMethod()
  
  # Add validation for known categories
  if (i %in% c("methods", "measures", "results", "discussion", "appendix", "template")) {
    if (!is.null(result) && !is.list(result)) {
      warning(sprintf("Category '%s' should be a list, found %s", i, class(result)[1]))
    }
  }
  
  result
}
```

### Phase 3: S7 Migration (v2.0.0 - 2026+)

**Goal**: Future-proof with S7 while maintaining backward compatibility

**Prerequisites**:
- S7 reaches v1.0.0 on CRAN
- Widespread tidyverse adoption
- Community best practices established

**Implementation approach**:
1. Create S7 classes that mirror S3 API
2. Ship behind feature flag: `options(boilerplate.use_s7 = TRUE)`
3. Maintain S3 wrappers for backward compatibility
4. Gradual migration over 2-3 versions

## Implementation Checklist for v1.2.1

- [ ] Create `R/class-boilerplate-db.R` with S3 class definition
- [ ] Update `boilerplate_import()` to return classed objects
- [ ] Update `boilerplate_init()` to create classed objects  
- [ ] Add `as_boilerplate_db()` to top of major exported functions
- [ ] Write tests in `tests/testthat/test-class-boilerplate-db.R`
- [ ] Update documentation to mention S3 class
- [ ] Add to NEWS.md
- [ ] Increment version to 1.2.1
- [ ] Run full R CMD check
- [ ] Update code coverage

## Benefits

1. **Immediate** (v1.2.1):
   - Better print output
   - Basic validation
   - Foundation for future improvements
   - Zero breaking changes

2. **Near-term** (v1.3.0):
   - IDE autocompletion
   - Type safety
   - Consistent validation
   - Better error messages

3. **Long-term** (v2.0.0):
   - Full type system
   - Multiple dispatch
   - Modern R practices
   - Performance optimizations

## Risks and Mitigation

| Risk | Mitigation |
|------|------------|
| Breaking existing code | Use S3 inheritance from list; extensive testing |
| User confusion | Clear documentation; gradual rollout |
| Maintenance burden | Start simple; S7 reduces long-term burden |
| Package bloat | S3 is lightweight; S7 is optional |

## Decision Point: v1.2.0 vs v1.2.1

### Option A: Include in v1.2.0
**Pros**:
- One CRAN submission instead of two
- Users get benefits immediately
- Shows responsiveness to review

**Cons**:
- Delays v1.2.0 submission
- Mixes bug fixes with new features
- Less testing time

### Option B: Release as v1.2.1
**Pros**:
- v1.2.0 focuses on CRAN compliance
- More time to test S3 implementation
- Cleaner release notes
- Follow-up release shows active development

**Cons**:
- Users wait longer for improvements
- Two CRAN submissions

### Recommendation: Release as v1.2.1

Submit v1.2.0 as-is to address CRAN feedback, then implement S3 classes in v1.2.1 (July 2025). This approach:
1. Gets critical fixes to CRAN quickly
2. Allows proper testing of S3 implementation
3. Demonstrates ongoing development
4. Keeps releases focused

## Code Review Reference

Original review date: 2025-06-12
Reviewer: [Stored separately for privacy]
Key points: Need for type safety, evolution path, S3→S7 migration strategy