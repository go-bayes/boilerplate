# Example 1: Using the new simplified function
methods_path = here::here("/Users/joseph/GIT/templates/databases/methods")
measures_path = here::here("/Users/joseph/GIT/templates/databases/measures")



# read
methods_db = margot::here_read("methods_db", methods_path)
measures_db = margot::here_read("merged_db", measures_path)


# 2. View the measures database
boilerplate_manage_measures(action = "list", db= measures_db)


# 3. Generate methods text for participant selection
methods_text <- boilerplate_generate_text(
  category = "methods",
  sections = c(
    "sample.default",
    "identification_assumptions.standard",
    "confounding_control.vanderweele",
    "statistical_estimator.lmtp.short",
    "missing_data.lmtp_time_vary",
    "approach.grf_cate_short"
  ),
  global_vars = list(
    exposure_var = "Political Conservativism",
    n_total = 47000,
    flipped_list = c("Anxiety", "Depression", "Fatigue", "Perfectionism"),
    appendices_sample = "A",
    appendix_outcomes = "B",
    baseline_wave = "NZAVS time 10, years 2018-2019",
    exposure_wave = "NZAVS time 11, years 2019-2020",
    outcome_wave = "NZAVS time 12, years 2020-2021",
    appendix_ref = "C",
    protocol_url = "https://osf.io/ce4t9/"
  ),
  db = methods_db
)

cat(methods_text)







# test
# initialise measures
library(glue)

# remove current sample
temp_methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "remove",
  name = "sample.nzavs",
  db = methods_db,
)

# ------------------------------------------------------
# sample section
# ------------------------------------------------------
sample_information_text <- "Data were collected as part of the New Zealand Attitudes and Values Study (NZAVS), an annual longitudinal national probability panel assessing New Zealand residents’ social attitudes, personality, ideology, and health outcomes. The panel began in 2009 and has since expanded to include over fifty researchers, with responses from {{n_total}} participants to date. The study operates independently of political or corporate funding and is based at a university. It employs prize draws to incentivise participation. The NZAVS tends to slightly under-sample males and individuals of Asian descent and to over-sample females and Māori (the Indigenous people of New Zealand). To enhance the representativeness of our sample population estimates for the target population of New Zealand, we apply census-based survey weights that adjust for age, gender, and ethnicity (New Zealand European, Asian, Māori, Pacific) [@sibley2021]. For more information about the NZAVS, visit: [OSF.IO/75SNB](https://doi.org/10.17605/OSF.IO/75SNB). Refer to [Appendix A](#appendix-timeline) for a histogram of daily responses for this cohort."


temp_methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  name = "sample.nzavs",
  value = list(
    default = sample_information_text  # keep the existing text as the default
  ),
  db = methods_db
)

cat(temp_methods_db$sample$nzavs$default)



# Tutorial ----------------------------------------------------------------


# example usage of generate_text for methods section
methods_text <- boilerplate_generate_text(
  category = "methods",
  sections = c(
    "sample.default",
    "identification_assumptions.standard",
    "confounding_control.vanderweele",
    "statistical_estimator.lmtp.short",
    "missing_data.lmtp_time_vary",
    "approach.grf_cate_short"
  ),
  global_vars = list(
    exposure_var = "Political Conservativism",
    n_total = 47000,
    flipped_list = c("Anxiety", "Depression", "Fatigue", "Perfectionism"),
    appendices_sample = "A",
    appendix_outcomes = "B",
    baseline_wave = "NZAVS time 10, years 2018-2019",
    exposure_wave = "NZAVS time 11, years 2019-2020",
    outcome_wave = "NZAVS time 12, years 2020-2021",
    appendix_ref = "C",
    protocol_url = "https://osf.io/ce4t9/"
  ),
  db = temp_methods_db
)

# print the generated text
cat(methods_text)


# results example ---------------------------------------------------------

results_text <- boilerplate_generate_text(
  category = "results",
  sections = c(
    "results.results.rate_qini_intro",
    "results.results.policy_tree_intro"
  ),
  global_vars = list(
    exposure_var = "political_conservative"
  ),
  db = methods_db
)


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
  var_name = "political_conservativism",
  appendices_sample = "A-C",
  baseline_wave = "NZAVS time 10, years 2018-2019",
  exposure_wave = "NZAVS time 11, years 2019-2020",
  outcome_wave = "NZAVS time 12, years 2020-2021",
  timeframe = "2018-2021",
  baseline_missing_data_proportion = 0.15,
  appendix_ref = "B",
  protocol_url = "https://osf.io/ce4t9/",
  causal_interventions = c("Increase political_conservative", "Do not change political_conservative"),
  contrasts = "null",
  null_intervention = "Do not change political_conservative",
  n_participants = 32451,
  population = "New Zealand Population in 2018",
  grf_appendix = "C"
)

# ------------------------------------------------------
# 1. generate the sample section
# ------------------------------------------------------
sample_text <- boilerplate_generate_text(
  category = "methods",
  sections = "sample.default",
  global_vars = study_params,
  db= temp_methods_db
)
cat(sample_text)
# ------------------------------------------------------
  # 2. generate identification assumptions section
# ------------------------------------------------------
identification_text <- boilerplate_generate_text(
  category = "methods",
  sections = "identification_assumptions.standard",
  global_vars = study_params,
  db = temp_methods_db
)
cat(identification_text)
# ------------------------------------------------------
# 3. generate confounding control section
# ------------------------------------------------------
confounding_text <- boilerplate_generate_text(
  category = "methods",
  sections = "confounding_control.vanderweele",
  global_vars = study_params,
  db = temp_methods_db
)
cat(confounding_text)
# --confounding_text# ------------------------------------------------------
# 4. generate missing data handling sections for multiple estimators
# ------------------------------------------------------
# for lmtp
missing_data_lmtp <- boilerplate_generate_text(
  category = "methods",
  sections = "missing_data.lmtp",
  global_vars = study_params,
  db = temp_methods_db
)

cat(missing_data_lmtp)

# for grf
missing_data_grf <- boilerplate_generate_text(
  category = "methods",
  sections = "missing_data.grf",
  global_vars = study_params,
  db = temp_methods_db
)

cat(missing_data_grf)

# ------------------------------------------------------
# 5. generate statistical estimator sections for multiple estimators
# ------------------------------------------------------
# for lmtp (using the short version)
lmtp_text <- boilerplate_generate_text(
  category = "methods",
  sections = "statistical_estimator.lmtp.short",
  global_vars = study_params,
  db = temp_methods_db
)

str(lmtp_text)

# for grf (using the short version)
grf_text <- boilerplate_generate_text(
  category = "methods",
  sections = "statistical_estimator.grf.short",
  global_vars = study_params,
  db = temp_methods_db
)

cat(grf_text)

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
    "sample.default",
    "identification_assumptions.standard",
    "confounding_control.vanderweele",
    "missing_data.lmtp",
    "missing_data.grf",
    "statistical_estimator.lmtp.short",
    "statistical_estimator.grf.short"
  ),
  global_vars = study_params,
  db = methods_db
)

cat(complete_methods)

# ------------------------------------------------------
# 8. write the methods section to a Quarto markdown file
# ------------------------------------------------------
# using the combined text from step 6
writeLines(methods_text, "methods_section.qmd")

# or using the complete text from step 7
writeLines(complete_methods, "methods_section_complete.qmd")

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
    "sample.default",
    "identification_assumptions.standard",
    "confounding_control.vanderweele",
    "missing_data.lmtp",
    "statistical_estimator.lmtp.short",
    "sensitivity_analysis.evalue"  # new section added to the database
  ),
  global_vars = study_params,
  db = methods_db
)

cat(complete_methods_updated)

# write the updated methods section to a Quarto markdown file
writeLines(complete_methods_updated, "methods_section_with_sensitivity.qmd")







# ELSE ADD ----------------------------------------------------------------



# #
# missing_data_grf_text <- "The GRF package accepts missing values at baseline. To obtain valid inference for missing responses we computed inverse probability of censoring weights. See Appendix {{grf_appendix}}."
#
# # add missing data handling for grf
# methods_db <- boilerplate_manage_text(
#   category = "methods",
#   action = "add",
#   name = "missing_data.grf",
#   value = missing_data_grf_text,
#   db = methods_db
# )
#
# # save
# margot::here_save(methods_db, "methods_db", methods_path)
# methods_path
# # ------------------------------------------------------
# # statistical estimator sections
# # ------------------------------------------------------
#
# # lmtp short
# lmtp_short_text <- "We estimate causal effects using the Longitudinal Modified Treatment Policy (LMTP) estimator within a Targeted Minimum Loss-based Estimation (TMLE) framework [@van2014targeted; @van2012targeted]. LMTP draws on machine learning for flexible outcome and treatment modeling and accounts for time-varying confounding [@van2014discussion; @vanderlaan2011; @vanderlaan2018]. This estimator is consistent if either the outcome model or the treatment mechanism is correct (double robustness). We use cross-validation to reduce overfitting [@bulbulia2024PRACTICAL]. We perform estimation with the `lmtp` package [@williams2021] and visualise outputs with the `margot` package [@margot2024]."
#
# # add lmtp short
# methods_db <- boilerplate_manage_text(
#   category = "methods",
#   action = "add",
#   name = "statistical_estimator.lmtp.short",
#   value = lmtp_short_text,
#   db = methods_db
# )
# # save
# margot::here_save(methods_db, "methods_db", methods_path)
#
# # lmtp long
# lmtp_long_text <- "We perform statistical estimation using a Targeted Minimum Loss-based Estimation (TMLE) approach, specifically the Longitudinal Modified Treatment Policy (LMTP) estimator [@van2014targeted; @van2012targeted]. TMLE is a flexible framework for causal inference that provides valid uncertainty estimates. LMTP extends TMLE to handle time-varying treatments and confounders.
#
# **Workflow:**
# 1. **Initial Modeling:** We use machine learning algorithms to flexibly model relationships among treatments, covariates, and outcomes. This approach accommodates complex, high-dimensional datasets without imposing strict parametric assumptions [@van2014discussion; @vanderlaan2011; @vanderlaan2018].
# 2. **Targeting:** TMLE then iteratively refines (or 'targets') these initial estimates, guided by the efficient influence function to align estimates more closely with the true causal effect.
#
# **Advantages:**
# - **Double robustness:** The estimator remains consistent if either the outcome model or the treatment mechanism model is correct.
# - **Time-varying structure:** LMTP handles complex longitudinal data and repeated treatments.
# - **Integration with machine learning:** TMLE benefits from flexible initial fits.
# - **Censoring and attrition:** LMTP accommodates missing data through inverse-probability weighting.
#
# We use cross-validation to avoid overfitting and to improve predictive performance [@bulbulia2024PRACTICAL]. The `lmtp` package [@williams2021] implements LMTP. We rely on the `SuperLearner` framework (with base learners such as `SL.ranger`, `SL.glmnet`, and `SL.xgboost`) for initial model fitting [@polley2023; @xgboost2023; @Ranger2017; @SuperLearner2023]. We create graphs, tables, and output with the `margot` package [@margot2024]."
#
# # add lmtp long
# methods_db <- boilerplate_manage_text(
#   category = "methods",
#   action = "add",
#   name = "statistical_estimator.lmtp.long",
#   value = lmtp_long_text,
#   db = methods_db
# )
# # save
# margot::here_save(methods_db, "methods_db", methods_path)
#
# # sdr short
# sdr_short_text <- "We estimate causal effects of time-varying treatment policies using a Sequential Doubly Robust (SDR) estimator with the `lmtp` package [@williams2021; @díaz2021; @hoffman2023]. SDR involves two main steps. First, flexible machine learning models capture complex relationships among treatments, covariates, and outcomes [@díaz2021]. Second, SDR targets these initial fits to refine causal effect estimates. This design is multiply robust if treatments repeat over multiple waves [@diaz2023lmtp; @hoffman2023], ensuring consistency when either the outcome or treatment model is correct. We use `SuperLearner` [@SuperLearner2023] with `SL.ranger`, `SL.glmnet`, and `SL.xgboost` [@polley2023; @xgboost2023; @Ranger2017]. We use cross-validation to reduce overfitting and improve finite-sample performance. We create graphs, tables, and output with the `margot` package [@margot2024]."
#
# # add sdr short
# methods_db <- boilerplate_manage_text(
#   category = "methods",
#   action = "add",
#   name = "statistical_estimator.sdr.short",
#   value = sdr_short_text,
#   db = methods_db
# )
# # save
# margot::here_save(methods_db, "methods_db", methods_path)
#
#
# sdr_long_text <- "
# #### Sequentially Doubly Robust (SDR) Estimator
#
# We employ a Sequentially Doubly Robust (SDR) estimator to assess the causal effects of time-varying treatment policies [@díaz2021]. SDR belongs to the broader class of doubly robust targeted learning estimators [@vanderlaan2011; @vanderlaan2018].
#
# **Process:**
# 1. **Initial Modeling:** SDR uses machine learning to flexibly model relationships among treatments, covariates, and outcomes at each time point, capturing complex dependencies without strict parametric assumptions.
# 2. **Sequential Updating:** SDR works backwards in time, combining outcome regression and propensity models to construct unbiased estimating equations for each time interval.
#
# **Advantages:**
# - **Sequential double robustness:** The estimator remains consistent at each time point if either the outcome or treatment mechanism model is correct (but not necessarily both).
# - **Time-varying confounders:** SDR naturally incorporates time-dependent structures.
# - **Flexible estimation:** It accommodates non-linearities and interactions through machine learning.
# - **Missingness:** The method handles attrition or loss-to-follow-up with inverse-probability weighting.
#
# We use cross-validation to reduce overfitting and improve finite-sample performance. We implement SDR through the `lmtp` package [@williams2021; @hoffman2023; @diaz2023lmtp], relying on `SuperLearner` with base learners such as `SL.ranger`, `SL.glmnet`, and `SL.xgboost` [@polley2023; @xgboost2023; @Ranger2017; @SuperLearner2023]. For more details, see [@hoffman2022; @hoffman2023; @díaz2021]. We use the `margot` package [@margot2024] for reporting and visualisation.
# "
# methods_db <- boilerplate_manage_text(
#   category = "methods",
#   action = "add",
#   name = "statistical_estimator.sdr.long",
#   value = sdr_long_text,
#   db = methods_db
# )
#
# # grf short
# grf_short_text <- "We estimate heterogeneous treatment effects with Generalized Random Forests (GRF) [@grf2024]. GRF extends random forests for causal inference by focusing on conditional average treatment effects (CATE). It handles complex interactions and non-linearities without explicit model specification, and it provides 'honest' estimates by splitting data between model-fitting and inference. GRF is doubly robust because it remains consistent if either the outcome model or the propensity model is correct. We evaluate policies with the `policytree` package [@policytree_package_2024; @athey_2021_policy_tree_econometrica] and visualise results with `margot` [@margot2024]."
#
# # add grf short
# methods_db <- boilerplate_manage_text(
#   category = "methods",
#   action = "add",
#   name = "statistical_estimator.grf.short",
#   value = grf_short_text,
#   db = methods_db
# )
#
#
#
# # save
# margot::here_save(methods_db, "methods_db", methods_path)
#
#
# # approach text -----------------------------------------------------------
# general_approach_cate_long <- "Our primary goal was to move beyond average treatment effects (ATE) and investigate whether the intervention's impact varied significantly across individuals based on their characteristics. To achieve this, we estimated individualised treatment effects, often termed conditional average treatment effects (CATEs), using causal forests [@grf2024]. Causal forests are a machine learning method adapted specifically for estimating how treatment effects differ across people defined by a set of covariates.
#
# For interpretability across different outcomes, we standardised the direction of effects. Some outcomes, like depression scores, are typically interpreted as 'lower is better'. We inverted the scales for such variables so that positive treatment effects consistently indicated improvement (e.g., a reduction in depression). This ensures that larger positive CATE estimates always signify greater benefit from the treatment. The following outcomes were inverted: {{flipped_list}}.
#
# A central challenge when modelling individual differences is ensuring the detected variations are genuine and not just noise or overfitting. Therefore, we rigorously evaluated the causal forest estimates using a 50/50 sample splitting approach. Half the data were used to train the causal forest model (i.e., to identify patterns of differing treatment effects), and the other half (the held-out data) were used exclusively for evaluation.
#
# On the held-out data, we first assessed the calibration of the predictions [@grf2024]. This involved checking if the average of the predicted CATEs accurately reflected the overall average treatment effect (ATE) found in the evaluation sample. More importantly, we tested whether the *predicted variation* in treatment effects (heterogeneous treatment effects, HTE) was reliable. A specific 'differential prediction' test acts as an omnibus indicator ($p$-value) of whether the model successfully captures statistically significant variability in how individuals respond to the treatment [@grf2024]. We also calculated the Rank-Weighted Average Treatment Effect (RATE) [@grf2024; @wager2018]. RATE quantifies the potential real-world value of using the model to target treatment – specifically, it measures the average outcome improvement we would expect if we prioritised treatment for the individuals predicted to benefit most, compared to a simpler strategy like treating everyone or no one based only on the ATE.
#
# To visualise the benefit of prioritisation, we used Qini curves [@grf2024]. These curves compare two scenarios evaluated on the held-out data:
# 1.  **Uniform Allocation:** Treating (or not treating) individuals based solely on the overall ATE.
# 2.  **Targeted Allocation:** Prioritising treatment for individuals ranked highest on their predicted CATE from the causal forest.
#
# The Qini curve plots the cumulative gain (or loss) achieved by the targeted approach as we increase the proportion of the sample receiving treatment (starting with those predicted to benefit most). Positive Qini values indicate that targeting treatment based on predicted CATEs yields better overall outcomes than the uniform approach for that proportion treated. This helps determine if a personalised strategy is advantageous, and potentially for what fraction of the population.
#
# Finally, if reliable heterogeneity was detected, we aimed to translate these complex CATE predictions into simpler, actionable rules using policy trees [@policytree_package_2024; @athey2021; @athey_2021_policy_tree_econometrica]. Policy trees learn simple decision rules (e.g., 'Treat individuals with baseline score > X and age < Y') that optimise treatment allocation based on the estimated CATEs. They identify key baseline characteristics that distinguish subgroups with markedly different responses, providing transparent, interpretable guidelines for potentially tailoring treatment in practice.
#
# All heterogeneity analyses, including calibration tests, RATE calculations, Qini curves, and policy trees, were conducted using R, primarily with the `grf` [@grf2024], `policytree` [@policytree_package_2024], and `margot` [@margot2024] packages. The figures presented were generated using `margot`.
#
# Collectively, this multi-stage approach allows us to first estimate individualised effects, rigorously test whether these estimated variations are reliable, evaluate the potential gains from targeting treatment, and finally, derive simple rules to guide personalised intervention strategies if justified by the data.
# "
# general_approach_cate_short <- "Our primary aim was to look beyond average treatment effects (ATE) and explore whether the intervention’s impact varied systematically across individuals. To that end, we estimated individualised treatment effects, also called conditional average treatment effects (CATEs), using causal forests [@grf2024], a machine learning approach tailored for detecting treatment-effect heterogeneity based on covariates.
#
# We standardised effect directions by inverting any outcome where 'lower is better', so positive values consistently denote improvement. The following outcomes were inverted: {{flipped_list}}.
#
# A common concern when modelling individual differences is distinguishing real variation from noise. To address this, we used a 50/50 sample split. We trained the causal forest on half the data, then tested model predictions exclusively on the remaining half to prevent overfitting.
#
# In the held-out sample, we checked whether the predicted CATEs were well calibrated [@grf2024]. This involved comparing (i) the mean of the predicted effects to the overall ATE in the evaluation sample, and (ii) testing whether the predicted *variation* in effects was reliable. A differential prediction test provided an omnibus $p$-value for whether the model captured genuine heterogeneity in responses. We also calculated the Rank-Weighted Average Treatment Effect (RATE), which estimates how effectively a model-based targeting strategy would outperform a uniform treatment strategy [@grf2024; @wager2018].
#
# To visualise the added value of targeting, we used Qini curves [@grf2024]. These compare:
#
# 1.  **Uniform Allocation**: treating or not treating everyone based on the overall ATE.
# 2.  **Targeted Allocation**: treating individuals ranked highest by their predicted CATE first.
#
# The Qini curve shows the cumulative gain (or loss) of the targeted strategy as we treat larger proportions of the sample. Positive values suggest that prioritising high-CATE individuals outperforms uniform treatment, helping identify whether, and at what coverage level, personalisation is beneficial.
#
# Finally, for practical implementation, we used policy trees [@policytree_package_2024; @athey2021; @athey_2021_policy_tree_econometrica] to derive simple, rule-based recommendations. Policy trees split participants into subgroups defined by key moderators, providing clear 'treat' or 'do not treat' cut-points, evaluated for effectiveness on the held-out data. All heterogeneity analyses—including calibration tests, RATE, Qini curves, and policy trees—were done in R using `grf` [@grf2024], `policytree` [@policytree_package_2024], and `margot` [@margot2024].
#
# Taken together, this multi-stage approach first identifies individualised treatment effects, then tests their reliability, estimates the added value of targeted intervention, and, if justified, provides simple rules for personalising treatment in practice."
#
# methods_db <- boilerplate_manage_text(
#   category = "methods",
#   action = "add",
#   name = "approach.grf_cate_long",
#   value = general_approach_cate_long,
#   db = methods_db
# )
#
# methods_db <- boilerplate_manage_text(
#   category = "methods",
#   action = "add",
#   name = "approach.grf_cate_short",
#   value = general_approach_cate_short,
#   db = methods_db
# )
#
# cat(methods_db$approach$grf_cate_short)
#
# results_ominibus_test_conclusion <-  "The omnibus test did not provide statistically significant evidence for overall treatment effect heterogeneity based on the examined covariates [@grf2024]. This suggests that, across all individuals and covariates considered, the model did not reliably detect variation beyond chance according to this specific test. However, omnibus tests can lack power for detecting subtle or localised heterogeneity. Therefore, we examined more specific indicators of potential targeting benefits and subgroup differences."
#
# # results_rate_qini_intro <-  "To assess the potential practical value of tailoring treatment based on individual predictions, we examined the Rank-Weighted Average Treatment Effect (RATE) and Qini curves [@grf2024; @wager2018]. RATE estimates the average gain expected if we prioritise treatment for those predicted to benefit most, compared to treating uniformly. Qini curves visualise this potential gain across different proportions of the population treated."
#
# results_rate_qini_intro <- "To assess the potential practical value of tailoring treatment based on individual predictions, we examined the Rank-Weighted Average Treatment Effect (RATE) and Qini curves [@grf2024; @wager2018]. These predictions are estimates (denoted $\\hat{\\tau}(X_i)$) of the underlying conditional average treatment effect (CATE, $\\tau(X_i)$), which represents the average treatment effect for individuals with specific baseline covariates $X_i$. Recall that for some outcomes ({{flipped_outcomes}}), scales were inverted so higher predicted effects ($\\hat{\\tau}(X_i)$) always indicate greater benefit from treatment. RATE and Qini curves evaluate how well a strategy of prioritising treatment using these CATE predictions $\\hat{\\tau}(X_i)$ performs compared to simpler approaches (e.g., uniform treatment based on the overall average effect, ATE). Specifically, RATE estimates the average gain achieved among the group prioritised by the model [@wager2018]. Qini curves dynamically visualise this potential gain: they plot the cumulative benefit realised as we hypothetically treat an increasing proportion of the population, starting with those individuals having the highest predicted effects $\\hat{\\tau}(X_i)$ [@grf2024]."
#
# results_policy_tree_intro <- "Finally, to identify potentially actionable insights and specific subgroups with distinct responses, we used policy trees [@policytree_package_2024; @athey2021; @athey_2021_policy_tree_econometrica]. This method seeks simple, interpretable rules (based on participant characteristics) that optimise treatment allocation based on estimated treatment effects ($\\hat{\\tau}(X_i)$). Recall that for some outcomes ({{flipped_outcomes}}), scales were inverted so higher predicted effects always indicate greater benefit. Policy trees can be particularly informative for uncovering localised heterogeneity, such as identifying small but well-defined subgroups who might experience substantially different treatment effects, even when overall variation is modest."
#
# methods_db <- boilerplate_manage_text(
#   category = "results",
#   action = "add",
#   name = "results.ominibus_test.conclusion",
#   value = results_ominibus_test_conclusion,
#   db = methods_db
# )
#
# methods_db <- boilerplate_manage_text(
#   category = "results",
#   action = "add",
#   name = "results.rate_qini_intro",
#   value = results_rate_qini_intro,
#   db = methods_db
# )
#
# methods_db <- boilerplate_manage_text(
#   category = "results",
#   action = "add",
#   name = "results.policy_tree_intro",
#   value = results_policy_tree_intro,
#   db = methods_db
# )
#
#
# # save
# margot::here_save(methods_db, "methods_db", methods_path)
#
#
# # ------------------------------------------------------
# # target population section
# # ------------------------------------------------------
# target_population_text <- "The target population for this study comprises New Zealand residents as represented in the {{baseline_wave}} of the New Zealand Attitudes and Values Study (NZAVS) during the years {{baseline_wave}} weighted by New Zealand Census weights for age, gender, and ethnicity (refer to @sibley2021). The NZAVS is a national probability study designed to reflect the broader New Zealand population accurately. Despite its comprehensive scope, the NZAVS has some limitations in its demographic representation. Notably, it tends to under-sample males and individuals of Asian descent while over-sampling females and Māori (the indigenous peoples of New Zealand). To address these disparities and enhance the accuracy of our findings, we apply New Zealand Census survey weights to the sample data."
#
# # add target population
# methods_db <- boilerplate_manage_text(
#   category = "methods",
#   action = "add",
#   name = "target_population.nzavs",
#   value = target_population_text,
#   db = methods_db
# )
# # save
# margot::here_save(methods_db, "methods_db", methods_path)
# # ------------------------------------------------------
# # causal interventions section
# # ------------------------------------------------------
# causal_interventions_text <- "#### Interventions
# This study considers the following causal interventions on the exposure variable '{{exposure_var}}':
#
# {{interventions_list}}
#
# #### Contrasts
# {{contrasts_text}}
#
# This approach to defining interventions and contrasts allows us to systematically evaluate the causal effects of interest in our study."
#
# # add causal interventions
# methods_db <- boilerplate_manage_text(
#   category = "methods",
#   action = "add",
#   name = "causal_interventions.standard",
#   value = causal_interventions_text,
#   db = methods_db
# )
#
# cat(methods_db$identification_assumptions$standard)
#
# # save
# margot::here_save(methods_db, "methods_db", methods_path)
#
# # ------------------------------------------------------
# # save the updated methods database
# # ------------------------------------------------------
# result <- boilerplate_manage_text(
#   category = "methods",
#   action = "save",
#   db = methods_db
# )



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
    "statistical_estimator.lmtp.short",
    "missing_data.lmtp_time_vary",
    "approach.grf_cate_short"
  ),
  global_vars = list(
    exposure_var = "Political Conservativism",
    n_total = 47000,
    flipped_list = c("Anxiety", "Depression", "Fatigue", "Perfectionism"),
    appendices_sample = "A",
    appendix_outcomes = "B",
    baseline_wave = "NZAVS time 10, years 2018-2019",
    exposure_wave = "NZAVS time 11, years 2019-2020",
    outcome_wave = "NZAVS time 12, years 2020-2021",
    appendix_ref = "C",
    protocol_url = "https://osf.io/ce4t9/"
  ),
  db = methods_db
)

# print the generated text
cat(methods_text)


# results example ---------------------------------------------------------

results_text <- boilerplate_generate_text(
  category = "results",
  sections = c(
    "results.results.rate_qini_intro",
    "results.results.rate_qini_intro",
    "results.results.policy_tree_intro"
  ),
  global_vars = list(
    exposure_var = "political_conservative",
  ),
  db = methods_db
)


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
  var_name = "political_conservativism",
  appendices_sample = "A-C",
  baseline_wave = "NZAVS time 10, years 2018-2019",
  exposure_wave = "NZAVS time 11, years 2019-2020",
  outcome_wave = "NZAVS time 12, years 2020-2021",
  timeframe = "2018-2021",
  baseline_missing_data_proportion = 0.15,
  appendix_ref = "B",
  protocol_url = "https://osf.io/ce4t9/",
  causal_interventions = c("Increase political_conservative", "Do not change political_conservative"),
  contrasts = "null",
  null_intervention = "Do not change political_conservative",
  n_participants = 32451,
  population = "New Zealand Population in 2018",
  grf_appendix = "C"
)

# ------------------------------------------------------
# 1. generate the sample section
# ------------------------------------------------------
sample_text <- boilerplate_generate_text(
  category = "methods",
  sections = "sample.default",
  global_vars = study_params,
  db= methods_db
)
cat(sample_text)
------------------------------------------------------
  # 2. generate identification assumptions section
  # ------------------------------------------------------
identification_text <- boilerplate_generate_text(
  category = "methods",
  sections = "identification_assumptions.standard",
  global_vars = study_params,
  db = methods_db
)
cat(identification_text)
# ------------------------------------------------------
# 3. generate confounding control section
# ------------------------------------------------------
confounding_text <- boilerplate_generate_text(
  category = "methods",
  sections = "confounding_control.vanderweele",
  global_vars = study_params,
  db = methods_db
)
cat(confounding_text)
# --confounding_text# ------------------------------------------------------
# 4. generate missing data handling sections for multiple estimators
# ------------------------------------------------------
# for lmtp
missing_data_lmtp <- boilerplate_generate_text(
  category = "methods",
  sections = "missing_data.lmtp",
  global_vars = study_params,
  db = methods_db
)

cat(missing_data_lmtp)

# for grf
missing_data_grf <- boilerplate_generate_text(
  category = "methods",
  sections = "missing_data.grf",
  global_vars = study_params,
  db = methods_db
)

cat(missing_data_grf)

# ------------------------------------------------------
# 5. generate statistical estimator sections for multiple estimators
# ------------------------------------------------------
# for lmtp (using the short version)
lmtp_text <- boilerplate_generate_text(
  category = "methods",
  sections = "statistical_estimator.lmtp.short",
  global_vars = study_params,
  db = methods_db
)

str(lmtp_text)

# for grf (using the short version)
grf_text <- boilerplate_generate_text(
  category = "methods",
  sections = "statistical_estimator.grf.short",
  global_vars = study_params,
  db = methods_db
)

cat(grf_text)

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
    "sample.default",
    "identification_assumptions.standard",
    "confounding_control.vanderweele",
    "missing_data.lmtp",
    "missing_data.grf",
    "statistical_estimator.lmtp.short",
    "statistical_estimator.grf.short"
  ),
  global_vars = study_params,
  db = methods_db
)

cat(complete_methods)

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

# add a new custom text entry
new_text <- "In our analysis of {{exposure_var}}, we apply a novel sensitivity analysis approach based on the E-value framework developed by @vanderweele2017. This allows us to quantify the minimum strength of association that an unmeasured confounder would need to have with both the exposure and the outcome to explain away the observed effect. For our primary outcome of {{primary_outcome}}, we calculate E-values for both the point estimate and the lower bound of the {{confidence_level}}% confidence interval."

methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  name = "sensitivity_analysis.evalue",
  value = new_text,
  db = methods_db
)

head(methods_db)

margot::here_save(methods_db, "methods_db", methods_path)

# save the updated database
# boilerplate_manage_text(
#   category = "methods",
#   action = "save",
#   db = methods_db
# )

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
    "sample.default",
    "identification_assumptions.standard",
    "confounding_control.vanderweele",
    "missing_data.lmtp",
    "statistical_estimator.lmtp.short",
    "sensitivity_analysis.evalue"  # new section added to the database
  ),
  global_vars = study_params,
  db = methods_db
)

cat(complete_methods_updated)

# write the updated methods section to a Quarto markdown file
writeLines(complete_methods_updated, "methods_section_with_sensitivity.qmd")







# enhanced boilerplate text extensions
# this script adds specialized sections to the methods database

library(tidyverse)

# get the current methods database
# methods_db <- boilerplate_manage_text(category = "methods", action = "list")

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
  name = "heterogeneous_effects.standard",
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
  name = "mediation_analysis.standard",
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
  name = "longitudinal_structure.standard",
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
  name = "multilevel_modeling.standard",
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
  name = "bayesian_approach.standard",
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
result
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
  n_total = "47,940",
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
  level2_description = "Therapists providing treatment"
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
  name = "statistical_estimator.lmtp.technical_audience",
  value = technical_lmtp_text,
  db = methods_db
)

methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  name = "statistical_estimator.lmtp.applied_audience",
  value = applied_lmtp_text,
  db = methods_db
)

methods_db <- boilerplate_manage_text(
  category = "methods",
  action = "add",
  name = "statistical_estimator.lmtp.general_audience",
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
  name = "document_templates.journal_article",
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
  name = "document_templates.conference_presentation",
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
  name = "document_templates.grant_proposal",
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
  n_total = "47000",
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




# working with databases --------------------------------------------------
# defaults
l_measures_db <- boilerplate_manage_measures(action = "list")

measuremeasures_db <- boilerplate_manage_measures(
  action = "add",
  name = "alcohol_frequency_2",
  measure = list(
    description = "Frequency of alcohol consumption was measured using a single item.",
    reference = "nzavs2009",
    waves = "1-current",
    keywords = c("alcohol", "frequency", "consumption"),
    items = list("How often do you have a drink containing alcohol?",
                 "test item")
  ),
  db = test_measures_db
)
measuremeasures_db$alcohol_frequency_2

