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

  all_data <- DBI::dbGetQuery(con, query)

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
  all_vintages <- DBI::dbGetQuery(con, query)
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
