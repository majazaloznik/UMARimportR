#' Insert a new table into the database
#'
#' @description
#' Inserts a new row into the table table. If a table with the same code already exists,
#' the function will not insert a duplicate and will return 0.
#'
#' @param con Database connection object
#' @param df A data frame with one row containing the following columns:
#'   * code (character): unique identifier code for the table
#'   * name (character): name/description of the table
#'   * source_id (integer): foreign key reference to the source table
#'   * url (character, optional): URL where the table data can be found
#'   * notes (character/json, optional): Additional notes in JSON format
#'   * keep_vintage (logical): Whether to keep historical versions of the table
#' @param schema Character string specifying the database schema. Defaults to "platform"
#'
#' @return A data frame with one column 'count' indicating number of rows inserted
#'         (1 for success, 0 if table with same code already exists)
#'
#' @examples
#' \dontrun{
#' df <- data.frame(
#'   code = "GDP_Q",
#'   name = "Quarterly GDP",
#'   source_id = 1,
#'   url = "http://example.com",
#'   notes = jsonlite::toJSON(list(frequency = "quarterly")),
#'   keep_vintage = TRUE
#' )
#' insert_new_table_table(con, df)
#' }
#'
#' @export
insert_new_table_table <- function(con, df, schema = "platform") {
  sql_function_call(con, "insert_new_table", as.list(df), schema)
}

#' Insert a new dimension for a table
#'
#' @description
#' Inserts a new dimension into the table_dimensions table. If the dimension
#' already exists for this table, the function will not insert a duplicate
#' and will return 0.
#'
#' @param con Database connection object
#' @param df A data frame with one row containing the following columns:
#'   * table_id (integer): ID of the table this dimension belongs to
#'   * dimension (character): name of the dimension
#'   * is_time (logical): whether this is a time dimension
#' @param schema Character string specifying the database schema. Defaults to "platform"
#'
#' @return A data frame with one column 'count' indicating number of rows inserted
#'         (1 for success, 0 if dimension already exists for this table)
#'
#' @examples
#' \dontrun{
#' df <- data.frame(
#'   table_id = 1,
#'   dimension = "time",
#'   is_time = TRUE
#' )
#' insert_new_table_dimensions(con, df)
#' }
#'
#' @export
insert_new_table_dimensions <- function(con, df, schema = "platform") {
  sql_function_call(con, "insert_new_table_dimensions", as.list(df), schema)
}

#' Insert a new dimension level
#'
#' @description
#' Inserts a new level into the dimension_levels table. If the level value
#' already exists for this dimension, the function will not insert a duplicate
#' and will return 0.
#'
#' @param con Database connection object
#' @param df A data frame with one row containing the following columns:
#'   * tab_dim_id (integer): ID of the table dimension this level belongs to
#'   * level_value (character): code or value for this level
#'   * level_text (character): descriptive text for this level (can be NULL)
#' @param schema Character string specifying the database schema. Defaults to "platform"
#'
#' @return A data frame with one column 'count' indicating number of rows inserted
#'         (1 for success, 0 if level value already exists for this dimension)
#'
#' @examples
#' \dontrun{
#' df <- data.frame(
#'   tab_dim_id = 1,
#'   level_value = "SI",
#'   level_text = "Slovenia"
#' )
#' insert_new_dimension_levels(con, df)
#' }
#'
#' @export
insert_new_dimension_levels <- function(con, df, schema = "platform") {
  sql_function_call(con, "insert_new_dimension_levels", as.list(df), schema)
}


#' Insert a new unit
#'
#' @description
#' Inserts a new unit into the unit table. If a unit with the same name
#' already exists, the function will not insert a duplicate and will return 0.
#'
#' @param con Database connection object
#' @param df A data frame with one row containing the following columns:
#'   * name (character): Name of the unit
#' @param schema Character string specifying the database schema. Defaults to "platform"
#'
#' @return A data frame with one column 'count' indicating number of rows inserted
#'         (1 for success, 0 if unit with same name already exists)
#'
#' @examples
#' \dontrun{
#' df <- data.frame(
#'   name = "meters"
#' )
#' insert_new_unit(con, df)
#' }
#'
#' @export
insert_new_unit <- function(con, df, schema = "platform") {
  sql_function_call(con, "insert_new_unit", as.list(df), schema)
}

#' Insert a new series
#'
#' @description
#' Inserts a new series into the series table. If a series with the same code
#' already exists for the same table, the function will not insert a duplicate
#' and will return 0.
#'
#' @param con Database connection object
#' @param df A data frame with one row containing the following columns:
#'   * table_id (integer): ID of the table this series belongs to
#'   * name_long (character): Long name/description of the series
#'   * unit_id (integer): ID of the unit for this series
#'   * code (character): Unique code within the table
#'   * interval_id (character): Frequency identifier (e.g., "M" for monthly, "A" for annual)
#' @param schema Character string specifying the database schema. Defaults to "platform"
#'
#' @return A data frame with one column 'count' indicating number of rows inserted
#'         (1 for success, 0 if series with same code already exists for this table)
#'
#' @examples
#' \dontrun{
#' df <- data.frame(
#'   table_id = 1,
#'   name_long = "Monthly GDP",
#'   unit_id = 1,
#'   code = "GDP_M",
#'   interval_id = "M"
#' )
#' insert_new_series(con, df)
#' }
#'
#' @export
insert_new_series <- function(con, df, schema = "platform") {
  sql_function_call(con, "insert_new_series", as.list(df), schema)
}

#' Insert a new series level
#'
#' @description
#' Inserts a new series level into the series_levels table. If the combination
#' of series_id and tab_dim_id already exists, the function will not insert
#' a duplicate and will return 0. The level_value must exist in the corresponding
#' dimension_levels table.
#'
#' @param con Database connection object
#' @param df A data frame with one row containing the following columns:
#'   * series_id (integer): ID of the series
#'   * tab_dim_id (integer): ID of the table dimension
#'   * level_value (character): Value that must exist in dimension_levels
#' @param schema Character string specifying the database schema. Defaults to "platform"
#'
#' @return A data frame with one column 'count' indicating number of rows inserted
#'         (1 for success, 0 if combination already exists)
#'
#' @examples
#' \dontrun{
#' df <- data.frame(
#'   series_id = 1,
#'   tab_dim_id = 1,
#'   level_value = "SI"
#' )
#' insert_new_series_levels(con, df)
#' }
#'
#' @export
insert_new_series_levels <- function(con, df, schema = "platform") {
  sql_function_call(con, "insert_new_series_levels", as.list(df), schema)
}




#' Insert a new source
#'
#' @description
#' Inserts a new data source into the source table. Sources must have unique
#' IDs and names. The name cannot contain dashes.
#'
#' @param con Database connection object
#' @param df A data frame with one row containing the following columns:
#'   * id (integer): Source identifier (primary key)
#'   * name (character): Short name of the source, must be unique and cannot contain dashes
#'   * name_long (character, optional): Full name of the source
#'   * url (character, optional): URL of the source
#' @param schema Character string specifying the database schema. Defaults to "platform"
#'
#' @return A data frame with one column 'count' indicating number of rows inserted
#'         (1 for success, 0 if source with same id or name already exists)
#'
#' @examples
#' \dontrun{
#' df <- data.frame(
#'   id = 1,
#'   name = "SURS",
#'   name_long = "Statistical Office",
#'   url = "http://www.stat.si"
#' )
#' insert_new_source(con, df)
#' }
#'
#' @export
insert_new_source <- function(con, df, schema = "platform") {
  sql_function_call(con, "insert_new_source", as.list(df), schema)
}

#' Insert a new category
#'
#' @description
#' Inserts a new category into the category table. Categories are unique per source,
#' identified by both id and name.
#'
#' @param con Database connection object
#' @param df A data frame with one row containing the following columns:
#'   * id (integer): Category identifier (unique within source_id)
#'   * name (character): Category name (unique within source_id)
#'   * source_id (integer): ID of the source this category belongs to
#' @param schema Character string specifying the database schema. Defaults to "platform"
#'
#' @return A data frame with one column 'count' indicating number of rows inserted
#'         (1 for success, 0 if category already exists for this source)
#'
#' @examples
#' \dontrun{
#' df <- data.frame(
#'   id = 1,
#'   name = "Economic Statistics",
#'   source_id = 1
#' )
#' insert_new_category(con, df)
#' }
#'
#' @export
insert_new_category <- function(con, df, schema = "platform") {
  sql_function_call(con, "insert_new_category", as.list(df), schema)
}


#' Insert a new category relationship
#'
#' @description
#' Creates a parent-child relationship between two categories within the same source.
#' The relationship is defined by specifying which category is the child (id) and
#' which is the parent (parent_id).
#'
#' @param con Database connection object
#' @param df A data frame with one row containing the following columns:
#'   * id (integer): ID of the child category
#'   * parent_id (integer): ID of the parent category
#'   * source_id (integer): ID of the source these categories belong to
#' @param schema Character string specifying the database schema. Defaults to "platform"
#'
#' @return A data frame with one column 'count' indicating number of rows inserted
#'         (1 for success, 0 if relationship already exists)
#'
#' @examples
#' \dontrun{
#' df <- data.frame(
#'   id = 2,         # child category
#'   parent_id = 1,  # parent category
#'   source_id = 1
#' )
#' insert_new_category_relationship(con, df)
#' }
#'
#' @export
insert_new_category_relationship <- function(con, df, schema = "platform") {
  sql_function_call(con, "insert_new_category_relationship", as.list(df), schema)
}

#' Insert a new category-table link
#'
#' @description
#' Links a table to a category within the same source. A table can be linked
#' to multiple categories.
#'
#' @param con Database connection object
#' @param df A data frame with one row containing the following columns:
#'   * category_id (integer): ID of the category
#'   * table_id (integer): ID of the table
#'   * source_id (integer): ID of the source these both belong to
#' @param schema Character string specifying the database schema. Defaults to "platform"
#'
#' @return A data frame with one column 'count' indicating number of rows inserted
#'         (1 for success, 0 if link already exists)
#'
#' @examples
#' \dontrun{
#' df <- data.frame(
#'   category_id = 1,
#'   table_id = 1,
#'   source_id = 1
#' )
#' insert_new_category_table(con, df)
#' }
#'
#' @export
insert_new_category_table <- function(con, df, schema = "platform") {
  sql_function_call(con, "insert_new_category_table", as.list(df), schema)
}



#' Insert new data for a table i.e. a vintage
#'
#' When new data for a table (in SURS speak 'matrix") is added, these are new
#' vintages. This function adds a set of new vintages and their corresponding
#' data points and flags to the database, by calling the respective SQL functions
#' for each of these tables.
#'
#' @inheritParams common_parameters
#'
#' @return list of tables with counts for each inserted row.
#' @export
#'
#' @examples
#' \dontrun{
#' purrr::walk(master_list_surs$code, ~insert_new_data(.x, con))
#' }
insert_new_data <- function(code_no, con, schema = "platform") {
  res <- list()
  res[[1]] <- sql_function_call(con,
                                "insert_new_vintage",
                                unname(as.list(prepare_vintage_table(code_no ,con))),
                                schema = schema)
  print(paste(sum(res[[1]]), "new rows inserted into the vintage table"))
  tryCatch(
    {insert_data_points(code_no, con, schema = schema)},
    error = function(cond){
      message(paste("The data was not inserted for SURS table", code_no))
      message("Here's the original error message:")
      message(conditionMessage(cond))
      # Choose a return value in case of error
      NA
    }
  )

}

#' Insert a new vintage
#'
#' @description
#' Creates a new vintage (version) of a series with a specific publication timestamp.
#' Each series can have multiple vintages with different timestamps.
#'
#' @param con Database connection object
#' @param df A data frame with one row containing the following columns:
#'   * series_id (integer): ID of the series this vintage belongs to
#'   * published (POSIXct): Timestamp when this vintage was published
#' @param schema Character string specifying the database schema. Defaults to "platform"
#'
#' @return A data frame with one column 'count' indicating number of rows inserted
#'         (1 for success, 0 if vintage with same timestamp already exists for this series)
#'
#' @examples
#' \dontrun{
#' df <- data.frame(
#'   series_id = 1,
#'   published = as.POSIXct("2024-01-01 10:00:00")
#' )
#' insert_new_vintage(con, df)
#' }
#'
#' @export
insert_new_vintage <- function(con, df, schema = "platform") {
  sql_function_call(con, "insert_new_vintage", as.list(df), schema)
}


#' Insert data points into database
#'
#' Generic function to insert prepared data points into the database.
#' Works with data prepared by SURS-specific or other preparation functions.
#'
#' @param prep_data A prepared data object from prepare_surs_data_for_insert
#' @param con Database connection
#' @param schema Schema name
#'
#' @return A data frame with insertion counts
#' @export
insert_prepared_data_points <- function(prep_data, con, schema = "platform") {
  # 1. Create temp table
  DBI::dbWriteTable(con, "tmp_prepared_data", prep_data$data, temporary = TRUE, overwrite = TRUE)
  on.exit(DBI::dbExecute(con, "DROP TABLE IF EXISTS tmp_prepared_data"))

  # Debug - check data got loaded
  message("Data loaded into tmp_prepared_data. Sample rows:")
  print(head(DBI::dbGetQuery(con, "SELECT * FROM tmp_prepared_data LIMIT 5")))

  # 2. Add series_id column
  DBI::dbExecute(con, "ALTER TABLE tmp_prepared_data ADD COLUMN series_id integer")
  DBI::dbExecute(con, "ALTER TABLE tmp_prepared_data ADD COLUMN vintage_id integer")

  # 3. Match dimension values with series
  dimension_names <- prep_data$dimension_names
  dimension_ids <- prep_data$dimension_ids

  message("Matching dimensions:")
  for(i in seq_along(dimension_names)) {
    message("  - ", dimension_names[i], " (ID: ", dimension_ids[i], ")")
  }

  # 3b. Update series IDs
  # Create EXISTS subqueries for each dimension
  # Create EXISTS clauses without using lapply
  # Create EXISTS clauses without using lapply
  exists_clauses <- vector("list", length(dimension_names))

  for (i in seq_along(dimension_names)) {
    dim_name <- dimension_names[i]
    dim_id <- dimension_ids[i]

    # Get column names from data frame
    col_names <- names(prep_data$data)

    # This is how pxR transforms names
    px_transformed_name <- make.names(dim_name)

        # Check for match
    match_found <- FALSE
    matched_col <- NULL

    for (col in col_names) {
      if (col == px_transformed_name) {
        matched_col <- col
        match_found <- TRUE
        break
      }
    }

    if (!match_found) {
      stop("Column not found for dimension: ", dim_name,
           "\nExpected column name: ", px_transformed_name,
           "\nAvailable columns: ", paste(col_names, collapse=", "))
    }

    message("  - Matched dimension: ", dim_name, " -> column: ", matched_col)

    # Create the EXISTS clause
    exists_clauses[[i]] <- sprintf(
      "EXISTS (
      SELECT 1 FROM %s.series_levels sl%d
      WHERE sl%d.series_id = s.id
      AND sl%d.tab_dim_id = %d
      AND tmp_prepared_data.\"%s\" = sl%d.level_value
    )",
      schema, i, i, i, dim_id, matched_col, i
    )
  }
  # Join all EXISTS clauses
  exists_conditions <- paste(exists_clauses, collapse = " AND ")

  # Build the final query
  update_query <- sprintf(
    "UPDATE tmp_prepared_data
   SET series_id = s.id
   FROM %s.series s
   WHERE s.table_id = %d
   AND %s",
    schema, prep_data$table_id, exists_conditions
  )

  # 3c. Update vintage IDs
  vintage_query <- sprintf(
    "UPDATE tmp_prepared_data
     SET vintage_id = v.id
     FROM (
       SELECT DISTINCT ON (series_id) id, series_id
       FROM %s.vintage
       ORDER BY series_id, published DESC
     ) v
     WHERE tmp_prepared_data.series_id = v.series_id",
    schema
  )

  # 4. Execute the updates
  rows_updated <- DBI::dbExecute(con, update_query)
  message("Updated series_id for ", rows_updated, " rows")

  rows_updated <- DBI::dbExecute(con, vintage_query)
  message("Updated vintage_id for ", rows_updated, " rows")

  # Debug - check matched data
  message("After matching. Sample rows:")
  print(head(DBI::dbGetQuery(con, "SELECT * FROM tmp_prepared_data LIMIT 5")))

  # Check if any rows have series_id and vintage_id
  matched_count <- DBI::dbGetQuery(con, "SELECT COUNT(*) FROM tmp_prepared_data WHERE series_id IS NOT NULL AND vintage_id IS NOT NULL")
  message("Rows with both series_id and vintage_id: ", matched_count[[1]])

  # 5. Insert data into permanent tables
  # 5a. Insert periods
  periods_query <- sprintf(
    "INSERT INTO %s.period (id, interval_id)
     SELECT DISTINCT time, '%s' FROM tmp_prepared_data
     ON CONFLICT DO NOTHING",
    schema, prep_data$interval_id
  )

  # 5b. Insert data points
  datapoints_query <- sprintf(
    "INSERT INTO %s.data_points (vintage_id, period_id, value)
     SELECT vintage_id, time, value FROM tmp_prepared_data
     WHERE vintage_id IS NOT NULL
     ON CONFLICT DO NOTHING",
    schema
  )

  # 5c. Insert flags
  flags_query <- sprintf(
    "INSERT INTO %s.flag_datapoint (vintage_id, period_id, flag_id)
     SELECT vintage_id, time, flag FROM tmp_prepared_data
     WHERE vintage_id IS NOT NULL AND flag <> ''
     ON CONFLICT DO NOTHING",
    schema
  )

  # 6. Execute inserts and track results
  periods_inserted <- DBI::dbExecute(con, periods_query)
  datapoints_inserted <- DBI::dbExecute(con, datapoints_query)
  flags_inserted <- DBI::dbExecute(con, flags_query)

  # 7. Create result
  result <- data.frame(
    periods_inserted = periods_inserted,
    datapoints_inserted = datapoints_inserted,
    flags_inserted = flags_inserted
  )

  # 8. Display results
  message("Inserted ", periods_inserted, " new periods")
  message("Inserted ", datapoints_inserted, " new data points")
  message("Inserted ", flags_inserted, " new flags")

  invisible(result)
}

#' #' Umbrella code for adding a new table to the database
#' #'
#' #' The code gets the new hierarchy from the structAPI to get the category levels
#' #' right and then inserts all the required strucutres and finally the data points
#' #' for the first set of vintages for these series
#' #' @param code character ID of the table e.g. "0714621S"
#' #' @param con connection to database
#' #' @param keep_vintage boolean whether to keep vintages
#' #'
#' #' @return nothing
#' #' @export
#' #'
#' add_new_table <- function(code, con, keep_vintage = FALSE) {
#'   # get full hierarchy
#'   cont <- get_API_response()
#'   tree <- parse_structAPI_response(cont)
#'   full <- get_full_structure(tree)
#'   out <- list()
#'   # insert table structures for a single matrix
#'   out[[1]] <- insert_new_table_structures(code, keep_vintage, con, full)
#'   # insert data  for a single matrix
#'   out[[2]] <- insert_new_data(code, con)
#'   out
#' }
#'
#'
#' #' Add new dimension levels to existing table
#' #'
#' #' Sometimes an existing table will get a new category. In that case you want to
#' #' add the levels, series and series levels separately just for the new series
#' #' and this function does that. You need to get the code for the new level from
#' #' Si-Stat
#' #'
#' #' @param code surs table code such as 0457102S
#' #' @param level level code such as 29
#' #' @param con connection to database
#' #' @param schema database schema name
#' #'
#' #' @return nothing
#' #' @export
#' #'
#' add_new_dimension_levels_full <- function(code, level, con, schema = "platform" ){
#'   dim_levels <- prepare_dimension_levels_table(code, con)
#'   dim_level <- dim_levels |>
#'     dplyr::filter(level_value == level)
#'   sql_function_call(con,
#'                     "insert_new_dimension_levels",
#'                     as.list(dim_level), schema = schema)
#'
#'   new_series <- prepare_series_table(code, con)
#'   new_series <- new_series |>
#'     dplyr::filter(grepl(paste0("--",level, "--"), series_code))
#'   sql_function_call(con,
#'                     "insert_new_series",
#'                     unname(as.list(new_series)), schema = schema)
#'
#'   series_levels <- prepare_series_levels_table(code, con)
#'   new_series_ids <- purrr::map(new_series$series_code, SURSfetchR:::get_series_id, con = con)
#'   new_series_levels <- series_levels |>
#'     dplyr::filter(series_id %in% new_series_ids)
#'   sql_function_call(con,
#'                     "insert_new_series_levels",
#'                     unname(as.list(new_series_levels)), schema = schema)
#' }
