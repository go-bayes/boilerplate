#' Generate Statistical Estimator Descriptions
#'
#' Produces short or long descriptions of various statistical estimators.
#'
#' @param estimators A character vector of estimator names. Supported values are:
#'   \code{"lmtp"}, \code{"sdr"}, \code{"grf"}.
#' @param version Either \code{"short"} or \code{"long"}. Defaults to \code{"short"}.
#'
#' @return A character string with the description in markdown format.
#' @export
#'
boilerplate_report_statistical_estimator <- function(estimators = "lmtp", version = "short") {

  # Ensure 'estimators' is a character vector
  if (is.character(estimators) && length(estimators) == 1) {
    estimators <- list(estimators)
  }

  # ============== LMTP ==============
  lmtp_short <- "
#### Longitudinal Modified Treatment Policy (LMTP) Estimator

We estimate causal effects using the Longitudinal Modified Treatment Policy (LMTP) estimator within a Targeted Minimum Loss-based Estimation (TMLE) framework [@van2014targeted; @van2012targeted]. LMTP draws on machine learning for flexible outcome and treatment modeling and accounts for time-varying confounding [@van2014discussion; @vanderlaan2011; @vanderlaan2018]. This estimator is consistent if either the outcome model or the treatment mechanism is correct (double robustness). We use cross-validation to reduce overfitting [@bulbulia2024PRACTICAL]. We perform estimation with the `lmtp` package [@williams2021] and visualise outputs with the `margot` package [@margot2024].
"

  lmtp_long <- "
#### Longitudinal Modified Treatment Policy (LMTP) Estimator

We perform statistical estimation using a Targeted Minimum Loss-based Estimation (TMLE) approach, specifically the Longitudinal Modified Treatment Policy (LMTP) estimator [@van2014targeted; @van2012targeted]. TMLE is a flexible framework for causal inference that provides valid uncertainty estimates. LMTP extends TMLE to handle time-varying treatments and confounders.

**Workflow:**
1. **Initial Modeling:** We use machine learning algorithms to flexibly model relationships among treatments, covariates, and outcomes. This approach accommodates complex, high-dimensional datasets without imposing strict parametric assumptions [@van2014discussion; @vanderlaan2011; @vanderlaan2018].
2. **Targeting:** TMLE then iteratively refines (or 'targets') these initial estimates, guided by the efficient influence function to align estimates more closely with the true causal effect.

**Advantages:**
- **Double robustness:** The estimator remains consistent if either the outcome model or the treatment mechanism model is correct.
- **Time-varying structure:** LMTP handles complex longitudinal data and repeated treatments.
- **Integration with machine learning:** TMLE benefits from flexible initial fits.
- **Censoring and attrition:** LMTP accommodates missing data through inverse-probability weighting.

We use cross-validation to avoid overfitting and to improve predictive performance [@bulbulia2024PRACTICAL]. The `lmtp` package [@williams2021] implements LMTP. We rely on the `SuperLearner` framework (with base learners such as `SL.ranger`, `SL.glmnet`, and `SL.xgboost`) for initial model fitting [@polley2023; @xgboost2023; @Ranger2017; @SuperLearner2023]. We create graphs, tables, and output with the `margot` package [@margot2024].
"

  # ============== SDR ==============
  sdr_short <- "
#### Sequential Doubly Robust (SDR) Estimator

We estimate causal effects of time-varying treatment policies using a Sequential Doubly Robust (SDR) estimator with the `lmtp` package [@williams2021; @díaz2021; @hoffman2023]. SDR involves two main steps. First, flexible machine learning models capture complex relationships among treatments, covariates, and outcomes [@díaz2021]. Second, SDR targets these initial fits to refine causal effect estimates. This design is multiply robust if treatments repeat over multiple waves [@diaz2023lmtp; @hoffman2023], ensuring consistency when either the outcome or treatment model is correct. We use `SuperLearner` [@SuperLearner2023] with `SL.ranger`, `SL.glmnet`, and `SL.xgboost` [@polley2023; @xgboost2023; @Ranger2017]. We use cross-validation to reduce overfitting and improve finite-sample performance. We create graphs, tables, and output with the `margot` package [@margot2024].
"

  sdr_long <- "
#### Sequentially Doubly Robust (SDR) Estimator

We employ a Sequentially Doubly Robust (SDR) estimator to assess the causal effects of time-varying treatment policies [@díaz2021]. SDR belongs to the broader class of doubly robust targeted learning estimators [@vanderlaan2011; @vanderlaan2018].

**Process:**
1. **Initial Modeling:** SDR uses machine learning to flexibly model relationships among treatments, covariates, and outcomes at each time point, capturing complex dependencies without strict parametric assumptions.
2. **Sequential Updating:** SDR works backwards in time, combining outcome regression and propensity models to construct unbiased estimating equations for each time interval.

**Advantages:**
- **Sequential double robustness:** The estimator remains consistent at each time point if either the outcome or treatment mechanism model is correct (but not necessarily both).
- **Time-varying confounders:** SDR naturally incorporates time-dependent structures.
- **Flexible estimation:** It accommodates non-linearities and interactions through machine learning.
- **Missingness:** The method handles attrition or loss-to-follow-up with inverse-probability weighting.

We use cross-validation to reduce overfitting and improve finite-sample performance. We implement SDR through the `lmtp` package [@williams2021; @hoffman2023; @diaz2023lmtp], relying on `SuperLearner` with base learners such as `SL.ranger`, `SL.glmnet`, and `SL.xgboost` [@polley2023; @xgboost2023; @Ranger2017; @SuperLearner2023]. For more details, see [@hoffman2022; @hoffman2023; @díaz2021]. We use the `margot` package [@margot2024] for reporting and visualisation.
"

  # ============== GRF ==============
  grf_short <- "
#### Generalized Random Forests (GRF)

We estimate heterogeneous treatment effects with Generalized Random Forests (GRF) [@grf2024]. GRF extends random forests for causal inference by focusing on conditional average treatment effects (CATE). It handles complex interactions and non-linearities without explicit model specification, and it provides 'honest' estimates by splitting data between model-fitting and inference. GRF is doubly robust because it remains consistent if either the outcome model or the propensity model is correct. We evaluate policies with the `policytree` package [@policytree_package_2024; @athey_2021_policy_tree_econometrica] and visualise results with `margot` [@margot2024].
"

  grf_long <- "
#### Generalized Random Forests (GRF)

We employ Generalized Random Forests (GRF) [@grf2024] to estimate heterogeneous treatment effects in a flexible, non-parametric framework. GRF modifies the standard random forest algorithm to target conditional average treatment effects (CATE) rather than only outcome prediction.

**Key Features:**
1. **Non-linear modeling:** GRF uncovers intricate relationships and interactions among covariates.
2. **Heterogeneity detection:** It reveals how treatment effects vary across subgroups or individuals with different characteristics.
3. **Honest inference:** GRF uses sample-splitting techniques to mitigate overfitting and produce valid confidence intervals.
4. **Multiple outcome types:** It handles continuous, binary, or time-to-event outcomes without strict distributional assumptions.
5. **Double robustness:** GRF remains consistent if either the outcome model or the propensity model is correct, which provides additional protection against model misspecification.

In our analysis:
- We rely on the `grf` package [@grf2024] for estimation.
- We evaluate policies with the `policytree` package [@policytree_package_2024; @athey_2021_policy_tree_econometrica].
- We create figures and tables using the `margot` package [@margot2024].

We highlight how average treatment effects may differ across relevant subgroups, offering nuanced causal insights.
"

  # Combine into a nested list for easy retrieval
  estimator_texts <- list(
    lmtp = list(short = lmtp_short, long = lmtp_long),
    sdr  = list(short = sdr_short,  long = sdr_long),
    grf  = list(short = grf_short,  long = grf_long)
  )

  # For each requested estimator, retrieve either short or long text
  selected_texts <- lapply(estimators, function(est) {
    est_lower <- tolower(est)
    if (!est_lower %in% names(estimator_texts)) {
      warning(sprintf("Estimator '%s' is not recognized. Skipping.", est))
      return(NULL)
    }
    estimator_texts[[est_lower]][[version]]
  })

  # Collapse all selected texts into one markdown string
  markdown_text <- paste0(
    "\n### Statistical Estimator\n\n",
    paste(unlist(selected_texts), collapse = "\n\n")
  )

  return(markdown_text)
}
# boilerplate_report_statistical_estimator <- function(estimators = "lmtp") {
#   if (is.character(estimators) && length(estimators) == 1) {
#     estimators <- list(estimators)
#   }
#
#   estimator_texts <- list(
#     lmtp = "
# #### Longitudinal Modified Treatment Policy (LMTP) Estimator
#
# We perform statistical estimation using a semi-parametric Targeted Minimum Loss-based Estimation (TMLE) approach, specifically the Longitudinal Modified Treatment Policy (LMTP) estimator. TMLE is a robust method for estimating causal effects while providing valid statistical uncertainty measures [@van2014targeted; @van2012targeted].
#
# TMLE operates through a two-step process:
#
# 1. **Initial Modeling:** TMLE models the relationship between treatments, covariates, and outcomes. We employ machine learning algorithms for this step, allowing us to flexibly model complex, high-dimensional covariate spaces without imposing restrictive model assumptions [@van2014discussion; @vanderlaan2011; @vanderlaan2018]. This results in a set of initial estimates for these relationships.
#
# 2. **Targeting:** TMLE 'targets' these initial estimates by incorporating information about the observed data distribution to improve the accuracy of the causal effect estimate. This iterative updating process adjusts the initial estimates towards the true causal effect, guided by the efficient influence function.
#
# TMLE offers several advantages for causal inference:
#
# 1. Double robust estimation: the estimator is consistent if either the outcome model or the treatment mechanism model is correctly specified (but not necessarily both);
# 2. Efficiency in the presence of time-varying confounding;
# 3. Ability to handle complex longitudinal data structures and time-varying treatments;
# 4. Flexibility in specifying dynamic treatment regimes;
# 5. Compatibility with machine learning methods for initial estimation steps;
# 6. Handling of missing data from attrition, loss-to-follow up using inverse-probability of censoring weighting.
#
# We use cross-validation to avoid overfitting, following pre-stated protocols [@bulbulia2024PRACTICAL]. The integration of TMLE and machine learning reduces dependence on restrictive modeling assumptions and introduces an additional layer of robustness.
#
# We perform estimation using the `lmtp` package [@williams2021]. We use the `superlearner` library for semi-parametric estimation with the predefined libraries `SL.ranger`, `SL.glmnet`, and `SL.xgboost` [@polley2023; @xgboost2023; @Ranger2017]. For further details on targeted learning using the `lmtp` package, see [@hoffman2022; @hoffman2023; @díaz2021]. Graphs, tables, and output reports are created using the `margot` package [@margot2024].
#     ",
#     sdr = "
# #### Sequentially Doubly Robust (SDR) Estimator
#
# We employ a semi-parametric estimator known as Sequentially Doubly Robust (SDR) estimation, which can estimate the causal effect of modified treatment policies on outcomes over time [@díaz2021]. This estimator belongs to the broader class of doubly-robust targeted learning frameworks developed by [@vanderlaan2011; @vanderlaan2018].
#
# SDR operates through the following process:
#
# 1. **Initial Modeling:** It employs machine learning algorithms to flexibly model the relationship between treatments, covariates, and outcomes at each time point. This flexibility allows SDR to account for complex, high-dimensional covariate spaces without imposing restrictive parametric modeling assumptions.
#
# 2. **Sequential Estimation:** SDR applies a sequential modelling approach, estimating the treatment effect by working backwards in time. At each time point, SDR combines the outcome regression and the propensity score to construct an unbiased estimating equation. This process naturally incorporates the time-dependent nature of the data and interventions.
#
# SDR offers several advantages for causal inference:
#
# 1. Sequential double robustness: The estimator is consistent if, for each time point, either the outcome model or the treatment mechanism model is correctly specified (but not necessarily both);
# 2. Efficiency in the presence of time-varying confounding;
# 3. Ability to handle complex longitudinal data structures and time-varying treatments;
# 4. Flexibility in specifying dynamic treatment regimes;
# 5. Compatibility with machine learning methods for initial estimation steps;
# 6. Handling of missing data from attrition, loss-to-follow up using inverse-probability of censoring weighting.
#
# SDR uses cross-validation to avoid over-fitting and ensure that the estimator performs well in finite samples. The combination of SDR and machine learning technologies reduces the dependence on restrictive modeling assumptions and introduces an additional layer of robustness.
#
# Estimation is performed using the `lmtp` package [@williams2021; @díaz2021; @hoffman2023]. For further details on the theoretical properties and practical applications of SDR, see [@hoffman2022; @hoffman2023; @díaz2021]. We employ a semi-parametric estimator known as Sequentially Doubly Robust (SDR) estimation, which can estimate the causal effect of modified treatment policies on outcomes over time [@díaz2021]. This estimator belongs to the broader class of doubly-robust targeted learning frameworks developed by [@vanderlaan2011; @vanderlaan2018].
#
# SDR operates through the following process:
#
# 1. **Initial Modeling:** It employs machine learning algorithms to flexibly model the relationship between treatments, covariates, and outcomes at each time point. This flexibility allows SDR to account for complex, high-dimensional covariate spaces without imposing restrictive parametric modeling assumptions.
#
# 2. **Sequential Estimation:** SDR applies a sequential regression approach, estimating the treatment effect by working backwards in time. At each time point, it combines the outcome regression and the propensity score to construct an unbiased estimating equation. This process naturally incorporates the time-dependent nature of the data and interventions.
#
# SDR offers several advantages for causal inference:
# - Sequential double robustness: The estimator is consistent if, for each time point, either the outcome model or the treatment mechanism model is correctly specified (but not necessarily both)
# - Efficiency in the presence of time-varying confounding
# - Ability to handle complex longitudinal data structures and time-varying treatments
# - Flexibility in specifying dynamic treatment regimes
# - Compatibility with machine learning methods for initial estimation steps
#
# SDR uses cross-validation to avoid over-fitting and ensure that the estimator performs well in finite samples. The combination of SDR and machine learning technologies reduces the dependence on restrictive modeling assumptions and introduces an additional layer of robustness.
#
# Estimation is performed using the `lmtp` package [@williams2021; @díaz2021; @hoffman2023]. For further details on the theoretical properties and practical applications of SDR, see [@hoffman2022; @hoffman2023; @díaz2021]. Graphs, tables, and output reports are created using the `margot` package [@margot2024].
#     ",
#     grf = "
# #### Generalized Random Forests (GRF)
#
# In this study, we employ Generalized Random Forests (GRF) to estimate causal effects, using the grf package [@grf2024]. GRF extends the random forest algorithm to estimate heterogeneous treatment effects, providing a non-parametric approach to causal inference. This method allows us to estimate conditional average treatment effects (CATE) across different subgroups or individual characteristics.
#
# GRF offers several advantages for causal inference:
#
# 1. Complex, non-linear relationships: GRF can model intricate interactions between covariates and treatment effects without requiring pre-specification.
# 2. Heterogeneous treatment effects: The method allows exploration of how treatment effects vary across different subgroups or individual characteristics.
# 3. Variable importance measures: GRF provides insights into which variables most influence treatment effects.
# 4. Flexibility with outcome types: It can handle continuous, binary, and time-to-event outcomes without assuming specific data distributions.
# 5. Double robustness: GRF estimates remain consistent if either the outcome model or the propensity score model is correctly specified (but not necessarily both).
# 6. Out-of-bag predictions: By using out-of-bag samples for fitting, GRF helps prevent overfitting and provides honest treatment effect estimates.
#
# The GRF method combines machine learning flexibility with statistical inference rigor, making it particularly useful in complex settings where treatment effects may vary across subpopulations or when relationships between covariates and outcomes are expected to be non-linear.
#
# In our analysis:
#
# We use the `maq `package [@maq_package_2024] to assess treatment heterogeneity.
# We evaluate optimal policies using the `policytree` package [@policytree_package_2024; @athey_2021_policy_tree_econometrica].
# We visualize policy predictions on held-out data using the `margot` package [@margot2024].
#
# By employing GRF, we can estimate both average treatment effects and explore how these effects differ across various subgroups or individual characteristics, providing clearer insight into causal relationships in the target population.
#     "
#   )
#
#   selected_estimators <- estimator_texts[unlist(estimators)]
#
#   markdown_text <- paste0("
# ### Statistical Estimator
#   ",
#                           paste(unlist(selected_estimators), collapse = "\n\n")
#   )
#
#   return(markdown_text)
# }
