## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  eval = FALSE
)

## ----load-package-------------------------------------------------------------
# library(boilerplate)

## ----list-versions------------------------------------------------------------
# # See all available database files
# files <- boilerplate_list_files()
# print(files)
# 
# # Check what versions exist for methods
# methods_files <- boilerplate_list_files(category = "methods")

## ----save-with-timestamp------------------------------------------------------
# # Load your database
# db <- boilerplate_import()
# 
# # Save with timestamp before major revision
# boilerplate_save(
#   db,
#   timestamp = TRUE,
#   quiet = FALSE
# )
# #> ✔ Saved unified database to: boilerplate_unified_20240115_143022.rds
# 
# # Later, import specific version
# # Note: Replace with your actual timestamped filename
# db_milestone <- boilerplate_import(
#   data_path = "path/to/your/boilerplate_unified_20240115_143022.rds"
# )

## ----backup-recovery----------------------------------------------------------
# # List available backups
# files <- boilerplate_list_files()
# # Look at files$backups for backup files
# 
# # View latest backup without restoring
# backup_db <- boilerplate_restore_backup(category = "methods")
# 
# # Restore latest backup as current version
# boilerplate_restore_backup(
#   category = "methods",
#   restore = TRUE,
#   confirm = TRUE
# )
# #> ✔ Restored backup from 20240110_120000
# 
# # Restore specific backup by timestamp
# boilerplate_restore_backup(
#   category = "methods",
#   backup_version = "20240110_120000",
#   restore = TRUE
# )

## ----workflow-example---------------------------------------------------------
# # 1. Check current versions
# files <- boilerplate_list_files("methods")
# 
# # 2. Save current work with timestamp
# methods_db <- boilerplate_import("methods")
# boilerplate_save(
#   methods_db,
#   category = "methods",
#   timestamp = TRUE
# )
# 
# # 3. Make changes
# methods_db$new_method <- "New methodology text"
# boilerplate_save(methods_db, category = "methods")
# 
# # 4. If changes were problematic, restore from backup
# boilerplate_restore_backup("methods", restore = TRUE)
# 
# # 5. Compare versions
# current <- boilerplate_import("methods")
# old_version <- boilerplate_import(
#   data_path = "path/to/your/methods_db_20240110_120000.rds"
# )

## ----git-integration----------------------------------------------------------
# # Save timestamped version for Git commit
# boilerplate_save(db, timestamp = TRUE)
# 
# # Add to Git
# # git add boilerplate/data/boilerplate_unified_*.rds
# # git commit -m "Snapshot before major refactoring"

## ----troubleshooting----------------------------------------------------------
# # List all files including backups
# all_files <- boilerplate_list_files()
# 
# # Check modification times
# # The most recently modified files appear first
# print(all_files$timestamped[1:5, c("file", "modified")])
# print(all_files$backups[1:5, c("file", "modified")])

## ----recovery-----------------------------------------------------------------
# # Try loading backup
# backup_db <- tryCatch(
#   boilerplate_restore_backup("methods"),
#   error = function(e) {
#     message("Backup corrupted, trying older version...")
#     # List files and manually load an older one
#     files <- boilerplate_list_files("methods")
#     if (nrow(files$timestamped) > 0) {
#       boilerplate_import(data_path = files$timestamped$path[2])
#     }
#   }
# )

