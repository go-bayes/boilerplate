# helpers
#' Generate Methods Text from Boilerplate
#'
#' This function generates methods text by retrieving and combining text from
#' the methods database. It's a wrapper around boilerplate_generate_text with
#' methods-specific defaults. Supports arbitrarily nested section paths
#' using dot notation for flexible organization.
#'
#' @param sections Character vector. The methods sections to include (can use dot notation for nesting).
#' @param global_vars List. Variables available to all sections.
#' @param section_vars List. Section-specific variables.
#' @param text_overrides List. Direct text overrides for specific sections.
#' @param db List. Optional methods database to use.
#' @param text_path Character. Path to the directory where text database files are stored.
#' @param warn_missing Logical. Whether to warn about missing template variables.
#' @param add_headings Logical. Whether to add markdown headings to sections. Default is FALSE.
#' @param heading_level Character. The heading level to use (e.g., "###"). Default is "###".
#' @param custom_headings List. Custom headings for specific sections. Names should match section names.
#'
#' @return Character. The combined methods text.
#'
#' @examples
#' \dontrun{
#' # Basic usage with default sections
#' methods_text <- boilerplate_methods_text(
#'   global_vars = list(
#'     exposure_var = "political_conservative",
#'     population = "university students"
#'   )
#' )
#'
#' # Using deeply nested organization with headings
#' methods_text <- boilerplate_methods_text(
#'   sections = c(
#'     "sample",
#'     "causal_assumptions.identification",
#'     "statistical.longitudinal.lmtp",
#'     "statistical.heterogeneity.grf.custom"
#'   ),
#'   global_vars = list(exposure_var = "treatment"),
#'   add_headings = TRUE
#' )
#' }
#'
#' @keywords internal
boilerplate_methods_text <- function(
    sections = c(
      "sample",
      "causal_assumptions.identification",
      "causal_assumptions.confounding_control",
      "statistical.longitudinal.lmtp"
    ),
    global_vars = list(),
    section_vars = list(),
    text_overrides = list(),
    db = NULL,
    text_path = NULL,
    warn_missing = TRUE,
    add_headings = FALSE,
    heading_level = "###",
    custom_headings = list()
) {
  boilerplate_generate_text(
    category = "methods",
    sections = sections,
    global_vars = global_vars,
    section_vars = section_vars,
    text_overrides = text_overrides,
    db = db,
    text_path = text_path,
    warn_missing = warn_missing,
    add_headings = add_headings,
    heading_level = heading_level,
    custom_headings = custom_headings
  )
}

#' Generate Results Text from Boilerplate
#'
#' This function generates results text by retrieving and combining text from
#' the results database with appropriate variable substitution. It's a wrapper
#' around boilerplate_generate_text with results-specific defaults.
#' Supports arbitrarily nested section paths using dot notation.
#'
#' @param sections Character vector. The results sections to include (can use dot notation for nesting).
#' @param results_data List. Data from analysis results to use in template variables.
#' @param section_vars List. Section-specific variables if needed beyond results_data.
#' @param text_overrides List. Direct text overrides for specific sections.
#' @param db List. Optional results database to use.
#' @param text_path Character. Path to the directory where text database files are stored.
#' @param warn_missing Logical. Whether to warn about missing template variables.
#' @param add_headings Logical. Whether to add markdown headings to sections. Default is FALSE.
#' @param heading_level Character. The heading level to use (e.g., "###"). Default is "###".
#' @param custom_headings List. Custom headings for specific sections. Names should match section names.
#'
#' @return Character. The combined results text.
#'
#' @examples
#' \dontrun{
#' # Basic usage with analysis results
#' results_text <- boilerplate_results_text(
#'   sections = c("main_effect"),
#'   results_data = list(
#'     effect_size = "0.35",
#'     confidence_interval = "95% CI: 0.21, 0.49",
#'     interpretation = "a moderate positive effect"
#'   )
#' )
#'
#' # Using domain-specific results with nested paths and headings
#' results_text <- boilerplate_results_text(
#'   sections = c("main_effect", "domain.health", "domain.psychological"),
#'   results_data = list(
#'     effect_size = "0.35",
#'     confidence_interval = "95% CI: 0.21, 0.49",
#'     interpretation = "a moderate positive effect",
#'     health_finding = "improved physical outcomes",
#'     psych_finding = "reduced stress levels"
#'   ),
#'   add_headings = TRUE
#' )
#' }
#'
#' @keywords internal
boilerplate_results_text <- function(
    sections = c("main_effect"),
    results_data = list(),
    section_vars = list(),
    text_overrides = list(),
    db = NULL,
    text_path = NULL,
    warn_missing = TRUE,
    add_headings = FALSE,
    heading_level = "###",
    custom_headings = list()
) {
  boilerplate_generate_text(
    category = "results",
    sections = sections,
    global_vars = results_data,
    section_vars = section_vars,
    text_overrides = text_overrides,
    db = db,
    text_path = text_path,
    warn_missing = warn_missing,
    add_headings = add_headings,
    heading_level = heading_level,
    custom_headings = custom_headings
  )
}
