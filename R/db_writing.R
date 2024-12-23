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







#'
#'
#' #' Insert new data for a table i.e. a vintage
#' #'
#' #' When new data for a table (in SURS speak 'matrix") is added, these are new
#' #' vintages. This function adds a set of new vintages and their corresponding
#' #' data points and flags to the database, by calling the respective SQL functions
#' #' for each of these tables.
#' #'
#' #' @inheritParams common_parameters
#' #'
#' #' @return list of tables with counts for each inserted row.
#' #' @export
#' #'
#' #' @examples
#' #' \dontrun{
#' #' purrr::walk(master_list_surs$code, ~insert_new_data(.x, con))
#' #' }
#' insert_new_data <- function(code_no, con, schema = "platform") {
#'   res <- list()
#'   res[[1]] <- sql_function_call(con,
#'                                 "insert_new_vintage",
#'                                 unname(as.list(prepare_vintage_table(code_no ,con))),
#'                                 schema = schema)
#'   print(paste(sum(res[[1]]), "new rows inserted into the vintage table"))
#'   tryCatch(
#'     {insert_data_points(code_no, con, schema = schema)},
#'     error = function(cond){
#'       message(paste("The data was not inserted for SURS table", code_no))
#'       message("Here's the original error message:")
#'       message(conditionMessage(cond))
#'       # Choose a return value in case of error
#'       NA
#'     }
#'   )
#'
#' }
#'
#'
#' #' Insert datapoints into data_point table
#' #'
#' #' This is one hell of a function. Not even sure how i got it all to work.. It
#' #' should eventually get rewritten like all the other insert functions are in
#' #' PL/pgSQL, but if it ain't broke don't try to fix it, innit?
#' #'
#' #' So, the function downloads and preps the data with \link[SURSfetchR]{prepare_data_table}
#' #' and writes it to a temporary table in the database. Then it gets the table id,
#' #' dimension ids and dim names. Then with all that in hand, the main bit of the code
#' #' prepares the temp table by adding the appropriate vintage ids for each series.
#' #'
#' #' Then the function gets the "za?asni podatki", which are inside the fucking time
#' #' period variable.. Needs to strip them off and save them separately, because we do
#' #' want to know.
#' #'
#' #' Then to finish off the function inserts any new periods into the period table,
#' #' adds the data points to the data point table and the flags (temporary = T) into
#' #' the flag-datapoint table.
#' #'
#' #' @inheritParams common_parameters
#' #'
#' #' @return nothing, just some printing along the way
#' #' @export
#' #'
#' insert_data_points <- function(code_no, con, schema = "platform"){
#'   on.exit(DBI::dbExecute(con, sprintf("drop table tmp")))
#'   df <- prepare_data_table(code_no, con)
#'   # THIS TAKES OUT NON ASCII CHARACTERS
#'   names(df) <- gsub("[^\x01-\x7F]+", "", names(df))
#'   DBI::dbWriteTable(con,
#'                     "new_data_points",
#'                     df,
#'                     temporary = TRUE,
#'                     overwrite = TRUE)
#'
#'   tbl_id <- get_table_id(code_no, con)
#'   dim_id <- DBI::dbGetQuery(con,
#'                             sprintf("SELECT id FROM %s.table_dimensions where
#'            table_id = %s and is_time is not true",schema, bit64::as.integer64(tbl_id)))
#'   dim_id_str <- toString(sprintf("%s", bit64::as.integer64(dim_id$id)))
#'   tbl_dims <- DBI::dbGetQuery(con,
#'                               sprintf("SELECT replace(dimension, ' ', '.') as dimension
#'                                FROM %s.table_dimensions
#'                                where id in (%s)
#'                                order by id",
#'                                       schema, dim_id_str))
#'   tbl_dims_str_w_types <- toString(paste(sprintf('"%s"', make.names(tbl_dims$dimension)), "text"))
#'   tbl_dims_str <- toString(paste(sprintf('"%s"', make.names(tbl_dims$dimension))))
#'   time <- get_time_dimension(code_no, con)
#'   interval_id <- get_interval_id(time)
#'   # prepares the tmp table with data_points with correct series id-s
#'   series_levels_wide <- DBI::dbExecute(con,
#'                                        sprintf("CREATE TEMP TABLE tmp AS
#'                                     select * from new_data_points
#'                                     left join
#'                                     (select *
#'                                     from crosstab(
#'                                     'SELECT series_id,  j.dimension, level_value
#'                                     FROM %s.series_levels
#'                                     left join
#'                                     (SELECT id, dimension
#'                                     FROM %s.table_dimensions
#'                                     where id in (%s)) as j
#'                                     on tab_dim_id = j.id
#'                                     where tab_dim_id in (%s)
#'                                     ORDER BY 1,2',
#'                                     'select dimension from (select distinct d.dimension, d.id from
#'                                     (SELECT id, dimension FROM %s.table_dimensions
#'                                      where id in (%s)) as d order by d.id) as dimz;')
#'                                     as t(series_id int, %s )) i using (%s)
#'                                     left join
#'                                     (select distinct on (series_id)
#'                                     id as vintage_id, series_id from
#'                                     %s.vintage
#'                                     order by series_id, published desc) as vinz using (series_id)
#'                                     ",
#'                                                schema,
#'                                                schema,
#'                                                dim_id_str,
#'                                                dim_id_str,
#'                                                schema,
#'                                                dim_id_str,
#'                                                gsub("[^\x01-\x7F]+", "",tbl_dims_str_w_types),
#'                                                gsub("[^\x01-\x7F]+", "",tbl_dims_str),
#'                                                schema))
#'
#'   DBI::dbExecute(con, sprintf("alter table \"tmp\" add  \"time\" varchar"))
#'   DBI::dbExecute(con, sprintf("alter table \"tmp\" add \"flag\" varchar"))
#'   DBI::dbExecute(con, sprintf("alter table \"tmp\" add \"interval_id\" varchar"))
#'
#'   # time is stripped of everything after first space
#'   # flags after the space in time are split off too.
#'   DBI::dbExecute(con, sprintf("UPDATE \"tmp\" SET
#'                         \"time\" = split_part(%s, ' ', 1),
#'                         \"flag\" = substring(%s,
#'                         (length(split_part(%s,' ',1)))+1,
#'                         (length(%s)) - (length(split_part(%s,' ',1)))),
#'                        \"interval_id\" = %s",
#'                               DBI::dbQuoteIdentifier(con,gsub("[^\x01-\x7F]+", "",time)),
#'                               DBI::dbQuoteIdentifier(con,gsub("[^\x01-\x7F]+", "",time)),
#'                               DBI::dbQuoteIdentifier(con,gsub("[^\x01-\x7F]+", "",time)),
#'                               DBI::dbQuoteIdentifier(con,gsub("[^\x01-\x7F]+", "",time)),
#'                               DBI::dbQuoteIdentifier(con,gsub("[^\x01-\x7F]+", "",time)),
#'                               DBI::dbQuoteLiteral(con, interval_id)))
#'
#'   # change "zacasni podatki" to flag "T"
#'   DBI::dbExecute(con, "UPDATE \"tmp\" SET flag = 'T' where flag like ' (za%asni podatki)'")
#'   # dbExecute(con, "UPDATE \"tmp\" SET flag = 'T' where flag like '(za%asni podatki)'")
#'   # insert into period table periods that are not already in there.
#'   x <- DBI::dbExecute(con, sprintf("insert into %s.period
#'                        select distinct on (\"time\") \"time\", tmp.interval_id from tmp
#'                        left join %s.period on \"time\" = id
#'                        on conflict do nothing",
#'                                    DBI::dbQuoteIdentifier(con, schema),
#'                                    DBI::dbQuoteIdentifier(con, schema)))
#'   print(paste(x, "new rows inserted into the period table"))
#'
#'   # insert data into main data_point table
#'   x <- DBI::dbExecute(con, sprintf("insert into %s.data_points
#'                        select vintage_id, time, value from tmp
#'                        WHERE vintage_id IS NOT NULL
#'                        on conflict do nothing",
#'                                    DBI::dbQuoteIdentifier(con, schema)))
#'   print(paste(x, "new rows inserted into the data_points table"))
#'
#'   # insert flags into flag_datapoint table
#'   x <- DBI::dbExecute(con, sprintf("insert into %s.flag_datapoint
#'                        select vintage_id, \"time\", flag from
#'                        tmp where tmp.flag <> ''
#'                        on conflict do nothing",
#'                                    DBI::dbQuoteIdentifier(con, schema)))
#'   print(paste(x, "new rows inserted into the flag_datapoint table"))
#' }
#'
#'
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
