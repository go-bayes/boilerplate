# Batch Edit with JSON vs RDS: A Comparison

## Scenario: Update all psychology measure references to include year 2024

### With RDS (Current Approach)
```r
# 1. Load database
db <- boilerplate_import()

# 2. Perform batch edit
db <- boilerplate_batch_edit(
  db = db,
  field = "reference",
  new_value = function(old_val) {
    if (!grepl("2024", old_val)) {
      paste0(old_val, " (updated 2024)")
    } else {
      old_val
    }
  },
  target_entries = "psychological.*",
  category = "measures"
)

# 3. Save (creates new timestamped file)
boilerplate_save(db)
```

### With JSON (Proposed Approach)

#### Option 1: Using R Functions
```r
# Same as above, but with JSON support
db <- boilerplate_import_json(format = "json")
# ... same batch edit ...
boilerplate_save_json(db, format = "json")
```

#### Option 2: Direct JSON Editing
```bash
# Using jq (command-line JSON processor)
jq '.measures.psychological[][] | select(.reference != null) | .reference += " (updated 2024)"' measures_db.json > measures_db_updated.json

# Or using any text editor with find/replace
# Find: "reference": "([^"]+)"(?![^"]*2024)
# Replace: "reference": "$1 (updated 2024)"
```

#### Option 3: Using Other Languages
```python
# Python example
import json

with open('measures_db.json', 'r') as f:
    db = json.load(f)

# Update references
for category in db['measures']['psychological'].values():
    for measure in category.values():
        if isinstance(measure, dict) and 'reference' in measure:
            if '2024' not in measure['reference']:
                measure['reference'] += ' (updated 2024)'

with open('measures_db_updated.json', 'w') as f:
    json.dump(db, f, indent=2)
```

## Advantages of JSON for Batch Operations

### 1. **Git-Friendly Diffs**
```diff
{
  "gad7": {
    "name": "gad7",
    "description": "Generalized Anxiety Disorder 7-item scale",
-   "reference": "Spitzer et al. 2006",
+   "reference": "Spitzer et al. 2006 (updated 2024)",
    "keywords": ["anxiety", "GAD-7", "mental health"]
  }
}
```

### 2. **Validation Before Committing**
```json
// measures_schema.json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "definitions": {
    "measure": {
      "type": "object",
      "required": ["name", "description", "type"],
      "properties": {
        "reference": {
          "type": "string",
          "pattern": ".*\\d{4}.*"  // Must contain a year
        }
      }
    }
  }
}
```

### 3. **Bulk Operations Across Projects**
```bash
# Update all JSON files in multiple projects
find ~/research/*/boilerplate/data -name "*.json" -exec \
  jq '... update expression ...' {} \; -exec mv {} {}.bak \;
```

### 4. **Integration with CI/CD**
```yaml
# .github/workflows/validate-boilerplate.yml
name: Validate Boilerplate Data
on: [push, pull_request]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Validate JSON Schema
        run: |
          npm install -g ajv-cli
          ajv validate -s schema/measures_schema.json -d data/measures_db.json
      - name: Check References Updated
        run: |
          jq -e '.measures[][] | select(.reference != null) | select(.reference | test("2024"))' data/measures_db.json
```

## Standardise Measures with JSON

### Benefits for standardise_measures():

1. **Clear Structure Visibility**
```json
{
  "gad7": {
    "name": "gad7",
    "description": "...",
    "type": "ordinal",
    "items": 7,
    "values": [0, 1, 2, 3],
    "value_labels": ["Not at all", "Several days", "More than half the days", "Nearly every day"],
    "range": [0, 21],
    "cutoffs": {
      "mild": 5,
      "moderate": 10,
      "severe": 15
    },
    "_meta": {
      "last_updated": "2024-01-15",
      "validated": true,
      "usage_count": 145
    }
  }
}
```

2. **Easy Field Addition/Removal**
```r
# Standardise to ensure all measures have required fields
standardised <- boilerplate_standardise_measures_json(
  measures_db,
  add_missing_fields = TRUE,
  standard_fields = c(
    "name", "description", "type", "reference",
    "keywords", "waves", "scoring", "interpretation"
  ),
  preserve_meta = TRUE  # Keep _meta fields for internal use
)
```

3. **Batch Standardisation Across Files**
```r
# Standardise all measure files in a directory
json_files <- list.files("data/measures", pattern = "\\.json$", full.names = TRUE)

for (file in json_files) {
  db <- read_json(file)
  db_std <- boilerplate_standardise_measures_json(db)
  write_json(db_std, file, pretty = TRUE, auto_unbox = TRUE)
}
```

## Migration Path

### Phase 1: Dual Format Support (Current + JSON)
- Add JSON read/write capabilities
- Keep RDS as default
- Provide conversion utilities

### Phase 2: JSON as Primary Format
- Switch default to JSON
- RDS becomes legacy support
- Update all documentation

### Phase 3: Enhanced JSON Features
- JSON Schema validation
- Web-based editor
- API endpoints for database queries
- Integration with other tools

## Summary

JSON format offers:
- ✅ Human readability
- ✅ Git-friendly diffs
- ✅ Cross-language compatibility
- ✅ Easy validation
- ✅ Direct editing capability
- ✅ Better for collaboration
- ❌ Slightly larger file sizes
- ❌ No R-specific type preservation

For a package focused on "plain text simplicity," JSON aligns perfectly with the philosophy while enabling powerful new workflows.