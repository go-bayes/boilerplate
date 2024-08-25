#' Generate Variables Section for Methods
#'
#' This function is a wrapper around boilerplate_measures() that generates
#' a markdown-formatted section describing the variables used in the study.
#' It ignores baseline variables and includes an optional reference to an appendix.
#'
#' @param exposure_var A character string specifying the name of the exposure variable.
#' @param outcome_vars A named list of character vectors specifying the outcome variables by domain.
#' @param measure_data A list containing information about each measure.
#' @param custom_titles An optional named list of custom titles for measures.
#' @param print_waves A logical value indicating whether to print wave information. Default is FALSE.
#' @param appendices_measures An optional character string for the appendix reference. If NULL, no reference is included.
#'
#' @return A character string containing the markdown-formatted section on variables.
#'
#' @examples
#' \dontrun{
#' # Define outcomes by domain
#' outcomes_health <- c("smoker_binary", "hlth_bmi", "log_hours_exercise")
#' outcomes_psychological <- c("hlth_fatigue", "kessler_latent_anxiety")
#' outcomes_social <- c("belong", "neighbourhood_community")
#' all_outcomes <- list(
#'   health = outcomes_health,
#'   psychological = outcomes_psychological,
#'   social = outcomes_social
#' )
#' # Define the exposure variable
#' exposure_var <- "political_conservative"
#' # Load your measure_data
#' measure_data <- readRDS(here::here("boilerplate", "data", "measure_data.rds"))
#' # Call the function
#' result <- boilerplate_report_variables(
#'   exposure_var = exposure_var,
#'   outcome_vars = all_outcomes,
#'   measure_data = measure_data,
#'   appendices_measures = "Appendix C"
#' )
#' # Print the result
#' cat(result)
#' }
#'
#' @export
boilerplate_report_variables <- function(exposure_var, outcome_vars, measure_data, appendices_measures = NULL, ...) {
  # Generate the bibliography
  bibliography_text <- boilerplate_report_measures(
    all_vars = c(exposure_var, unlist(outcome_vars)),
    exposure_var = exposure_var,
    outcome_vars = unlist(outcome_vars),
    measure_data = measure_data,
    print_keywords = FALSE,
    print_waves = FALSE
  )

  # Create sections for each domain
  domain_sections <- lapply(names(outcome_vars), function(domain) {
    domain_vars <- outcome_vars[[domain]]
    domain_title <- tools::toTitleCase(gsub("_", " ", domain))
    domain_text <- paste0("### ", domain_title, "\n\n")
    for (var in domain_vars) {
      var_info <- measure_data[[var]]
      if (!is.null(var_info)) {
        var_title <- janitor::make_clean_names(var, case = "title")
        var_description <- var_info$description
        var_reference <- var_info$reference
        var_items <- var_info$item

        domain_text <- paste0(domain_text, "#### ", var_title, "\n\n")

        # Handle multiple items
        if (length(var_items) > 1) {
          items_text <- paste(sapply(var_items, function(item) paste0("*", item, "*")), collapse = "\n")
          domain_text <- paste0(domain_text, items_text, "\n\n")
        } else {
          domain_text <- paste0(domain_text, "*", var_items, "*\n\n")
        }

        domain_text <- paste0(domain_text, var_description, " [@", var_reference, "]\n\n")
      }
    }
    return(domain_text)
  })

  # Combine all sections
  full_text <- paste0("## Variables\n\n",
                      "### Exposure Variable\n\n",
                      format_measure(exposure_var, measure_data[[exposure_var]]),
                      "### Outcome Variables\n\n",
                      paste(domain_sections, collapse = "\n"))

  # Add appendix reference if provided
  if (!is.null(appendices_measures)) {
    appendix_text <- paste0("\n\nDetailed descriptions of how these variables were measured and operationalized can be found in **", appendices_measures, "**.")
    full_text <- paste0(full_text, appendix_text)
  }

  return(full_text)
}
# Helper function to format a single measure
format_measure <- function(var_name, measure_info) {
  if (is.null(measure_info)) {
    return(paste0("#### ", janitor::make_clean_names(var_name, case = "title"), "\n\nNo information available for this variable.\n\n"))
  }

  title <- janitor::make_clean_names(var_name, case = "title")
  description <- measure_info$description
  reference <- measure_info$reference
  items <- measure_info$item

  formatted_text <- paste0("#### ", title, "\n\n")

  # Handle multiple items
  if (length(items) > 1) {
    items_text <- paste(sapply(items, function(item) paste0("*", item, "*")), collapse = "\n")
    formatted_text <- paste0(formatted_text, items_text, "\n\n")
  } else {
    formatted_text <- paste0(formatted_text, "*", items, "*\n\n")
  }

  formatted_text <- paste0(formatted_text, description, " [@", reference, "]\n\n")

  return(formatted_text)
}
