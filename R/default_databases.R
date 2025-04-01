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
        lmtp = "e perform statistical estimation using a Targeted Minimum Loss-based Estimation (TMLE) approach, specifically the Longitudinal Modified Treatment Policy (LMTP) estimator [@van2014targeted; @van2012targeted]. TMLE is a flexible framework for causal inference that provides valid uncertainty estimates. LMTP extends TMLE to handle time-varying treatments and confounders.",
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

