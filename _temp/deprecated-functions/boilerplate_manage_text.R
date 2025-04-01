#' Manage Boilerplate Text
#'
#' This function provides a unified interface for managing boilerplate text
#' across different categories (measures, methods, etc.). It allows listing,
#' adding, updating, removing, and retrieving text entries with template
#' variable substitution. Supports arbitrarily nested hierarchical organization
#' through dot-separated paths.
#'
#' @param category Character. Category of text to manage, e.g., "measures", "methods".
#'   Default options are "measures", "methods", "results", and "discussion".
#' @param action Character. Action to perform: "list", "add", "update", "remove", "get", or "save".
#' @param name Character. Identifier for the text entry (required for add/update/remove/get).
#'   For nested entries, use dot-separated paths (e.g., "methods.statistical.lmtp").
#' @param value Text content for the entry (required for add/update).
#' @param db Optional existing database. If not supplied, the default db is loaded.
#' @param text_path Character. Path to the directory where text database files are stored.
#'   If NULL (default), the function will look in the following locations in order:
#'   1. "boilerplate/data/" subdirectory of the current working directory (via here::here())
#'   2. Package installation directory's "boilerplate/data/" folder
#'   3. "boilerplate/data/" relative to the current working directory
#' @param file_name Character. Name of the file to save or load (without path).
#'   If NULL (default), uses "[category]_db.rds".
#' @param template_vars List. Optional variables for template substitution.
#' @param warn_missing Logical. Whether to warn about missing template variables. Default is TRUE.
#'
#' @return Depending on action:
#'   - "list": Returns the database or part of it
#'   - "add"/"update"/"remove": Returns the modified database
#'   - "get": Returns a specific text entry, with template variables substituted
#'   - "save": Returns TRUE if successful, FALSE otherwise
#'
#' @examples
#' # List default methods
#' methods_db <- boilerplate_manage_text(category = "methods", action = "list")
#'
#' # Add a new method entry
#' methods_db <- boilerplate_manage_text(
#'   category = "methods",
#'   action = "add",
#'   name = "causal_assumptions",
#'   value = "We made the following assumptions: {{assumptions}}"
#' )
#'
#' # Add a nested entry
#' methods_db <- boilerplate_manage_text(
#'   category = "methods",
#'   action = "add",
#'   name = "statistical.longitudinal.lmtp",
#'   value = "We used the LMTP estimator with {{software}}."
#' )
#'
#' # Get a specific entry with template substitution
#' text <- boilerplate_manage_text(
#'   category = "methods",
#'   action = "get",
#'   name = "causal_assumptions",
#'   db = methods_db,
#'   template_vars = list(assumptions = "no unmeasured confounding")
#' )
#'
#' # Get a nested entry with template substitution
#' text <- boilerplate_manage_text(
#'   category = "methods",
#'   action = "get",
#'   name = "statistical.longitudinal.lmtp",
#'   db = methods_db,
#'   template_vars = list(software = "lmtp R package")
#' )
#'
#' # Update an existing entry
#' methods_db <- boilerplate_manage_text(
#'   category = "methods",
#'   action = "update",
#'   name = "causal_assumptions",
#'   value = "Updated assumptions: {{assumptions}}",
#'   db = methods_db
#' )
#'
#' # Save the database to a specific location
#' boilerplate_manage_text(
#'   category = "methods",
#'   action = "save",
#'   db = methods_db,
#'   text_path = "path/to/data",
#'   file_name = "my_methods.rds"
#' )
#'
#' # Working with a specific database location
#' methods_db <- boilerplate_manage_text(
#'   category = "methods",
#'   action = "list",
#'   text_path = "path/to/project/data"
#' )
#'
#' @importFrom utils modifyList
#' @export
boilerplate_manage_text <- function(
    category = c("measures", "methods", "results", "discussion"),
    action = c("list", "add", "update", "remove", "get", "save"),
    name = NULL,
    value = NULL,
    db = NULL,
    text_path = NULL,
    file_name = NULL,
    template_vars = list(),
    warn_missing = TRUE
) {
  # Validate inputs
  category <- match.arg(category)
  action <- match.arg(action)

  # validate name for actions that require it
  if (action %in% c("add", "update", "remove", "get") && is.null(name)) {
    stop(paste("The", action, "action requires a name parameter."))
  }

  # validate value for actions that require it
  if (action %in% c("add", "update") && is.null(value)) {
    stop(paste("The", action, "action requires a value parameter."))
  }

  # load default database if not provided
  if (is.null(db)) {
    db <- load_text_db(category, text_path, file_name)
  }

  # input validation: ensure db is a list
  if (!is.list(db)) {
    stop("Database must be a list.")
  }

  # handle path-based navigation or simple name
  if (!is.null(name) && grepl("\\.", name)) {
    # We have a nested path
    path_parts <- strsplit(name, "\\.")[[1]]

    if (action == "list") {
      # For list action, navigate to the requested folder
      return(get_nested_folder(db, path_parts))
    } else if (action == "get") {
      # For get action, retrieve and process the text
      return(get_nested_text(db, path_parts, template_vars, warn_missing))
    } else if (action %in% c("add", "update", "remove")) {
      # For modification actions, update the nested structure
      return(modify_nested_entry(db, path_parts, action, value))
    }
  } else {
    # handle regular key-based operations
    if (action == "list") {
      if (!is.null(name)) {
        # List a specific top-level entry
        if (!(name %in% names(db))) {
          stop(paste("Text entry", name, "not found."))
        }
        return(db[[name]])
      }
      return(db)
    } else if (action == "add") {
      if (name %in% names(db)) {
        stop("text entry already exists")
      }
      db[[name]] <- value
    } else if (action == "update") {
      if (!(name %in% names(db))) {
        stop("text entry does not exist")
      }
      db[[name]] <- value
    } else if (action == "remove") {
      if (!(name %in% names(db))) {
        stop("text entry does not exist")
      }
      db[[name]] <- NULL
    } else if (action == "get") {
      if (!(name %in% names(db))) {
        stop("text entry does not exist")
      }
      text <- db[[name]]
      # Apply template substitution
      return(apply_template_vars(text, template_vars, warn_missing))
    } else if (action == "save") {
      return(save_text_db(db, category, text_path, file_name))
    }
  }

  return(db)
}
#' Retrieve a Nested Folder from the Database
#'
#' Navigates through a nested list structure to retrieve a specific folder.
#'
#' @param db List. The database to navigate.
#' @param path_parts Character vector. Path components.
#'
#' @return The nested list at the specified path.
#'
#' @noRd
get_nested_folder <- function(db, path_parts) {
  if (length(path_parts) == 0) {
    return(db)
  }

  current_part <- path_parts[1]
  remaining_parts <- path_parts[-1]

  if (!(current_part %in% names(db))) {
    stop(paste("Path component", current_part, "not found"))
  }

  current_item <- db[[current_part]]

  if (!is.list(current_item)) {
    stop(paste("Path component", current_part, "is not a folder"))
  }

  if (length(remaining_parts) == 0) {
    return(current_item)
  } else {
    return(get_nested_folder(current_item, remaining_parts))
  }
}

#' Retrieve Text from a Nested Structure
#'
#' This helper function recursively navigates a nested list structure
#' to retrieve text at any depth of nesting.
#'
#' @param db The database or sublist to search within
#' @param path_parts Character vector of path components
#' @param template_vars Variables for template substitution
#' @param warn_missing Whether to warn about missing template variables
#'
#' @return Retrieved text with template variables substituted
#'
#' @noRd
get_nested_text <- function(db, path_parts, template_vars = list(), warn_missing = TRUE) {
  if (length(path_parts) == 0) {
    stop("Empty path")
  }

  current_part <- path_parts[1]
  remaining_parts <- path_parts[-1]

  if (!(current_part %in% names(db))) {
    stop(paste("Path component", current_part, "not found"))
  }

  current_item <- db[[current_part]]

  if (length(remaining_parts) == 0) {
    # We've reached the leaf node
    if (is.list(current_item)) {
      # If this is a folder, look for a default entry
      if ("default" %in% names(current_item)) {
        current_item <- current_item[["default"]]
      } else {
        stop(paste("Path component", current_part, "is a folder without a default entry"))
      }
    }

    # Apply template substitution and return
    return(apply_template_vars(current_item, template_vars, warn_missing))
  } else {
    # Keep navigating deeper
    if (!is.list(current_item)) {
      stop(paste("Path component", current_part, "is not a folder"))
    }

    return(get_nested_text(current_item, remaining_parts, template_vars, warn_missing))
  }
}

#' Modify a Nested Entry in the Database
#'
#' Recursively navigates a nested list structure to add, update, or remove an entry.
#'
#' @param db List. The database to modify.
#' @param path_parts Character vector. Path components.
#' @param action Character. The action to perform ("add", "update", or "remove").
#' @param value Any. The value to set (for add or update).
#'
#' @return The modified database.
#'
#' @noRd
modify_nested_entry <- function(db, path_parts, action, value = NULL) {
  if (length(path_parts) == 0) {
    stop("Empty path")
  }

  current_part <- path_parts[1]
  remaining_parts <- path_parts[-1]

  # When adding, create missing folders as needed
  if (action == "add" && !(current_part %in% names(db))) {
    if (length(remaining_parts) > 0) {
      # Create folder for intermediate path
      db[[current_part]] <- list()
    } else {
      # Add leaf value
      db[[current_part]] <- value
      return(db)
    }
  } else if (action != "add" && !(current_part %in% names(db))) {
    stop(paste("Path component", current_part, "not found"))
  }

  if (length(remaining_parts) == 0) {
    # We've reached the leaf node
    if (action == "add") {
      if (current_part %in% names(db)) {
        stop(paste("Path component", current_part, "already exists"))
      }
      db[[current_part]] <- value
    } else if (action == "update") {
      db[[current_part]] <- value
    } else if (action == "remove") {
      db[[current_part]] <- NULL
    }
  } else {
    # Continue navigation
    current_item <- db[[current_part]]

    if (!is.list(current_item)) {
      stop(paste("Path component", current_part, "is not a folder"))
    }

    # Recursively modify the nested structure
    db[[current_part]] <- modify_nested_entry(current_item, remaining_parts, action, value)
  }

  return(db)
}

#' Apply Template Variables to Text
#'
#' Substitutes template variables in text using the {{variable_name}} syntax.
#' Uses glue package for robust variable replacement, with a fallback method.
#' Can optionally warn about missing variables.
#'
#' @param text Character. The template text with placeholders.
#' @param template_vars List. Variables to substitute in the template.
#' @param warn_missing Logical. Whether to warn about missing template variables.
#'
#' @return Character. The text with variables substituted.
#'
#' @importFrom glue glue
#' @noRd
apply_template_vars <- function(text, template_vars = list(), warn_missing = TRUE) {
  # Return early for non-character text or empty variables
  if (length(template_vars) == 0 || !is.character(text)) {
    return(text)
  }

  # For vector values, convert to comma-separated strings
  template_vars_processed <- template_vars
  for (var_name in names(template_vars)) {
    var_value <- template_vars[[var_name]]
    if (length(var_value) > 1) {
      template_vars_processed[[var_name]] <- paste(as.character(var_value), collapse = ", ")
    }
  }

  # Prepare the environment for glue
  env <- list2env(template_vars_processed, parent = emptyenv())

  # Try to use glue for substitution
  tryCatch({
    # Convert {{var}} syntax to glue's {var} syntax
    glue_ready_text <- gsub("\\{\\{([^\\}]+)\\}\\}", "{\\1}", text)
    result <- glue::glue(glue_ready_text, .envir = env)
    return(as.character(result))
  }, error = function(e) {
    # Fallback to manual substitution if glue fails
    for (var_name in names(template_vars_processed)) {
      var_value <- template_vars_processed[[var_name]]
      if (is.character(var_value) || is.numeric(var_value)) {
        text <- gsub(
          paste0("\\{\\{", var_name, "\\}\\}"),
          as.character(var_value),
          text,
          fixed = FALSE
        )
      }
    }

    # Issue a warning for unresolved variables if requested
    if (warn_missing) {
      # Look for any remaining {{variable}} patterns
      var_pattern <- "\\{\\{([^\\}]+)\\}\\}"
      if (requireNamespace("stringr", quietly = TRUE)) {
        # Use stringr if available
        remaining_vars <- stringr::str_extract_all(text, var_pattern)
        if (length(remaining_vars[[1]]) > 0) {
          remaining_vars <- unique(gsub("\\{\\{|\\}\\}", "", remaining_vars[[1]]))
          warning(paste("Unresolved template variables:", paste(remaining_vars, collapse = ", ")))
        }
      } else {
        # Fallback to base R
        if (grepl(var_pattern, text)) {
          matches <- gregexpr(var_pattern, text)
          if (matches[[1]][1] != -1) {
            warning("Unresolved template variables present. Consider installing the 'stringr' package for detailed information.")
          }
        }
      }
    }

    return(text)
  })
}

#' Save Database to File
#'
#' @param db List. The database to save.
#' @param file_path Character. Path to save the database.
#'
#' @return Logical. TRUE if successful, FALSE otherwise.
#'
#' @noRd
save_db <- function(db, file_path) {
  # Ensure directory exists
  dir_path <- dirname(file_path)
  if (!dir.exists(dir_path)) {
    dir.create(dir_path, recursive = TRUE)
  }

  # Save database
  tryCatch({
    saveRDS(db, file = file_path)
    message(paste("Database saved to", file_path))
    return(TRUE)
  }, error = function(e) {
    warning(paste("Error saving database:", e$message))
    return(FALSE)
  })
}

#' Get Default Database for a Category
#'
#' @param category Character. Category to get defaults for.
#'
#' @return List. The default database for the category.
#'
#' @noRd
get_default_db <- function(category) {
  # check for existing saved database
  file_path <- get_default_file_path(category)
  if (file.exists(file_path)) {
    tryCatch({
      return(readRDS(file_path))
    }, error = function(e) {
      warning(paste("Error loading saved database:", e$message))
      # Fall back to defaults if loading fails
    })
  }

  # return built-in defaults
  if (category == "measures") {
    return(get_default_measures_db())
  } else if (category == "methods") {
    return(get_default_methods_db())
  } else if (category == "results") {
    return(get_default_results_db())
  } else if (category == "discussion") {
    return(get_default_discussion_db())
  }

  # Default to empty database for unknown categories
  warning(paste("Unknown category:", category))
  return(list())
}

#' get Default File Path for a Category
#'
#' @param category Character. Category to get file path for.
#'
#' @return Character. The default file path for the category.
#'
#' @noRd
get_default_file_path <- function(category) {
  # Use appropriate package function for path resolution if available
  if (requireNamespace("here", quietly = TRUE)) {
    return(here::here("boilerplate", "data", paste0(category, "_db.rds")))
  } else {
    # Fallback
    data_dir <- system.file("boilerplate", "data", package = "boilerplate", mustWork = FALSE)
    if (dir.exists(data_dir)) {
      return(file.path(data_dir, paste0(category, "_db.rds")))
    } else {
      return(file.path("boilerplate", "data", paste0(category, "_db.rds")))
    }
  }
}

#' Get Default Measures Database
#'
#' @return List. The default measures database.
#'
#' @noRd
get_default_measures_db <- function() {
  list(
    # Top-level entries
    scale = "Default scale measure description",
    reliability = "Default reliability metric description",

    # Subcategories
    psychological = list(
      anxiety = "Anxiety was measured using the {{scale_name}} scale [@{{reference}}]",
      depression = "Depression was measured using the {{scale_name}} scale [@{{reference}}]",

      # Nested example
      clinical = list(
        ptsd = "PTSD was assessed using the {{ptsd_scale}} [@{{ptsd_ref}}]",
        default = "Standard clinical assessment protocols were followed."
      )
    ),
    demographic = list(
      age = "Age was measured in years",
      gender = "Gender was recorded as self-identified by participants"
    )
  )
}

#' Get Default Methods Database
#'
#' @return List. The default methods database.
#'
#' @noRd
get_default_methods_db <- function() {
  list(
    # Top-level entries
    sample = "Participants were recruited from {{population}} during {{timeframe}}.",

    # Causal assumptions subcategory
    causal_assumptions = list(
      identification = "This study relies on the following key identification assumptions for estimating the causal effect of {{exposure_var}}:

1. **Consistency**: the observed outcome under the observed {{exposure_var}} is equal to the potential outcome under that exposure level.

2. **Positivity**: there is a non-zero probability of receiving each level of {{exposure_var}} for every combination of values of {{exposure_var}} and confounders in the population.

3. **No unmeasured confounding**: all variables that affect both {{exposure_var}} and the outcome have been measured and accounted for in the analysis.",

      confounding_control = "To manage confounding in our analysis, we implement [@vanderweele2019]'s *modified disjunctive cause criterion* by following these steps:

1. **Identified all common causes** of both the treatment and outcomes.
2. **Excluded instrumental variables** that affect the exposure but not the outcome.
3. **Included proxies for unmeasured confounders** affecting both exposure and outcome.
4. **Controlled for baseline exposure** and **baseline outcome**."
    ),

    # Statistical methods subcategory with deep nesting
    statistical = list(
      default = "We used appropriate statistical methods for causal inference.",

      longitudinal = list(
        default = "Longitudinal data was analyzed using proper time-varying confounding adjustment.",
        lmtp = "We estimate causal effects using the Longitudinal Modified Treatment Policy (LMTP) estimator within a Targeted Minimum Loss-based Estimation (TMLE) framework [@van2014targeted; @van2012targeted].",
        sdr = "We employed a semi-parametric estimator known as Sequentially Doubly Robust (SDR) estimation [@díaz2021]."
      ),

      heterogeneity = list(
        default = "Treatment effect heterogeneity was assessed using appropriate methods.",
        grf = list(
          default = "We estimate heterogeneous treatment effects with Generalized Random Forests (GRF) [@grf2024].",
          standard = "We used the standard GRF implementation for heterogeneity detection.",
          custom = "We implemented a custom GRF approach with modified splitting criteria."
        ),
        causal_forest = "Causal forests were used to estimate conditional average treatment effects."
      )
    )
  )
}

#' Get Default Results Database
#'
#' @return List. The default results database.
#'
#' @noRd
get_default_results_db <- function() {
  list(
    main_effect = "The estimated causal effect was {{effect_size}} ({{confidence_interval}}), indicating {{interpretation}}.",
    null_results = "We did not find evidence of an effect ({{effect_size}}, {{confidence_interval}}).",

    # Nested results by domain
    domain = list(
      default = "Results varied by outcome domain.",
      health = "In the health domain, we found {{health_finding}}.",
      psychological = "In the psychological domain, we found {{psych_finding}}.",
      social = "In the social domain, we found {{social_finding}}."
    )
  )
}

#' Get Default Discussion Database
#'
#' @return List. The default discussion database.
#'
#' @noRd
get_default_discussion_db <- function() {
  list(
    limitations = "Our study has several limitations. First, {{limitation1}}. Second, {{limitation2}}.",
    future_directions = "Future research should explore {{future_direction}}.",

    implications = list(
      default = "This study has several implications.",
      clinical = "The clinical implications of our findings include {{clinical_implication}}.",
      policy = "Our findings suggest the following policy considerations: {{policy_implication}}.",
      theoretical = "From a theoretical perspective, these results suggest {{theoretical_implication}}."
    )
  )
}

#' Initialize Boilerplate Text Databases
#'
#' This function initializes or updates the boilerplate text databases with default values.
#' It's useful for setting up the system initially or adding new default entries.
#'
#' @param categories Character vector. Categories to initialize.
#' @param merge_strategy Character. How to merge with existing databases: "keep_existing", "merge_recursive", or "overwrite_all".
#' @param overwrite Logical. Whether to overwrite existing entries (deprecated, use merge_strategy instead).
#'
#' @return No return value, called for side effects.
#'
#' @examples
#' \dontrun{
#' # Initialize all categories with default merge strategy
#' boilerplate_init_text()
#'
#' # Initialize only methods
#' boilerplate_init_text("methods")
#'
#' # Use recursive merging
#' boilerplate_init_text(merge_strategy = "merge_recursive")
#'
#' # Completely overwrite existing databases
#' boilerplate_init_text(merge_strategy = "overwrite_all")
#' }
#'
#' @export
boilerplate_init_text <- function(
    categories = c("measures", "methods", "results", "discussion"),
    merge_strategy = c("keep_existing", "merge_recursive", "overwrite_all"),
    overwrite = FALSE
) {
  # Handle input validation
  merge_strategy <- match.arg(merge_strategy)

  # Handle deprecated overwrite parameter
  if (overwrite && merge_strategy == "keep_existing") {
    merge_strategy <- "overwrite_all"
    warning("The 'overwrite' parameter is deprecated. Please use merge_strategy='overwrite_all' instead.")
  }

  # Process each category
  for (category in categories) {
    # Get default database for category
    default_db <- get_default_db(category)

    # Get file path
    file_path <- get_default_file_path(category)

    # Check if file exists
    if (file.exists(file_path) && merge_strategy != "overwrite_all") {
      # Load existing database
      existing_db <- tryCatch({
        readRDS(file_path)
      }, error = function(e) {
        warning(paste("Error loading existing database:", e$message))
        return(list())
      })

      # Apply selected merge strategy
      if (merge_strategy == "keep_existing") {
        # Only add new keys, never modify existing ones
        merged_db <- utils::modifyList(default_db, existing_db, keep.null = TRUE)
        message(paste("Merged", category, "database (keeping existing entries)"))
      } else if (merge_strategy == "merge_recursive") {
        # Deep recursive merge, combining nested structures
        merged_db <- merge_recursive_lists(default_db, existing_db)
        message(paste("Recursively merged", category, "database"))
      }

      # Save merged database
      saveRDS(merged_db, file = file_path)
    } else {
      # Create directory if needed
      dir_path <- dirname(file_path)
      if (!dir.exists(dir_path)) {
        dir.create(dir_path, recursive = TRUE)
      }

      # Save default database
      saveRDS(default_db, file = file_path)
      if (file.exists(file_path)) {
        action <- if (merge_strategy == "overwrite_all") "Overwrote" else "Created new"
        message(paste(action, category, "database at", file_path))
      } else {
        warning(paste("Failed to create", category, "database at", file_path))
      }
    }
  }

  message("Initialization complete.")
}

#' Recursively Merge Two Lists
#'
#' This helper function performs a deep recursive merge of two lists,
#' combining nested structures while keeping values from the second list
#' when there are conflicts.
#'
#' @param x First list (defaults)
#' @param y Second list (existing values, takes precedence)
#'
#' @return Merged list
#'
#' @noRd
merge_recursive_lists <- function(x, y) {
  if (!is.list(x) || !is.list(y)) return(y)

  # For each name in x
  for (name in names(x)) {
    if (name %in% names(y)) {
      if (is.list(x[[name]]) && is.list(y[[name]])) {
        # Recursively merge lists
        y[[name]] <- merge_recursive_lists(x[[name]], y[[name]])
      }
      # Otherwise y's value takes precedence
    } else {
      # If not in y, add from x
      y[[name]] <- x[[name]]
    }
  }

  return(y)
}

#' Generate Text from Boilerplate
#'
#' This function generates text by retrieving and combining text from
#' a boilerplate database. It allows for template variable substitution and
#' customization through overrides. Supports arbitrarily nested section paths
#' using dot notation.
#'
#' @param category Character. Category of text to generate.
#' @param sections Character vector. The sections to include (can use dot notation for nesting).
#' @param global_vars List. Variables available to all sections.
#' @param section_vars List. Section-specific variables.
#' @param text_overrides List. Direct text overrides for specific sections.
#' @param db List. Optional database to use.
#' @param warn_missing Logical. Whether to warn about missing template variables.
#'
#' @return Character. The combined text.
#'
#' @examples
#' \dontrun{
#' # Basic usage with methods sections
#' methods_text <- boilerplate_generate_text(
#'   category = "methods",
#'   sections = c("sample", "causal_assumptions.identification"),
#'   global_vars = list(
#'     exposure_var = "political_conservative",
#'     population = "university students"
#'   )
#' )
#'
#' # Using deeply nested paths
#' methods_text <- boilerplate_generate_text(
#'   category = "methods",
#'   sections = c(
#'     "sample",
#'     "statistical.longitudinal.lmtp",
#'     "statistical.heterogeneity.grf.custom"
#'   ),
#'   global_vars = list(exposure_var = "treatment")
#' )
#' }
#'
#' @keywords internal
boilerplate_generate_text <- function(
    category = c("measures", "methods", "results", "discussion"),
    sections,
    global_vars = list(),
    section_vars = list(),
    text_overrides = list(),
    db = NULL,
    warn_missing = TRUE
) {
  # Input validation
  category <- match.arg(category)

  # Load database if not provided
  if (is.null(db)) {
    db <- boilerplate_manage_text(category = category, action = "list")
  }

  # Initialize result
  result <- character(0)

  # Process each section for text generation with arbitrary nesting
  for (section in sections) {
    # Check for text override
    if (section %in% names(text_overrides)) {
      result <- c(result, text_overrides[[section]])
      next
    }

    # Split the section into parts
    key_parts <- strsplit(section, "\\.")[[1]]

    # Merge global and section-specific variables
    vars <- global_vars
    if (section %in% names(section_vars)) {
      vars <- c(vars, section_vars[[section]])
    }

    # Attempt to retrieve text recursively
    section_text <- tryCatch({
      get_nested_text(db, key_parts, vars, warn_missing)
    }, error = function(e) {
      warning(paste("Error retrieving section", section, ":", e$message))
      return(NULL)
    })

    if (!is.null(section_text) && is.character(section_text)) {
      result <- c(result, section_text)
    }
  }

  # Combine all sections
  return(paste(result, collapse = "\n\n"))
}

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
#' @param warn_missing Logical. Whether to warn about missing template variables.
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
#' # Using deeply nested organization
#' methods_text <- boilerplate_methods_text(
#'   sections = c(
#'     "sample",
#'     "causal_assumptions.identification",
#'     "statistical.longitudinal.lmtp",
#'     "statistical.heterogeneity.grf.custom"
#'   ),
#'   global_vars = list(exposure_var = "treatment")
#' )
#' }
#'
#' @export
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
    warn_missing = TRUE
) {
  boilerplate_generate_text(
    category = "methods",
    sections = sections,
    global_vars = global_vars,
    section_vars = section_vars,
    text_overrides = text_overrides,
    db = db,
    warn_missing = warn_missing
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
#' @param warn_missing Logical. Whether to warn about missing template variables.
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
#' # Using domain-specific results with nested paths
#' results_text <- boilerplate_results_text(
#'   sections = c("main_effect", "domain.health", "domain.psychological"),
#'   results_data = list(
#'     effect_size = "0.35",
#'     confidence_interval = "95% CI: 0.21, 0.49",
#'     interpretation = "a moderate positive effect",
#'     health_finding = "improved physical outcomes",
#'     psych_finding = "reduced stress levels"
#'   )
#' )
#' }
#'
#' @export
boilerplate_results_text <- function(
    sections = c("main_effect"),
    results_data = list(),
    section_vars = list(),
    text_overrides = list(),
    db = NULL,
    warn_missing = TRUE
) {
  boilerplate_generate_text(
    category = "results",
    sections = sections,
    global_vars = results_data,
    section_vars = section_vars,
    text_overrides = text_overrides,
    db = db,
    warn_missing = warn_missing
  )
}

#' Create an Interactive Text Editor for Boilerplate Text
#'
#' This function provides a hierarchical text editor interface for managing
#' boilerplate text entries. It allows users to navigate, view, add, update, and
#' remove text entries in various categories with support for nested structures.
#'
#' @param category Character. Category of text to manage.
#'
#' @return No return value, called for side effects.
#'
#' @examples
#' \dontrun{
#' # Launch the interactive editor for methods
#' boilerplate_text_editor("methods")
#' }
#'
#' @importFrom cli cli_h1 cli_h2 cli_text cli_ol cli_li cli_alert_info
#'             cli_alert_danger cli_alert_warning cli_alert_success cli_code col_cyan
#' @export
boilerplate_text_editor <- function(category = c("measures", "methods", "results", "discussion")) {
  category <- match.arg(category)

  if (!requireNamespace("cli", quietly = TRUE)) {
    stop("Package 'cli' is required for the text editor interface.")
  }

  # Load database
  db <- boilerplate_manage_text(category = category, action = "list")

  # Create UI helper functions
  get_input <- function(prompt, allow_empty = FALSE) {
    while (TRUE) {
      input <- trimws(readline(cli::col_cyan(prompt)))
      if (input != "" || allow_empty)
        return(input)
      cli::cli_alert_danger("Input cannot be empty. Please try again.")
    }
  }

  get_multiline_input <- function(prompt) {
    cli::cli_text(cli::col_cyan(prompt))
    cli::cli_text(cli::col_cyan("Enter your text (press Enter twice on an empty line to finish):"))
    lines <- character()
    empty_line_count <- 0
    repeat {
      line <- readline()
      if (line == "") {
        empty_line_count <- empty_line_count + 1
        if (empty_line_count == 2) {
          break
        }
      } else {
        empty_line_count <- 0
      }
      lines <- c(lines, line)
    }
    paste(lines, collapse = "\n")
  }

  display_menu <- function(title, options) {
    cli::cli_h2(title)
    cli::cli_ol(options)
  }

  get_choice <- function(prompt, max_choice, allow_zero = FALSE) {
    while (TRUE) {
      choice <- suppressWarnings(as.integer(get_input(prompt)))
      if (!is.na(choice) &&
          ((allow_zero && choice >= 0 && choice <= max_choice) ||
           (!allow_zero && choice >= 1 && choice <= max_choice))) {
        return(choice)
      }
      if (allow_zero) {
        cli::cli_alert_danger(paste("Invalid choice. Please enter a number between 0 and", max_choice))
      } else {
        cli::cli_alert_danger(paste("Invalid choice. Please enter a number between 1 and", max_choice))
      }
    }
  }

  # Main editor loop
  cli::cli_h1(paste("Boilerplate Text Editor -", toupper(substr(category, 1, 1)), substr(category, 2, nchar(category))))

  # Initialize path stack for navigation
  path_stack <- list(list(name = "root", db = db))
  current_level <- 1

  repeat {
    current_location <- path_stack[[current_level]]
    current_db <- current_location$db

    # Display breadcrumb navigation
    breadcrumb <- if (current_level == 1) {
      "Root"
    } else {
      paste(sapply(path_stack[1:current_level], function(x) x$name), collapse = " > ")
    }

    # Display current entries
    cli::cli_h2(paste("Location:", breadcrumb))
    entries <- names(current_db)

    if (length(entries) == 0) {
      cli::cli_alert_info("No entries found at this location.")
    } else {
      for (i in seq_along(entries)) {
        if (is.list(current_db[[entries[i]]])) {
          # This is a subfolder
          cli::cli_li("{i}. [FOLDER] {entries[i]}")
        } else {
          # This is a text entry
          preview <- current_db[[entries[i]]]
          if (nchar(preview) > 50) {
            preview <- paste0(substr(preview, 1, 47), "...")
          }
          cli::cli_li("{i}. {entries[i]}: {preview}")
        }
      }
    }

    # Display options
    options <- c(
      "Navigate to folder/view entry",
      "Add entry",
      "Update entry",
      "Remove entry",
      "Go up one level",
      "Save changes",
      "Exit"
    )

    display_menu("Options", options)
    choice <- get_choice("Enter your choice: ", length(options))

    if (choice == 1) {
      # Navigate or view
      if (length(entries) == 0) {
        cli::cli_alert_warning("No entries to navigate to or view.")
      } else {
        entry_choice <- get_choice("Enter the number of the entry: ", length(entries))
        entry_name <- entries[entry_choice]
        entry_value <- current_db[[entry_name]]

        if (is.list(entry_value)) {
          # Navigate into subfolder
          path_stack[[current_level + 1]] <- list(name = entry_name, db = entry_value)
          current_level <- current_level + 1
        } else {
          # View text entry
          cli::cli_h2(paste("Entry:", entry_name))
          cli::cli_code(entry_value)
          readline(cli::col_cyan("Press Enter to continue..."))
        }
      }
    } else if (choice == 2) {
      # Add entry
      entry_name <- get_input("Enter name for the new entry: ")

      # Check if entry already exists
      if (entry_name %in% entries) {
        cli::cli_alert_danger("Entry already exists!")
        next
      }

      # Ask if this should be a folder or text entry
      entry_type <- tolower(get_input("Is this a folder (f) or text entry (t)? "))

      if (entry_type == "f") {
        # Create a new subfolder
        current_db[[entry_name]] <- list()
        cli::cli_alert_success("Created new folder: {entry_name}")
      } else {
        # Create a new text entry
        entry_text <- get_multiline_input("Enter text for the new entry: ")
        current_db[[entry_name]] <- entry_text
        cli::cli_alert_success("Added new text entry: {entry_name}")
      }

      # Update the database in the path stack
      path_stack[[current_level]]$db <- current_db

      # If we're in a subfolder, update the parent folders
      if (current_level > 1) {
        for (i in (current_level - 1):1) {
          parent_name <- path_stack[[i + 1]]$name
          path_stack[[i]]$db[[parent_name]] <- path_stack[[i + 1]]$db
        }
      }

      # Update the main database
      db <- path_stack[[1]]$db
    } else if (choice == 3) {
      # Update entry
      if (length(entries) == 0) {
        cli::cli_alert_warning("No entries to update.")
      } else {
        entry_choice <- get_choice("Enter the number of the entry to update: ", length(entries))
        entry_name <- entries[entry_choice]
        entry_value <- current_db[[entry_name]]

        if (is.list(entry_value)) {
          cli::cli_alert_warning("Cannot update a folder directly. Navigate into it first.")
        } else {
          cli::cli_h2(paste("Current text for", entry_name))
          cli::cli_code(entry_value)

          entry_text <- get_multiline_input("Enter new text: ")
          current_db[[entry_name]] <- entry_text

          # Update the database in the path stack
          path_stack[[current_level]]$db <- current_db

          # If we're in a subfolder, update the parent folders
          if (current_level > 1) {
            for (i in (current_level - 1):1) {
              parent_name <- path_stack[[i + 1]]$name
              path_stack[[i]]$db[[parent_name]] <- path_stack[[i + 1]]$db
            }
          }

          # Update the main database
          db <- path_stack[[1]]$db

          cli::cli_alert_success("Updated text entry: {entry_name}")
        }
      }
    } else if (choice == 4) {
      # Remove entry
      if (length(entries) == 0) {
        cli::cli_alert_warning("No entries to remove.")
      } else {
        entry_choice <- get_choice("Enter the number of the entry to remove: ", length(entries))
        entry_name <- entries[entry_choice]

        confirm <- tolower(get_input(paste("Are you sure you want to remove", entry_name, "? (y/n): ")))
        if (confirm == "y") {
          current_db[[entry_name]] <- NULL

          # Update the database in the path stack
          path_stack[[current_level]]$db <- current_db

          # If we're in a subfolder, update the parent folders
          if (current_level > 1) {
            for (i in (current_level - 1):1) {
              parent_name <- path_stack[[i + 1]]$name
              path_stack[[i]]$db[[parent_name]] <- path_stack[[i + 1]]$db
            }
          }

          # Update the main database
          db <- path_stack[[1]]$db

          cli::cli_alert_success("Removed entry: {entry_name}")
        }
      }
    } else if (choice == 5) {
      # Go up one level
      if (current_level == 1) {
        cli::cli_alert_warning("Already at the root level.")
      } else {
        current_level <- current_level - 1
      }
    } else if (choice == 6) {
      # Save changes
      file_path <- get_input("Enter file path to save (or press Enter for default): ", allow_empty = TRUE)
      if (file_path == "") {
        file_path <- get_default_file_path(category)
      }

      result <- boilerplate_manage_text(
        category = category,
        action = "save",
        db = db,
        file_path = file_path
      )

      if (result) {
        cli::cli_alert_success("Database saved successfully.")
      }
    } else if (choice == 7) {
      # Exit
      confirm_exit <- tolower(get_input("Exit without saving? Changes may be lost. (y/n): "))
      if (confirm_exit == "y") {
        cli::cli_alert_success("Exiting editor.")
        break
      }
    }
  }
}


#' Initialize Boilerplate Text Databases
#'
#' This function initializes or updates the boilerplate text databases with default values.
#' It's useful for setting up the system initially or adding new default entries.
#'
#' @param categories Character vector. Categories to initialize.
#' @param merge_strategy Character. How to merge with existing databases: "keep_existing", "merge_recursive", or "overwrite_all".
#' @param text_path Character. Path to the directory where text database files are stored.
#'   If NULL (default), the function will look in the following locations in order:
#'   1. "boilerplate/data/" subdirectory of the current working directory (via here::here())
#'   2. Package installation directory's "boilerplate/data/" folder
#'   3. "boilerplate/data/" relative to the current working directory
#' @param overwrite Logical. Whether to overwrite existing entries (deprecated, use merge_strategy instead).
#'
#' @return No return value, called for side effects.
#'
#' @examples
#' \dontrun{
#' # Initialize all categories with default merge strategy
#' boilerplate_init_text()
#'
#' # Initialize only methods
#' boilerplate_init_text("methods")
#'
#' # Use recursive merging
#' boilerplate_init_text(merge_strategy = "merge_recursive")
#'
#' # Completely overwrite existing databases
#' boilerplate_init_text(merge_strategy = "overwrite_all")
#'
#' # Initialize in a specific directory
#' boilerplate_init_text(text_path = "path/to/project/data")
#' }
#'
#' @export
boilerplate_init_text <- function(
    categories = c("measures", "methods", "results", "discussion"),
    merge_strategy = c("keep_existing", "merge_recursive", "overwrite_all"),
    text_path = NULL,
    overwrite = FALSE
) {
  # Handle input validation
  merge_strategy <- match.arg(merge_strategy)

  # Handle deprecated overwrite parameter
  if (overwrite && merge_strategy == "keep_existing") {
    merge_strategy <- "overwrite_all"
    warning("The 'overwrite' parameter is deprecated. Please use merge_strategy='overwrite_all' instead.")
  }

  # Process each category
  for (category in categories) {
    # Get default database for category
    default_db <- get_default_db(category)

    # Get file path
    file_path <- get_text_file_path(category, text_path)

    # Check if file exists
    if (file.exists(file_path) && merge_strategy != "overwrite_all") {
      # Load existing database
      existing_db <- tryCatch({
        readRDS(file_path)
      }, error = function(e) {
        warning(paste("Error loading existing database:", e$message))
        return(list())
      })

      # Apply selected merge strategy
      if (merge_strategy == "keep_existing") {
        # Only add new keys, never modify existing ones
        merged_db <- utils::modifyList(default_db, existing_db, keep.null = TRUE)
        message(paste("Merged", category, "database (keeping existing entries)"))
      } else if (merge_strategy == "merge_recursive") {
        # Deep recursive merge, combining nested structures
        merged_db <- merge_recursive_lists(default_db, existing_db)
        message(paste("Recursively merged", category, "database"))
      }

      # Save merged database
      save_text_db(merged_db, category, text_path)
    } else {
      # Save default database
      save_text_db(default_db, category, text_path)

      action <- if (merge_strategy == "overwrite_all") "Overwrote" else "Created new"
      message(paste(action, category, "database"))
    }
  }

  message("Initialization complete.")
}

#' Recursively Merge Two Lists
#'
#' This helper function performs a deep recursive merge of two lists,
#' combining nested structures while keeping values from the second list
#' when there are conflicts.
#'
#' @param x First list (defaults)
#' @param y Second list (existing values, takes precedence)
#'
#' @return Merged list
#'
#' @noRd
merge_recursive_lists <- function(x, y) {
  if (!is.list(x) || !is.list(y)) return(y)

  # For each name in x
  for (name in names(x)) {
    if (name %in% names(y)) {
      if (is.list(x[[name]]) && is.list(y[[name]])) {
        # Recursively merge lists
        y[[name]] <- merge_recursive_lists(x[[name]], y[[name]])
      }
      # Otherwise y's value takes precedence
    } else {
      # If not in y, add from x
      y[[name]] <- x[[name]]
    }
  }

  return(y)
}




# # Working with deeply nested paths
# methods_db <- boilerplate_manage_text(
#   category = "methods",
#   action = "add",
#   path = "statistical.longitudinal.custom.version1",
#   value = "Custom longitudinal estimation approach version 1."
# )
#
# # Retrieving from deep nested structure
# text <- boilerplate_manage_text(
#   category = "methods",
#   action = "get",
#   path = "statistical.heterogeneity.grf.custom",
#   template_vars = list(custom_param = "specialized splitting")
# )
#
# # Generating methods text with arbitrarily nested sections
# methods_text <- boilerplate_methods_text(
#   sections = c(
#     "sample",
#     "causal_assumptions.identification",
#     "statistical.longitudinal.lmtp",
#     "statistical.heterogeneity.grf.custom"
#   ),
#   global_vars = list(exposure_var = "treatment")
# )

