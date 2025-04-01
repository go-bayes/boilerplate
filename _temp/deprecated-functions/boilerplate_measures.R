#' Generate Measures Section for Methods
#'
#' This function generates a markdown-formatted section describing the measures used in the study.
#' It includes baseline variables if provided, renames measures based on label mappings, and excludes
#' appendix-related sections and color formatting. References are formatted based on their content.
#'
#' @param baseline_vars A character vector specifying the names of baseline variables. Optional.
#' @param exposure_var A character string specifying the name of the exposure variable.
#' @param outcome_vars A named list of character vectors specifying the outcome variables by domain.
#' @param measure_data A list containing information about each measure.
#' @param label_mappings An optional named list where each element is a named vector for renaming variables.
#' @param print_waves A logical value indicating whether to print wave information. Default is FALSE.
#'
#' @return A character string containing the markdown-formatted section on measures.
#'
#' @examples
#' \dontrun{
#' # Define baseline variables
#' baseline_vars <- c("age", "gender", "education_level")
#'
#' # Define outcomes by domain
#' outcomes_health <- c("hlth_bmi", "hlth_sleep_hours")
#' outcomes_psychological <- c("kessler_latent_anxiety", "rumination")
#' all_outcomes <- list(
#'   health = outcomes_health,
#'   psychological = outcomes_psychological
#' )
#'
#' # Define the exposure variable
#' exposure_var <- "religion_church"
#'
#' # Define label mappings
#' label_mappings <- list(
#'   baseline = var_labels_baseline,
#'   exposure = label_mapping_raw_exposure,
#'   health = label_mapping_raw_health,
#'   psychological = label_mapping_raw_psych
#' )
#'
#' # Load your measure_data
#' measure_data <- readRDS(here::here("boilerplate", "data", "measure_data.rds"))
#'
#' # Call the function
#' measures_section <- boilerplate_measures(
#'   baseline_vars = baseline_vars,
#'   exposure_var = exposure_var,
#'   outcome_vars = all_outcomes,
#'   measure_data = measure_data,
#'   label_mappings = label_mappings
#' )
#'
#' # Print the generated markdown
#' cat(measures_section)
#' }
#'
#' @keywords internal
boilerplate_measures <- function(baseline_vars = NULL,
                                 exposure_var,
                                 outcome_vars,
                                 measure_data,
                                 label_mappings = NULL,
                                 print_waves = FALSE) {

  # Load required packages
  if (!requireNamespace("janitor", quietly = TRUE)) {
    stop("The 'janitor' package is required but not installed. Please install it.")
  }

  # helper function to apply label mappings
  apply_label_mapping <- function(var_name, label_mappings, category = NULL) {
    if (!is.null(label_mappings)) {
      if (!is.null(category) && category %in% names(label_mappings)) {
        mappings <- label_mappings[[category]]
        if (var_name %in% names(mappings)) {
          return(mappings[[var_name]])
        }
      }
      # Check in a general mappings list if available
      if ("general" %in% names(label_mappings)) {
        mappings <- label_mappings[["general"]]
        if (var_name %in% names(mappings)) {
          return(mappings[[var_name]])
        }
      }
    }
    # default to making clean names if no mapping is found
    return(janitor::make_clean_names(var_name, case = "title"))
  }

  # helper function to format references based on specifications
  format_reference <- function(reference) {
    if (is.null(reference) || reference == "") {
      return("")
    }

    # remove 'string_is' if present
    reference <- gsub("string_is", "", reference)
    reference <- trimws(reference)  # Remove leading/trailing whitespace

    # check if reference is a single word (no spaces)
    if (grepl("^\\S+$", reference)) {
      return(paste0(" [@", reference, "]"))
    } else {
      return(paste0(" ", reference))
    }
  }

  # helper function to format a single measure
  format_measure <- function(var_name, measure_info, label_mappings, category = NULL) {
    if (is.null(measure_info)) {
      return(paste0("#### ", apply_label_mapping(var_name, label_mappings, category), "\n\nNo information available for this variable.\n\n"))
    }

    title <- apply_label_mapping(var_name, label_mappings, category)
    description <- measure_info$description
    reference <- measure_info$reference
    items <- measure_info$item

    # format the reference
    formatted_reference <- format_reference(reference)

    formatted_text <- paste0("#### ", title, "\n\n")

    # handle multiple items
    if (length(items) > 1) {
      items_text <- paste(sapply(items, function(item) paste0("* ", item)), collapse = "\n")
      formatted_text <- paste0(formatted_text, items_text, "\n\n")
    } else {
      formatted_text <- paste0(formatted_text, "*", items, "*\n\n")
    }

    # append description and reference
    formatted_text <- paste0(formatted_text, description, formatted_reference, "\n\n")

    return(formatted_text)
  }

  # initialise the full text
  full_text <- ""

  # add Baseline Variables if provided
  if (!is.null(baseline_vars) && length(baseline_vars) > 0) {
    full_text <- paste0(full_text, "## Baseline Variables\n\n")
    for (var in baseline_vars) {
      var_info <- measure_data[[var]]
      full_text <- paste0(full_text, format_measure(var, var_info, label_mappings, category = "baseline"))
    }
  }

  # add Exposure Variable
  full_text <- paste0(full_text, "## Exposure Variable\n\n",
                      format_measure(exposure_var, measure_data[[exposure_var]], label_mappings, category = "exposure"))

  # add Outcome Variables
  if (!is.null(outcome_vars) && length(outcome_vars) > 0) {
    full_text <- paste0(full_text, "## Outcome Variables\n\n")
    for (domain in names(outcome_vars)) {
      domain_title <- tools::toTitleCase(gsub("_", " ", domain))
      full_text <- paste0(full_text, "### ", domain_title, "\n\n")
      for (var in outcome_vars[[domain]]) {
        var_info <- measure_data[[var]]
        full_text <- paste0(full_text, format_measure(var, var_info, label_mappings, category = domain))
      }
    }
  }

  return(full_text)
}
