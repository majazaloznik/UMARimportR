#' Delete a table and all its dependent records
#'
#' @description
#' Deletes a table and all its dependent records in the correct order:
#' flag_datapoint -> data_points -> vintage -> series_levels -> series ->
#' dimension_levels -> table_dimensions -> category_table -> table
#'
#' @param con Database connection object
#' @param table_id Integer identifier of the table to delete
#' @param schema Character string specifying the database schema. Defaults to "platform"
#'
#' @return A data frame with one column 'deleted_count' indicating number of tables deleted (1 for success, 0 if table not found)
#' @export
delete_table <- function(con, table_id, schema = "platform") {
  result <- sql_function_call(con, "delete_table", list(table_id), schema)
  names(result) <- c("table_count", "series_count", "vintage_count",
                     "data_points_count", "flag_count", "dimension_count",
                     "dimension_levels_count", "series_levels_count",
                     "category_table_count")
  result
}

#' Delete a series and all its dependent records
#'
#' @description
#' Deletes a series and all its dependent records in the correct order:
#' flag_datapoint -> data_points -> vintage -> series_levels -> series
#'
#' @param con Database connection object
#' @param series_id Integer identifier of the series to delete
#' @param schema Character string specifying the database schema. Defaults to "platform"
#'
#' @return A data frame with one column 'deleted_count' indicating number of tables deleted (1 for success, 0 if table not found)
#' @export
delete_series <- function(con, series_id, schema = "platform") {
  result <- sql_function_call(con, "delete_series", list(series_id), schema)
  names(result) <- c("series_count", "vintage_count",
                     "data_points_count", "flag_count", "series_levels_count")
  result
}


#' Delete a vintage and all its dependent records
#'
#' @description
#' Deletes a vintage and all its dependent records in the correct order:
#' flag_datapoint -> data_points -> vintage
#'
#' @param con Database connection object
#' @param vintage_id Integer identifier of the vintage to delete
#' @param schema Character string specifying the database schema. Defaults to "platform"
#'
#' @return A data frame with one column 'deleted_count' indicating number of vintages deleted (1 for success, 0 if vintage not found)
#' @export
delete_vintage <- function(con, vintage_id, schema = "platform") {
  result <- sql_function_call(con, "delete_vintage", list(vintage_id), schema)
  names(result) <- c("vintage_count",
                     "data_points_count", "flag_count")
  result
}

#' Clean up function for leftover vintages without datapoints
#'
#' cleans up vintages without data points. Also cascades to flags.
#' @param con Database connection object
#' @param schema Character string specifying the database schema. Defaults to "platform"
#'
#' @returns invisibly the deleted vintage ids
#' @export
remove_empty_vintages <- function(con, schema = "platform") {
  # First identify empty vintages
  query <- sprintf(
    "SELECT v.id AS vintage_id
     FROM %s.vintage v
     LEFT JOIN %s.data_points dp ON v.id = dp.vintage_id
     GROUP BY v.id
     HAVING COUNT(dp.period_id) = 0",
    schema, schema
  )

  empty_vintages <- DBI::dbGetQuery(con, query) |>
    dplyr::mutate(vintage_id = as.numeric(vintage_id))
  empty_count <- nrow(empty_vintages)

  if(empty_count == 0) {
    cat("No empty vintages found.\n")
    return(invisible(NULL))
  }

  # Delete empty vintages using existing function
  results <- lapply(empty_vintages$vintage_id, function(vid) {
    delete_vintage(con, vid, schema)
  })

  cat(sprintf("Removed %d empty vintages.\n", empty_count))
  return(invisible(empty_vintages$vintage_id))
}
