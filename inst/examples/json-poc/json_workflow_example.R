# JSON Workflow Example for Boilerplate Package
# This demonstrates how JSON support could work with existing functions

library(boilerplate)
library(jsonlite)  # Required for JSON support

# 1. Import from JSON files
# -------------------------
# Import all categories (auto-detects JSON files)
unified_db <- boilerplate_import(
  data_path = "inst/examples/json-poc"
)

# View the structure
str(unified_db$measures$demographics)

# 2. Batch Edit Operations on JSON Data
# -------------------------------------
# Update references for all anxiety measures
updated_db <- boilerplate_batch_edit(
  db = unified_db,  # or can pass file path directly
  field = "reference",
  new_value = "Updated 2024",
  target_entries = "anxiety*",
  category = "measures",
  preview = FALSE,
  confirm = FALSE,
  quiet = FALSE
)

# Batch clean - remove special characters from descriptions
cleaned_db <- boilerplate_batch_clean(
  db = updated_db,
  field = "description",
  remove_chars = c("@", "#"),
  category = "methods",
  confirm = FALSE
)

# 3. Standardise Measures for JSON
# --------------------------------
# Extract measures and standardise
measures <- boilerplate_measures(unified_db)

standardised_measures <- boilerplate_standardise_measures(
  db = measures,
  json_compatible = TRUE,
  quiet = FALSE
)

# 4. Generate Text with JSON Database
# -----------------------------------
# Generate methods text with variable substitution
methods_text <- boilerplate_generate_text(
  db = unified_db,
  category = "methods",
  sections = c("sample.default", "statistical.longitudinal.lmtp"),
  global_vars = list(
    n_total = 500,
    location = "online survey platforms",
    start_date = "January 2023",
    end_date = "December 2023",
    shift_type = "hypothetical",
    lmtp_version = "1.3.2"
  ),
  quiet = FALSE
)

cat(methods_text)

# 5. Save to Both JSON and RDS
# ----------------------------
# Save the updated database in both formats
boilerplate_save(
  db = unified_db,
  data_path = "output",
  format = "both",  # Creates both .json and .rds files
  confirm = FALSE,
  quiet = FALSE,
  pretty = TRUE
)

# 6. Convert Existing RDS to JSON
# -------------------------------
# Convert all RDS files in a directory to JSON
boilerplate_rds_to_json(
  input_path = "boilerplate/data",
  output_path = "boilerplate/data/json",
  pretty = TRUE,
  quiet = FALSE
)

# 7. Working with Complex Nested Measures
# ---------------------------------------
# Create a complex measure structure
complex_measure <- list(
  name = "complex_scale",
  description = "A complex psychological scale",
  type = "ordinal",
  items = 20,
  subscales = list(
    anxiety = list(
      items = c(1, 5, 9, 13, 17),
      description = "Anxiety subscale"
    ),
    depression = list(
      items = c(2, 6, 10, 14, 18),
      description = "Depression subscale"
    ),
    stress = list(
      items = c(3, 7, 11, 15, 19),
      description = "Stress subscale"
    )
  ),
  scoring = list(
    type = "sum",
    reverse_items = c(4, 8, 12, 16, 20),
    interpretation = list(
      low = c(0, 20),
      moderate = c(21, 40),
      high = c(41, 60)
    )
  ),
  cutoffs = list(
    clinical = 35,
    severe = 50
  ),
  reference = "Smith et al. 2023",
  keywords = c("mental health", "psychometric", "validated")
)

# Add to measures database
unified_db$measures$psychological$complex_scale <- complex_measure

# Save as JSON - maintains full structure
write_json(
  unified_db$measures,
  "complex_measures.json",
  pretty = TRUE,
  auto_unbox = TRUE
)

# 8. Advantages of JSON Format
# ---------------------------

# A. Easy to edit in any text editor
# B. Version control friendly - see actual changes in git
# C. Can be validated with JSON schema
# D. Interoperable with other tools (Python, R, JavaScript)
# E. Human-readable structure

# Example: Create a JSON schema for measures
measures_schema <- list(
  `$schema` = "http://json-schema.org/draft-07/schema#",
  type = "object",
  properties = list(
    name = list(type = "string", description = "Measure identifier"),
    description = list(type = "string", description = "Measure description"),
    type = list(
      type = "string",
      enum = c("continuous", "categorical", "ordinal", "binary")
    ),
    reference = list(type = "string"),
    keywords = list(
      type = "array",
      items = list(type = "string")
    ),
    values = list(
      type = "array",
      items = list(type = c("number", "string"))
    )
  ),
  required = c("name", "description", "type")
)

# Save schema
write_json(measures_schema, "measures_schema.json", pretty = TRUE, auto_unbox = TRUE)

# 9. Migration Strategy
# --------------------

# Step 1: Add JSON support alongside RDS (backward compatible)
# Step 2: Provide conversion utilities
# Step 3: Update documentation with JSON examples
# Step 4: Gradually migrate internal data to JSON
# Step 5: Make JSON the default format in next major version

# The package could support both formats indefinitely, letting users choose
# based on their needs:
# - JSON for collaboration, editing, version control
# - RDS for performance, R-specific features, backward compatibility