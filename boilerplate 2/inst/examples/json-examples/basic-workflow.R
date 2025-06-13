# Basic Workflow with JSON Support
# This example shows the standard boilerplate workflow using JSON format

library(boilerplate)

# 1. Initialise a new project with JSON format
# ---------------------------------------------
# Create databases in JSON format (recommended for new projects)
boilerplate_init(
  data_path = "my_project/data",
  format = "json",  # Use JSON instead of RDS
  create_dirs = TRUE,
  confirm = FALSE
)

# 2. Import existing JSON database
# --------------------------------
# From local file
db <- boilerplate_import(
  data_path = "my_project/data"  # Auto-detects JSON format
)

# From GitHub repository
# db <- boilerplate_import(
#   data_path = "https://raw.githubusercontent.com/go-bayes/templates/main/boilerplate_data/"
#   # Auto-detects JSON format from file extensions
# )

# 3. View and manage content
# --------------------------
# List all methods
methods <- boilerplate_methods(db)
str(methods, max.level = 2)

# View specific method
methods$statistical$regression$lmtp

# Search for content
boilerplate_find_entries(db, pattern = "regression", category = "methods")

# 4. Generate text with variable substitution
# -------------------------------------------
text <- boilerplate_generate_text(
  db = db,
  category = "methods",
  sections = c("sample.default", "statistical.regression.lmtp"),
  replacements = list(
    n_total = 500,
    n_male = 250,
    n_female = 245,
    n_other = 5,
    location = "New Zealand",
    start_date = "March 2023",
    end_date = "December 2023",
    exposure = "social media use",
    outcome = "wellbeing",
    n_timepoints = 3,
    shift_type = "modified",
    lmtp_version = "1.3.2"
  )
)

cat(text)

# 5. Edit content
# ---------------
# Add new method
db$methods$statistical$machine_learning <- list(
  random_forest = list(
    text = "We used random forests with {{n_trees}} trees and {{max_depth}} maximum depth.",
    reference = "Breiman 2001",
    keywords = c("machine learning", "random forest", "ensemble")
  )
)

# Update existing content
db$methods$sample$default <- paste(
  db$methods$sample$default,
  "Participants provided informed consent before participation."
)

# 6. Batch operations
# -------------------
# Update all references to include year 2024
db <- boilerplate_batch_edit(
  db = db,  # Can also pass file path: "my_project/data/boilerplate_unified.json"
  field = "reference",
  new_value = "Updated 2024",  # Note: functions not supported, use string value
  target_entries = "*",
  category = "methods"
)

# 7. Validate before saving
# -------------------------
# Local validation
validation_results <- validate_json_database(db)

if (validation_results$valid) {
  cli::cli_alert_success("Database structure is valid")
} else {
  cli::cli_alert_warning("Validation issues found:")
  print(validation_results$issues)
}

# 8. Save in both formats
# -----------------------
# Save as JSON (primary format)
boilerplate_save(
  db = db,
  data_path = "my_project/data",
  format = "json",
  pretty = TRUE,
  confirm = FALSE
)

# Also save as RDS for backward compatibility
boilerplate_save(
  db = db,
  data_path = "my_project/data",
  format = "both",  # Creates both .json and .rds
  confirm = FALSE
)

# 9. Version control workflow
# ---------------------------
# The JSON format makes version control much clearer:
#
# git diff boilerplate_unified.json
#
# Shows exactly what text changed, making reviews easier

# 10. Quick edits without R
# -------------------------
# With JSON, you can make quick edits in any text editor:
# - Fix typos
# - Update references
# - Add new entries
# - Remove outdated content
#
# Then validate before committing:
# Rscript -e "boilerplate::validate_json_database('my_project/data/boilerplate_unified.json')"
