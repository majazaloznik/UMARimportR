#' Calculate vintage hashes
#'
#' Calculates the hash of all the datapoints in a particular vintage as well
#' as a partial hash, which excludes the last datapoint, allowing the hashes
#' of sucessive vintages to be easily compared.
#'
#' @param vintage_ids vector of vintage ids
#' @param con connection to database
#' @param schema schema name, defaults to "platform"
#'
#' @returns dataframe with vintage id and both hashes
#' @export
#'
calculate_vintage_hashes <- function(vintage_ids, con, schema = "platform") {
  # Get all data points for the specified vintages in one query
  query <- sprintf(
    "SELECT vintage_id, period_id, value
     FROM %s.data_points
     WHERE vintage_id IN (%s)
     ORDER BY vintage_id, period_id",
    schema, paste(vintage_ids, collapse = ",")
  )

  all_data <- DBI::dbGetQuery(con, query) |>
    dplyr::mutate(vintage_id = as.numeric(vintage_id))

  # Handle case where no data points exist for any vintage
  if(nrow(all_data) == 0) {
    return(data.frame(
      vintage_id = vintage_ids,
      full_hash = NA_character_,
      partial_hash = NA_character_,
      stringsAsFactors = FALSE
    ))
  }

  # Split by vintage_id
  data_by_vintage <- split(all_data, all_data$vintage_id)

  # Calculate hashes for each vintage
  result <- lapply(data_by_vintage, function(data) {
    # Special case for all NULL values
    if(all(is.na(data$value))) {
      # Use period_ids for hashing when all values are NULL
      full_hash <- digest::digest(data$period_id)

      partial_hash <- if(nrow(data) > 1) {
        digest::digest(data$period_id[-length(data$period_id)])
      } else {
        NA_character_
      }
    } else {
      # Normal case - hash the values
      full_hash <- digest::digest(data$value)

      partial_hash <- if(nrow(data) > 1) {
        digest::digest(data$value[-length(data$value)])
      } else {
        NA_character_
      }
    }

    data.frame(
      vintage_id = data$vintage_id[1],
      full_hash = full_hash,
      partial_hash = partial_hash,
      stringsAsFactors = FALSE
    )
  })

  # Combine results
  do.call(rbind, result)
}

#' Add vintage hashes to vintage table
#'
#' Queries all the (newly added) vintages which don't have hashes yet
#' and calculates their hashes. Before doing that it actually deletes
#' any vintages in the database that don't have any datapoints, cuz
#' they shouldn't be there in the first plase. but might sometimes
#' occur if the datapoint import was somehow corrupted and only the vintages
#' got inserted.
#'
#' @param con connection to database
#' @param schema schema name, defaults to "platform"
#'
#' @returns number of updated vintages
#' @export
add_missing_vintage_hashes <- function(con, schema = "platform") {
  # First delete any empty vintages in the database
  remove_empty_vintages(con, schema)

  # Get all vintage IDs without hashes
  query <- sprintf(
    "SELECT id FROM %s.vintage
     WHERE full_hash IS NULL OR partial_hash IS NULL
     ORDER BY id",
    schema
  )
  all_vintages <- DBI::dbGetQuery(con, query) |>
    dplyr::mutate(id = as.numeric(id))
  total_vintages <- nrow(all_vintages)

  # Early return if no vintages need updating
  if(total_vintages == 0) {
    cat("No vintages need hash updates.\n")
    return(invisible(NULL))
  }

  # Calculate hashes in batches to avoid memory issues
  batch_size <- 100

  for (i in seq(1, total_vintages, by = batch_size)) {
    end_idx <- min(i + batch_size - 1, total_vintages)
    batch_ids <- all_vintages$id[i:end_idx]

    # Get hashes for this batch
    hash_df <- calculate_vintage_hashes(batch_ids, con, schema)

    # Skip if no results returned (shouldn't happen, but just in case)
    if(nrow(hash_df) == 0) {
      cat(sprintf("Batch %d-%d: No data found for these vintages\n", i, end_idx))
      next
    }

    # Update database
    for (j in 1:nrow(hash_df)) {
      update_query <- sprintf(
        "UPDATE %s.vintage
         SET full_hash = '%s', partial_hash = %s
         WHERE id = %d",
        schema,
        hash_df$full_hash[j],
        ifelse(is.na(hash_df$partial_hash[j]), "NULL", paste0("'", hash_df$partial_hash[j], "'")),
        hash_df$vintage_id[j]
      )
      DBI::dbExecute(con, update_query)
    }

    cat(sprintf("Processed %d/%d vintages\n", end_idx, total_vintages))
  }

  cat("All vintage hashes updated successfully\n")
  # invisibly return the value of total_vintages
  invisible(total_vintages)
}

#' Clean up vintage data based on keep_vintage settings with table-level transactions
#'
#' This function performs cleanup of vintages after data import based on table settings
#' and hash comparisons. For tables with keep_vintage = FALSE, it keeps only the most
#' recent vintage. For tables with keep_vintage = TRUE, it applies hash comparison
#' to determine if older vintages contain unique information worth preserving.
#'
#' @param con Database connection object
#' @param schema Character string specifying the database schema
#' @param table_id Optional integer specifying a single table to process
#' @param resume Logical, whether to resume from a previous run using the progress file
#' @param progress_file Path to file where progress will be saved when resuming
#'
#' @return Invisibly returns list with cleanup summary
#' @export
vintage_cleanup <- function(con, schema = "platform", table_id = NULL,
                            resume = FALSE, progress_file = "vintage_cleanup_progress.rds") {
  # Initialize result counters
  result <- list(
    no_keep_vintages_deleted = 0,
    redundant_vintages_deleted = 0,
    tables_processed = 0,
    errors = list()
  )

  if (!requireNamespace("UMARaccessR", quietly = TRUE)) {
    stop("UMARaccessR must be installed to use the vintage_cleanup function")
  }

  # Ensure all vintages have proper hashes
  message("Calculating hashes for new vintages...")
  tryCatch({
    add_missing_vintage_hashes(con, schema)
  }, error = function(e) {
    message(sprintf("Warning: Error calculating hashes: %s", e$message))
    result$errors[[length(result$errors) + 1]] <- list(
      operation = "add_missing_vintage_hashes",
      message = e$message
    )
  })

  # Initialize or load progress tracking
  processed_tables <- c()

  # Only load progress file if resume is TRUE
  if (resume && file.exists(progress_file)) {
    message("Resuming from previous run...")
    processed_tables <- tryCatch({
      readRDS(progress_file)
    }, error = function(e) {
      message("Could not read progress file, starting fresh")
      c()
    })
  } else if (resume && !file.exists(progress_file)) {
    message("No progress file found, starting fresh")
  } else if (!resume && file.exists(progress_file)) {
    message("Starting a new run (not resuming). Existing progress file will be overwritten.")
    # Delete existing progress file to start fresh
    file.remove(progress_file)
  }

  # Get tables to process
  all_tables <- NULL

  if (!is.null(table_id)) {
    # Single table mode - get table info
    message(sprintf("Processing single table ID %d...", table_id))

    # Get the table information including keep_vintage status
    table_query <- sprintf(
      "SELECT id, keep_vintage FROM %s.table WHERE id = %d",
      schema, table_id
    )

    table_info <- DBI::dbGetQuery(con, table_query)

    if (nrow(table_info) == 0) {
      stop(sprintf("Table ID %d not found", table_id))
    }

    all_tables <- table_info |>
      dplyr::mutate(id = as.numeric(id), keep_vintage = as.logical(keep_vintage))

  } else {
    # Multiple tables mode - get all tables
    message("Processing all tables...")

    # Get all tables with their keep_vintage flag
    tables_query <- sprintf(
      "SELECT id, keep_vintage FROM %s.table ORDER BY id",
      schema
    )

    all_tables <- DBI::dbGetQuery(con, tables_query)

    if (nrow(all_tables) == 0) {
      stop("No tables found in the database")
    }

    all_tables <- all_tables |>
      dplyr::mutate(id = as.numeric(id), keep_vintage = as.logical(keep_vintage))

    message(sprintf("Found %d tables total", nrow(all_tables)))
  }

  # Filter out already processed tables if resuming
  if (resume && length(processed_tables) > 0) {
    all_tables <- all_tables[!all_tables$id %in% processed_tables, ]
    message(sprintf("%d tables left to process after filtering already processed tables",
                    nrow(all_tables)))
  }

  if (nrow(all_tables) == 0) {
    message("No tables to process")
    return(invisible(result))
  }

  # Process each table in its own transaction
  for (i in 1:nrow(all_tables)) {
    current_table_id <- all_tables$id[i]
    keep_vintage <- all_tables$keep_vintage[i]

    message(sprintf("Processing table %d/%d: ID %d, keep_vintage = %s",
                    i, nrow(all_tables), current_table_id, keep_vintage))

    # Table result for this transaction
    table_result <- list(
      no_keep_vintages_deleted = 0,
      redundant_vintages_deleted = 0,
      success = TRUE
    )

    tryCatch({
      # Begin transaction for this table
      DBI::dbBegin(con)

      if (!keep_vintage) {
        # Process table with keep_vintage = FALSE
        table_result <- process_no_keep_vintage_table(con, schema, current_table_id, table_result)
      } else {
        # Process table with keep_vintage = TRUE
        table_result <- process_keep_vintage_table(con, schema, current_table_id, table_result)
      }

      # Commit the transaction if successful
      DBI::dbCommit(con)
      message(sprintf("Table ID %d: Transaction committed successfully", current_table_id))

      # Update result counters
      result$no_keep_vintages_deleted <- result$no_keep_vintages_deleted +
        table_result$no_keep_vintages_deleted
      result$redundant_vintages_deleted <- result$redundant_vintages_deleted +
        table_result$redundant_vintages_deleted
      result$tables_processed <- result$tables_processed + 1

      # Record this table as processed
      processed_tables <- c(processed_tables, current_table_id)
      saveRDS(processed_tables, progress_file)

    }, error = function(e) {
      # If any error occurs, rollback the transaction
      if (DBI::dbIsValid(con)) {
        DBI::dbRollback(con)
        message(sprintf("Table ID %d: Transaction rolled back due to error", current_table_id))
      }
      message(sprintf("Error processing table ID %d: %s", current_table_id, e$message))
      result$errors[[length(result$errors) + 1]] <- list(
        table_id = current_table_id,
        operation = ifelse(!keep_vintage, "no_keep_vintage", "keep_vintage"),
        message = e$message
      )
    })

    # Report progress for this table
    if (table_result$success) {
      message(sprintf("Table ID %d: Deleted %d older vintages and %d redundant vintages",
                      current_table_id,
                      table_result$no_keep_vintages_deleted,
                      table_result$redundant_vintages_deleted))
    }
  }

  # Report final results
  message(sprintf("Cleanup completed: Processed %d tables", result$tables_processed))
  message(sprintf("Deleted %d vintages from tables with keep_vintage = FALSE",
                  result$no_keep_vintages_deleted))
  message(sprintf("Deleted %d redundant vintages from tables with keep_vintage = TRUE",
                  result$redundant_vintages_deleted))

  if (length(result$errors) > 0) {
    message(sprintf("Encountered %d errors during vintage cleanup", length(result$errors)))
  } else {
    # If everything completed successfully and no errors occurred,
    # we can remove the progress file
    if (file.exists(progress_file) && nrow(all_tables) > 0) {
      message("Cleanup completed successfully. Removing progress file.")
      file.remove(progress_file)
    }
  }

  invisible(result)
}

#' Process a table with keep_vintage = FALSE
#'
#' @param con Database connection object
#' @param schema Character string specifying the database schema
#' @param table_id Integer specifying the table to process
#' @param result List to store results
#'
#' @return Updated result list
#' @keywords internal
process_no_keep_vintage_table <- function(con, schema, table_id, result) {
  # Find all series in this table
  series_ids <- UMARaccessR::sql_get_series_from_table_id(table_id, con, schema)

  if (nrow(series_ids) > 0) {
    # Process each series
    for (series_id in series_ids$id) {
      # Find all vintages for this series, ordered by published date (newest first)
      vintages <- UMARaccessR::sql_get_vintages_from_series(series_id, con, schema = schema)

      # If there are multiple vintages, delete all but the most recent
      if (!is.null(vintages)) {
       vintages <- vintages |>
          dplyr::mutate(id = as.numeric(id))
        # Since vintages are ordered newest first, we keep index 1 and delete the rest
        vintages_to_delete <- vintages$id[-1]  # Skip the first (most recent)

        for (vintage_id in vintages_to_delete) {
          delete_result <- delete_vintage(con, vintage_id, schema)
          result$no_keep_vintages_deleted <- result$no_keep_vintages_deleted +
            delete_result$vintage_count
        }
      }
    }
  }

  result$success <- TRUE
  return(result)
}

#' Process a table with keep_vintage = TRUE
#'
#' @param con Database connection object
#' @param schema Character string specifying the database schema
#' @param table_id Integer specifying the table to process
#' @param result List to store results
#'
#' @return Updated result list
#' @keywords internal
process_keep_vintage_table <- function(con, schema, table_id, result) {
  # Find all series in this table
  series_ids <- UMARaccessR::sql_get_series_from_table_id(table_id, con, schema)

  if (nrow(series_ids) > 0) {
    # Process each series
    for (series_id in series_ids$id) {
      # Find all vintages for this series with their hashes, ordered by published date (newest first)
      vintages <- UMARaccessR::sql_get_vintages_with_hashes_from_series_id(series_id, con, schema) |>
        dplyr::mutate(id = as.numeric(id))

      # Need at least two vintages to compare
      if (nrow(vintages) >= 2) {
        redundant_count <- 0

        # Keep the newest vintages that are processed first in the loop
        for (i in 1:(nrow(vintages)-1)) {
          current_vintage <- vintages[i, ]  # Newer vintage
          next_vintage <- vintages[i+1, ]   # Older vintage

          # If the older vintage's full hash matches this vintage's partial hash,
          # then the older vintage is redundant (contains a subset of data)
          if (!is.na(current_vintage$partial_hash) &&
              !is.na(next_vintage$full_hash) &&
              current_vintage$partial_hash == next_vintage$full_hash) {

            delete_result <- delete_vintage(con, next_vintage$id, schema)
            result$redundant_vintages_deleted <- result$redundant_vintages_deleted +
              delete_result$vintage_count
            redundant_count <- redundant_count + 1
          }
        }
      }
    }
  }

  result$success <- TRUE
  return(result)
}
