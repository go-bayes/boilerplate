# build the lmtp text-database entry set shipped at inst/extdata/lmtp_boilerplate.json
#
# purpose: the margot.lmtp reporting family hardcodes no report prose. it resolves
# narration from this database by dot-separated path, for example
# "methods.lmtp.density_ratio_report.upper_tail", and substitutes realised values
# through the package's {{variable}} syntax.
#
# provenance: every non-TODO string below is taken verbatim from the approved
# registration at
# arc/studies/2026/jb-lmtp-workflow/registration/registration-report.qmd
# (NZAVS-LMTP-v1). template variables replace registered or study-specific values
# only; no sentence here was composed for this database. entries marked
# "TODO(author)" have no source sentence in the registration and await author
# wording.
#
# to rebuild:  Rscript data-raw/lmtp-boilerplate-entries.R
# to consume:  boilerplate_import(
#                data_path = system.file("extdata", "lmtp_boilerplate.json",
#                                        package = "boilerplate"),
#                quiet = TRUE
#              )

# load the package under development, falling back to sourcing R/ when the
# full Imports set is not installed on the build machine
if (requireNamespace("boilerplate", quietly = TRUE)) {
  library(boilerplate)
} else {
  loaded <- FALSE
  if (requireNamespace("pkgload", quietly = TRUE)) {
    loaded <- tryCatch(
      {
        pkgload::load_all(".", quiet = TRUE)
        TRUE
      },
      error = function(e) FALSE
    )
  }
  if (!loaded) {
    library(cli)
    for (source_file in list.files("R", pattern = "\\.R$", full.names = TRUE)) {
      sys.source(source_file, envir = globalenv())
    }
  }
}

registration_path <- file.path(
  "~", "GIT", "arc", "studies", "2026", "jb-lmtp-workflow",
  "registration", "registration-report.qmd"
)

# a TODO marker names its variables without braces, so that apply_template_vars()
# neither substitutes nor warns on an entry that is still awaiting wording
todo <- function(what, variables) {
  paste0(
    "TODO(author): supply wording for ", what,
    ". Variables available: ", paste(variables, collapse = ", "), "."
  )
}

# entries in dot-path order; names are paths, values are the stored text
entries <- list(

  ## methods.lmtp.density_ratio_report ---------------------------------------

  "methods.lmtp.density_ratio_report.framing" = paste0(
    "Positivity requires that, for every history the registered policy reaches, the observed exposure process assigns positive conditional density or mass to the value the policy would assign. ",
    "We argue that assumption from the definition of the policy in Step 2. ",
    "We cannot establish it from the data. ",
    "Density ratios answer a related and different question: how far the policy distribution departs from the observed exposure process, and therefore how heavily the estimator must reweight the observed trajectories. ",
    "Díaz and colleagues make the distinction explicit in the applied analysis of their methods paper, where the maximum cumulative density ratio (node ratios multiplied across waves; the next subsections define both) reached 97.7. ",
    "Instability of the inverse-probability weights, they write, \"does not mean that there are positivity violations\", only that the weights are highly variable [@diaz2023lmtp, p. 855]. ",
    "We report the density ratios for that reason and no other."
  ),

  "methods.lmtp.density_ratio_report.no_consensus" = paste0(
    "The technical literature holds no consensus on quantitative positivity diagnostics for longitudinal modified treatment policies, and this registration does not pretend otherwise. ",
    "Petersen and colleagues, whose 2012 paper is the standard treatment of positivity diagnostics for marginal structural models, recommend prespecified selection criteria built on a parametric-bootstrap bias diagnostic that requires the outcome, and they close by stating that assessing positivity bias for longitudinal causal parameters remains an open research problem [@petersen2012positivity]. ",
    "Their diagnostic is therefore unavailable at an outcome-blind design stage. ",
    "Petersen and colleagues also state the asymmetry that governs every ratio summary: well-behaved weights are not sufficient in themselves to ensure the absence of positivity violations, because a history stratum in which the assigned value never occurs contributes no weight and raises no warning. ",
    "Díaz and colleagues supply no empirical cutpoint at all. ",
    "We cite each source for what it establishes and claim neither as authority for any choice made here."
  ),

  "methods.lmtp.density_ratio_report.two_parts" = paste0(
    "The design-stage ratio report has two parts, and the two parts do different jobs. ",
    "The conditional-support check bears on positivity. ",
    "The weight-concentration report bears on estimator behaviour and on how far the policy displaces the natural course; it bears on positivity in neither direction. ",
    "We keep the two parts separately labelled in every report and every record for that reason."
  ),

  "methods.lmtp.density_ratio_report.three_sections" = paste0(
    "The weight-concentration report itself has three sections (the upper tail, the lower tail, and the concentration-and-cap disclosures) because they raise different concerns: the upper tail concerns how heavily the estimator leans on a few trajectories, and the lower tail concerns how far the policy displaces the exposure histories the cohort produced."
  ),

  "methods.lmtp.density_ratio_report.weight_concentration" = paste0(
    "The second part of the design-stage ratio report is the weight-concentration report. ",
    "It gives the node-specific and cumulative density-ratio distributions, their upper quantiles and maximum, the share of the total weight carried by the largest 1%, 5%, and 10% of trajectories, the exact-zero counts classified by verified cause over the full eligible denominator, and the Kish effective sample size (defined below) of the analysis weight vector including zeros."
  ),

  "methods.lmtp.density_ratio_report.conditional_support.default" = paste0(
    "The first part of the design-stage ratio report is the conditional-support check. ",
    "For each policy node and each policy arm, we report whether the assigned value $d(a_t, h_t)$ falls inside the estimated conditional support of the exposure given the measured history, the share of person-nodes for which it does not, and the covariate strata in which those failures concentrate. ",
    "The conditional-support check bears on positivity."
  ),

  "methods.lmtp.density_ratio_report.conditional_support.realised" = todo(
    "the realised conditional-support check for one policy arm",
    c("arm_label", "node_label", "conditional_support_outside_share",
      "conditional_support_strata", "eligible_denominator")
  ),

  "methods.lmtp.density_ratio_report.upper_tail.default" = paste0(
    "The upper-tail report enters the identification review as context the investigators weigh alongside the conditional-support argument of Step 2. ",
    "It is never evidence for positivity and never evidence against it."
  ),

  "methods.lmtp.density_ratio_report.upper_tail.realised" = todo(
    "the realised upper-tail section for one policy arm",
    c("arm_label", "upper_tail_node_max", "upper_tail_cumulative_max",
      "upper_tail_cumulative_q99", "upper_tail_policy_mass_top_1",
      "upper_tail_policy_mass_top_5", "upper_tail_policy_mass_top_10",
      "upper_tail_denominator")
  ),

  "methods.lmtp.density_ratio_report.lower_tail.default" = paste0(
    "The lower tail enters a separate scientific-design judgement about whether the policy still asks a question worth asking of these data."
  ),

  "methods.lmtp.density_ratio_report.lower_tail.static_binary" = paste0(
    "A static binary contrast assigns one exposure state at every shifted wave. ",
    "Both assigned states are interventions requiring their own conditional-support argument. ",
    "This structure changes what the reports can say for the static binary class. ",
    "Every non-conforming trajectory contributes a cumulative product of exactly zero. ",
    "A count of small cumulative products is therefore, for this class, a count of non-conforming trajectories."
  ),

  "methods.lmtp.density_ratio_report.lower_tail.realised" = todo(
    "the realised lower-tail section for one policy arm",
    c("arm_label", "lower_tail_zero_share_total",
      "lower_tail_zero_share_not_at_risk", "lower_tail_zero_share_not_observed",
      "lower_tail_zero_share_nonconformance",
      "lower_tail_zero_share_policy_induced", "eligible_denominator")
  ),

  "methods.lmtp.density_ratio_report.concentration.default" = paste0(
    "The concentration-and-cap disclosures enter the design-stage record with no path into identification."
  ),

  "methods.lmtp.density_ratio_report.concentration.realised" = todo(
    "the realised concentration section for one policy arm",
    c("arm_label", "concentration_kish_ess", "concentration_kish_ess_fraction",
      "concentration_binding_node", "uncensored_count")
  ),

  ## methods.lmtp.kish_caveats ------------------------------------------------

  "methods.lmtp.kish_caveats" = paste0(
    "The Kish effective sample size needs its two limits stated wherever it appears. ",
    "For cumulative weights $w_i$, the Kish effective sample size (a survey-statistics measure of weight concentration: the number of equally weighted observations that would carry the same information) is $(\\sum_i w_i)^2/\\sum_i w_i^2$. ",
    "The formula is exact for a weighted mean and conservative for the sequentially doubly robust estimator, whose influence function includes outcome-regression terms that damp the estimate's sensitivity to the weights. ",
    "The formula also omits the baseline sampling weights that the target-standardised estimator uses. ",
    "We report the absolute cumulative effective sample size and its fraction of the uncensored count at every policy node, and we read the quantity at the binding node, which is ordinarily the last, because cumulative products only accumulate. ",
    "The quantity is reported and never applied as a criterion. ",
    "It carries no positivity, retention, or question-selection role."
  ),

  ## methods.lmtp.instrument_limits ------------------------------------------

  "methods.lmtp.instrument_limits.default" = paste0(
    "The instrument carries bounds of its own, and we state them because a reader who does not know them will misread the reports. ",
    "As of version {{lmtp_version}}, `lmtp` forms each node-specific ratio as $\\hat p / \\{1 - \\min(\\hat p, 0.999)\\}$, where $\\hat p$ is the fitted probability of the observed exposure-and-censoring value for that participant at that node. ",
    "No node-specific ratio can therefore exceed approximately 1000 whatever value `.trim` takes. ",
    "A mass of ratios at that value records saturation of the software bound rather than a measured magnitude. ",
    "Setting `.trim = 1` disables the pooled quantile cap and leaves this denominator bound in place; fitted probabilities are otherwise bounded only at machine tolerance in this version. ",
    "We therefore describe the design-stage fit as *quantile-untrimmed* and never as *uncapped*: the quantile cap is off, and the software's internal bounds remain live."
  ),

  "methods.lmtp.instrument_limits.denominator_bound" = paste0(
    "As of version {{lmtp_version}}, `lmtp` forms each node-specific ratio as $\\hat p / \\{1 - \\min(\\hat p, 0.999)\\}$, where $\\hat p$ is the fitted probability of the observed exposure-and-censoring value for that participant at that node. ",
    "No node-specific ratio can therefore exceed approximately 1000 whatever value `.trim` takes. ",
    "A mass of ratios at that value records saturation of the software bound rather than a measured magnitude."
  ),

  "methods.lmtp.instrument_limits.quantile_untrimmed" = paste0(
    "Setting `.trim = 1` disables the pooled quantile cap and leaves this denominator bound in place; fitted probabilities are otherwise bounded only at machine tolerance in this version. ",
    "We therefore describe the design-stage fit as *quantile-untrimmed* and never as *uncapped*: the quantile cap is off, and the software's internal bounds remain live."
  ),

  "methods.lmtp.instrument_limits.conformer_floor" = paste0(
    "For a policy declared to `lmtp` with `mtp = FALSE`, the package floors the fitted probability at 0.5 for participants who followed the assigned sequence. ",
    "Every conforming node ratio is therefore at least 1. ",
    "The cumulative product for this class is therefore either exactly zero or at least one, and the class has no continuous lower tail at all. ",
    "We instead report the distribution of the estimated assigned-state probabilities at every policy node together with the conformance counts, separately for each of the two registered states, because each state is its own intervention."
  ),

  ## methods.lmtp.cap_disclosures --------------------------------------------

  "methods.lmtp.cap_disclosures.default" = paste0(
    "The registered primary estimator keeps the `lmtp` package default `.trim = {{trim_setting}}`. ",
    "Some regularisation is prudent under measurement error, which inflates the estimated tails of a density-ratio distribution, and a cap prevents a few extreme trajectories from dominating the fit. ",
    "The setting is provisional. ",
    "A package-level audit of how the cap behaves on full-sample ratio matrices, run within the reference implementation, may change the registered default for later studies. ",
    "A study may register a departure (`.trim = 1` or another prespecified cap) in the sealed estimator contract before estimation."
  ),

  "methods.lmtp.cap_disclosures.mechanics" = paste0(
    "The cap replaces every estimated density ratio above the 99.9th percentile of the pooled fitted ratio matrix with that percentile. ",
    "The pooled matrix contains an exact zero for every person-node (one participant at one policy node) that is censored, not at risk (for example after a competing event), or non-conforming under a static policy (Step 6 defines conformance). ",
    "Because the zeros occupy part of the pooled distribution, trimming the top 0.1% of all entries trims a larger share of the positive ones: with pooled exact-zero fraction $p_0$, the cap falls at the $\\left(1 - \\tfrac{0.001}{1-p_0}\\right)$ quantile of the positive ratios. ",
    "Its severity rises as conformance falls; one registered setting therefore regularises a long static policy more heavily than a short one. ",
    "For every fitted policy arm (each registered policy's own fitted ratio set) we therefore report the realised cutoff, the exact-zero fraction, the number and percentage of positive entries capped, and the equivalent quantile of the positive entries, so that regularisation summaries mean the same thing across every candidate question a study assesses. ",
    "A realised cutoff of zero invalidates the fit: the software raises an error rather than silently setting the whole ratio matrix to zero."
  ),

  "methods.lmtp.cap_disclosures.realised" = todo(
    "the realised cap disclosure for one policy arm",
    c("arm_label", "trim_setting", "cap_realised_cutoff",
      "cap_zero_fraction", "cap_capped_n", "cap_capped_percent",
      "cap_equivalent_quantile")
  ),

  ## methods.lmtp.expectations ------------------------------------------------

  "methods.lmtp.expectations.default" = paste0(
    "Before any question-specific density ratio is fitted, the investigators seal their quantitative expectations. ",
    "An expectation states what result the investigators anticipate and what a departure from it would prompt: retention with reasons, revision under the registered question-revision plan, or stopping. ",
    "The registration prints every sealed expectation beside its realised value. ",
    "A departure never withdraws the causal question automatically. ",
    "A departure obliges the investigators to record the departure, its magnitude, and their reasoning, and obliges the registration to report that record beside the expectation it departs from."
  ),

  "methods.lmtp.expectations.arm_level_default" = paste0(
    "House guidance (the workflow's own recommendations, as distinct from its registered requirements) recommends one expectation per policy arm as the default granularity. ",
    "The conditional-support argument of Step 2 is made per policy. ",
    "The arm is therefore the unit at which investigators already hold a reasoned view before seeing any ratios. ",
    "A report-level expectation is ordinarily too coarse, because a healthy aggregate can hide one troubled arm and a departure then points nowhere. ",
    "A node-level expectation is ordinarily too fine, because investigators rarely have grounds to predict wave-by-wave ratio behaviour, and an unmotivated node-level seal degenerates into a guess. ",
    "A wave with known disruption (a pandemic wave, a change of instrument) is the clean case for a motivated node-level expectation alongside the arm-level ones. ",
    "The default is guidance and never a rule. ",
    "Each study registers the granularity it can defend."
  ),

  "methods.lmtp.expectations.no_inferential_authority" = paste0(
    "An expectation is a prediction and carries no inferential authority. ",
    "It claims nothing about identification, and no expectation converts a density-ratio summary into an enforced consequence. ",
    "It gives a later reader a standard against which to check the recorded decision."
  ),

  "methods.lmtp.expectations.realised" = todo(
    "one sealed expectation printed beside its realised value",
    c("expectation_id", "metric_id", "arm_label", "node_label",
      "expectation_level", "expectation_statement", "realised_value",
      "departure_declared", "departure_response")
  ),

  ## methods.lmtp.workflow_limits and enforced_rule ---------------------------

  "methods.lmtp.workflow_limits" = paste0(
    "This workflow places every retention on the record, attributed and dated, and it reports every departure beside its expectation. ",
    "It does not mechanically prevent investigators from retaining a poorly supported causal question."
  ),

  "methods.lmtp.enforced_rule" = paste0(
    "One rule binds without exception. ",
    "Investigators who judge that a required identification assumption is indefensible must withdraw the causal question. ",
    "No override and no recorded rationale reverses that conclusion. ",
    "The rule is a matter of coherence rather than a threshold: investigators cannot retain a question they have themselves concluded is not identified."
  ),

  ## results.lmtp -------------------------------------------------------------

  "results.lmtp.computational_validity" = paste0(
    "The investigators review the registered question once the reports are computationally valid. ",
    "Computational validity is a precondition rather than a finding: the fitted ratios must verify as coming from the sealed fit, the fitted predictions must contain no sentinel values (software placeholder codes) and no missing values, every zero must be classified by cause, the denominators must be as registered, and the package versions, folds, and seed must match the sealed specification. ",
    "An invalid report sends the study back to review of the implementation and supports no question decision at all."
  ),

  "results.lmtp.question_decision_record" = paste0(
    "Every response is recorded before the freeze, together with the realised value of every sealed expectation, the departure from each, the named investigators, and the date. ",
    "Each rationale names the specific reported value it responds to, and that value must be recoverable from the sealed ratio fit."
  ),

  "results.lmtp.design_stage_record" = paste0(
    "We also report the complete design-stage record: every sealed expectation beside its realised value, every departure with its explanation, both parts of the ratio report for every candidate question assessed, the cap disclosures registered in Step 4, the recorded decision, and its verification."
  ),

  "results.lmtp.data_informed_selection" = paste0(
    "The registered target is data-informed, and we say so rather than implying otherwise. ",
    "We refine the question using exposure and censoring data alone: no outcome, no exposure–outcome association, and no estimate of any registered causal contrast informs the choice. ",
    "Outcome-blind refinement removes the classical worry that a result steers the question. ",
    "It does not make the registered target sample-independent. ",
    "A different draw of the same cohort could have led the investigators to register a different target. ",
    "Our frequentist statements therefore proceed under the frozen study-specific contract and hold conditional on the realised target."
  ),

  "results.lmtp.stability_audit" = paste0(
    "A stability audit accompanies the selection, because the fitted ratios that inform the choice also feed the estimator. ",
    "We refit the density ratios under small perturbations: alternative cross-fitting splits under registered seeds, and resamples of the analysis-ready frame. ",
    "We then confirm that the same target question would have been chosen. ",
    "The audit is reported with the registration whatever it shows. ",
    "An audit in which the selected target does not survive perturbation is itself a material finding about the study, and we report it as one."
  ),

  "results.lmtp.reproduction" = paste0(
    "Before confirmatory estimation, we rerun the same treatment and censoring procedure and recompute the same reports. ",
    "Reproduction of the frozen record is a reproducibility requirement rather than a second decision. ",
    "The confirmatory analysis cannot use a fresh report to reopen the recorded question decision. ",
    "A report that differs means that the registered procedure failed to reproduce, perhaps because of a documented software change, numerical variation, or an implementation fault. ",
    "We attribute and report the difference without reopening a design decision."
  )
)

# build the unified database through the package's own path operations
db <- list(methods = list(), results = list())
for (path in names(entries)) {
  db <- boilerplate_add_entry(db, path, entries[[path]], auto_sort = TRUE)
}

# write through the package writer, then move the unified file into inst/extdata
staging <- file.path(tempdir(), "lmtp-boilerplate-staging")
dir.create(staging, showWarnings = FALSE, recursive = TRUE)
boilerplate_save(
  db,
  data_path = staging,
  confirm = FALSE,
  create_dirs = TRUE,
  create_backup = FALSE,
  quiet = TRUE
)
target <- file.path("inst", "extdata", "lmtp_boilerplate.json")
invisible(file.copy(file.path(staging, "boilerplate_unified.json"), target, overwrite = TRUE))
cli::cli_alert_success("wrote {target} with {length(entries)} entries")

# verification: every sentence that carries neither a template variable nor a
# TODO marker must appear verbatim in the approved registration
if (file.exists(path.expand(registration_path))) {
  source_text <- paste(
    readLines(path.expand(registration_path), warn = FALSE),
    collapse = "\n"
  )
  unverified <- character(0)
  for (path in names(entries)) {
    if (grepl("TODO(author)", entries[[path]], fixed = TRUE)) next
    sentences <- unlist(strsplit(entries[[path]], "(?<=\\.) (?=[A-Z])", perl = TRUE))
    for (sentence in sentences) {
      if (grepl("{{", sentence, fixed = TRUE)) next
      if (!grepl(trimws(sentence), source_text, fixed = TRUE)) {
        unverified <- c(unverified, paste0(path, ": ", substr(sentence, 1, 60)))
      }
    }
  }
  if (length(unverified) > 0) {
    cli::cli_alert_danger("sentences not found verbatim in the registration:")
    cli::cli_ul(unverified)
  } else {
    cli::cli_alert_success("every non-templated sentence verified against the registration")
  }
} else {
  cli::cli_alert_warning("registration not found at {registration_path}; skipped verification")
}
