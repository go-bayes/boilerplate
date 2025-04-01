# test
# initialise measures
boilerplate_manage_text(
  category = "methods",
  action = "save",
  db = methods_db,
  file_path = "/Users/joseph/GIT/templates/method/boilerplate-text/methods_db.rds"
)

# list defaults
methods_db <- boilerplate_manage_text(category = "methods", action = "list")


# remove current sample
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "remove",
  key = "sample",
  db = methods_db
)


# ------------------------------------------------------
# sample section
# ------------------------------------------------------
sample_information_text <- "Data were collected as part of the New Zealand Attitudes and Values Study (NZAVS), an annual longitudinal national probability panel assessing New Zealand residents’ social attitudes, personality, ideology, and health outcomes. The panel began in 2009 and has since expanded to include over fifty researchers, with responses from `r n_total` participants to date. The study operates independently of political or corporate funding and is based at a university. It employs prize draws to incentivise participation. The NZAVS tends to slightly under-sample males and individuals of Asian descent and to over-sample females and Māori (the Indigenous people of New Zealand). To enhance the representativeness of our sample population estimates for the target population of New Zealand, we apply census-based survey weights that adjust for age, gender, and ethnicity (New Zealand European, Asian, Māori, Pacific) [@sibley2021]. For more information about the NZAVS, visit: [OSF.IO/75SNB](https://doi.org/10.17605/OSF.IO/75SNB). Refer to [Appendix A](#appendix-timeline) for a histogram of daily responses for this cohort."


methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  key = "sample",
  value = list(
    default = sample_information_text  # keep the existing text as the default
  ),
  db = methods_db
)

cat(methods_db$sample$default)

cat(methods_db$causal_assumptions$identification)


# ------------------------------------------------------
# identification assumptions section
# ------------------------------------------------------
identification_text <- "This study relies on the following key identification assumptions for estimating the causal effect of {{exposure_var}}:

1. **Consistency**: the observed outcome under the observed {{exposure_var}} is equal to the potential outcome under that exposure level. As part of consistency, we assume no interference: the potential outcomes for one individual are not affected by the {{exposure_var}} status of other individuals.

2. **Positivity**: there is a non-zero probability of receiving each level of {{exposure_var}} for every combination of values of {{exposure_var}} and confounders in the population.

3. **No unmeasured confounding**: all variables that affect both {{exposure_var}} and the outcome have been measured and accounted for in the analysis.

Satisfaction of these assumptions is critical for the causal interpretability of our results and should be carefully considered in light of the study design and available data."

# remove current sample
# methods_db <- boilerplate_manage_text(
#   category = "methods",
#   action = "remove",
#   key = "identification_assumptions",
#   db = methods_db
# )


# add identification assumptions section
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  path = "identification_assumptions.standard",
  value = identification_text,
  db = methods_db
)
cat(methods_db$identification_assumptions$standard)

# ------------------------------------------------------
# confounding control section
# ------------------------------------------------------
confounding_text <- "To manage confounding in our analysis, we implement [@vanderweele2019]'s *modified disjunctive cause criterion* by following these steps:

1. **Identified all common causes** of both the treatment and outcomes.
2. **Excluded instrumental variables** that affect the exposure but not the outcome. Instrumental variables do not contribute to controlling confounding and can reduce the efficiency of the estimates.
3. **Included proxies for unmeasured confounders** affecting both exposure and outcome. According to the principles of d-separation @pearl2009a, using proxies allows us to control for their associated unmeasured confounders indirectly.
4. **Controlled for baseline exposure** and **baseline outcome**. Both are used as proxies for unmeasured common causes, enhancing the robustness of our causal estimates, refer to @vanderweele2020."
# These methods adhere to the guidelines provided in [@bulbulia2024PRACTICAL] and were pre-specified in our study protocol [{{protocol_url}}]({{protocol_url}}).

# add confounding control section
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  path = "confounding_control.vanderweele",
  value = confounding_text,
  db = methods_db
)

cat(methods_db$confounding_control$vanderweele)

# ------------------------------------------------------
# eligibility criteria section
# ------------------------------------------------------
eligibility_text <- "To be included in the analysis of this study, participants needed to participate in the {{baseline_wave}} of the study and respond to {{exposure_var}}:

#### Inclusion Criteria

Participants may have been lost to follow-up at the end of the study if they met eligibility criteria at {{baseline_wave}}. We adjusted for attrition and non-response using censoring weights, described below.

#### Exclusion Criteria

A total of {{n_participants}} individuals met these criteria and were included in the study."

# add eligibility criteria section
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  path = "eligibility_criteria.standard",
  value = eligibility_text,
  db = methods_db
)

cat(methods_db$eligibility_criteria$standard)

# ------------------------------------------------------
# missing data handling section
# ------------------------------------------------------
missing_data_lmtp_text <- "To mitigate bias from missing data, we used the following strategies:

**Baseline missingness**: we employed the `ppm` algorithm from the `mice` package in R [@vanbuuren2018] to impute missing baseline data (wave {{baseline_wave}}). This method allowed us to reconstruct incomplete datasets by estimating a plausible value for missing observation. Because we could only pass one data set to the lmtp, we employed single imputation. Approximately {{baseline_missing_data_proportion}}% of covariate values were missing at {{baseline_wave}}. We only used baseline data to impute baseline wave missingness (refer to @zhang2023shouldMultipleImputation).

**Outcome missingness**: to address confounding and selection bias arising from missing responses and panel attrition at the end of study {{outcome_wave}}, we applied censoring weights obtained using nonparametric machine learning ensembles afforded by the `lmtp` package (and its dependencies) in R [@williams2021]."

missing_data_time_vary_lmtp_text <- "To mitigate bias from missing data, we implement the following strategies:

**Baseline missingness**: We used predictive mean matching from the `mice` package [@vanbuuren2018] to impute missing baseline values (comprising `r percent_missing_baseline` of the baseline data). Following [@zhang2023shouldMultipleImputation], we performed single imputation using only baseline data. For each column with missing values, we created a binary indicator of missingness so that the machine learning algorithms we employed could condition on missingness information during estimation (see `lmtp` documentation [@williams2021]).

**Missingness in Time-Varying Variables**: When a time-varying value was missing in any wave but a future value was observed, we carried forward the previous response and included a missingness indicator. Again, this approach let the patterns of missingness inform nonparametric machine learning. If no future value was observed, we considered the participant censored and used inverse probability of treatment weights to address attrition.

**Outcome missingness**: to address confounding and selection bias arising from missing responses and panel attrition at the end of study {{outcome_wave}}, we applied censoring weights obtained using nonparametric machine learning ensembles afforded by the `lmtp` package (and its dependencies) in R [@williams2021]."

# add missing data handling for lmtp
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  path = "missing_data.lmtp",
  value = missing_data_lmtp_text,
  db = methods_db
)


# add missing data handling for lmtp
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  path = "missing_data.lmtp_time_vary",
  value = missing_data_lmtp_text,
  db = methods_db
)


missing_data_grf_text <- "The GRF package accepts missing values at baseline. To obtain valid inference for missing responses we computed inverse probability of censoring weights. See Appendix {{grf_appendix}}."

# add missing data handling for grf
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  path = "missing_data.grf",
  value = missing_data_grf_text,
  db = methods_db
)

# ------------------------------------------------------
# statistical estimator sections
# ------------------------------------------------------

# lmtp short
lmtp_short_text <- "We estimate causal effects using the Longitudinal Modified Treatment Policy (LMTP) estimator within a Targeted Minimum Loss-based Estimation (TMLE) framework [@van2014targeted; @van2012targeted]. LMTP draws on machine learning for flexible outcome and treatment modeling and accounts for time-varying confounding [@van2014discussion; @vanderlaan2011; @vanderlaan2018]. This estimator is consistent if either the outcome model or the treatment mechanism is correct (double robustness). We use cross-validation to reduce overfitting [@bulbulia2024PRACTICAL]. We perform estimation with the `lmtp` package [@williams2021] and visualise outputs with the `margot` package [@margot2024]."

# add lmtp short
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  path = "statistical_estimator.lmtp.short",
  value = lmtp_short_text,
  db = methods_db
)

# lmtp long
lmtp_long_text <- "We perform statistical estimation using a Targeted Minimum Loss-based Estimation (TMLE) approach, specifically the Longitudinal Modified Treatment Policy (LMTP) estimator [@van2014targeted; @van2012targeted]. TMLE is a flexible framework for causal inference that provides valid uncertainty estimates. LMTP extends TMLE to handle time-varying treatments and confounders.

**Workflow:**
1. **Initial Modeling:** We use machine learning algorithms to flexibly model relationships among treatments, covariates, and outcomes. This approach accommodates complex, high-dimensional datasets without imposing strict parametric assumptions [@van2014discussion; @vanderlaan2011; @vanderlaan2018].
2. **Targeting:** TMLE then iteratively refines (or 'targets') these initial estimates, guided by the efficient influence function to align estimates more closely with the true causal effect.

**Advantages:**
- **Double robustness:** The estimator remains consistent if either the outcome model or the treatment mechanism model is correct.
- **Time-varying structure:** LMTP handles complex longitudinal data and repeated treatments.
- **Integration with machine learning:** TMLE benefits from flexible initial fits.
- **Censoring and attrition:** LMTP accommodates missing data through inverse-probability weighting.

We use cross-validation to avoid overfitting and to improve predictive performance [@bulbulia2024PRACTICAL]. The `lmtp` package [@williams2021] implements LMTP. We rely on the `SuperLearner` framework (with base learners such as `SL.ranger`, `SL.glmnet`, and `SL.xgboost`) for initial model fitting [@polley2023; @xgboost2023; @Ranger2017; @SuperLearner2023]. We create graphs, tables, and output with the `margot` package [@margot2024]."

# add lmtp long
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  path = "statistical_estimator.lmtp.long",
  value = lmtp_long_text,
  db = methods_db
)

# sdr short
sdr_short_text <- "We estimate causal effects of time-varying treatment policies using a Sequential Doubly Robust (SDR) estimator with the `lmtp` package [@williams2021; @díaz2021; @hoffman2023]. SDR involves two main steps. First, flexible machine learning models capture complex relationships among treatments, covariates, and outcomes [@díaz2021]. Second, SDR targets these initial fits to refine causal effect estimates. This design is multiply robust if treatments repeat over multiple waves [@diaz2023lmtp; @hoffman2023], ensuring consistency when either the outcome or treatment model is correct. We use `SuperLearner` [@SuperLearner2023] with `SL.ranger`, `SL.glmnet`, and `SL.xgboost` [@polley2023; @xgboost2023; @Ranger2017]. We use cross-validation to reduce overfitting and improve finite-sample performance. We create graphs, tables, and output with the `margot` package [@margot2024]."

# add sdr short
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  path = "statistical_estimator.sdr.short",
  value = sdr_short_text,
  db = methods_db
)

# grf short
grf_short_text <- "We estimate heterogeneous treatment effects with Generalized Random Forests (GRF) [@grf2024]. GRF extends random forests for causal inference by focusing on conditional average treatment effects (CATE). It handles complex interactions and non-linearities without explicit model specification, and it provides 'honest' estimates by splitting data between model-fitting and inference. GRF is doubly robust because it remains consistent if either the outcome model or the propensity model is correct. We evaluate policies with the `policytree` package [@policytree_package_2024; @athey_2021_policy_tree_econometrica] and visualise results with `margot` [@margot2024]."

# add grf short
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  path = "statistical_estimator.grf.short",
  value = grf_short_text,
  db = methods_db
)

# ------------------------------------------------------
# target population section
# ------------------------------------------------------
target_population_text <- "The target population for this study comprises New Zealand residents as represented in the {{baseline_wave}} of the New Zealand Attitudes and Values Study (NZAVS) during the years {{baseline_wave}} weighted by New Zealand Census weights for age, gender, and ethnicity (refer to @sibley2021). The NZAVS is a national probability study designed to reflect the broader New Zealand population accurately. Despite its comprehensive scope, the NZAVS has some limitations in its demographic representation. Notably, it tends to under-sample males and individuals of Asian descent while over-sampling females and Māori (the indigenous peoples of New Zealand). To address these disparities and enhance the accuracy of our findings, we apply New Zealand Census survey weights to the sample data."

# add target population
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  path = "target_population.nzavs",
  value = target_population_text,
  db = methods_db
)

# ------------------------------------------------------
# causal interventions section
# ------------------------------------------------------
causal_interventions_text <- "#### Interventions
This study considers the following causal interventions on the exposure variable '{{exposure_var}}':

{{interventions_list}}

#### Contrasts
{{contrasts_text}}

This approach to defining interventions and contrasts allows us to systematically evaluate the causal effects of interest in our study."

# add causal interventions
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  path = "causal_interventions.standard",
  value = causal_interventions_text,
  db = methods_db
)

cat(methods_db$identification_assumptions$standard)

# ------------------------------------------------------
# save the updated methods database
# ------------------------------------------------------
result <- boilerplate_manage_text(
  category = "methods",
  action = "save",
  db = methods_db
)

boilerplate_manage_text()
methods_db$sample$default
# check if save was successful
if (result) {
  cat("Methods database saved successfully!")
} else {
  cat("Error saving methods database!")
}



# ------------------------------------------------------
# now test generating text from the database
# ------------------------------------------------------

# example usage of generate_text for methods section
methods_text <- boilerplate_generate_text(
  category = "methods",
  sections = c(
    "sample.default",
    "identification_assumptions.standard",
    "confounding_control.vanderweele",
    "statistical_estimator.lmtp.short"
  ),
  global_vars = list(
    exposure_var = "political_conservative",
    n_total = 47000,
    appendices_sample = "A-C",
    baseline_wave = "NZAVS time 10, years 2018-2019",
    exposure_wave = "NZAVS time 11, years 2019-2020",
    outcome_wave = "NZAVS time 12, years 2020-2021",
    appendix_ref = "B",
    protocol_url = "https://osf.io/ce4t9/"
  )
)

# print the generated text
cat(methods_text)




# example of using the boilerplate text database in a research workflow
# this demonstrates how to generate methods text for a specific study

library(tidyverse)

# ------------------------------------------------------
# define study-specific variables
# ------------------------------------------------------

# define the study parameters
exposure_var <- "political_conservative"
outcomes_health <- c("smoker_binary", "hlth_bmi", "log_hours_exercise")
outcomes_psychological <- c("hlth_fatigue", "kessler_latent_anxiety")
outcomes_social <- c("belong", "neighbourhood_community")

# combine all outcomes into a single list
all_outcomes <- list(
  health = outcomes_health,
  psychological = outcomes_psychological,
  social = outcomes_social
)

study_params <- list(
  exposure_var = exposure_var,
  n_total = 47000,
  appendices_sample = "A-C",
  baseline_wave = "NZAVS time 10, years 2018-2019",
  exposure_wave = "NZAVS time 11, years 2019-2020",
  outcome_wave = "NZAVS time 12, years 2020-2021",
  baseline_missing_data_proportion = 0.15,
  appendix_ref = "B",
  protocol_url = "https://osf.io/ce4t9/",
  causal_interventions = c("Increase political_conservative", "Do not change political_conservative"),
  contrasts = "null",
  null_intervention = "Do not change political_conservative",
  n_participants = 32451,
  grf_appendix = "C"
)

# ------------------------------------------------------
# 1. generate the sample section
# ------------------------------------------------------
sample_text <- boilerplate_generate_text(
  category = "methods",
  sections = "sample.nzavs",
  global_vars = study_params
)

# ------------------------------------------------------
# 2. generate identification assumptions section
# ------------------------------------------------------
identification_text <- boilerplate_generate_text(
  category = "methods",
  sections = "identification_assumptions.standard",
  global_vars = study_params
)

# ------------------------------------------------------
# 3. generate confounding control section
# ------------------------------------------------------
confounding_text <- boilerplate_generate_text(
  category = "methods",
  sections = "confounding_control.vanderweele",
  global_vars = study_params
)

# ------------------------------------------------------
# 4. generate missing data handling sections for multiple estimators
# ------------------------------------------------------
# for lmtp
missing_data_lmtp <- boilerplate_generate_text(
  category = "methods",
  sections = "missing_data.lmtp",
  global_vars = study_params
)

# for grf
missing_data_grf <- boilerplate_generate_text(
  category = "methods",
  sections = "missing_data.grf",
  global_vars = study_params
)

# ------------------------------------------------------
# 5. generate statistical estimator sections for multiple estimators
# ------------------------------------------------------
# for lmtp (using the short version)
lmtp_text <- boilerplate_generate_text(
  category = "methods",
  sections = "statistical_estimator.lmtp.short",
  global_vars = study_params
)

# for grf (using the short version)
grf_text <- boilerplate_generate_text(
  category = "methods",
  sections = "statistical_estimator.grf.short",
  global_vars = study_params
)

# ------------------------------------------------------
# 6. combine all sections to create a complete methods section
# ------------------------------------------------------
methods_text <- paste(
  "# Methods\n\n",
  sample_text, "\n\n",
  identification_text, "\n\n",
  confounding_text, "\n\n",
  "## Missing Data Handling\n\n",
  "### LMTP Estimator\n",
  missing_data_lmtp, "\n\n",
  "### GRF Estimator\n",
  missing_data_grf, "\n\n",
  "## Statistical Estimators\n\n",
  "### LMTP\n",
  lmtp_text, "\n\n",
  "### GRF\n",
  grf_text,
  sep = ""
)

# ------------------------------------------------------
# 7. alternatively, generate the entire methods section at once
# ------------------------------------------------------
complete_methods <- boilerplate_generate_text(
  category = "methods",
  sections = c(
    "sample.nzavs",
    "identification_assumptions.standard",
    "confounding_control.vanderweele",
    "missing_data.lmtp",
    "missing_data.grf",
    "statistical_estimator.lmtp.short",
    "statistical_estimator.grf.short"
  ),
  global_vars = study_params
)

# ------------------------------------------------------
# 8. write the methods section to a Quarto markdown file
# ------------------------------------------------------
# using the combined text from step 6
writeLines(methods_text, "methods_section.qmd")

# or using the complete text from step 7
writeLines(complete_methods, "methods_section_complete.qmd")

# ------------------------------------------------------
# 9. add new entries to the database for future use
# ------------------------------------------------------
# first, get the current database
methods_db <- boilerplate_manage_text(category = "methods", action = "list")

# add a new custom text entry
new_text <- "In our analysis of {{exposure_var}}, we apply a novel sensitivity analysis approach based on the E-value framework developed by @vanderweele2017. This allows us to quantify the minimum strength of association that an unmeasured confounder would need to have with both the exposure and the outcome to explain away the observed effect. For our primary outcome of {{primary_outcome}}, we calculate E-values for both the point estimate and the lower bound of the {{confidence_level}}% confidence interval."

methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  path = "sensitivity_analysis.evalue",
  value = new_text,
  db = methods_db
)

# save the updated database
boilerplate_manage_text(
  category = "methods",
  action = "save",
  db = methods_db
)

# ------------------------------------------------------
# 10. creating a complete methods document with the updated database
# ------------------------------------------------------
# define additional parameters for the sensitivity analysis
study_params$primary_outcome <- "kessler_latent_anxiety"
study_params$confidence_level <- 95

# generate complete methods including the new sensitivity analysis section
complete_methods_updated <- boilerplate_generate_text(
  category = "methods",
  sections = c(
    "sample.nzavs",
    "identification_assumptions.standard",
    "confounding_control.vanderweele",
    "missing_data.lmtp",
    "statistical_estimator.lmtp.short",
    "sensitivity_analysis.evalue"  # new section added to the database
  ),
  global_vars = study_params
)

# write the updated methods section to a Quarto markdown file
writeLines(complete_methods_updated, "methods_section_with_sensitivity.qmd")







# enhanced boilerplate text extensions
# this script adds specialized sections to the methods database

library(tidyverse)

# get the current methods database
methods_db <- boilerplate_manage_text(category = "methods", action = "list")

# ------------------------------------------------------
# 1. heterogeneous treatment effects section
# ------------------------------------------------------
het_effects_text <- "### Heterogeneous Treatment Effects

To investigate whether the effect of {{exposure_var}} varies across different subgroups, we employ {{heterogeneity_method}} to estimate conditional average treatment effects (CATEs). This approach allows us to identify potential effect modifiers and understand how the intervention's impact differs across the population.

Our analysis focuses on the following pre-specified potential effect modifiers:
{{effect_modifiers}}

For each identified subgroup with significant effect heterogeneity, we report:
1. The estimated conditional average treatment effect
2. The difference from the overall average treatment effect
3. Statistical significance of the heterogeneity (p-values and confidence intervals)

This heterogeneity analysis provides critical insights for tailoring interventions and understanding which subpopulations may benefit most from the {{intervention_type}} intervention."

# add heterogeneous treatment effects section
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  path = "heterogeneous_effects.standard",
  value = het_effects_text,
  db = methods_db
)

# ------------------------------------------------------
# 2. mediation analysis section
# ------------------------------------------------------
mediation_text <- "### Causal Mediation Analysis

To understand the mechanisms through which {{exposure_var}} affects {{outcome_var}}, we conduct a formal causal mediation analysis. This analysis decomposes the total effect into:

1. **Natural Direct Effect (NDE)**: The effect of {{exposure_var}} on {{outcome_var}} that occurs through pathways other than the proposed mediator {{mediator_var}}.
2. **Natural Indirect Effect (NIE)**: The effect of {{exposure_var}} on {{outcome_var}} that operates specifically through the mediator {{mediator_var}}.

Our mediation analysis relies on the following additional identification assumptions:

1. **No mediator-outcome confounders affected by treatment**: There are no variables that (a) are affected by {{exposure_var}}, (b) confound the relationship between {{mediator_var}} and {{outcome_var}}.
2. **Cross-world counterfactual independence**: The counterfactual outcome under one exposure value and the counterfactual mediator under another exposure value are independent.

We implement this analysis using the {{mediation_method}} approach [@{{mediation_citation}}], which accommodates non-linearities in the relationships between variables and allows for exposure-mediator interactions. The proportion mediated is calculated as the ratio of the natural indirect effect to the total effect."

# add mediation analysis section
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  path = "mediation_analysis.standard",
  value = mediation_text,
  db = methods_db
)

# ------------------------------------------------------
# 3. longitudinal data structure section
# ------------------------------------------------------
longitudinal_text <- "### Longitudinal Data Structure

This study employs a longitudinal design spanning {{n_waves}} waves of data collection over {{time_period}}.

**Wave Structure**:
- **Baseline ({{baseline_wave}})**: Collection of baseline covariates and initial measurements of {{exposure_var}} and {{outcome_var}}
- **Intervention Period ({{intervention_waves}})**: {{intervention_description}}
- **Follow-up ({{follow_up_waves}})**: Assessment of outcomes and potential mediators

This longitudinal structure allows us to establish temporal precedence, with baseline covariates measured before the exposure, and outcomes measured after the exposure. The repeated measurements enable us to:

1. Account for time-varying confounding
2. Assess the stability of treatment effects over time
3. Investigate lagged effects and potential feedback loops
4. Track changes in both exposure and outcome variables

Our analytical approach explicitly incorporates this temporal structure through {{time_varying_approach}}."

# add longitudinal data structure section
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  path = "longitudinal_structure.standard",
  value = longitudinal_text,
  db = methods_db
)

# ------------------------------------------------------
# 4. multi-level model section
# ------------------------------------------------------
multilevel_text <- "### Hierarchical Data Structure and Multi-Level Modeling

Our data has a hierarchical structure with {{level1_units}} (level 1) nested within {{level2_units}} (level 2){{#level3_units}}, which are further nested within {{level3_units}} (level 3){{/level3_units}}. To account for this clustering and potential non-independence of observations, we employ multi-level modeling techniques.

The hierarchical structure of our data is as follows:
- **Level 1**: {{level1_description}}
- **Level 2**: {{level2_description}}
{{#level3_units}}
- **Level 3**: {{level3_description}}
{{/level3_units}}

Our multi-level models include random effects for {{random_effects_description}}. This approach allows us to:
1. Account for correlation among observations within the same cluster
2. Estimate cluster-specific effects
3. Properly partition variance at different levels of analysis
4. Generate appropriate standard errors that account for clustering

All analyses are implemented using the {{multilevel_package}} package in R, with maximum likelihood estimation."

# add multi-level model section
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  path = "multilevel_modeling.standard",
  value = multilevel_text,
  db = methods_db
)

# ------------------------------------------------------
# 5. Bayesian analysis section
# ------------------------------------------------------
bayesian_text <- "### Bayesian Statistical Approach

We employ a Bayesian framework for our statistical analysis, which offers several advantages for causal inference:

1. **Prior Information Integration**: We incorporate existing knowledge through informative priors based on {{prior_source}}. Specifically, we use {{prior_distribution}} priors for {{parameter_description}}.

2. **Full Posterior Distributions**: Rather than point estimates, we report entire posterior distributions for causal effects, providing a more nuanced understanding of uncertainty.

3. **Probabilistic Interpretation**: Results are presented as posterior probabilities and credible intervals, which have more intuitive interpretations than frequentist confidence intervals.

4. **Missing Data Handling**: The Bayesian approach naturally accommodates missing data through joint modeling of the complete data distribution.

We implement our models using {{bayesian_software}}, with {{mcmc_description}} to sample from the posterior distributions. Convergence is assessed through visual inspection of trace plots and the Gelman-Rubin diagnostic (R̂). We report posterior means, standard deviations, and {{credible_interval}}% credible intervals for all parameters of interest."

# add Bayesian analysis section
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  path = "bayesian_approach.standard",
  value = bayesian_text,
  db = methods_db
)

# ------------------------------------------------------
# 6. save the updated methods database
# ------------------------------------------------------
result <- boilerplate_manage_text(
  category = "methods",
  action = "save",
  db = methods_db
)

# check if save was successful
if (result) {
  cat("Methods database with extensions saved successfully!")
} else {
  cat("Error saving methods database!")
}

# ------------------------------------------------------
# 7. example usage with advanced sections
# ------------------------------------------------------

# define additional parameters for advanced sections
advanced_params <- list(
  exposure_var = "cognitive_behavioral_therapy",
  outcome_var = "depression_score",
  mediator_var = "negative_automatic_thoughts",
  heterogeneity_method = "Causal Random Forests (CRF)",
  effect_modifiers = "age, gender, baseline depression severity, and comorbid anxiety",
  intervention_type = "cognitive-behavioral",
  mediation_method = "interventional effects",
  mediation_citation = "vanderweele2014",
  n_waves = 4,
  time_period = "12 months",
  baseline_wave = "Month 0",
  intervention_waves = "Months 1-3",
  intervention_description = "Administration of the cognitive-behavioral therapy intervention",
  follow_up_waves = "Months 6 and 12",
  time_varying_approach = "marginal structural models",
  level1_units = "patients",
  level2_units = "clinicians",
  level3_units = "clinics",
  level1_description = "Individual patients receiving treatment (n = 1240)",
  level2_description = "Therapists providing treatment
}


# creating and using audience-specific method descriptions
library(tidyverse)

# get the current methods database
methods_db <- boilerplate_manage_text(category = "methods", action = "list")

# ------------------------------------------------------
# add audience-specific lmtp descriptions
# ------------------------------------------------------

# technical audience (statisticians/methodologists)
technical_lmtp_text <- "We estimate causal effects using the Longitudinal Modified Treatment Policy (LMTP) estimator within a Targeted Minimum Loss-based Estimation (TMLE) framework [@van2014targeted; @van2012targeted]. This semi-parametric estimator leverages the efficient influence function (EIF) to achieve double robustness and asymptotic efficiency. LMTP employs flexible machine learning for initial estimates of outcome regressions and treatment mechanisms, then updates these estimates through a targeted bias correction step that solves the efficient influence curve equation. The estimator remains consistent if either the outcome model or the treatment mechanism is correctly specified, providing dual protection against model misspecification. Implementation utilizes cross-validation to minimize overfitting risk [@bulbulia2024PRACTICAL] and incorporates the highly adaptive lasso (HAL) for complex functional forms. We rely on the `lmtp` package [@williams2021] with the `SuperLearner` ensemble framework [@polley2023] for implementation."

# applied researchers audience
applied_lmtp_text <- "We estimate causal effects using the Longitudinal Modified Treatment Policy (LMTP) estimator [@van2014targeted; @van2012targeted]. This approach combines machine learning with causal inference methods to estimate treatment effects while avoiding strict parametric assumptions. The estimator has a property called 'double robustness,' meaning it produces valid results if either our models for the outcome or for treatment assignment are correct. This provides additional protection against model misspecification compared to standard regression methods. We implement the approach using the `lmtp` package in R [@williams2021], with machine learning algorithms to flexibly capture relationships in the data. Cross-validation is employed to reduce overfitting [@bulbulia2024PRACTICAL]."

# general audience/policymakers
general_lmtp_text <- "We used advanced statistical methods that account for multiple factors that might influence both {{exposure_var}} and {{outcome_var}}. Our approach uses recent developments in causal inference that provide more reliable estimates than traditional statistical methods. This method helps us distinguish between mere association and actual causal effects by carefully accounting for other variables that might explain the relationship. Our analysis incorporates machine learning techniques that can detect complex patterns in the data without making overly simplistic assumptions about how variables relate to each other."

# add audience-specific entries to database
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  path = "statistical_estimator.lmtp.technical_audience",
  value = technical_lmtp_text,
  db = methods_db
)

methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  path = "statistical_estimator.lmtp.applied_audience",
  value = applied_lmtp_text,
  db = methods_db
)

methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  path = "statistical_estimator.lmtp.general_audience",
  value = general_lmtp_text,
  db = methods_db
)

# save the updated database
boilerplate_manage_text(
  category = "methods",
  action = "save",
  db = methods_db
)

# ------------------------------------------------------
# usage example: generating audience-specific reports
# ------------------------------------------------------

# define study parameters
study_params <- list(
  exposure_var = "political_conservative",
  outcome_var = "social_wellbeing",
  n_total = 47000,
  baseline_wave = "NZAVS time 10, years 2018-2019",
  exposure_wave = "NZAVS time 11, years 2019-2020",
  outcome_wave = "NZAVS time 12, years 2020-2021"
)

# function to generate methods text for different audiences
generate_methods_by_audience <- function(audience = c("technical", "applied", "general")) {
  audience <- match.arg(audience)

  # select appropriate paths based on audience
  if (audience == "technical") {
    lmtp_path <- "statistical_estimator.lmtp.technical_audience"
  } else if (audience == "applied") {
    lmtp_path <- "statistical_estimator.lmtp.applied_audience"
  } else {
    lmtp_path <- "statistical_estimator.lmtp.general_audience"
  }

  # generate text
  boilerplate_generate_text(
    category = "methods",
    sections = c(
      "sample.nzavs",
      lmtp_path
    ),
    global_vars = study_params
  )
}

# generate reports for different audiences
technical_report <- generate_methods_by_audience("technical")
applied_report <- generate_methods_by_audience("applied")
general_report <- generate_methods_by_audience("general")

# write outputs to files
writeLines(technical_report, "methods_technical_audience.qmd")
writeLines(applied_report, "methods_applied_audience.qmd")
writeLines(general_report, "methods_general_audience.qmd")


# creating document templates that incorporate boilerplate text sections
library(tidyverse)
library(glue)

# get the current methods database
methods_db <- boilerplate_manage_text(category = "methods", action = "list")

# ------------------------------------------------------
# create document templates for different formats
# ------------------------------------------------------

# typical journal article template
journal_article_template <- "---
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
{{methods.sample}}

## Measures
{{methods.measures}}

## Identification Assumptions
{{methods.identification_assumptions}}

## Confounding Control
{{methods.confounding_control}}

## Statistical Approach
{{methods.statistical_approach}}

# Results

{{results}}

# Discussion

{{discussion}}

# References
"

# add to database
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  path = "document_templates.journal_article",
  value = journal_article_template,
  db = methods_db
)

# conference presentation template
conference_template <- "---
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
{{methods.sample_brief}}

### Approach
{{methods.statistical_approach_brief}}

## Key Findings
{{results_highlights}}

## Implications
{{implications}}

## Thank You
{{acknowledgments}}
"

# add to database
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  path = "document_templates.conference_presentation",
  value = conference_template,
  db = methods_db
)

# grant proposal template
grant_template <- "---
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

## Overview
{{research_strategy.overview}}

## Methods
{{methods.sample_planned}}
{{methods.measures_planned}}
{{methods.statistical_approach_planned}}

## Timeline
{{timeline}}

# Budget Justification
{{budget_justification}}

# References
"

# add to database
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  path = "document_templates.grant_proposal",
  value = grant_template,
  db = methods_db
)

# save the updated database
boilerplate_manage_text(
  category = "methods",
  action = "save",
  db = methods_db
)

# ------------------------------------------------------
# function to generate a complete document from a template
# ------------------------------------------------------

generate_document <- function(template_path, study_params, template_vars) {
  # get the template
  template <- boilerplate_manage_text(
    category = "methods",
    action = "get",
    path = template_path
  )

  # generate all method sections
  methods <- list()

  # process each methods section specified in template_vars
  for (section_name in names(template_vars)) {
    # check if it's a methods section
    if (startsWith(section_name, "methods.")) {
      section_path <- template_vars[[section_name]]
      # generate the text for this section
      section_text <- boilerplate_generate_text(
        category = "methods",
        sections = section_path,
        global_vars = study_params
      )
      # store in methods list
      methods[[section_name]] <- section_text
      # update template_vars with actual text
      template_vars[[section_name]] <- section_text
    }
  }

  # apply all template variables to the template
  document <- template
  for (var_name in names(template_vars)) {
    var_placeholder <- paste0("{{", var_name, "}}")
    document <- gsub(var_placeholder, template_vars[[var_name]], document, fixed = TRUE)
  }

  return(document)
}

# ------------------------------------------------------
# usage example: generating a journal article
# ------------------------------------------------------

# define study parameters
study_params <- list(
  exposure_var = "political_conservative",
  outcome_var = "social_wellbeing",
  n_total = 47000,
  appendices_sample = "A-C",
  baseline_wave = "NZAVS time 10, years 2018-2019",
  exposure_wave = "NZAVS time 11, years 2019-2020",
  outcome_wave = "NZAVS time 12, years 2020-2021",
  appendix_ref = "B",
  protocol_url = "https://osf.io/ce4t9/"
)

# define template variables
template_vars <- list(
  title = "Political Orientation and Social Wellbeing in New Zealand: A Causal Analysis",
  authors = "Jane Smith, John Doe, and Robert Johnson",
  date = format(Sys.Date(), "%B %d, %Y"),
  abstract = "This study investigates the causal relationship between political orientation and social wellbeing using data from the New Zealand Attitudes and Values Study.",
  introduction = "Understanding the relationship between political beliefs and wellbeing has important implications for social policy and public health...",
  methods.sample = "sample.nzavs",
  methods.identification_assumptions = "identification_assumptions.standard",
  methods.confounding_control = "confounding_control.vanderweele",
  methods.statistical_approach = "statistical_estimator.lmtp.applied_audience",
  methods.measures = "Custom text about measures will go here.",
  results = "Our analysis revealed significant effects of political conservatism on social wellbeing...",
  discussion = "These findings suggest that political orientation may causally influence wellbeing through several pathways..."
)

# generate the document
journal_article <- generate_document(
  template_path = "document_templates.journal_article",
  study_params = study_params,
  template_vars = template_vars
)


# creating document templates that incorporate boilerplate text sections
library(tidyverse)
library(glue)

# get the current methods database
methods_db <- boilerplate_manage_text(category = "methods", action = "list")

# ------------------------------------------------------
# create document templates for different formats
# ------------------------------------------------------

# typical journal article template
journal_article_template <- "---
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
{{methods.sample}}

## Measures
{{methods.measures}}

## Identification Assumptions
{{methods.identification_assumptions}}

## Confounding Control
{{methods.confounding_control}}

## Statistical Approach
{{methods.statistical_approach}}

# Results

{{results}}

# Discussion

{{discussion}}

# References
"

# add to database
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  path = "document_templates.journal_article",
  value = journal_article_template,
  db = methods_db
)

# conference presentation template
conference_template <- "---
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
{{methods.sample_brief}}

### Approach
{{methods.statistical_approach_brief}}

## Key Findings
{{results_highlights}}

## Implications
{{implications}}

## Thank You
{{acknowledgments}}
"

# add to database
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  path = "document_templates.conference_presentation",
  value = conference_template,
  db = methods_db
)

# grant proposal template
grant_template <- "---
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

## Overview
{{research_strategy.overview}}

## Methods
{{methods.sample_planned}}
{{methods.measures_planned}}
{{methods.statistical_approach_planned}}

## Timeline
{{timeline}}

# Budget Justification
{{budget_justification}}

# References
"

# add to database
methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  path = "document_templates.grant_proposal",
  value = grant_template,
  db = methods_db
)

# save the updated database
boilerplate_manage_text(
  category = "methods",
  action = "save",
  db = methods_db
)

# ------------------------------------------------------
# function to generate a complete document from a template
# ------------------------------------------------------

generate_document <- function(template_path, study_params, template_vars) {
  # get the template
  template <- boilerplate_manage_text(
    category = "methods",
    action = "get",
    path = template_path
  )

  # generate all method sections
  methods <- list()

  # process each methods section specified in template_vars
  for (section_name in names(template_vars)) {
    # check if it's a methods section
    if (startsWith(section_name, "methods.")) {
      section_path <- template_vars[[section_name]]
      # generate the text for this section
      section_text <- boilerplate_generate_text(
        category = "methods",
        sections = section_path,
        global_vars = study_params
      )
      # store in methods list
      methods[[section_name]] <- section_text
      # update template_vars with actual text
      template_vars[[section_name]] <- section_text
    }
  }

  # apply all template variables to the template
  document <- template
  for (var_name in names(template_vars)) {
    var_placeholder <- paste0("{{", var_name, "}}")
    document <- gsub(var_placeholder, template_vars[[var_name]], document, fixed = TRUE)
  }

  return(document)
}

# ------------------------------------------------------
# usage example: generating a journal article
# ------------------------------------------------------

# define study parameters
study_params <- list(
  exposure_var = "political_conservative",
  outcome_var = "social_wellbeing",
  n_total = 47000,
  appendices_sample = "A-C",
  baseline_wave = "NZAVS time 10, years 2018-2019",
  exposure_wave = "NZAVS time 11, years 2019-2020",
  outcome_wave = "NZAVS time 12, years 2020-2021",
  appendix_ref = "B",
  protocol_url = "https://osf.io/ce4t9/"
)

# define template variables
template_vars <- list(
  title = "Political Orientation and Social Wellbeing in New Zealand: A Causal Analysis",
  authors = "Jane Smith, John Doe, and Robert Johnson",
  date = format(Sys.Date(), "%B %d, %Y"),
  abstract = "This study investigates the causal relationship between political orientation and social wellbeing using data from the New Zealand Attitudes and Values Study.",
  introduction = "Understanding the relationship between political beliefs and wellbeing has important implications for social policy and public health...",
  methods.sample = "sample.nzavs",
  methods.identification_assumptions = "identification_assumptions.standard",
  methods.confounding_control = "confounding_control.vanderweele",
  methods.statistical_approach = "statistical_estimator.lmtp.applied_audience",
  methods.measures = "Custom text about measures will go here.",
  results = "Our analysis revealed significant effects of political conservatism on social wellbeing...",
  discussion = "These findings suggest that political orientation may causally influence wellbeing through several pathways..."
)

# generate the document
journal_article <- generate_document(
  template_path = "document_templates.journal_article",
  study_params = study_params,
  template_vars = template_vars
)

# write to file
writeLines(journal_article, "political_orientation_article.qmd")

# write to file
writeLines(journal_article, "political_orientation_article.qmd")

