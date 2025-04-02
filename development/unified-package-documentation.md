# Boilerplate Package: Unified Database Implementation

## Changes Overview

- implemented a unified database approach for the boilerplate package that simplifies workflows and makes the API more consistent. This redesign:

1. **Unifies text databases** (methods, results, discussion, appendix, template) while keeping measures as a distinct but compatible structure
2. **Provides standardized import/save functions** that work consistently across all database types
3. **Maintains backward compatibility** through wrapper functions
4. **Adds helper functions** for accessing specific parts of the unified database
5. **Updates the text generation functions** to work seamlessly with either unified or individual databases

## Key New Functions

| Function | Description |
|----------|-------------|
| `boilerplate_import()` | Import one or more databases into a unified structure |
| `boilerplate_save()` | Save a unified database or individual category |
| `boilerplate_init()` | Initialize all databases with a single function |
| `boilerplate_init_category()` | Initialize a specific category |
| `boilerplate_methods()` | Extract methods from a unified database |
| `boilerplate_measures()` | Extract measures from a unified database |
| `boilerplate_results()` | Extract results from a unified database |
| `boilerplate_discussion()` | Extract discussion from a unified database |
| `boilerplate_appendix()` | Extract appendix from a unified database |
| `boilerplate_template()` | Extract templates from a unified database |

## Migration Guide

### Old Workflow vs. New Workflow

#### Old Workflow:
```r
# Import separate databases
measures_db <- boilerplate_manage_measures(action = "list")
methods_db <- boilerplate_manage_text(action = "list", category = "methods")

# Generate text
methods_text <- boilerplate_generate_text(
  category = "methods",
  sections = c("sample", "statistical.longitudinal"),
  db = methods_db
)

# Add a measure
measures_db <- boilerplate_manage_measures(
  action = "add",
  name = "new_measure",
  measure = list(name = "New Measure", description = "Description")
)

# Save changes
boilerplate_manage_measures(
  action = "save",
  db = measures_db,
  file_name = "measures_db.rds"
)
```

#### New Workflow:
```r
# Import unified database
unified_db <- boilerplate_import()

# Generate text (same function, works with unified database)
methods_text <- boilerplate_generate_text(
  category = "methods",
  sections = c("sample", "statistical.longitudinal"),
  db = unified_db  # Just pass the unified database
)

# Add a measure
unified_db$measures$new_measure <- list(
  name = "New Measure",
  description = "Description"
)

# Save all changes at once
boilerplate_save(unified_db)
```

### Migration Steps

1. **Replace import calls**:
   - Replace `boilerplate_manage_measures(action = "list")` with `boilerplate_import("measures")`
   - Replace `boilerplate_manage_text(action = "list", category = "xyz")` with `boilerplate_import("xyz")`

2. **Replace save calls**:
   - Replace `boilerplate_manage_measures(action = "save", db = db, ...)` with `boilerplate_save(db, "measures")`
   - Replace `boilerplate_manage_text(action = "save", category = "xyz", db = db, ...)` with `boilerplate_save(db, "xyz")`

3. **Update database modification**:
   - Instead of using `action = "add"/"update"/"remove"`, use direct list manipulation:
     - `db$name <- value` (add/update)
     - `db$name <- NULL` (remove)

4. **Consider using the unified database**:
   - Use `unified_db <- boilerplate_import()` to get all databases at once
   - Access specific categories with `unified_db$category` or the helper functions

## Technical Implementation Notes

1. **File structure remains the same**:
   - Each category still has its own file on disk
   - `boilerplate_import()` combines them into a single structure
   - `boilerplate_save()` writes each category back to its own file

2. **Backward compatibility**:
   - Legacy functions are maintained but issue deprecation warnings
   - They internally call the new functions to maintain consistency

3. **Database contents**:
   - The structure and content of databases is unchanged
   - The new system is just a different way to access and manage them

4. **Text generation**:
   - `boilerplate_generate_text()` and `boilerplate_generate_measures()` work with either individual databases or the unified database

## Future Enhancements

1. **Database validation** might be added to ensure consistency
2. **Searching across categories** could be made easier with the unified approach
3. **Export/import between projects** could be implemented for sharing databases
4. **Version control integration** for database changes could be more straightforward

## Breaking Changes

There are no breaking changes in the implementation, as all existing functions are preserved with backward compatibility wrappers. However, using custom file names is now discouraged as the unified system uses standardized file names.
