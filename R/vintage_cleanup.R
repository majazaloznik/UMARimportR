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

#' Clean up vintage data based on keep_vintage settings
#'
#' This function performs cleanup of vintages after data import based on table settings
#' and hash comparisons. For tables with keep_vintage = FALSE, it keeps only the most
#' recent vintage. For tables with keep_vintage = TRUE, it applies hash comparison
#' to determine if older vintages contain unique information worth preserving.
#'
#' You can also pass a single table_id to process only that table.
#'
#' @param con Database connection object
#' @param schema Character string specifying the database schema
#' @param table_id Optional integer specifying a single table to process
#'
#' @return Invisibly returns list with cleanup summary
#' @export
vintage_cleanup <- function(con, schema = "platform", table_id = NULL) {
  # Initialize result counters
  result <- list(
    no_keep_vintages_deleted = 0,
    redundant_vintages_deleted = 0,
    errors = list()
  )
  if (!requireNamespace("UMARaccessR", quietly = TRUE)) {
    stop("UMARaccessR must be installed to use the vintage_cleanup function")
  }
  tryCatch({
    # First ensure all vintages have proper hashes
    message("Calculating hashes for new vintages...")
    add_missing_vintage_hashes(con, schema)

    # Begin transaction
    DBI::dbBegin(con)

    # If a specific table_id is provided, get its keep_vintage status
    if (!is.null(table_id)) {
      message(sprintf("Processing single table ID %d...", table_id))

      # Get the table information to determine if keep_vintage is TRUE/FALSE
      table_info <- UMARaccessR::sql_get_table_info(table_id, con, schema)

      if (is.null(table_info)) {
        stop(sprintf("Table ID %d not found", table_id))
      }

      keep_vintage <- table_info$keep_vintage

      # Process based on keep_vintage value
      if (!keep_vintage) {
        # Process table with keep_vintage = FALSE
        message(sprintf("Table ID %d has keep_vintage = FALSE", table_id))
        result <- process_no_keep_vintage_table(con, schema, table_id, result)
      } else {
        # Process table with keep_vintage = TRUE
        message(sprintf("Table ID %d has keep_vintage = TRUE", table_id))
        result <- process_keep_vintage_table(con, schema, table_id, result)
      }
    } else {
      # Process all tables
      message("Processing all tables...")

      # Get tables with keep_vintage = FALSE
      message("Identifying tables with keep_vintage = FALSE...")
      no_keep_tables <- UMARaccessR::sql_get_tables_with_keep_vintage(FALSE, con, schema) |>
        dplyr::mutate(id = as.numeric(id))

      if (nrow(no_keep_tables) > 0) {
        message(sprintf("Found %d tables with keep_vintage = FALSE", nrow(no_keep_tables)))

        # For each table with keep_vintage = FALSE
        for (current_table_id in no_keep_tables$id) {
          result <- process_no_keep_vintage_table(con, schema, current_table_id, result)
        }
      } else {
        message("No tables found with keep_vintage = FALSE")
      }

      # Get tables with keep_vintage = TRUE
      message("Identifying tables with keep_vintage = TRUE...")
      keep_tables <- UMARaccessR::sql_get_tables_with_keep_vintage(TRUE, con, schema) |>
        dplyr::mutate(id = as.numeric(id))

      if (nrow(keep_tables) > 0) {
        message(sprintf("Found %d tables with keep_vintage = TRUE", nrow(keep_tables)))

        # For each table with keep_vintage = TRUE
        for (current_table_id in keep_tables$id) {
          result <- process_keep_vintage_table(con, schema, current_table_id, result)
        }
      } else {
        message("No tables found with keep_vintage = TRUE")
      }
    }

    # Commit the transaction if all operations succeeded
    DBI::dbCommit(con)
    message("Transaction committed successfully")

  }, error = function(e) {
    # If any error occurs in the main process, rollback the transaction
    if (DBI::dbIsValid(con)) {
      DBI::dbRollback(con)
      message("Transaction rolled back due to error")
    }
    message(sprintf("Error in vintage_cleanup: %s", e$message))
    result$errors[[length(result$errors) + 1]] <- list(
      operation = "main_process",
      message = e$message
    )
  })

  # Report results
  if (result$no_keep_vintages_deleted > 0 || result$redundant_vintages_deleted > 0) {
    message(sprintf("Cleanup summary: Deleted %d vintages from tables with keep_vintage = FALSE",
                    result$no_keep_vintages_deleted))
    message(sprintf("Cleanup summary: Deleted %d redundant vintages from tables with keep_vintage = TRUE",
                    result$redundant_vintages_deleted))
  } else {
    message("No vintages were deleted during cleanup")
  }

  if (length(result$errors) > 0) {
    message(sprintf("Encountered %d errors during vintage cleanup", length(result$errors)))
  }

  invisible(result)
}

#' Process a table with keep_vintage = FALSE
#'
#' @param con Database connection object
#' @param schema Character string specifying the database schema
#' @param table_id Integer specifying the table to process
#' @param result List to store results and errors
#'
#' @return Updated result list
#' @keywords internal
process_no_keep_vintage_table <- function(con, schema, table_id, result) {
  tryCatch({
    message(sprintf("Processing table ID %d...", table_id))

    # Find all series in this table
    series_ids <- UMARaccessR::sql_get_series_from_table_id(table_id, con, schema)

    if (nrow(series_ids) > 0) {
      # Process each series
      for (series_id in series_ids$id) {
        # Find all vintages for this series, ordered by published date (newest first)
        vintages <- UMARaccessR::sql_get_vintages_from_series(series_id, con, schema = schema) |>
          dplyr::mutate(id = as.numeric(id))

        # If there are multiple vintages, delete all but the most recent
        if (nrow(vintages) > 1) {
          # Since vintages are ordered newest first, we keep index 1 and delete the rest
          vintages_to_delete <- vintages$id[-1]  # Skip the first (most recent)
          message(sprintf("Series ID %d: Deleting %d older vintages",
                          series_id, length(vintages_to_delete)))

          for (vintage_id in vintages_to_delete) {
            delete_result <- delete_vintage(con, vintage_id, schema)
            result$no_keep_vintages_deleted <- result$no_keep_vintages_deleted +
              delete_result$vintage_count
          }
        }
      }
    }
    return(result)
  }, error = function(e) {
    message(sprintf("Error processing table ID %d: %s", table_id, e$message))
    result$errors[[length(result$errors) + 1]] <- list(
      table_id = table_id,
      operation = "no_keep_vintage",
      message = e$message
    )
    return(result)
  })
}

#' Process a table with keep_vintage = TRUE
#'
#' @param con Database connection object
#' @param schema Character string specifying the database schema
#' @param table_id Integer specifying the table to process
#' @param result List to store results and errors
#'
#' @return Updated result list
#' @keywords internal
process_keep_vintage_table <- function(con, schema, table_id, result) {
  tryCatch({
    message(sprintf("Processing table ID %d...", table_id))

    # Find all series in this table
    series_ids <- UMARaccessR::sql_get_series_from_table_id(table_id, con, schema)

    if (nrow(series_ids) > 0) {
      # Process each series
      for (series_id in series_ids$id) {
        # Find all vintages for this series with their hashes, ordered by published date (newest first)
        vintages <- UMARaccessR::sql_get_vintages_with_hashes_from_series_id(series_id, con, schema) |>
          dplyr::mutate(id = as.numeric(id))

        # Reverse the order to process from oldest to newest
        # This makes the comparison logic cleaner
        vintages <- vintages[nrow(vintages):1, ]

        # Need at least two vintages to compare
        if (nrow(vintages) >= 2) {
          redundant_count <- 0

          for (i in 2:nrow(vintages)) {
            current_vintage <- vintages[i, ]
            previous_vintage <- vintages[i-1, ]

            # If the previous vintage's full hash matches this vintage's partial hash,
            # then this vintage is redundant (only differs by one datapoint)
            if (!is.na(previous_vintage$full_hash) &&
                !is.na(current_vintage$partial_hash) &&
                previous_vintage$full_hash == current_vintage$partial_hash) {

              delete_result <- delete_vintage(con, current_vintage$id, schema)
              result$redundant_vintages_deleted <- result$redundant_vintages_deleted +
                delete_result$vintage_count
              redundant_count <- redundant_count + 1
            }
          }

          if (redundant_count > 0) {
            message(sprintf("Series ID %d: Deleted %d redundant vintages",
                            series_id, redundant_count))
          }
        }
      }
    }
    return(result)
  }, error = function(e) {
    message(sprintf("Error processing table ID %d: %s", table_id, e$message))
    result$errors[[length(result$errors) + 1]] <- list(
      table_id = table_id,
      operation = "keep_vintage",
      message = e$message
    )
    return(result)
  })
}

