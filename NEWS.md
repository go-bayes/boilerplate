# boilerplate (development version)
## [2024-04-01] boilerplate 0.2.1
### Improved
- added cli alerts to main functions

## Deprecated
- `boilerplate_results_text()`, `boilerplate_measures_text()`, handled more simply with `boilerplate_generate_text()`

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
