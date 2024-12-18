#' Insert a new row into the table table
#'
#' @description
#' Inserts a new row into the platform.table table using the insert_new_table SQL function.
#' The function prevents duplicate insertions using ON CONFLICT DO NOTHING.
#'
#' @param df A data frame with one row containing the following columns:
#'   * code (character): unique identifier code for the table
#'   * name (character): name/description of the table
#'   * source_id (integer): foreign key reference to the source table
#'   * url (character, optional): URL where the table data can be found
#'   * notes (character/json, optional): Additional notes in JSON format
#'   * keep_vintage (logical): Whether to keep historical versions of the table
#' @inheritParams common_parameters
#' @return A data frame with one column 'count' indicating number of rows inserted (1 for success, 0 for duplicate)
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
#' insert_new_table_table(df)
#' }
#'
#' @export
insert_new_table_table <- function(con, df, schema = "platform") {
  sql_function_call(con, "insert_new_table", as.list(df), schema)
}




#' #' Insert table structure data for a new table
#' #'
#' #' When a new table (in SURS speak 'matrix") is added, a set of nine
#' #' tables need to be populated with appropriate metadata about that table.
#' #' This umbrella function calls the respective SQL functions for each
#' #' of the nine tables.
#' #'
#' #' @inheritParams common_parameters
#' #' @param full full field hierarchy with parent_ids et al, output from
#' #'  \link[SURSfetchR]{get_full_structure}
#' #' @param schema default schema
#' #' @param keep_vintage boolean whether to keep vintages
#' #'
#' #' @return list of tables with counts for each inserted row.
#' #' @export
#' #'
#' #' @examples
#' #' \dontrun{
#' #' purrr::walk(master_list_surs$code, ~insert_new_table_structures(.x, con, full))
#' #' }
#' insert_new_table_structures <- function(code_no, con, full, schema = "platform", keep_vintage = FALSE) {
#'   res <- list()
#'   res[[1]] <- sql_function_call(con,
#'                                 "insert_new_table",
#'                                 as.list(prepare_table_table(code_no, keep_vintage)), schema = schema)
#'   res[[2]] <- sql_function_call(con,
#'                                 "insert_new_category",
#'                                 as.list(prepare_category_table(code_no, full)), schema = schema)
#'   res[[3]] <- sql_function_call(con,
#'                                 "insert_new_category_relationship",
#'                                 as.list(prepare_category_relationship_table(code_no, full)), schema = schema)
#'
#'   res[[4]] <- sql_function_call(con,
#'                                 "insert_new_category_table",
#'                                 as.list(prepare_category_table_table(code_no, full, con)), schema = schema)
#'   res[[5]] <- sql_function_call(con,
#'                                 "insert_new_table_dimensions",
#'                                 as.list(prepare_table_dimensions_table(code_no, con)), schema = schema)
#'   res[[6]] <- sql_function_call(con,
#'                                 "insert_new_dimension_levels",
#'                                 as.list(prepare_dimension_levels_table(code_no, con)), schema = schema)
#'   res[[7]] <- sql_function_call(con,
#'                                 "insert_new_unit",
#'                                 unname(as.list(prepare_unit_table(code_no, con))), schema = schema)
#'   res[[8]] <-  sql_function_call(con,
#'                                  "insert_new_series",
#'                                  unname(as.list(prepare_series_table(code_no, con))), schema = schema)
#'   res[[9]] <- sql_function_call(con,
#'                                 "insert_new_series_levels",
#'                                 unname(as.list(prepare_series_levels_table(code_no, con))), schema = schema)
#'   res
#' }
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
