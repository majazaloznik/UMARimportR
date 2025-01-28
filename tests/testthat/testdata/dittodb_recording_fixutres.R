source("tests/testthat/helper-connection.R")

# start_db_capturing()
# con <- make_test_connection()
# DBI::dbExecute(con, "set search_path to test_schema")
#
# # Test basic function
# result1 <- sql_function_call(con, "get_count", NULL, "test_schema")
#
# # Test with parameters
# result2 <- sql_function_call(
#   con,
#   "filter_data",
#   list(min_value = 10, category_param = "test"),
#   "test_schema"
# )
#
# # Test NULL handling
# result3 <- sql_function_call(
#   con,
#   "handle_nulls",
#   list(param1 = NULL, param2 = 1),
#   "test_schema"
# )
#
# sql_function_call(con, "filter_data", list(10, "test"), "test_schema")
# stop_db_capturing()


#
# start_db_capturing()
# # First insert
# con <- make_test_connection()
# df1 <- data.frame(
#   code = "TEST03",
#   name = "Test Table",
#   source_id = 1L,
#   url = "http://example.com",
#   notes = jsonlite::toJSON(list(note = "test note")),
#   keep_vintage = TRUE,
#   stringsAsFactors = FALSE
# )
# print(insert_new_table_table(con, df1, schema = "test_platform"))
# stop_db_capturing()
#
# start_db_capturing()
# con <- make_test_connection()
#
# # Test vintage deletion
# v_result <- delete_vintage(con, 6396, schema = "test_platform")
# print("Vintage deletion result:")
# print(v_result)
#
# # Test series deletion
# s_result <- delete_series(con, 5802, schema = "test_platform")
# print("Series deletion result:")
# print(s_result)
#
# # Test table deletion
# t_result <- delete_table(con, 22, schema = "test_platform")
# print("Table deletion result:")
# print(t_result)
#
# stop_db_capturing()
#
# start_db_capturing()
# con <- make_test_connection()
#
# # Just capture one insert
# df <- data.frame(
#   code = "TEST01",
#   name = "Test Table",
#   source_id = 1L,
#   url = "http://example.com",
#   notes = jsonlite::toJSON(list(note = "test note")),
#   keep_vintage = TRUE,
#   stringsAsFactors = FALSE
# )
# result <- insert_new_table_table(con, df, schema = "test_platform")
# print(result)
#
# stop_db_capturing()
# start_db_capturing()
# con <- make_test_connection()
#
# df <- data.frame(
#   table_id = 174L,
#   dimension = "time",
#   is_time = TRUE
# )
# result <- insert_new_table_dimensions(con, df, schema = "test_platform")
# print(result)
#
# stop_db_capturing()
#
#
# start_db_capturing()
# con <- make_test_connection()
#
# df <- data.frame(
#   tab_dim_id = 267L,
#   level_value = "SI",
#   level_text = "Slovenia",
#   stringsAsFactors = FALSE
# )
# result <- insert_new_dimension_levels(con, df, schema = "test_platform")
# print(result)
#
# stop_db_capturing()
#
# start_db_capturing()
# con <- make_test_connection()
#
# df <- data.frame(
#   name = "meters",
#   stringsAsFactors = FALSE
# )
# result <- insert_new_unit(con, df, schema = "test_platform")
# print(result)
#
# stop_db_capturing()
#
#
# start_db_capturing()
# con <- make_test_connection()
#
# df <- data.frame(
#   table_id = 174,
#   name_long = "Monthly GDP",
#   unit_id = 1L,
#   code = "GDP_M",
#   interval_id = "M",
#   stringsAsFactors = FALSE
# )
# result <- insert_new_series(con, df, schema = "test_platform")
# print(result)
#
# stop_db_capturing()
#
#
# start_db_capturing()
# con <- make_test_connection()
#
# df <- data.frame(
#   series_id = 42785L,
#   tab_dim_id = 267L,
#   level_value = "SI",
#   stringsAsFactors = FALSE
# )
# result <- insert_new_series_levels(con, df, schema = "test_platform")
# print(result)
#
# stop_db_capturing()
#
# start_db_capturing()
# con <- make_test_connection()
#
# df <- data.frame(
#   id = 5L,
#   name = "SURSi",
#   name_long = "Statistical Office",
#   url = "http://www.stat.si",
#   stringsAsFactors = FALSE
# )
# result <- insert_new_source(con, df, schema = "test_platform")
# print(result)
#
# stop_db_capturing()
#
# start_db_capturing()
# con <- make_test_connection()
#
# df <- data.frame(
#   id = 999L,
#   name = "Economic Statistics",
#   source_id = 1L,
#   stringsAsFactors = FALSE
# )
# result <- insert_new_category(con, df, schema = "test_platform")
# print(result)
#
# stop_db_capturing()
#
#
# start_db_capturing()
# con <- make_test_connection()
#
# df <- data.frame(
#   id = 999L,          # child category
#   parent_id = 57L,   # parent category
#   source_id = 1L,
#   stringsAsFactors = FALSE
# )
# result <- insert_new_category_relationship(con, df, schema = "test_platform")
# print(result)
#
# stop_db_capturing()
#
# start_db_capturing()
# con <- make_test_connection()
#
# df <- data.frame(
#   category_id = 1L,
#   table_id = 191L,
#   source_id = 5L,
#   stringsAsFactors = FALSE
# )
# result <- insert_new_category_table(con, df, schema = "test_platform")
# print(result)
#
# stop_db_capturing()
#
# start_db_capturing()
# con <- make_test_connection()
#
# df <- data.frame(
#   series_id = 1917L,
#   published = as.POSIXct("2024-01-01 10:00:00"),
#   stringsAsFactors = FALSE
# )
# result <- insert_new_vintage(con, df, schema = "test_platform")
# print(result)
#
# stop_db_capturing()
