## boilerplate

## [2024-04-03] boilerplate 1.0.3
### New
- `boilerplate_init()` supports initialising empty database structures by default.
- `boilerplate_export()` export wholes or parts of databases, for 
  - Full database export (ideal for versioning)
  - Selective export using dot notation (e.g., "methods.statistical.longitudinal")
  - Wildcard selections using "*" (e.g., "methods.*" selects all methods)
  - Category-prefixed paths for unified databases
- Export is distinct from save: use `boilerplate_save()` for normal database updates and `boilerplate_export()` for creating standalone exports.

## [2024-04-03] boilerplate 1.0.2
### Improved 
 - `get_default_measures_db()` creates measures data with the correct structure.
 -  improved README examples for clarity
 -  tidyed up R folder to remove old functions


## [2024-04-03] boilerplate 1.0.1
### Improved 
- `boilerplate_save()` confirms intention to overwrite, in case this occurs accidentally
- `boilerplate_init()` messages are clearer when initialising from existing databases 

## [2024-04-03] boilerplate 1.0.0

## Boilerplate Package: Unified Database Implementation

### Changes Overview

- implemented a unified database approach for the boilerplate package that simplifies workflows and makes the API more consistent. 
- the redesign:

1. **unifies text databases** (methods, results, discussion, appendix, template) while keeping measures as a distinct but compatible structure
2. **provides standardised import/save functions** that work consistently across all database types
3. **maintains backward compatibility** through wrapper functions
4. **adds helper functions** for accessing specific parts of the unified database
5. **updates the text generation functions** to work seamlessly with either unified or individual databases

### New Functions

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

### Migration Guide

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
# import unified database
unified_db <- boilerplate_import()

# generate text (same function, works with unified database)
methods_text <- boilerplate_generate_text(
  category = "methods",
  sections = c("sample", "statistical.longitudinal"),
  db = unified_db  # just pass the unified database
)

# add a measure
unified_db$measures$new_measure <- list(
  name = "New Measure",
  description = "Description"
)

# save all changes at once
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
   - use `unified_db <- boilerplate_import()` to get all databases at once
   - access specific categories with `unified_db$category` or the helper functions

## Technical Implementation Notes

1. **File structure remains the same**:
   - each category still has its own file on disk
   - `boilerplate_import()` combines them into a single structure
   - `boilerplate_save()` writes each category back to its own file

2. **Backward compatibility**:
   - legacy functions are maintained but issue deprecation warnings
   - they internally call the new functions to maintain consistency

3. **Database contents**:
   - the structure and content of databases is unchanged
   - the new system is just a different way to access and manage them

4. **Text generation**:
   - `boilerplate_generate_text()` and `boilerplate_generate_measures()` work with either individual databases or the unified database

## Future Enhancements

1. **Database validation** will be added to ensure consistency
2. **Searching across categories** could be made easier with the unified approach, to be considered
3. **Export/import between projects** could be implemented for sharing databases (needs thought)
4. **Version control integration** for database changes could be more straightforward -- presently we rely on overwrite warnings, this is far from user-proof. 

## Breaking Changes

There are no breaking changes in the implementation, as all existing functions are preserved with backward compatibility wrappers. However, using custom file names is now discouraged as the unified system uses standardised file names.

## [2024-04-01] boilerplate 0.3.0
## Improved
- `boilerplate_measures_text()` now `boilerplate_generate_text`
-  user-proof defaults for checking against writing over existing databases. 

## [2024-04-01] boilerplate 0.2.1
### Improved
- added cli alerts to main functions

## Deprecated
- `boilerplate_results_text()`, `boilerplate_measures_text()`, handled more simply with `boilerplate_generate_text()`
- templating now possible for templating full manuscripts. 
- different version (technical, non-technical) of templated manuscripts now possible. 

## [2024-03-29] boilerplate 0.2.0
## New
- Major refactoring of package for simplicity. 
- Change of liscence to MIT.

- `boilerplate_manage_text()` - uses template variable substitution to create customised text. 
- `boilerplate_generate_text()` - produces text for boilerplate_manage_text
- `boilerplate_results_text()` - produces results for boilerplate_manage_text
- `boilerplate_init_text()` - initialises text for boilerplate_manage_text

## Deprecated
- all previous functions: 
    - boilerplate_init_text(previous version) 
    - boilerplate_manage_measures (previous version)
    - boilerplate_manage_text (previous version)
    - boilerplate_merge_databases (previous version)
    - boilerplate_measures
    - boilerplate_report_additional_sections
    - boilerplate_report_causal_interventions
    - boilerplate_report_confounding_control
    - boilerplate_report_eligibility_criteria
    - boilerplate_report_identification_assumptions
    - boilerplate_report_measures
    - boilerplate_report_methods
    - boilerplate_report_missing_data
    - boilerplate_report_sample
    - boilerplate_report_statistical_estimator
    - boilerplate_report_target_population
    - boilerplate_report_variables


## [2024-12-22] boilerplate 0.0.1.6
### Improved
- `boilerplate_report_statistical_estimator()` enhanced for `grf` and allows short and long reporting. 

## [2024-12-22] boilerplate 0.0.1.5

### New
`boilerplate_measures()` - one function that does all we need for measures reporting

## [2024-09-25] boilerplate 0.0.1.4

- more flexible handling of additional sections in methods (still work to be done)

## [2024-08-24] boilerplate 0.0.1.3

### Improved

* fixed issue in `boilerplate_report_measures()` works if only `baseline_vars`, `exposure_var`, or `outcome_vars` are passed. 



## [2024-08-24] boilerplate 0.0.1.2

### Improved

* fixed issue in `boilerplate_manage_measures()`: now, if 'n' is selected for new database name, the manager will return to the main menu instead of charging along. 

## [24-08-2024] boilerplate 0.0.1.1-alpha

### New

* `boilerplate_merge_databases()`: merges databases, currently implemented for measures_data.
* fixed helper functions on the `boilerplate_report_methods()` function.

## [2024-08-24] boilerplate 0.0.1.0-alpha

* alpha release
* doi: 10.5281/zenodo.13370816


## [2024-08-24] boilerplate 0.0.0.92

*  boilerplate_report_additional_sections()
*  boilerplate_report_confounding_control()
*  boilerplate_report_eligibility_criteria()
*  boilerplate_report_identification_assumptions()
*  boilerplate_report_methods()
*  boilerplate_report_missing_data()
*  boilerplate_report_sample()
*  boilerplate_report_statistical_estimator()
*  boilerplate_report_target_population()

## [2024-08-24] boilerplate 0.0.0.91

* `boilerplate_manage_measures()`: simple gui to input measures, saves as .rds files 
* `boilerplate_report_measures()`:  report an appendix of measures with items described.
* `boilerplate_report_causal_interventions()`: report causal contrasts
* `boilerplate_report_variables()`:report variables in methods section (exposure/ outcomes)

## [2024-08-24] boilerplate 0.0.0.9

### New

* first package commit 
