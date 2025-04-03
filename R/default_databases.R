
#' Get Default Measures Database
#'
#' @return List. The default measures database.
#'
#' @noRd
get_default_measures_db <- function() {
  # return a properly structured measures database with measures at the top level
  list(
    # anxiety measure as a top-level entry
    anxiety = list(
      name = "anxiety scale",
      description = "anxiety was measured using a standard anxiety scale",
      reference = "anxiety_reference",
      waves = "1-3",
      keywords = c("anxiety", "mental health"),
      items = list(
        "feeling nervous or anxious",
        "worrying too much about different things"
      )
    ),

    # depression measure as a top-level entry
    depression = list(
      name = "depression scale",
      description = "depression was measured using a standard depression scale",
      reference = "depression_reference",
      waves = "1-3",
      keywords = c("depression", "mental health"),
      items = list(
        "feeling down or depressed",
        "having little interest in doing things"
      )
    ),

    # alcohol frequency measure
    alcohol_frequency = list(
      name = "alcohol consumption frequency",
      description = "frequency of alcohol consumption was measured with a single item",
      reference = "alcohol_reference",
      waves = "1-4",
      keywords = c("alcohol", "substance use"),
      items = list(
        "how often do you consume alcoholic beverages?"
      )
    ),

    # another example measure
    life_satisfaction = list(
      name = "life satisfaction scale",
      description = "life satisfaction was measured using a standard scale",
      reference = "satisfaction_reference",
      waves = "1-4",
      keywords = c("wellbeing", "satisfaction"),
      items = list(
        "i am satisfied with my life",
        "the conditions of my life are excellent"
      )
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
      identification = "This study relies on the following identification assumptions for estimating the causal effect of {{exposure_var}}:

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
        default = "We estimate causal effects using the Longitudinal Modified Treatment Policy (LMTP) estimator within a Targeted Minimum Loss-based Estimation (TMLE) framework [@van2014targeted; @van2012targeted].",
        lmtp = "We perform statistical estimation using a Targeted Minimum Loss-based Estimation (TMLE) approach, specifically the Longitudinal Modified Treatment Policy (LMTP) estimator [@van2014targeted; @van2012targeted]. TMLE is a flexible framework for causal inference that provides valid uncertainty estimates. LMTP extends TMLE to handle time-varying treatments and confounders.",
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
      present_reflective = "In the present-reflective domain, we found {{present_reflective_finding}}.",
      life_reflective = "In the present-reflective domain, we found {{life_reflective_finding}}.",
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
    limitations = NULL,  # No default text, just a structural element
    future_directions = NULL,
    implications = list(
      clinical = NULL,
      policy = NULL,
      theoretical = NULL
    )
  )
}

#' Get Default Appendix Database
#'
#' @return List. The default appendix database.
#'
#' @noRd
get_default_appendix_db <- function() {
  list(
    supplementary_methods = "This appendix provides additional methodological details that supplement the main manuscript.",
    sensitivity_analyses = "We conducted several sensitivity analyses to evaluate the robustness of our findings to different assumptions.",
    additional_tables = "This appendix contains additional tables that could not be included in the main manuscript due to space constraints.",
    alternative_specifications = "We tested alternative model specifications to ensure that our results are not sensitive to specific modeling choices."
  )
}

#' Get Default Template Database
#'
#' @return List. The default template database.
#'
#' @noRd
get_default_template_db <- function() {
  list(
    journal_article = "---
title: \"{{title}}\"
author: \"{{authors}}\"
date: \"{{date}}\"
format:
  docx:
    reference-doc: journal_template.docx
bibliography: references.bib
---

# Abstract

{{abstract}}

# Introduction

{{introduction}}

# Methods

## Sample
{{methods_sample}}

## Measures
{{methods_measures}}

## Statistical Approach
{{methods_statistical}}

# Results

{{results}}

# Discussion

{{discussion}}

# References
",

    conference_presentation = "---
title: \"{{title}}\"
author: \"{{authors}}\"
date: \"{{date}}\"
format:
  revealjs:
    theme: default
    logo: institution_logo.png
bibliography: references.bib
---

## Research Question

{{research_question}}

## Methods
{{methods_brief}}

## Key Findings
{{results_highlights}}

## Implications
{{implications}}

## Thank You
{{acknowledgments}}
",

    grant_proposal = "---
title: \"{{title}}\"
author: \"{{authors}}\"
date: \"{{date}}\"
format: pdf
---

# Project Summary
{{project_summary}}

# Specific Aims
{{specific_aims}}

# Background and Significance
{{background}}

# Preliminary Studies
{{preliminary_studies}}

# Research Strategy

## Methods
{{methods_planned}}

## Timeline
{{timeline}}

# Budget Justification
{{budget_justification}}

# References
"
  )
}

#' Get Default Database for a Category
#'
#' @param category Character. Category to get default database for.
#'
#' @return List. Default database for the category.
#'
#' @noRd
get_default_db <- function(category) {
  # Return category-specific defaults
  if (category == "methods") {
    return(get_default_methods_db())
  } else if (category == "results") {
    return(get_default_results_db())
  } else if (category == "discussion") {
    return(get_default_discussion_db())
  } else if (category == "measures") {
    return(get_default_measures_db())
  } else if (category == "appendix") {
    return(get_default_appendix_db())
  } else if (category == "template") {
    return(get_default_template_db())
  } else {
    return(list())
  }
}
