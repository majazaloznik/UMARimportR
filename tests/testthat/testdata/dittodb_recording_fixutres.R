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
