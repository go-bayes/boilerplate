# Migration Script for go-bayes Lab Boilerplate Database
# This script migrates your lab's existing boilerplate_data to a unified JSON format
# and demonstrates best practices for collaborative research teams

library(boilerplate)
library(jsonlite)
library(cli)

# Configuration for your lab
LAB_NAME <- "go-bayes"
GITHUB_DATA_URL <- "https://github.com/go-bayes/templates/raw/main/boilerplate_data/"
LOCAL_OUTPUT_PATH <- "~/Documents/go-bayes-boilerplate-json"  # Adjust as needed
CREATE_BACKUP <- TRUE

# Step 1: Download and Analyze Current RDS Files
# ----------------------------------------------
cli_h1("Downloading go-bayes Lab Database")

# Create temporary directory for downloads
temp_dir <- tempdir()
rds_dir <- file.path(temp_dir, "boilerplate_rds")
dir.create(rds_dir, recursive = TRUE, showWarnings = FALSE)

# List of expected RDS files
rds_files <- c(
  "appendix_db.rds",
  "discussion_db.rds",
  "measures_db.rds",
  "methods_db.rds",
  "results_db.rds",
  "template_db.rds"
)

# Download each file
downloaded_files <- list()
for (file in rds_files) {
  url <- paste0(GITHUB_DATA_URL, file)
  dest <- file.path(rds_dir, file)

  tryCatch({
    cli_alert_info("Downloading {file}")
    download.file(url, dest, mode = "wb", quiet = TRUE)
    downloaded_files[[file]] <- dest
    cli_alert_success("Downloaded {file}")
  }, error = function(e) {
    cli_alert_warning("Could not download {file}: {e$message}")
  })
}

# Step 2: Load and Convert to Unified Structure
# ---------------------------------------------
cli_h1("Converting to Unified JSON Structure")

# Initialise unified database with metadata
unified_db <- list(
  `_meta` = list(
    version = "1.0.0",
    lab = LAB_NAME,
    created = Sys.time(),
    description = "Unified boilerplate database for go-bayes research lab",
    schema_version = "1.0",
    contributors = list(
      list(name = "Lab Administrator", role = "maintainer")
    )
  )
)

# Process each downloaded file
for (file_name in names(downloaded_files)) {
  file_path <- downloaded_files[[file_name]]
  category <- gsub("_db\\.rds$", "", file_name)

  cli_alert_info("Processing {category}")

  tryCatch({
    # Read RDS file
    db_content <- readRDS(file_path)

    # Handle wrapper structure if present
    if (paste0(category, "_db") %in% names(db_content)) {
      content <- db_content[[paste0(category, "_db")]]
    } else {
      content <- db_content
    }

    # Clean and enhance content
    content <- enhance_content_for_json(content, category)

    # Add to unified structure
    unified_db[[category]] <- content

    # Report statistics
    entry_count <- count_entries(content)
    cli_alert_success("{category}: {entry_count} entries processed")

  }, error = function(e) {
    cli_alert_danger("Failed to process {category}: {e$message}")
  })
}

# Step 3: Create Output Directory Structure
# ----------------------------------------
cli_h1("Creating Output Directory Structure")

# Create main directories
output_dirs <- list(
  main = LOCAL_OUTPUT_PATH,
  data = file.path(LOCAL_OUTPUT_PATH, "data"),
  archive = file.path(LOCAL_OUTPUT_PATH, "data", "archive"),
  schemas = file.path(LOCAL_OUTPUT_PATH, "schemas"),
  docs = file.path(LOCAL_OUTPUT_PATH, "docs"),
  web = file.path(LOCAL_OUTPUT_PATH, "web-interface")
)

for (dir_name in names(output_dirs)) {
  dir.create(output_dirs[[dir_name]], recursive = TRUE, showWarnings = FALSE)
  cli_alert_success("Created {dir_name} directory")
}

# Step 4: Save Unified JSON Database
# ----------------------------------
cli_h1("Saving Unified JSON Database")

# Main unified database
unified_path <- file.path(output_dirs$data, "boilerplate_unified.json")

# Pretty print with proper formatting
json_content <- toJSON(
  unified_db,
  pretty = TRUE,
  auto_unbox = TRUE,
  null = "null",
  na = "null"
)

writeLines(json_content, unified_path)
cli_alert_success("Created unified database: boilerplate_unified.json")

# Create timestamped backup
if (CREATE_BACKUP) {
  backup_name <- sprintf(
    "boilerplate_unified_%s.json",
    format(Sys.time(), "%Y%m%d_%H%M%S")
  )
  backup_path <- file.path(output_dirs$archive, backup_name)
  writeLines(json_content, backup_path)
  cli_alert_success("Created backup: {backup_name}")
}

# Step 5: Generate Schema Files
# -----------------------------
cli_h1("Generating JSON Schemas")

# Unified schema
unified_schema <- list(
  `$schema` = "http://json-schema.org/draft-07/schema#",
  title = "Boilerplate Unified Database Schema",
  type = "object",
  required = c("_meta", "methods", "measures"),
  properties = list(
    `_meta` = list(
      type = "object",
      properties = list(
        version = list(type = "string"),
        lab = list(type = "string"),
        created = list(type = "string"),
        schema_version = list(type = "string"),
        contributors = list(
          type = "array",
          items = list(
            type = "object",
            properties = list(
              name = list(type = "string"),
              role = list(type = "string")
            )
          )
        )
      )
    ),
    methods = list(
      type = "object",
      additionalProperties = list(
        type = "object",
        properties = list(
          text = list(type = "string"),
          description = list(type = "string"),
          keywords = list(type = "array", items = list(type = "string")),
          variables = list(type = "array", items = list(type = "string")),
          references = list(type = "array", items = list(type = "string"))
        )
      )
    ),
    measures = list(
      type = "object",
      additionalProperties = list(
        type = "object",
        properties = list(
          name = list(type = "string"),
          description = list(type = "string"),
          type = list(type = "string", enum = c("continuous", "categorical", "ordinal", "binary")),
          values = list(type = "array"),
          keywords = list(type = "array", items = list(type = "string"))
        )
      )
    )
  )
)

schema_path <- file.path(output_dirs$schemas, "unified_schema.json")
writeLines(toJSON(unified_schema, pretty = TRUE, auto_unbox = TRUE), schema_path)
cli_alert_success("Created unified schema")

# Step 6: Create Enhanced Web Interface
# ------------------------------------
cli_h1("Creating Web Interface")

# Copy and enhance the web editor
web_interface_content <- '<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>go-bayes Boilerplate Database Editor</title>
    <style>
        :root {
            --primary: #2563eb;
            --primary-dark: #1d4ed8;
            --danger: #dc2626;
            --success: #16a34a;
            --gray-100: #f3f4f6;
            --gray-200: #e5e7eb;
            --gray-700: #374151;
            --shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1);
        }

        * { box-sizing: border-box; }

        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            margin: 0;
            padding: 0;
            background: var(--gray-100);
            color: var(--gray-700);
        }

        .header {
            background: white;
            border-bottom: 1px solid var(--gray-200);
            padding: 1rem 2rem;
            box-shadow: var(--shadow);
        }

        .header h1 {
            margin: 0;
            font-size: 1.5rem;
            color: var(--primary);
        }

        .container {
            display: grid;
            grid-template-columns: 350px 1fr;
            gap: 2rem;
            max-width: 1400px;
            margin: 2rem auto;
            padding: 0 2rem;
        }

        .card {
            background: white;
            border-radius: 8px;
            box-shadow: var(--shadow);
            padding: 1.5rem;
        }

        .tabs {
            display: flex;
            gap: 1rem;
            margin-bottom: 1.5rem;
            border-bottom: 1px solid var(--gray-200);
            padding-bottom: 0.5rem;
        }

        .tab {
            padding: 0.5rem 1rem;
            border: none;
            background: none;
            cursor: pointer;
            font-size: 1rem;
            color: var(--gray-700);
            border-bottom: 2px solid transparent;
            transition: all 0.2s;
        }

        .tab:hover {
            color: var(--primary);
        }

        .tab.active {
            color: var(--primary);
            border-bottom-color: var(--primary);
        }

        .search-box {
            width: 100%;
            padding: 0.75rem;
            border: 1px solid var(--gray-200);
            border-radius: 6px;
            font-size: 1rem;
            margin-bottom: 1rem;
        }

        .tree-view {
            max-height: 600px;
            overflow-y: auto;
        }

        .tree-item {
            padding: 0.5rem;
            cursor: pointer;
            border-radius: 4px;
            margin-bottom: 0.25rem;
            transition: all 0.2s;
        }

        .tree-item:hover {
            background: var(--gray-100);
        }

        .tree-item.selected {
            background: var(--primary);
            color: white;
        }

        .tree-category {
            font-weight: 600;
            color: var(--primary);
            margin-top: 1rem;
            margin-bottom: 0.5rem;
        }

        .form-group {
            margin-bottom: 1.25rem;
        }

        .form-label {
            display: block;
            font-weight: 500;
            margin-bottom: 0.5rem;
            color: var(--gray-700);
        }

        .form-input, .form-select, .form-textarea {
            width: 100%;
            padding: 0.75rem;
            border: 1px solid var(--gray-200);
            border-radius: 6px;
            font-size: 1rem;
            transition: border-color 0.2s;
        }

        .form-input:focus, .form-select:focus, .form-textarea:focus {
            outline: none;
            border-color: var(--primary);
        }

        .form-textarea {
            resize: vertical;
            min-height: 100px;
        }

        .btn {
            padding: 0.75rem 1.5rem;
            border: none;
            border-radius: 6px;
            font-size: 1rem;
            cursor: pointer;
            transition: all 0.2s;
            font-weight: 500;
        }

        .btn-primary {
            background: var(--primary);
            color: white;
        }

        .btn-primary:hover {
            background: var(--primary-dark);
        }

        .btn-danger {
            background: var(--danger);
            color: white;
        }

        .btn-secondary {
            background: var(--gray-200);
            color: var(--gray-700);
        }

        .actions {
            display: flex;
            gap: 1rem;
            margin-top: 2rem;
            padding-top: 2rem;
            border-top: 1px solid var(--gray-200);
        }

        .json-output {
            background: #1e293b;
            color: #e2e8f0;
            padding: 1rem;
            border-radius: 6px;
            font-family: "Monaco", "Consolas", monospace;
            font-size: 0.875rem;
            max-height: 300px;
            overflow-y: auto;
            white-space: pre;
        }

        .status-message {
            padding: 0.75rem;
            border-radius: 6px;
            margin-bottom: 1rem;
            display: none;
        }

        .status-success {
            background: #d1fae5;
            color: #065f46;
        }

        .status-error {
            background: #fee2e2;
            color: #991b1b;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>go-bayes Boilerplate Database Editor</h1>
        <p style="margin: 0.5rem 0 0 0; color: #6b7280;">
            Manage your lab\'s boilerplate text and measures in a unified database
        </p>
    </div>

    <div class="container">
        <div class="card">
            <div class="tabs">
                <button class="tab active" onclick="switchCategory(\'methods\')">Methods</button>
                <button class="tab" onclick="switchCategory(\'measures\')">Measures</button>
                <button class="tab" onclick="switchCategory(\'results\')">Results</button>
                <button class="tab" onclick="switchCategory(\'discussion\')">Discussion</button>
            </div>

            <input type="text" class="search-box" id="searchBox"
                   placeholder="Search entries...">

            <div class="tree-view" id="treeView"></div>

            <button class="btn btn-primary" style="width: 100%; margin-top: 1rem;"
                    onclick="addNewEntry()">
                + Add New Entry
            </button>
        </div>

        <div class="card">
            <div id="statusMessage" class="status-message"></div>

            <h2 id="editorTitle">Select an entry to edit</h2>

            <form id="editorForm" style="display: none;">
                <div id="formFields"></div>

                <div class="actions">
                    <button type="submit" class="btn btn-primary">Save Changes</button>
                    <button type="button" class="btn btn-secondary" onclick="cancelEdit()">
                        Cancel
                    </button>
                    <button type="button" class="btn btn-danger" onclick="deleteEntry()">
                        Delete
                    </button>
                </div>
            </form>

            <div style="margin-top: 2rem;">
                <h3>Database Preview</h3>
                <div class="json-output" id="jsonOutput"></div>
                <div style="margin-top: 1rem; display: flex; gap: 1rem;">
                    <button class="btn btn-primary" onclick="downloadDatabase()">
                        Download Database
                    </button>
                    <button class="btn btn-secondary" onclick="loadDatabase()">
                        Load Database
                    </button>
                </div>
            </div>
        </div>
    </div>

    <script>
        // Initialise with empty database structure
        let database = {
            "_meta": {
                "version": "1.0.0",
                "lab": "go-bayes",
                "modified": new Date().toISOString()
            },
            "methods": {},
            "measures": {},
            "results": {},
            "discussion": {}
        };

        let currentCategory = "methods";
        let currentPath = null;

        // Try to load existing database from localStorage
        const savedDb = localStorage.getItem("gobayes_boilerplate_db");
        if (savedDb) {
            try {
                database = JSON.parse(savedDb);
            } catch (e) {
                console.error("Failed to load saved database:", e);
            }
        }

        // Field definitions for each category
        const categoryFields = {
            methods: [
                { name: "text", type: "textarea", label: "Method Text", required: true },
                { name: "description", type: "text", label: "Description" },
                { name: "keywords", type: "text", label: "Keywords (comma-separated)" },
                { name: "variables", type: "text", label: "Variables (comma-separated)" },
                { name: "references", type: "text", label: "References" }
            ],
            measures: [
                { name: "name", type: "text", label: "Measure Name", required: true },
                { name: "description", type: "textarea", label: "Description", required: true },
                { name: "type", type: "select", label: "Type", required: true,
                  options: ["continuous", "categorical", "ordinal", "binary"] },
                { name: "items", type: "number", label: "Number of Items" },
                { name: "reference", type: "text", label: "Reference/Citation" },
                { name: "keywords", type: "text", label: "Keywords (comma-separated)" }
            ],
            results: [
                { name: "text", type: "textarea", label: "Results Text", required: true },
                { name: "description", type: "text", label: "Description" },
                { name: "statistical_test", type: "text", label: "Statistical Test" },
                { name: "variables", type: "text", label: "Variables (comma-separated)" }
            ],
            discussion: [
                { name: "text", type: "textarea", label: "Discussion Text", required: true },
                { name: "description", type: "text", label: "Description" },
                { name: "keywords", type: "text", label: "Keywords (comma-separated)" }
            ]
        };

        function switchCategory(category) {
            currentCategory = category;
            document.querySelectorAll(".tab").forEach(tab => {
                tab.classList.toggle("active", tab.textContent.toLowerCase() === category);
            });
            renderTreeView();
        }

        function renderTreeView() {
            const container = document.getElementById("treeView");
            const searchTerm = document.getElementById("searchBox").value.toLowerCase();
            container.innerHTML = "";

            const categoryData = database[currentCategory] || {};
            const paths = [];

            // Extract all paths
            function extractPaths(obj, prefix = "") {
                Object.entries(obj).forEach(([key, value]) => {
                    const path = prefix ? `${prefix}.${key}` : key;
                    if (value && typeof value === "object" && !value.text && !value.name) {
                        extractPaths(value, path);
                    } else {
                        paths.push({ path, data: value });
                    }
                });
            }

            extractPaths(categoryData);

            // Group by top-level category
            const grouped = {};
            paths.forEach(({ path, data }) => {
                const parts = path.split(".");
                const topLevel = parts[0];
                if (!grouped[topLevel]) grouped[topLevel] = [];

                // Apply search filter
                if (!searchTerm ||
                    path.toLowerCase().includes(searchTerm) ||
                    JSON.stringify(data).toLowerCase().includes(searchTerm)) {
                    grouped[topLevel].push({ path, data });
                }
            });

            // Render grouped items
            Object.entries(grouped).forEach(([category, items]) => {
                if (items.length === 0) return;

                const categoryDiv = document.createElement("div");
                categoryDiv.className = "tree-category";
                categoryDiv.textContent = category;
                container.appendChild(categoryDiv);

                items.forEach(({ path, data }) => {
                    const item = document.createElement("div");
                    item.className = "tree-item";
                    if (path === currentPath) item.classList.add("selected");

                    const label = data.description || data.name || path.split(".").pop();
                    item.textContent = `${path} - ${label}`;
                    item.onclick = () => selectEntry(path);
                    container.appendChild(item);
                });
            });

            updateJsonOutput();
        }

        function selectEntry(path) {
            currentPath = path;
            const data = getDataAtPath(path);

            document.getElementById("editorTitle").textContent = `Editing: ${path}`;
            document.getElementById("editorForm").style.display = "block";

            // Generate form fields
            const formContainer = document.getElementById("formFields");
            formContainer.innerHTML = "";

            const fields = categoryFields[currentCategory];
            fields.forEach(field => {
                const group = document.createElement("div");
                group.className = "form-group";

                const label = document.createElement("label");
                label.className = "form-label";
                label.textContent = field.label;
                if (field.required) label.textContent += " *";
                group.appendChild(label);

                let input;
                if (field.type === "textarea") {
                    input = document.createElement("textarea");
                    input.className = "form-textarea";
                    input.rows = 4;
                } else if (field.type === "select") {
                    input = document.createElement("select");
                    input.className = "form-select";
                    field.options.forEach(opt => {
                        const option = document.createElement("option");
                        option.value = opt;
                        option.textContent = opt;
                        input.appendChild(option);
                    });
                } else {
                    input = document.createElement("input");
                    input.className = "form-input";
                    input.type = field.type || "text";
                }

                input.name = field.name;
                input.required = field.required || false;

                // Set value
                if (field.name === "keywords" || field.name === "variables") {
                    input.value = (data[field.name] || []).join(", ");
                } else {
                    input.value = data[field.name] || "";
                }

                group.appendChild(input);
                formContainer.appendChild(group);
            });

            // Also add path field
            const pathGroup = document.createElement("div");
            pathGroup.className = "form-group";
            pathGroup.innerHTML = `
                <label class="form-label">Path *</label>
                <input type="text" name="path" class="form-input" value="${path}" required>
            `;
            formContainer.insertBefore(pathGroup, formContainer.firstChild);

            renderTreeView();
        }

        function getDataAtPath(path) {
            const parts = path.split(".");
            let current = database[currentCategory];
            for (const part of parts) {
                current = current[part] || {};
            }
            return current;
        }

        function setDataAtPath(path, data) {
            const parts = path.split(".");
            let current = database[currentCategory];

            for (let i = 0; i < parts.length - 1; i++) {
                if (!current[parts[i]]) current[parts[i]] = {};
                current = current[parts[i]];
            }

            current[parts[parts.length - 1]] = data;
        }

        function deleteAtPath(path) {
            const parts = path.split(".");
            let current = database[currentCategory];

            for (let i = 0; i < parts.length - 1; i++) {
                current = current[parts[i]];
                if (!current) return;
            }

            delete current[parts[parts.length - 1]];
        }

        function addNewEntry() {
            const path = prompt(`Enter path for new ${currentCategory} entry (e.g., statistical.regression):`);
            if (!path) return;

            setDataAtPath(path, {
                text: "New entry",
                description: "New entry description",
                created: new Date().toISOString()
            });

            renderTreeView();
            selectEntry(path);
        }

        function deleteEntry() {
            if (!currentPath) return;
            if (!confirm(`Delete entry at path "${currentPath}"?`)) return;

            deleteAtPath(currentPath);
            currentPath = null;
            document.getElementById("editorForm").style.display = "none";
            document.getElementById("editorTitle").textContent = "Select an entry to edit";

            showStatus("Entry deleted", "success");
            saveToLocalStorage();
            renderTreeView();
        }

        function cancelEdit() {
            document.getElementById("editorForm").style.display = "none";
            document.getElementById("editorTitle").textContent = "Select an entry to edit";
            currentPath = null;
            renderTreeView();
        }

        function updateJsonOutput() {
            document.getElementById("jsonOutput").textContent =
                JSON.stringify(database, null, 2);
        }

        function showStatus(message, type) {
            const status = document.getElementById("statusMessage");
            status.textContent = message;
            status.className = `status-message status-${type}`;
            status.style.display = "block";

            setTimeout(() => {
                status.style.display = "none";
            }, 3000);
        }

        function saveToLocalStorage() {
            database._meta.modified = new Date().toISOString();
            localStorage.setItem("gobayes_boilerplate_db", JSON.stringify(database));
        }

        function downloadDatabase() {
            const dataStr = JSON.stringify(database, null, 2);
            const dataUri = "data:application/json;charset=utf-8," + encodeURIComponent(dataStr);

            const link = document.createElement("a");
            link.href = dataUri;
            link.download = `boilerplate_unified_${new Date().toISOString().split("T")[0]}.json`;
            link.click();

            showStatus("Database downloaded", "success");
        }

        function loadDatabase() {
            const input = document.createElement("input");
            input.type = "file";
            input.accept = ".json";

            input.onchange = (e) => {
                const file = e.target.files[0];
                if (!file) return;

                const reader = new FileReader();
                reader.onload = (e) => {
                    try {
                        database = JSON.parse(e.target.result);
                        saveToLocalStorage();
                        renderTreeView();
                        showStatus("Database loaded successfully", "success");
                    } catch (err) {
                        showStatus("Failed to load database: " + err.message, "error");
                    }
                };
                reader.readAsText(file);
            };

            input.click();
        }

        // Form submission
        document.getElementById("editorForm").onsubmit = (e) => {
            e.preventDefault();

            const formData = new FormData(e.target);
            const newPath = formData.get("path");
            const data = {};

            // Collect field values
            categoryFields[currentCategory].forEach(field => {
                const value = formData.get(field.name);
                if (field.name === "keywords" || field.name === "variables") {
                    data[field.name] = value ? value.split(",").map(s => s.trim()) : [];
                } else if (value) {
                    data[field.name] = field.type === "number" ? parseInt(value) : value;
                }
            });

            // Add metadata
            if (!data._meta) data._meta = {};
            data._meta.modified = new Date().toISOString();

            // Handle path change
            if (newPath !== currentPath) {
                deleteAtPath(currentPath);
            }

            setDataAtPath(newPath, data);
            currentPath = newPath;

            saveToLocalStorage();
            showStatus("Changes saved", "success");
            renderTreeView();
        };

        // Search functionality
        document.getElementById("searchBox").oninput = renderTreeView;

        // Initial render
        renderTreeView();
    </script>
</body>
</html>'

web_path <- file.path(output_dirs$web, "index.html")
writeLines(web_interface_content, web_path)
cli_alert_success("Created web interface")

# Step 7: Create Documentation
# ---------------------------
cli_h1("Creating Documentation")

# Main README
readme_content <- sprintf('# go-bayes Boilerplate Database

This repository contains the unified boilerplate database for the go-bayes research lab.

## 📁 Structure

```
%s/
├── data/
│   ├── boilerplate_unified.json    # Main unified database
│   └── archive/                    # Timestamped backups
├── schemas/
│   └── unified_schema.json         # JSON schema for validation
├── web-interface/
│   └── index.html                  # Web-based editor
└── docs/
    └── README.md                   # This file
```

## 🚀 Quick Start

### Using in R

```r
library(boilerplate)
library(jsonlite)

# Load the unified database
db <- read_json("data/boilerplate_unified.json")

# Access specific content
methods_text <- db$methods$statistical$regression$default

# Or use boilerplate functions (with JSON support)
boilerplate_import("data/")
```

### Using the Web Interface

1. Open `web-interface/index.html` in your browser
2. Browse and search entries by category
3. Edit entries with the form interface
4. Download updated database when done

### Using in Python

```python
import json

# Load database
with open("data/boilerplate_unified.json", "r") as f:
    db = json.load(f)

# Access content
regression_text = db["methods"]["statistical"]["regression"]["default"]
```

## 📝 Editing Guidelines

### Direct JSON Editing

1. Open `data/boilerplate_unified.json` in your text editor
2. Make changes following the existing structure
3. Validate against schema (optional but recommended)
4. Commit with descriptive message

### Path Conventions

Use dot notation for hierarchical organization:
- `methods.statistical.regression.lmtp`
- `measures.psychological.anxiety.gad7`
- `results.descriptive.table1`

### Adding New Content

```json
{
  "methods": {
    "your_category": {
      "your_method": {
        "text": "Your boilerplate text with {{variables}}",
        "description": "Brief description",
        "keywords": ["keyword1", "keyword2"],
        "variables": ["variable1", "variable2"]
      }
    }
  }
}
```

## 🔄 Version Control

The JSON format provides excellent git integration:
- Clear diffs showing exactly what changed
- Easy review in pull requests
- Automatic conflict resolution for most cases

## 👥 Contributing

1. Create a feature branch
2. Make your changes
3. Validate against schema
4. Submit pull request with clear description

## 📊 Database Statistics

Generated: %s

Categories:
%s

## 🛡️ Validation

To validate the database against the schema:

```r
library(jsonvalidate)

validator <- json_validator("schemas/unified_schema.json")
is_valid <- validator("data/boilerplate_unified.json")
```

## 🤝 Collaboration

This unified approach enables:
- Multiple researchers working on different sections
- Clear ownership and attribution
- Easy sharing between projects
- Standardised methodology across the lab

---

*Maintained by the go-bayes research team*',
  LAB_NAME,
  format(Sys.time(), "%Y-%m-%d"),
  paste(sprintf("- **%s**: %d entries",
                names(unified_db)[names(unified_db) != "_meta"],
                sapply(unified_db[names(unified_db) != "_meta"], length)),
        collapse = "\n")
)

readme_path <- file.path(output_dirs$docs, "README.md")
writeLines(readme_content, readme_path)
cli_alert_success("Created documentation")

# Step 8: Create R Helper Script
# ------------------------------
r_helper <- '# Helper functions for working with go-bayes boilerplate JSON database

# Load the unified database
load_gobayes_db <- function(path = "data/boilerplate_unified.json") {
  if (!file.exists(path)) {
    stop("Database file not found at: ", path)
  }

  db <- jsonlite::read_json(path)
  class(db) <- c("boilerplate_db", class(db))
  return(db)
}

# Save the database
save_gobayes_db <- function(db, path = "data/boilerplate_unified.json") {
  # Update metadata
  db$`_meta`$modified <- Sys.time()

  # Create backup
  if (file.exists(path)) {
    backup_dir <- file.path(dirname(path), "archive")
    dir.create(backup_dir, showWarnings = FALSE)
    backup_path <- file.path(backup_dir, sprintf("backup_%s.json",
                                                 format(Sys.time(), "%Y%m%d_%H%M%S")))
    file.copy(path, backup_path)
  }

  # Save
  jsonlite::write_json(db, path, pretty = TRUE, auto_unbox = TRUE)
  message("Database saved to: ", path)
}

# Add new entry
add_entry <- function(db, category, path, content) {
  parts <- strsplit(path, "\\\\.")[[1]]

  # Navigate to location
  current <- db[[category]]
  if (is.null(current)) db[[category]] <- list()

  # Create nested structure
  for (i in seq_along(parts)) {
    if (i == length(parts)) {
      db[[category]][[parts[i]]] <- content
    } else {
      if (is.null(db[[category]][[parts[i]]])) {
        db[[category]][[parts[i]]] <- list()
      }
    }
  }

  return(db)
}

# Example usage:
# db <- load_gobayes_db()
# db <- add_entry(db, "methods", "new.technique", list(text = "New method text"))
# save_gobayes_db(db)
'

helper_path <- file.path(output_dirs$main, "helper_functions.R")
writeLines(r_helper, helper_path)

# Step 9: Summary Report
# ---------------------
cli_h1("Migration Complete!")

cli_alert_success("Created unified JSON database at: {output_dirs$data}")
cli_alert_info("Web interface available at: {output_dirs$web}")
cli_alert_info("Documentation at: {output_dirs$docs}")

cat("\n")
cli_h2("Next Steps")
cli_bullets(c(
  "*" = "Open web-interface/index.html to edit your database",
  "*" = "Review the unified structure in data/boilerplate_unified.json",
  "*" = "Test loading in R with: db <- jsonlite::read_json('data/boilerplate_unified.json')",
  "*" = "Set up GitHub repository for version control",
  "*" = "Share with your lab members!"
))

# Cleanup
unlink(rds_dir, recursive = TRUE)

# Helper functions used in the script
enhance_content_for_json <- function(content, category) {
  # Add metadata to entries if missing
  if (is.list(content)) {
    for (name in names(content)) {
      if (is.list(content[[name]])) {
        # Add creation timestamp if missing
        if (is.null(content[[name]]$`_meta`)) {
          content[[name]]$`_meta` <- list(
            created = Sys.time(),
            category = category
          )
        }

        # Clean up any problematic characters in keys
        if (!is.null(names(content[[name]]))) {
          names(content[[name]]) <- gsub("[^a-zA-Z0-9_]", "_", names(content[[name]]))
        }
      }
    }
  }
  return(content)
}

count_entries <- function(x, depth = 0) {
  if (!is.list(x)) return(0)

  count <- 0
  for (item in x) {
    if (is.list(item)) {
      # Check if this is a terminal node (has text/description/name)
      if (any(c("text", "description", "name") %in% names(item))) {
        count <- count + 1
      } else {
        count <- count + count_entries(item, depth + 1)
      }
    }
  }
  return(count)
}
