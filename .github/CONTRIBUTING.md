# Contributing to boilerplate

We welcome contributions to the boilerplate package! This guide will help you get started.

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone https://github.com/YOUR-USERNAME/boilerplate.git
   cd boilerplate
   ```
3. Create a new branch for your feature or fix:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Setup

### Prerequisites

- R >= 4.1
- RStudio (recommended)
- devtools package: `install.packages("devtools")`
- roxygen2 package: `install.packages("roxygen2")`

### Building and Testing

```r
# Load all functions for interactive development
devtools::load_all()

# Run tests
devtools::test()

# Check package
devtools::check()

# Build documentation
devtools::document()
```

## Code Style

We follow the tidyverse style guide. Key points:

- Use meaningful variable names
- Indent with 2 spaces (no tabs)
- Place spaces around operators (=, +, -, etc.)
- Use `<-` for assignment, not `=`
- Maximum line length of 80 characters

### Function Naming

- Public functions: `boilerplate_action()` or `boilerplate_category_action()`
- Internal functions: `action_object()` (no prefix)
- Use snake_case for all names

## Making Changes

### Adding New Features

1. **Discuss First**: Open an issue to discuss significant changes
2. **Write Tests**: Add tests for new functionality
3. **Document**: Include roxygen2 documentation
4. **Update Vignettes**: Add examples if relevant

### Code Structure

When adding new functionality, follow the existing patterns:

```r
#' Title (imperative mood, e.g., "Create new database")
#'
#' Description of what the function does.
#'
#' @param param1 Description of parameter
#' @param param2 Description of parameter
#'
#' @return What the function returns
#'
#' @examples
#' \dontrun{
#' boilerplate_example(param1 = "value")
#' }
#'
#' @export
boilerplate_example <- function(param1, param2 = NULL) {
  # Input validation
  if (!is.character(param1)) {
    stop("param1 must be a character string")
  }
  
  # Main logic
  result <- process_data(param1, param2)
  
  # Return
  invisible(result)
}
```

### Internal Functions

Document internal functions with roxygen2 but include `@noRd`:

```r
#' Internal function to process data
#'
#' @param data Input data
#' @return Processed data
#' @noRd
process_data <- function(data) {
  # Implementation
}
```

## Testing

### Test Organisation

Place tests in `tests/testthat/` following the naming pattern `test-*.R`

### Writing Tests

```r
test_that("function performs expected action", {
  # Arrange
  input <- "test_data"
  
  # Act
  result <- boilerplate_function(input)
  
  # Assert
  expect_equal(result, expected_output)
  expect_true(is.character(result))
})
```

### Test Coverage

- Test happy paths and edge cases
- Test error conditions
- Test with different input types
- Ensure backwards compatibility

## Documentation

### Function Documentation

All exported functions must have complete roxygen2 documentation including:
- Title and description
- All parameters documented
- Return value documented
- At least one example
- Any important notes or warnings

### Vignettes

For significant features, consider adding or updating vignettes:
- Place in `vignettes/` directory
- Use clear, practical examples
- Explain concepts before code
- Test all code examples

## Submitting Changes

### Before Submitting

1. Run all tests: `devtools::test()`
2. Check package: `devtools::check()`
3. Update documentation: `devtools::document()`
4. Update NEWS.md with your changes
5. Ensure all files use NZ English spelling

### Pull Request Process

1. Push your branch to your fork
2. Open a Pull Request against the main branch
3. Fill in the PR template completely
4. Ensure all CI checks pass
5. Request review from maintainers

### PR Guidelines

- Keep PRs focused on a single feature or fix
- Write clear commit messages
- Reference any related issues
- Be responsive to review feedback
- Be patient - reviews may take time

## Reporting Issues

When reporting issues, please include:

1. A minimal reproducible example
2. Your R session info: `sessionInfo()`
3. Full error messages
4. What you expected vs what happened

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on constructive criticism
- Respect differing viewpoints

### Unacceptable Behaviour

- Harassment or discrimination
- Trolling or insulting comments
- Public or private harassment
- Publishing others' private information

## Getting Help

- Check existing issues and discussions
- Read the package documentation
- Ask questions in issues (tag as "question")
- Check the vignettes for examples

## Recognition

Contributors will be recognised in:
- The package AUTHORS file
- The package website
- Release notes for significant contributions

Thank you for contributing to boilerplate!